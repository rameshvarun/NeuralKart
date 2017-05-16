import argparse
import os
import sys
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
import matplotlib.animation as animation

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Replay a race with steering shown.')
    parser.add_argument('recording')
    args = parser.parse_args()

    recording = args.recording
    if not os.path.isdir(recording):
        print("{} is not a folder.".format(recording))
        sys.exit(1)

    steering = [float(line) for line in open(
        ("{}/steering.txt").format(recording)).read().splitlines()]

    plt.title("Recording: {}".format(recording))
    plt.plot(steering)
    plt.show()
