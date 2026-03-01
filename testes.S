
desafio1: 
    mov R0, R1


desafio2:
    ;Escrevere o maior valor entre A e B na variável C.
    ; A => R0; B => R1; C => R2
    
    ;Primeiro fazemos a subtração dos dois valores para a comparação. Para que tenhamos acesso as flags
    CMP R0 R1
    ;SE A < B. 
    BLT if1
    MOV R2, R0

if1:
    MOV R2, R1


desafio3:
    ;Escreva nas variáveis q e r o quociente e o resto resultantes da divisão de x por y
    ; X => R0; Y => R1; Q => R2; R => R3




