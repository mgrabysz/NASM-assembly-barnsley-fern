section .text

global f
f:
; arguments: rdi = x, rsi = y

    ; prologue
	push	rbp
	mov		rbp, rsp

    ; random number generator 0-99
    mov     rdx, 0
    rdrand  rax
	mov     rcx, 100
    div     rcx         ; rdx = random(0-99)

    cmp     rdx, 85
    jl      f1
    cmp     rdx, 92
    jl      f2
    cmp     rdx, 99
    jl      f3

f4:
    mov     rax, 4
    jmp     end

f1:
    mov     rax, 1
    jmp     end

f2:
    mov     rax, 2
    jmp     end

f3:
    mov     rax, 3

end:
    ; epilogue
	mov		rsp, rbp
	pop		rbp
	ret
