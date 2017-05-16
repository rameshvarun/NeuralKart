import shutil, os, subprocess

import time

import numpy as np

from train import create_model, INPUT_WIDTH, INPUT_HEIGHT, INPUT_CHANNELS

from lib import vjoy
from lib.capture import WindowCapture

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

    model = create_model(keep_prob=1)
    model.load_weights('checkpoints/model_weights.hdf5')

    time.sleep(2)
    capture = WindowCapture(u"Mupen64Plus OpenGL Video Plugin by Rice v2.5.0")

    while emulator.poll() == None:
        im = capture.capture().resize((INPUT_WIDTH, INPUT_HEIGHT))
        im_arr = np.frombuffer(im.tobytes(), dtype=np.uint8)
        im_arr = im_arr.reshape((INPUT_HEIGHT, INPUT_WIDTH, INPUT_CHANNELS))
        im_arr = np.expand_dims(im_arr, axis=0)

        prediction = model.predict(im_arr, batch_size=1)[0]
        print(prediction)

        vjoy.set_steering(prediction[0])
        vjoy.set_acceleration(1)

    vjoy.set_steering(0)
    vjoy.set_acceleration(0)
