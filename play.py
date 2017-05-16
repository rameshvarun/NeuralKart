import shutil
import os
import subprocess
import argparse
import time
import sys
import uuid
import threading

import numpy as np

from train import create_model, INPUT_WIDTH, INPUT_HEIGHT, INPUT_CHANNELS

from colorama import Fore, Style, init
init()

MANUAL_OVERRIDE_DEAD_ZONE = 0.1

from lib import vjoy
from lib.capture import WindowCapture
from lib.utils import MovingAverage, mkdirp


class OverrideThread (threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)
        self.recording_id = "overrides-" + str(uuid.uuid4())
        mkdirp('recordings/')
        mkdirp('recordings/' + self.recording_id + '/')
        self.steering_file = open(
            'recordings/{}/steering.txt'.format(self.recording_id), 'w')
        self.overriding_steer = None
        self.running = True
        self.override_frame = 1

    def run(self):
        print("Starting override thread...")
        from lib import ujoy

        while self.running:
            ujoy.process_events()
            steer = ujoy.get_axis(ujoy.AXIS_X_HORIZONTAL)
            if abs(steer) > MANUAL_OVERRIDE_DEAD_ZONE:
                print(Fore.YELLOW + "Manual override:", steer, Style.RESET_ALL)
                self.overriding_steer = steer
                vjoy.set_steering(steer)
            else:
                self.overriding_steer = None

        self.steering_file.close()
        print("Exiting override thread...")

    def save_frame(self, image, steer):
        self.steering_file.write(str(steer))
        self.steering_file.write('\n')
        im.save("recordings/{}/{}.png".format(self.recording_id, self.override_frame))
        self.override_frame += 1

    def stop(self):
        self.running = False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('--allow-override', action='store_true',
                        help='Allow for manual overrides by the user.',
                        dest='override')
    args = parser.parse_args()

    if args.override:
        override_thread = OverrideThread()
        override_thread.start()

    mupen = shutil.which("mupen64plus-ui-console.exe")
    if mupen is None:
        print("Mupen64Plus is not in the path.")
        sys.exit(1)

    if not os.path.isfile('mariokart64.n64'):
        print("Rom is not in working directory")
        sys.exit(1)

    mupen_dir = os.path.dirname(mupen)
    emulator = subprocess.Popen(["mupen64plus-ui-console.exe",
                                 "--savestate", "states/luigis-raceway.st0",
                                 "--resolution", "320x240",
                                 "--plugindir", mupen_dir,
                                 "--datadir", mupen_dir,
                                 "--configdir", ".",
                                 'mariokart64.n64'])

    model = create_model(keep_prob=1)
    model.load_weights('weights.hdf5')

    time.sleep(2)

    capture = WindowCapture(u"Mupen64Plus OpenGL Video Plugin by Rice v2.5.0")
    fps = MovingAverage(0.9)

    vjoy.set_acceleration(1)

    while emulator.poll() == None:
        frame_start_time = time.time()
        im = capture.capture()

        if args.override:
            overriding_steer = override_thread.overriding_steer
            if overriding_steer != None:
                override_thread.save_frame(im, overriding_steer)
                continue

        im = im.resize((INPUT_WIDTH, INPUT_HEIGHT))
        im_arr = np.frombuffer(im.tobytes(), dtype=np.uint8)
        im_arr = im_arr.reshape((INPUT_HEIGHT, INPUT_WIDTH, INPUT_CHANNELS))
        im_arr = np.expand_dims(im_arr, axis=0)

        prediction = model.predict(im_arr, batch_size=1)[0]
        vjoy.set_steering(prediction[0])
        print(prediction)

        frame_end_time = time.time()
        fps.observe(1 / (frame_end_time - frame_start_time))
        print("Prediction FPS:", fps.get())

    if args.override:
        override_thread.stop()
        override_thread.join()

    vjoy.set_steering(0)
    vjoy.set_acceleration(0)
