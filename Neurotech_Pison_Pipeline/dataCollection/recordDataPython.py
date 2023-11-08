from pylsl import resolve_stream
from get_lsl_data import PyLSLWrapper, get_all_streams
from pynput import keyboard
import random
import sys
import threading
import os
import time
import numpy as np

pressed_key = None
key_press_event = threading.Event()
wrapper = None

"""
Helper Functions
"""
clear = lambda : os.system('cls' if os.name == 'nt' else 'clear')

def key_action(key_char):
    global pressed_key
    pressed_key = key_char
    if pressed_key == 'q':
        key_press_event.set()
        sys.exit(0)
    key_press_event.set()

def on_press(key):
    try:
        key_char = key.char
        key_action(key_char)
    except AttributeError:
        pass

def on_release(key):
    # Exit the listener and the while loop when the 'esc' key is pressed
    try:
        key_char = key.char
        if key_char == 'q':
            return False
    except:
       pass

def exit_program():
    if wrapper:
        wrapper.end_stream_listener()
    key_press_event.clear()
    listener_thread.stop()
    listener_thread.join()
    sys.exit(0)

# Start the key listener thread
if __name__=='__main__':
    listener_thread = keyboard.Listener(on_press=on_press, on_release=on_release)
    listener_thread.start()

    clear()
    stream_name = None

    # Resolve which stream to pull
    while not stream_name:
        key_press_event.clear()
        streams = resolve_stream()
        clear()
        for i, stream in enumerate(streams):
            print(f"\033[1m{i}: {stream.name()}\033[0m")
        print('Which stream? (r) to reload list of available/ (q) to quit')
        key_press_event.wait()
        if pressed_key:
            pressed = pressed_key.strip()
            if pressed == 'r':
                print('Reloading')
                continue
            elif pressed == 'q':
                sys.exit(0)
            else:
                try:
                    stream_name = streams[int(pressed_key)].name()
                    clear()
                except:
                    print('Please enter a valid int listed')

    # Initialize gesturelist and shuffle
    gestures = np.concatenate((np.ones(10), np.ones(10)*2, np.ones(10)*3))
    random.shuffle(gestures)
    # Create a PyLSLWrapper object
    wrapper = PyLSLWrapper(stream_name)
    wrapper.launch_stream_listener()
    i = 0
    while i < len(gestures):
        clear()
        key_press_event.clear()
        gesture = gestures[i]
        if gesture==1:
            gestName = "Rock"
        if gesture==2:
            gestName = "Paper"
        if gesture==3:
            gestName = "Scissors"
        passed = False
        while not passed:
            key_press_event.clear()
            print('(r) start recording / (q) quit')
            print(f"Gesture: \033[1m{gestName}\033[0m ({i+1}/30)")
            key_press_event.wait()
            if pressed_key:
                pressed = pressed_key.strip()
                if pressed == 'r':
                    tstamp = time.time()
                    print('3\r')
                    time.sleep(1)
                    print('2\r')
                    time.sleep(1)
                    print('1\r')
                    time.sleep(.5)
                    wrapper.add_marker(gesture)
                    time.sleep(.5)
                    print('Shoot!')
                    time.sleep(1)
                    passed = True
                elif pressed == 'q':
                    key_press_event.clear()
                    exit_program()
                else:
                    clear()
                    print('Please enter a valid key')
        key_press_event.wait()
        passed = False
        while not passed:
            key_press_event.clear()
            print('(n) next gesture / (r) re-record / (q) quit')
            key_press_event.wait()
            if pressed_key:
                pressed = pressed_key.strip()
                if pressed == 'r':
                    print('Re-recording gesture')
                    wrapper.edit_last_marker()
                    break
                elif pressed == 'q':
                    key_press_event.clear()
                    exit_program()
                elif pressed == 'n':
                    print('Moving to next gesture!')
                    passed = True
                    i += 1
                else:
                    clear()
                    print('Please enter a valid key!')
    print('Done recording!')
    exit_program()

