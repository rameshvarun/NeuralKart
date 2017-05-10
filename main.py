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

    def preloop(self):
        print("Entering binding mode...")

class RecordMode(cmd.Cmd):
    prompt = '(mode-record) '
    def do_accelerate(self, line):
        vjoy.set_acceleration(0.25)
    def do_stop(self, line):
        vjoy.set_acceleration(0)

class MainMode(cmd.Cmd):
    prompt = '(mode-main) '
    def do_mode(self, line):
        BindingMode().cmdloop()
    def do_record(self, line):
        RecordMode().cmdloop()

if __name__ == '__main__':
    MainMode().cmdloop()






from capture import WindowCapture

'''capture = WindowCapture("DiRT Rally")

for i in range(100):
    im = capture.capture()
    im.save("images/{}.png".format(i))
    print(i)'''