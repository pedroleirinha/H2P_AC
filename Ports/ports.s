    .equ INPUTPORT_ADDR, 0xFFB0
    .equ OUTPUTPORT_ADDR, 0xFFC0

    .text 

    B program
    B . ; Reservado (ISR)

program:
    LDR sp, stack_top_addr
    B   main


;START MAIN
main:

    B



inport_read:
    ldr r0, input_port_addr
    ldrb r0, [r0]
    mov pc, lr


outport_write:
    ldr r1, out_port_addr
    strb r0, [r1]

    ldr r1, out_port_img_addr
    ldrb r1, [r1]
    
    strb r0, [r1]

    mov pc, lr


outport_clr_bits:
    PUSH LR
    
    LDR r1, out_port_img_addr
    LDRB r1, [r1]

    MVN r0, r0
    AND r0, r0, r1

    BL outport_write
    
    POP PC

;MASK - R0, VALUE - R1
outport_write_bits:
    PUSH LR
    
    LDR r2, out_port_img_addr
    LDRB r2, [r2]

    AND r0, r0, r1
    ORR r0, r2, r0

    ; and r1,r0,r1
    ; mvn r0,r0
    ; and r0,r2,r0
    ; orr r0,r0,r1

    BL outport_write
    
    POP PC


;MASK - R0
outport_set_bits:
    PUSH LR
    
    LDR r1, out_port_img_addr
    LDRB r1, [r1]

    ORR r0, r0, r1

    BL outport_write
    
    POP PC


input_port_addr:
    .word INPUTPORT_ADDR

out_port_addr:
    .word OUTPUTPORT_ADDR

out_port_img_addr:
    .byte outport_imgOUTPUTPORT_ADDR


    .data
outport_img:
    .space 1
