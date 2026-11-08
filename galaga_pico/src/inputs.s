@ ============================================================================
@ inputs.s - Joystick: ejes X/Y por ADC (GP26=ADC0, GP27=ADC1) y botón Z (GP22)
@ ============================================================================
.include "defs.inc"

.text

@ inputs_init: configura pines y enciende el ADC
func inputs_init
    ldr  r2, =(IO_BANK0_BASE + 0x04 + 8*22)   @ GPIO22_CTRL
    movs r1, #5                               @ FUNCSEL = SIO
    str  r1, [r2]
    ldr  r2, =(IO_BANK0_BASE + 0x04 + 8*26)   @ GPIO26_CTRL
    movs r1, #31                              @ FUNCSEL = null (analógico)
    str  r1, [r2]
    ldr  r2, =(IO_BANK0_BASE + 0x04 + 8*27)   @ GPIO27_CTRL
    str  r1, [r2]
    ldr  r2, =(PADS_BANK0_BASE + 0x04 + 4*22) @ pad del botón: IE + pull-up
    movs r1, #0x5A
    str  r1, [r2]
    movs r1, #0x10                            @ pads analógicos: IE=0, sin pulls
    ldr  r2, =(PADS_BANK0_BASE + 0x04 + 4*26)
    str  r1, [r2]
    ldr  r2, =(PADS_BANK0_BASE + 0x04 + 4*27)
    str  r1, [r2]
    ldr  r0, =ADC_BASE
    movs r1, #1
    str  r1, [r0]                             @ ADC_CS.EN = 1
1:  ldr  r1, [r0]
    lsls r1, r1, #23                          @ bit 8 (READY) -> bit 31
    bpl  1b
    bx   lr
    .ltorg

@ adc_read: r0 = canal (0..4)  ->  r0 = lectura de 12 bits (0..4095)
func adc_read
    ldr  r1, =ADC_BASE
    lsls r0, r0, #12                          @ AINSEL
    movs r2, #1
    orrs r0, r0, r2                           @ EN
    str  r0, [r1]
    movs r2, #4
    orrs r0, r0, r2                           @ START_ONCE
    str  r0, [r1]
    movs r2, #1
    lsls r2, r2, #8                           @ máscara READY
1:  ldr  r3, [r1]
    tst  r3, r2
    beq  1b
    ldr  r0, [r1, #4]                         @ ADC_RESULT
    bx   lr
    .ltorg

@ input_axis: r0 = canal  ->  r0 = desplazamiento con signo (-4..+3 px/frame)
@ Zona muerta de +-400 alrededor del centro (2048); luego escala por >>9.
func input_axis
    push {lr}
    bl   adc_read
    ldr  r1, =2048
    subs r0, r0, r1                           @ centrar
    ldr  r1, =400
    cmp  r0, r1
    bgt  1f
    negs r1, r1
    cmp  r0, r1
    blt  1f
    movs r0, #0                               @ dentro de la zona muerta
    pop  {pc}
1:  asrs r0, r0, #9
    pop  {pc}
    .ltorg

@ input_button_pressed: r0 = 1 si el botón Z está pulsado (activo en bajo)
@ Con BTN_FALLBACK=1 también cuenta la palanca empujada a tope a la izquierda
@ (solo para emergencias si el pulsador del módulo no responde).
func input_button_pressed
.if BTN_FALLBACK
    push {lr}
.endif
    ldr  r1, =SIO_BASE
    ldr  r0, [r1, #4]                         @ GPIO_IN
    lsrs r0, r0, #22
    movs r1, #1
    ands r0, r0, r1
    eors r0, r0, r1                           @ invierte
.if BTN_FALLBACK
    cmp  r0, #0
    bne  8f
    movs r0, #0
    bl   adc_read                             @ eje X
    ldr  r1, =300
    cmp  r0, r1
    blo  7f
    movs r0, #0
    b    8f
7:  movs r0, #1
8:  pop  {pc}
.else
    bx   lr
.endif
    .ltorg

@ input_wait_press: espera a soltar y luego a que se pulse el botón Z
func input_wait_press
    push {lr}
1:  bl   led_heartbeat
    bl   input_button_pressed
    cmp  r0, #0
    bne  1b
2:  bl   led_heartbeat
    bl   input_button_pressed
    cmp  r0, #0
    beq  2b
    pop  {pc}
    .ltorg

@ input_moved: r0 = 1 si la palanca esta empujada (cualquier eje) mas alla de
@ MOVE_THRESH desde el centro (2048); 0 si esta en reposo. Preserva r4.
func input_moved
    push {r4, lr}
    movs r0, #0
    bl   adc_read                             @ eje del canal 0
    bl   dev_big
    movs r4, r0
    movs r0, #1
    bl   adc_read                             @ eje del canal 1
    bl   dev_big
    orrs r0, r0, r4
    pop  {r4, pc}
    .ltorg

@ dev_big (interna): r0 = lectura ADC -> r0 = 1 si |r0 - 2048| > MOVE_THRESH
func dev_big
    ldr  r1, =2048
    subs r0, r0, r1
    bpl  1f
    negs r0, r0                               @ valor absoluto
1:  ldr  r1, =MOVE_THRESH
    cmp  r0, r1
    bhi  2f
    movs r0, #0
    bx   lr
2:  movs r0, #1
    bx   lr
    .ltorg

@ input_wait_move: espera a que la palanca vuelva al centro y luego a que se
@ mueva. Reemplaza al boton Z para iniciar / reiniciar la partida.
func input_wait_move
    push {lr}
1:  bl   led_heartbeat
    bl   input_moved
    cmp  r0, #0
    bne  1b                                   @ aun empujada: esperar a soltar
2:  bl   led_heartbeat
    bl   input_moved
    cmp  r0, #0
    beq  2b                                   @ en reposo: esperar movimiento
    pop  {pc}
    .ltorg
