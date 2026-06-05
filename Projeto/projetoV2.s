; Definicao dos valores dos simbolos utilizados no programa
;
	.equ	STACK_SIZE, 64              ; Dimensao do stack, em bytes
	.equ	ENABLE_EXTINT, 0x10         ; Ativa a flag I do CPSR (ativa as interrupcoes)
	.equ	OUTPORT_ADDRESS, 0xFFC0     ; Endereco do porto de saida
	.equ 	INPUTPORT_ADDR, 0xFFB0		; Endereco do porto de entrada

	.equ 	ALL_GREEN_LIGHTS, 0xAA
	.equ 	ALL_RED_LIGHTS, 0x55
	.equ 	ALL_YELLOW_LIGHTS, 0xFF
	.equ 	NO_LIGHTS, 0x00
	
	.equ 	ROUNDS_COUNT, 0x0A
	.equ 	BLINKING_COUNT, 0x03

	.equ 	VICTORY_LIGHTS, 0x01
	.equ 	LOSER_LIGHTS, 0x00

	.equ 	WAIT_500MS, 0x53

	.equ	PTC_ADDRESS, 0xFF00      	; Endereco do circuito pTC
	.equ	INT_CS_ADDRESS, 0xFF00      ; Local em memória para ativar o [nCS_EXT0] Chip select [FF00 a FF3F]
    .equ	PTC_TCR_ADDRESS, 0     		; Endereço de memória para ativar o [TCR Register] do pTC [0xFF00]
	.equ	PTC_TMR_ADDRESS, 2     		; Endereço de memória para ativar o [TMR Register] do pTC [0xFF02]
	.equ	PTC_TC_ADDRESS, 4     		; Endereço de memória para ativar o [TC Register] do pTC [0xFF04]
	.equ	PTC_TIR_ADDRESS, 6			; Endereço de memória para ativar o [TIR Register] do pTC [0xFF06]
	.equ	PTC_CMD_START, 0			; Comando para iniciar a contagem no pTC
	.equ	PTC_CMD_STOP, 1				; Comando para parar a contagem no pTC

;; O VALOR DO CONTADOR INTERNO DO PICO TIMER SERA SEMPRE 6 PARA GARANTIR QUE É SEMPRE FEITA INTERRUPÇÕES A CADA 6MS
;; COMO USAMOS UM CLOCK DE 1KHZ, TEMOS CLOCKS A CADA 1MS
;; ASSUMIMOS QUE O ISR DEMORA 1.2MS A EXECUTAR E GARANTIMOS QUE O PROGRAMA CORRE NOS RESTANTES 5MS

	.equ	TMR_INIT_VAL, 0x05           ; Valor inicial do sysclk que garante a frequencia em segundos das interrupções
	


; Seccao:    text
; Descricao: Guarda o codigo do programa
;
	.text
	b	program
	b	isr
program:
	LDR	sp, stack_top_addr
    b   main

stack_top_addr:
	.word	stack_top

; Rotina:    MAIN Function
; Descricao: -
; Entradas:  -
; Saidas:    -
; Efeitos:   -
main:
	MOV R0, #TMR_INIT_VAL
	BL sysclk_init

loop:
	
	BL game_setup_fun
	BL game_start_fun
	BL game_finished
	
	B loop
	
;; END MAIN



;
; >> Função GAME SETUP << Rotina que prepeara o inicio do jogo. 
;	Inicia o PicoTimer, Faz enable ás interrupções, Lê a dificuldade do jogo posta no inputport e 
;	deteta o primeiro input para iniciar o jogo
; Tipo: - NAO FOLHA -
; Parametros de entrada:
;	-
; variaveis locais:
;	R1 -> i (Mascara usada para definir qual o input que estamos a "detetar")
; Parametros de saida:
;   VOID
;
game_setup_fun:
	PUSH LR
	
	BL game_start_signal 
	BL start_up_interruptions		; PROCESSO DE INICIALIZAÇÃO DAS INTERRUPÇÕES

	MOV R4, #0x01
