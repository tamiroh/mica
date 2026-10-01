ENTRY(_start)

MEMORY {
    /* Leave the start of RAM available for QEMU's device tree. */
    ram (rwx) : ORIGIN = 0x40080000, LENGTH = 128M - 512K
}

SECTIONS {
    .text : {
        KEEP(*(.text.boot))
        *(.text .text.*)
    } > ram
    .rodata : { *(.rodata .rodata.*) } > ram
    .data : { *(.data .data.*) } > ram
    .bss (NOLOAD) : ALIGN(8) {
        __bss_start = .;
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(8);
        __bss_end = .;
    } > ram
    .stack (NOLOAD) : ALIGN(16) {
        . += 64K;
        __stack_top = .;
    } > ram
}
