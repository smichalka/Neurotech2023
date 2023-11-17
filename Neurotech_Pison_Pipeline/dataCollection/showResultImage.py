#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Nov 17 08:36:24 2023

@author: smichalka
"""

import pygame

    
# pygame
pygame.init()
display_width = 800
display_height = 800
gameDisplay = pygame.display.set_mode((display_width,display_height))
center = gameDisplay.get_rect().center
pygame.display.set_caption('Rock, Paper, Scissors')
black = (0,0,0)
white = (255,255,255)
DEFAULT_IMAGE_SIZE = (500, 500)
DEFAULT_IMAGE_POSITION = (200, 600)
rockImg = pygame.image.load('imgs/rock.png')
rockImg = pygame.transform.scale(rockImg, DEFAULT_IMAGE_SIZE)
paperImg = pygame.image.load('imgs/paper.png')
paperImg = pygame.transform.scale(paperImg, DEFAULT_IMAGE_SIZE)
scissorsImg = pygame.image.load('imgs/scissors.png')
scissorsImg = pygame.transform.scale(scissorsImg, DEFAULT_IMAGE_SIZE)
failImg = pygame.image.load('imgs/panda.jpeg')
failImg = pygame.transform.scale(failImg, DEFAULT_IMAGE_SIZE)


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


def show_result_image(val):
    gameDisplay.fill(white)
    pygame.display.update()
    
    player1_img= choose_image(val, rockImg, paperImg, scissorsImg, failImg)
    gameDisplay.blit(player1_img,player1_img.get_rect(center = center))
    pygame.display.update()

def close_game():
    pygame.quit()
    
        