


main:
    push LR

    mov r0, #0
    mov r1, #3

    bl indexof_max

    POP PC

    b .

indexof_max:
    ;r4 = a
    ;r5 = n
    ;r6 = idx
    ;r7 = i
    ;r8 = val
    mov r4, r0
    mov r5, r1 
    mov r6, #0
    mov r7, #0
    mov r8, #0

    push LR
    push r4
    push r5
    push r6
    push r7
    push r8


while:
    cmp r7, r5
    bge out

    lsl r7, r7, #1
    LDR r0, [r4, r7]
    lsr r7, r7, #1

    bl abs

    mov r1, r8
    cmp r1, r0

    bhs continue
    mov r8, r0
    mov r6, r7

continue:
    add r7, r7, #1

    b while

out: 
    mov r0, r6

    pop r8
    pop r7
    pop r6
    pop r5
    pop r4


    pop PC

; r0 = v
abs:
    mov r1, #0
    cmp r0, r1 ;Subtrai o primeiro pelo segundo. r0 - r1
    bge return 
    sub r0, r1, r0

return:
    mov pc, lr


