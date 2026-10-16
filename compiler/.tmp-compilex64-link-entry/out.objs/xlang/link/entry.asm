global xlang_entry_main
extern main
extern xlang_minit
extern xlang_mexit
section .text
xlang_entry_main:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 32
    call xlang_minit
    call main
    xor eax, eax
    mov DWORD [rsp], eax
    call xlang_mexit
    mov eax, DWORD [rsp]
    leave
    ret

; .ident "xlang (x64/nasm/mingw32) alpha-1.1.0"
