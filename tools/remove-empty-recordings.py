import glob, os
for recording in glob.iglob("recordings/*/*/*"):
    if os.listdir(recording) == ["steering.txt"]:
        print(recording, "is empty. Removing...")
        os.remove(os.path.join(recording, 'steering.txt'))
        os.rmdir(recording)
