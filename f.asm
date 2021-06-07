%use fp
section .text

global f
f:
; argumnets: rdi = *image_header, rsi = counter, rdx = prob1, rcx = prob2, r8 = prob3

    ; prologue
	push	rbp
	mov		rbp, rsp

    mov     r14, rdi        ; r14 = *image_header
    mov     r13, rsi        ; r13 = counter
    mov     r12, rdx        ; r12 = prob1

    add     rdx, rcx        ; rdx = prob2_treshold = prob1 + prob2
    mov     r11, rdx        ; r11 = prob2_treshold

    add     rdx, r8         ; rdx = prob3_treshold = prob1 + prob2 + prob3
    mov     r10, rdx        ; r10 = prob3_treshold

	mov     rcx, 0x4169E1   ; royal blue 4169E1
    mov     r9, rcx         ; r9 = color

    ; calculate row
    mov     rbx, [rdi+18]   ; rbx = width of image
    imul    rbx, 3          ; rbx = rbx * 3
    add     rbx, 3
    and     ebx, 0xFFFFFFFC ; possible padding
    mov     r8, rbx         ; r8 = row_size

    ; variables in registers:
    ; r14 = *image_header
    ; r13 = counter
    ; r12 = prob1
    ; r11 = prob2_treshold
    ; r10 = prob3_treshold
    ; r9 = color
    ; r8 = row_size

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
    mov     rbx, r14        ; rbx = *image header

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
    mov     rbx, r8         ; rbx = row_size

    imul    rbx, rcx        ; rbx = row_size * y
    imul    rdx, 3          ; rdx = 3*x
    add     rbx, rdx        ; rbx = pixel_relative_address
    add     rbx, rax        ; rbx = header_adress + pixel_relative_adress
    add     rbx, 54         ; rbx = pixel absolute address

    ; fill with RGB
    mov     rdx, r9         ; rdx = 0x00RRGGBB
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
    cmp     rdx, r12        ; if rdx < prob1 than goto f1
    jl      f1
    cmp     rdx, r11        ; if rdx < prob2_treshold than goto f2
    jl      f2
    cmp     rdx, r10        ; if rdx < prob3_treshold than goto f3
    jl      f3
                            ; else goto f4

; barnsley fern functions
; arguments: rdi = x (int), rsi = y (int)
; returns: xmm0 = x (float), xmm1 = y (float)
; constants 1.6 and 0.44 are multiplied by 80 to rescale the image

f4:
    mov         rax, float64(0.0)
    movq        xmm0, rax           ; xmm0 = 0.0
    mov         rax, float64(0.16)
    movq        xmm2, rax           ; xmm2 = 0.16
    cvtsi2sd    xmm1, rsi           ; xmm1 = float(y)
    mulsd       xmm1, xmm2          ; xmm1 = y * 0.16 (new y)

    jmp     finish

f1:
    cvtsi2sd    xmm2, rdi       ; xmm2 = float(x)
    cvtsi2sd    xmm3, rsi       ; xmm3 = float(y)
    mov     rax, float64(0.85)
    movq    xmm0, rax           ; xmm0 = 0.85
    mulsd   xmm0, xmm2          ; xmm0 = x*0.85
    mov     rax, float64(0.04)
    movq    xmm4, rax           ; xmm4 = 0.04
    mulsd   xmm4, xmm3          ; xmm4 = y*0.04
    addsd   xmm0, xmm4          ; xmm0 = x*0.85 + y*0.04 (new x)

    mov     rax, float64(-0.04)
    movq    xmm1, rax           ; xmm1 = -0.04
    mulsd   xmm1, xmm2          ; xmm1 = x*-0.04
    mov     rax, float64(0.85)
    movq    xmm4, rax           ; xmm4 = 0.85
    mulsd   xmm4, xmm3          ; xmm4 = y*0.85
    addsd   xmm1, xmm4          ; xmm1 = x*-0.04 + y*0.85
    mov     rax, float64(128.0) ; constant 1.6 multiplied by 80
    movq    xmm4, rax           ; xmm4 = 128.0
    addsd   xmm1, xmm4          ; xmm3 = x*-0.04 + y*0.85 + 128.0 (new y)

    jmp     finish

f2:
    cvtsi2sd    xmm2, rdi       ; xmm2 = float(x)
    cvtsi2sd    xmm3, rsi       ; xmm3 = float(y)
    mov     rax, float64(-0.15)
    movq    xmm0, rax           ; xmm0 = -0.15
    mulsd   xmm0, xmm2          ; xmm2 = x*-0.15
    mov     rax, float64(0.28)
    movq    xmm4, rax           ; xmm4 = 0.28
    mulsd   xmm4, xmm3          ; xmm4 = y*0.28
    addsd   xmm0, xmm4          ; xmm2 = x*-0.15 + y*0.28 (new x)

    mov     rax, float64(0.26)  ; rax = 0.26
    movq    xmm1, rax           ; xmm1 = 0.26
    mulsd   xmm1, xmm2          ; xmm1 = x*0.26
    mov     rax, float64(0.24)
    movq    xmm4, rax           ; xmm4 = 0.24
    mulsd   xmm4, xmm3          ; xmm4 = y*0.24
    addsd   xmm1, xmm4          ; xmm1 = x*0.26 + y*0.24
    mov     rax, float64(35.2)  ; constant 0.44 multiplied by 80
    movq    xmm4, rax           ; xmm4 = 35.2
    addsd   xmm1, xmm4          ; xmm1 = x*0.26 + y*0.24 + 35.2 (new y)

    jmp     finish

f3:
    cvtsi2sd    xmm2, rdi       ; xmm2 = float(x)
    cvtsi2sd    xmm3, rsi       ; xmm3 = float(y)
    mov     rax, float64(0.20)
    movq    xmm0, rax           ; xmm0 = 0.20
    mulsd   xmm0, xmm2          ; xmm0 = x*0.20
    mov     rax, float64(-0.26)
    movq    xmm4, rax           ; xmm4 = -0.26
    mulsd   xmm4, xmm3          ; xmm4 = y*-0.26
    addsd   xmm0, xmm4          ; xmm0 = x*0.20 + y*-0.26 (new x)

    mov     rax, float64(0.23)  ; rax = 0.23
    movq    xmm1, rax           ; xmm1 = 0.23
    mulsd   xmm1, xmm2          ; xmm1 = x*0.23
    mov     rax, float64(0.22)
    movq    xmm4, rax           ; xmm4 = 0.22
    mulsd   xmm4, xmm3          ; xmm4 = y*0.22
    addsd   xmm1, xmm4          ; xmm1 = x*0.23 + y*0.22
    mov     rax, float64(128.0) ; constant 1.6 multiplied by 80
    movq    xmm4, rax           ; xmm4 = 128
    addsd   xmm1, xmm4          ; xmm3 = x*0.23 + y*0.22 + 128

finish:
; sets new coords to rdi and rsi
    cvtsd2si    rax, xmm0
    mov         rdi, rax    ; rdi = new_x

    cvtsd2si    rax, xmm1
    mov         rsi, rax    ; rsi = new_y

    ; check counter
    dec     r13             ; decrement counter
    mov     rax, r13
    cmp     rax, 0
    jnz     color           ; if counter != 0 than goto color


    ; epilogue
	mov		rsp, rbp
	pop		rbp
	ret
