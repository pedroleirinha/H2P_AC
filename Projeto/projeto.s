; Definicao dos valores dos simbolos utilizados no programa
;
	.equ	STACK_SIZE, 64              ; Dimensao do stack, em bytes
	.equ	ENABLE_EXTINT, 0x10         ; Ativa a flag I do CPSR (ativa as interrupcoes)
	.equ	OUTPORT_ADDRESS, 0xFFC0     ; Endereco do porto de saida
	.equ 	INPUTPORT_ADDR, 0xFFB0		; Endereco do porto de entrada

	.equ	PTC_ADDRESS, 0xFF00      	; Endereco do circuito pTC
	.equ	INT_CS_ADDRESS, 0xFF00      ; Local em memória para ativar o [nCS_EXT0] Chip select [FF00 a FF3F]
    .equ	PTC_TCR_ADDRESS, 0     		; Endereço de memória para ativar o [TCR Register] do pTC [0xFF00]
	.equ	PTC_TMR_ADDRESS, 1     		; Endereço de memória para ativar o [TMR Register] do pTC [0xFF02]
	.equ	PTC_TC_ADDRESS, 2     		; Endereço de memória para ativar o [TC Register] do pTC [0xFF04]
	.equ	PTC_TIR_ADDRESS, 3			; Endereço de memória para ativar o [TIR Register] do pTC [0xFF06]
	.equ	PTC_CMD_START, 0			; Comando para iniciar a contagem no pTC
	.equ	PTC_CMD_STOP, 1				; Comando para parar a contagem no pTC

	.equ	SYSCLK_INIT, 100              ; Valor inicial do sysclk
	


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

; Rotina:    MAIN Function
; Descricao: -
; Entradas:  -
; Saidas:    -
; Efeitos:   -
main:
	
	;BL game_setup_fun
	BL game_start_fun
	;BL game_finished
	
	B main
	
;; END MAIN


; Rotina:    Game_Setup_Fun
; Descricao: -
; Entradas:  -
; Saidas:    -
; Efeitos:   -
game_finished:
	PUSH LR

	BL clear_lights
	MOV R0, #0xFF
	BL outport_write
	
	MOV R0, #2
	BL sleep
	
	MOV R0, #0xFF
	BL outport_write
	
	MOV R0, #2
	BL sleep

	MOV R0, #0xFF
	BL outport_write
	
	MOV R0, #2
	BL sleep

	POP PC
;END GAME_FINISHED

; Rotina:    Game_Setup_Fun
; Descricao: -
; Entradas:  -
; Saidas:    -
; Efeitos:   -
game_setup_fun:
	PUSH LR
	
	BL game_start_signal 
	BL read_and_save_game_dificulty ; Lê e grava em memória o tempo selecionado para a ronda
	BL start_up_interruptions		; PROCESSO DE INICIALIZAÇÃO DAS INTERRUPÇÕES
	BL sysclk_init
detect_cycle:
	MOV R1, #0x01
	BL detect_play
	AND R0, R0, R1
	
	BZS detect_cycle
game_setup_return:
	POP PC
;; END Game_Setup_Fun


; Rotina:    Game_Start_Fun
; Descricao: -
; Entradas:  -
; Saidas:    -
; Efeitos:   -
game_start_fun:
	PUSH LR
	PUSH R4
	PUSH R5
	BL clear_lights

	MOV R6, #0						;Nº DA RONDA 
next_round:
	MOV R0, R6						;Nº DA RONDA 
	BL show_moles_state				;CARREGA AS POSIÇÕES DAS TOUPEIRAS A PARTIR DO ARRAY em R0

	BL game_round

	ADD R6, R6, #1					; INCREMENTA O Nº DA RONDA
	BL clear_lights
	MOV R0, #5
	BL sleep
	B next_round

game_start_return:
	POP R4
	POP R5
	POP PC
;; END Game_Start_Fun



; Rotina:    game_round
; Descricao: 
; Entradas:  R0 -> posicoes das toupeiras
; Saidas:    -
; Efeitos:  
game_round:
	PUSH LR
	PUSH R4

	MOV R4, R0

