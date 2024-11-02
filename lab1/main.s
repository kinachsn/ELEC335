/*
 * asm.s
 *
 * author: Hüseyin Safa Ünlü
 *
 * description: This assembly code is for turning on and off the LED on
 *   the STM32F103C8T6 Nucleo board (connected to PC13).
 */

.syntax unified
.cpu cortex-m3
.thumb

/* make linker see this */
.global Reset_Handler

/* get these from linker script */
.word _sdata
.word _edata
.word _sbss
.word _ebss

/* define peripheral addresses */
.equ RCC_BASE,         (0x40021000)          // RCC base address
.equ RCC_APB2ENR,      (RCC_BASE   + (0x18)) // RCC APB2ENR register offset

.equ GPIOC_BASE,       (0x40011000)          // GPIOC base address
.equ GPIOC_CRH,        (GPIOC_BASE + (0x04)) // GPIOC CRH register offset
.equ GPIOC_ODR,        (GPIOC_BASE + (0x0C)) // GPIOC ODR register offset

/* vector table */
.section .vectors
vector_table:
    .word _estack             /* Stack pointer */
    .word Reset_Handler +1    /* Reset handler */
    .word Default_Handler +1  /* NMI handler */
    .word Default_Handler +1  /* HardFault handler */

/* reset handler */
.section .text
Reset_Handler:
    /* set stack pointer */
    ldr r0, =_estack
    mov sp, r0

    /* initialize data and bss */
    bl init_data

    /* call main */
    bl main

    /* trap if returned */
    b .

/* initialize data and bss sections */
.section .text
init_data:
    /* copy rom to ram */
    ldr r0, =_sdata
    ldr r1, =_edata
    ldr r2, =_sidata
    movs r3, #0
    b LoopCopyDataInit

CopyDataInit:
    ldr r4, [r2, r3]
    str r4, [r0, r3]
    adds r3, r3, #4

LoopCopyDataInit:
    adds r4, r0, r3
    cmp r4, r1
    bcc CopyDataInit

    /* zero bss */
    ldr r2, =_sbss
    ldr r4, =_ebss
    movs r3, #0
    b LoopFillZerobss

FillZerobss:
    str  r3, [r2]
    adds r2, r2, #4

LoopFillZerobss:
    cmp r2, r4
    bcc FillZerobss

    bx lr

/* default handler */
.section .text
Default_Handler:
    b Default_Handler

/* main function */
.section .text
main:
    /* enable GPIOC clock, bit4 on APB2ENR */
    ldr r6, =RCC_APB2ENR
    ldr r5, [r6]
    movs r4, #0x10      /* Enable bit for GPIOC (IOPCEN) */
    orrs r5, r5, r4
    str r5, [r6]

    /* setup PC13 for output mode (push-pull) in CRH */
    ldr r6, =GPIOC_CRH
    ldr r5, [r6]
    bics r5, r5, #(0xF << 20)  /* Clear bits for PC13 */
    orrs r5, r5, #(0x1 << 20)  /* Output mode, max speed 10 MHz */
    str r5, [r6]

loop:
    /* turn on LED connected to PC13 */
    ldr r6, =GPIOC_ODR
    ldr r5, [r6]
    movs r4, #0x2000      /* Set PC13 */
    bics r5, r5, r4       /* Clear bit to turn LED ON (active low) */
    str r5, [r6]

    /* delay */
    bl delay

    /* turn off LED connected to PC13 */
    ldr r6, =GPIOC_ODR
    ldr r5, [r6]
    movs r4, #0x2000      /* Set PC13 */
    orrs r5, r5, r4       /* Set bit to turn LED OFF (active low) */
    str r5, [r6]

    /* delay */
    bl delay

    /* repeat the loop */
    b loop

/* delay function */
.section .text
delay:
    ldr r0, =0x3FFFF   /* Load the large constant into r0 */
delay_loop:
    subs r0, r0, #1    /* Decrement counter */
    bne delay_loop     /* Loop until counter reaches 0 */
    bx lr              /* Return from delay function */
