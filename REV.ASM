; SPROTY VYPOCET :)
; format vypisu od 2eho riadku: 
; 50:424242424242424242424242424242424242424242424242424 ; 50 je posunutie, ':' - oddelovac, 42h - 'B'ASCII
; Kedze chcem aby najvatsi buffer v pamati bol 65535 - tak musim si vyratat kolko znakov chcem scitavat na raz, lebo pri transformacii v hexo - kazda pismeno bude 2 znaky
; 65535/2 = 32767 + 1    						                     ; tu by som vedel ze mozem nacitat 32767
; citam - 32767                						  	           ; ale potom musiel by som pridat aj posunutia znaku od riadka
; v prerobenom mam - 65534 + 1('$')                        
; obratno - 65535 + numbers(???) // horsi pripar ked kazdy char na osobitnom riadku. pre tento zapis potrebovali by sme 32767 riadkov a na kazdom urcite viac viac ako 1 znak(od 2 riadku ktoru ma posunutie 				 50 - 2 znaky) na uchova => preskocili by sme 65535
; preto chcem si zvolit predpoklad, kolko budem mat znakov na jednom riadku (stredna hodnota) - bude to 50
; 111111111111111111111111111111111111111111111111111 // 50
; 32767/50 = 656 vapross :                                                ; znamena to ze by sme mali mat 656 riadkov
; 2 - 2znaky // 2									; na 2om riadku 2 znaky(pre zapis 50)
; 3az 20 (3+(950-100)%50) - 3znaky //3*18 = 54		                        ; na 3om az 20om 3 znaky(pre zapis 100,150,200,....950 arifm postupnost)
; 21 az  202 (22+(9950-950)%50) - 4znaky // 4*201 = 804                   ; na 21 az 202 riadku 4 znaky(pre zapis 1000,1050....,9950 arifm postupnost)
; 203 az 656 // 5 znakov // 5*453 = 2265  		                          	; na 203 az 656om riadku 5 znakov( pre zapis 10000, 10050 az ~32000 arifm postupnost)
; summ of al character which i need to print positions                    ; celkovy pocet potrebnych znakov je 3125
; + oddelovac na kazdy riadok // 3125+655 = 3780                          ; musime pridat aj 655 oddelovacich znakov ':' na zacitok ridku
; 											                                                  ; 3780 znakov celkovo mame vyhradit pre zapis posunutia
; takze by sme mali vyhradit pre jedno nacitanie 32767 - 3780 = 28987
; ale tym padom ked sme zmensili pocet pismen re pocitanie, zmensil sa aj pocet riadkov a posunutia 
; vediem k tomu ze niekde je ta hran medzi 28987 a 32767 znakov ktore budu presne pasovat pre max. percent vyuzitia tej pamati na nacitavanie => menej nacitanij ale uz to pocitat nebudem
; a za predpokladu ze kazdy riadok obsahuje v strednom 50 znakov pouziem uplne dostatocne 28987 bajtov na nacitavanie kusov suboru
;@see https://stackoverflow.com/questions/27105410/tasm-checking-arguments-when-cx-is-modified
;---------------------------------------------------------------------------------------------------------------------
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
;----------------------------------------------------------------------------------------------------------------------  

model small

; STACK ----------------------------------------------------------------------------------------------------------------
.stack 100h
; ----------------------------------------------------------------------------------------------------------------------


; DATA -----------------------------------------------------------------------------------------------------------------
.data 
newLineSign db 1 dup('N')
filename   db 'test.txt',0
filehandle dw ?
buffer     db 250 dup('$') 
bufferHex  db 250 dup('$')
param      db 10 dup(0)
paramH     db '-h', '$'
HelperMessage          db 'Usage message here', 10, 13,'$'
wrongParametersMessage db 'Wrong parameter.',10,13,'Available parameters:',10,13,'-h - for showing help',10,13,'-p - as linux less comand',10,13,'-r - for reverse output',10,13,'-s - for alfabetic ordered output',10,13,'$'
OpenFileErrorMessage   db 'No such file.',10, 13, '$'
ReadFileErrorMessage   db 'Read error occurred.',10, 13, '$'
CloseFileErrorMessage  db 'Close file error occured.', 10, 13, '$'

NoParamsMesage db 'No params was entered', 10, 13, '$'
; ----------------------------------------------------------------------------------------------------------------------


.code


; MACROS ---------------------------------------------------------------------------------------------------------------
; Prints content of msg
print MACRO msg        
      mov ah, 09h
      lea dx, msg
      int 21h
      endm

; Prints buferr and counts positions - new lines
printBuffer MACRO buff 
      mov ah, 09h
      lea dx, msg
      int 21h
      endm
; ----------------------------------------------------------------------------------------------------------------------

; PROCEDURE ------
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
      ; mov  si, offset strHelper
    cycle2:  
      pop  dx        
      add  dl, 48         ;CONVERT DIGIT TO CHARACTER.
      mov  [ si ], dl
      inc  si
      loop cycle2  

      ret
endp  
;@endsrc
; --------

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
  jmp readFile

  openError:
    print OpenFileErrorMessage
    jmp stop

; READ FILE			
  readFile:
    mov ah,3fh		
    mov bx,filehandle
    mov cx, 0000FFFFh   
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
    cmp al, 10
    je newLineHandler
    cmp al, '$'        ; is end of buffer
    jne div2            ; if end of buferr - stop programm
    jmp countLetterPossitionInBuffer
 
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
    ; mov ah, 2;
    ; int 21h
    
    LOOP getHex2

    jmp getChar;
    
  moreHex2:
    add dl, 7h
    jmp hexRet2

  newLineHandler:
    mov dl, newLineSign
    mov [di], dl
    inc di
    jmp getChar

; PRINT _16 OUTPUT
countLetterPossitionInBuffer: 

    mov si, offset buffer
    mov di, offset bufferHex
    mov cx, 0                   ; Initialize the counter

    processLetter:
      mov dx, 0                   ; Clear DX
      xor ax, ax         ; set ax to 0
      mov al, [di]   ; get char from bufferHex
      inc di
      cmp al, 'N'
      je newLineChanger
      inc cx
      cmp al, '$'        ; is end of buffer
      jne addLetterToBuffer
      jmp readyBuffer
    
      newLineChanger:
        mov dl, 10
        mov [si], dl
        inc si
        ; mov dl, 13
        ; mov [si], dl
        ; inc si
        mov ax, cx
        shr ax, 1
        call number2string
        mov dl, ':'
        mov [si], dl
        inc si
        jmp processLetter

      addLetterToBuffer:
        mov dl, al
        mov [si], dl
        inc si
        jmp processLetter

      readyBuffer:
        mov [si], '$'
        print buffer

; CLOSING FILE
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
 

