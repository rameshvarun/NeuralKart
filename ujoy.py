import pygame

# Get the user joystick, which will be mapped to the virtual joystick.
pygame.joystick.init()
joysticks = [pygame.joystick.Joystick(x) for x in range(pygame.joystick.get_count())]
try:
    joy = [j for j in joysticks if j.get_name() != "vJoy Device"][0]
    joy.init()
except IndexError:
    raise Exception("No joystick other than the vJoystick found.")

def get_axis(axis_number):
    return joy.get_axis(axis_number)


import time

while True:
    time.sleep(1)
    print(get_axis(1))