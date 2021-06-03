section .text

global f
f:
; OLD arguments: rdi = x, rsi = y, rdx = *image_header
; NEW argumnets: rdi = *image_header, rsi = counter, rdx = prob1, rcx = prob2, r8 = prob3

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

    ;calculate row
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
    add     rdi, 54         ; rdi = *first_byte

white_loop:
    mov     byte [rdi], 0xFF
    inc     rdi             ; rdi = *next_byte
    dec     rcx             ; number_of_bytes--
    cmp     rcx, 0
    jnz     white_loop      ; if number_of_bytes != 0 than goto white_loop

    ; set starting (x, y) = (0, 0)
    mov     rdi, 0
    mov     rsi, 0

color:
; arguments: rdi = x, rsi = y

    mov     rdx, rdi        ; rdx = x
    mov     rcx, rsi        ; rcx = y

    ; intentional offset to middle of bitmap
    add     rdx, 512        ; 1/2 width
    add     rcx, 128        ; 1/8 height

    ; check if coordinates are correct

    ; check if x > 0 and y > 0
    cmp     rdx, 0
    jl      coordinates
    cmp     rcx, 0
    jl      coordinates

    ; check if x < width and y < height
    mov     rbx, [rbp-8]    ; rbx = *image header
    xor     rax, rax

    mov     eax, [rbx+18]   ; rax = width of image
    cmp     rdx, rax
    jge     coordinates     ; if x >= width than goto coordinates

    mov     eax, [rbx+22]   ; rax = height of image
    cmp     rcx, rax
    jge     coordinates     ; if y >= height than goto coordinates

    ; calculate pixel address

    mov     rbx, [rbp-56]   ; rbx = row_size
    mov     rax, [rbp-8]    ; rax = *image_header

    imul    rbx, rcx        ; rbx = row_size * y

    ; calculate column
    imul    rdx, 3          ; rdx = 3*x
    add     rbx, rdx        ; rbx = pixel_relative_address
    add     rbx, rax        ; rbx = header_adress + pixel_relative_adress
    add     rbx, 54         ; rbx = pixel absolute address

    ; copy to memory
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
    div     rcx         ; rdx = random(0-99)

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
    add     rcx, 12800      ; rcx += 160

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
    xor     rdx, rdx    ; rdx = 0
    mov     rbx, 100    ; rdx = 100
    cqo                 ; filling rdx with most significant bit of rax
    idiv    rbx         ; rax = new_x
    mov     rdi, rax    ; rdi = new_x

    ; new y division by 100
    xor     rdx, rdx    ; rdx = 0
    mov     rax, rcx    ; rax = 100 * new_y
    cqo                 ; filling rdx with most significant bit of rax
    idiv    rbx         ; rax = new_y
    mov     rsi, rax    ; rsi = new_y

    ; check counter
    dec     qword [rbp-16]
    mov     rax, [rbp-16]
    cmp     rax, 0
    jnz     color


    ; epilogue
	mov		rsp, rbp
	pop		rbp
	ret
