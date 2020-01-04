.section .boot-first-stage, "awx"
.globl _start
.code16

_start:
    // clear segment regiesters
    xorw %ax, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss
    movw %ax, %fs
    movw %ax, %gs
    cld

enable_a20:
    inb $0x92, %al
    testb $2, %al
    jnz ea_end
    orb $2, %al
    andb $0xFE, %al
    outb %al, $0x92
ea_end:

setup_stack:
    movw $0x7c00, %sp
    movw %sp, %bp

enable_protected_mode:
    cli
    push %ds
    push %es
    lgdt gdt32

    movl %cr0, %eax 
    orb $1, %al // cr0 bit 0 => PE
    movl %eax, %cr0

during_protected_mode:
    movw $0x10, %bx // 0b00001000 for segment selector; least significant 3 bits are RPL and TI
    movw %bx, %ds
    movw %bx, %es

enter_unreal_mode:
    andl $0xfe, %eax
    movl %eax, %cr0
    pop %es
    pop %ds
    sti

check_13h_extensions:
    movb $0x41, %ah
    movw $0x55aa, %bx
    int $0x13
    jc no_in13h_extensions

load_rest:
    leal _rest_of_bootloader_start_addr, %eax

    movw %ax, dap_buffer_offset

    leal _rest_of_bootloader_end_addr, %ebx
    subl %eax, %ebx
    shrl $9, %ebx
    movw %bx, dap_num_blocks

    leal _start, %ebx
    subl %ebx, %eax
    shrl $9, %eax
    movl %eax, dap_start_lba

    lea dap, %si
    movb $0x42, %ah
    int $0x13
    jc rest_of_bootloader_load_failed

jump_to_2nd_stage:
    lea stage2, %eax
    jmpl *%eax
    
// functions

/*
PARAM %al
CLOBBER %ah
*/
real_mode_print_char:
    movb $0xe, %ah
    int $0x10
    ret

/*
PARAM %al
CLOBBER %ah
*/
real_mode_print_hex_char:
    pushw %ax
    shrb $4, %al
    call real_mode_print_hex_oct
    popw %ax
    call real_mode_print_hex_oct
    movw $' ', %ax
    call real_mode_print_char
    ret

real_mode_print_hex_oct:
    andb $0xf, %al
    cmpb $0xa, %al
    js _rmpho_below_a
    addb $0x37, %al
    call real_mode_print_char
    jmp _rmpho_end
    _rmpho_below_a:
    addb $0x30, %al
    call real_mode_print_char 
    _rmpho_end:
    ret


/*
PARAM %si
CLOBBER %ax
*/
real_mode_print:
    cld
    _rmp_loop:
    lodsb
    testb %al, %al
    jz _rmp_end
    call real_mode_print_char
    call _rmp_loop
    _rmp_end:
    ret

/*
PARAM %si, %cx
CLOBBER %ax
*/
real_mode_print_hex:
    cld
rmph_loop:
    lodsb
    testw %cx, %cx
    jz rmph_end
    call real_mode_print_hex_char
    decw %cx
    call rmph_loop
rmph_end:
    ret

spin:
    jmp spin

real_mode_error:
    call real_mode_print
    jmp spin

no_in13h_extensions:
    lea no_int13h_extensions_str, %si
    call real_mode_error

rest_of_bootloader_load_failed:
    lea rest_of_bootloader_load_failed_str, %si
    call real_mode_error

// data

no_int13h_extensions_str: .asciz "No support for int13h extensions"
rest_of_bootloader_load_failed_str: .asciz "Failed to load rest of bootloader"

gdt32:
    .quad // first entry always empty
code_desc:
    .byte 0xff
    .byte 0xff // 0,1,6[4:7] segment limit set to max
    .byte 0
    .byte 0
    .byte 0
    .byte 0x9a // 5 0b10011010 bit 4 set => code segment
    .byte 0xcf // 6 0b11001111
    .byte 0 // 2,3,4,7 segment base set to beginning
data_desc:
    .byte 0xff
    .byte 0xff
    .byte 0
    .byte 0
    .byte 0
    .byte 0x92 // 5 0b10010010 bit 4 cleared => data segment
    .byte 0xcf
    .byte 0

dap: // disk access packet
    .byte 0x10 // size of this dap(16 bytes)
    .byte 0
dap_num_blocks:
    .2byte 0 // # of sectors
dap_buffer_offset:
    .2byte 0 // offset of memory buffer
    .2byte 0 // segment of memory buffer
dap_start_lba:
    .8byte 0 // start lba(logical block address)

.= 510
.2byte 0xaa55

