; Ficheiro:  lab04_ex1.S
; Descricao: Programa para a realizacao da 4a atividade laboratorial de
;            Arquitetura de Computadores.
; Autor:     Tiago M Dias (tiago.dias@isel.pt)
; Data:      09-05-2025

; Definicao dos valores dos simbolos utilizados no programa
;
	.equ	STACK_SIZE, 64                ; Dimensao do stack, em bytes

; *** Inicio de troco para completar ***
	.equ	ENABLE_EXTINT, 0x10           ; Para ativar o 4º bit do CPSQ, temos de passar o valor 00010000
; *** Fim de troco para completar ***

	.equ	OUTPORT_ADDRESS, 0xFFC0       ; Endereco do porto de saida

	.equ	VAR_INIT_VAL, 0               ; Valor inicial de var

; Seccao:    text
; Descricao: Guarda o codigo do programa
;
	.text
	b	program
	push	r1					; Guarda R1 na stack
	push	r0					; Guarda R0 na stack
	ldr	r0, var_addr_startup	; Guarda em R0 o endereço de memoria de R0
	ldrb	r1, [r0, #0]		; Guarda em r1 o valor de val
	add	r1, r1, #1				; Incrementa o valor em R1 por 1 unidade
	strb	r1, [r0, #0]		; Guarda o R1 incrementado de novo em val.
	pop	r0						; Retoma o r0
	pop	r1						; Retoma o r1
	movs	pc, lr				; Retorno do LR para o PC e atualiza as flags com as guardadas
program:
	ldr	sp, stack_top_addr
    b   main

stack_top_addr:
	.word	stack_top

var_addr_startup:
	.word	var

; Rotina:    main
; Descricao: *** Para completar ***
; Entradas:  *** Para completar ***
; Saidas:    *** Para completar ***
; Efeitos:   *** Para completar ***
main:
	mov	 r0, #VAR_INIT_VAL ; Mete r0 = 0
	ldr	 r1, var_addr_main ; Faz load do endereço de memoria de var para r1
	strb r0, [r1, #0]	   ; Coloca o 0 no var. var = 0
	bl	 outport_write	   ; Escreve o valor zero no outputport
	mrs	 r0, cpsr		   ; guarda as flags no r0
	mov	 r1, #ENABLE_EXTINT; guarda qualquer coisa no R1
	orr	 r0, r0, r1		   ; Realiza o OR bit a bit entre os dois
	msr	 cpsr, r0		   ; Atualiza o CPSR com as flags em R0
main_loop:
	ldr	r0, var_addr_main  ; Carrega o endereco do var para R0
	ldrb	r0, [r0, #0]   ; Carrega o valor real de var para R0
	bl	outport_write	   ; 
	b	main_loop

var_addr_main:
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