detect_cycle:
	MOV R1, R4
	BL detect_play
	AND R0, R0, R4
	
	BZS detect_cycle
game_setup_return:
	BL read_and_save_game_dificulty ; Lê e grava em memória o tempo selecionado para a ronda

	POP PC
;; END Game_Setup_Fun


;
; >> Função GAME FINISHED << Rotina que é executada depois do jogo terminar, 
;	quer por tempo terminado ou por concluir as rondas todas
; Tipo: - NAO FOLHA -
; Parametros de entrada:
;	R0 -> Estado do jogo [0 - DERROTA; 1 - VITORIA]
; variaveis locais:
;	R1 -> i (para o ciclo)
; Parametros de saida:
;   VOID
;
game_finished:
	PUSH LR

	MOV R1, #0
	CMP R1, R0

	BEQ game_finished_loss

game_finished_vitory:
	MOV R0, #VICTORY_LIGHTS 
	BL flashing_lights
	B return_game

game_finished_loss:
	MOV R0, #LOSER_LIGHTS 
	BL flashing_lights

return_game:

	POP PC
;END GAME_FINISHED


;
; >> Função GAME START << Rotina que inicializa o jogo. 
;	Limpa os LEDS da placa, lê as posições do array das toupeiras com base no nº da ronda
;	INICIA a rounda e no final, se houver o jogador vender, incrementa a ronda e recomeça o jogo
; Tipo: - NAO FOLHA -
; Parametros de entrada:
;	-
; variaveis locais:
;	R5 -> rondaNum (Número da ronda que é incrementado após a ronda anterior terminar com uscesso)
; Parametros de saida:
;   VOID
;
game_start_fun:
	PUSH LR
	PUSH R4
	PUSH R5
	
	BL clear_lights

	BL get_difficulty_time
	
	MOV R5, #ROUNDS_COUNT
	MOV R4, #0						;Nº DA RONDA 
next_round:
	
	MOV R0, R4
	BL generate_random_mole
	BL show_moles_state				;CARREGA AS POSIÇÕES DAS TOUPEIRAS A PARTIR DO ARRAY em R0

	BL game_round
	AND R0, R0, R0
	BZS game_start_return_false

	ADD R4, R4, #1					; INCREMENTA O Nº DA RONDA
	
	BL clear_lights
	MOV R0, #WAIT_500MS
	BL wait_ticks
		
	CMP R5, R4
	BEQ game_start_return_true
	
	B next_round

game_start_return_true:
	MOV R0, #1
	B game_start_return
game_start_return_false:
	MOV R0, #0
game_start_return:
	POP R5
	POP R4
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
	PUSH R5
	PUSH R6

	MOV R4, R0

	BL time_get_ref						; Começa a contar o tempo da ronda
	MOV R5, R0							; Guarda o valor do contador no momento do inicio

	BL get_difficulty_time
	MOV R6, R0
	
game_round_loop:
    MOV R0, R5							; Metemos em R0, o valor que estava no inicio da contagem
    BL time_elapsed         			; Calcula diferença entre agora e R1
    CMP R0, R6              			; Compara tempo decorrido com o desejado
    BHS game_timeout					; Enquanto decorrido < desejado, espera


	MOV R1, #0x0F
	BL detect_play						; DEVOLVE A MASCARA DOS INPUTS DETETADOS
	AND R0, R0, R0						; SE ESTIVER A ZERO, NAO HOUVE INPUTS E CONTINUA

	BZS game_round_loop
	
	MOV R1, R4
	BL if_mole_hit_change_color
	AND R0, R0, R0						; SE ESTIVER A ZERO, NAO HOUVE TROCAS
	BZS game_round_loop


	BL check_if_any_mole_left
	AND R0, R0, R0
	
	BZC game_round_loop					; SE FOR ZERO É PORQUE NAO HA MAIS TOUPEIRAS POR MATAR

	MOV R0, #WAIT_500MS		
	BL wait_ticks			
	
	MOV R0, #1							; Retorna true, ganhou
	B game_return
