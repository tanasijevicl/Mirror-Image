;This file contains procedures prototypes for processing PGMA file format

INCLUDE Irvine32.inc

MAX_RESOLUTION = 2000000
MAX_NAME_LENGTH = 254
MAX_ROW_WIDTH = 15

TRUE equ 1
FALSE equ 0
NEWLINE equ 10
SPACE equ 32

PGMA STRUCT
	fname BYTE MAX_NAME_LENGTH+1 DUP (?)
	fhandle DWORD 0
	pwidth WORD 0
	pheight WORD 0
	pmax WORD 0
	pixels WORD MAX_RESOLUTION DUP (0)
	end_of_file BYTE FALSE
PGMA ENDS


InitVariables PROTO						;Function initializes the values of the variables

ReadAscii PROTO							;Function reads one ascii character at the time

WriteAscii PROTO, char:BYTE				;Function writes one ascii character in the file

ReadNumber PROTO						;Function reads ascii characters and convert them into integer

WriteNumber PROTO, number:WORD			;Function writes an integer number in the file


CheckPgmaFormat PROTO					;Function checks whether the file format is correct

ReadPgmaData PROTO						;Function reads all data from the file

LoadPgmaFile PROTO						;Function reads a PGMA file


MirrorTop PROTO							;Function mirrors photo relative to the top edge of the image

MirrorBottom PROTO						;Function mirrors photo relative to the bottom edge of the image

MirrorLeft PROTO						;Function mirrors photo relative to the left edge of the image

MirrorRight PROTO						;Function mirrors photo relative to the right edge of the image