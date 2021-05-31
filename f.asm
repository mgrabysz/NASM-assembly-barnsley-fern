section .text

global f
f:
; arguments: rdi = x, rsi = y, rdx = *image_header

    ; prologue
	push	rbp
	mov		rbp, rsp

	mov     rcx, 0x4169E1   ; royal blue


	mov     rax, 1000000       ; counter

    mov     rbx, [rdx+18]   ; rbx = width of image

    ;calculate row
    imul    rbx, 3          ; rbx = rbx * 3
    add     rbx, 3
    and     ebx, 0xFFFFFFFC ; possible padding

    push    rdx             ; [rbp-8] = *image_header
    push    rbx             ; [rbp-16] = row_size
    push    rcx             ; [rbp-24] = color
    push    rax             ; [rbp-32] = counter

color:
; arguments: rdi = x, rsi = y

    mov     rdx, rdi        ; rdx = x
    mov     rcx, rsi        ; rcx = y

    ; intentional offset to middle of bitmap
    add     rdx, 64
    add     rcx, 64

    mov     rbx, [rbp-16]   ; rbx = row_size
    mov     rax, [rbp-8]    ; rax = *image_header

    imul    rbx, rcx        ; rbx = row_size * y

    ;calculate column
    imul    rdx, 3          ; rdx = 3*x
    add     rbx, rdx        ; rbx = pixel_relative_address
    add     rbx, rax        ; rbx = header_adress + pixel_relative_adress
    add     rbx, 54         ; rbx = pixel absolute address

    ;copy to memory
    mov     rdx, [rbp-24]   ; rdx = 0x00RRGGBB
    mov     [rbx], dx       ; store GGBB
    shr     rdx, 16         ; in edx now 0x000000RR
    mov     [rbx+2], dl     ; store red


    ; begin of coordinate generator
    ; arguments: rdi = x, rsi = y
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
;    cmp     rdi, -6400;
 ;   jl      begin
;    cmp     rsi, -6400;
;    jl      begin

;    cmp     rax, 6300;
 ;   jge     begin
  ;  cmp     rcx, 6300;
   ; jge     begin

    ; new x division by 100
    xor     rdx, rdx    ; rdx = 0
    mov     rbx, 100    ; rdx = 100
    cqo                 ; filling rdx with most significant bit of rax
    idiv    rbx         ; rax = new_x
    mov     rdi, rax    ; rdi = new_x

    ; new y diviosion by 100
    xor     rdx, rdx    ; rdx = 0
    mov     rax, rcx    ; rax = 100 * new_y
    cqo                 ; filling rdx with most significant bit
    idiv    rbx         ; rax = new_y
    mov     rsi, rax    ; rsi = new_y

    ; check counter
    dec     qword [rbp-32]
    mov     rax, [rbp-32]
    cmp     rax, 0
    jnz     color

end:
    ; epilogue
	mov		rsp, rbp
	pop		rbp
	ret
