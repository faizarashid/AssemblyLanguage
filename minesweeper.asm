.386
.model flat, StdCall
.stack 4096
GetStdHandle PROTO, a1:DWORD
WriteConsoleA PROTO, a1:DWORD, a2: PTR BYTE, a3: Dword, a4: ptr dword, a5: dword
ReadConsoleA PROTO, a1:DWORD, a2: PTR BYTE, a3: Dword, a4: ptr dword, a5: dword
SetConsoleTextAttribute PROTO, a1:DWORD,a2:DWORD
ExitProcess PROTO STDCALL:DWORD
GetTickCount PROTO
SetConsoleCursorPosition PROTO,handle:DWORD,pos:DWORD

.data
backG byte 100 dup (5Fh)
frontG byte 100 dup(5Fh)
rowS byte 3 dup(0h)
colS byte 3 dup(0h)
count byte 2 dup(0)

welcome byte "..Welcome to MineSweeper.."
Ask byte "Please Enter Row And Column You Wish To Open", 0ah 
askr byte "R:"
askc byte "C:"
error byte "Invalid Input, Try Again Later."
bombed byte 0ah,"Oops!! You hit a bomb.",0ah, "***GAME OVER***"
won Byte "You Are Safe And Sound, :)",0ah, "*****CONGRAJULASHONS*****"
nextline byte 0ah
space byte 20h


i byte ?
j byte ?
position byte ?

seed dword 89h
x dword ?

bomb byte "*"

ColNum byte 20h, 20h,"0 1 2 3 4 5 6 7 8 9",0
RowNum byte "0","1","2","3","4","5","6","7","8","9",0
Displaytime byte 0ah,"TIME ::",0
selection byte 4 dup(?) 
caltime byte 6 dup(?)
outhandle dword ?
inhandle dword ?

.code
;Receives address of a null terminated character array in ESI
;Returns corresponding SIGNED number in EAX
 ToDecimal PROC
	push esi
	cmp byte ptr [esi], '-'
	jne itspostive
	inc esi
	itspostive:
	mov ebx, 0			; x = 0
	L1:
		mov cl, [esi]	; Get a character
		cmp cl, 0		; check if its a null character
		je endL1
		mov edi, 10
		mov eax, ebx
		mul edi			; 10*x
		sub cl, 48		; (s[i]-'0') 
						; the character has been converted to its corrsponding number
		movzx ecx, cl
		add eax, ecx	; x*10 + (s[i]-48) 
		mov ebx, eax    ; x = x*10 + (s[i]-48)  
		inc esi
	jmp L1
	endL1:
	mov eax, ebx
	pop esi
	cmp byte ptr[esi], '-'
	jne itwaspositive
	neg eax
	itwaspositive:
ret
ToDecimal ENDP

; Receives an unsigned number in EAX
; Receives address of a character array in ESI
; Fills the array with the corresponding chracters and null terminate it
; returns count of characters in EAX
ToString PROC uses ecx edi esi edx
    push eax
    mov edi, 10
    mov ecx, 0                ; Ecx will have the digit count in the end
    findnumofdigits:
        cmp eax, 0
        je exitfinddigits
        mov edx, 0
        div edi
        inc ecx
    jmp findnumofdigits
    exitfinddigits:
    pop eax
    push ecx
    mov byte ptr [esi+ecx] , 0 ; null terminate the string
	cmp ecx,0
	je last
    savecharacters:
        mov edx, 0
        div edi
        add dl, 48
        mov [esi+ecx-1], dl
    loop savecharacters
    pop eax
ret
last:
mov edx, 0
        div edi
        add dl, 48
        mov [esi+ecx], dl
