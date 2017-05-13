import os
import errno

def mkdirp(dirname):
    try: os.mkdir(dirname)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(dirname): pass
        else: raise exc
