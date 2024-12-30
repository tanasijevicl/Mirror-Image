;This file contains procedures source codes for processing PGMA file format

INCLUDE pgma.inc

.data?	
	ascii BYTE ?

.data
	error1 BYTE 10,"ERROR: Unable to open file!",10,0
	error2 BYTE 10,"ERROR: Invalid file format!",10,0
	error3 BYTE 10,"ERROR: Invalid file data!",10,0
	error BYTE FALSE

	format BYTE "P2",10,"# mirrored photo",10
	mirror_file BYTE "mirror.pgm",0
	
	file PGMA <>
	
.code

;Function initializes the values of the variables
InitVariables PROC
	push ecx

	mov ecx, 0
	.WHILE (ecx <= MAX_NAME_LENGTH)
		mov file.fname[ecx], 0
		inc ecx
	.ENDW

	mov ecx,0
	.WHILE (ecx <= MAX_RESOLUTION)
		mov file.pixels[ecx], 0
		inc ecx
	.ENDW

	mov error, FALSE

	pop ecx
	ret
InitVariables ENDP

;Function reads one ascii character at the time
ReadAscii PROC
	push eax										
	push ecx
	push edx

	mov eax, file.fhandle							;read one character from the file								
	mov ecx, 1
	mov edx, OFFSET ascii
	call ReadFromFile									
	jc readingError									;in case of error jump on the label ReadingError
	
	cmp eax, 0										;if the character is not read jump on the label endOfFile
	je endOfFile					
	
	jmp endLabel									;if there are no errors jump on the label endLabel

  endOfFile:
	mov file.end_of_file, TRUE
	jmp endLabel

  readingError:
    mov error, TRUE
	call WriteWindowsMsg							;print an error message
  
  endLabel:	
	pop edx				
	pop ecx
	pop eax
	ret
ReadAscii ENDP

;Function writes one ascii character in the file
WriteAscii PROC, char:BYTE
	push eax										
	push ecx
	push edx

	mov  eax, file.fhandle							;write one character in the file
	mov  ecx, 1
    lea  edx, char
    call WriteToFile
	jc writingError									;in case of error jump on the label ReadingError
	
	cmp eax, 0										
	je writingError									;if the character is not written jump on the label endOfFile
	
	jmp endLabel									;if there are no errors jump on the label endLabel

  writingError:
	mov error, TRUE
	call WriteWindowsMsg							;print an error message
	  
  endLabel:	
	pop edx				
	pop ecx
	pop eax
	ret
WriteAscii ENDP

;Function reads ascii characters and convert them into integer
ReadNumber PROC
	LOCAL number:WORD, digits[5]:BYTE
	push eax
	push ecx
	push edi

	mov number, 0

	.WHILE (ascii == NEWLINE || ascii == SPACE)		;skip newline and space characters
		call ReadAscii
		cmp error, TRUE
		je endLabel
	.ENDW
	
	mov cl, 0 
	lea edi, digits
	.WHILE (ascii != NEWLINE && ascii != SPACE)		;read digits until new line or space character
		mov al, ascii
		call IsDigit								;check if the ascii character is a digit
		jnz invalidData								;if not, jump on the label invalidData

		sub al, "0"									;convert ascii to digit
		mov [edi], al
		inc cl
		inc edi
		call ReadAscii								;read next character
		cmp error, TRUE								;check for errors
		je endLabel									;in case of error jump on the label endLabel
	.ENDW

	lea edi, digits

	cmp cl, 6										;depending on the number of digits
	jae invalidData									;jump to a specific label
	cmp cl, 5
	je fiveDigits
	cmp cl, 4
	je fourDigits
	cmp cl, 3
	je threeDigits
	cmp cl, 2
	je twoDigits
	jmp oneDigit

  fiveDigits:										
	mov eax, 10000									;multiply a digit with a certain order of magnitude
	mov bl, [edi]									
	mul bl
	add number, ax									;and add it to the total number
	inc edi
  fourDigits:
	mov eax, 1000
	mov bl, [edi]
	mul bl
	add number, ax
	inc edi
  threeDigits:
	mov eax, 100
	mov bl, [edi]
	mul bl
	add number, ax
	inc edi
  twoDigits:
    mov eax, 10
	mov bl, [edi]
	mul bl
	add number, ax
	inc edi
  oneDigit:
	mov eax, 1
	mov bl, [edi]
	mul bl
	add number, ax

	mov bx, number									;bx as a return value
	jmp endLabel
	
  invalidData:
	mov error, TRUE
 
  endLabel:
	pop edi
	pop ecx
	pop eax
	ret