pop eax
ret
ToString ENDP
 ;Generate a random number in the range [0, n-1]  
 ;Expect one parameter that is 'n' in EAX 
 ;returns random number in EAX 
 ;seed is a dword type variable global variable initialized with positive numbe
 generaterandom proc uses ebx edx   
   mov ebx, eax  ; maximum value
   mov  eax, 343FDh
   imul seed   
   add eax, 269EC3h  
   mov seed, eax     ; save the seed for the next call   
   ror eax,8         ; rotate out the lowest digit   
   mov edx,0   
   div ebx   ; divide by max value   
   mov eax, edx  ; return the remainder  
   ret 
   generaterandom endp 

 ;Method Used to print grid on screen
 printGrid Proc uses ecx
    invoke WriteConsoleA, outhandle, offset ColNum, lengthof ColNum-1, offset x, 0
	mov esi, 0   ;For ColNum
	mov edi, offset RowNum   ;for RowNum
	mov esi,offset frontG
	L1:
	mov bl, [edi]     ;compare if the strong of row number ended
	cmp bl, 0
	je endd
	invoke WriteConsoleA, outhandle, offset nextline ,1, offset x, 0
    invoke WriteConsoleA, outhandle, edi ,1, offset x, 0
	invoke WriteConsoleA, outhandle, offset space ,1, offset x, 0

	mov ecx,10
	L2:
	push ecx
	
    invoke WriteConsoleA, outhandle, esi ,1, offset x, 0
	invoke WriteConsoleA, outhandle, offset space ,1, offset x, 0
	pop ecx
	inc esi
	inc eax
	Loop L2
	inc edi
	jmp L1
	endd:
 ret
 printGrid endp

 ;Method that places bombs in backend grid when called.
 ;Places 10 bombs in 10*10 grid
 bombPlace proc uses ecx
 mov ecx, 10
 l1:
 mov eax, lengthof backG
 call generaterandom
 mov backG[eax], "*"
 loop l1
 ret
 bombPlace endp


 ; Checks bombs around the selected position. 
 ; Returns value in esi.
 CheckSurrounding proc uses eax ebx edx 
 mov esi,0          ; counter for bombs around the selected position
 mov edx, 0
 movzx eax, position
 ;cmp eax,0
 Minus1p:
 push eax
 dec eax
 push eax
 mov ebx, 10
 cdq
 div ebx
 pop eax
 cmp edx, 9
 je Plus1p
 cmp backG[eax], "*"
 jne Plus1p
 inc esi
 Plus1p: 
 pop eax
 inc eax
 push eax
 mov ebx, 10
 cdq
 div ebx
 pop eax
 cmp edx, 0
 je Minus10
 cmp backG[eax], "*"
 jne Minus10
 inc esi

 movzx eax, position
 Minus10:
 push eax
 sub eax, 10
 cmp eax, 0
 jl Plus10
 cmp backG[eax], "*"
 jne Minus1b
 inc esi
 Minus1b:
 push eax 
 dec eax
 push eax
 mov ebx, 10
 cdq
 div ebx
 pop eax
 cmp edx, 9
 je Plus1b
 cmp backG[eax], "*"
 jne Plus1b
 inc esi
 Plus1b:
 pop eax 
 inc eax
 push eax
 mov ebx, 10
 cdq
 div ebx
 pop eax
 cmp edx, 0
 je Plus10
 cmp backG[eax], "*"
 jne Plus10
 inc esi

 Plus10:
movzx eax, position
 add eax, 10
 cmp eax, 99
 jg endd
 cmp backG[eax], "*"
 jne Minus1f
 inc esi
 Minus1f:
 push eax 
 dec eax
 push eax
 mov eax, 10
 cbw
 div ebx
 pop eax
 cmp edx, 9
 je Plus1f
 cmp backG[eax], "*"
 jne Plus1f
 inc esi
 Plus1f:
 pop eax
 inc eax
 push eax
 mov ebx, 10
 cbw
 div ebx
 pop eax
 cmp edx, 0
 je endd
 cmp backG[eax], "*"
 jne endd
 inc esi
 endd:
 pop eax
 ret
 CheckSurrounding endp
 
 
 main proc
 invoke GetStdHandle, -11
 mov outhandle, eax
 invoke GetStdHandle, -10
 mov inhandle, eax

 invoke WriteConsoleA, outhandle, offset space ,1, offset x, 0
 invoke WriteConsoleA, outhandle, offset space ,1, offset x, 0
 invoke WriteConsoleA, outhandle, offset welcome ,lengthof welcome, offset x, 0 
 call bombPlace
 mov edi, 0
 invoke GetTickCount
 mov ebp,eax
 push ebp
 GameStart:
 ;invoke SetConsoleCursorPosition, outhandle ,0
 invoke WriteConsoleA, outhandle, offset nextline ,1, offset x, 0
 invoke WriteConsoleA, outhandle, offset nextline ,1, offset x, 0
 call printGrid                     ;Prints grid
 cmp edi, 90
 jne AskPosition
 GameWon:
 invoke WriteConsoleA, outhandle, offset won,lengthof won, offset x, 0
 jmp EndGame
 AskPosition:
 invoke WriteConsoleA, outhandle, offset nextline ,1, offset x, 0
 invoke WriteConsoleA, outhandle, offset nextline ,1, offset x, 0
 invoke WriteConsoleA, outhandle, offset ask ,lengthof ask, offset x, 0
 invoke WriteConsoleA, outhandle, offset askr ,lengthof askr, offset x, 0
 invoke ReadConsoleA, inhandle, offset rowS ,lengthof rowS, offset x, 0
 invoke WriteConsoleA, outhandle, offset askc ,lengthof askc, offset x, 0
 invoke ReadConsoleA, inhandle, offset colS ,lengthof colS, offset x, 0

 mov rowS[1],0
 mov rowS[2],0
 mov colS[1],0
 mov colS[2],0

 mov ecx, 0
 mov edx,0
 ;Row:
 ;mov bh, selection[ecx]
 ;cmp bh, 20h
 ;je column
 ;mov rowS[edx],bh
 ;inc edx
 ;inc ecx
 ;jmp Row
 ;column:
 ;inc ecx
 ;mov edx, 0
 ;mov bh, selection[ecx]
 ;cmp bh, 0
 ;je Conversion
 ;mov colS[edx],bh
 ;inc edx
 ;jmp column
 
 Conversion:
 mov esi, offset rowS         ;converting string of row into number
 call ToDecimal
 mov i,al
 mov esi, offset colS         ;converting string of column into number
 call ToDecimal
 mov j, al

 PositionSelected:            ;Determination of exact position in game array.
 mov bl,10                    
 mov al,i
 mul bl
 add al,j
 mov position,al
 cmp position, 99
 jng nextcheck
 jmp InvalidInput
 nextcheck:
 cmp position,0
 jnl CheckBomb
 InvalidInput:
 invoke WriteConsoleA, outhandle, offset error ,lengthof error, offset x, 0
 jmp AskPosition
 mov ebx,0
 movzx eax,position
 inc edi

 CheckBomb:
 mov bl, backG[eax]
 cmp bl,bomb
 je GameOver
 

 call CheckSurrounding

 mov eax, esi
 mov esi, offset count
 call ToString
 mov al, [esi]
 movzx ebx, position
 mov frontG[ebx], al

 mov ecx,0
 mov eax,0
 mov edx,0
 checking:
  mov al,frontG[ebx]
  cmp al,"_"
  je incri
  inc edx
  incri:
  inc ecx
  cmp ecx,100
  jne checking

  cmp edx,89
  je GAMEWIN


 jmp GameStart
 GAMEWIN:
  invoke WriteConsoleA, outhandle, offset won ,lengthof won, offset x, 0
  jmp EndGame




 GameOver:
  pop ebp
 invoke GetTickCount
 
 sub eax,ebp
 mov ecx,1000
 cdq
 div ecx
 mov eax,edx
 mov esi,offset caltime
 call ToString

 mov eax,0
 mov ebx,0
 mov ecx,0
 copyingbombs:
 mov bl,backG[eax]
 cmp bl,"*"
 jne dontcopy
mov  frontG[eax],bl
 dontcopy:
 inc eax
 cmp eax,100
 jne copyingbombs
 call printGrid





 invoke WriteConsoleA, outhandle, offset Bombed,lengthof bombed, offset x, 0
  invoke WriteConsoleA, outhandle, offset Displaytime,lengthof Displaytime, offset x, 0
  invoke WriteConsoleA, outhandle, offset caltime,lengthof caltime, offset x, 0
 EndGame:
 mov eax, 0
 





 main endp


 end main






