game_timeout:
	MOV R0, #0							; Retorna false, perdeu

game_return:
	POP R6
	POP R5
	POP R4
	POP PC
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
	PUSH LR
	BL inport_read

	; Só precisamos dos 3 bits mais significativos
	MOV R2, #0xE0
	AND R0, R0, R2

	LSR R0, R0, #5
	LSL R0, R0, #1

	;LDR r1, period_addr	; Carrega o endereço do array
	;LDR r0, [R1, R0]	; Carrega do array a posição R0

	BL get_period_time_from_array

	;LDR r1, diff_addr	; Carrega o endereço da variavel
	;STR r0, [R1]		; Guarda o valor obtido do array na variável

	BL set_difficulty_time


	POP PC
; END


; Rotina:    vitory_lights
; Descricao: 
; Entradas:  R0  -> State. 0 -> Loss | 1 -> Victory
; Saidas:    -
; Efeitos:  Pisca os leds 3 vezes com base no parametro de entrada R0. 
;	Usa uma função auxiliar que permite esperar meio segundo, atraves do pico timer, antes de acender ou apagar o led
flashing_lights:
	PUSH LR
	PUSH R4

	MOV R4, #BLINKING_COUNT
	
	MOV R3, #WAIT_500MS
	
	MOV R2, #LOSER_LIGHTS
	CMP R0, R2
	BEQ loser_prep

victory_prep:
	MOV R2, #ALL_GREEN_LIGHTS
	B flashing_lights_loop
loser_prep:
	MOV R2, #ALL_RED_LIGHTS

flashing_lights_loop:

	MOV R0, R2					; METE TUDO A VERDE
	BL outport_write
	
	MOV R0, R3			
	BL wait_ticks

	BL clear_lights				; APAGA OS LEDS TODOS

	MOV R0, R3			
	BL wait_ticks

	SUB R4, R4, #1
	BZS flashing_lights_retur
	B flashing_lights_loop

flashing_lights_retur:
	POP R4
	POP PC
;END


; Rotina:    delay_ticks
; Descricao: 
; Entradas:  R0 -> Recebe o número de ciclos que pretende esperar
; Saidas:    -
; Efeitos:  Espera meio segundo
wait_ticks:
    PUSH LR
    PUSH R1
    PUSH R2

    MOV R2, R0              ; Guarda o tempo desejado
    BL time_get_ref
    MOV R1, R0              ; R1 = tempo de referência inicial

wait_loop:
    MOV R0, R1
    BL time_elapsed         ; Calcula diferença entre agora e R1
    CMP R0, R2              ; Compara tempo decorrido com o desejado
    BLT wait_loop          ; Enquanto decorrido < desejado, espera

    POP R2
    POP R1
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
	PUSH R5

	MOV R4, R1

	BL convert_moleinput_moleoutput	; FICA EM R0 o index da marretada detetada
	MOV R5, R0

	BL get_mole_green 				; VAI BUSCAR A MASCARA QUE REPRESENTA OS LEDS VERDES NO INDEX DA MARRETA
	AND R0, R0, R4					; VALIDA SE O BIT GREEN OBTIDO CORRESPONDE À POSICAO DA TOUPEIRA

	BZS mole_hit_return_false

	MOV R0, R5
	BL turn_mole_red				; APAGA O LED VERDE E ACENDE O RESPETIVO LED VERMERLHO
	B mole_hit_return_true

mole_hit_return_false:
	MOV R0, #0
	B mole_hit_return
mole_hit_return_true:
	MOV R0, #1

mole_hit_return:

	POP R5
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

	BL outport_write

	POP PC
; END SHOW_MOLES_STATE


; Rotina:    get_moles_positions_from_array
; Descricao: 
; Entradas: R0 -> Indice do array aleatorio para aceder ao array de posicionamentoos das toupeiras 
; Saidas:   
; Efeitos:  
get_moles_positions_from_array:
	LDR R1, moles_position_addr
	LDRB R0, [R1, R0]

	MOV PC, LR
