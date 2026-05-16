; Ficheiro:  lab04_ex2.S
; Descricao: Programa para a realizacao da 4a atividade laboratorial de
;            Arquitetura de Computadores.
; Autor:     Tiago M Dias (tiago.dias@isel.pt)
; Data:      09-05-2025

; Definicao dos valores dos simbolos utilizados no programa
;
	.equ	STACK_SIZE, 64                ; Dimensao do stack, em bytes
	.equ	ENABLE_EXTINT, 0x10           ; Ativa a flag I do CPSR (ativa as interrupcoes)
	.equ	OUTPORT_ADDRESS, 0xFFC0       ; Endereco do porto de saida
	.equ	INT_CS_ADDRESS, 0xFF00        ; Local em memória para ativar o [nCS_EXT0] Chip select [FF00 a FF3F]
    
	.equ	TCR_ADDRESS, 0xFF00           ; Endereço de memória para ativar o [TCR Register] do pTC
	.equ	TMR_ADDRESS, 0xFF02           ; Endereço de memória para ativar o [TMR Register] do pTC
	.equ	TC_ADDRESS, 0xFF04            ; Endereço de memória para ativar o [TC Register] do pTC
	.equ	TIR_ADDRESS, 0xFF06           ; Endereço de memória para ativar o [TIR Register] do pTC

	.equ	VAR_INIT_VAL, 0               ; Valor inicial de var

; Seccao:    text
; Descricao: Guarda o codigo do programa
;
	.text
	b	program
	b	isr
program:
	ldr	sp, stack_top_addr
    b   main

stack_top_addr:
	.word	stack_top

; Rotina:    main
; Descricao: *** Para completar ***
; Entradas:  *** Para completar ***
; Saidas:    *** Para completar ***
; Efeitos:   *** Para completar ***
main:
	mov	r0, #VAR_INIT_VAL
	ldr	r1, var_addr_main
	strb	r0, [r1, #0]     ; Mete var = 0

	bl	outport_write		 ; Escreve o zero no output port
	mov	r0, #FED_ADDRESS & 0xFF
	movt	r0, #(FED_ADDRESS >> 8) & 0xFF
	strb	r0, [r0, #0]

	mrs	r0, cpsr
	mov	r1, #ENABLE_EXTINT
	orr	r0, r0, r1
	msr	cpsr, r0
main_loop:
	ldr	r0, var_addr_main
	ldrb	r0, [r0, #0]
	bl	outport_write
	b	main_loop

var_addr_main:
	.word	var

; Rotina:    isr
; Descricao: *** Para completar ***
; Entradas:  *** Para completar ***
; Saidas:    *** Para completar ***
; Efeitos:   *** Para completar ***
isr:
	push	r1
	push	r0
	mov	r0, #FED_ADDRESS & 0xFF
	movt	r0, #(FED_ADDRESS >> 8) & 0xFF
	strb	r2, [r0, #0]
	ldr	r0, var_addr_isr
	ldrb	r1, [r0, #0]
	add	r1, r1, #1
	strb	r1, [r0, #0]
	pop	r0
	pop	r1
	movs	pc, lr

var_addr_isr:
	.word	var

; Rotina:    outport_write
; Descricao: Escreve num porto de saida a 8 bits o valor passado como argumento.
;            Interface exemplo: void outport_write( uint8_t value );
; Entradas:  r0 - valor a escrever no porto de saida
; Saidas:    -
; Efeitos:   r1 - guarda o endereco do porto alvo da escrita
outport_write:
	mov	r1, #OUTPORT_ADDRESS & 0xFF
	movt	r1, #(OUTPORT_ADDRESS >> 8) & 0xFF
	strb	r0, [r1, #0]
	mov	pc, lr


; Rotina:    sleep
; Descricao: Faz um atraso de tempo de #1 em r0 e r1
; Entradas:  Recebe r0
; Saidas:    Não têm
; Efeitos:   Altera os registos R0 e R1
sleep:
	and	r0, r0, r0
	beq	sleep_end
sleep_outer_loop:
	mov	r1, #0x3E
	movt	r1, #0x03
sleep_inner_loop:
	sub	r1, r1, #1
	bne	sleep_inner_loop
	sub	r0, r0, #1
	bne	sleep_outer_loop
sleep_end:
	mov	pc, lr





period:
	.byte 0x05 ; 1s
    .byte 0x0A ; 2s
    .byte 0x0F ; 3s
    .byte 0x14 ; 4s
    .byte 0x19 ; 5s
    .byte 0x1E ; 6s
    .byte 0x23 ; 7s
    .byte 0x28 ; 8s


; Seccao:    data
; Descricao: Guarda as variaveis globais
;
	.data
var:
	.space	1

; Seccao:    stack
; Descricao: Implementa a pilha com a dimensao definida pelo simbolo STACK_SIZE
;
	.stack
	.space	STACK_SIZE
stack_top:
