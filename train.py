import glob
import os
import hashlib

from PIL import Image

import numpy as np
from keras.models import Sequential
from keras.layers import Dense, Dropout, Flatten
from keras.layers import Conv2D
from keras import optimizers
from keras import backend as K
from keras.callbacks import ModelCheckpoint

import matplotlib.pyplot as plt

OUT_SHAPE = 1

INPUT_WIDTH = 200
INPUT_HEIGHT = 66
INPUT_CHANNELS = 3

VALIDATION_SPLIT = 0.1

def customized_loss(y_true, y_pred, loss='euclidean'):
    # Simply a mean squared error that penalizes large joystick summed values
    if loss == 'L2':
        L2_norm_cost = 0.001
        val = K.mean(K.square((y_pred - y_true)), axis=-1) \
            + K.sum(K.square(y_pred), axis=-1) / 2 * L2_norm_cost
    # euclidean distance loss
    elif loss == 'euclidean':
        val = K.sqrt(K.sum(K.square(y_pred - y_true), axis=-1))
    return val


def create_model(keep_prob=0.8):
    model = Sequential()

    # NVIDIA's model
    model.add(Conv2D(24, kernel_size=(5, 5), strides=(2, 2), activation='relu',
                     input_shape=(INPUT_HEIGHT, INPUT_WIDTH, INPUT_CHANNELS)))
    model.add(Conv2D(36, kernel_size=(5, 5), strides=(2, 2), activation='relu'))
    model.add(Conv2D(48, kernel_size=(5, 5), strides=(2, 2), activation='relu'))
    model.add(Conv2D(64, kernel_size=(3, 3), activation='relu'))
    model.add(Conv2D(64, kernel_size=(3, 3), activation='relu'))
    model.add(Flatten())
    model.add(Dense(1164, activation='relu'))
    drop_out = 1 - keep_prob
    model.add(Dropout(drop_out))
    model.add(Dense(100, activation='relu'))
    model.add(Dropout(drop_out))
    model.add(Dense(50, activation='relu'))
    model.add(Dropout(drop_out))
    model.add(Dense(10, activation='relu'))
    model.add(Dropout(drop_out))
    model.add(Dense(OUT_SHAPE, activation='softsign'))

    return model


def load_training_data():
    X_train, y_train = [], []
    X_val, y_val = [], []

    for recording in os.listdir('recordings'):
        filenames = list(glob.iglob('recordings/{}/*.png'.format(recording)))
        filenames.sort(key=lambda f: int(os.path.basename(f)[:-4]))

        steering = [float(line) for line in open(
            ("recordings/{}/steering.txt").format(recording)).read().splitlines()]

        for file, steer in zip(filenames, steering):
            name_hash = hashlib.md5(file.encode('utf-8')).digest()
            prob = int.from_bytes(name_hash[:2], byteorder='big') / 2**16

            im = Image.open(file).resize((INPUT_WIDTH, INPUT_HEIGHT))
            im_arr = np.frombuffer(im.tobytes(), dtype=np.uint8)
            im_arr = im_arr.reshape((INPUT_HEIGHT, INPUT_WIDTH, INPUT_CHANNELS))

            if prob > VALIDATION_SPLIT:
                X_train.append(im_arr)
                y_train.append(steer)
            else:
                X_val.append(im_arr)
                y_val.append(steer)

    assert len(X_train) == len(y_train)
    assert len(X_val) == len(y_val)

    return np.asarray(X_train), \
        np.asarray(y_train).reshape((len(y_train), 1)), \
        np.asarray(X_val), \
        np.asarray(y_val).reshape((len(y_val), 1))


if __name__ == '__main__':
    # Load Training Data
    X_train, y_train, X_val, y_val = load_training_data()

    print(X_train.shape[0], 'training samples.')
    print(X_val.shape[0], 'validation samples.')

    # Training loop variables
    epochs = 100
    batch_size = 50

    model = create_model()

    model.compile(loss=customized_loss, optimizer=optimizers.adam())
    checkpointer = ModelCheckpoint(
        monitor='val_loss', filepath="weights.hdf5", verbose=1, save_best_only=True, mode='min')
    model.fit(X_train, y_train, batch_size=batch_size, epochs=epochs,
              shuffle=True, validation_data=(X_val, y_val), callbacks=[checkpointer])