game_round_loop:
	MOV R1, #0x0F
	BL detect_play			; DEVOLVE A MASCARA DOS INPUTS DETETADOS
	AND R0, R0, R0			; SE ESTIVER A ZERO, NAO HOUVE INPUTS E CONTINUA
	
	BZS game_round_loop
	
	MOV R1, R4
	BL if_mole_hit_change_color

	BZS game_round_loop
	
	BL check_if_any_mole_left
	AND R0, R0, R0
	
	BZC game_round_loop					; SE FOR ZERO É PORQUE NAO HA MAIS TOUPEIRAS POR MATAR

	POP R4
	POP PC


; Rotina:    if_mole_hit_change_color
; Descricao: 
; Entradas:  R0 -> mascara de hits detetada
; Entradas:  R1 -> posicoes das toupeiras
; Saidas:    -
; Efeitos:  
if_mole_hit_change_color:
	PUSH LR
	PUSH R4

	MOV R4, R1

	BL convert_moleinput_moleoutput	; FICA EM R0 o index da marretada detetada
	MOV R5, R0

	BL get_mole_green 				; VAI BUSCAR A MASCARA QUE REPRESENTA OS LEDS VERDES NO INDEX DA MARRETA
	AND R0, R0, R4

	MOV R0, R5
	BL turn_mole_red				; APAGA O LED VERDE E ACENDE O RESPETIVO LED VERDE

	POP R4
	POP PC
; end_is_mole_hit




; Rotina:    show_moles_state
; Descricao: 
; Entradas:  R0 -> INDEX da ronda
; Saidas:    -
; Efeitos:  
show_moles_state:
	PUSH LR
	
	LDR R2, moles_position_addr
	LDRB R3, [R2, R0]

	MOV R0, R3
	BL outport_write

	POP PC
; END SHOW_MOLES_STATE



moles_position_addr: .word moles_position


; Rotina:    detect play
; Descricao: Verifica se é detetada uma transição descendente em qualquer um dos primeiros 4 bits
; Entradas:  -
; Saidas:    -
; Efeitos:   
detect_play:
	PUSH LR
	PUSH R4
	
	BL read_marreta 				; Lê e retorna os 4 bits de menor peso R0
	MOV R1, #0x0F
	BL falling_edge_v2

	POP R4
	POP PC

;END DETECT_PLAY



; Entradas:  r0 - valor lido o porto de entrada
; 			 r1 - Mascara inicial 
falling_edge_v2:
	ldr	 r2, last_play_addr
	ldrb r3, [r2]	; VALOR EM MEMORIA

	strb r0, [r2]	; ATUALIZA EM MEMORIA

	MVN R0, R0		; INVERTE OS BITS 
	AND R0, R0, R3	

	AND R0, R0, R1 ; FILTRA OS 4 BITS menos significativos 
	MOV PC, LR

last_play_addr:
	.word	last_play


