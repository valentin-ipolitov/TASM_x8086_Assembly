;---------------------------------------------------------------------------------------------------------------------
; uloha_5.asm + additional tasks numbers: 
; 
; Description: 
;   "Vypísať obsah vstupu v hexadecimálnom tvare. Na začiatku každého riadku vypísať posunutie prvej vypisovanej hodnoty od začiatku."
;
; Hardware + software
;   Processor: intel 8086
;   Assembler: TASM
;
; Compile:
;   Assemble with: "tasm uloha_5.asm"
;   Link with: "link uloha_5.obj"
;   Execute with: "uloha_5.exe"
;           OR
;   Assemle + Link + Execute: "compile.bat uloha_5"
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
flag           db 1 dup(0)         ; flag byte representation |x|x|x|x|x|x|r|h|
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

; CODE -----------------------------------------------------------------------------------------------------------------
.code
  
; MAIN
; Main part of code. 
; All procedures called from here
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

; PROC number2string
; Explanaition:
;   converting number to string
;   during convertions prints out the string on the screen
; WhereItUsed:
;   print character offset
; Usage:
;   mov to AX the number to print on screen and "call number2string"
; HowItWorks:
;   In first cycle - pushing in stack reminders after deviding AX by 10.
;   Continue to devide AX by 10, until AX is greater than 0.
;   In second cycle pop digits from stack,
;   add 48 - ASCII '0'
;   print digit on screen
; Reference: https://stackoverflow.com/questions/29568631/how-to-print-the-contents-of-a-register-in-emu8086
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

; PROC number2string
; Explanaition:
;   getting command line arguments into DX register
; HowItWorks:
;   get number of parameters bytes into CX 
;   get all CMDparameters into DX
proc getCLIArguments
  xor ch, ch            ; set CH = 0
  mov cl, ds:[0080h]    ; CX = number of bytes to write
  cmp cx, 1             ; if there is parameters
  jge getParams         ; then get them
  ret;jmp normalFlow        ; otherwise - skip this part and go to normalFlow(without parameters manipulations)

  getParams:
    xor dx, dx          ; set DX = 0
    mov dx, 82h         ; mov into DX pointer to parameters 'str'
    
  ret
endp

