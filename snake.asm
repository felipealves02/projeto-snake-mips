#===============================================================================
# PROJETO SNAKE - Assembly MIPS (simulador MARS)
#-------------------------------------------------------------------------------
# Regiao de jogo : 512 x 512 pixels  ->  Bitmap Display do MARS
# Celula         : 16 x 16 pixels    ->  grade de 32 x 32 = 1024 celulas
# Endereco base  : 0x10010000 (static data) -> rotulo "tela" (1o dado do .data)
#
# Regras implementadas (conforme a especificacao):
#   - A cobra comeca com tamanho 1 (so a cabeca) na celula (0,0).
#   - A comida e colocada numa celula (I,J) sorteada aleatoriamente.
#   - A cada 0,5 s a cobra anda uma celula, repetindo o ultimo comando
#     recebido caso nenhuma tecla nova tenha sido pressionada.
#   - Ao comer, a cobra cresce 1 celula na cauda e a comida reaparece
#     em outra posicao livre.
#   - Fim de jogo quando a cabeca atinge uma parede (borda da regiao) ou
#     qualquer parte do proprio corpo; a pontuacao e entao exibida.
#   - Pontuacao: +1 ponto a cada 0,5 s e +5 pontos a cada comida coletada.
#
# COMO EXECUTAR NO MARS
#   1) Tools > Bitmap Display:
#        Unit Width = 16 , Unit Height = 16
#        Display Width = 512 , Display Height = 512
#        Base address for display = 0x10010000 (static data)
#      Clique em "Connect to MIPS".
#   2) Tools > Keyboard and Display MMIO Simulator  >  "Connect to MIPS".
#   3) Monte (F3) e execute (F5). Clique dentro da caixa de entrada do
#      MMIO Simulator e use as teclas W (cima), A (esquerda), S (baixo),
#      D (direita). A primeira tecla inicia a partida.
#===============================================================================

                .data
#-------------------------------------------------------------------------------
# ATENCAO: "tela" precisa ser o PRIMEIRO dado declarado, pois o Bitmap Display
# le a partir de 0x10010000. Cada palavra (4 bytes) = uma celula de 16x16 px.
# Indice da celula = linha * 32 + coluna   (0 .. 1023)
#-------------------------------------------------------------------------------
tela:           .space 4096         # 32 x 32 celulas x 4 bytes

                .align 2
corpo:          .space 4096         # fila circular: celulas ocupadas pela cobra
ocupado:        .space 1024         # 1 byte por celula: 1 = tem cobra, 0 = vazio

                .align 2
cab_x:          .word 0             # coluna atual da cabeca
cab_y:          .word 0             # linha atual da cabeca
dir_x:          .word 1             # direcao pendente (comando do jogador)
dir_y:          .word 0
ult_x:          .word 1             # direcao realmente usada no ultimo passo
ult_y:          .word 0             # (serve para proibir a inversao de 180 graus)
tamanho:        .word 1             # quantidade de celulas da cobra
cabeca_idx:     .word 0             # posicao da cabeca dentro da fila "corpo"
comida:         .word 0             # celula onde esta a comida
pontos:         .word 0             # pontuacao do jogador
recorde:        .word 0
msg_recorde:    .asciiz " | Maior Recorde: "

msg_abertura:   .asciiz "=== PROJETO SNAKE - MIPS ===\nTeclas: W (cima)  A (esquerda)  S (baixo)  D (direita)\nAbra o Bitmap Display (16x16, 512x512, base 0x10010000) e o\nKeyboard and Display MMIO Simulator, clique na caixa de entrada\ne pressione uma tecla para comecar.\n"
msg_fim:        .asciiz "\nFIM DE JOGO! Pontuacao final: "
msg_vitoria:    .asciiz "\nVITORIA! A cobra ocupou toda a tela. Pontuacao final: "
msg_nl:         .asciiz "\n"

                .text
                .globl main

#===============================================================================
# PROGRAMA PRINCIPAL
#===============================================================================
main:
                li      $v0, 4                  # imprime as instrucoes no console
                la      $a0, msg_abertura
                syscall

                jal     limpar_tela             # pinta o fundo de toda a regiao
                jal     iniciar_jogo            # cobra em (0,0) + primeira comida

#--- espera o jogador apertar a primeira tecla antes de comecar o relogio ------
espera_inicio:
                jal     ler_teclado             # $v0 = 1 se veio tecla valida
                bnez    $v0, loop_principal
                li      $v0, 32                 # dorme 20 ms para nao travar a CPU
                li      $a0, 20
                syscall
                j       espera_inicio

