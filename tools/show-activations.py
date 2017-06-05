from PIL import Image
import numpy as np
import matplotlib.pyplot as plt
import easygui
import keras.backend as K

import itertools
itertools.izip = zip

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

def get_activations(model, model_inputs, print_shape_only=False, layer_name=None):
    import keras.backend as K
    print('----- activations -----')
    activations = []
    inp = model.input

    model_multi_inputs_cond = True
    if not isinstance(inp, list):
        # only one input! let's wrap it in a list.
        inp = [inp]
        model_multi_inputs_cond = False

    outputs = [layer.output for layer in model.layers if
               layer.name == layer_name or layer_name is None]  # all layer outputs

    funcs = [K.function(inp + [K.learning_phase()], [out]) for out in outputs]  # evaluation functions

    if model_multi_inputs_cond:
        list_inputs = []
        list_inputs.extend(model_inputs)
        list_inputs.append(1.)
    else:
        list_inputs = [model_inputs, 1.]

    # Learning phase. 1 = Test mode (no dropout or batch normalization)
    # layer_outputs = [func([model_inputs, 1.])[0] for func in funcs]
    layer_outputs = [func(list_inputs)[0] for func in funcs]
    for layer_activations in layer_outputs:
        activations.append(layer_activations)
        if print_shape_only:
            print(layer_activations.shape)
        else:
            print(layer_activations)
    return activations

im = prepare_image(Image.open(easygui.fileopenbox()))
im_arr = np.expand_dims(im, axis=0)
for activation in get_activations(model, im_arr, print_shape_only=True, layer_name="first_layer"):
    activations = [activation[0, :, :, i] for i in range(24)]
    im = np.vstack((
        np.hstack(activations[:3]), np.hstack(activations[3:6]),
        np.hstack(activations[6:9]), np.hstack(activations[9:12]),
        np.hstack(activations[12:15]), np.hstack(activations[15:18]),
        np.hstack(activations[18:21]), np.hstack(activations[21:24])
    ))
    im = np.expand_dims(im, axis=2)
    plt.imshow(np.concatenate((im, im, im), axis=2))
    plt.axis('off')
    plt.show()
