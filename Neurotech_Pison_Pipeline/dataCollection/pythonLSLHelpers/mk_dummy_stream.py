from pylsl import StreamInfo, StreamOutlet
import time
import random
import argparse

if __name__=='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('name', help='Name of the stream')
    args = parser.parse_args()
    strm = StreamInfo(f'{args}', 'test', 1, 2, 'float32')
    outlet = StreamOutlet(strm)
    while True:
        outlet.push_sample([random.random()])
        time.sleep(.5)

