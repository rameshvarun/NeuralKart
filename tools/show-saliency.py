import os.path, sys
sys.path.append(os.path.join(os.path.dirname(os.path.realpath(__file__)), os.pardir))

from PIL import Image
import numpy as np
import matplotlib.pyplot as plt
import easygui
import keras.backend as K

import itertools; itertools.izip = zip

def prepare_image(im):
    im = im.resize((INPUT_WIDTH, INPUT_HEIGHT))
    im_arr = np.frombuffer(im.tobytes(), dtype=np.uint8)
    im_arr = im_arr.reshape((INPUT_HEIGHT, INPUT_WIDTH, INPUT_CHANNELS))
    return im_arr

from train import create_model, INPUT_WIDTH, INPUT_HEIGHT, INPUT_CHANNELS

from vis.utils import utils
from vis.visualization import visualize_saliency, visualize_cam, get_num_filters, visualize_activation

model = create_model(keep_prob=1)
model.load_weights('weights/lr.hdf5')

# The name of the layer we want to visualize
# (see model definition in vggnet.py)
layer_name = 'predictions'
layer_idx = [idx for idx, layer in enumerate(model.layers) if layer.name == layer_name][0]

im = prepare_image(Image.open(easygui.fileopenbox()))

saliency = visualize_saliency(model, layer_idx, [0], im, alpha=0.7)
cam = visualize_cam(model, layer_idx, [0], im, alpha=0.7)

plt.figure()
plt.subplot(211)
plt.axis('off')
plt.imshow(saliency)
plt.title('Saliency Map')

plt.subplot(212)
plt.axis('off')
plt.imshow(cam)
plt.title('Class Activation Map')

plt.show()
