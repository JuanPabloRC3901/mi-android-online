/* MIT. Proceso ARM de 32 bits para comprobar compatibilidad EL0 real. */
.syntax unified
.arm
.global _start
.type _start,%function
_start:
 mov r0,#1
 ldr r1,=message
 mov r2,#message_end-message
 mov r7,#4
 svc #0
 mov r0,#0
 mov r7,#1
 svc #0
message:
 .ascii "MIAO_ARM|ARM32_EXECUTED\n"
message_end:

.section .note.GNU-stack,"",%progbits
