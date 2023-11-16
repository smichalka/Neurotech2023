from pylsl import resolve_stream, StreamInfo, StreamOutlet, StreamInlet
from pynput import keyboard
import threading
import time
import os
import sys
#import matplotlib.pyplot as plt 
#import matplotlib.image as img
import pygame

"""
Helper functions
"""
MAPPING = {1: 'Rock', 2: 'Paper', 3: 'Scissors'}
clear = lambda : os.system('cls' if os.name == 'nt' else 'clear')
pressed_key = None
key_press_event = threading.Event()
wrapper = None

# pygame
pygame.init()
display_width = 800
display_height = 600
gameDisplay = pygame.display.set_mode((display_width,display_height))
pygame.display.set_caption('Rock, Paper, Scissors')
black = (0,0,0)
white = (255,255,255)
rockImg = pygame.image.load('imgs/rock.png')
paperImg = pygame.image.load('imgs/paper.png')
scissorsImg = pygame.image.load('imgs/scissors.png')
failImg = pygame.image.load('imgs/panda.jpeg')


#im_scissors =  img.imread('imgs/scissors.png')
#plt.imshow(im_scissors)

def key_action(key_char):
    global pressed_key
    pressed_key = key_char
    if pressed_key == 'q':
        print('Quitting stuff program')
        key_press_event.set()
        sys.exit(0)
        print('still here...')
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

def choose_image(val, rockImg, paperImg, scissorsImg, failImg):
    # return the appropriate image
    if val == 1:
        im_out = rockImg
    elif val ==2:
        im_out = paperImg
    elif val == 3:
        im_out = scissorsImg
    else:
        im_out = failImg
    return im_out

if __name__=='__main__':
    # Create the marker out stream
    listener_thread = keyboard.Listener(on_press=on_press, on_release=on_release)
    listener_thread.start()
    # Wait for the user to join
    player1 = None
    while not player1:
        key_press_event.clear()
        streams = resolve_stream()
        for i, stream in enumerate(streams):
            print(f"\033[1m{i}: {stream.name()}\033[0m")
        print('Which stream is Player 1? (r) to reload list of available/ (q) to quit')
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
                    if stream_name == 'marker_send':
                        print('Don\'t use the marker stream as a player stream')
                        stream_name = None
                        continue
                    else:
                        player1 = streams[int(pressed_key)]
                    clear()
                except:
                    print('Please enter a valid int listed')

    player2 = None
    while not player2:
        key_press_event.clear()
        streams = resolve_stream()
        for i, stream in enumerate(streams):
            print(f"\033[1m{i}: {stream.name()}\033[0m")
        print('Which stream is Player 2? (r) to reload list of available/ (q) to quit')
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
                    player2 = streams[int(pressed_key)].name()
                    if player2 == 'marker_send':
                        print('Don\'t use the marker stream as a player stream')
                        stream_name = None
                        continue
                    else:
                        player2 = streams[int(pressed_key)]
                    clear()
                except:
                    print('Please enter a valid int listed')
    clear() 

    marker_info = StreamInfo('marker_send', 'markers', 1, 0)
    marker_out = StreamOutlet(marker_info)
    # NOW we can connect the streams and play rock paper scissors
    # Create the inlet for the player streams
    player1_inlet = StreamInlet(player1)
    player2_inlet = StreamInlet(player2)
    pts_player1 = 0
    pts_player2 = 0
    while pts_player1 < 10 and pts_player2 < 10:
        key_press_event.clear()
        print(player1.name())
        print(player2.name())
        print('Sending rock paper scissors signal on (r)')
        print(f'Player 1: {pts_player1} | Player 2: {pts_player2}')
        key_press_event.wait()
        if pressed_key:
            pressed = pressed_key.strip()
            if pressed == 'r':
                marker_out.push_sample([1])
                print('Sent rock paper scissors signal')
                player1_response, timestamp = player1_inlet.pull_sample()
                player2_response, timestamp = player2_inlet.pull_sample()
                player1_response = player1_response[0]
                player2_response = player2_response[0] 
                print(player1_response)
                print(player2_response)
                print(f'Player 1: {MAPPING[player1_response]}, Player 2: {player2_response}')
                player1_img = choose_image(player1_response,rockImg,paperImg,scissorsImg,failImg)
                player2_img = choose_image(player2_response,rockImg,paperImg,scissorsImg,failImg)
                gameDisplay.blit(player1_img,(200,200))
                
                gameDisplay.blit(player1_img,(600,200))
                pygame.wait(1.0)
                pygame.display.update()
                pygame.wait(1.0)
                
                if player1_response == player2_response:
                    print('Tie!')
                elif player1_response == 1:
                    if player2_response == 2:
                        print('Player 2 wins!')
                        pts_player2 += 1
                    elif player2_response == 3:
                        print('Player 1 wins!')
                        pts_player1 += 1
                elif player1_response == 2:
                    if player2_response == 1:
                        print('Player 1 wins!')
                        pts_player1 += 1
                    elif player2_response == 3:
                        print('Player 2 wins!')
                        pts_player2 += 1
                elif player1_response == 3:
                    if player2_response == 1:
                        print('Player 2 wins!')
                        pts_player2 += 1
                    elif player2_response == 2:
                        print('Player 1 wins!')
                        pts_player1 += 1
            elif pressed == 'q':
                sys.exit(0)
            clear()
    print(f'Player {1 if pts_player1 > pts_player2 else 2} wins!')
    print(f'Final score: Player 1: {pts_player1} | Player 2: {pts_player2}')
