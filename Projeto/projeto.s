; 	TODO
; 	1. Aguardar que o jogo comece cumprindo os requisitos expressos no enunciado;
;	2. O jogo é constituído por uma única ronda, onde é afixada a toupeira numa posição fixa (sempre no mesmo buraco);
;	3. A ronda termina quando o jogador conseguir "bater" na toupeira;
;	4. O jogo termina, nesta fase, sempre com sucesso, e deve cumprir os requisitos expressos no enunciado;
;	5. O jogo volta ao estado inicial.
; 


; Definicao dos valores dos simbolos utilizados no programa
;
	.equ	STACK_SIZE, 64              ; Dimensao do stack, em bytes
	.equ	ENABLE_EXTINT, 0x10         ; Ativa a flag I do CPSR (ativa as interrupcoes)
	.equ	OUTPORT_ADDRESS, 0xFFC0     ; Endereco do porto de saida
	.equ 	INPUTPORT_ADDR, 0xFFB0		; Endereco do porto de entrada

	.equ	INT_CS_ADDRESS, 0xFF00      ; Local em memória para ativar o [nCS_EXT0] Chip select [FF00 a FF3F]
    .equ	TCR_ADDRESS, 0xFF00         ; Endereço de memória para ativar o [TCR Register] do pTC
	.equ	TMR_ADDRESS, 0xFF02         ; Endereço de memória para ativar o [TMR Register] do pTC
	.equ	TC_ADDRESS, 0xFF04          ; Endereço de memória para ativar o [TC Register] do pTC
	.equ	TIR_ADDRESS, 0xFF06			; Endereço de memória para ativar o [TIR Register] do pTC
	.equ	VAR_INIT_VAL, 0             ; Valor inicial de var


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
	BL start_up ; PROCESSO DE INICIALIZAÇÃO DO JOGO
	
	BL game_start_signal ; Aiva os LEDs a laranja

	BL read_and_save_game_dificulty ; Lê e grava em memória o tempo selecionado para a ronda

	MOV R0, #4
	BL convert_moleinput_moleoutput
	MOV R1, #1
	MOV R2, #1
	BL show_mole


