import shutil, os, subprocess, uuid

from lib import vjoy, ujoy
from lib.capture import WindowCapture
from lib.utils import *

def start_recording():
    print("Starting recording. Press start to stop recording.")
    recording_id = str(uuid.uuid4())

    mkdirp('recordings/')
    mkdirp('recordings/' + recording_id + '/')

    vjoy.set_acceleration(1)
    capture = WindowCapture(u"Mupen64Plus OpenGL Video Plugin by Rice v2.5.0")

    steering = open('recordings/{}/steering.txt'.format(recording_id), 'w')

    frame = 1
    while True:
        ujoy.process_events()
        if ujoy.get_button_down(ujoy.BUTTON_START):
            break
        steer = ujoy.get_axis(ujoy.AXIS_X_HORIZONTAL)
        vjoy.set_steering(steer)

        im = capture.capture()
        steering.write(str(steer))
        steering.write('\n')
        im.save("recordings/{}/{}.png".format(recording_id, frame))
        frame += 1

    print("Stopping recording.")
    vjoy.set_acceleration(0)
    vjoy.set_steering(0)
    steering.close()

if __name__ == "__main__":
    mupen = shutil.which("mupen64plus-ui-console.exe")
    mupen_dir = os.path.dirname(mupen)

    if mupen is None:
        print("Mupen64Plus is not in the path.")
    if not os.path.isfile('mariokart64.n64'):
        print("Rom is not in working directory")

    emulator = subprocess.Popen(["mupen64plus-ui-console.exe",
        "--savestate", "states/luigis-raceway.st0",
        "--resolution", "320x240",
        "--plugindir", mupen_dir,
        "--datadir", mupen_dir,
        "--configdir", ".",
        'mariokart64.n64'])

    print("Press start to initiate a recording...")
    while True:
        ujoy.process_events()
        if ujoy.get_button_down(ujoy.BUTTON_START):
            start_recording()
            break

    emulator.terminate()
