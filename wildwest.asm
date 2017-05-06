; Project made by Yoav Shai.
; The image files should be 320x200, 256 color BMPs.
; When I wrote this thing, only God and I knew how it worked.
; 																								Today? He stands alone.

IDEAL
MODEL small
STACK 100h
DATASEG

	played db 0 ; used to flag whether we should show insturctions or not
	fails db 0 ; used for main menu fail counting
	oneSec db ?
	loopUntil db ?
	waitSeconds db ?
	waitMilli db ?
; ------------------------------ SCORE PRINTING -------------------------------

	wWinsCountMsg db 13,10,'W key wins: ','$' ; 13, 10 maybe?
	upWinsCountMsg db 13,10,'Up arrow wins: ','$',13,10
	lineDown db 13,10,'$'
	upWinsCount db 0
	wWinsCount db 0
	divisorTable db 10,1,0
	tieMsg db 13,10,'It is a tie!', 13, 10, '$'
	upWonMsg db 13,10,'Up key won!', 13, 10, '$'
	wWonMsg db 13,10,'W key won!', 13, 10, '$'

;	------------------------------------ KEYS -----------------------------------

	enterkey equ 1Ch
	downarrow equ 50h
	uparrow equ 48h
  wkey equ 11h
	spacebar equ 39h
	esckey equ 1h

; ----------------------------- BMP PRINTING VARS -----------------------------

	bmp_test db 'test.bmp',0
	filehandle dw ?
	currentlyopen dw ? ; used to store the file that's currently open
	openflag db ? ; 1 = a file is open. 0 = a file isn't open.
	Header db 54 dup (0)
	Palette db 256*4 dup (0)
	ScrLine db 320 dup (0)
	ErrorMsg db 'Error opening a file, bleep bloop.',13,10,'$'

; ---------------------------------- IMAGES -----------------------------------

	bmp_mainMenu db 'mainmenu.bmp',0
	bmp_onefail db 'onef.bmp',0
	bmp_twofails db 'twof.bmp',0
	bmp_threefails db 'threef.bmp',0
	bmp_fourfails db 'fourf.bmp',0
	bmp_fivefails db 'fivef.bmp',0
	bmp_mainMenuQuitSelected db 'quit.bmp',0
	bmp_mainMenuPlaySelected db 'play.bmp',0
	bmp_gameInstructions db 'instr.bmp',0
	bmp_gameInstructionsTwo db 'instrtwo.bmp',0
	bmp_countdownthree db 'three.bmp',0
	bmp_countdowntwo db 'two.bmp',0
	bmp_countdownone db 'one.bmp',0
	bmp_notyet db 'notyet.bmp',0
	bmp_shoot db 'shoot.bmp',0
	bmp_upWon db 'upwon.bmp',0
	bmp_wWon db 'wwon.bmp',0
	bmp_getready db 'getready.bmp',0


CODESEG ; --------------------------- CODE ------------------------------------

; ------------------------------ SCORE PRINTING -------------------------------

proc printNumber
	push ax
	push bx
	push dx
	mov bx, offset divisorTable
	nextDigit:
		xor ah, ah
		div [byte ptr bx] ; al - quotinent, ah - remainder, ax/bx scores/divtable
		add al, '0'
		call PrintCharacter
		mov al, ah
		add bx, 1
		cmp [byte ptr bx], 0
		jne nextDigit
	pop dx
	pop bx
	pop ax
	ret
endp printNumber

proc printCharacter
	push ax
	push dx
	mov ah, 2
	mov dl, al
	int 21h
	pop dx
	pop ax
	ret
endp printCharacter


	; -------------------------- END SCORE PRINTING -----------------------------
proc WaitForKeypress ; ah = scancode, al = ASCII
	mov ah, 0
	int 16h
	cmp ah, 1h
	je escpressed
	ret
	escpressed:
	call SwitchToText
	mov ax, 4c00h
	int 21h