#--- laco do jogo: 1 volta = 1 passo da cobra = 0,5 s --------------------------
loop_principal:
                jal     esperar_passo           # 500 ms lendo o teclado o tempo todo
                jal     mover                   # $v0: 0 = segue, 1 = colidiu, 2 = venceu

                li      $t0, 1
                beq     $v0, $t0, fim_de_jogo
                li      $t0, 2
                beq     $v0, $t0, vitoria
                j       loop_principal

#--- encerramento --------------------------------------------------------------
fim_de_jogo:
                jal     pintar_cobra_vermelha   # destaque visual do "game over"
                li      $v0, 4
                la      $a0, msg_fim
                syscall
                j       mostrar_pontos

vitoria:
                li      $v0, 4
                la      $a0, msg_vitoria
                syscall

mostrar_pontos:
                li      $v0, 1                  # imprime a pontuacao final
                lw      $a0, pontos
                syscall
                
                # --- Atualiza e Exibe o Recorde ---
                lw      $t0, pontos
                lw      $t1, recorde
                ble     $t0, $t1, exibe_recorde # Se pontos <= recorde, salta
                sw      $t0, recorde            # Grava novo recorde na memoria
                move    $t1, $t0
exibe_recorde:
                li      $v0, 4
                la      $a0, msg_recorde
                syscall
                li      $v0, 1
                move    $a0, $t1                # Imprime o valor do recorde
                syscall
                
                li      $v0, 4
                la      $a0, msg_nl
                syscall
                
                # --- Pausa e Reinício Automático ---
                li      $v0, 32                 # Syscall de sleep (dormir)
                li      $a0, 2000               # Espera 2000 ms (2 segundos)
                syscall
                
                j       main                    # Volta ao inicio sem fechar o programa

#===============================================================================
# limpar_tela - pinta as 1024 celulas com a cor do fundo
#===============================================================================
limpar_tela:
                la      $t0, tela
                li      $t1, 1024
                li      $t2, 0x00101010         # cor do fundo (cinza bem escuro)
lt_loop:
                sw      $t2, 0($t0)
                addiu   $t0, $t0, 4
                addiu   $t1, $t1, -1
                bgtz    $t1, lt_loop
                jr      $ra

#===============================================================================
# iniciar_jogo - zera as estruturas, poe a cobra em (0,0) e sorteia a comida
#===============================================================================
iniciar_jogo:
                addiu   $sp, $sp, -4
                sw      $ra, 0($sp)

                # --- marca todas as celulas como vazias ---
                la      $t0, ocupado
                li      $t1, 1024
ij_zera:
                sb      $zero, 0($t0)
                addiu   $t0, $t0, 1
                addiu   $t1, $t1, -1
                bgtz    $t1, ij_zera

                # --- estado inicial da cobra (tamanho 1, celula (0,0)) ---
                sw      $zero, cab_x
                sw      $zero, cab_y
                li      $t2, 1
                sw      $t2, dir_x              # comeca andando para a direita
                sw      $zero, dir_y
                sw      $t2, ult_x
                sw      $zero, ult_y
                sw      $t2, tamanho
                sw      $zero, cabeca_idx
                sw      $zero, pontos

                la      $t3, corpo              # corpo[0] = celula 0
                sw      $zero, 0($t3)
                la      $t3, ocupado            # ocupado[0] = 1
                sb      $t2, 0($t3)

                la      $t3, tela               # pinta a cabeca
                li      $t4, 0x0033AAFF
                sw      $t4, 0($t3)

                jal     nova_comida

                lw      $ra, 0($sp)
                addiu   $sp, $sp, 4
                jr      $ra

#===============================================================================
# nova_comida - sorteia uma celula livre (I,J) e desenha a comida nela
#===============================================================================
nova_comida:
nc_sorteia:
                li      $v0, 42                 # inteiro aleatorio em [0, 1024)
                li      $a0, 0                  # gerador 0
                li      $a1, 1024
                syscall                         # resultado volta em $a0

                move    $t0, $a0
                la      $t1, ocupado
                addu    $t1, $t1, $t0
                lb      $t2, 0($t1)
                bnez    $t2, nc_sorteia         # caiu em cima da cobra: sorteia de novo

                sw      $t0, comida
                la      $t3, tela               # pinta a comida de verde
                sll     $t4, $t0, 2
                addu    $t3, $t3, $t4
                li      $t5, 0x0022CC22
                sw      $t5, 0($t3)
                jr      $ra

