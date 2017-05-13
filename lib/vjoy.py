"""
This module wraps interactions with the "virtual joystick" - which is what the
game actually sees as input.
"""

import pyvjoy
vjoy = pyvjoy.VJoyDevice(1)

def set_steering(value):
    global steering
    steering = value

    if value > 1 or value < -1:
        raise ValueError("value was {} when it must be between -1 and 1.".format(value))
    interp = (value + 1)/2
    vjoy.set_axis(pyvjoy.HID_USAGE_X, int((1 - interp)*0x1 + interp*0x8000))

def set_acceleration(on):
    vjoy.set_button(1, on)

# Set steering and acceleration to zero upon loading.
set_steering(0)
set_acceleration(0)
