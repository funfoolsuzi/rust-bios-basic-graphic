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
/*    // enable a20
_enable_a20:
    inb $0x92, %al
    testb $2, %al
    jnz _enable_a20_end
    orb $2, %al
    andb $0xFE, %al
    outb %al, $0x92
_enable_a20_end:*/
    // set up stack
    movw $0x7c00, %sp
    movw %sp, %bp

    movl $0xe820, %eax
    movl $0, %ebx
    movl $40, %ecx
    movl $0x534D4150, %edx
    leal smap, %edi

    int $0x15
    jc _fail
    leaw smap, %si
    movw 10(%si), %dx
    movw 8(%si), %ax
    callw _print_int_on_stack
    jmp _halt

.lcomm smap, 40

/*
_print_int_on_stack:
params: 
%dx:%ax: number to print
*/
.lcomm print_buffer, 20

_print_int_on_stack:
    pushw %bx // divisor
    pushw %cx // counter
    pushw %di
    pushw %si
    movw $0, %cx
    _print_int_on_stack_load_remainder_loop:
    movw $0xa, %bx // set divisor to 10
    divw %bx
    addw $0x30, %dx
    leaw print_buffer, %bx // load buffer base
    movw %cx, %di // load buffer index from %cx to %di
    movb %dl, (%bx, %di, 1)
    incw %cx
    cmpw $19, %cx // make sure counter(%cx) is not reaching 20 limit
    je _print_int_on_stack_finish
    movw %ax, %dx
    or %dx, %dx // make sure quotient is not zero
    movw $0, %dx
    jne _print_int_on_stack_load_remainder_loop
    _print_int_on_stack_finish:
    leaw (%bx, %di, 1), %si
    std
    movb $0xe, %ah
    _print_single_digit:
    lodsb
    or %al, %al
    jz _print_int_on_stack_cleanup
    int $0x10
    jmp _print_single_digit
    _print_int_on_stack_cleanup:
    cld
    popw %si
    popw %di
    popw %cx
    popw %bx
    retw

_fail:
    movb $0xe, %ah
    movb $0x46, %al
    int $0x10
    jmp _halt

_break:
    pushw %ax
    movb $0xe, %ah
    movb $0x42, %al
    int $0x10
    popw %ax
    retw

_halt:
    hlt

.= 510
.2byte 0xaa55