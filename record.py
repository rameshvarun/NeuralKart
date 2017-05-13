import shutil, os, subprocess
from lib import capture, vjoy, ujoy

if __name__ == "__main__":
    mupen = shutil.which("mupen64plus-ui-console.exe")
    mupen_dir = os.path.dirname(mupen)

    if mupen is None:
        print("Mupen64Plus is not in the path.")
    if not os.path.isfile('mariokart64.n64'):
        print("Rom is not in working directory")

    subprocess.call(["mupen64plus-ui-console.exe",
        "--savestate", "states/luigis-raceway.st0",
        "--resolution", "320x240",
        "--plugindir", mupen_dir,
        "--datadir", mupen_dir,
        'mariokart64.n64'])
