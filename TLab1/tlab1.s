    .equ STACK_SIZE, 128
    .equ VAL_MIN, 0x0005
    .equ MASK, 0x8000

    .text 

    b program
    b . ; Reservado (ISR)

program:
    ldr sp, stack_top_addr
    b main

stack_top_addr:
    .word stack_top

;START MAIN
main:
    push LR

    mov r0, #100
    ldr r1, array_vals1_addr
    ldr r2, array_k1_addr
    ldr r3, array_s1_addr

    bl build_sequence
    
    mov r4, r0

    ;n2
    mov r0, #10
    ldr r1, array_vals2_addr
    ldr r2, array_k2_addr
    ldr r3, array_s2_addr

    bl build_sequence

    mov r5, r0

    ;n3
    mov r0, #50
    ldr r1, array_vals3_addr
    ldr r2, array_k3_addr
    ldr r3, array_s3_addr

    bl build_sequence
    
    mov r6, r0

    pop PC

;END MAIN


;
; >> Função BUILD_SEQUENCE <<
; Tipo: - NAO FOLHA -
; Parametros de entrada:
;   uint16_t v_init --> r0
;   uint16_t v [] ----> r1
;   uint8_t k [] -----> r2
;   uint8_t s [] -----> r3
;
; variaveis locais:
;   uint16_t i -------> r4
;
; Parametros de saida:
;   uint16_t ---------> r0
;
build_sequence:
    push LR ; prologo
    push r4 ; prologo
    push r5 ; prologo
    push r6 ; prologo
    push r7 ; prologo

    mov r4, #0         ; uint16_t i = 0;

    str r0, [r1]       ; v[0] = v_init;

    mov r5, r1 ; V
    mov r6, r2 ; K
    mov r7, r3 ; S

    ; ciclo while
build_sequence_while:

    mov r3, #0 ; i = 0
    ldrb r2, [r7, r4] ;s[i]

    cmp r3, r2
    beq build_sequence_while_end ; s[i] != 0
    
    LSL r3, r4, #1
    
    ldr r0, [r5, r3]    ;v[i]
    ldrb r1, [r6, r4]   ;k[i]
    ldrb r2, [r7, r4]   ;s[i]

    BL scale_value
    
    ADD	r4, r4, #1 ; i++
    LSL r3, r4, #1

    STR r0, [r5, r3]

    B	build_sequence_while

build_sequence_while_end:
    
    ADD	r0, r4, #1 ; i++

    pop r7
    pop r6
    pop r5
    pop r4 
    pop PC
;END BUILD_SEQUENCE

array_s1_addr:   .word array_s1
array_k1_addr:   .word array_k1
array_vals1_addr: .word array_vals1

array_s2_addr:   .word array_s2
array_k2_addr:   .word array_k2
array_vals2_addr: .word array_vals2

array_s3_addr:   .word array_s3
array_k3_addr:   .word array_k3
array_vals3_addr: .word array_vals3


;
; >> Função SCALE_VALUE <<
; Tipo: - NAO FOLHA -
; Parametros de entrada:
;   uint16_t v -------> r0
;   uint8_t k --------> r1
;   uint8_t s --------> r2
;
; variaveis locais:
;   uint32_t prod ----> r4,r5
;   uint16_t k_ext ---> r6
;   uint16_t prod_s --> r7
;   uint16_t prod_c --> r8
;
; Parametros de saida:
;   uint16_t ---------> r0
;
scale_value: 
    ;r0 = v
    ;r1 = k
    ;r2 = s

    push LR ;prologo
    push r4 ;prologo
    push r5 ;prologo
    push r6 ;prologo
    push r7 ;prologo

    mov r4, r0 ; V
    mov r5, r1 ; K
    mov r6, r2 ; S

    ;r0 e r1 = prod -- Não precisa de estar na stack porque não haverá mais chamadas a funções onde seja preciso perservar o valor
    
    MOV r2, #0xFF                ; k_ext = k & 0xFF; Mascara para tratar os bits
    AND r1, r2, r1               ; menos significativos.    

    ;; r0 = v[i]
    ;; r1 = k_ext

    bl multiplication
    ; r0, r1 -> return
    
    mov r2, #0  ; 
    cmp r6, r2  ; if (s != 0)
    beq scale_while_end02    ; 

    ;operacoes com s

    MOV r2, #0xFF                ; k_ext = k & 0xFF; Mascara para tratar os bits
    AND r6, r6, r2               ; menos significativos.    


    mov r2, r6 ; S = 8
    mov r3, #1
scale_before_while:
    mov r4, #1 ; 1
scale_while:
    cmp	r4, r2 ; S >= 1
    bhs	scale_while_end 
    
    lsl r3, r3, #1
    sub	r2, r2, #1 ; m => contador; m--
    b	scale_while

scale_while_end:

    add r0, r0, r3  ; 
    mov r3, #0      ; prod += 0x00000001 << (s - 1);
    adc r0, r0, r3  ; 

    mov r2, r6 ; S = 8
scale_before_while02:
    mov r4, #0 ; 1
scale_while02:
    cmp	r4, r2 ; S >= 1
    bhs	scale_while_end02 
    
    lsr r1, r1, #1 ;MAIS SIGNIFICATIVO
    RRX r0, r0 ;MENOS SIGNIFICATIVO
    sub	r2, r2, #1 ; m => contador; m--
    b	scale_while02

scale_while_end02:
    ; prod = r0 e r1

    ; r0 -> prod_s ; r1 -> VAL_MIN; r2 -> r0
    mov r1, #VAL_MIN
    mov r2, r0

    bl clamp_value_func    
    ;retorno já esta no r0

    pop r7
    pop r6
    pop r5
    pop r4 
    pop PC
;END SCALE_VALUE


;START MULTIPLICATION
multiplication:
    ;r0 = v
    ;r1 = k
    ;r2,r3 = acc
    
    PUSH R4


    ;compare_menor dos registos
	cmp r0, r1
	bhs before_while ;aqui o r1 é menor que o r0

    ;faz troca
    mov r3, r0 ;mete o M no r4
    mov r0, r1 ;mete no M o m
    mov r1, r3 ;mete no m o r4  (que é o M)

before_while:
    mov r4, #0
    
    mov r2, #0 ;acc[0]
    mov r3, #0 ;acc[1]

while:
    cmp	r4, r1
    bhs	while_end ; 0 >= m

    add	r2, r2, r0
    mov r4, #0
    adc r3, r3, r4
    
    sub	r1, r1, #1 ; m => contador; m--
    b	while

while_end:

    POP R4 

    mov r0, r2
    mov r1, r3
    mov pc, lr ;return

;END MULTIPLICATION


;START CLAMP
clamp_value_func:
    ;r0 = val
    ;r1 = min
    ;r2 = max

    cmp r1, r0 ;if( val < min )
    blt else
    mov r0, r1
    b return
else:
    cmp r0, r2 ;if( val > max )
    blt return
    mov r0, r2

return:
    mov PC, LR
;END CLAMP


    .data

array_k1: .byte 205, 154, 102, 51, 0
array_k2: .byte 35, 38, 42, 45, 0
array_k3: .byte 205, 154, 0, 45, 35, 0

array_s1: .byte 8, 8, 8, 8, 0
array_s2: .byte 5, 5, 5, 5, 0
array_s3: .byte 8, 8, 0, 5, 5, 0

    .align 1

array_vals1: .space 12 ;[6] words
array_vals2: .space 12 ;[6] words
array_vals3: .space 14 ;[6] words


    .stack
    .space STACK_SIZE
stack_top:
 