import pyvjoy
vjoy = pyvjoy.VJoyDevice(1)

def set_steering(value):
    if value > 1 or value < -1:
        raise ValueError("value was {} when it must be between -1 and 1.".format(value))
    interp = (value + 1)/2
    vjoy.set_axis(pyvjoy.HID_USAGE_X, int((1 - interp)*0x1 + interp*0x8000))

def set_acceleration(value):
    if value > 1 or value < 0:
        raise ValueError("value was {} when it must be between -1 and 1.".format(value))
    interp = (value + 1)/2
    vjoy.set_axis(pyvjoy.HID_USAGE_Y, int((1 - interp)*0x1 + interp*0x8000))

# Set steering and acceleration to zero upon loading.
set_steering(0)
set_acceleration(0)