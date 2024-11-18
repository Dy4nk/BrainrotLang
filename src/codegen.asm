section .data
indentLevel db 0                 ; Tracks current indentation level (debugging)
outputBuffer times 4096 db 0     ; Output buffer for generated code
outputIndex dd 0                 ; Current position in the output buffer
newline db 10, 0                 ; Newline character for output

section .bss
tempVarCounter resd 1            ; Counter for temporary variables (for expressions)
labelCounter resd 1              ; Counter for unique labels

section .text
global codegenStart

; ------------------------
; Code Generation Functions
; ------------------------

codegenStart:
    ; Entry point for code generation
    ; rdi: pointer to the root AST node
    push rdi                  ; Save root node pointer
    call generateNode         ; Generate code starting from the root node
    pop rdi                   ; Restore root node pointer
    ret

generateNode:
    ; Generate code for the current AST node
    ; rdi: pointer to the AST node
    ; AST node structure assumed to have:
    ;   - type: Node type (e.g., expression, statement)
    ;   - left: Pointer to left child
    ;   - right: Pointer to right child
    ;   - value: Value or operator
    mov rax, [rdi + 0]          ; Load node type
    cmp rax, NODE_EXPR          ; Is it an expression?
    je generateExpression
    cmp rax, NODE_STMT          ; Is it a statement?
    je generateStatement
    ret

generateExpression:
    ; Generate code for an expression
    ; Example: a + b
    ; rdi: Pointer to the expression node
    mov rax, [rdi + 0]          ; Get operator type
    cmp rax, OP_ADD             ; Is it addition?
    je generateAddition
    cmp rax, OP_SUB             ; Is it subtraction?
    je generateSubtraction
    cmp rax, OP_MUL             ; Is it multiplication?
    je generateMultiplication
    cmp rax, OP_DIV             ; Is it division?
    je generateDivision
    ret

generateAddition:
    ; Generate code for addition
    ; rdi: Pointer to addition node
    push rdi
    mov rdi, [rdi + 8]          ; Left operand
    call generateNode
    pop rdi
    mov rdi, [rdi + 16]         ; Right operand
    call generateNode
    ; Emit ADD instruction
    lea rdi, [outputBuffer]
    call emitCode
    ret

generateStatement:
    ; Generate code for a statement
    ; Example: Assignment, loops, etc.
    mov rax, [rdi + 0]          ; Load statement type
    cmp rax, STMT_ASSIGN        ; Assignment statement
    je generateAssignment
    cmp rax, STMT_LOOP          ; Loop statement
    je generateLoop
    ret

generateAssignment:
    ; Generate code for an assignment
    ; Example: x = y + 1
    ; rdi: Pointer to assignment node
    push rdi
    mov rdi, [rdi + 8]          ; Left side (variable)
    call generateNode
    pop rdi
    mov rdi, [rdi + 16]         ; Right side (expression)
    call generateNode
    ; Emit MOV instruction
    lea rdi, [outputBuffer]
    call emitCode
    ret

generateLoop:
    ; Generate code for a loop
    ; Example: while (condition) { body }
    ; rdi: Pointer to loop node
    push rdi
    mov rdi, [rdi + 8]          ; Loop condition
    call generateNode           ; Generate condition code
    pop rdi
    mov rdi, [rdi + 16]         ; Loop body
    call generateNode           ; Generate body code
    ; Emit JMP and conditional jumps
    lea rdi, [outputBuffer]
    call emitCode
    ret

emitCode:
    ; Emits assembly instructions to the output buffer
    ; rdi: Pointer to string containing the instruction
    lea rsi, [outputBuffer + outputIndex]
    call strcpy                 ; Copy instruction to buffer
    add dword [outputIndex], rax ; Increment buffer index
    ret

strcpy:
    ; Copy a null-terminated string from rdi to rsi
    push rdi
    push rsi
strcpyLoop:
    mov al, [rdi]
    stosb
    inc rdi
    test al, al
    jnz strcpyLoop
    pop rsi
    pop rdi
    ret
