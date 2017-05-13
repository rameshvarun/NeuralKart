from PIL import ImageGrab
from ctypes import *

user32, gdi32 = windll.user32, windll.gdi32
user32.SetProcessDPIAware()

class RECT(Structure):
    _fields_ = [('left', c_long), ('top', c_long), ('right', c_long), ('bottom', c_long)]
    def __str__(self):
        return "({}-{}, {}-{})".format(self.left, self.right, self.top, self.bottom)

class POINT(Structure):
    _fields_ = [("x", c_long), ("y", c_long)]
    def __str__(self):
        return "({}, {})".format(self.x, self.y)
    def clear(self):
        self.x, self.y = 0, 0

class WindowCapture:
    def __init__(self, title):
        self.hwnd = user32.FindWindowW(None, title)
        if self.hwnd == 0:
            raise Exception("Window with title \"{}\" not found.".format(title))
        self.topleft = POINT()
        self.clientrect = RECT()

    def capture(self):
        self.topleft.clear()
        user32.GetClientRect(self.hwnd, byref(self.clientrect))
        user32.ClientToScreen(self.hwnd, byref(self.topleft))

        return ImageGrab.grab((self.topleft.x, self.topleft.y,
            self.topleft.x + self.clientrect.right,
            self.topleft.y + self.clientrect.bottom))

        return ImageGrab.grab()

if __name__ == '__main__':
    capture = WindowCapture(u"Mupen64Plus OpenGL Video Plugin by Rice v2.5.0")

    for i in range(100):
        im = capture.capture()
        im.save("images/{}.png".format(i))
        print(i)