#===============================================================================
# esperar_passo - espera 0,5 s divididos em 25 fatias de 20 ms, lendo o
#                 teclado a cada fatia (assim nenhuma tecla se perde)
#===============================================================================
esperar_passo:
                addiu   $sp, $sp, -8
                sw      $ra, 0($sp)
                sw      $s0, 4($sp)

                li      $s0, 25
ep_loop:
                jal     ler_teclado
                li      $v0, 32
                li      $a0, 20
                syscall
                addiu   $s0, $s0, -1
                bgtz    $s0, ep_loop

                jal     ler_teclado             # pega o que chegou na ultima fatia

                lw      $ra, 0($sp)
                lw      $s0, 4($sp)
                addiu   $sp, $sp, 8
                jr      $ra

#===============================================================================
# ler_teclado - consome todas as teclas pendentes no MMIO (0xffff0000) e
#               guarda a ultima direcao valida em dir_x/dir_y.
#               Retorno: $v0 = 1 se alguma tecla valida foi lida, senao 0.
#===============================================================================
ler_teclado:
                li      $v0, 0
                li      $t0, 0xffff0000         # controle do receptor
lk_poll:
                lw      $t1, 0($t0)
                andi    $t1, $t1, 1             # bit 0 = tem caractere pronto?
                beqz    $t1, lk_ret
                lw      $t2, 4($t0)             # le o caractere (limpa o bit)

                # --- converte maiuscula em minuscula ---
                li      $t3, 65                 # 'A'
                blt     $t2, $t3, lk_compara
                li      $t3, 90                 # 'Z'
                bgt     $t2, $t3, lk_compara
                addiu   $t2, $t2, 32
lk_compara:
                li      $t3, 119                # 'w' -> cima
                beq     $t2, $t3, lk_cima
                li      $t3, 115                # 's' -> baixo
                beq     $t2, $t3, lk_baixo
                li      $t3, 97                 # 'a' -> esquerda
                beq     $t2, $t3, lk_esquerda
                li      $t3, 100                # 'd' -> direita
                beq     $t2, $t3, lk_direita
                j       lk_poll                 # outra tecla: ignora

lk_cima:        li      $t4, 0
                li      $t5, -1
                j       lk_aplica
lk_baixo:       li      $t4, 0
                li      $t5, 1
                j       lk_aplica
lk_esquerda:    li      $t4, -1
                li      $t5, 0
                j       lk_aplica
lk_direita:     li      $t4, 1
                li      $t5, 0

lk_aplica:
                # proibe a inversao de 180 graus quando a cobra tem corpo
                lw      $t6, tamanho
                li      $t7, 1
                beq     $t6, $t7, lk_aceita
                lw      $t8, ult_x
                lw      $t9, ult_y
                addu    $t8, $t8, $t4           # soma zero nos dois eixos
                addu    $t9, $t9, $t5           # significa direcao oposta
                bnez    $t8, lk_aceita
                bnez    $t9, lk_aceita
                j       lk_poll                 # comando invalido: descarta
lk_aceita:
                sw      $t4, dir_x
                sw      $t5, dir_y
                li      $v0, 1
                j       lk_poll
lk_ret:
                jr      $ra

#===============================================================================
# mover - executa um passo da cobra.
#         Retorno em $v0: 0 = continua, 1 = fim de jogo, 2 = vitoria
#===============================================================================
mover:
                addiu   $sp, $sp, -20
                sw      $ra, 0($sp)
                sw      $s0, 4($sp)
                sw      $s1, 8($sp)
                sw      $s2, 12($sp)
                sw      $s3, 16($sp)

                lw      $t0, cab_x
                lw      $t1, cab_y
                lw      $t2, dir_x
                lw      $t3, dir_y
                sw      $t2, ult_x              # direcao efetivamente usada
                sw      $t3, ult_y
                addu    $s0, $t0, $t2           # $s0 = nova coluna
                addu    $s1, $t1, $t3           # $s1 = nova linha

                # --- colisao com as paredes que cercam a regiao ---
                bltz    $s0, mv_bateu
                bltz    $s1, mv_bateu
                li      $t4, 32
                bge     $s0, $t4, mv_bateu
                bge     $s1, $t4, mv_bateu

                sll     $s2, $s1, 5             # $s2 = linha * 32 + coluna
                addu    $s2, $s2, $s0

                # --- a nova celula tem comida? ---
                lw      $t5, comida
                li      $s3, 0
                bne     $s2, $t5, mv_sem_comida
                li      $s3, 1
