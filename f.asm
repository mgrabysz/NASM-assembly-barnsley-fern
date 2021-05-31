section .text

global f
f:
; arguments: rdi = x, rsi = y

    ; prologue
	push	rbp
	mov		rbp, rsp

begin:
    ; random number generator 0-99
    xor     rdx, rdx
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
    xor     rax, rax        ; rax = 0
    imul    rcx, rsi, 16    ; rcx = y * 16

    jmp     check

f1:
    imul    rax, rdi, 85    ; rax = x * 85
    imul    rbx, rsi, 4     ; rbx = y * 4
    imul    rcx, rdi, -4    ; rcx = x * -4
    imul    rdx, rsi, 85    ; rdx = y * 85

    add     rax, rbx        ; rax = x * 85 + y * 4
    add     rcx, rdx        ; rcx = x * -4 + y * 85
    add     rcx, 160        ; rcx += 160

    jmp     check

f2:
    imul    rax, rdi, -15
    imul    rbx, rsi, 28
    imul    rcx, rdi, 26
    imul    rdx, rsi, 24

    add     rax, rbx
    add     rcx, rdx
    add     rcx, 44

    jmp     check

f3:
    imul    rax, rdi, 20
    imul    rbx, rsi, -26
    imul    rcx, rdi, 23
    imul    rdx, rsi, 22

    add     rax, rbx
    add     rcx, rdx
    add     rcx, 160

check:
    ; rax = 100 * new_x
    ; rcx = 100 * new_y

    ; if new_x < 0 or new_y < 0
    ; than point is ignored
    cmp     rax, 0;
    jl      begin
    cmp     rcx, 0;
    jl      begin

    ; new x division by 100
    xor     rdx, rdx    ; rdx = 0
    mov     rbx, 100    ; rdx = 100
    div     rbx         ; rax = new_x
    mov     rdi, rax    ; rdi = new_x

    ; new y diviosion by 100
    xor     rdx, rdx    ; rdx = 0
    mov     rax, rcx    ; rax = 100 * new_y
    div     rbx         ; rax = new_y
    mov     rsi, rax    ; rsi = new_y

    ; testowanie
    mov     rax, rdi

    ; epilogue
	mov		rsp, rbp
	pop		rbp
	ret
