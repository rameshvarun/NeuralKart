import argparse, os, sys
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
import matplotlib.animation as animation

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Replay a race with steering shown.')
    parser.add_argument('recording')
    args = parser.parse_args()

    recording = args.recording
    if not os.path.isdir(recording):
        print("{} is not a folder.".format(recording))
        sys.exit(1)

    steering = [float(line) for line in open(("{}/steering.txt").format(recording)).read().splitlines()]

    fig, ax = plt.subplots(2)

    ax[1].plot(steering)
    ax[1].set_ylim(-1, 1)

    def animate(frameno):
        if frameno > 0:
            ax[0].imshow(mpimg.imread("{}/{}.png".format(recording, frameno)))
            ax[1].set_xlim(0, frameno)

    plt.title("Recording: {}".format(recording))
    ani = animation.FuncAnimation(fig, animate, blit=False, interval=50, repeat=True)
    plt.show()
