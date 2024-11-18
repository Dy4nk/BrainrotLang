section .data
inputFile db "program.yap", 0          ; Default input file
outputFile db "program.asm", 0         ; Output file for generated assembly
errorNoFile db "Error: No input file provided.", 10, 0
errorFileOpen db "Error: Cannot open input file.", 10, 0
errorFileWrite db "Error: Cannot write to output file.", 10, 0
newline db 10, 0

section .bss
fileDescriptor resd 1    ; Input file descriptor
astRoot resq 1           ; Pointer to the root of the AST

section .text
global _start

_start:
    ; Entry point of the program
    ; Parse command-line arguments to get input file
    mov rdi, [rsp + 8]             ; Get argv[1]
    test rdi, rdi
    jz useDefaultInputFile

    ; Open the specified input file
    mov rsi, rdi                  ; File name
    jmp openInputFile

useDefaultInputFile:
    lea rsi, [inputFile]           ; Default file name

openInputFile:
    mov rax, 2                    ; syscall: open
    mov rdi, rsi                  ; File path
    xor rsi, rsi                  ; Read-only mode
    syscall
    mov [fileDescriptor], eax     ; Store file descriptor
    test eax, eax
    js fileError

    ; Step 1: Tokenize the input file
    call lexerStart               ; Lexer entry point
    ; Tokens are now available in `tokenBuffer`

    ; Step 2: Parse tokens into an AST
    call parserStart              ; Parser entry point
    mov [astRoot], rax            ; Store the root of the AST

    ; Step 3: Generate code from AST
    mov rdi, [astRoot]            ; Pass AST root to codegen
    call codegenStart             ; Codegen entry point

    ; Step 4: Write generated assembly to the output file
    lea rsi, [outputFile]         ; Output file name
    mov rax, 1                    ; syscall: open (write)
    mov rdi, rsi                  ; File path
    mov rsi, 577                  ; Flags: O_CREAT | O_WRONLY
    mov rdx, 0644                 ; Permissions: rw-r--r--
    syscall
    test eax, eax
    js fileError
    mov rdi, eax                  ; File descriptor for output

    ; Write the generated code from the buffer
    lea rsi, [outputBuffer]
    mov rdx, [outputIndex]        ; Number of bytes to write
    mov rax, 1                    ; syscall: write
    syscall
    test rax, rax
    js fileWriteError

    ; Step 5: Clean up and exit
    mov rax, 60                   ; syscall: exit
    xor rdi, rdi                  ; Exit status 0
    syscall

fileError:
    ; Print error and exit
    mov rdi, errorFileOpen
    call printString
    mov rax, 60
    xor rdi, rdi
    syscall

fileWriteError:
    ; Print error and exit
    mov rdi, errorFileWrite
    call printString
    mov rax, 60
    xor rdi, rdi
    syscall

printString:
    ; Print a null-terminated string
    ; rdi: Address of string
    mov rsi, rdi                  ; String pointer
    mov rdx, newline              ; Add newline after the message
    mov rax, 1                    ; syscall: write
    mov rdi, 1                    ; STDOUT
    syscall
    ret

