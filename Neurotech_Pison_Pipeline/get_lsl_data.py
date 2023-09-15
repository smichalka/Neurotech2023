# pylslmod.py
"""Python module for liblsl interactions"""
from pylsl import resolve_stream, StreamInlet, StreamOutlet, StreamInfo
import threading
import atexit
import scipy.io
import time
import sys

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

    def pull_stream(self, to_pull, data_arr, timeout_set):
        """
        Find a stream corresponding to the specified device ID

        Return the list
        """
        print('Launched listener!')
        
        inlet = StreamInlet(to_pull)
        try:
            while self.run_thread:
                try:
                    sample, timestamp = inlet.pull_sample(timeout=timeout_set)
                    data_arr.append([timestamp]+sample)
                except:
                    raise ValueError('Stream has empty values! Check the app')
                    continue
        except: # see if there's a timeout error that can occur
            inlet.close_stream()
            raise Exception("LSL Stream was lost while pulling data. Try connecting to device again.")
        inlet.close_stream()
        print('Ending stream listener')

    def launch_stream_listener(self):
        """
        Wrapper to launch the pull_stream function in a thread
        """
        print(f'Searching for butt {self.device_name}')
        streams = resolve_stream()
        to_pull = None
        print(streams)
        for stream in streams:
            print(f'Pison Vulcan - {self.device_name} ADC')
            if stream.name() == f'Pison Vulcan - {self.device_name} ADC':
                to_pull = stream
                print('LSL Stream found!')
            if stream.name() == f'Pison Vulcan - {self.device_name} IMU':
                to_pull_IMU = stream
        if not to_pull:
            raise Exception('Could not find the LSL stream')
        else:
            # marker_info = StreamInfo(f'Marker_{self.device_name}','Marker',1,100,'float32')
            # self.marker_outlet = StreamOutlet(marker_info)
            # self.marker_outlet.push_sample([-100])
            # marker_inlet = StreamInlet(marker_info)
            self.listener_thread = threading.Thread(target=self.pull_stream, args=(to_pull,self.lsl_data,0.1)) 
            # self.marker_thread = threading.Thread(target=self.pull_stream, args=(marker_info, self.marker_data,0.5))
            self.run_thread = True
            self.listener_thread.start()
            self.local_puller = StreamInlet(to_pull_IMU)
            # self.marker_thread.start()

    def add_marker(self, marker):
        """
        Add a marker to the stream

        marker: int corresponding to trial no.
        """
        # kind of a gross hack here :/
        tstamp = self.lsl_data[-1][0]
        self.marker_data.append([tstamp, marker])
        

    def end_stream_listener(self):
        """
        End the LSL Stream
        """
        print('Sending signal to end listener thread')
        self.run_thread = False
        self.listener_thread.join()
        print('Listener stopped!')
        scipy.io.savemat(f'lsl_data_{time.strftime("%Y-%m-%d-%H-%M-%S")}.mat',
                         mdict={'lsl_data':self.lsl_data, 'marker_data':self.marker_data})
        print(self.lsl_data)
        print(self.marker_data)


