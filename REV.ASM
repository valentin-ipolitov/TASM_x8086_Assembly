;@see https://stackoverflow.com/questions/27105410/tasm-checking-arguments-when-cx-is-modified
;---------------------------------------------------------------------------------------------------------------------
; uloha_5.asm
; 
; Description: "Vypísať obsah vstupu v hexadecimálnom tvare. Na začiatku každého riadku vypísať posunutie prvej vypisovanej hodnoty od začiatku."
;
;
; Processor: intel 8086
; Assembler: TASM
;
; Assemble with: "tasm uloha_5.asm"
; Link with: "link uloha_5.obj"
; Execute with: "uloha_5.exe"
;           OR
; Assemle + Link + Execute: "compile.bat uloha_5"
;----------------------------------------------------------------------------------------------------------------------  

model compact

; STACK ----------------------------------------------------------------------------------------------------------------
.stack 100h
; ----------------------------------------------------------------------------------------------------------------------

; INCLUDES -------------------------------------------------------------------------------------------------------------
INCLUDE macros.asm
; ----------------------------------------------------------------------------------------------------------------------

; DATA -----------------------------------------------------------------------------------------------------------------
.data 
flag           db 1 dup(0)
params         db 30 dup('$')
newLineSign    db 1 dup('N')
offsetCounter  dw 0
filename       db 10 dup('$')
filehandle     dw ?
buffer         db 640 dup('$') 
HelperMessage          db 'Available parameters:',10,13,'-h - for showing help',10,13,'-p - as linux less comand',10,13,'-r - for reverse file data output',10,13,'-s - for alfabetic ordered output',10,13,'$'
OpenFileErrorMessage   db 'No such file.',10, 13, '$'
ReadFileErrorMessage   db 'Read error occurred.',10, 13, '$'
CloseFileErrorMessage  db 'Close file error occured.', 10, 13, '$'
; ----------------------------------------------------------------------------------------------------------------------

.code

;@src: https://stackoverflow.com/questions/29568631/how-to-print-the-contents-of-a-register-in-emu8086
proc number2string 
  mov  bx, 10             ;DIGITS ARE EXTRACTED DIVIDING BY 10.
  mov  cx, 0              ;COUNTER FOR EXTRACTED DIGITS.
    cycle1:       
      mov  dx, 0          ;NECESSARY TO DIVIDE BY BX.
      div  bx             ;DX:AX / 10 = AX:QUOTIENT DX:REMAINDER.
      push dx             ;PRESERVE DIGIT EXTRACTED FOR LATER.
      inc  cx             ;INCREASE COUNTER FOR EVERY DIGIT EXTRACTED.
      cmp  ax, 0          ;IF NUMBER IS
      jne  cycle1         ;NOT ZERO, LOOP. 
                          ;NOW RETRIEVE PUSHED DIGITS.
    
    cycle2:  
      pop  dx        
      add  dl, 48         ;CONVERT DIGIT TO CHARACTER.
      mov ah, 2;
      int 21h
      loop cycle2  

      ret
endp  
;@endsrc

proc getCLIArguments
  mov ah, 40h         ; DOS 2+ - WRITE - WRITE TO FILE OR DEVICE
  mov bx, 1           ; File handle = STDOUT
  xor ch, ch
  mov cl, ds:[0080h]  ; CX: number of bytes to write
  cmp cx, 1
  jge processParams
  jmp normalFlow

  processParams:
    xor dx, dx
    mov dx, 82h         ; DS:DX -> data to write (command line)
    
  ret
endp

