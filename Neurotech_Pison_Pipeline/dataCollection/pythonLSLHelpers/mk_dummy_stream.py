from pylsl import StreamInfo, StreamOutlet
import time
import random

if __name__=='__main__':
    strm = StreamInfo('Test Stream', 'test', 1, 2, 'float32')
    outlet = StreamOutlet(strm)
    while True:
        outlet.push_sample([random.random()])
        time.sleep(.5)

