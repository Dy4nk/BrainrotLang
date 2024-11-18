; I miss C, man...
section .data
keywords db "yap", 0, "cap", 0, "pog", 0, "goon", 0, "vibecheck", 0, "thug", 0, "zesty", 0, "digits", 0, "skibidi", 0, "rizz", 0, "bussin", 0, "fr", 0, "edging", 0, 0
symbols db "+", "-", "*", "/", "=", "(", ")", "{", "}", ";", 0
newline db 10, 0
tabChar db 9, 0

errorNoFile db "Error: No input file specified.", 10, 0
errorFileOpen db "Error: Could not open file.", 10, 0
errorUnsupported db "Error: Unsupported character detected.", 10, 0
errorBufferOverflow db "Error: Token buffer overflow.", 10, 0

section .bss
fileDescriptor resd 1
char resb 1
tokenBuffer times 256 db 0
tokenIndex resd 1

section .text
global _start

_start:
    ; Parse command-line arguments
    mov rdi, [rsp + 8] ; Pointer to argv[1]
    test rdi, rdi
    jz no_input_file

    ; Open the input file
    mov rax, 2 ; syscall: open
    mov rdi, rdi ; Pass the file path
    mov rsi, 0 ; Read-only mode
    syscall
    mov [fileDescriptor], eax

    ; Check if the file opened successfully
    cmp eax, 0
    jl file_error

    ; Tokenize the file
    call tokenize

    ; Debug: Print token buffer
    call debugPrintTokens

    ; Exit the program
    mov rax, 60 ; syscall: exit
    xor rdi, rdi
    syscall

no_input_file:
    mov rdi, errorNoFile
    call printString
    mov rax, 60
    xor rdi, rdi
    syscall

file_error:
    mov rdi, errorFileOpen
    call printString
    mov rax, 60
    xor rdi, rdi
    syscall

tokenize:
    ; Read the file one character at a time
    mov rdi, [fileDescriptor]
tokenizeLoop:
    mov rsi, char
    mov rdx, 1
    mov rax, 0 ; syscall: read
    syscall
    cmp rax, 0 ; EOF check
    jz tokenize_done

    ; Detect comments starting with //
    movzx rax, byte [char]
    cmp al, '/'
    jne checkClassification

    ; Read the next character
    mov rsi, char
    mov rdx, 1
    mov rax, 0 ; syscall: read
    syscall
    cmp rax, 0 ; EOF check
    jz tokenize_done
    movzx rax, byte [char]
    cmp al, '/'
    jne checkClassification

    ; Detected `//`, skip until newline
skipComment:
    mov rsi, char
    mov rdx, 1
    mov rax, 0 ; syscall: read
    syscall
    cmp rax, 0 ; EOF check
    jz tokenize_done
    movzx rax, byte [char]
    cmp al, newline
    jne skipComment
    jmp tokenizeLoop

checkClassification:
    ; Classify the character
    call classifyChar
    jmp tokenizeLoop

tokenize_done:
    ret

classifyChar:
    ; Handle symbols
    lea rsi, [symbols]
    call matchSymbol
    test al, al
    jnz addSymbolToken

    ; Handle keywords
    lea rsi, [keywords]
    call matchKeyword
    test al, al
    jnz addKeywordToken

    ; Handle identifiers
    mov al, [char]
    call isAlpha
    test al, al
    jnz readIdentifier

    ; Handle numbers
    mov al, [char]
    call isDigit
    test al, al
    jnz readNumber

    ; Handle whitespace
    cmp al, ' '
    je doneClassification
    cmp al, tabChar
    je doneClassification
    cmp al, newline
    je doneClassification

    ; Handle unsupported characters
    call reportUnsupportedChar
    jmp doneClassification

doneClassification:
    ret

matchSymbol:
    ; Compare the character in `char` with symbols
    mov al, [char]
    movzx rcx, byte [rsi]
symbolLoop:
    cmp rcx, 0 ; End of symbols array
    je symbolNotFound
    cmp al, cl ; Compare char with symbol
    je symbolFound
    inc rsi
    movzx rcx, byte [rsi]
    jmp symbolLoop

symbolFound:
    mov al, 1
    ret

symbolNotFound:
    xor al, al
    ret

matchKeyword:
    ; Compare current word with known keywords
    lea rdi, tokenBuffer
    lea rsi, [keywords]
    call compareStrings
    test al, al
    jnz keywordFound

    xor al, al
    ret

readIdentifier:
    ; Reads a sequence of alphanumeric characters and stores in tokenBuffer
    mov rsi, char
    lea rdi, tokenBuffer
readIdentifierLoop:
    mov al, [rsi]
    call isAlpha
    test al, al
    jz readIdentifierDone
    stosb ; Store character in tokenBuffer
    inc rsi
    jmp readIdentifierLoop

readIdentifierDone:
    ret

readNumber:
    ; Reads a sequence of numeric characters
    mov rsi, char
    lea rdi, tokenBuffer
readNumberLoop:
    mov al, [rsi]
    call isDigit
    test al, al
    jz readNumberDone
    stosb
    inc rsi
    jmp readNumberLoop

readNumberDone:
    ret

addSymbolToken:
    ; Add the symbol to the token buffer
    call ensureBufferSpace
    mov rax, tokenIndex
    mov [tokenBuffer + rax], char
    inc tokenIndex
    ret

addKeywordToken:
    ; Add a keyword token to the buffer
    call ensureBufferSpace
    mov rax, tokenIndex
    mov [tokenBuffer + rax], char
    inc tokenIndex
    ret

ensureBufferSpace:
    mov rax, tokenIndex
    cmp rax, 255
    jl bufferOK
    mov rdi, errorBufferOverflow
    call printString
    mov rax, 60
    xor rdi, rdi
    syscall

bufferOK:
    ret

reportUnsupportedChar:
    mov rdi, errorUnsupported
    call printString
    ret

printString:
    ; Print a string to stdout
    mov rsi, rdi
    mov rax, 1 ; syscall: write
    mov rdi, 1 ; stdout
    syscall
    ret

debugPrintTokens:
    lea rsi, [tokenBuffer]
debugLoop:
    mov al, [rsi]
    cmp al, 0
    je debugDone
    mov rdi, al
    call printChar
    inc rsi
    jmp debugLoop
debugDone:
    ret

printChar:
    ; Print a single character to stdout
    mov rsi, char
    mov rdx, 1
    mov rax, 1 ; syscall: write
    mov rdi, 1 ; stdout
    syscall
    ret

