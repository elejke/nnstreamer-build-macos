/* Copy of vlc_x86.S with just the vlc functions for the unit test */
	#include "asmoff.h"
.section .note.GNU-stack, "", @progbits

.text
	.align 4
.globl dv_decode_vlc 
	.type	 dv_decode_vlc,@function
dv_decode_vlc:
	pushl %ebx

	/* Args are at 8(%esp). */
	movl  8(%esp),%eax		/* %eax is bits */
	movl  12(%esp),%ebx		/* %ebx is maxbits */
	andl  $0x3f,%ebx		/* limit index range STL*/

	movl  dv_vlc_class_index_mask(,%ebx,4),%edx
	andl  %eax,%edx
	movl  dv_vlc_class_index_rshift(,%ebx,4),%ecx
	sarl  %cl,%edx
	movl  dv_vlc_classes(,%ebx,4),%ecx
	movsbl  (%ecx,%edx,1),%edx	/* %edx is class */
			
	movl  dv_vlc_index_mask(,%edx,4),%ebx
	movl  dv_vlc_index_rshift(,%edx,4),%ecx
	andl  %eax,%ebx
	sarl  %cl,%ebx

	movl  dv_vlc_lookups(,%edx,4),%edx
	movl  (%edx,%ebx,4),%edx

	/* Now %edx holds result, like this:
	   bits 0-7   run
	   bits 8-15  len
	   bits 16-31 amp
	*/
	/* code needs to do this with result:
	   if ((amp > 0) &&
	     if (bits & sign_mask[result->len])
	         amp = -amp;
	   }
	*/

	/* Form a mask from (bits & sign_mask[result->len]) */
	movl  %edx,%ecx
	sarl  $8,%ecx
	andl  $0xff,%ecx
	movl  sign_mask(,%ecx,4),%ebx
	andl  %ebx,%eax
	negl  %eax
	sarl  $31,%eax

	movl  %edx,%ebx
	sarl  $31,%ebx
	xorl  $0xffffffff,%ebx
	andl  $0xffff0000,%ebx

	andl  %ebx,%eax

	/* Now %eax is 0xffff0000 if we want to negate %edx, zero otherwise */
	xorl  %eax,%edx
	subl  %eax,%edx

	/*
	if (maxbits < result->len)
	    *result = broken;
	Note that the 'broken' pattern is all ones (i.e. 0xffffffff)
	*/
	movl  12(%esp),%ebx		/* %ebx is maxbits */
	subl  %ecx,%ebx
	sbbl  %ebx,%ebx
	orl   %ebx,%edx

	movl  16(%esp),%eax
	movl  %edx,(%eax)
	
	popl  %ebx
	ret
	
.text
	.align 4
.globl __dv_decode_vlc 
	.type	 __dv_decode_vlc,@function
__dv_decode_vlc:
	pushl %ebx

	/* Args are at 8(%esp). */
	movl  8(%esp),%eax		/* %eax is bits */
	
	movl  %eax,%edx			/* %edx is class */
	andl  $0xfe00,%edx
	sarl  $9,%edx
	movsbl dv_vlc_class_lookup5(%edx),%edx
	
	movl  dv_vlc_index_mask(,%edx,4),%ebx
	movl  dv_vlc_index_rshift(,%edx,4),%ecx
	andl  %eax,%ebx
	sarl  %cl,%ebx

	movl  dv_vlc_lookups(,%edx,4),%edx
	movl  (%edx,%ebx,4),%edx

	/* Now %edx holds result, like this:
	   bits 0-7   run
	   bits 8-15  len
	   bits 16-31 amp
	*/
	/* code needs to do this with result:
	   if ((amp > 0) &&
	     if ((bits >> sign_rshift[result->len]) & 1)
	         amp = -amp;
	   }
	*/
	/* if (amp < 0) %edx is 0, else 0xffff0000. */
	movl  %edx,%ecx
	sarl  $8,%ecx
	andl  $0xff,%ecx
	movl  sign_mask(,%ecx,4),%ecx
	andl  %ecx,%eax
	negl  %eax
	sarl  $31,%eax

	movl  %edx,%ebx
	sarl  $31,%ebx
	xorl  $0xffffffff,%ebx
	andl  $0xffff0000,%ebx

	andl  %ebx,%eax
	
	xorl  %eax,%edx
	subl  %eax,%edx

	movl  12(%esp),%eax
	movl  %edx,(%eax)
	
	popl  %ebx
	ret
