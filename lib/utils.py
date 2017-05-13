import os
import errno

class MovingAverage:
  """Keep track of an exponentially weighted moving average. Used for FPS."""
   def __init__(self, alpha, initial=0):
       self.value = initial
       self.alpha = alpha
   def observe(self, value):
       self.value = self.alpha * value + (1 - self.alpha) * self.value
   def get(self):
       return self.value

def mkdirp(dirname):
    try: os.mkdir(dirname)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(dirname): pass
        else: raise exc
