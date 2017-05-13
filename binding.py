import cmd, time
from lib import vjoy

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
        vjoy.set_acceleration(1)
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

if __name__ == "__main__":
    BindingMode().cmdloop()
