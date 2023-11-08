# pylslmod.py
"""Python module for liblsl interactions"""
from pylsl import resolve_stream, StreamInlet, StreamOutlet, StreamInfo
import threading
import numpy as np
import atexit
import scipy.io
import time
import sys

def get_all_streams():
        streams = resolve_stream()
        return [stream.name() for stream in streams]

class PyLSLWrapper:
    """
    Class to create PyLSL bindings callable from MATLAB to pull data from
    a Vulcan's LSL stream and add markers to the stream
    """
    def __init__(self, device_name):
        self.marker_outlet = None
        self.run_thread = False
        self.lsl_data = []
        self.marker_data = []
        self.listener_thread = None
        self.device_name = device_name
        self.local_puller = None
        self.outlet = None

    def pull_stream(self, to_pull, data_arr, timeout_set):
        """
        Find a stream corresponding to the specified device ID

        Return the list
        """
        print('Launched listener!')
        
        inlet = StreamInlet(to_pull)
        while self.run_thread:
            try:
                sample, timestamp = inlet.pull_sample(timeout=timeout_set)
                data_arr.append([timestamp]+sample)
            except:
                raise ValueError('Stream has empty values! Check the app')
                continue
        inlet.close_stream()
        print('Ending stream listener')

    def push_stream(self):
        """
        Launch a stream and return the stream inlet as
        a reference
        """
        stream_info = StreamInfo(f'Marker_{self.device_name}', channel_count=1)
        self.outlet = StreamOutlet(stream_info)

    def push_to_stream(self, val):
        self.outlet.push_sample([val])

    def launch_stream_listener(self):
        """
        Wrapper to launch the pull_stream function in a thread
        """
        print(f'Searching for {self.device_name}')
        streams = resolve_stream()
        to_pull = None
        for stream in streams:
            if stream.name() == self.device_name:
                to_pull = stream
                print(f'Connected to {self.device_name}')
        if not to_pull:
            raise Exception('Could not find the LSL stream')
        else:
            self.listener_thread = threading.Thread(target=self.pull_stream, args=(to_pull,self.lsl_data,1.0)) 
            self.run_thread = True
            self.listener_thread.start()

    def add_marker(self, marker):
        """
        Add a marker to the stream

        marker: int corresponding to trial no.
        """
        # kind of a gross hack here :/
        tstamp = self.lsl_data[-1][0]
        self.marker_data.append([tstamp, marker])

    def edit_last_marker(self):
        """
        Edit the previous marker to show that it is an invalid data point
        when you re-record a gesture.
        """
        last_pt = self.marker_data[-1]
        self.marker_data[-1] = [last_pt[0], 99]
        
    def get_curr_timestamp(self):
        """
        Get the most recent timestamp pushed to the lsl stream
        """
        return self.lsl_data[-1][0]
        
    def get_data_from(self, start_time):
        """
        Return the list of data from a certain timestamp to now. To get
        the full list, just call get_data_from with start_time 0 or -100
        """
        np_lsl_data = np.asarray(self.lsl_data)
        return np_lsl_data[np_lsl_data[:,0] > start_time]

    def end_stream_listener(self, save_file=True):
        """
        End the LSL Stream
        """
        print('Sending signal to end listener thread')
        self.run_thread = False
        self.listener_thread.join()
        print('Listener stopped!')
        if save_file:
            scipy.io.savemat(f'lsl_data_{time.strftime("%Y-%m-%d-%H-%M-%S")}.mat',
                            mdict={'lsl_data':self.lsl_data, 'marker_data':self.marker_data})
            print(len(self.lsl_data))

