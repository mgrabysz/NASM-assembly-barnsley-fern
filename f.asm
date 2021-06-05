section .text

global f
f:
; argumnets: rdi = *image_header, rsi = counter, rdx = prob1, rcx = prob2, r8 = prob3

    ; prologue
	push	rbp
	mov		rbp, rsp

    push    rdi             ; [rbp-8] = *image_header
    push    rsi             ; [rbp-16] = counter
    push    rdx             ; [rbp-24] = prob1

    add     rdx, rcx        ; rdx = prob2_treshold = prob1 + prob2
    push    rdx             ; [rbp-32] = prob2_treshold

    add     rdx, r8         ; rdx = prob3_treshold = prob1 + prob2 + prob3
    push    rdx             ; [rbp-40] = prob3_treshold

	mov     rcx, 0x4169E1   ; royal blue 4169E1
	push    rcx             ; [rbp-48] = color

    ; calculate row
    mov     rbx, [rdi+18]   ; rbx = width of image
    imul    rbx, 3          ; rbx = rbx * 3
    add     rbx, 3
    and     ebx, 0xFFFFFFFC ; possible padding
    push    rbx             ; [rbp-56] = row_size

    ; stack content
    ; [rbp-8] = *image_header
    ; [rbp-16] = counter
    ; [rbp-24] = prob1
    ; [rbp-32] = prob2_treshold
    ; [rbp-40] = prob3_treshold
    ; [rbp-48] = color
    ; [rbp-56] = row_size

    ; white
    mov     rcx, [rdi+2]    ; rcx = file size
    sub     rcx, 54         ; rcx = number of bytes
    shr     rcx, 2          ; rcx = 1/4 * number of bytes = number of dwords
    add     rdi, 54         ; rdi = *first_byte

white_loop:
    mov     dword [rdi], 0xFFFFFFFF
    add     rdi, 4          ; rdi = *next_dword
    dec     rcx             ; number of dwords--
    cmp     rcx, 0
    jnz     white_loop      ; if number_of_dwords != 0 than goto white_loop

    ; set starting (x, y) = (0, 0)
    mov     rdi, 0
    mov     rsi, 0

color:
; arguments: rdi = x, rsi = y

    mov     rdx, rdi        ; rdx = x
    mov     rcx, rsi        ; rcx = y

    ; calculate vector [1/2 width, 1/8 height]
    mov     rbx, [rbp-8]    ; rbx = *image header

    ; x shift = 1/2 width
    xor     rax, rax
    mov     eax, [rbx+18]   ; rax = width of image
    shr     rax, 1          ; rax = 1/2 width
    add     rdx, rax        ; x shift by vector

    ; y shift = 1/8 height
    xor     rax, rax
    mov     eax, [rbx+22]   ; rax = height of image
    shr     rax, 3          ; rax = 1/8 height
    add     rcx, rax        ; y shift by vector

    ; check if coordinates are correct

    ; check if x > 0 and y > 0
    cmp     rdx, 0
    jl      coordinates
    cmp     rcx, 0
    jl      coordinates

    ; check if x < width and y < height
    xor     rax, rax
    mov     eax, [rbx+18]   ; rax = width of image
    cmp     rdx, rax
    jge     coordinates     ; if x >= width than goto coordinates

    mov     eax, [rbx+22]   ; rax = height of image
    cmp     rcx, rax
    jge     coordinates     ; if y >= height than goto coordinates

    ; calculate pixel address
    mov     rax, rbx        ; rax = *image_header
    mov     rbx, [rbp-56]   ; rbx = row_size
    
    imul    rbx, rcx        ; rbx = row_size * y
    imul    rdx, 3          ; rdx = 3*x
    add     rbx, rdx        ; rbx = pixel_relative_address
    add     rbx, rax        ; rbx = header_adress + pixel_relative_adress
    add     rbx, 54         ; rbx = pixel absolute address

    ; fill with RGB
    mov     rdx, [rbp-48]   ; rdx = 0x00RRGGBB
    mov     [rbx], dx       ; store GGBB
    shr     rdx, 16         ; in edx now 0x000000RR
    mov     [rbx+2], dl     ; store red


coordinates:
    ; begin of coordinate generator
    ; arguments: rdi = x, rsi = y

    ; random number generator 0-99
    xor     rdx, rdx
    rdrand  rax
	mov     rcx, 100
    div     rcx             ; rdx = random(0-99)

    ; choose a function
    cmp     rdx, [rbp-24]   ; if rdx < prob1 than goto f1
    jl      f1
    cmp     rdx, [rbp-32]   ; if rdx < prob2_treshold than goto f2
    jl      f2
    cmp     rdx, [rbp-40]   ; if rdx < prob3_treshold than goto f3
    jl      f3
                            ; else goto f4

    ; barnsley fern functions
f4:
    xor     rax, rax        ; rax = 0
    imul    rcx, rsi, 16    ; rcx = y * 16

    jmp     finish

f1:
    imul    rax, rdi, 85    ; rax = x * 85
    imul    rbx, rsi, 4     ; rbx = y * 4
    imul    rcx, rdi, -4    ; rcx = x * -4
    imul    rdx, rsi, 85    ; rdx = y * 85

    add     rax, rbx        ; rax = x * 85 + y * 4
    add     rcx, rdx        ; rcx = x * -4 + y * 85
    add     rcx, 12800

    jmp     finish

f2:
    imul    rax, rdi, -15
    imul    rbx, rsi, 28
    imul    rcx, rdi, 26
    imul    rdx, rsi, 24

    add     rax, rbx
    add     rcx, rdx
    add     rcx, 3520

    jmp     finish

f3:
    imul    rax, rdi, 20
    imul    rbx, rsi, -26
    imul    rcx, rdi, 23
    imul    rdx, rsi, 22

    add     rax, rbx
    add     rcx, rdx
    add     rcx, 12800

finish:
    ; rax = 100 * new_x
    ; rcx = 100 * new_y

    ; new x division by 100
    mov     rbx, 100    ; rdx = 100
    cqo                 ; filling rdx with most significant bit of rax
    idiv    rbx         ; rax = new_x
    mov     rdi, rax    ; rdi = new_x

    ; new y division by 100
    mov     rax, rcx    ; rax = 100 * new_y
    cqo                 ; filling rdx with most significant bit of rax
    idiv    rbx         ; rax = new_y
    mov     rsi, rax    ; rsi = new_y

    ; check counter
    dec     qword [rbp-16]  ; decrement counter
    mov     rax, [rbp-16]
    cmp     rax, 0
    jnz     color           ; if counter != 0 than goto color


    ; epilogue
	mov		rsp, rbp
	pop		rbp
	ret
