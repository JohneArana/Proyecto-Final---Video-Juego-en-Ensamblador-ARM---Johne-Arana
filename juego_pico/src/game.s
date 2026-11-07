@ ============================================================================
@ game.s - Lógica de "METEOROS": nave controlada por joystick (ejes X/Y) que
@ esquiva 4 meteoros que caen solos. Colisión AABB, 3 vidas, puntos por cada
@ meteoro esquivado, dificultad creciente, HUD y pantallas de menú / Game Over.
@ ============================================================================
.include "defs.inc"

.section .bss
.align 2
.global game_vars
game_vars: .space 72

.section .rodata
spr_player: .byte 0xE0,0x70,0x3C,0x7F,0x7F,0x3C,0x70,0xE0
spr_enemy:  .byte 0x3C,0x7E,0xEF,0xFB,0xFF,0xF7,0x7E,0x3C
str_pts:    .asciz "PTS:"
str_vidas:  .asciz "VIDAS:"
str_title:  .asciz "METEOROS"
str_press:  .asciz "PULSA Z"
str_over:   .asciz "GAME OVER"

.text

@ rng_next: xorshift32 -> r0 = número pseudoaleatorio (estado en game_vars)
func rng_next
    ldr  r1, =game_vars
    ldr  r0, [r1, #G_RNG]
    lsls r2, r0, #13
    eors r0, r0, r2
    lsrs r2, r0, #17
    eors r0, r0, r2
    lsls r2, r0, #5
    eors r0, r0, r2
    str  r0, [r1, #G_RNG]
    bx   lr
    .ltorg

@ enemy_respawn: r0 = índice del enemigo (0..3). x aleatoria, y sobre la pantalla,
@ velocidad 1..4 px/frame según azar y puntaje.
func enemy_respawn
    push {r4-r5, lr}
    movs r4, r0
    bl   rng_next
    movs r5, r0
    lsrs r0, r5, #16
    movs r1, #0x7F
    ands r0, r0, r1
    cmp  r0, #120
    bls  1f
    movs r0, #120
1:  ldr  r1, =game_vars
    lsls r2, r4, #2
    adds r3, r1, r2              @ r3 = base + idx*4
    str  r0, [r3, #G_EX]
    lsrs r0, r5, #4
    movs r2, #0x1F
    ands r0, r0, r2
    movs r2, #8
    subs r0, r2, r0              @ y = 8 - (0..31)
    str  r0, [r3, #G_EY]
    lsrs r0, r5, #28
    movs r2, #1
    ands r0, r0, r2
    adds r0, r0, #1              @ 1 ó 2
    ldr  r2, [r1, #G_SCORE]
    lsrs r2, r2, #3              @ +1 de velocidad cada 8 puntos
    cmp  r2, #2
    bls  2f
    movs r2, #2
2:  adds r0, r0, r2
    str  r0, [r3, #G_EV]
    pop  {r4-r5, pc}
    .ltorg

@ game_reset: reinicia TODOS los registros de estado de la partida
func game_reset
    push {r4-r5, lr}
    ldr  r4, =game_vars
    movs r0, #60
    str  r0, [r4, #G_PX]
    movs r0, #52
    str  r0, [r4, #G_PY]
    movs r0, #3
    str  r0, [r4, #G_LIVES]
    movs r0, #0
    str  r0, [r4, #G_SCORE]
    str  r0, [r4, #G_INV]
    ldr  r1, =(TIMER_BASE + 0x0C)
    ldr  r0, [r1]                @ semilla = microsegundos actuales (TIMELR)
    movs r2, #1
    orrs r0, r0, r2              @ nunca cero
    str  r0, [r4, #G_RNG]
    movs r5, #0
1:  movs r0, r5
    bl   enemy_respawn
    adds r5, r5, #1
    cmp  r5, #4
    bne  1b
    pop  {r4-r5, pc}
    .ltorg

@ game_update: un paso de física (se llama 1 vez por tick del timer)
@ devuelve r0 = 1 si la partida terminó (0 vidas), 0 si continúa
func game_update
    push {r4-r6, lr}
    ldr  r4, =game_vars
    @ ---- nave: eje X (canal 0) ----
    movs r0, #0
    bl   input_axis
.if INVERT_X
    negs r0, r0
.endif
    ldr  r1, [r4, #G_PX]
    adds r1, r1, r0
    cmp  r1, #0
    bge  1f
    movs r1, #0
1:  cmp  r1, #120
    ble  2f
    movs r1, #120
2:  str  r1, [r4, #G_PX]
    @ ---- nave: eje Y (canal 1) ----
    movs r0, #1
    bl   input_axis
.if INVERT_Y
    negs r0, r0
.endif
    ldr  r1, [r4, #G_PY]
    adds r1, r1, r0
    cmp  r1, #8                  @ debajo del HUD
    bge  3f
    movs r1, #8
3:  cmp  r1, #56
    ble  4f
    movs r1, #56
4:  str  r1, [r4, #G_PY]
    @ ---- invulnerabilidad ----
    ldr  r0, [r4, #G_INV]
    cmp  r0, #0
    beq  5f
    subs r0, r0, #1
    str  r0, [r4, #G_INV]
    @ ---- enemigos ----
5:  movs r5, #0
6:  lsls r0, r5, #2
    adds r6, r4, r0              @ r6 = base + idx*4
    ldr  r1, [r6, #G_EY]
    ldr  r2, [r6, #G_EV]
    adds r1, r1, r2
    str  r1, [r6, #G_EY]
    cmp  r1, #64
    blt  7f
    ldr  r0, [r4, #G_SCORE]      @ salió por abajo: +1 punto y reaparece
    adds r0, r0, #1
    str  r0, [r4, #G_SCORE]
    movs r0, r5
    bl   enemy_respawn
    b    9f
7:  ldr  r0, [r4, #G_INV]        @ colisión solo si no hay invulnerabilidad
    cmp  r0, #0
    bne  9f
    ldr  r0, [r6, #G_EX]
    ldr  r2, [r4, #G_PX]
    subs r0, r0, r2
    adds r0, r0, #7              @ |dx| <= 7  <=>  0 <= dx+7 <= 14
    cmp  r0, #14
    bhi  9f                      @ comparación sin signo
    ldr  r0, [r6, #G_EY]
    ldr  r2, [r4, #G_PY]
    subs r0, r0, r2
    adds r0, r0, #7
    cmp  r0, #14
    bhi  9f
    ldr  r0, [r4, #G_LIVES]      @ ¡choque!: -1 vida
    subs r0, r0, #1
    str  r0, [r4, #G_LIVES]
    movs r0, #INV_FRAMES
    str  r0, [r4, #G_INV]
    movs r0, r5
    bl   enemy_respawn
9:  adds r5, r5, #1
    cmp  r5, #4
    bne  6b
    @ ---- fin de partida ----
    ldr  r0, [r4, #G_LIVES]
    movs r1, #0
    cmp  r0, #0
    bgt  10f
    movs r1, #1
10: movs r0, r1
    pop  {r4-r6, pc}
    .ltorg

@ game_draw: dibuja la escena completa en el framebuffer (no envía a la pantalla)
func game_draw
    push {r4-r6, lr}
    bl   fb_clear
    ldr  r4, =game_vars
    movs r5, #0
1:  lsls r0, r5, #2
    adds r6, r4, r0
    ldr  r1, [r6, #G_EY]
    cmp  r1, #8
    blt  2f                      @ aún sobre la pantalla / bajo el HUD
    ldr  r0, [r6, #G_EX]
    ldr  r2, =spr_enemy
    bl   fb_draw_sprite
2:  adds r5, r5, #1
    cmp  r5, #4
    bne  1b
    ldr  r0, [r4, #G_INV]        @ parpadeo de la nave mientras es invulnerable
    movs r1, #2
    tst  r0, r1
    bne  3f
    ldr  r0, [r4, #G_PX]
    ldr  r1, [r4, #G_PY]
    ldr  r2, =spr_player
    bl   fb_draw_sprite
3:  movs r0, #0                  @ HUD: PTS:000
    movs r1, #0
    ldr  r2, =str_pts
    bl   fb_draw_text
    movs r0, #24
    movs r1, #0
    ldr  r2, [r4, #G_SCORE]
    bl   fb_draw_number3
    movs r0, #80                 @ HUD: VIDAS:n
    movs r1, #0
    ldr  r2, =str_vidas
    bl   fb_draw_text
    movs r0, #116
    movs r1, #0
    ldr  r2, [r4, #G_LIVES]
    adds r2, r2, #48
    bl   fb_draw_char
    pop  {r4-r6, pc}
    .ltorg

@ draw_menu: pantalla inicial estática
func draw_menu
    push {lr}
    bl   fb_clear
    movs r0, #40
    movs r1, #1
    ldr  r2, =str_title
    bl   fb_draw_text
    movs r0, #28
    movs r1, #32
    ldr  r2, =spr_player
    bl   fb_draw_sprite
    movs r0, #92
    movs r1, #32
    ldr  r2, =spr_enemy
    bl   fb_draw_sprite
    movs r0, #43
    movs r1, #6
    ldr  r2, =str_press
    bl   fb_draw_text
    bl   oled_flush
    pop  {pc}
    .ltorg

@ draw_gameover: pantalla final con el puntaje
func draw_gameover
    push {r4, lr}
    bl   fb_clear
    movs r0, #37
    movs r1, #1
    ldr  r2, =str_over
    bl   fb_draw_text
    movs r0, #43
    movs r1, #3
    ldr  r2, =str_pts
    bl   fb_draw_text
    ldr  r4, =game_vars
    movs r0, #67
    movs r1, #3
    ldr  r2, [r4, #G_SCORE]
    bl   fb_draw_number3
    movs r0, #43
    movs r1, #6
    ldr  r2, =str_press
    bl   fb_draw_text
    bl   oled_flush
    pop  {r4, pc}
    .ltorg
