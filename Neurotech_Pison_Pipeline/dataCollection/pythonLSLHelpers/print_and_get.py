from pylsl import resolve_stream, StreamInlet

streams = resolve_stream()
for i, stream in enumerate(streams):
    print(f"{i}: {stream.name()}")

stream = streams[int(input('Which stream?'))]
inlet = StreamInlet(stream)
while True:
    print(inlet.pull_sample())

