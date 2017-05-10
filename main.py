import time
import sys
import cmd

import vjoy # The virtual joystick
import ujoy # The user joystick

def countdown(num):
    for i in range(num, 0, -1):
        print(str(i) + "...")
        time.sleep(1)

class BindingMode(cmd.Cmd):
    prompt = '(mode-binding) '

    def do_acceleration(self, line):
        print("Turning on acceleration in 4 seconds...")
        countdown(4)
        print("Turning on acceleration for 3 seconds...")
        vjoy.set_acceleration(0.75)
        countdown(3)
        print("Turning off acceleration...")
        vjoy.set_acceleration(0)

    def do_right(self, line):
        print("Turning on right in 4 seconds...")
        countdown(4)
        print("Turning on right for 3 seconds...")
        vjoy.set_steering(0.75)
        countdown(3)
        print("Turning off right...")
        vjoy.set_steering(0)

    def do_left(self, line):
        print("Turning on left in 4 seconds...")
        countdown(4)
        print("Turning on left for 3 seconds...")
        vjoy.set_steering(-0.75)
        countdown(3)
        print("Turning off left...")
        vjoy.set_steering(0)

    def preloop(self):
        print("Entering binding mode...")

def record_mode():
    print("Entering record mode...")
    print("Press start to initiate a recording...")
    while True:
        ujoy.process_events()
        if ujoy.get_button_down(ujoy.BUTTON_START):
            start_recording()

def start_recording():
    print("Starting recording. Press start to stop recording.")
    vjoy.set_acceleration(0.6)
    while True:
        ujoy.process_events()
        if ujoy.get_button_down(ujoy.BUTTON_START):
            break
        vjoy.set_steering(ujoy.get_axis(ujoy.AXIS_X_HORIZONTAL))
    print("Stopping recording.")
    vjoy.set_acceleration(0)
    vjoy.set_steering(0)

class MainMode(cmd.Cmd):
    prompt = '(mode-main) '
    def do_binding(self, line):
        BindingMode().cmdloop()
    def do_recording(self, line):
        record_mode()

if __name__ == '__main__':
    MainMode().cmdloop()






from capture import WindowCapture

'''capture = WindowCapture("DiRT Rally")

for i in range(100):
    im = capture.capture()
    im.save("images/{}.png".format(i))
    print(i)'''