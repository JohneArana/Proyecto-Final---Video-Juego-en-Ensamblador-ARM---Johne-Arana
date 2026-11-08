@ ============================================================================
@ timer.s - Temporizador por hardware (TIMER ALARM0 -> NVIC IRQ0)
@ Cada FRAME_US (33333 us = 30 FPS) la ISR levanta frame_flag. El bucle
@ principal duerme con WFI hasta que llega la interrupción: sin delay loops.
@ ============================================================================
.include "defs.inc"

.section .bss
.align 2
.global frame_flag
frame_flag: .space 4

.text

@ timer_start: arma ALARM0, habilita su interrupción en el TIMER y en el NVIC
func timer_start
    ldr  r0, =frame_flag
    movs r1, #0
    str  r1, [r0]
    ldr  r0, =TIMER_BASE
    movs r1, #1
    str  r1, [r0, #0x34]         @ INTR: limpia alarma pendiente
    ldr  r1, [r0, #0x0C]         @ TIMELR (microsegundos actuales)
    ldr  r2, =FRAME_US
    adds r1, r1, r2
    str  r1, [r0, #0x10]         @ ALARM0 = ahora + periodo (arma la alarma)
    movs r1, #1
    str  r1, [r0, #0x38]         @ INTE: habilita ALARM0
    ldr  r0, =NVIC_ICPR
    str  r1, [r0]                @ limpia IRQ0 pendiente
    ldr  r0, =NVIC_ISER
    str  r1, [r0]                @ habilita IRQ0 en el NVIC
    cpsie i
    bx   lr
    .ltorg

@ timer_stop: detiene totalmente el temporizador de física (Game Over)
func timer_stop
    ldr  r0, =TIMER_BASE
    movs r1, #0
    str  r1, [r0, #0x38]         @ INTE = 0
    movs r1, #1
    str  r1, [r0, #0x34]         @ limpia INTR
    ldr  r0, =NVIC_ICER
    str  r1, [r0]                @ deshabilita IRQ0
    ldr  r0, =NVIC_ICPR
    str  r1, [r0]
    ldr  r0, =frame_flag
    movs r1, #0
    str  r1, [r0]
    bx   lr
    .ltorg

@ timer_isr: se ejecuta cada 33.333 ms. Solo usa r0-r2 (guardados por hardware)
func timer_isr
    ldr  r0, =TIMER_BASE
    movs r1, #1
    str  r1, [r0, #0x34]         @ limpia la bandera de ALARM0
    ldr  r1, [r0, #0x10]
    ldr  r2, =FRAME_US
    adds r1, r1, r2
    str  r1, [r0, #0x10]         @ re-arma: periodo exacto sin acumular deriva
    ldr  r0, =frame_flag
    movs r1, #1
    str  r1, [r0]                @ avisa al bucle principal
    bx   lr
    .ltorg