ReadNumber ENDP

;Function writes an integer number in the file
WriteNumber PROC, number:WORD
	LOCAL digit:BYTE
	push eax
	push ebx
	push ecx

	cmp number, 10000								;depending on the number of digits of number 
	jae fiveDigits									;jump to a specific label
	cmp number, 1000
	jae fourDigits
	cmp number, 100
	jae threeDigits
	cmp number, 10
	jae twoDigits
	jmp oneDigit

  fiveDigits:
    mov eax, 0										;divide a number with a certain order of magnitude
	mov edx, 0										 
	mov ax, number
	mov bx, 10000
	div bx
	mov digit, al

	mov eax, 10000									;subtract from the total number
	mov ebx, 0
	mov bl, digit 
	mul bx
	sub number, ax

	add digit, "0"									;convert digit in ascii character
	INVOKE WriteAscii, digit						;write digit in the file
	cmp error, TRUE									;check for errors
	je endLabel										;in case of error jump on the label endLabel

  fourDigits:
    mov eax, 0
	mov edx, 0
	mov ax, number
	mov bx, 1000
	div bx
	mov digit, al

	mov eax, 1000
	mov ebx, 0
	mov bl, digit 
	mul bx
	sub number, ax

	add digit, "0"
	INVOKE WriteAscii, digit
	cmp error, TRUE
	je endLabel	

  threeDigits:
    mov eax, 0
	mov edx, 0
	mov ax, number
	mov bx, 100
	div bx
	mov digit, al

	mov eax, 100
	mov ebx, 0
	mov bl, digit 
	mul bx
	sub number, ax

	add digit, "0"
	INVOKE WriteAscii, digit
	cmp error, TRUE
	je endLabel	

  twoDigits:
    mov eax, 0
	mov edx, 0
	mov ax, number
	mov bx, 10
	div bx
	mov digit, al

	mov eax, 10
	mov ebx, 0
	mov bl, digit 
	mul bx
	sub number, ax

	add digit, "0"
	INVOKE WriteAscii, digit
	cmp error, TRUE
	je endLabel	

  oneDigit:
	add number, "0"
	INVOKE WriteAscii, BYTE PTR number

  endLabel:
	pop ecx
	pop ebx
	pop eax
	ret
WriteNumber ENDP

;Function checks whether the file format is correct
CheckPgmaFormat PROC
	
	call ReadAscii									;read a character
	cmp error, TRUE									;check for errors
	je endLabel									    ;in case of error jmp on the label endLabel
	cmp ascii, "P"									;compare the read character with the given one 
	jne invalidFormat								;if they do not match jmp on the label invalidFormat

	call ReadAscii
	cmp error, TRUE
	je endLabel
	cmp ascii, "2"
	jne invalidFormat

	call ReadAscii
	cmp error, TRUE
	je endLabel
	cmp ascii, NEWLINE
	jne invalidFormat

	call ReadAscii
	cmp error, TRUE
	je endLabel
	cmp ascii, "#"
	jne invalidFormat

	.WHILE (ascii != NEWLINE)						;skip comment in the file
		call ReadAscii
		cmp error, TRUE
		je endLabel
	.ENDW
	
	jmp endLabel

  invalidFormat:
	mov error, TRUE
  endLabel:
	ret
