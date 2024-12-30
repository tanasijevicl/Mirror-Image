.386
.model flat, stdcall
.stack 4096
ExitProcess proto, dwExitCode:dword

INCLUDE pgma.inc

.data
	intro1 BYTE "MIRROR PHOTO PROGRAM",10,0
    intro2 BYTE "Only PGMA format is supported",10,0

    message1 BYTE 10,"Enter the image file name: ",0
	message2 BYTE 10,"Incorrect keyboard input",10,0
	message3 BYTE 10,"The image is mirrored",10,0

    mirror1 BYTE 10,"1. Press up arrow to mirror photo relative to the top edge of the image",10,0
    mirror2 BYTE "2. Press down arrow to mirror photo relative to the bottom edge of the image",10,0
    mirror3 BYTE "3. Press left arrow to mirror photo relative to the left edge of the image",10,0
    mirror4 BYTE "4. Press right arrow to mirror photo relative to the right edge of the image",10,0

    error BYTE FALSE
.code
	main PROC
			;Print intro
			mov  edx, OFFSET intro1
			call WriteString
			mov  edx, OFFSET intro2
			call WriteString

		.WHILE (1)
	start:	
			;Input file name and read file
			mov edx, OFFSET message1
			call WriteString
			call LoadPgmaFile
			mov error, bl

			;In case of reading error go back to the start
			.IF (error == TRUE)
				mov error, FALSE
				jmp start
			.ENDIF

	programOptions:
			;Print program options
			mov  edx, OFFSET mirror1
			call WriteString
			mov  edx, OFFSET mirror2
			call WriteString
			mov  edx, OFFSET mirror3
			call WriteString
			mov  edx, OFFSET mirror4
			call WriteString

			;Wait for keyboard input (option select)
	lookForKey:
			mov eax, 10
			call Delay
			call ReadKey
			jz lookForKey

			.IF (dl == VK_UP)
				call MirrorTop
		    .ELSEIF (dl == VK_DOWN)
				call MirrorBottom
		    .ELSEIF (dl == VK_LEFT)
				call MirrorLeft
		    .ELSEIF (dl == VK_RIGHT)
				call MirrorRight
			.ELSE
				mov  edx, OFFSET message2
				call WriteString
				jmp programOptions
		    .ENDIF

			;if there are no errors, print the message
			mov error, bl
			.IF (error == FALSE)
				mov  edx, OFFSET message3
				call WriteString
			.ENDIF
		.ENDW
	main ENDP
END main