proc parseCLIArguments
  parseParameters:
    mov si, offset dx
    mov bx, cx
    add si, cx
    dec si
    pushArgs:
      mov dl, [si]
      dec si
      push dx   
      loop pushArgs

    mov  ax, @data
    mov  ds, ax   
    
    ;pop
    mov cx, bx
    mov di, offset params
    popArgs:
      pop dx
      mov [di], dx
      inc di
      loop popArgs
    

    mov si, offset params
    mov di, offset filename
    mov cx, bx

    passSpace:
      mov dl, [si]
      inc si
      dec cx
      cmp dl, 20h
      je passSpace
      cmp dl, '-'
      je showHelper
      jmp getFileName

    showHelper:
      print HelperMessage
      jmp stop    
    
    getFileName:
      mov byte ptr [di], dl
      inc di
      mov dl, [si]
      inc si
      dec cx
      cmp cx, 0
      jle getOpts
      cmp dl, ' '
      jne getFileName
    

    getOpts:
      mov dl, [si]
      inc si
      cmp dl, '-'
      je getParam
      dec cx
      cmp cx, 0
      jle normalFlow
      jmp getOpts
    
    getParam:
      mov dl, [si]
      inc si
      dec cx
      cmp dl, 'h'
      je setFlagH
      cmp dl, 'r'
      je setFlagR
      jmp getOpts
      
    setFlagH:
      mov ax, 1
      or flag, al
      jmp getOpts
    
    setFlagR:
      mov ax, 2
      or flag, al
      jmp getOpts
  ret
endp


proc openFile
  normalFlow:         ;normal program flow
    mov  ax, @data
    mov  ds, ax   
  
  mov al, 1
  and al, flag
  cmp al, 0
  je openFileJMP
  print HelperMessage 

  ; OPEN FILE
  openFileJMP:
    mov ax,3d00h		; open file
        ; 3d is DOS command to open file
        ; 00 is read mode in al
    lea dx,filename	; specifying file name
    int 21h		; execute command
    jc openError 		; if error
    mov filehandle,ax
    jmp readFile

    openError:
      print OpenFileErrorMessage
      jmp stop
  ret
endp

proc readFile 
  readFile:
    mov ah,3fh		
    mov bx,filehandle
    mov cx, 0000FA00h   
    lea dx,buffer
    int 21h
    jc readError
    jmp isReverse 

  readError:
    print ReadFileErrorMessage
    jmp stop
  ret
endp

proc closeFile 
  closeFile:
    mov ah,3eh
    mov bx,filehandle
    int 21h
    jc closeError

  closeError:
    print CloseFileErrorMessage
    jmp stop
  ret
endp
  
proc mainProgram
  isReverse:  
    mov al, 2
    and al, flag
    cmp al, 0
    jne reverseStr
    jmp converASCCI_to_Hexo

  reverseStr:
    reverseString buffer

  ; CONVERTION ASCCI TO _16
  converASCCI_to_Hexo:
    mov si, offset buffer

  ; in AX should be a char
  getChar:
    mov bx, 16                  ; Set up the divisor (base 16)
    mov cx, 0                   ; Initialize the counter
    mov dx, 0                   ; Clear DX
    xor ax, ax         ; set ax to 0
    mov al, [si]   ; get char from buffer
    inc si
    inc offsetCounter
    cmp al, 10
    je newLineHandler
    cmp al, '$'        ; is end of buffer
    jne div2            ; if end of buferr - stop programm
    jmp stop

  div2:
    div bx
    push dx ; pocemu pusim dx, kak ostatok po deleniu tuda popodajet ?????

    inc cx
    mov dx, 0
    cmp ax, 0
    jne div2

  getHex2:
    mov dx, 0
    pop dx
    add dl, 30h

  cmp dl, 39h
    jg moreHex2

  hexRet2:
    mov ah, 2;
    int 21h

    loop getHex2

    jmp getChar;

  moreHex2:
    add dl, 7h
    jmp hexRet2

  ; PRINT _16 OUTPUT
  newLineHandler: 
    ; printing new line
    mov dl, 10
    mov ah, 2;
    int 21h
    mov dl, 13
    mov ah, 2;
    int 21h

    ; prining offset number
    mov ax, offsetCounter
    call number2string

    ; printing separator
    mov dl, ':'
    mov ah, 2;
    int 21h

    ; geting next char
    jmp getChar

  ret
endp  
      
main proc
  call getCLIArguments
  call parseCLIArguments
  call openFile
  call readFile
  call closeFile
  call mainProgram

  ; ends the program  
  stop:
    mov ax, 4c00h
    int 21h

main endp

end main