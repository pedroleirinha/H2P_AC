    .equ STACK_SIZE, 64
    .equ BCD_MASK, 0x000F
    .equ INPUTPORT_ADDR, 0xFC00
    .equ OUTPUTPORT_ADDR, 0xF800

    .text 

    B program
    B . ; Reservado (ISR)

program:
    LDR sp, stack_top_addr
    B   main

stack_top_addr:
    .word stack_top


;START MAIN
main:

    mov r0, #0
    bL outport_write

while_loop:

    BL inport_read
    

    LSL r1, r0, #1 ; FAZ um shift left para sacar o bit de EN
    BCC while_loop ; SE nao houver carry, quer dizer que o A15 era 0



    MOV r2, #BCD_MASK ;
    AND r0, r0, r2  ; Ficamos com os 4 bits menos significativos correspondente ao BCD
                    ; Fica logo no r0 para poder passar 

    MOV r3, #9
    cmp r3, r0      ; Verifica se o valor do BCD é menor que 9
                    ; Se for <9 escreve no output port

    BLO while_loop

    ldr r1, display_addr
    ldrb r0, [r1, r0]

    ;output value
    BL outport_write ; Escreve no Output o value em R0

    B while_loop


    B .

display_addr:   .word display

inport_read:
    ldr r0, input_port_addr
    ldr r0, [r0]

    mov pc, lr


outport_write:
    ldr r1, out_port_addr
    strb r0, [r1, #1]

    mov pc, lr


input_port_addr:
    .word INPUTPORT_ADDR

out_port_addr:
    .word OUTPUTPORT_ADDR
    
display:
    .byte 0b00111111 ; zero
    .byte 0b00000110 ; um
    .byte 0b01011011 ; dois
    .byte 0b01001111 ; tres
    .byte 0b01100110 ; quatro
    .byte 0b01101101 ; cinco
    .byte 0b01111101 ; seis
    .byte 0b00000111 ; sete
    .byte 0b01111111 ; oito
    .byte 0b01101111 ; nove


    .stack
    .space STACK_SIZE
stack_top:
 