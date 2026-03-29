    .equ STACK_SIZE, 128
    .equ SIZE, 10
    .equ MINUS_1, 0xFF
    .equ VOWEL_A, 0x0061
    .equ VOWEL_E, 0x0065
    .equ VOWEL_I, 0x0069
    .equ VOWEL_O, 0x006F
    .equ VOWEL_U, 0x0075

    .text 

    B program
    B . ; Reservado (ISR)

program:
    LDR sp, stack_top_addr
    B   main


;START MAIN
main:

    LDR R0, texto_addr
    MOV R1, #7
    LDR R2, occurrences_addr
    BL  vowel_histogram

    B .

;END MAIN

stack_top_addr: .word stack_top
occurrences_addr: .word occurrences
texto_addr: .word texto




;
; >> Função WHICH_VOWEL <<
; Tipo: - FOLHA -
; Parametros de entrada:
;   CHAR letter --> r0
;
; variaveis locais:
;   int16_t i -------> r0
;
; Parametros de saida:
;   int16_t ---------> r0
;
which_vowel:
    
    MOV r1, r0 ;passa o letter para o r1

    MOV r2, #VOWEL_A    ;    case ’a’
    CMP r1, r2
    MOV R2, #0          
    BEQ jump

    MOV r2, #VOWEL_E    ;    case ’e’
    CMP r1, r2
    MOV R2, #1          
    BEQ jump

    MOV r2, #VOWEL_I    ;    case ’i’
    CMP r1, r2
    MOV R2, #2          
    BEQ jump
    
    MOV r2, #VOWEL_O    ;    case ’o’
    CMP r1, r2
    MOV R2, #3          
    BEQ jump
    
    MOV r2, #VOWEL_U    ;    case ’u’
    CMP r1, r2
    MOV R2, #4          
    BEQ jump

    MOV R2, #MINUS_1
jump: 
    mov r0, r2

    MOV PC, LR
;END WHICH_VOWEL



;
; >> Função WHICH_VOWEL <<
; Tipo: - NÃO FOLHA -
; Parametros de entrada:
;   CHAR[] phrase --> r0
;   uint16_t max_letters --> r1
;   uint16_t[] occurrences --> r2
;
; variaveis locais:
;   int16_t idx -------> r0
;   int16_t i -------> r0
;
; Parametros de saida:
;   VOID
;
vowel_histogram:
    PUSH LR

    PUSH R4
    PUSH R5
    PUSH R6
    PUSH R7

    MOV R4, R0          ; phrase
    MOV R5, R1          ; max_letters
    MOV R6, R2          ; occurrences
    MOV R7, #0          ; i = 0


    ;Condicao do FOR
histogram_for_condition:
    CMP r7, r5          ; i < max_letters
    BHS histogram_end             ; Se i MAIOR OU IGUAL a max_letters

    LDRB r0, [R4, R7]   ; phrase [i]
    MOV R1, #0  
    CMP r0, R1          ; Se phrase [i] == '\0'
    BEQ histogram_end   ; Chegamos ao fim da string

    ;Dentro do ciclo

    ;O R0 já tem o phrase[i]
    BL which_vowel
    ;O R0 agora tem o retorno. O valor da letra
    MOV R1, #MINUS_1
    CMP R0, R1          ; Se idx != -1
    BEQ histogram_for_increment
    
    LSL R0, R0, #1 
    
    LDR R2, [R6, R0]    ; Para ir buscar o valor já no array
    ADD R2, R2, #1      ; incrementa o nº de ocorrencias
    STR R2, [R6, R0]    ;occurrences[idx]++

histogram_for_increment:

    ADD R7, R7, #1  ; i++
    B histogram_for_condition
histogram_end:

    POP R7
    POP R6
    POP R5
    POP R4
    POP PC
;END VOWEL_HISTOGRAM    


    .data
texto:          .asciz "heello"
.align 1
occurrences:    .space SIZE, 0


    .stack
    .space STACK_SIZE
stack_top:
 