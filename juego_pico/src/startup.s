@ ============================================================================
@ startup.s - Tabla de vectores, arranque, reloj y reset de periféricos
@ El binario se carga en SRAM (0x20000000) vía UF2; la ROM lee SP y PC de la
@ tabla de vectores ubicada al inicio de la RAM.
@ ============================================================================
.include "defs.inc"

.section .vectors, "a"
.align 8
.global vector_table
vector_table:
    .word STACK_TOP              @  0 SP inicial
    .word reset_handler          @  1 Reset
    .word default_handler        @  2 NMI
    .word default_handler        @  3 HardFault
    .rept 7
    .word 0                      @  4..10 reservados
    .endr
    .word default_handler        @ 11 SVCall
    .word 0                      @ 12
    .word 0                      @ 13
    .word default_handler        @ 14 PendSV
    .word default_handler        @ 15 SysTick
    .word timer_isr              @ 16 IRQ0 = TIMER_IRQ_0 (ALARM0)
    .rept 31
    .word default_handler        @ 17..47 resto de IRQ
    .endr

.text

@ ---------------------------------------------------------------------------
@ reset_handler: limpia .bss, fija VTOR, configura reloj y desbloquea periféricos
@ ---------------------------------------------------------------------------
func reset_handler
    ldr  r0, =__bss_start
    ldr  r1, =__bss_end
    movs r2, #0
1:  cmp  r0, r1
    bhs  2f
    str  r2, [r0]
    adds r0, r0, #4
    b    1b
2:  ldr  r0, =SCB_VTOR
    ldr  r1, =vector_table
    str  r1, [r0]
    bl   clocks_init
    bl   resets_init
    bl   main                    @ no retorna
3:  b    3b
    .ltorg

func default_handler
    b    default_handler

@ ---------------------------------------------------------------------------
@ clocks_init: XOSC 12 MHz -> clk_ref -> clk_sys; clk_adc desde XOSC;
@              tick de 1 us (watchdog) para el TIMER
@ ---------------------------------------------------------------------------
func clocks_init
    ldr  r0, =XOSC_BASE
    movs r1, #47
    str  r1, [r0, #0x0C]         @ XOSC_STARTUP
    ldr  r1, =0x00FABAA0         @ ENABLE (0xFAB) | FREQ_RANGE 1-15 MHz (0xAA0)
    str  r1, [r0, #0x00]         @ XOSC_CTRL
1:  ldr  r1, [r0, #0x04]         @ XOSC_STATUS
    cmp  r1, #0                  @ bit 31 STABLE => valor negativo
    bge  1b

    ldr  r0, =CLOCKS_BASE
    movs r1, #2                  @ clk_ref <- XOSC
    str  r1, [r0, #0x30]         @ CLK_REF_CTRL
2:  ldr  r1, [r0, #0x38]         @ CLK_REF_SELECTED
    cmp  r1, #4
    bne  2b
    movs r1, #0                  @ clk_sys <- clk_ref
    str  r1, [r0, #0x3C]         @ CLK_SYS_CTRL
3:  ldr  r1, [r0, #0x44]         @ CLK_SYS_SELECTED
    cmp  r1, #1
    bne  3b
    ldr  r1, =0x00000860         @ clk_adc: ENABLE (bit 11) | AUXSRC = XOSC (3<<5)
    str  r1, [r0, #0x60]         @ CLK_ADC_CTRL

    ldr  r0, =WATCHDOG_TICK
    ldr  r1, =0x0000020C         @ ENABLE (bit 9) | 12 ciclos = 1 us @ 12 MHz
    str  r1, [r0]
    bx   lr
    .ltorg

@ ---------------------------------------------------------------------------
@ resets_init: saca de reset ADC, I2C0, IO_BANK0, PADS_BANK0 y TIMER
@ ---------------------------------------------------------------------------
func resets_init
    ldr  r0, =RESETS_CLR
    ldr  r1, =RESET_MASK
    str  r1, [r0]
    ldr  r0, =RESETS_BASE
1:  ldr  r2, [r0, #0x08]         @ RESET_DONE
    ands r2, r2, r1
    cmp  r2, r1
    bne  1b
    bx   lr
    .ltorg
