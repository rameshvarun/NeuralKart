import sys, time, logging, os, argparse

import numpy as np
from PIL import Image
from socketserver import TCPServer, StreamRequestHandler

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

from train import create_model, INPUT_WIDTH, INPUT_HEIGHT, INPUT_CHANNELS, INPUT_TIMESTEPS

WAIT_FRAMES = 5
SNAPSHOT_INTERVAL = 30
FRAME_DISTANCE = int(SNAPSHOT_INTERVAL / WAIT_FRAMES)

class TCPHandler(StreamRequestHandler):
    def handle(self):
        logger.info("Reloading model weights...")
        model.load_weights('weights.hdf5')

        im_arr_total = np.zeros((INPUT_HEIGHT, INPUT_WIDTH,
                                 INPUT_CHANNELS * INPUT_TIMESTEPS * FRAME_DISTANCE))

        logger.info("Handling a new connection...")
        for line in self.rfile:
            message = str(line.strip(),'utf-8')
            logger.debug(message)

            if message.startswith("PREDICT:"):
                im = Image.open(message[8:])
                im = im.resize((INPUT_WIDTH, INPUT_HEIGHT))
                im_arr = np.frombuffer(im.tobytes(), dtype=np.uint8)
                im_arr = im_arr.reshape((INPUT_HEIGHT, INPUT_WIDTH, INPUT_CHANNELS))

                # Move one timestep forward
                im_arr_total = np.concatenate((im_arr, im_arr_total[:,:,:-INPUT_CHANNELS]), axis=2)
                prediction_arr = np.zeros((INPUT_HEIGHT, INPUT_WIDTH,
                                           INPUT_CHANNELS * INPUT_TIMESTEPS))

                for i in range(INPUT_TIMESTEPS):
                    prediction_arr[:,:,i*INPUT_CHANNELS:(i+1)*INPUT_CHANNELS] \
                        = im_arr_total[:,:,
                                       i*FRAME_DISTANCE*INPUT_CHANNELS:
                                       i*FRAME_DISTANCE*INPUT_CHANNELS + INPUT_CHANNELS]

                prediction = model.predict(np.expand_dims(prediction_arr, axis=0), batch_size=1)[0]
                self.wfile.write((str(prediction[0]) + "\n").encode('utf-8'))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Start a prediction server that other apps will call into.')
    parser.add_argument('-p', '--port', type=int, help='Port number', default=36296)
    parser.add_argument('-c', '--cpu', action='store_true', help='Force Tensorflow to use the CPU.', default=False)
    args = parser.parse_args()

    if args.cpu:
        os.environ["CUDA_DEVICE_ORDER"] = "PCI_BUS_ID"
        os.environ["CUDA_VISIBLE_DEVICES"] = "-1"

    logger.info("Loading model...")
    model = create_model(keep_prob=1)
    model.load_weights('weights.hdf5')

    logger.info("Starting server...")
    server = TCPServer(('0.0.0.0', args.port), TCPHandler)

    print("Listening on Port: {}".format(server.server_address[1]))
    sys.stdout.flush()
    server.serve_forever()
