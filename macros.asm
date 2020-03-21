
; MACROS ---------------------------------------------------------------------------------------------------------------

; Prints content of msg
print MACRO msg        
      mov ah, 09h
      lea dx, msg
      int 21h
      endm

reverseString MACRO params        
      mov cx, 0
      mov si offset params
      pushArgs2:
            mov dl, [si]
            inc si
            inc cx
            push dx   
            cmp dx, '$'
            jne pushArgs2


      ;pop
      mov di, offset params
      popArgs2:
            pop dx
            mov [di], dx
            inc di
            loop popArgs2
endm

      
       
; ----------------------------------------------------------------------------------------------------------------------