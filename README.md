# PGMA Mirror Image

## Overview

This project is a MASM (x86 assembly) program that performs mirror effect transformations on PGMA format images based on keyboard arrow key inputs. 

## Features

The program supports the following operations:

- **Up Arrow Key**: Mirrors the image along the top edge.
- **Down Arrow Key**: Mirrors the image along the bottom edge.
- **Left Arrow Key**: Mirrors the image along the left edge.
- **Right Arrow Key**: Mirrors the image along the right edge.

The transformed image is saved as a new file (`mirror.pgm`) with the same extension.

## PGMA Format

**PGMA** (Portable Graymap ASCII) is a plain-text format used for grayscale images. It represents pixel values as ASCII integers, where each number corresponds to the intensity of a pixel (0 for black and the maximum value for white).

## Project Files

- **`main.asm`** : File contains the part of the code responsible for interacting with the user.
- **`pgma.asm`** & **`pgma.inc`**: File contains procedure source codes for processing PGMA file formats. It includes routines for initialization, reading, and writing ASCII characters and numbers, validating file formats, reading PGMA data, and mirroring the image.

## Data Files

- **`barbara.pgm`**: Example input file in PGMA format. 
- **`mirror.pgm`**: Output file containing mirrored image.

## Dependencies

- **MASM Assembler**: Visual Studio 2019 (or newer) is recommended for building this project.
- **Irvine32 Library**: Used to simplify tasks related to input-output and string handling in assembly language programming.