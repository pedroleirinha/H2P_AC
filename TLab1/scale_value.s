    .equ STACK_SIZE, 64
    .equ VAL_MIN, 0x0005

    .text 

    B program
    B . ; Reservado (ISR)

program:
    LDR sp, stack_top_addr
    B main

stack_top_addr:
    .word stack_top

;START MAIN
main:
    PUSH LR

    MOV r0, #100
    MOV r1, #205
    MOV r2, #8

    BL scale_value ; RES = 80

    MOV r0, #0b1111
    MOV r1, #55
    MOV r2, #5

    BL scale_value ; RES = 344
    
    MOV r5, r0

    
    MOV r0, #100
    MOV r1, #22
    MOV r2, #2

    BL scale_value ; RES = 550
    
    MOV r6, r0
    
    
    MOV r0, #255
    MOV r1, #255
    MOV r2, #19

    BL scale_value ; RES = 32
    
    MOV r7, r0

    POP PC

;END MAIN


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
    PUSH LR         ; prologo
    PUSH r4         ; prologo
    PUSH r5         ; prologo
    PUSH r6         ; prologo
    PUSH r7         ; prologo

    MOV r4, r0      ; V
    MOV r5, r1      ; K
    MOV r6, r2      ; S

                    ; r0 e r1 = prod -- 
                    ; Não precisa de estar na stack porque não haverá mais chamadas à funções 
                    ; onde seja preciso perservar o valor
    
    MOV r2, #0xFF   ; k_ext = k & 0xFF; Mascara para tratar os bits
    AND r1, r2, r1  ; menos significativos.    

                    ; r0 = v[i]
                    ; r1 = k_ext

    BL umull
                    ; r0, r1 -> return
    
    MOV r2, #0      ;
    CMP r6, r2      ; if (s != 0)
    BEQ scale_while_end02    

    ; operacoes com s

    MOV r2, #0xFF   ; k_ext = k & 0xFF; Mascara para tratar os bits
    AND r6, r6, r2  ; menos significativos.    


    MOV r2, r6      ; S = 8
    MOV r3, #1      ; valor inicial para o shift dos bits menos significativos
    MOV r4, #0      ; valor inicial para o shift dos bits mais significativos
scale_before_while:
    MOV r5, #1
scale_while:
    CMP	r5, r2          ; S >= 1
    BHS	scale_while_end 
    
    LSL r3, r3, #1  ; desloca o valor de r3 1 bit para a esquerda (multiplica por 2)
    MOV r7, #0
    BCS scale_carry_set
    LSL r4, r4, #1  ; desloca o valor de r4 1 bit para a esquerda (multiplica por 2)

scale_carry_set:
	ADC r4, r4, r7	; Caso o carry = 1 [Do LSL] é adicionado 1 bit ao 2º registo 

    SUB	r2, r2, #1      ; m => contador; m--
    B	scale_while

scale_while_end:
    ADD r0, r0, r3  ; 
    MOV r3, #0      ; prod += 0x00000001 << (s - 1);
    ADC r1, r1, r4  ; 

    MOV r2, r6      ; S = 8
scale_before_while02:
    MOV r4, #0 ; 1
scale_while02:
    CMP	r4, r2              ; S >= 1
    BHS	scale_while_end02 
    
    LSR r1, r1, #1          ; MAIS SIGNIFICATIVO
    RRX r0, r0              ; MENOS SIGNIFICATIVO
    SUB	r2, r2, #1          ; m => contador; m--
    B	scale_while02

scale_while_end02:
    ; prod = r0 e r1

    ; r0 -> prod_s ; r1 -> VAL_MIN; r2 -> r0
    MOV r1, #VAL_MIN
    MOV r2, r0

    BL clamp_value_func    
    ;retorno já esta no r0

    POP r7
    POP r6
    POP r5
    POP r4 
    POP PC
;END SCALE_VALUE


;
; >> Função UMULL <<
; Tipo: - FOLHA -
; Parametros de entrada:
;   uint16_t v --> r0
;   uint16_t k --> r1
;
; variaveis locais:
;   uint16_t p -------> r2  ; Bits menos significativos
;   uint16_t p -------> r3  ; Bits mais significativos
;
; Parametros de saida:
;   uint32_t p -------> r0, r1
;
umull:
    PUSH R4

                        ; compare_menor dos registos
	CMP r0, r1
	BHS before_while    ; aqui o r1 é menor que o r0

                        ; faz troca
    MOV r3, r0          ; mete o M no r4
    MOV r0, r1          ; mete no M o m
    MOV r1, r3          ; mete no m o r4  (que é o M)

before_while:
    MOV r4, #0
    
    MOV r2, #0          ; accumulado/p [0]
    MOV r3, #0          ; accumulado/p [1]

while:
    CMP	r4, r1
    BHS	while_end       ; 0 >= m

    ADD	r2, r2, r0
    MOV r4, #0
    ADC r3, r3, r4
    
    SUB	r1, r1, #1      ; m => contador; m--
    B	while

while_end:

    POP R4 

    MOV r0, r2
    MOV r1, r3
    MOV pc, lr          ; return do p no r0 e r1

;END UMULL



;
; >> Função CLAMP_VALUE <<
; Tipo: - FOLHA -
; Parametros de entrada:
;   uint16_t val --> r0
;   uint16_t min --> r1
;   uint16_t max --> r2
;
; variaveis locais:
;   --Sem variáveis locais --
;
; Parametros de saida:
;   uint32_t val -------> r0
;
clamp_value_func:

    CMP r1, r0  ; if( val < min )
    BLT else
    MOV r0, r1
    B return
else:
    CMP r0, r2  ; if( val > max )
    BLT return
    MOV r0, r2

return:
    MOV PC, LR
;END CLAMP_VALUE


    .data

array_k1: .byte 10, 5, 2, 0
array_k2: .byte 35, 38, 42, 45, 0
array_k3: .byte 205, 154, 0, 45, 35, 0

array_s1: .byte 8, 20, 8, 0
array_s2: .byte 5, 5, 5, 5, 0
array_s3: .byte 8, 8, 0, 5, 5, 0

    .align 1

array_vals1: .space 12 ;[6] words
array_vals2: .space 12 ;[6] words
array_vals3: .space 14 ;[6] words


    .stack
    .space STACK_SIZE
stack_top:
 