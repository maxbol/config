testl	%edi, %edi
jle	 L1
xorl	%eax, %eax
xorl	%edx, %edx
nopl	(%rax,%rax)
L0:
movl	%eax, %ecx
imull	%eax, %ecx
addl	$0x1, %eax
addl	%ecx, %edx
cmpl	%eax, %edi
jne	 L0
movl	%edx, %eax
retq
nopl	(%rax)
L1:
xorl	%edx, %edx
movl	%edx, %eax
retq