endp WaitForKeypress

proc WaitAnyKeypress
	push ax
	mov ah, 0
	int 16h
	cmp ah, 1h ; esc key
	je escpressed
	pop ax
	ret
endp WaitAnyKeypress

proc GetKeypress ;scancode in ah, ascii in al

 WaitingLoop:
	mov ah, 1
	int 16h
	jz WaitingLoop
	mov ah, 0 ; if we've reached this point, there's a key in the buffer
	int 16h ; let's read it!
	ret

endp GetKeypress

proc PushAll ; not used
	pop di
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	ret
endp PushAll

proc PopAll ; not used
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	push di
	ret
endp PopAll

proc SwitchToGraphic
	push ax
	mov ax, 13h
	int 10h
	pop ax
	ret
endp SwitchToGraphic

proc SwitchToText
	push ax
	mov ax, 0002h
	int 10h
	pop ax
	ret
endp SwitchToText

proc OpenFile ; file offset should be in dx
	mov ah, 3Dh
	xor al, al
;	mov dx, offset filename
	int 21h
	jc openerror
	mov [filehandle], ax
	mov [currentlyopen], ax
	mov [openflag], 1
	ret
	openerror:
		mov dx, offset ErrorMsg
		mov ah, 9h
		int 21h
		ret
endp OpenFile

proc CloseFile ; can't have too many files open
	mov ah, 3Eh
	mov bx, [currentlyopen]
	int 21h
	mov [openflag], 0
	ret
endp CloseFile

proc ReadHeader
	mov ah, 3fh
	mov bx, [filehandle]
	mov cx, 54
	mov dx, offset Header
	int 21h
	ret
endp ReadHeader

proc ReadPalette
	mov ah, 3fh
	mov cx, 400h
	mov dx, offset palette
	int 21h
	ret
endp ReadPalette

proc CopyPal
	mov si, offset Palette
	mov cx, 256
	mov dx, 3C8h
	mov al, 0
	out dx, al
	inc dx
	PalLoop:
		mov al, [si+2]
		shr al, 2
		out dx, al
		mov al, [si+1]
		shr al, 2
		out dx, al
		mov al, [si]
		shr al, 2
		out dx, al
		add si, 4
		loop PalLoop
		ret
endp CopyPal

proc CopyBitmap
	mov ax, 0A000h
	mov es, ax
	mov cx, 200
	PrintBMPLoop:
		push cx
		mov di, cx
		shl cx, 6
		shl di, 8
		add di, cx
		mov ah, 3fh
		mov cx, 320
		mov dx, offset ScrLine
		int 21h
		cld
		mov ax, 320
		mov si, offset ScrLine
		rep movsb
		pop cx
		loop PrintBMPLoop
		ret
endp CopyBitmap

proc PrintBMPFile ;you should have the bmp's offset in dx
	cmp [openflag], 0
	je nofileopen
	call CloseFile
	nofileopen:
	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	ret
endp PrintBMPFile

proc WaitASecond
	push ax
	push cx
	push dx
	mov ah, 2Ch
	int 21h ; get time. seconds in dh, milliseconds in dl.
	cmp dh, 59
	je resetSeconds
	afterResetSeconds:
	mov [waitSeconds], dh
	mov [waitMilli], dl
	WaitASecondLoop:
		mov ah, 1
		int 16h
		jnz somethingWasPressed ; needed to check if they pressed ESC
		mov ah, 2Ch
		int 21h ; get time
		mov ch, dh
		sub ch, 2
		cmp ch, [waitSeconds]
		je doneWaiting ; in case when testing ms were very high
		cmp dh, [waitSeconds]
		je WaitASecondLoop ; if we're at the same second, check again later
		cmp dl, [waitMilli]
		jl WaitASecondLoop
	doneWaiting:
	pop dx
	pop cx
	pop ax
	ret
	resetSeconds:
	sub dh, 60
	jmp afterResetSeconds
	somethingWasPressed:
	mov ah, 0
	int 16h
	cmp ah, esckey
	jne WaitASecondLoop
	call SwitchToText
	mov ax, 4C00h
	int 21h
