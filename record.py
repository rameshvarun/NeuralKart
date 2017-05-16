import shutil
import os
import subprocess
import uuid
import threading
import time

from lib import vjoy, ujoy
from lib.capture import WindowCapture
from lib.utils import *


class RecordThread (threading.Thread):
    def __init__(self, capture, recording_id, steering_file):
        threading.Thread.__init__(self)
        self.fps = MovingAverage(0.9)
        self.capture = capture
        self.recording_id = recording_id
        self.steering_file = steering_file
        self.exit = False
        self.steer = 0

    def run(self):
        print("Starting record thread...")
        frame = 1
        while not self.exit:
            frame_start_time = time.time()

            im = self.capture.capture()
            self.steering_file.write(str(self.steer))
            self.steering_file.write('\n')
            im.save("recordings/{}/{}.png".format(self.recording_id, frame))
            frame += 1

            frame_end_time = time.time()
            self.fps.observe(1 / (frame_end_time - frame_start_time))
            if frame % 10:
                print("Recording FPS:", self.fps.get())

        self.steering_file.close()
        print("Exiting record thread...")

    def stop(self):
        self.exit = True


def print_time(threadName, delay, counter):
    while counter:
        if exitFlag:
            threadName.exit()
        time.sleep(delay)
        print("%s: %s" % (threadName, time.ctime(time.time())))
        counter -= 1


def start_recording():
    print("Starting recording. Press start to stop recording.")
    recording_id = str(uuid.uuid4())

    mkdirp('recordings/')
    mkdirp('recordings/' + recording_id + '/')

    vjoy.set_acceleration(1)
    capture = WindowCapture(u"Mupen64Plus OpenGL Video Plugin by Rice v2.5.0")

    steering_file = open(
        'recordings/{}/steering.txt'.format(recording_id), 'w')

    record_thread = RecordThread(capture, recording_id, steering_file)
    record_thread.start()

    while True:
        ujoy.process_events()
        if ujoy.get_button_down(ujoy.BUTTON_START):
            break
        steer = ujoy.get_axis(ujoy.AXIS_X_HORIZONTAL)
        record_thread.steer = steer
        vjoy.set_steering(steer)

    record_thread.stop()

    print("Stopping recording.")
    vjoy.set_acceleration(0)
    vjoy.set_steering(0)


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
