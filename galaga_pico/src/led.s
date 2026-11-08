@ ============================================================================
@ led.s - LED integrado de la Pico (GP25) como diagnostico + estado de la OLED
@   led_init      : GP25 como salida SIO
@   led_on/off    : enciende / apaga
@   led_heartbeat : parpadea segun el TIMER (lento = OLED ok, rapido = OLED no responde)
@ ============================================================================
.include "defs.inc"

.section .bss
.align 2
.global oled_status
oled_status: .space 4            @ 0 = la OLED respondio por I2C, 1 = no respondio

.text

func led_init
    ldr  r0, =(IO_BANK0_BASE + 0x04 + 8*25)   @ GPIO25_CTRL
    movs r1, #5                               @ FUNCSEL = SIO
    str  r1, [r0]
    ldr  r0, =SIO_BASE
    movs r1, #1
    lsls r1, r1, #25
    str  r1, [r0, #0x24]                      @ GPIO_OE_SET: GP25 salida
    bx   lr
    .ltorg

func led_on
    ldr  r0, =SIO_BASE
    movs r1, #1
    lsls r1, r1, #25
    str  r1, [r0, #0x14]                      @ GPIO_OUT_SET
    bx   lr
    .ltorg

func led_off
    ldr  r0, =SIO_BASE
    movs r1, #1
    lsls r1, r1, #25
    str  r1, [r0, #0x18]                      @ GPIO_OUT_CLR
    bx   lr
    .ltorg

@ led_heartbeat: el LED sigue un bit del contador de microsegundos (TIMELR)
@   OLED ok     -> bit 19 (~1 Hz)     OLED sin respuesta -> bit 16 (~8 Hz)
func led_heartbeat
    ldr  r0, =TIMER_BASE
    ldr  r1, [r0, #0x0C]                      @ TIMELR
    ldr  r2, =oled_status
    ldr  r2, [r2]
    cmp  r2, #0
    beq  1f
    lsrs r1, r1, #16
    b    2f
1:  lsrs r1, r1, #19
2:  movs r2, #1
    ands r1, r1, r2
    ldr  r0, =SIO_BASE
    lsls r2, r2, #25
    cmp  r1, #0
    beq  3f
    str  r2, [r0, #0x14]                      @ encender
    bx   lr
3:  str  r2, [r0, #0x18]                      @ apagar
    bx   lr
    .ltorg
