@ ============================================================================
@ defs.inc - Constantes del RP2040 (direcciones base y offsets de registros)
@ Todo el acceso a hardware se hace por direcciones de memoria (sin SDK).
@ ============================================================================
.syntax unified
.cpu cortex-m0plus
.thumb

@ --- Macro para declarar funciones (símbolo global, modo Thumb) -------------
.macro func name
    .global \name
    .thumb_func
    .type \name, %function
\name:
.endm

@ --- Memoria -----------------------------------------------------------------
.equ STACK_TOP,       0x20042000      @ tope de los 264 KB de SRAM

@ --- Bloques de periféricos ----------------------------------------------------
.equ SIO_BASE,        0xD0000000      @ GPIO_IN en +0x04
.equ RESETS_BASE,     0x4000C000      @ RESET +0x0, RESET_DONE +0x8
.equ RESETS_CLR,      0x4000F000      @ alias atómico "clear" de RESETS
.equ CLOCKS_BASE,     0x40008000
.equ XOSC_BASE,       0x40024000
.equ WATCHDOG_TICK,   0x4005802C      @ genera el tick de 1 us para el TIMER
.equ TIMER_BASE,      0x40054000
.equ IO_BANK0_BASE,   0x40014000
.equ PADS_BANK0_BASE, 0x4001C000
.equ I2C0_BASE,       0x40044000
.equ ADC_BASE,        0x4004C000

@ --- Cortex-M0+ (NVIC / SCB) ---------------------------------------------------
.equ NVIC_ISER,       0xE000E100
.equ NVIC_ICER,       0xE000E180
.equ NVIC_ICPR,       0xE000E280
.equ SCB_VTOR,        0xE000ED08

@ --- Bits de RESETS: ADC(0) I2C0(3) IO_BANK0(5) PADS_BANK0(8) TIMER(21) -------
.equ RESET_MASK,      0x00200129

@ --- Parámetros del sistema -----------------------------------------------------
.equ FRAME_US,        33333           @ periodo del timer: 30 FPS
.equ OLED_ADDR,       0x3C            @ dirección I2C del SSD1306
.equ INV_FRAMES,      45              @ frames de invulnerabilidad tras choque
.equ INVERT_X,        0               @ pon 1 si el joystick mueve al revés
.equ INVERT_Y,        0

@ --- Estados de la máquina de estados ---------------------------------------------
.equ ST_MENU,         0
.equ ST_PLAY,         1
.equ ST_OVER,         2

@ --- Offsets de la estructura game_vars (en bytes) --------------------------------
.equ G_PX,            0
.equ G_PY,            4
.equ G_LIVES,         8
.equ G_SCORE,         12
.equ G_INV,           16
.equ G_RNG,           20
.equ G_EX,            24              @ x de 4 enemigos (24..39)
.equ G_EY,            40              @ y de 4 enemigos (40..55)
.equ G_EV,            56              @ velocidad de 4 enemigos (56..71)
