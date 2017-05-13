import pygame

pygame.joystick.init()
pygame.display.init()

# Get the user joystick, which will be mapped to the virtual joystick.
joysticks = [pygame.joystick.Joystick(x) for x in range(pygame.joystick.get_count())]

try:
    joy = [j for j in joysticks if j.get_name() != "vJoy Device"][0]
except IndexError:
    raise Exception("No joystick other than the vJoystick found.")

joy.init()

NUM_BUTTONS = joy.get_numbuttons()
NUM_AXES = joy.get_numaxes()

AXIS_X_HORIZONTAL = 0
AXIS_X_VERTICAL = 1
AXIS_TRIGGERS = 2

def get_axis(axis_number):
    return joy.get_axis(axis_number)

BUTTON_A = 0
BUTTON_B = 1
BUTTON_X = 2
BUTTON_Y = 3
BUTTON_START = 7

def get_button(button):
    return joy.get_button(button)

def get_button_down(button):
    return get_button(button) and not previous_state[button]

def get_button_up(button):
    return not get_button(button) and previous_state[button]

def process_events():
    global previous_state
    previous_state = [joy.get_button(i) for i in range(NUM_BUTTONS)]
    pygame.event.pump()

if __name__ == "__main__":
    import time
    while True:
        time.sleep(0.5)
        process_events()
        print([joy.get_button(i) for i in range(NUM_BUTTONS)],
              ["{:.2f}".format(joy.get_axis(i)) for i in range(NUM_AXES)])