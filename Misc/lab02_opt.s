; -----------------------------------------------------------------------------
; Ficheiro:  lab01.s
; Descricao: Codigo de suporte a realizacao da 1a atividade laboratorial de AC.
; Autor:     Tiago M Dias (tiago.dias@isel.pt)
; Data:      11-03-2022
; -----------------------------------------------------------------------------

	; r0 guarda o valor da variavel M
	; r1 guarda o valor da variavel m
	; r2 guarda o valor da variavel p
	; r3 e utilizado para guardar valores temporariamente

initialize:
	mov	r2, #0
	mov	r3, #0 


;compare M != 0:
	cmp	r3, r0 ; 0 - M
	beq end_if ; SE r3 == r0

;compare_menor dos registos
	cmp r0, r1
	bhs while ;aqui o r1 é menor que o r0

;faz troca
	mov r4, r0 ;mete o M no r4
	mov r0, r1 ;mete no M o m
	mov r1, r4 ;mete no m o r4  (que é o M)

while:
	cmp	r3, r1
	bhs	while_end ; 0 >= m
	add	r2, r2, r0
	sub	r1, r1, #1 ; m => contador; m--
	b	while
while_end:
end_if:
	b	.
	
