.MODEL SMALL
.STACK 100h

.DATA 
	filename DB 'text.txt', 0
	fileHandle DW 0
	fileBuffer DB 500 DUP(0)
	fileLen DW 0
	
	inputPrompt DB 'Input word: $'
	inputBuff DB 20, 0, 20 DUP(0)
	
	msgFound DB 0Dh, 0Ah, 'Found on line: $'
	msgPos DB ', Word number: $'
	msgSent DB 0Dh, 0Ah, 'Sentence count: $'
	msgErr DB 'Error: File is missing!$'
	msgTotalWords DB 0Dh, 0Ah, 'Total words: $'
	newline DB 0Dh, 0Ah, '$'
	
	currLine DW 1
	currWord DW 0 
	sentCount DW 0
	totalWords DW 0
	
	
	
	inWord DB 0
	
.CODE
MAIN PROC
	mov ax, @DATA
	mov ds, ax
	
	;;open file
	mov ah, 3Dh
	mov al, 0
	lea dx, filename
	int 21h
	
	jnc FILE_OPENED
	jmp FILE_ERROR
	mov fileHandle, ax
	
FILE_OPENED:
	mov fileHandle, ax
	
	;;read
	mov bx, fileHandle
	mov ah, 3Fh
	mov cx, 500
	lea dx, fileBuffer
	int 21h
	mov fileLen, ax
	
	;;close file
	mov ah, 3Eh
	mov bx, fileHandle
	int 21h
	
	;;user input
	lea dx, inputPrompt
	mov ah, 09h
	int 21h
	
	lea dx, inputBuff
	mov ah, 0Ah
	int 21h
	
	lea dx, newline
	mov ah, 09h
	int 21h
	
	xor si, si
	mov currLine, 1
	mov currWord, 0
	mov sentCount, 0
	mov inWord, 0

PROCESS_LOOP:
	cmp si, fileLen
	jge END_PROCESSING
	
	mov al, [fileBuffer + si]
	
	cmp al, '.'
	je INC_SENTENCE
	cmp al, '!'
	je INC_SENTENCE
	cmp al, '?'
	je INC_SENTENCE
	jmp CHECK_SEPARATOR

INC_SENTENCE:
	inc sentCount
	
CHECK_SEPARATOR:
	call IS_CHAR_SEPARATOR
	cmp ah, 1
	je HANDLE_SEPARATOR
	
	cmp inWord, 1
	je NEXT_CHAR
	
	mov inWord, 1
	inc currWord
	inc totalWords
	
	call CHECK_MATCH
	jmp NEXT_CHAR

HANDLE_SEPARATOR:
	mov inWord, 0
	
	cmp al, 0Ah
	je NEW_LINE_FOUND
	jmp NEXT_CHAR

NEW_LINE_FOUND:
	inc currLine
	mov currWord, 0
	jmp NEXT_CHAR
	
NEXT_CHAR:
	inc si
	jmp PROCESS_LOOP
	
END_PROCESSING:
	lea dx, msgSent
	mov ah, 09h
	int 21h
	
	mov ax, sentCount
	call PRINT_NUM
	
	lea dx, msgTotalWords
	mov ah, 09h
	int 21h
	
	mov ax, totalWords
	call PRINT_NUM
	
	mov ax, 4c00h
	int 21h
	
FILE_ERROR:
	lea dx, msgErr
	mov ah, 09h
	int 21h
	mov ax, 4c00h
	int 21h
	
	
MAIN ENDP

CHECK_MATCH PROC
	push ax
	push bx
	push cx
	push di
	push si
	
	xor ch, ch
	mov cl, [inputBuff + 1]
	cmp cx, 0
	je NO_MATCH
	
	lea di, [inputBuff + 2]
	
MATCH_LOOP:
	mov al, [fileBuffer + si]
	mov bl, [di]
	
	cmp al, bl
	jne NO_MATCH
	
	inc si
	inc di
	loop MATCH_LOOP
	
	cmp si, fileLen
	jge IT_IS_MATCH
	
	mov al, [fileBuffer + si]
	call IS_CHAR_SEPARATOR
	cmp ah, 1
	jne NO_MATCH
	
IT_IS_MATCH:
	lea dx, msgFound
	mov ah, 09h
	int 21h
	
	mov ax, currLine
	call PRINT_NUM
	
	lea dx, msgPos
	mov ah, 09h
	int 21h
	
	mov ax, currWord
	call PRINT_NUM
	
NO_MATCH:
	pop si
	pop di
	pop cx
	pop bx
	pop ax
	ret
CHECK_MATCH ENDP

IS_CHAR_SEPARATOR PROC
	cmp al, ' '
	je IS_SEP
	cmp al, 09h
	je IS_SEP
	cmp al, 0Dh
	je IS_SEP
	cmp al, 0Ah
	je IS_SEP
	cmp al, '.'
	je IS_SEP
	cmp al, ','
	je IS_SEP
	cmp al, '!'
	je IS_SEP
	cmp al, '?'
	je IS_SEP
	cmp al, '-'
	je IS_SEP
	
	mov ah, 0
	ret
	
IS_SEP:
	mov ah, 1
	ret
IS_CHAR_SEPARATOR ENDP

PRINT_NUM PROC
	push ax
	push bx 
	push cx
	push dx
	
	xor cx, cx
	mov bx, 10
	
PN_DIV_LOOP:
	xor dx, dx
	div bx
	push dx
	inc cx
	test ax, ax
	jnz PN_DIV_LOOP
	
PN_PRINT_LOOP:
	pop dx
	add dl, '0'
	mov ah, 02h
	int 21h
	loop PN_PRINT_LOOP
	
	pop dx
	pop cx
	pop bx
	pop ax
	ret
PRINT_NUM ENDP

END MAIN