endp WaitASecond

proc WaitASecondOld ; completely halts the program for a second.
	push ax
	push cx
	push dx
	mov cx, 0Fh
	mov dx, 4240h
	mov ah, 86h
	int 15h
	pop dx
	pop cx
	pop ax
	ret
endp WaitASecondOld



proc GetScancode ; The scan code will get placed in al

	WaitForScancodeLoop:
	in al, 64h
	cmp al, 10b ; Is the buffer empty?
	je WaitForScancodeLoop
	in al, 60h
	cmp al, 1 ; ESC button
	je killme
	ret
	killme:
	call SwitchToText
	mov ax, 4c00h
	int 21h

endp GetScancode

start:
	mov ax, @data
	mov ds, ax
	call SwitchToGraphic
mainMenu: ; Main menu section. This will let the players pick 'play' or 'quit'
	mov dx, offset bmp_mainMenu ; MAIN MENU bmp file
	call PrintBMPFile
	xor cx, cx ; cx will later act as the fail counter
mainMenuSelect:
	call WaitForKeypress ; returns scancode in al
	cmp ah, uparrow
	je mainMenuPlaySelected
	cmp ah, downarrow
	je mainMenuQuitSelected
;	jmp mainMenuSelect ; uncomment to enable no fails mode - DEBUG

mainMenuFail: ; if the code has reached this point, it means the user has
							; typed an invalid key. We will count his fails and fuck him up.
	mov dl, [fails]
	inc dl
	mov [fails], dl
	; now we will see how many times user has failed, punish him appropriately
	cmp [fails], 1
	je onefail
	cmp [fails], 2
	je twofails
	cmp [fails], 3
	je threefails
	cmp [fails], 4
	je fourfails
	cmp [fails], 5
	je fivefails ; the last straw
	onefail:
		mov dx, offset bmp_onefail ; press one of the arrow buttons ya dip
		call PrintBMPFile
		jmp mainMenuSelect
	twofails:
		mov dx, offset bmp_twofails ; either the up or down keys
		call PrintBMPFile
		jmp mainMenuSelect
	threefails:
		mov dx, offset bmp_threefails ; holy shit, are you fucking retarded
		call PrintBMPFile
		jmp mainMenuSelect
	fourfails:
		mov dx, offset bmp_fourfails ; do it ONE more time.
		call PrintBMPFile
		jmp mainMenuSelect
	fivefails:
		mov dx, offset bmp_fivefails ; done playing, FUCK OFF message
		call PrintBMPFile
		call WaitASecond
		jmp exit
	mainMenuPlaySelected:
		mov dx, offset bmp_mainMenuPlaySelected
		call PrintBMPFile
	mainMenuPlaySelectedTwo:
		call WaitForKeypress
		cmp ah, downarrow
		je mainMenuQuitSelected
		cmp ah, enterkey
		je beforePlaying
		cmp ah, spacebar
		je beforePlaying
		jmp mainMenuPlaySelectedTwo
	mainMenuQuitSelected:
		mov dx, offset bmp_mainMenuQuitSelected
		call PrintBMPFile
	mainMenuQuitSelectedTwo:
		call WaitForKeypress
		cmp ah, uparrow
		je mainMenuPlaySelected
		cmp ah, spacebar
		je QuitAndShowScores
		cmp ah, enterkey
		jne mainMenuQuitSelectedTwo ; no need in printing again

		; code reaching this point means the user has pressed enter.
		; we shall display the scores and quit the game.
