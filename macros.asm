
; MACROS ---------------------------------------------------------------------------------------------------------------

; Prints content of msg
print MACRO msg        
      mov ah, 09h
      lea dx, msg
      int 21h
      endm

reverseString MACRO string        
      mov cx, 0
      mov si, offset string
      pushStr:
            mov dl, [si]
            ; mov ah, 2
            ; int 21h
            inc si
            inc cx
            cmp dx, '$'
            je popStr
            push dx  
            jmp pushStr 


      ;pop
      mov di, offset string
      popStr:
            pop dx
            mov [di], dx
            ; mov ah, 2
            ; int 21h
            inc di
            loop popStr
      mov [di], '$'
    
endm

      
       
; ----------------------------------------------------------------------------------------------------------------------