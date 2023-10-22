from pylsl import resolve_stream
from get_lsl_data import PyLSLWrapper, get_all_streams
from pynput import keyboard
import random
import sys
import threading
import os
import time
import numpy as np

clear = lambda : os.system('tput reset')
pressed_key = None
key_press_event = threading.Event()

def key_action(key_char):
    global pressed_key
    pressed_key = key_char
    if pressed_key == 'q':
        print('Exiting program')
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
    if key == keyboard.Key.esc:
        global keep_running
        keep_running = False
        return False

# This function will run the key listener in a separate thread
def listen_to_keyboard():
    with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
        listener.join()

# Start the key listener thread
listener_thread = threading.Thread(target=listen_to_keyboard)
listener_thread.start()

clear()
stream_name = None
while not stream_name:
    key_press_event.clear()
    streams = resolve_stream()
    clear()
    for i, stream in enumerate(streams):
        print(f"{i}: {stream.name()}")
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

gestures = np.concatenate((np.ones(10), np.ones(10)*2, np.ones(10)*3))
random.shuffle(gestures)
print(gestures)
# Create a PyLSLWrapper object
wrapper = PyLSLWrapper(stream_name)
wrapper.launch_stream_listener()
i = 0
while i < len(gestures):
    clear()
    key_press_event.clear()
    print('(r) start recording / (q) quit')
    gesture = gestures[i]
    if gesture==1:
        gestName = "Rock"
    if gesture==2:
        gestName = "Paper"
    if gesture==3:
        gestName = "Scissors"
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
            wrapper.add_marker(0)
            time.sleep(.5)
            print('Shoot!')
            time.sleep(1)
        elif pressed == 'q':
            print('Quitting')
            sys.exit(0)
    key_press_event.clear()
    print('(n) next gesture / (r) re-record / (q) quit')
    key_press_event.wait()
    if pressed_key:
        pressed = pressed_key.strip()
        if pressed == 'r':
            print('Re-recording gesture')
            continue
        elif pressed == 'q':
            print('quitting')
            sys.exit(0)
        elif pressed == 'n':
            print('Moving to next gesture!')
            i += 1

print('Finished the gestures!')
listener_thread.join()