CheckPgmaFormat ENDP

;Function reads all data from the file
ReadPgmaData PROC
	LOCAL pixel_number:DWORD

	call ReadNumber									;read picture width
	cmp error, TRUE
	je endLabel
	mov file.pwidth, bx

	call ReadNumber									;read picture height
	cmp error, TRUE
	je endLabel
	mov file.pheight, bx

	call ReadNumber									;read max pixel value
	cmp error, TRUE
	je endLabel
	mov file.pmax, bx

	mov eax, 0										;calculate the number of pixels
	mov edx, 0										;width x height
	mov ax, file.pwidth
	mul file.pheight
	mov ebx, edx
	shl ebx, 16
	mov bx, ax
	mov pixel_number, ebx

	mov ecx, 0
	.WHILE (ecx < pixel_number)						;read pixels value
		call ReadNumber
		cmp error, TRUE
		je endLabel
		cmp bx, file.pmax							;check if the pixel value is greater than the maximum
		ja invalidData								;if so jump on the label endLabel
		mov file.pixels[ecx*2], bx
		inc ecx
		.IF (file.end_of_file == TRUE)				;in case of end_of_file flag 
			cmp ecx, pixel_number					;check whether all pixel values have been read
			jne invalidData
		.ENDIF
	.ENDW
  
  jmp endLabel

  invalidData:
	mov error, TRUE
  endLabel:
	ret
ReadPgmaData ENDP

;Function reads PGMA file
LoadPgmaFile PROC
	push eax
	push ecx
	push edx

	call InitVariables									;initialize variables

	mov edx, OFFSET file.fname							;read the file name form standard input		
	mov ecx, MAX_NAME_LENGTH
	call ReadString

	mov edx, OFFSET file.fname							;open the file
	call OpenInputFile
	mov	file.fhandle, eax

	.IF (eax == INVALID_HANDLE_VALUE)					
		mov edx, OFFSET error1							;in case of error print an error message
		call WriteString
		mov bl, TRUE									;and return "error flag"
		jmp endLabel
	.ENDIF

	call CheckPgmaFormat  							    ;check if the file format is good 

	.IF (error == TRUE)							
		mov edx, OFFSET error2							;in case of invalid file format print an error message
		call WriteString
		mov bl, TRUE									;and return "error flag"
		jmp endLabel
	.ENDIF

	call ReadPgmaData									;read pgma data

	.IF (error == TRUE)									;in case of invalid file format print an error message
		mov edx, OFFSET error3
		call WriteString
		mov bl, TRUE									;and return "error flag"
		jmp endLabel
	.ENDIF

	mov bl, FALSE

  endLabel:
	mov eax, file.fhandle								;close the file
	call CloseFile
	pop edx
	pop ecx
	pop eax
	ret
LoadPgmaFile ENDP

