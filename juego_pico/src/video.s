@ ============================================================================
@ video.s - OLED SSD1306 128x64 por I2C0 (GP4=SDA, GP5=SCL) + framebuffer
@ Framebuffer: 1024 bytes en RAM, formato de páginas (8 pixeles verticales por
@ byte, bit0 = fila superior). Se agregan 128 bytes "fantasma" al final para
@ que un sprite en la última página pueda desbordar sin corromper memoria.
@ ============================================================================
.include "defs.inc"

.section .bss
.align 2
.global framebuffer
framebuffer: .space 1024 + 128

.section .rodata
oled_init_seq:
    .byte 0xAE                  @ display OFF
    .byte 0xD5, 0x80            @ reloj
    .byte 0xA8, 0x3F            @ multiplex 64 filas
    .byte 0xD3, 0x00            @ offset 0
    .byte 0x40                  @ start line 0
    .byte 0x8D, 0x14            @ charge pump ON
    .byte 0x20, 0x00            @ direccionamiento horizontal
    .byte 0xA1                  @ segment remap
    .byte 0xC8                  @ COM scan invertido
    .byte 0xDA, 0x12            @ configuración de pines COM
    .byte 0x81, 0xCF            @ contraste
    .byte 0xD9, 0xF1            @ pre-carga
    .byte 0xDB, 0x40            @ nivel VCOMH
    .byte 0xA4                  @ muestra RAM
    .byte 0xA6                  @ normal (no invertido)
    .byte 0xAF                  @ display ON
.equ OLED_INIT_LEN, . - oled_init_seq
oled_window_seq:
    .byte 0x21, 0x00, 0x7F      @ columnas 0..127
    .byte 0x22, 0x00, 0x07      @ páginas 0..7

.text

