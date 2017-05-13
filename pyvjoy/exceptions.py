
class vJoyException(Exception):
	pass

class vJoyNotEnabledException(vJoyException):
	pass

class vJoyFailedToAcquireException(vJoyException):
	pass

class vJoyFailedToRelinquishException(vJoyException):
	pass


class vJoyButtonException(vJoyException):
	pass

class vJoyDriverMismatchException(vJoyException):
	pass

class vJoyInvalidAxisException(vJoyException):
	pass

class vJoyInvalidPovValueException(vJoyException):
	pass

class vJoyInvalidPovIDException(vJoyException):
	pass


