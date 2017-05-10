import cmd
import sys

from PIL import Image, ImageGrab

from ctypes import *
user32, gdi32 = windll.user32, windll.gdi32

CF_BITMAP = 2
SM_CXVIRTUALSCREEN = 78
SM_CYVIRTUALSCREEN = 79
SRCCOPY = 13369376


class WindowCapture:
    def __init__(self, title):
        self.hdc = user32.GetDC(None)
        self.hDest = gdi32.CreateCompatibleDC(self.hdc)

        self.width = user32.GetSystemMetrics(SM_CXVIRTUALSCREEN)
        self.height = user32.GetSystemMetrics(SM_CYVIRTUALSCREEN)

        self.bitmap = gdi32.CreateCompatibleBitmap(self.hdc, self.width, self.height);
        gdi32.SelectObject(self.hDest, self.bitmap)

    def capture(self):
        gdi32.BitBlt(self.hDest, 0, 0, self.width, self.height, self.hdc, 0, 0,  SRCCOPY)
        user32.OpenClipboard(None)
        user32.EmptyClipboard();
        user32.SetClipboardData(CF_BITMAP, self.bitmap)
        user32.CloseClipboard()

    def release(self):
        user32.ReleaseDC(None, self.hdc)
        gdi32.DeleteDC(self.hDest)

class RECT(Structure):
    _fields_ = [('left', c_long), ('top', c_long), ('right', c_long), ('bottom', c_long)]

capture = WindowCapture("DiRT Rally")
capture.capture()
capture.release()