;Function mirrors photo relative to the top edge of the image
MirrorTop PROC
	LOCAL cnt:DWORD, pixel_number:DWORD
	push eax
	push ecx
	push edx
	push esi
	push edi

	mov edx, OFFSET mirror_file							;create the output file
	call CreateOutputFile
	mov file.fhandle, eax

	mov  eax, file.fhandle								;write format
	mov  ecx, LENGTHOF format
    mov  edx, OFFSET format
    call WriteToFile
	jc writingError

	INVOKE WriteNumber, file.pwidth						;write picture width
	cmp error, TRUE
	je writingError

	INVOKE WriteAscii, SPACE
	cmp error, TRUE
	je writingError

	mov eax, 0											;multiply picture height by 2
	mov ax, 2
	mov bx, file.pheight
	mul bx

	INVOKE WriteNumber, ax								;write picture height
	cmp error, TRUE
	je writingError

	INVOKE WriteAscii, NEWLINE
	cmp error, TRUE
	je writingError

	INVOKE WriteNumber, file.pmax						;write pixel max value
	cmp error, TRUE
	je writingError

	INVOKE WriteAscii, NEWLINE
	cmp error, TRUE
	je writingError

	mov eax, 0											;set pixel pointer on the last row
	mov edx, 0
	mov ax, file.pwidth
	mul file.pheight
	mov esi, edx
	shl esi, 16
	mov si, ax
	mov eax, 0
	mov ax, file.pwidth
	sub esi, eax

	mov di, file.pheight								;set column counter
	mov cnt, 0

	.WHILE(di > 0)										;write from bottom to the top
		mov eax, esi
		mov cx, 0
		.WHILE(cx < file.pwidth)						;write from right to left
			INVOKE WriteNumber, file.pixels[esi*2]		;write pixel value
			cmp error, TRUE								;check for errors
			je writingError

			.IF (cnt >= MAX_ROW_WIDTH)					;every x times write the newline character
				INVOKE WriteAscii, NEWLINE
				mov cnt, 0
			.ELSE
				INVOKE WriteAscii, SPACE
			.ENDIF
			cmp error, TRUE								;check for errors
			je writingError

			inc cnt										;increment counters
			inc esi
			inc cx
		.ENDW
		mov	esi, eax									;set pixel pointer on the next row
		mov eax, 0
		mov ax, file.pwidth 
		sub esi, eax
		dec di
	.ENDW

	mov eax, 0											;calculate the number of pixels
	mov edx, 0											;width x height
	mov ax, file.pwidth
	mul file.pheight
	mov ebx, edx
	shl ebx, 16
	mov bx, ax
	mov pixel_number, ebx

	mov esi, 0											
	.WHILE(esi < pixel_number)							;write the pixels in order
		INVOKE WriteNumber, file.pixels[esi*2]
		.IF (cnt >= MAX_ROW_WIDTH)
			INVOKE WriteAscii, NEWLINE
			mov cnt, 0
		.ELSE
			INVOKE WriteAscii, SPACE
		.ENDIF
		cmp error, TRUE									;check for errors
		je writingError

		inc cnt											;increment counters
		inc esi
	.ENDW
	
	jmp endLabel 

  writingError:
	call WriteWindowsMsg								;print an error message

  endLabel:
	mov bl, error
	mov  eax, file.fhandle								;close the output file
    call CloseFile

	pop edi
	pop esi
	pop edx
	pop ecx
	pop eax
	ret
MirrorTop ENDP

