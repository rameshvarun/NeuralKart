import requests
from PIL import Image, ImageDraw
from collections import namedtuple

TrackData = namedtuple('TrackData', ['url'])

TRACK_DATA = {
    'CM': TrackData('http://www.mariouniverse.com/images/maps/n64/mk/choco-mountain.jpg'),
    'LR': TrackData('http://www.mariouniverse.com/images/maps/n64/mk/luigi-raceway.jpg'),
    'MR': TrackData('http://www.mariouniverse.com/images/maps/n64/mk/mario-raceway.jpg')
}

im = Image.open(requests.get(TRACK_DATA['CM'].url, stream=True).raw)

play_positions = []
search_trajectories = []
search_trajectory = []

for line in open('choco.log', 'r'):
    if line.startswith("Play Position:"):
        pos = tuple(map(float, line.strip().split('\t')[1:]))
        play_positions.append(pos)

    if line.startswith("Search Position:"):
        pos = tuple(map(float, line.strip().split('\t')[1:]))
        search_trajectory.append(pos)
    else:
        if len(search_trajectory) > 0:
            search_trajectories.append(search_trajectory)
            search_trajectory = []

IMG_START = (652, 518)
START_POS = (-5.99742794036865, -675.072143554688, 47.0080032348633)
POINT_RADIUS = 6
LINE_WIDTH = 4

draw = ImageDraw.Draw(im)
SCALE = (0.67, 0.65)
def project(point):
    return (IMG_START[0] + (point[0] - START_POS[0])*SCALE[0], IMG_START[1]  + (point[1] - START_POS[1])*SCALE[1])

prev_point = play_positions[0]
proj = project(prev_point)
draw.ellipse([(proj[0] - POINT_RADIUS, proj[1] - POINT_RADIUS), (proj[0] + POINT_RADIUS, proj[1] + POINT_RADIUS)], fill=(0,0,255,255))
for point in play_positions[1:]:
    draw.line([project(prev_point), project(point)], width = LINE_WIDTH, fill=(0,0,255,255))
    prev_point = point

for traj in search_trajectories:
    prev_point = traj[0]

    proj = project(prev_point)
    draw.ellipse([(proj[0] - POINT_RADIUS, proj[1] - POINT_RADIUS), (proj[0] + POINT_RADIUS, proj[1] + POINT_RADIUS)], fill=(0,255,0,255))

    for point in traj[1:]:
        draw.line([project(prev_point), project(point)], width = LINE_WIDTH, fill=(0,255,0,255))
        prev_point = point

im.save("composite.png")
im.show()
