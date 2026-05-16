; Ficheiro:  lab03.s
; Descricao: Programa para a realizacao da 3a atividade laboratorial de
;            Arquitetura de Computadores.
; Autor:     Tiago M Dias (tiago.dias@isel.pt)
; Data:      29-04-2025

; Definicao dos valores dos simbolos utilizados no programa
;
	.equ	STACK_SIZE, 64                ; Dimensao do stack, em bytes

	.equ	ALL_ONES, 0xFFFF              ; Palavra com todos os bits a 1
	.equ	ALL_ZEROS, 0x0000             ; Palavra com todos os bits a 0

	.equ	INPORT_ADDRESS, 0xFF80        ; Endereco base do porto de entrada U6 (nCS_IN)
	.equ	OUTPORT_ADDRESS, 0xFFC0       ; Endereco base do porto de saida U16 (nCS_OUT)

; Seccao:    text
; Descricao: Guarda o codigo do programa
;
	.text
	b	program
	b	.		; Reservado para a ISR
program:        
	ldr	sp, stack_top_addr
	b	main

stack_top_addr:
	.word	stack_top

; Rotina:    main
; Descricao: Inicia o porto de saida e executa um ciclo infinito.
; Entradas:  Não têm
; Saidas:    Não têm
; Efeitos:   Altera os registos R0 e R1
main:
	mov	r0, #ALL_ONES & 0xFF
	bl	outport_write
	mov	r0, #ALL_ZEROS & 0xFF
	bl	outport_write
	MOV r3, #0
	MOV r4, #0
loop:
	bl	inport_read

	LDR r1, period_addr	; Carrega o endereço do array
	LDRB r2, [R1, R0]	; Carrega do array a posição R0
	
	CMP r4, r3

	BEQ increment
	MOV r4, #0

	B start_sleep
increment:
	MOV r4, #1

start_sleep:
	MOV r0, r2
	; R0 tem o valor do porto de entrada
	BL sleep ; Espera X ciclos
	MOV r0, r4
	bl	outport_write


	b	loop

period_addr:   .word period







; Rotina:    inport_read
; Descricao: Adquire e devolve o valor corrente do porto de entrada.
;            Interface exemplo: uint8_t inport_read( );
; Entradas:  -
; Saidas:    r0 - Lé do hardware os 8 bits menos significativos
; Efeitos:   r1 - Utilizado para enderessar o valor do porto
inport_read:
	mov	r1, #INPORT_ADDRESS & 0xFF
	movt	r1, #(INPORT_ADDRESS >> 8) & 0xFF
	ldrb	r0, [r1, #0]
	mov	pc, lr

; Rotina:    outport_write
; Descricao: Escreve num porto de saida a 8 bits o valor passado como argumento.
;            Interface exemplo: void outport_write( uint8_t value );
; Entradas:  r0 - Valor a escrever no porto de saida
; Saidas:    -
; Efeitos:   r1 - Registo utilizado para endereçamento do porto.
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

; Seccao:    data
; Descricao: Guarda as variaveis globais
;

;	.data

period:
	.byte 0x05 ; 1s
    .byte 0x0A ; 2s
    .byte 0x0F ; 3s
    .byte 0x14 ; 4s
    .byte 0x19 ; 5s
    .byte 0x1E ; 6s
    .byte 0x23 ; 7s
    .byte 0x28 ; 8s


; Seccao:    stack
; Descricao: Implementa a pilha com a dimensao definida pelo simbolo STACK_SIZE
;
	.stack
	.space	STACK_SIZE
stack_top:
