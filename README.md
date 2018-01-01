# NeuralKart - A Real-time Mario Kart AI using CNNs, Offline Search, and DAGGER

<p align="center">
  <img src="./demo.gif"/>
</p>

- [Explanation Video](https://www.youtube.com/watch?v=Eo07BAsyQ24)
- [Videos of Runs](https://www.youtube.com/playlist?list=PLSHD7WB3aI6Ks04Z7kS_UskyG_uY02EzY)
- [Class Poster](https://drive.google.com/open?id=0B7KSCOuXHAaQcE8wWXZmRVhjX2c)
- [Class Writeup](https://drive.google.com/open?id=0B7KSCOuXHAaQb1FtY2wzUS1yZ0E)
- Blog Post (Coming Soon)

## Set-up

The project has only been tested on Windows, but might work in other systems with adjustments.

### Install Python Dependencies
The following Python dependencies need to be installed.

- Tensorflow
- Keras
- Pillow
- mkdir_p

### Get BizHawk (1.12.2)

Our scripts are all written for the BizHawk emulator (tested in version 1.12.2), which has embedded Lua scripting. To get BizHawk you first need to install the prerequisites - https://github.com/TASVideos/BizHawk-Prereqs/releases. Then you can download BizHawk and unzip it to any directory - https://github.com/TASVideos/BizHawk/releases/

### (Optional) Download Our Weights and Recordings

- [Save States](https://drive.google.com/open?id=0B7KSCOuXHAaQaGNDWEI2MlBSRDQ)
- [Weights](https://drive.google.com/open?id=0B7KSCOuXHAaQQUY3V2dqQjNNbXM)
- [Recordings](https://drive.google.com/open?id=0B7KSCOuXHAaQSHFLRFpCQTBVemM)

## Usage Instructions

## Other Projects + Links

- [TensorKart](https://github.com/kevinhughes27/TensorKart) - The first MarioKart deep learning project, which we started from as our baseline.
- [Deep Learning for Real-Time Atari Game Play Using Offline Monte-Carlo Tree Search Planning](https://papers.nips.cc/paper/5421-deep-learning-for-real-time-atari-game-play-using-offline-monte-carlo-tree-search-planning.pdf) - The idea for using a search-based AI for teaching the Convnet AI came from this paper.
- [A Reduction of Imitation Learning and Structured Prediction to No-Regret Online Learning](https://www.cs.cmu.edu/~sross1/publications/Ross-AIStats11-NoRegret.pdf) - The DAGGER algorithm was first introduced in this paper.
- [MarioKart 64 NEAT](https://www.youtube.com/watch?v=tmltm0ZHkHw) - This AI uses the NEAT algorithm to genetically evolve a shallow neural network
- [weatherton/BizHawkMarioKart64](https://github.com/weatherton/BizHawkMarioKart64) - Some MarioKart 64 scripts which we used as a reference for memory locations.
