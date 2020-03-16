;@see https://stackoverflow.com/questions/27105410/tasm-checking-arguments-when-cx-is-modified
;------------------------------------------------------------------------------------------------
; uloha_5.asm
; 
; there is description text
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
; Assembler: TASM
; OS: Any Win32-based OS
;
; Assemble with: "tasm uloha_5.asm"
; Link with: "link uloha_5.obj"
; Execute with: "uloha_5.exe"
;           OR
; Assemle + Link + Execute: "compile.bat uloha_5"
;------------------------------------------------------------------------------------------------

model small

.stack 100h

.data
offsetBufferHex dw ?
strHelper  db  6 dup(?)
filename   db 'test.txt',0
filehandle dw ?
buffer     db 100 dup('$') 
bufferHex db 200 dup(0)
param  db 10 dup(0)
paramH db '-h', '$'
HelperMessage db 'Usage message here', 10, 13,'$'
wrongParametersMessage db 'Wrong parameter.',10,13,'Available parameters:',10,13,'-h - for showing help',10,13,'-p - as linux less comand',10,13,'-r - for reverse output',10,13,'-s - for alfabetic ordered output',10,13,'$'
OpenFileErrorMessage  db 'No such file.',10, 13, '$'
ReadFileErrorMessage  db 'Read error occurred.',10, 13, '$'
CloseFileErrorMessage db 'Close file error occured.', 10, 13, '$'
DebugMessage          db 'The program4ik go through breakpoint',10,13,'$'
msg0 db 'OK0', 10, 13, '$'
msg1 db 'OK1', 10, 13, '$'
msg2 db 'OK2', 10, 13, '$'
msg3 db 'OK3', 10, 13, '$'

NoParamsMesage db 'No params was entered', 10, 13, '$'

.code

; MACROS
print MACRO msg
      mov ah, 09h
      lea dx, msg
      int 21h
      endm

;@src: https://www.quora.com/How-do-I-write-a-string-comparison-in-an-assembly-language
cmpStr MACRO str1, str2 
      mov bx, 00
      mov bl, str1+1
      mov bg, str2+2

      cmp bl,bh
      jne l1
      
      add si, 2
      add di, 2
      
      l2: 
        mov bl, byte ptr[si]
        cmp byte ptr[di], bl
        jne l1
        inc si
        inc di
        cmp byte ptr[di], "$"
        jne l2
        
        mov ax, 1

      l1: 
        mov ax, 0
endm
;@endsrc

; PROCEDURES
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
      mov  si, offset strHelper
    cycle2:  
      pop  dx        
      add  dl, 48         ;CONVERT DIGIT TO CHARACTER.
      mov  [ si ], dl
      inc  si
      loop cycle2  

      ret
endp  
;@endsrc


main proc


; INITIALIZE DS
mov  ax, @data
mov  ds, ax   


; GET OPTIONS
;mov ah, 40h         ; DOS 2+ - WRITE - WRITE TO FILE OR DEVICE
;mov bx, 1           ; File handle = STDOUT
;;xor cx, cx
;;mov cl, ds:[0080h]   ; CX: number of bytes to write;
;cmp cl, 0
;;mov al, cl

; jge processeParams   ; need to process entered params

;jnz processeParams
;int 21h             ; Call MSDOS
;print NoParamsMesage
;jmp stop   


; OPEN FILE
  mov ax,3d02h		; open file
			; 3d is DOS command to open file
			; 02 is read/write mode in al
  lea dx,filename	; specifying file name
  int 21h		; execute command
  jc openError 		; if error
  mov filehandle,ax


; READ FILE			
  mov ah,3fh		
  mov bx,filehandle
  mov cx,32h  
  lea dx,buffer
  int 21h
  jc readError
 	
; convertion for one character
  mov bx, 16                  ; Set up the divisor (base 16)
  mov si, offset buffer
  mov di, offset bufferHex

  ; in AX should be a char
  getChar:
    mov cx, 0                   ; Initialize the counter
    mov dx, 0                   ; Clear DX
    xor ax, ax         ; set ax to 0
    mov al, [si]   ; get char from buffer
    inc si
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
    mov [di], dl
    inc di
    mov ah, 2;
    int 21h
    
    LOOP getHex2

    jmp getChar;
    
  moreHex2:
    add dl, 7h
    jmp hexRet2



; PRINT FILE
  print bufferHex


; CLOSING FILE
  mov ah,3eh
  mov bx,filehandle
  int 21h
  jc closeError

; ENDS PROGRAM
  jmp stop

  ; error messages
  openError:
    print OpenFileErrorMessage
    jmp stop
    
  closeError:
    print CloseFileErrorMessage
    jmp stop

  readError:
    print ReadFileErrorMessage
    jmp stop
  
  ; processing parameters
  processeParams:
    mov dx, 81h         ; DS:DX -> data to write (command line)
    mov param, 81h
    jmp stop
    ; cmpStr dx, paramH 
    ; jne wrongParameters
    ; jmp showHelper
  
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
 

