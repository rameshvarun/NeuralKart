import sys, time, logging, os

import numpy as np
from PIL import Image
from socketserver import TCPServer, StreamRequestHandler

logging.basicConfig(filename='predict-server.log',level=logging.DEBUG)
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

def handle_exception(exc_type, exc_value, exc_traceback):
    if issubclass(exc_type, KeyboardInterrupt):
        sys.__excepthook__(exc_type, exc_value, exc_traceback)
        return
    logger.error("Uncaught exception", exc_info=(exc_type, exc_value, exc_traceback))
sys.excepthook = handle_exception

sys.stderr = open(os.devnull, "w")
from train import create_model, INPUT_WIDTH, INPUT_HEIGHT, INPUT_CHANNELS

class TCPHandler(StreamRequestHandler):
    def handle(self):
        message = str(self.rfile.readline().strip(),'utf-8')
        logger.debug(message)
        if message == "QUIT":
            logger.info("Server shutting down...")
            self.shutdown()

        if message.startswith("PREDICT:"):
            im = Image.open(message[8:])
            im = im.resize((INPUT_WIDTH, INPUT_HEIGHT))
            im_arr = np.frombuffer(im.tobytes(), dtype=np.uint8)
            im_arr = im_arr.reshape((INPUT_HEIGHT, INPUT_WIDTH, INPUT_CHANNELS))
            im_arr = np.expand_dims(im_arr, axis=0)

            prediction = model.predict(im_arr, batch_size=1)[0]
            self.wfile.write(str(prediction))
            self.wfile.write("\n")

if __name__ == "__main__":
    logger.info("Loading model...")
    model = create_model(keep_prob=1)
    model.load_weights('weights.hdf5')

    logger.info("Starting server...")
    server = TCPServer(('0.0.0.0', 0), TCPHandler)
    server.model - model

    print("Listening on Port: {}".format(server.server_address[1]))
    sys.stdout.flush()
    server.serve_forever()