@ i2c_init: pines GP4/GP5 como I2C0, 400 kHz, maestro, dirección 0x3C
func i2c_init
    ldr  r0, =IO_BANK0_BASE
    movs r1, #3                  @ FUNCSEL = I2C
    str  r1, [r0, #0x24]         @ GPIO4_CTRL
    str  r1, [r0, #0x2C]         @ GPIO5_CTRL
    ldr  r0, =PADS_BANK0_BASE
    movs r1, #0x5A               @ IE + pull-up
    str  r1, [r0, #0x14]         @ PADS GPIO4
    str  r1, [r0, #0x18]         @ PADS GPIO5
    ldr  r0, =I2C0_BASE
    movs r1, #0
    str  r1, [r0, #0x6C]         @ IC_ENABLE = 0 (necesario para configurar)
    ldr  r1, =0x165              @ maestro | fast | restart_en | slave_disable
    str  r1, [r0, #0x00]         @ IC_CON
    movs r1, #OLED_ADDR
    str  r1, [r0, #0x04]         @ IC_TAR
    movs r1, #12
    str  r1, [r0, #0x1C]         @ IC_FS_SCL_HCNT  (12 + 18 ciclos = 400 kHz)
    movs r1, #18
    str  r1, [r0, #0x20]         @ IC_FS_SCL_LCNT
    movs r1, #1
    ldr  r2, =(I2C0_BASE + 0xA0)
    str  r1, [r2]                @ IC_FS_SPKLEN
    movs r1, #4
    str  r1, [r0, #0x7C]         @ IC_SDA_HOLD
    movs r1, #1
    str  r1, [r0, #0x6C]         @ IC_ENABLE = 1
    bx   lr
    .ltorg

@ i2c_write: r0 = byte (bit 9 = STOP)  ->  r0 = 0 ok, 1 si hubo abort (NACK)
func i2c_write
    ldr  r1, =I2C0_BASE
1:  ldr  r2, [r1, #0x34]     @ IC_RAW_INTR_STAT
    movs r3, #0x40           @ TX_ABRT
    tst  r2, r3
    bne  2f
    ldr  r2, [r1, #0x70]     @ IC_STATUS
    movs r3, #2              @ TFNF: FIFO de TX con espacio
    tst  r2, r3
    beq  1b
    str  r0, [r1, #0x10]     @ IC_DATA_CMD
    movs r0, #0
    bx   lr
2:  ldr  r2, [r1, #0x54]     @ IC_CLR_TX_ABRT (lectura limpia el abort)
    movs r0, #1
    bx   lr
    .ltorg

@ oled_cmds: r0 = puntero a comandos, r1 = cantidad -> r0 = 0 ok
func oled_cmds
    push {r4-r6, lr}
    movs r4, r0
    movs r5, r1
    ldr  r6, =(I2C0_BASE + 0x54)
    ldr  r0, [r6]                @ limpia abort previo
    movs r0, #0                  @ byte de control: Co=0, D/C#=0 (comandos)
    bl   i2c_write
    cmp  r0, #0
    bne  3f
1:  ldrb r0, [r4]
    adds r4, r4, #1
    subs r5, r5, #1
    bne  2f
    movs r1, #1
    lsls r1, r1, #9
    orrs r0, r0, r1              @ STOP en el último byte
2:  bl   i2c_write
    cmp  r0, #0
    bne  3f
    cmp  r5, #0
    bne  1b
3:  pop  {r4-r6, pc}
    .ltorg

func oled_init
    push {lr}
    ldr  r0, =oled_init_seq
    movs r1, #OLED_INIT_LEN
    bl   oled_cmds
    pop  {pc}
    .ltorg

@ oled_flush: envía los 1024 bytes del framebuffer en una sola transacción I2C
@ (1033 bytes * 9 bits / 400 kHz ~= 24 ms < 33.3 ms de periodo)
func oled_flush
    push {r4-r6, lr}
    ldr  r0, =oled_window_seq
    movs r1, #6
    bl   oled_cmds
    cmp  r0, #0
    bne  3f
    movs r0, #0x40               @ byte de control: D/C#=1 (datos)
    bl   i2c_write
    cmp  r0, #0
    bne  3f
    ldr  r4, =framebuffer
    movs r5, #1
    lsls r5, r5, #10             @ 1024
1:  ldrb r0, [r4]
    adds r4, r4, #1
    subs r5, r5, #1
    bne  2f
    movs r1, #1
    lsls r1, r1, #9
    orrs r0, r0, r1              @ STOP al final
2:  bl   i2c_write
    cmp  r0, #0
    bne  3f
    cmp  r5, #0
    bne  1b
3:  pop  {r4-r6, pc}
    .ltorg

@ fb_clear: borra el framebuffer
func fb_clear
    ldr  r0, =framebuffer
    ldr  r2, =(framebuffer + 1024)
    movs r1, #0
1:  str  r1, [r0]
    adds r0, r0, #4
    cmp  r0, r2
    bne  1b
    bx   lr
    .ltorg

@ fb_draw_sprite: r0 = x, r1 = y, r2 = puntero a sprite 8x8 (8 bytes, 1 por columna)
func fb_draw_sprite
    push {r4-r7, lr}
    cmp  r1, #64
    bhs  9f                      @ fuera de pantalla (sin signo cubre y < 0)
    lsrs r3, r1, #3              @ página
    lsls r3, r3, #7              @ * 128
    adds r3, r3, r0              @ + x
    ldr  r0, =framebuffer
    adds r3, r3, r0              @ r3 = destino (columna 0, página p)
    movs r4, #7
    ands r4, r4, r1              @ r4 = desplazamiento dentro de la página
    movs r5, #8
    subs r5, r5, r4              @ r5 = 8 - desplazamiento
    movs r6, #8                  @ 8 columnas
1:  ldrb r0, [r2]
    adds r2, r2, #1
    movs r1, r0
    lsls r0, r0, r4              @ parte que cae en la página p
    lsrs r1, r1, r5              @ parte que cae en la página p+1
    ldrb r7, [r3]
    orrs r7, r7, r0
    strb r7, [r3]
    adds r3, r3, #128
    ldrb r7, [r3]
    orrs r7, r7, r1
    strb r7, [r3]
    subs r3, r3, #127            @ -128 (volver a p) + 1 (siguiente columna)
    subs r6, r6, #1
    bne  1b
9:  pop  {r4-r7, pc}
    .ltorg

@ fb_draw_char: r0 = x, r1 = página (0..7), r2 = carácter ASCII (32..90)
func fb_draw_char
    push {r4, r5}
    subs r2, r2, #32
    cmp  r2, #58
    bhi  9f
    lsls r3, r2, #2
    adds r2, r2, r3              @ índice * 5
    ldr  r3, =font5x7
    adds r2, r2, r3              @ r2 -> glifo
    lsls r1, r1, #7
    adds r1, r1, r0
    ldr  r3, =framebuffer
    adds r1, r1, r3              @ r1 -> destino
    movs r4, #5
1:  ldrb r3, [r2]
    adds r2, r2, #1
    ldrb r5, [r1]
    orrs r5, r5, r3
    strb r5, [r1]
    adds r1, r1, #1
    subs r4, r4, #1
    bne  1b
9:  pop  {r4, r5}
    bx   lr
    .ltorg

@ fb_draw_text: r0 = x, r1 = página, r2 = cadena terminada en 0
func fb_draw_text
    push {r4-r6, lr}
    movs r4, r0
    movs r5, r1
    movs r6, r2
1:  ldrb r2, [r6]
    cmp  r2, #0
    beq  9f
    movs r0, r4
    movs r1, r5
    bl   fb_draw_char
    adds r4, r4, #6
    adds r6, r6, #1
    b    1b
9:  pop  {r4-r6, pc}

@ fb_draw_number3: r0 = x, r1 = página, r2 = valor (0..999), 3 dígitos
func fb_draw_number3
    push {r4-r7, lr}
    movs r4, r0
    movs r5, r1
    movs r6, r2
    ldr  r0, =999
    cmp  r6, r0
    bls  1f
    movs r6, r0
1:  movs r7, #100
    bl   num_digit
    movs r7, #10
    bl   num_digit
    movs r7, #1
    bl   num_digit
    pop  {r4-r7, pc}
    .ltorg

@ fb_draw_number4: r0 = x, r1 = página, r2 = valor (0..9999), 4 dígitos
func fb_draw_number4
    push {r4-r7, lr}
    movs r4, r0
    movs r5, r1
    movs r6, r2
    ldr  r7, =1000
    bl   num_digit
    movs r7, #100
    bl   num_digit
    movs r7, #10
    bl   num_digit
    movs r7, #1
    bl   num_digit
    pop  {r4-r7, pc}
    .ltorg

@ num_digit (interna): r4 = x, r5 = página, r6 = resto, r7 = divisor
@ No hay instrucción DIV en Cortex-M0+: se divide por restas sucesivas.
.thumb_func
num_digit:
    push {lr}
    movs r2, #48                 @ '0'
1:  cmp  r6, r7
    blo  2f
    subs r6, r6, r7
    adds r2, r2, #1
    b    1b
2:  movs r0, r4
    movs r1, r5
    bl   fb_draw_char
    adds r4, r4, #6
    pop  {pc}