;Function mirrors photo relative to the bottom edge of the image
MirrorBottom PROC
	LOCAL cnt:DWORD, pixel_number:DWORD
	push eax
	push ecx
	push edx
	push esi
	push edi

	mov edx, OFFSET mirror_file							;create the output file
	call CreateOutputFile
	mov file.fhandle, eax

	mov  eax, file.fhandle								;write format
	mov  ecx, LENGTHOF format
    mov  edx, OFFSET format
    call WriteToFile
	jc writingError

	INVOKE WriteNumber, file.pwidth						;write picture width
	cmp error, TRUE
	je writingError

	INVOKE WriteAscii, SPACE
	cmp error, TRUE
	je writingError

	mov eax, 0											;multiply picture height by 2
	mov ax, 2
	mov bx, file.pheight
	mul bx

	INVOKE WriteNumber, ax								;write picture height
	cmp error, TRUE
	je writingError

	INVOKE WriteAscii, NEWLINE
	cmp error, TRUE
	je writingError

	INVOKE WriteNumber, file.pmax						;write pixel max value
	cmp error, TRUE
	je writingError

	INVOKE WriteAscii, NEWLINE
	cmp error, TRUE
	je writingError

	mov eax, 0											;calculate the number of pixels
	mov edx, 0											;width x height
	mov ax, file.pwidth
	mul file.pheight
	mov ebx, edx
	shl ebx, 16
	mov bx, ax
	mov pixel_number, ebx

	mov esi, 0											
	.WHILE(esi < pixel_number)							;write the pixels in order
		INVOKE WriteNumber, file.pixels[esi*2]
		.IF (cnt >= MAX_ROW_WIDTH)
			INVOKE WriteAscii, NEWLINE
			mov cnt, 0
		.ELSE
			INVOKE WriteAscii, SPACE
		.ENDIF
		cmp error, TRUE									;check for errors
		je writingError

		inc cnt											;increment counters
		inc esi
	.ENDW

	mov eax, 0											;set pixel pointer on the last row
	mov edx, 0
	mov ax, file.pwidth
	mul file.pheight
	mov esi, edx
	shl esi, 16
	mov si, ax
	mov eax, 0
	mov ax, file.pwidth
	sub esi, eax

	mov di, file.pheight								;set column counter
	mov cnt, 0

	.WHILE(di > 0)										;write from bottom to the top
		mov eax, esi
		mov cx, 0
		.WHILE(cx < file.pwidth)						;write from left to right
			INVOKE WriteNumber, file.pixels[esi*2]		;write pixel value
			cmp error, TRUE								;check for errors
			je writingError

			.IF (cnt >= MAX_ROW_WIDTH)					;every x times write the newline character
				INVOKE WriteAscii, NEWLINE
				mov cnt, 0
			.ELSE
				INVOKE WriteAscii, SPACE
			.ENDIF
			cmp error, TRUE								;check for errors
			je writingError

			inc cnt										;increment counters
			inc esi
			inc cx
		.ENDW
		mov	esi, eax									;set pixel pointer on next row
		mov eax, 0
		mov ax, file.pwidth 
		sub esi, eax
		dec di
	.ENDW

	jmp endLabel 

  writingError:
	call WriteWindowsMsg								;print an error message

  endLabel:
	mov bl, error
	mov  eax, file.fhandle								;close the output file
    call CloseFile

	pop edi
	pop esi
	pop edx
	pop ecx
	pop eax
	ret
MirrorBottom ENDP

;Function mirrors photo relative to the left edge of the image
MirrorLeft PROC
	LOCAL cnt:DWORD, pixel_number:DWORD
	push eax
	push ecx
	push edx
	push esi
	push edi

	mov edx, OFFSET mirror_file							;create the output file
	call CreateOutputFile
	mov file.fhandle, eax

	mov  eax, file.fhandle								;write format
	mov  ecx, LENGTHOF format
    mov  edx, OFFSET format
    call WriteToFile
	jc writingError

	mov eax, 0											;multiply picture width by 2
	mov ax, 2
	mov bx, file.pwidth
	mul bx
	
	INVOKE WriteNumber, ax								;write picture width
	cmp error, TRUE
	je writingError

	INVOKE WriteAscii, SPACE
	cmp error, TRUE
	je writingError

	INVOKE WriteNumber, file.pheight					;write picture height
	cmp error, TRUE
	je writingError

	INVOKE WriteAscii, NEWLINE
	cmp error, TRUE
	je writingError

	INVOKE WriteNumber, file.pmax						;write pixel max value
	cmp error, TRUE
	je writingError

	INVOKE WriteAscii, NEWLINE
	cmp error, TRUE
	je writingError

	mov eax, 0											;calculate the number of pixels
	mov edx, 0											;width x height
	mov ax, file.pwidth
	mul file.pheight
	mov ebx, edx
	shl ebx, 16
	mov bx, ax
	mov pixel_number, ebx

	mov eax, 0
	mov ax, file.pwidth
	mov esi, eax
	.WHILE(esi <= pixel_number)							;write from top to bottom
		mov di, file.pwidth
		.WHILE(di > 0)									;write row from right to left
			dec esi
			dec di
			INVOKE WriteNumber, file.pixels[esi*2]
			.IF (cnt >= MAX_ROW_WIDTH)
				INVOKE WriteAscii, NEWLINE
				mov cnt, 0
			.ELSE
				INVOKE WriteAscii, SPACE
			.ENDIF
			cmp error, TRUE								;check for errors
			je writingError
			inc cnt
		.ENDW

		.WHILE(di < file.pwidth)						;write row from left to right
			INVOKE WriteNumber, file.pixels[esi*2]
			.IF (cnt >= MAX_ROW_WIDTH)
				INVOKE WriteAscii, NEWLINE
				mov cnt, 0
			.ELSE
				INVOKE WriteAscii, SPACE
			.ENDIF
			cmp error, TRUE								;check for errors
			je writingError
			inc cnt
			inc esi
			inc di
		.ENDW

		mov eax, 0										;set pointer on the next row
		mov ax, file.pwidth
		add esi, eax
	.ENDW

	jmp endLabel 

  writingError:
	call WriteWindowsMsg								;print an error message

  endLabel:
	mov bl, error
	mov  eax, file.fhandle								;close the output file
    call CloseFile

	pop edi
	pop esi
	pop edx
	pop ecx
	pop eax
	ret
