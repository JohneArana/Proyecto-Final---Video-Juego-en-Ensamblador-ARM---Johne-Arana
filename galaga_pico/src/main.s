@ ============================================================================
@ main.s (GALAGA) - Máquina de estados:  MENU -> JUEGO -> GAME OVER -> JUEGO ...
@   MENU : pantalla estática, espera mover la palanca (timer apagado)
@   JUEGO: cada tick del timer (30 FPS) = leer joystick, física, dibujar, enviar
@   OVER : timer detenido, pantalla final, espera mover la palanca y reinicia registros
@ ============================================================================
.include "defs.inc"

.text
func main
    bl   inputs_init
    bl   i2c_init
    bl   oled_init
    bl   draw_menu               @ estado MENU (r0 = 0 si la OLED respondió)
    ldr  r1, =oled_status
    str  r0, [r1]
    bl   input_wait_move        @ mover la palanca arranca el juego
restart:
    bl   game_reset              @ reinicio de registros de estado
    bl   timer_start             @ estado JUEGO: arranca el timer por hardware
loop:
    cpsid i                      @ evita perder un tick entre el chequeo y WFI
    ldr  r0, =frame_flag
    ldr  r1, [r0]
    cmp  r1, #0
    bne  go
    wfi                          @ duerme hasta la interrupción del timer
    cpsie i
    b    loop
go: movs r1, #0
    str  r1, [r0]
    cpsie i
    bl   game_update
    cmp  r0, #0
    bne  over
    bl   game_draw
    bl   oled_flush              @ ~24 ms de transferencia por I2C
    b    loop
over:                            @ estado GAME OVER
    bl   timer_stop              @ detención total del timer de física
    bl   draw_gameover
    bl   input_wait_move        @ mover la palanca reinicia
    b    restart
    .ltorg
