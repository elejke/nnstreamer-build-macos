/* Copy of vlc_x86_64.S with just the vlc functions for the unit test */
	#include "asmoff.h"
.section .note.GNU-stack, "", @progbits

.text
	.align 4
.globl dv_decode_vlc
	.type	 dv_decode_vlc,@function
dv_decode_vlc:
	push %rbx
	push %rbp

	/* Args are at bits=rdi, maxbit=rsi, result=rdx */
	mov  %rdi,%rax		/* %rax is bits */
	mov  %rsi,%rbx		/* %rbx is maxbits */
	and  $0x3f,%rbx		/* limit index range STL*/
	
	/* note that BITS is left aligned */
	/* klass = dv_vlc_classes[maxbits][(bits & (dv_vlc_class_index_mask[maxbits])) >> */
	/*         (dv_vlc_class_index_rshift[maxbits])];  */
/*	xor  %rbp,%rbp */
	mov  dv_vlc_class_index_mask@GOTPCREL(%rip),%r11    /* use %rip for PIC code */
 	mov  (%r11,%rbx,4),%ebp           /* int32 */      /* dv_vlc_class_index_mask[maxbits] */
	and  %eax,%ebp                                     /* bits & */
	mov  dv_vlc_class_index_rshift@GOTPCREL(%rip),%rcx
	mov  (%rcx,%rbx,4),%ecx           /* int32 */      /* dv_vlc_class_index_rshift[maxbits] */
	sar  %cl,%ebp                                      /* >> */
	mov  dv_vlc_classes@GOTPCREL(%rip),%rcx
	mov  (%rcx,%rbx,8),%rcx           /* ptr */        /* dv_vlc_classes[maxbits], a pointer */
	movsbq  (%rcx,%rbp,1),%rbp        /* int8 */       /* klass = */

	/* *result = dv_vlc_lookups[klass][(bits & (dv_vlc_index_mask[klass])) >> */
	/*           (dv_vlc_index_rshift[klass])];   */
/*	xor  %rbx,%rbx */
	mov  dv_vlc_index_mask@GOTPCREL(%rip),%r11
	mov  (%r11,%rbp,4),%ebx          /* int32 */       /* (dv_vlc_index_mask[klass]) */
/*	xor  %rcx,%rcx */
	mov  dv_vlc_index_rshift@GOTPCREL(%rip),%r11
	mov  (%r11,%rbp,4),%ecx          /* int32 */       /* dv_vlc_index_rshift[klass] */
	and  %eax,%ebx                                     /* bits &  */
	sar  %cl,%ebx                                      /* >> */

	mov  dv_vlc_lookups@GOTPCREL(%rip),%r11
	mov  (%r11,%rbp,8),%rbp          /* ptr */         /* dv_vlc_lookups[klass] */
	mov  (%rbp,%rbx,4),%ebp          /* int32 */       /* *result = */

	/* Now %ebp holds result, a dv_vlc_t, like this:
	   bits 0-7   run
	   bits 8-15  len
	   bits 16-31 amp
	*/
	/* code needs to do this with result:
	   if ((result->lamp > 0) &&
	     if (bits & sign_mask[result->len])
	         result->lamp = -result->lamp;
	   }
	*/

	/* Form a mask from (bits & sign_mask[result->len]) */
	mov  %ebp,%ecx
	sar  $8,%ecx
	and  $0xff,%ecx                /* result->len */
	mov  sign_mask@GOTPCREL(%rip),%rbx
	mov  (%rbx,%rcx,4),%ebx        /* int32 */
	and  %ebx,%eax
	neg  %eax
	sar  $31,%eax

	mov  %ebp,%ebx
	sar  $31,%ebx                  /* result->amp */
	xor  $0xffffffff,%ebx
	and  $0xffff0000,%ebx

	and  %rbx,%rax

	/* Now %eax is 0xffff0000 if we want to negate %ebp, zero otherwise */
	xor  %eax,%ebp
	sub  %eax,%ebp

	/*
	if (maxbits < result->len)
	    *result = broken;
	Note that the 'broken' pattern is all ones (i.e. 0xffffffff)
	*/
	mov  %esi,%ebx		/* maxbits */ /* int32 */
	sub  %ecx,%ebx
	sbb  %ebx,%ebx
	or   %ebx,%ebp

	mov  %ebp,(%rdx)        /* *result = */

	pop  %rbp
	pop  %rbx

	ret

/*
void __dv_decode_vlc(int bits, dv_vlc_t *result)
*/
	
.text
	.align 4
.globl __dv_decode_vlc
	.type	 __dv_decode_vlc,@function
__dv_decode_vlc:
	push %rbx
	push %rbp

	/* Args are bits=rdi, result=rsi  */
	mov  %rdi,%rax			/* %rax is bits */
	
	mov  %rax,%rbp
	and  $0xfe00,%ebp
	sar  $9,%ebp
	mov  dv_vlc_class_lookup5@GOTPCREL(%rip),%r11
	movsbq  (%r11,%rbp),%rbp        /* int8 klass */

	mov  dv_vlc_index_mask@GOTPCREL(%rip),%rbx
	mov  (%rbx,%rbp,4),%ebx         /* int32 */
	mov  dv_vlc_index_rshift@GOTPCREL(%rip),%rcx
	mov  (%rcx,%rbp,4),%ecx         /* int32 */
	and  %eax,%ebx
	sar  %cl,%ebx			/* %rbx is klass */

	mov  dv_vlc_lookups@GOTPCREL(%rip),%r11
	mov  (%r11,%rbp,8),%rbp         /* ptr */
	mov  (%rbp,%rbx,4),%ebp         /* int32 */

	/* Now %ebp holds result, like this:
	   bits 0-7   run
	   bits 8-15  len
	   bits 16-31 amp
	*/
	/* code needs to do this with result:
	   if ((result->amp > 0) &&
	     if ((bits >> sign_rshift[result->len]) & 1)
	         result->amp = result->-amp;
	   }
	*/
	/* if (result->amp < 0) %rbp is 0, else 0xffff0000. */
	mov  %ebp,%ecx
	sar  $8,%ecx
	and  $0xff,%ecx
	mov  sign_mask@GOTPCREL(%rip),%r11
	mov  (%r11,%rcx,4),%ecx        /* int32 */
	and  %ecx,%eax
	neg  %eax
	sar  $31,%eax

	mov  %ebp,%ebx
	sar  $31,%ebx
	xor  $0xffffffff,%ebx
	and  $0xffff0000,%ebx

	and  %ebx,%eax
	
	xor  %eax,%ebp
	sub  %eax,%ebp

	mov  %ebp,(%rsi)       /* *result = */

	pop  %rbp
	pop  %rbx
	
	ret
