section .data
newline db 10, 0
inputBuffer times 256 db 0 ; Buffer for user input
errorAlloc db "Error: Memory allocation failed.", 10, 0

section .bss
heapStart resq 1        ; Pointer to the start of the heap
heapEnd resq 1          ; Pointer to the end of the allocated heap

section .text
global _start

_start:
    ; Initialize heap (start after .bss)
    lea rax, [heapEnd]
    mov [heapStart], rax

    ; Example: Call a stdlib function (yap example below)
    ; mov rdi, msg
    ; call yap

    ; Exit program
    mov rax, 60          ; syscall: exit
    xor rdi, rdi         ; status: 0
    syscall

; ------------------------
; Standard Library Functions
; ------------------------

; yap - Print a string to stdout
; rdi: pointer to null-terminated string
yap:
    mov rsi, rdi          ; String pointer
    call stringLength     ; Calculate string length
    mov rdx, rax          ; String length
    mov rax, 1            ; syscall: write
    mov rdi, 1            ; file descriptor: stdout
    syscall
    ret

; yapLn - Print a string followed by a newline
; rdi: pointer to null-terminated string
yapLn:
    call yap              ; Print the string
    mov rdi, newline      ; Print newline
    call yap
    ret

; input - Read input from the user
; rdi: buffer for input
; rsi: maximum number of bytes to read
input:
    mov rax, 0            ; syscall: read
    mov rdi, 0            ; file descriptor: stdin
    syscall
    ret

; malloc - Allocate memory on the heap
; rdi: size (in bytes)
; Returns:
; rax: pointer to allocated memory (or 0 on failure)
malloc:
    mov rax, [heapStart]  ; Current heap start
    add rax, rdi          ; Calculate new heap pointer
    cmp rax, [heapEnd]    ; Ensure it doesn't exceed heapEnd
    ja allocFail          ; Fail if out of memory
    mov [heapStart], rax  ; Update heapStart
    sub rax, rdi          ; Return the start of the allocated block
    ret

allocFail:
    xor rax, rax          ; Return null pointer
    ret

; stringLength - Calculate the length of a null-terminated string
; rdi: pointer to the string
; Returns:
; rax: length of the string
stringLength:
    xor rax, rax          ; Length counter
strlenLoop:
    mov bl, byte [rdi]
    cmp bl, 0             ; Null terminator?
    je strlenDone
    inc rdi
    inc rax
    jmp strlenLoop
strlenDone:
    ret

; strcmp - Compare two null-terminated strings
; rdi: pointer to string1
; rsi: pointer to string2
; Returns:
; rax: 0 if equal, non-zero if not equal
strcmp:
    xor rax, rax
strcmpLoop:
    mov al, byte [rdi]
    mov bl, byte [rsi]
    cmp al, bl
    jne stringsNotEqual
    test al, al
    je stringsEqual       ; Both strings ended at the same time
    inc rdi
    inc rsi
    jmp strcmpLoop
stringsNotEqual:
    mov rax, 1            ; Non-zero indicates not equal
    ret
stringsEqual:
    xor rax, rax          ; Zero indicates equal
    ret

; strcpy - Copy a string from source to destination
; rdi: pointer to destination
; rsi: pointer to source
; Returns:
; rax: pointer to destination
strcpy:
    push rdi              ; Save destination pointer
strcpyLoop:
    mov al, byte [rsi]
    stosb
    test al, al
    jnz strcpyLoop
    pop rax               ; Restore destination pointer
    ret

; atoi - Convert a string to an integer
; rdi: pointer to null-terminated string
; Returns:
; rax: integer value
atoi:
    xor rax, rax          ; Result
    xor rbx, rbx          ; Sign (+1 or -1)
    mov bl, 1             ; Default sign is positive
atoiLoop:
    mov cl, byte [rdi]    ; Current character
    cmp cl, 0
    je atoiDone           ; End of string
    cmp cl, '-'
    jne atoiDigit
    mov bl, -1            ; Negative sign
    inc rdi
    jmp atoiLoop
atoiDigit:
    sub cl, '0'
    cmp cl, 9
    ja atoiDone           ; Non-digit character
    imul rax, rax, 10
    add rax, rcx
    inc rdi
    jmp atoiLoop
atoiDone:
    imul rax, rax, rbx    ; Apply sign
    ret

; itoa - Convert an integer to a string
; rdi: integer value
; rsi: pointer to buffer
; Returns:
; rax: pointer to buffer
itoa:
    xor rdx, rdx          ; Clear remainder
    xor r8, r8            ; Digit counter
    mov rbx, rdi          ; Copy integer value
    test rdi, rdi
    jns itoaPositive
    mov byte [rsi], '-'   ; Add negative sign
    inc rsi
    neg rdi
itoaPositive:
itoaLoop:
    xor rdx, rdx
    mov rcx, 10
    div rcx               ; Divide rax by 10
    add dl, '0'           ; Convert remainder to ASCII
    push rdx              ; Store digit
    inc r8                ; Increment digit counter
    test rax, rax
    jnz itoaLoop
itoaWrite:
    pop rdx
    mov [rsi], dl         ; Write digit
    inc rsi
    dec r8
    jnz itoaWrite
    mov byte [rsi], 0     ; Null-terminate
    ret

