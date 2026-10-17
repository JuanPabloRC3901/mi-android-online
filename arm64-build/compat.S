/* MIT. Prueba real ARM32 EABI de memfd y compat_ioctl ashmem. */
.syntax unified
.arm
.global _start
.section .text
_start:
 ldr r0,=name
 mov r1,#3
 ldr r7,=385
 svc #0
 cmp r0,#0
 blt failed
 mov r4,r0
 mov r1,#4096
 mov r7,#93
 svc #0
 cmp r0,#0
 bne failed
 mov r0,r4
 ldr r1,=0x7704
 mov r2,#0
 mov r7,#54
 svc #0
 cmp r0,#4096
 bne failed
 mov r0,r4
 ldr r1,=0x40047705
 mov r2,#5
 mov r7,#54
 svc #0
 cmp r0,#0
 bne failed
 mov r0,r4
 ldr r1,=0x7706
 mov r2,#0
 mov r7,#54
 svc #0
 cmp r0,#5
 bne failed
 mov r0,#1
 ldr r1,=message
 ldr r2,=message_end-message
 mov r7,#4
 svc #0
 mov r0,#0
 mov r7,#1
 svc #0
failed:
 mov r0,#1
 mov r7,#1
 svc #0
.section .rodata
name: .asciz "miao-arm32"
message: .ascii "MIAO_ARM|ARM32_EXECUTED\nMIAO_ARM|ARM32_ASHMEM_COMPAT_VERIFIED\n"
message_end:
.section .note.GNU-stack,"",%progbits