main_loop:
	ldr	r0, var_addr_main
	ldrb	r0, [r0, #0]
	bl	outport_write
	b	main_loop




; Rotina:    isr
; Descricao: Rotina de interrupção
isr:
	push	r1
	push	r0
	mov	r0, #INT_CS_ADDRESS & 0xFF
	movt	r0, #(INT_CS_ADDRESS >> 8) & 0xFF
	strb	r2, [r0, #0]
	ldr	r0, var_addr_isr
	ldrb	r1, [r0, #0]
	add	r1, r1, #1
	strb	r1, [r0, #0]
	pop	r0
	pop	r1
	movs	pc, lr


; START_UP
; Rotina que inicializa o programa.
start_up:
	PUSH LR

	mov	r0, #VAR_INIT_VAL
	ldr	r1, var_addr_main
	strb	r0, [r1, #0]     ; Mete var = 0

	bl	outport_write		 ; Escreve o zero no output port
	mov	r0, #INT_CS_ADDRESS & 0xFF				; CARREGA O ENDEREÇO DE MEMÓRIA DO INT_CS
	movt	r0, #(INT_CS_ADDRESS >> 8) & 0xFF	; CARREGA O ENDEREÇO DE MEMÓRIA DO INT_CS		
	strb	r0, [r0, #0]						; Faz um STOREB para ativar o sinal nWrL

	mrs	r0, cpsr								; Passa as flags para o R0
	mov	r1, #ENABLE_EXTINT						; Passa para R1 a mascara que ativa a flag I
	orr	r0, r0, r1								; Realiza um OR bit a bit entre R0 e R1
	msr	cpsr, r0								; Passa as novas flags atualizadas para o registo CPSR

	POP PC

var_addr_main:		.word var
var_addr_isr:		.word var


;
; >> Função SHOW_MOLE << Coloca todos os leds a laranja
; Tipo: - FOLHA -
; Parametros de entrada:
;	-
; variaveis locais:
;	-
; Parametros de saida:
;   - 
;
game_start_signal: 
	MOV R0, #0xFF ; Coloca todos os 8 bits do output a 1, que significa ativar o RED e GREEN simultaneamente

	BL outport_set_bits

	MOV PC, LR
; END


;
; >> Função READ_GAME_DIFICULTY <<
; Tipo: - FOLHA -
; Parametros de entrada:
;	-
; variaveis locais:
;	-
; Parametros de saida:
;   R0 -> 
;
read_and_save_game_dificulty: 

	BL inport_read

	; Só precisamos dos 3 bits mais significativos
	MOV R2, #0x03
	AND R0, R0, R2
	
	;LSR R0, R0, #5

	LDR r1, period_addr	; Carrega o endereço do array
	LDRB r0, [R1, R0]	; Carrega do array a posição R0

	LDR r1, diff_addr	; Carrega o endereço da variavel
	STRB r0, [R1]		; Guarda o valor obtido do array na variável


	MOV PC, LR
; END

period_addr:  		.word period
diff_addr:   		.word dificulty_time

;
; >> Função DETECT_PLAY <<
; Tipo: - FOLHA -
; Parametros de entrada:
;	-
; variaveis locais:
;	-
; Parametros de saida:
;   R0 -> Boolean
;
detect_play:
	PUSH LR

	BL inport_read			; Só precisamos dos 4 bits menos significativos
	MOV R1, #0xF
	AND R0, R0, R1

	LDR R1, last_play_addr
	LDRB R1, [R1]

	CMP R1, R0 				; Se o novo valor no inport for igual ao valor antigo em memória

	BEQ detect_play_return	; SE forem iguais, significa que nao ha alterações, sai da função com 0

detect_play_return1:
	MOV R0, #1

detect_play_return0:
	MOV R0, #0

detect_play_return:

	POP PC

last_play_addr:		.word last_play

;
; >> Função SHOW_MOLE << Mostra nos LEDs do output port o estado de uma toupeira 
; Tipo: - NÃO FOLHA -
; Parametros de entrada:
;   uint8_t v -------> r0 - ; R0 -> Nº da toupeira [8bits]
;   uint8_t k -------> r1 - Estado da toupeira, #0 -> R, #1 -> G
;   uint8_t p -------> r2 - Estado da toupeira, #0 -> LR | G, #1 -> Yellow
;
; variaveis locais:
;   uint8_t i --> r3
;
; Parametros de saida:
;   uint8_t ---------> r0
;
show_mole:
	PUSH LR

	MOV R3, #1
	CMP R2, R3

	BEQ mole_yellow		; SE o R1 for 1, é YELLOW 

	CMP R1, R3			; 
	
	BNE mole_red		; SE o R0 for 0, é RED
	BL mole_green		; SE o R0 for 1, é GREEN

mole_yellow:
	BL show_mole_yellow
	B show_mole_end
	
mole_red:
	BL show_mole_red
	B show_mole_end

mole_green:
	BL show_mole_green
	B show_mole_end
show_mole_end:
	POP PC



;
; >> Função CONVERT_MOLEINPUT_MOLEOUTPUT <<
; Tipo: - FOLHA -
; Parametros de entrada:
;   uint4_t v -------> r0
;
; variaveis locais:
;   uint8_t prod_c --> r1
;   uint8_t contador  --> r2
;
; Parametros de saida:
;   uint8_t ---------> r0
;
convert_moleinput_moleoutput:
	MOV R1, R0

convert_before_while:
    MOV r2, #0 ; 1
convert_while:
    CMP	r2, r1              ; n >= 1
    BHS	convert_end 
    
    LSL r0, r0, #1          
    SUB	r1, r1, #1          ; m => contador; m--
    B	convert_while

convert_end:

	MOV PC, LR


; SHOW_MOLE_RED
; Mostra num LED vermelho do output port o estado de uma toupeira 
; R0 -> Nº da toupeira [4bits]
show_mole_red:
	BL outport_set_bits

	MOV PC, LR


; SHOW_MOLE_RED
; Mostra num LED Verde do output port o estado de uma toupeira 
; R0 -> Nº da toupeira [4bits]
show_mole_green:
	LSL r0, r0, #1		; Faz o shift para a esquerda da posição inicial da toupeira para que acerte no input do LED verde

	BL outport_set_bits

	MOV PC, LR


; SHOW_MOLE_YELLOW
; Mostra num LED amarelo do output port o estado de uma toupeira 
; R0 -> Nº da toupeira [4bits]
show_mole_yellow:
	LSL r1, r0, #1		; Faz o shift para a esquerda da posição inicial da toupeira para que acerte no input do LED verde
	ORR r0, r0, r1

	BL outport_set_bits

	MOV PC, LR


; OUTPORT_SET_BITS
; Introduz os BITS ao valor já no outputport através de uma mascara
; R0 -> é a mascara que será aplicada ao valor já existente no output-port
;
outport_set_bits:
    PUSH LR
    
    LDR r1, out_port_img_addr
    LDRB r1, [r1]

    ORR r0, r0, r1

    BL outport_write
    
    POP PC

; OUTPORT_CLR_BITS
; Limpa os BITS do valor já no outputport através de uma mascara
; R0 -> é a mascara que será aplicada ao valor já existente no output-port
;
outport_clr_bits:
    PUSH LR
    
    LDR r1, out_port_img_addr
    LDRB r1, [r1]

    MVN r0, r0
    AND r0, r0, r1

    BL outport_write
    
    POP PC


; Rotina:    outport_write
; Descricao: Escreve num porto de saida a 8 bits o valor passado como argumento.
;            Interface exemplo: void outport_write( uint8_t value );
; Entradas:  r0 - valor a escrever no porto de saida
; Saidas:    -
; Efeitos:   r1 - guarda o endereco do porto alvo da escrita
outport_write:
	mov	 r1, #OUTPORT_ADDRESS & 0xFF
	movt r1, #(OUTPORT_ADDRESS >> 8) & 0xFF
	strb r0, [r1, #0]

	; É necessário guardar o ultimo valor escrito no output port para conseguirmos modificar o ultimo valor com
	; uma mascara

    ldr r1, out_port_img_addr    
    strb r0, [r1, #0]

	mov	pc, lr

; Rotina:    INPORT_READ
; Descricao: lê do porto de saida os 8 bits.
;            Interface exemplo: uint8_t outport_write();
; Entradas:   - 
; Saidas:    r0 - valor lido do porto de entrada

inport_read:
    ldr r0, input_port_addr
    ldrb r0, [r0]
    mov pc, lr

input_port_addr:	.word INPUTPORT_ADDR

out_port_addr:		.word OUTPORT_ADDRESS

out_port_img_addr:  .word outport_img


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
var:			.space	1
dificulty_time:	.space	1
outport_img: 	.space	1
last_play:   	.space	1

; Seccao:    stack
; Descricao: Implementa a pilha com a dimensao definida pelo simbolo STACK_SIZE
;
	.stack
	.space	STACK_SIZE
stack_top:
