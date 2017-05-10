from capture import WindowCapture

capture = WindowCapture("DiRT Rally")

for i in range(100):
    im = capture.capture()
    im.save("images/{}.png".format(i))
    print(i)