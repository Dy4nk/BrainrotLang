section .data
errorUnexpectedToken db "Error: Unexpected token encountered.", 10, 0
errorMissingSemicolon db "Error: Missing semicolon.", 10, 0
errorInvalidSyntax db "Error: Invalid syntax.", 10, 0
errorEmptyInput db "Error: No input to parse.", 10, 0

validTypes db "int", 0, "char", 0, "float", 0, 0
assignOp db '=', 0
semicolon db ';', 0

section .bss
currentToken resb 256  ; Current token being processed
tokenIndex resd 1      ; Index of the token being processed
tokenBuffer times 256 db 0 ; Tokenized input from the lexer
treeBuffer times 1024 db 0 ; Space to store the parse tree

section .text
global _start

_start:
    ; Initialize token index
    xor eax, eax
    mov [tokenIndex], eax

    ; Begin parsing
    call parseTokens

    ; Exit the program
    mov rax, 60 ; syscall: exit
    xor rdi, rdi
    syscall

parseTokens:
    ; Ensure input is not empty
    mov rsi, tokenBuffer
    cmp byte [rsi], 0
    je reportEmptyInput

parseLoop:
    ; Fetch the next token
    call getNextToken
    test al, al
    jz parseDone ; End of tokens

    ; Parse constructs
    call parseStatement
    jmp parseLoop

parseDone:
    ret

parseStatement:
    ; Parse a single statement (e.g., variable declaration, assignment, or function call)

    ; Check for valid type (e.g., int, char)
    lea rsi, [validTypes]
    call matchKeyword
    test al, al
    jnz parseDeclaration

    ; Check for assignment
    mov al, [currentToken]
    cmp al, assignOp
    je parseAssignment

    ; Check for function call or invalid token
    call parseFunctionCall
    ret

parseDeclaration:
    ; Handle variable declarations: type identifier = value;

    ; Get the next token (identifier)
    call getNextToken
    call isIdentifier
    test al, al
    jz invalidSyntax

    ; Check for assignment operator
    call getNextToken
    mov al, [currentToken]
    cmp al, assignOp
    jne invalidSyntax

    ; Get the value
    call getNextToken
    call isValue
    test al, al
    jz invalidSyntax

    ; Ensure semicolon
    call getNextToken
    mov al, [currentToken]
    cmp al, semicolon
    jne missingSemicolon

    ; Successfully parsed a declaration
    ret

parseAssignment:
    ; Handle assignment: identifier = value;

    ; Check that the token is an identifier
    call isIdentifier
    test al, al
    jz invalidSyntax

    ; Get the next token (assignment operator)
    call getNextToken
    mov al, [currentToken]
    cmp al, assignOp
    jne invalidSyntax

    ; Get the value
    call getNextToken
    call isValue
    test al, al
    jz invalidSyntax

    ; Ensure semicolon
    call getNextToken
    mov al, [currentToken]
    cmp al, semicolon
    jne missingSemicolon

    ; Successfully parsed an assignment
    ret

parseFunctionCall:
    ; Handle function calls: identifier(args);
    call isIdentifier
    test al, al
    jz invalidSyntax

    ; Check for '('
    call getNextToken
    mov al, [currentToken]
    cmp al, '('
    jne invalidSyntax

    ; Parse arguments (optional)
    call parseArguments

    ; Check for ')'
    call getNextToken
    mov al, [currentToken]
    cmp al, ')'
    jne invalidSyntax

    ; Ensure semicolon
    call getNextToken
    mov al, [currentToken]
    cmp al, semicolon
    jne missingSemicolon

    ; Successfully parsed a function call
    ret

parseArguments:
    ; Parse a comma-separated list of arguments (if any)
    call getNextToken
parseArgLoop:
    call isValue
    test al, al
    jz argDone ; No more arguments

    ; Check for ','
    call getNextToken
    mov al, [currentToken]
    cmp al, ','
    jne argDone

    ; Get the next argument
    call getNextToken
    jmp parseArgLoop
argDone:
    ret

getNextToken:
    ; Fetch the next token from the token buffer
    mov eax, [tokenIndex]
    lea rsi, [tokenBuffer + rax]
    mov rdi, currentToken
    call copyString
    inc eax
    mov [tokenIndex], eax
    mov al, [rdi] ; Check if token is null
    test al, al
    ret

isIdentifier:
    ; Check if the current token is an identifier (alphanumeric starting with a letter)
    mov rsi, currentToken
    mov al, [rsi]
    call isAlpha
    test al, al
    jz notIdentifier
    ret

notIdentifier:
    xor al, al
    ret

isValue:
    ; Check if the current token is a value (number, string, etc.)
    mov rsi, currentToken
    mov al, [rsi]
    call isDigit
    test al, al
    jnz isValidValue
    ; Add checks for other types (e.g., strings) if necessary
    xor al, al
    ret

isValidValue:
    mov al, 1
    ret

copyString:
    ; Copy a null-terminated string from rsi to rdi
copyLoop:
    mov al, [rsi]
    stosb
    test al, al
    jnz copyLoop
    ret

matchKeyword:
    ; Compare currentToken against a list of valid keywords
    lea rdi, currentToken
    lea rsi, [validTypes]
matchLoop:
    movzx al, byte [rsi]
    cmp al, 0
    je keywordNotFound
    lea rdi, currentToken
    call compareStrings
    test al, al
    jz matchDone
    add rsi, 4 ; Skip to next keyword (length = 4 with null terminator)
    jmp matchLoop

matchDone:
    mov al, 1
    ret

keywordNotFound:
    xor al, al
    ret

invalidSyntax:
    mov rdi, errorInvalidSyntax
    call printString
    mov rax, 60
    xor rdi, rdi
    syscall

missingSemicolon:
    mov rdi, errorMissingSemicolon
    call printString
    mov rax, 60
    xor rdi, rdi
    syscall

reportEmptyInput:
    mov rdi, errorEmptyInput
    call printString
    mov rax, 60
    xor rdi, rdi
    syscall

printString:
    ; Print a null-terminated string to stdout
    mov rsi, rdi
    mov rdx, newline
    mov rax, 1 ; syscall: write
    mov rdi, 1 ; stdout
    syscall
    ret