; START_UP
; Rotina que inicializa o programa.
start_up_interruptions:
	PUSH LR

	bl	outport_write		 					; Escreve o zero no output port
	mov	r0, #INT_CS_ADDRESS & 0xFF				; CARREGA O ENDEREÇO DE MEMÓRIA DO INT_CS
	movt	r0, #(INT_CS_ADDRESS >> 8) & 0xFF	; CARREGA O ENDEREÇO DE MEMÓRIA DO INT_CS		
	strb	r0, [r0, #0]						; Faz um STOREB para ativar o sinal nWrL

	mrs	r0, cpsr								; Passa as flags para o R0
	mov	r1, #ENABLE_EXTINT						; Passa para R1 a mascara que ativa a flag I
	orr	r0, r0, r1								; Realiza um OR bit a bit entre R0 e R1
	msr	cpsr, r0								; Passa as novas flags atualizadas para o registo CPSR

	POP PC




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

	LDR r1, period_addr	; Carrega o endereço do array
	LDRB r0, [R1, R0]	; Carrega do array a posição R0

	LDR r1, diff_addr	; Carrega o endereço da variavel
	STRB r0, [R1]		; Guarda o valor obtido do array na variável


	POP PC
; END


; Rotina:    sleep
; Descricao: Faz um atraso de tempo de #1 em r0 e r1
; Entradas:  Recebe r0
; Saidas:    Não têm
; Efeitos:   Altera os registos R0 e R1
sleep:

	LDR r1, period_addr	; Carrega o endereço do array
	LDRB r0, [R1, R0]	; Carrega do array a posição R0

	and	r0, r0, r0
	beq	sleep_end
sleep_outer_loop:
	mov	r1, #0x3E
	movt r1, #0x03
sleep_inner_loop:
	sub	r1, r1, #1
	bne	sleep_inner_loop
	sub	r0, r0, #1
	bne	sleep_outer_loop
sleep_end:
	mov	pc, lr


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
	CMP R1, R3			; 
	
	BNE mole_red		; SE o R0 for 0, é RED
	BL mole_green		; SE o R0 for 1, é GREEN

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
;
; variaveis locais:
;   uint8_t contador  --> r2
;
; Parametros de saida:
;   uint8_t ---------> r0
;
convert_moleinput_moleoutput:
	MOV R1, #0
convert_while:

    LSR r0, r0, #1          
	BZS convert_end
    ADD r1, r1, #1          ; m => contador; m--
    B	convert_while

convert_end:
	MOV R0, R1
	MOV PC, LR
; END CONVERT


; GETMOLE_RED
; Retorna a posição do LED vermelho do output port com base na posição como parametro.  
; R0 -> Nº da toupeira [4bits]
get_mole_red:
	LDR R1, moles_red_addr
	LDRB R0, [R1, R0]

	MOV PC, LR


; GETMOLE_GREEN
; Retorna a posição do LED verde do output port com base na posição como parametro.  
; R0 -> Nº da toupeira [4bits]
get_mole_green:
	LDR R1, moles_green_addr
	LDRB R0, [R1, R0]

	MOV PC, LR

; SHOW_MOLE_RED
; Mostra num LED vermelho do output port o estado de uma toupeira 
; R0 -> Nº da toupeira [4bits]
show_mole_red:
	PUSH LR
	
	BL get_mole_red
	BL outport_set_bits

	POP PC


; SHOW_MOLE_RED
; Mostra num LED Verde do output port o estado de uma toupeira 
; R0 -> Nº da toupeira [4bits]
show_mole_green:
	PUSH LR

	BL get_mole_green
	BL outport_set_bits

	POP PC


moles_red_addr:  .word moles_red
moles_green_addr:  .word moles_green

;
; >> Função GAME START SIGNAL << Coloca todos os leds a laranja
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

;
; >> Função CLEAR LIGHTS << Desliga todos os leds
; Tipo: - FOLHA -
; Parametros de entrada:
;	-
; variaveis locais:
;	-
; Parametros de saida:
;   - 
;
clear_lights: 
	PUSH LR
	MOV R0, #0xFF ; Coloca todos os 8 bits do output a 1, que significa ativar o RED e GREEN simultaneamente

	BL outport_clr_bits

	POP PC
; END

;
; >> Função READ_MARRETA << Lê os 4bits menos significativos do inputport
; Tipo: - FOLHA -
; Parametros de entrada:
;	-
; variaveis locais:
;	-
; Parametros de saida:
;   - 
;
read_marreta:
	PUSH LR

	MOV R1, #0x0F
	BL inport_read
	AND R0, R0, R1

	POP PC

;END READ_MARRETA



; Rotina:    turn_mole_red
; Descricao: 
; Entradas:  R0 -> INDEX da toupeira
; Saidas:    -
; Efeitos:   
turn_mole_red:
	PUSH LR
	PUSH R4

	MOV R4, R0
	BL get_mole_green 
	
	BL outport_clr_bits			; LIMPA O BIT QUE TORNA O LED VERDE NA TOUPEIRA 

	MOV R0, R4
	BL get_mole_red 

	BL outport_set_bits			; ATIVA O BIT QUE TORNA O LED VERMELHO NA TOUPEIRA 

	POP R4
	POP PC
;END TURN_MOLE_RED


; Rotina:    check_if_any_mole_left
; Descricao: 
; Entradas: 
; Saidas:    -
; Efeitos:  
check_if_any_mole_left:
	LDR R1, out_port_img_addr	; VAI BUSCAR O VALOR QUE ESTA VISIVEL QUE ESTA NO OUTPUTPORT
	LDRB R1, [R1]				; VAI BUSCAR O VALOR QUE ESTA VISIVEL QUE ESTA NO OUTPUTPORT

	MOV R2, #0xAA				; MASCARA QUE CORRESPONDE A TODAS AS POSIÇÕES POSSIVEIS DAS TOUPEIRAS VIVAS
	AND R0, R1, R2

	MOV PC, LR
; end check


; Rotina:    check_mole_position
; Descricao: 
; Entradas:  R0 -> INDEX da marretada
; Saidas:    -
; Efeitos:   
check_mole_position:
	PUSH LR
	
	
	BL get_mole_green 

	LDR R1, out_port_img_addr
	LDRB R1, [R1]

	AND R0, R0, R1		; VERIFICA SE OS MESMOS BITS DO OUTPUT PORT E DA GREEN POSISTION DA TOUPEIRA SAO IGUAIS

check_mole_return:

	POP PC
;END CHECK_MOLE_POSITION






;;						;;
;; 		PORTS API 		;;
;; 						;;

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



;;									;;
;; 			PICO TIMER API 			;;
;; 									;;


/************************************************************************************
 * LIB time
 ************************************************************************************/
; Rotina:    time_get_ref
; Descricao: Obtém o tempo de referência (sysclk atual) para servir de referência à contagem de um tempo (implementar um relógio)
; Entradas:  void
; Saidas:    R0 - valor atual do sysclk (16 bits)
; Efeitos:   *** Para completar ***
time_get_ref:
	; Completar

; Rotina:    time_elapsed
; Descricao: Retorna o número de ticks passados desde o tempo de referência
; Entradas:  R0 - tempo de referência (quando se iniciou a contagem de tempo)
; Saidas:    R0 - número de ticks passados desde tempo de referência (now-ref : de notar que o resultado da diferença continua a ser válido se now<ref)
; Efeitos:   *** Para completar ***
time_elapsed:
	; Completar

/************************************************************************************
 * HAL sys_clk
 ************************************************************************************/
; Rotina:    isr
; Descricao: Incrementa o valor da variável global sysclk.
; Entradas:  -
; Saidas:    -
; Efeitos:   *** Para completar ***
isr:
	push	r1
	push	r0
	mov	r0, #INT_CS_ADDRESS & 0xFF
	movt	r0, #(INT_CS_ADDRESS >> 8) & 0xFF
	strb	r2, [r0, #0]
	ldr	r0, SYSCLK_ADDR
	ldrb	r1, [r0, #0]
	add	r1, r1, #1
	strb	r1, [r0, #0]
	pop	r0
	pop	r1
	movs	pc, lr


; Rotina:    sysclk_init
; Descricao: Inicia uma nova contagem no periferico pTC com o intervalo de
;            contagem recebido em R0, em ticks, limpando eventuais pedidos de
;            interrupção pendentes e iniciando com o valor zero a variavel
;            global sysclk.
;            Interface exemplo: void sysclk_init( uint8_t interval );
; Entradas:  R0 - Valor do novo intervalo de contagem, em ticks.
; Saidas:    -
; Efeitos:   Inicia a contagem no periférico a partir do valor zero, limpando
;            eventuais pedidos de interrupção pendentes e iniciando com o
;            valor zero a variavel global sysclk
sysclk_init:
	push	lr
	ldr		r1, SYSCLK_ADDR
	mov		r2, #0
	str 	r2, [r1]
	bl		ptc_init
	pop		pc
	
; Rotina:    sysclk_get_ticks
; Descricao: Devolve o valor corrente da variável global sysclk.
;            Interface exemplo: uint16_t sysclk_get_ticks ( );
; Entradas:  -
; Saidas:    *** Para completar ***
; Efeitos:   -
sysclk_get_ticks:
	ldr		r0, SYSCLK_ADDR
	ldr		r0, [r0]
	mov		pc, lr

SYSCLK_ADDR:
	.word	sysclk

/************************************************************************************
 * Gestor de periférico para o Pico Timer/Counter (pTC): HAL pTC
 ************************************************************************************/
; Rotina:    ptc_init
; Descricao: Faz a iniciacao do periférico pTC, habilitando o seu funcionamento
;            em modo contínuo e com o intervalo de contagem recebido em R0, em
;            ticks.
;            Interface exemplo: void ptc_init( uint8_t interval );
; Entradas:  R0 - Valor do novo intervalo de contagem, em ticks.
; Saidas:    -
; Efeitos:   Inicia a contagem no periferico a partir do valor zero, limpando
;            o pedido de interrupcao eventualmente pendente.
ptc_init:
    push    lr
	push	r0
	bl 		ptc_stop
	pop		r0
	ldr		r1, PTC_ADDR
	strb	r0, [r1, #PTC_TMR_ADDRESS]
    bl  	ptc_clr_irq
	bl 		ptc_start
	pop pc


; Rotina:    ptc_start
; Descricao: Habilita a contagem no periferico pTC.
;            Interface exemplo: void ptc_start( );
; Entradas:  -
; Saidas:    -
; Efeitos:   -
ptc_start:
	ldr		r0, PTC_ADDR
	mov		r1, #PTC_CMD_START
	strb	r1, [r0, #PTC_TC_ADDRESS]
	mov		pc, lr

; Rotina:    ptc_stop
; Descricao: Para a contagem no periferico pTC.
;            Interface exemplo: void ptc_stop( );
; Entradas:  -
; Saidas:    -
; Efeitos:   O valor do registo TC do periferico e colocado a zero.
ptc_stop:
	ldr		r0, PTC_ADDR
	mov		r1, #PTC_CMD_STOP
	strb	r1, [r0, #PTC_TC_ADDRESS]
	mov		pc, lr

; Rotina:    ptc_get_value
; Descricao: Devolve o valor corrente da contagem do periferico pTC.
;            Interface exemplo: uint8_t ptc_get_value( );
; Entradas:  -
; Saidas:    R0 - O valor corrente do registo TC do periferico.
; Efeitos:   -
ptc_get_value:
	ldr		r1, PTC_ADDR
	ldrb	r0, [r1, #PTC_TC_ADDRESS]
	mov		pc, lr

; Rotina:    ptc_clr_irq
; Descricao: Sinaliza o periferico pTC que foi atendido um pedido de
;            interrupção.
;            Interface exemplo: void ptc_clr_irq( );
; Entradas:  -
; Saidas:    -
; Efeitos:   -
ptc_clr_irq:
	ldr		r0, PTC_ADDR
	strb	r1, [r0, #PTC_TIR_ADDRESS]
	mov		pc, lr

PTC_ADDR:
	.word	PTC_ADDRESS



moles_red:
	.byte 0x01
    .byte 0x04
    .byte 0x10
    .byte 0x40

moles_green:
	.byte 0x02
    .byte 0x08
    .byte 0x20
    .byte 0x80

moles_yellow:
	.byte 0x03
    .byte 0x0C
    .byte 0x30
    .byte 0xC0

period:
	.byte 0x63 ;10 s   
	.byte 0x59 ;9  s
    .byte 0x4F ;8  s
    .byte 0x45 ;7  s
    .byte 0x3B ;6  s
    .byte 0x31 ;5  s
    .byte 0x27 ;4  s
    .byte 0x1D ;3  s
    .byte 0x13 ;2  s
    .byte 0x09 ;1  s
    .byte 0x04 ;0.5s


; Seccao:    data
; Descricao: Guarda as variaveis globais
;
	.data
dificulty_time:	.space	1
outport_img: 	.space	1
last_play:   	.space	1
sysclk:			.space	2

moles_position: ; GUARDAR AS POSIÇÕES EM 8 BITS.
	.byte 0x20	; RONDA 1  => [ _1__ ]
	.byte 0x40	; RONDA 2  => [ 1___ ]
	.byte 0x02	; RONDA 3  => [ ___1 ]
	.byte 0x04	; RONDA 4  => [ __1_ ]
	.byte 0x20	; RONDA 5  => [ _1__ ]
	.byte 0x44	; RONDA 6  => [ 1_1_ ]
	.byte 0x22	; RONDA 7  => [ _1_1 ]
	.byte 0x24	; RONDA 8  => [ _11_ ]
	.byte 0x42	; RONDA 9  => [ 1_1_ ]
	.byte 0x24	; RONDA 10 => [ _11_ ]


; Seccao:    stack
; Descricao: Implementa a pilha com a dimensao definida pelo simbolo STACK_SIZE
;
	.stack
	.space	STACK_SIZE
stack_top:


; SE A FREQ FOR 100kH, dá 0.01ms por cada contagem de clock. Se for até 255, dá no maximo 2,5ms
; SE A FREQ FOR 1kH, dá 1ms por cada contagem de clock. Se for até 255, dá no maximo 255ms

; 	TEMPO		CICLOS	PL		
; 	10 s		100		99 	[0x63]
; 	9  s		90		89	[0x59]
; 	8  s		80		79	[0x4F]
; 	7  s		70		69	[0x45]
; 	6  s		60		59	[0x3B]
; 	5  s		50		49	[0x31]
; 	4  s		40		39	[0x27]
; 	3  s		30		29	[0x1D]
; 	2  s		20		19	[0x13]
; 	1  s		10		09	[0x09]
; 	0.5s		5		04	[0x04]
; 
