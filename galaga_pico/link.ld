/* link.ld - la imagen se carga en SRAM; la tabla de vectores va en 0x20000000 */
ENTRY(reset_handler)
MEMORY { RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 264K }
SECTIONS
{
    .text : {
        KEEP(*(.vectors))
        *(.text*)
        . = ALIGN(4);
        *(.rodata*)
        . = ALIGN(4);
    } > RAM
    .bss (NOLOAD) : {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > RAM
    /DISCARD/ : { *(.ARM.exidx*) *(.comment) *(.ARM.attributes) }
}
