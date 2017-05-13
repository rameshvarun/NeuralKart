DLL_FILENAME = "vJoyInterface.dll"

HID_USAGE_X = 0x30
HID_USAGE_Y	= 0x31
HID_USAGE_Z	= 0x32
HID_USAGE_RX = 0x33
HID_USAGE_RY = 0x34
HID_USAGE_RZ = 0x35
HID_USAGE_SL0 = 0x36
HID_USAGE_SL1 = 0x37
HID_USAGE_WHL = 0x38
HID_USAGE_POV = 0x39

#for validity checking
HID_USAGE_LOW = HID_USAGE_X
HID_USAGE_HIGH = HID_USAGE_POV


VJD_STAT_OWN = 0	# The  vJoy Device is owned by this application.
VJD_STAT_FREE = 1 	# The  vJoy Device is NOT owned by any application (including this one).
VJD_STAT_BUSY = 2   # The  vJoy Device is owned by another application. It cannot be acquired by this application.
VJD_STAT_MISS = 3 	# The  vJoy Device is missing. It either does not exist or the driver is down.
VJD_STAT_UNKN = 4 	# Unknown

