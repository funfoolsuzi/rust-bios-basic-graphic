.section .boot, "awx"
.code16

stage2_msg: .asciz "stage 2 now"


stage2:
    lea stage2_msg, %si
    call real_mode_print