mv_sem_comida:
                bnez    $s3, mv_pula_cauda

                # --- nao comeu: a cauda sai da celula onde estava ---
                lw      $t6, cabeca_idx
                lw      $t7, tamanho
                subu    $t6, $t6, $t7
                addiu   $t6, $t6, 1
                andi    $t6, $t6, 1023          # indice da cauda na fila circular
                la      $t8, corpo
                sll     $t9, $t6, 2
                addu    $t8, $t8, $t9
                lw      $t9, 0($t8)             # celula da cauda
                la      $t8, ocupado
                addu    $t8, $t8, $t9
                sb      $zero, 0($t8)           # libera a celula
                la      $t8, tela
                sll     $t7, $t9, 2
                addu    $t8, $t8, $t7
                li      $t7, 0x00101010         # apaga (cor do fundo)
                sw      $t7, 0($t8)

mv_pula_cauda:
                # --- colisao com o proprio corpo ---
                la      $t8, ocupado
                addu    $t8, $t8, $s2
                lb      $t9, 0($t8)
                bnez    $t9, mv_bateu

                # --- a cabeca antiga passa a ser corpo ---
                lw      $t0, cabeca_idx
                la      $t2, corpo
                sll     $t3, $t0, 2
                addu    $t3, $t2, $t3
                lw      $t3, 0($t3)             # celula onde estava a cabeca
                la      $t8, ocupado
                addu    $t8, $t8, $t3
                lb      $t9, 0($t8)
                beqz    $t9, mv_sem_repintar    # cobra de tamanho 1: a cauda ja saiu
                la      $t4, tela
                sll     $t5, $t3, 2
                addu    $t4, $t4, $t5
                li      $t5, 0x000066CC         # azul do corpo
                sw      $t5, 0($t4)
mv_sem_repintar:
                # --- avanca a cabeca na fila circular ---
                addiu   $t0, $t0, 1
                andi    $t0, $t0, 1023
                sw      $t0, cabeca_idx
                sll     $t3, $t0, 2
                addu    $t3, $t2, $t3
                sw      $s2, 0($t3)             # corpo[cabeca] = nova celula
                la      $t8, ocupado
                addu    $t8, $t8, $s2
                li      $t9, 1
                sb      $t9, 0($t8)

                la      $t4, tela               # desenha a nova cabeca
                sll     $t5, $s2, 2
                addu    $t4, $t4, $t5
                li      $t5, 0x0033AAFF
                sw      $t5, 0($t4)

                sw      $s0, cab_x
                sw      $s1, cab_y

                # --- pontuacao: +1 por passo (0,5 s) e +5 por comida ---
                lw      $t0, pontos
                addiu   $t0, $t0, 1
                beqz    $s3, mv_sem_bonus
                addiu   $t0, $t0, 5
mv_sem_bonus:
                sw      $t0, pontos

                beqz    $s3, mv_ok

                # --- comeu: a cobra cresce 1 celula e a comida muda de lugar ---
                lw      $t1, tamanho
                addiu   $t1, $t1, 1
                sw      $t1, tamanho
                li      $t2, 1024
                beq     $t1, $t2, mv_venceu     # cobra ocupou a tela inteira
                jal     nova_comida

mv_ok:          li      $v0, 0
                j       mv_sai
mv_bateu:       li      $v0, 1
                j       mv_sai
mv_venceu:      li      $v0, 2
mv_sai:
                lw      $ra, 0($sp)
                lw      $s0, 4($sp)
                lw      $s1, 8($sp)
                lw      $s2, 12($sp)
                lw      $s3, 16($sp)
                addiu   $sp, $sp, 20
                jr      $ra

#===============================================================================
# pintar_cobra_vermelha - no fim de jogo, repinta a cobra de vermelho
#===============================================================================
pintar_cobra_vermelha:
                la      $t0, ocupado
                la      $t1, tela
                li      $t2, 0                  # indice da celula
                li      $t3, 0x00CC2222         # vermelho
pcv_loop:
                addu    $t4, $t0, $t2
                lb      $t5, 0($t4)
                beqz    $t5, pcv_proxima
                sll     $t6, $t2, 2
                addu    $t6, $t1, $t6
                sw      $t3, 0($t6)
pcv_proxima:
                addiu   $t2, $t2, 1
                li      $t7, 1024
                blt     $t2, $t7, pcv_loop
                jr      $ra