;END 




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
	LDR	 r2, last_play_addr
	LDRB r3, [r2]	; VALOR EM MEMORIA

	STRB r0, [r2]	; ATUALIZA EM MEMORIA

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

	BL	outport_write		 					; Escreve o zero no output port
	MOV	r0, #INT_CS_ADDRESS & 0xFF				; CARREGA O ENDEREÇO DE MEMÓRIA DO INT_CS
	MOVT	r0, #(INT_CS_ADDRESS >> 8) & 0xFF	; CARREGA O ENDEREÇO DE MEMÓRIA DO INT_CS		
	STRB	r0, [r0, #0]						; Faz um STOREB para ativar o sinal nWrL

	mrs	r0, cpsr								; Passa as flags para o R0
	MOV	r1, #ENABLE_EXTINT						; Passa para R1 a mascara que ativa a flag I
	orr	r0, r0, r1								; Realiza um OR bit a bit entre R0 e R1
	msr	cpsr, r0								; Passa as novas flags atualizadas para o registo CPSR

	POP PC
;END interruption


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

;END




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
	MOV R0, #ALL_YELLOW_LIGHTS ; Coloca todos os 8 bits do output a 1, que significa ativar o RED e GREEN simultaneamente

	BL outport_set_bits

	POP PC
; END

;
; >> Função CLEAR LIGHTS << Desliga todos os leds
; Tipo: - NAO FOLHA -
; Parametros de entrada:
;	-
; variaveis locais:
;	-
; Parametros de saida:
;   - 
;
clear_lights: 
	PUSH LR
	MOV R0, #NO_LIGHTS 

	BL outport_write

	POP PC
; END

;
; >> Função READ_MARRETA << Lê os 4bits menos significativos do inputport
; Tipo: - NAO FOLHA -
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

	MOV R2, #ALL_GREEN_LIGHTS	; MASCARA QUE CORRESPONDE A TODAS AS POSIÇÕES POSSIVEIS DAS TOUPEIRAS VIVAS
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


; Rotina:    generate_new_mole
; Descricao: 
; Entradas:
; Saidas:    Devolve a posição do array das toupeiras gerada aleatoriamente
; Efeitos:  
generate_new_mole:
	PUSH LR

	BL sysclk_get_ticks		; VAI buscar o valor da variavel sysclk
	MOV R1, #0x07
	AND R0, R0, R1			; Filtra para ficar só com os 2 bits menos significativos __XX


	POP PC
;END

; Rotina:    generate_new_mole
; Descricao: 
; Entradas: R0 -> N º da ronda atual
; Saidas:   R0 -> Mascarada de onde estão posicionadas as toupeiras geradas aleatoriamente
;				1 Toupeira se: 0 <= N <= 3
;				2 Toupeira se: 4 <= N <  7
; Efeitos:  
generate_random_mole:
	PUSH LR
	PUSH R4
	MOV R4, R0

	BL generate_new_mole 
	MOV R1, #3
	CMP R4, R1		; SE nº de ronda for >= que 3
	BLO return_random_mole

two_moles:
	MOV R1, #0x08
	ORR R0, R1, R0

return_random_mole:

	BL get_moles_positions_from_array

	POP R4
	POP PC
;END


; Rotina:    generate_new_mole
; Descricao: 
; Entradas: 
; Saidas:   R0 -> Valor em ciclos da dificuldade definida em memória
; Efeitos:  
get_difficulty_time:

	LDR R1, diff_addr
	LDR R0, [R1]					; CARREGA EM R0 o tempo retirado do array de periodos

	MOV PC, LR
;END 

; Rotina:    generate_new_mole
; Descricao: 
; Entradas: R0 -> Valor em ciclos da dificuldade para guardar em memória
; Saidas:   
; Efeitos:  
set_difficulty_time:
	LDR r1, diff_addr	; Carrega o endereço da variavel
	STR r0, [R1]		; Guarda o valor obtido do array na variável

	MOV PC, LR
;END 

diff_addr:   		.word dificulty_time


; Rotina:    generate_new_mole
; Descricao: 
; Entradas: R0 -> Indice do array com os periodos definidos para a dificuldade. 
; Saidas:   
; Efeitos:  
get_period_time_from_array:
	LDR r1, period_addr	; Carrega o endereço do array
	LDR r0, [R1, R0]	; Carrega do array a posição R0

	MOV PC, LR
;END 

period_addr:  		.word period



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
	MOV	 r1, #OUTPORT_ADDRESS & 0xFF
	MOVT r1, #(OUTPORT_ADDRESS >> 8) & 0xFF
	STRB r0, [r1, #0]

	; É necessário guardar o ultimo valor escrito no output port para conseguirmos modificar o ultimo valor com
	; uma mascara

    LDR r1, out_port_img_addr    
    STRB r0, [r1, #0]

	MOV	pc, lr

; Rotina:    INPORT_READ
; Descricao: lê do porto de saida os 8 bits.
;            Interface exemplo: uint8_t outport_write();
; Entradas:   - 
; Saidas:    r0 - valor lido do porto de entrada

inport_read:
    LDR r0, input_port_addr
    LDRB r0, [r0]
    MOV pc, lr

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
	PUSH LR

	BL sysclk_get_ticks

	POP PC
;time_get_ref

; Rotina:    time_elapsed
; Descricao: Retorna o número de ticks passados desde o tempo de referência
; Entradas:  R0 - tempo de referência (quando se iniciou a contagem de tempo)
; Saidas:    R0 - número de ticks passados desde tempo de referência (now-ref : de notar que o resultado da diferença continua a ser válido se now<ref)
; Efeitos:   *** Para completar ***
time_elapsed:
	PUSH LR

	MOV R1, R0

	BL sysclk_get_ticks		; Retorna o valor atual do sysclock

	SUB R0, R0, R1			; Calcula a diferença entre o tempo atual (sysclk) e o valor referncia (sysclk antigo)

	POP PC
;time_elapsed

/************************************************************************************
 * HAL sys_clk
 ************************************************************************************/
; Rotina:    isr
; Descricao: Incrementa o valor da variável global sysclk.
; Entradas:  -
; Saidas:    -
; Efeitos:   *** Para completar ***
isr:
	PUSH	LR
	PUSH	r1
	PUSH	r0
	
	BL 		ptc_clr_irq

	LDR		r0, SYSCLK_ADDR
	LDR		r1, [r0, #0]
	ADD		r1, r1, #1
	STR		r1, [r0, #0]
	POP		r0
	POP		r1	
	POP		LR 

	MOVS	pc, lr


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
	PUSH	lr
	LDR		r1, SYSCLK_ADDR
	MOV		r2, #0
	STR 	r2, [r1]
	BL		ptc_init
	POP		pc
	
; Rotina:    sysclk_get_ticks
; Descricao: Devolve o valor corrente da variável global sysclk.
;            Interface exemplo: uint16_t sysclk_get_ticks ( );
; Entradas:  -
; Saidas:    *** Para completar ***
; Efeitos:   -
sysclk_get_ticks:
	LDR		r0, SYSCLK_ADDR
	LDR		r0, [r0]
	MOV		pc, lr


.align 1
SYSCLK_ADDR: .word	sysclk


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
    PUSH    lr
	PUSH	r0
	BL 		ptc_stop
	POP		r0
	LDR		r1, PTC_ADDR
	STRB	r0, [r1, #PTC_TMR_ADDRESS]
    BL  	ptc_clr_irq
	BL 		ptc_start
	POP pc



; Rotina:    ptc_start
; Descricao: Habilita a contagem no periferico pTC.
;            Interface exemplo: void ptc_start( );
; Entradas:  -
; Saidas:    -
; Efeitos:   -
ptc_start:
	LDR		r0, PTC_ADDR
	MOV		r1, #PTC_CMD_START
	STRB	r1, [r0, #PTC_TC_ADDRESS]
	MOV		pc, lr

; Rotina:    ptc_stop
; Descricao: Para a contagem no periferico pTC.
;            Interface exemplo: void ptc_stop( );
; Entradas:  -
; Saidas:    -
; Efeitos:   O valor do registo TC do periferico e colocado a zero.
ptc_stop:
	LDR		r0, PTC_ADDR
	MOV		r1, #PTC_CMD_STOP
	STRB	r1, [r0, #PTC_TC_ADDRESS]
	MOV		pc, lr

; Rotina:    ptc_get_value
; Descricao: Devolve o valor corrente da contagem do periferico pTC.
;            Interface exemplo: uint8_t ptc_get_value( );
; Entradas:  -
; Saidas:    R0 - O valor corrente do registo TC do periferico.
; Efeitos:   -
ptc_get_value:
	LDR		r1, PTC_ADDR
	LDRB	r0, [r1, #PTC_TC_ADDRESS]
	MOV		pc, lr

; Rotina:    ptc_clr_irq
; Descricao: Sinaliza o periferico pTC que foi atendido um pedido de
;            interrupção.
;            Interface exemplo: void ptc_clr_irq( );
; Entradas:  -
; Saidas:    -
; Efeitos:   -
ptc_clr_irq:
	LDR		r0, PTC_ADDR
	STRB	r1, [r0, #PTC_TIR_ADDRESS]
	MOV		pc, lr

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

;1KHZ
period: 
    .word 0x7D0 ; 10  s
    .word 0x5E7 ; 9	  s
    .word 0x479 ; 7	  s
    .word 0x347 ; 5	  s
    .word 0x320 ; 4	  s
	.word 0x1F8 ; 3	  s
    .word 0x14F ; 2	  s
	.word 0xA7 	; 1	  s


; Seccao:    data
; Descricao: Guarda as variaveis globais
;
	.data
dificulty_time:	.space	2
outport_img: 	.space	1
last_play:   	.space	1
sysclk:			.space	2

moles_position: ; GUARDAR AS POSIÇÕES EM 8 BITS.
	; 1 TOUPEIRAS
	.byte 0x20	; [ _1__ ]
	.byte 0x80	; [ 1___ ]
	.byte 0x02	; [ ___1 ]
	.byte 0x08	; [ __1_ ]
	.byte 0x20	; [ _1__ ]
	.byte 0x80	; [ 1___ ]
	.byte 0x02	; [ ___1 ]
	.byte 0x08	; [ __1_ ]
	; 2 TOUPEIRAS
	.byte 0x88	; [ 1_1_ ]
	.byte 0x22	; [ _1_1 ]
	.byte 0x28	; [ _11_ ]
	.byte 0x82	; [ 1__1 ]
	.byte 0xC0	; [ 11__ ]
	.byte 0x0C	; [ __11 ]
	.byte 0x82	; [ 1__1 ]
	.byte 0x22	; [ _1_1 ]


; Seccao:    stack
; Descricao: Implementa a pilha com a dimensao definida pelo simbolo STACK_SIZE
;
	.stack
	.space	STACK_SIZE
stack_top:


; SE A FREQ FOR 100kH, dá 0.01ms por cada contagem de clock. Se for até 255, dá no maximo 2,5ms
; SE A FREQ FOR 1kH, dá 1ms por cada contagem de clock. Se for até 255, dá no maximo 255ms

; COM 1KHZ
; 	TEMPO		CICLOS	PL		
; 	0.5	s		84		83	 	[0x53]
; 	1	s		168		167		[0xA7]
; 	2	s		336		335		[0x14F]
; 	3	s		504		503		[0x1F7]
; 	4	s		672		671		[0x29F]
; 	5	s		840		839		[0x347]
; 	6	s		1008	1007	[0x3EF]
; 	7	s		1176	1175	[0x479]
; 	8	s		1344	1343	[0x53F]
; 	9	s		1512	1511	[0x5E7]
; 	10	s		1680	1679	[0x68F]
; 