QuitAndShowScores:
		call SwitchToText
		mov dx, offset wWinsCountMsg
		mov ah, 9
		int 21h
		xor ax, ax
		mov al, [wWinsCount]
		call printNumber ; we now have w's score printed
		mov dx, offset upWinsCountMsg
		mov ah, 9
		int 21h
		xor ax, ax
		mov al, [upWinsCount]
		call printNumber
		mov dx, offset lineDown
		mov ah, 9h
		int 21h

		; checking who won
		mov al, [upWinsCount]
		mov ah, [wWinsCount]
		cmp al, ah
		jg printUpWonMsg
		je printTieMsg
		; reaching this point means W won
		mov dx, offset wWonMsg
		printBeforeQuitting:
		mov ah, 9
		int 21h

		; quitting here.
		mov ax, 4C00h
		int 21h

		printUpWonMsg:
		mov dx, offset upWonMsg
		jmp printBeforeQuitting

		printTieMsg:
		mov dx, offset tieMsg
		jmp printBeforeQuitting

beforePlaying: ;no need in showing the instructions a second time
	cmp [played], 1
	je playTheGame
gameInstructions:
	mov dx, offset bmp_gameInstructions
	call PrintBMPFile
	call WaitASecond ; we don't want them to accidentally skip this.
gameInstructionsAfterWait:
	mov dx, offset bmp_gameInstructionsTwo
	call PrintBMPFile
	call WaitAnyKeypress
playTheGame:
	mov dx, offset bmp_getready
  call PrintBMPFile
;  call WaitASecond ; give them a second to get ready
;  mov dx, offset bmp_countdownthree
;  call PrintBMPFile
;  call WaitASecond
;  mov dx, offset bmp_countdowntwo
;  call PrintBMPFile
;  call WaitASecond
;  mov dx, offset bmp_countdownone
;  call PrintBMPFile
;  call WaitASecond
;  mov dx, offset bmp_notyet

; --------------------------- uncomment these lines for countdown -------------
randomNumber:
  mov ah, 2Ch
  int 21h ; time is now in ch:cl:dh:dl
  and dl, 00000111b ; max is 7
	inc dl ; making sure they have at least one second
	add dl, dh ; we want to loop until currsec+rand[1-7]
	cmp dl, 59
	jle SaveLoopUntil ; if it won't flow, no reason to change anything
	sub dl, 60 ; the timer will flow to the next minute, so we'll adjust accordingly

	SaveLoopUntil:
	mov [loopUntil], dl

	; wait for a new second to start the timer
	mov ah, 2Ch ; get curr time
	int 21h
	mov [oneSec], dh ; save current second

	WaitForTick:
		int 21h
		cmp dh, [oneSec]
		je WaitForTick ; as long as we are in the same second, keep looping.

	LoopWhileChecking:
	mov ah, 2Ch
	int 21h ; get time, seonds in dh
	cmp dh, [loopUntil]
	je ShootingAllowed
	mov ah, 1
	int 16h ; read keyboard status
	jz LoopWhileChecking
	mov ah, 0
	int 16h ; we now have the key
	cmp ah, uparrow
	je wWon
	cmp ah, wkey
	je upWon
	cmp ah, esckey
	je exit
	loop LoopWhileChecking

; if we've reached this point, it means the times is done. Players should be able
; to shoot now.
ShootingAllowed:
  mov dx, offset bmp_shoot
  call PrintBMPFile
scanwhopressed:
	; waiting for input, no need for complex loops now
	call WaitForKeypress
	cmp ah, uparrow
	je upWon
	cmp ah, wkey
	je wWon
	jmp scanwhopressed

wWon:
	mov [played], 1
	add [wWinsCount], 1
	mov dx, offset bmp_wWon
	call PrintBMPFile
	call WaitASecond
	jmp mainMenuPlaySelected

upWon:
	mov [played], 1
	add [upWinsCount], 1
	mov dx, offset bmp_upWon
	call PrintBMPFile
	call WaitASecond
	jmp mainMenuPlaySelected

exit:
	call SwitchToText
	mov ax, 4c00h
	int 21h

END start ; finito la comedia
