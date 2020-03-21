;@see https://stackoverflow.com/questions/27105410/tasm-checking-arguments-when-cx-is-modified
;---------------------------------------------------------------------------------------------------------------------
; uloha_5.asm
; 
; Description: "Vypísať obsah vstupu v hexadecimálnom tvare. Na začiatku každého riadku vypísať posunutie prvej vypisovanej hodnoty od začiatku."
;
; TODO - budem delat string comparation: https://www.quora.com/How-do-I-write-a-string-comparison-in-an-assembly-language
;      - kak budem obrabativat druhie prepinaci
;        1. nastavim flag
;           esli vo flage tak 1 perechodim na druhuju cast
;           esli tak to perechodim
;           inace - idem normalnym flow-om
;
;
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
params         db 30 dup('$')
newLineSign    db 1 dup('N')
offsetCounter  dw 0
filename       db 10 dup('$')
filehandle     dw ?
buffer         db 640 dup('$') 
HelperMessage          db 'Usage message here', 10, 13,'$'
wrongParametersMessage db 'Wrong parameter.',10,13,'Available parameters:',10,13,'-h - for showing help',10,13,'-p - as linux less comand',10,13,'-r - for reverse output',10,13,'-s - for alfabetic ordered output',10,13,'$'
OpenFileErrorMessage   db 'No such file.',10, 13, '$'
ReadFileErrorMessage   db 'Read error occurred.',10, 13, '$'
CloseFileErrorMessage  db 'Close file error occured.', 10, 13, '$'
NoParamsMesage         db 'No params was entered', 10, 13, '$'
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

main proc


; GET OPTIONS
mov ah, 40h         ; DOS 2+ - WRITE - WRITE TO FILE OR DEVICE
mov bx, 1           ; File handle = STDOUT
xor ch, ch
mov cl, ds:[0080h]  ; CX: number of bytes to write
cmp cx, 1
jge processParams
jmp normalFlow

processParams:
  xor dx, dx
  mov dx, 81h         ; DS:DX -> data to write (command line)
 ; int 21h             ; Call MSDOS

parseParameters:
 
  mov si, offset dx
  ; rrr:mov dl, [si]
  ; inc si
  ; mov ah, 2;
  ; int 21h
  ; loop rrr
  ; mov dl, 10
  ; mov ah, 2
  ; int 21h
  ; mov dl, 13
  ; mov ah, 2
  ; int 21h
  ;-----
  ; copy all params to sting
  
  ; sochranit cx
  ; zapusit v stack loop
  ; vypusit v param 
  mov bx, cx
  add si, cx
  dec si
  pushArgs:
    mov dl, [si]
    dec si
    push dx   
    ; mozet dec cx?
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
    print filename
    jmp stop


normalFlow:         ;normal program flow
  mov  ax, @data
  mov  ds, ax   
 



; OPEN FILE
  mov ax,3d02h		; open file
			; 3d is DOS command to open file
			; 02 is read/write mode in al
  lea dx,filename	; specifying file name
  int 21h		; execute command
  jc openError 		; if error
  mov filehandle,ax
  jmp readFile

  openError:
    print OpenFileErrorMessage
    jmp stop

; READ FILE			
  readFile:
    mov ah,3fh		
    mov bx,filehandle
    mov cx, 0000FA00h   
    lea dx,buffer
    int 21h
    jc readError
    print buffer
    jmp converASCCI_to_Hexo 

  readError:
    print ReadFileErrorMessage
    jmp stop
  
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
    jmp closeFile
 
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
    
    LOOP getHex2

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

; CLOSING FILE
  closeFile:
    mov ah,3eh
    mov bx,filehandle
    int 21h
    jc closeError


; ENDS PROGRAM
  jmp stop

  ; error messages
  
    
  closeError:
    print CloseFileErrorMessage
    jmp stop
    
  wrongParameters:
    print wrongParametersMessage
    jmp stop 
    
  showHelper:
    print HelperMessage
    jmp stop  
  
  ; ends the program  
  stop:
    mov ax, 4c00h
    int 21h

main endp
end main