MirrorLeft ENDP

;Function mirrors photo relative to the right edge of the image
MirrorRight PROC
	LOCAL cnt:DWORD, pixel_number:DWORD
	push eax
	push ecx
	push edx
	push esi
	push edi

	mov edx, OFFSET mirror_file							;create the output file
	call CreateOutputFile
	mov file.fhandle, eax

	mov  eax, file.fhandle								;write format
	mov  ecx, LENGTHOF format
    mov  edx, OFFSET format
    call WriteToFile
	jc writingError

	mov eax, 0											;multiply picture width by 2
	mov ax, 2
	mov bx, file.pwidth
	mul bx

	INVOKE WriteNumber, ax								;write picture width
	cmp error, TRUE
	je writingError

	INVOKE WriteAscii, SPACE
	cmp error, TRUE
	je writingError

	INVOKE WriteNumber, file.pheight					;write picture height
	cmp error, TRUE
	je writingError

	INVOKE WriteAscii, NEWLINE
	cmp error, TRUE
	je writingError

	INVOKE WriteNumber, file.pmax						;write pixel max value
	cmp error, TRUE
	je writingError

	INVOKE WriteAscii, NEWLINE
	cmp error, TRUE
	je writingError

	mov eax, 0											;calculate the number of pixels
	mov edx, 0											;width x height
	mov ax, file.pwidth
	mul file.pheight
	mov ebx, edx
	shl ebx, 16
	mov bx, ax
	mov pixel_number, ebx

	mov esi, 0
	mov edi, 0
	.WHILE(esi < pixel_number)							;write the pixels value in file

		.WHILE(di < file.pwidth)						;write row from left to right
			INVOKE WriteNumber, file.pixels[esi*2]
			.IF (cnt >= MAX_ROW_WIDTH)
				INVOKE WriteAscii, NEWLINE
				mov cnt, 0
			.ELSE
				INVOKE WriteAscii, SPACE
			.ENDIF
			cmp error, TRUE								;check for errors
			je writingError
			inc cnt
			inc esi
			inc di
		.ENDW

		.WHILE(di > 0)									;write row from right to left
			dec esi
			dec di
			INVOKE WriteNumber, file.pixels[esi*2]
			.IF (cnt >= MAX_ROW_WIDTH)
				INVOKE WriteAscii, NEWLINE
				mov cnt, 0
			.ELSE
				INVOKE WriteAscii, SPACE
			.ENDIF
			cmp error, TRUE								;check for errors
			je writingError
			inc cnt

		.ENDW

		mov eax, 0										;set pointer on next row
		mov ax, file.pwidth
		add esi, eax
	.ENDW

	jmp endLabel 

  writingError:
	call WriteWindowsMsg								;print an error message

  endLabel:
	mov bl, error
	mov  eax, file.fhandle								;close the output file
    call CloseFile

	pop edi
	pop esi
	pop edx
	pop ecx
	pop eax
	ret
MirrorRight ENDP

END