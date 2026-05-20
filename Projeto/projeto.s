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

	.equ 	FALLING_EDGE_MODE_MSK, 0x07	; Máscara para o controlo de entrada do modo de piscar: Pisca ON / pisca OFF (O7)
	.equ	SWT_BLINK_MODE_POS, 7		; Posição do bit do modo de piscar
	
	.equ	VOU_JOGO, 0		; Posição do bit do modo de piscar
	.equ	ESTOU_AQUI, 1		; Posição do bit do modo de piscar
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
main:
	
	BL start_up ; PROCESSO DE INICIALIZAÇÃO DO JOGO
	
	BL read_and_save_game_dificulty ; Lê e grava em memória o tempo selecionado para a ronda


	MOV R4, #VOU_JOGO ; GAME STATE -> ESTADO: "VOU A JOGO"
main_loop:
	
	MOV R5, #0
	CMP R4, R5
	BNE game_toupeiras

game_leds:
	BL game_start_signal ; Aiva os LEDs a laranja

game_toupeiras:

	

	BL read_marreta ; Lê e retorna os 4 bits de menor peso
	ldr	 r1, last_play_addr
	strb r0, [r1]	
	MOV R3, R0

	MOV R1, #0x07
ciclo:
	MOV R0, R3		; INPORT
	BL 	falling_edge  ; RETORNA TRUE (1) OU FALSE (0)
	MOV R2, #1	
	CMP R0, R2
	BZS return_true			; SE RETORNO DO FALLING EDGE É IGUAL A 1 => (R2)

	LSR R1, R1, #1
	BZS salto

	B ciclo

return_true:
	MOV R4, #ESTOU_AQUI
	MOV R0, #2
	BL outport_write
	B main_loop

salto: 

	; R1 -> MASK onde detetou


	;MOV R0, #4
	;MOV R1, #1
	;MOV R2, #1
	;BL show_mole

	b	main_loop



; Rotina:    falling_edge
; Descricao: Retorna booleano indicando se detetou uma transição descendente no bit que controla o modo de funcionamento do sistema;
; Entradas:  r0 - valor lido o porto de entrada
; 			 r1 - a mascara do bit
; Saidas:    r0 - igual a 0 -> não ocorreu transição descendente; diferente de 0 -> ocorreu transição descendente
; Efeitos:   
falling_edge:

	ldr		r2, last_play_addr
	ldrb	r2, [r2]			; R2 = observação anterior do bit que controla o modo de operação
	AND 	r5, r0, r1 			; Aplica a mascara no valor de entrada

	; O bit atual do valor no inputport tem de ser 0 para detetar uma transição descendente 

	BNE falling_edge_false

	AND 	r2, r1, r2 			; Aplica a mascara no valor antigo

	BZS falling_edge_false
; TRANSICAO DESCENDENTE
	mov		r0, #1				; retorna true: observação anterior igual a OFF (1) e observação atual igual a ON (0)
	mov		pc, lr

	B falling_edge_return

falling_edge_false:

	mov 	r5, #FALLING_EDGE_MODE_MSK
	and		r0, r0, r5			; isola o valor atual do bit modo piscar
	strb	r0, [r1]


falling_edge_return:

	mov		r0, #0
	mov		pc, lr


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

last_play_addr:
	.word	last_play



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
	PUSH LR
	BL inport_read

	; Só precisamos dos 3 bits mais significativos
	MOV R2, #0xE0
	AND R0, R0, R2
	
	;LSR R0, R0, #5

	LDR r1, period_addr	; Carrega o endereço do array
	LDRB r0, [R1, R0]	; Carrega do array a posição R0

	LDR r1, diff_addr	; Carrega o endereço da variavel
	STRB r0, [R1]		; Guarda o valor obtido do array na variável


	POP PC
; END

period_addr:  		.word period
diff_addr:   		.word dificulty_time


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
;   uint4_t num_ -------> r0
;   uint4_t index -------> r1
;
; variaveis locais:
;   uint8_t contador  --> r2
;
; Parametros de saida:
;   uint8_t ---------> r0
;
convert_moleinput_moleoutput:
	MOV R2, R0

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
	PUSH LR
	MOV R0, #0xFF ; Coloca todos os 8 bits do output a 1, que significa ativar o RED e GREEN simultaneamente

	BL outport_set_bits

	POP PC
; END


read_marreta:
	PUSH LR

	MOV R1, #0x0F
	BL inport_read
	AND R0, R0, R1

	POP PC


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
