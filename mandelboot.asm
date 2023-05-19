BITS 16
ORG 7C00h

start:
    ; Enforce CS:IP
    jmp 0:_start

; Constants
yfactor:
dd 0.012
yoffset:
dd -1.2
xfactor:
dd 0.012
xoffset:
dd -2.5
four:
dd 4.0

_start:
    ; Set segment registers before accessing variables
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; TODO: Might not be needed
    ; Prepare the stack
    mov sp, 7B00h
    mov bp, sp

    ; Set video mode
    xor ah, ah
    mov al, 13h
    int 10h

    ; Initialize the FPU
    fwait
    finit
    fwait

    ; Clear line and column and set base video address
    xor di, di
    xor si, si
    mov dx, 0xA000
    mov es, dx
    xor dx, dx
draw_loop:
    ; Push column as integer into FP registers
    mov [val], si
    fild word [val]
    fwait

    ; Multiply by factor
    fld dword [xfactor]
    fwait
    fmulp st1, st0
    fwait

    ; Add offset
    fld dword [xoffset]
    fwait
    faddp st1, st0
    fwait

    ; Push line as integer into FP registers
    mov [val], di
    fild word [val]
    fwait

    ; Multiply by factor
    fld dword [yfactor]
    fwait
    fmulp st1, st0
    fwait

    ; Add offset
    fld dword [yoffset]
    fwait
    faddp st1, st0
    fwait

    ; Allocate z_re(n) = 0 and z_im(n) = 0 and work values
    fldz
    fwait
    fldz
    fwait

    ; So now, we have
    ; c_re
    ; c_im
    ; z_re[n]
    ; z_im[n]
    ; ------
    ; z_re[n+1] / modsq
    ; z_im[n+1]

    ; Clear iteration counter
    xor cx, cx
mandel_loop:
    ; z_re[n+1] = z_re[n]*z_re[n] - z_im[n]*z_im[n] + c_re
    fldz
    fwait
    fadd st2
    fwait
    fmul st2
    fwait

    fldz
    fwait
    fadd st2
    fwait
    fmul st2
    fwait

    fsubp st1, st0
    fwait

    fadd st4
    fwait

    ; z_im[n+1] = z_re[n]*z_im[n]*2 + c_im
    fldz
    fwait
    fadd st3
    fwait
    fmul st2
    fwait
    
    fadd st0
    fwait

    fadd st4
    fwait

    ; z_im[n] = z_im[n+1]
    fxch st2
    fwait
    fincstp
    fwait

    ; z_re[n] = z_re[n+1]
    fxch st2
    fwait
    fincstp
    fwait

    ; modsq = z_re[n]*z_re[n] + z_im[n]*z_im[n]
    fldz
    fwait
    fadd st2
    fwait
    fmul st2
    fwait

    fldz
    fwait
    fadd st2
    fwait
    fmul st2
    fwait

    faddp st1, st0
    fwait

    ; Push 4
    fld dword [four]
    fwait

    ; Compare and pop both modsq and 4
    fcomi
    fwait
    fincstp
    fwait
    fincstp
    fwait

    ; If greater, give up
    jbe mandel_end

    ; Increament and if not last iteration, continue
    inc cx
    cmp cx, 15
    jne mandel_loop
mandel_end:

    ; Offset cx by 32
    add cx, 32

    mov ax, si
    mov si, dx
    mov [es:si], cl
    mov si, ax
    inc dx

    ; Increment column and continue of not done
    inc si
    cmp si, 320
    jne draw_loop 

    ; Clear column
    xor si, si

    ; Increment line and continue of not done
    inc di
    cmp di, 200
    jne draw_loop

end:
    hlt
    jmp end

val:
dd 0

; MBR
times 510-($-$$) db 0
db 0x55
db 0xAA