; PROC number2string
; Explanaition:
;   parsing parameters, thats had been stored into DX
; HowItWorks:
;   1. First of all, we shoul get filename from parameters and save it
;      problem is, that we cant save filename before we initialize DATA segment, but
;      if we initialize DATA segment to DX register, then we override our parameters(we dont want it)
;      so...we need to temperary store our parameters somewhere, where it will not be overriden 
;      after DATA segment initialization - STACK. 
;      First we storirng our parameters to STACK, but PUSHing bytes from the end of params, because we dont want
;      our params to be reverse after POP it back.
;   2. Getting filename into 'filename' string
;   3. Getting options, as '-h', '-r'
;   4. Set my own flag - 'flag'
proc parseCLIArguments
  cmp cx, 1             ; if there is parameters
  jge parseParameters         ; then get them
  ret

  parseParameters:
    mov si, offset dx           ; get pointer to parameters into SI
    mov bx, cx                  ; temperary save number of bytes of parameters string to BX
    add si, cx                  ; move pointer SI to the end of parameters string
    dec si                      ; remove '$'
    pushArgs:
      mov dl, [si]              ; mov into DL current byte
      dec si                    ; move pointer one char back
      push dx                   ; push char current byte into stack
      loop pushArgs             ; looping till cx is greater than 0 (loop instruction automaticli decrements CX register)

    mov  ax, @data              ; initializing DATA segment
    mov  ds, ax   
    
    
    mov cx, bx                  ; het num of parameters byte back to CX
    mov di, offset params       ; DI = pointer to parameters str
    popArgs:                    ; start of pop from stack
      pop dx                    ; pop byte from stack into DX
      mov [di], dx              ; store byte in parameters string
      inc di                    ; move pointer on parameters
      loop popArgs              ; looping until we do not get all bytes into params 
    

    mov si, offset params       ; si = pointer to params
    mov di, offset filename     ; di = pointer to filename
    mov cx, bx                  ; CX = number of params bytes

    passSpace:                  ; removing all spaces befor filename
      mov dl, [si]              ; get param byte
      inc si                    ; move pointer params one byte further
      dec cx                    ; decremnt CX
      cmp dl, 20h               ; check is current byte equal to ' '(space)
      je passSpace              ; if true => continue passing spaces
      cmp dl, '-'               ; check is current byte equal to '-'
      je showHelper             ; if true => show helper messagee, because it is wrong, fist char should be filename char
      jmp getFileName           ; if we dont have ' ' or '-', then it is start of filename

    showHelper:
      print HelperMessage     
      jmp stop                  ; stop program
    
    getFileName:                ; getting filename
      mov byte ptr [di], dl     ; move DL byte to filename pointer
      inc di                    ; move filename pointer one byte further
      mov dl, [si]              ; get next byte from params
      inc si                    ; move params pointer one byte further
      dec cx                    ; decriment CX
      cmp cx, 0                 ; if no bytes left in params (the end of filename and nothing else after it)
      jle getOpts               ; go to getOpts
      cmp dl, ' '               ; check is byte equal ' '(space)
      jne getFileName           ; untill byte not ' '(space), continiu adding butes to bilename
                                ; otherwise go next, normal flow => getOpts

    getOpts:                    ; getting options, as '-h', '-r'
      mov dl, [si]              ; move to DL params byte  
      inc si                    ; move params pointer one byte further
      cmp dl, '-'               ; if byte = '-', then we need to get next char
      je getParam               ; so jump to getParams
      dec cx                    ; decrement CX
      cmp cx, 1                 ; if we dont hawe no params
      jge getOpts               ; otherwise continiu getting options as,'-h', '-r' 
      ret
    
    getParam:
      mov dl, [si]              ; move to DL params byte
      inc si                    ; move params pointer one byte further
      dec cx                    ; decrement number of parameters byte left
      cmp dl, 'h'               ; is parameter 'h'
      je setFlagH               ; then jump to setFlagH
      cmp dl, 'r'               ; is parameter 'r'
      je setFlagR               ; then jump to setFlagR
      jmp getOpts               ; otherwise continue to get options
      
    setFlagH:                  
      mov ax, 1                 ; mov to ax, 1 
      or flag, al               ; add to flag H=1
      jmp getOpts               ; continue to get options
    
    setFlagR:
      mov ax, 2                 ; mov to ax, 2 
      or flag, al               ; add to flag H=2
      jmp getOpts               ; continue to get options
  ret
endp


; PROC openFile
; Explanaition:
;   initializing DATA segment and open file to read
proc openFile
  
  normalFlow:                   ; normal program flow
    mov  ax, @data              ; initialize DATA segment
    mov  ds, ax                 
  
  mov al, 1                     ; chcek is h flag set
  and al, flag
  cmp al, 0
  je openFileJMP                ; if not set => jump to openFileJMP
  print HelperMessage           ; otherwise print helper message continue normal flow

  ; OPEN FILE
  openFileJMP:
    mov ax,3d00h	              ; open file: 3d is DOS command to open file, 00 is read mode 
    lea dx,filename	            ; specifying file name
    int 21h		                  ; execute command
    jc openError 		            ; if error
    mov filehandle,ax           ; getting file handler
    ret                         ; jump to read file

    openError:                  ; if errors occured => print error message
      print OpenFileErrorMessage
      jmp stop
  ret
endp


; PROC readFile
; Explanaition:
;   read file to buffer
proc readFile 
  readFile:
    mov ah,3fh		              ; DOS read from file instruction
    mov bx,filehandle           ; mov filehandler to bx
    mov cx, 0000FA00h           ; specify number of bytes to read
    lea dx,buffer               ; mov pointer  where write data
    int 21h                     ; execute command
    jc readError                ; if errors occured => print error message
    ret          

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
    ret
    
  closeError:
    print CloseFileErrorMessage
    jmp stop

  ret
endp
  
proc mainProgram
  isReverse:                       ; check is reverse flag set
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
; ----------------------------------------------------------------------------------------------------------------------

end main