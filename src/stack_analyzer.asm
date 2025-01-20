; MARF Stack Analyzer Assembly Component
; Provides low-level stack inspection capabilities

BITS 64
global analyze_stack
global get_stack_pointer
global execute_analysis_code
global validate_stack_frame

section .text

analyze_stack:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32         ; Allocate stack frame
    
    ; Save registers
    mov     [rbp-8], rbx
    mov     [rbp-16], r12
    mov     [rbp-24], r13
    
    ; Get stack pointer
    mov     rax, rsp
    add     rax, 32         ; Adjust for our frame
    
    ; Check stack alignment
    test    rax, 0xf
    jz      .aligned
    
    ; Handle misalignment
    and     rax, ~0xf
    add     rax, 16
    
.aligned:
    ; Store result
    mov     [rbp-32], rax
    
    ; Restore registers
    mov     rbx, [rbp-8]
    mov     r12, [rbp-16]
    mov     r13, [rbp-24]
    
    ; Return result
    mov     rax, [rbp-32]
    
    leave
    ret

get_stack_pointer:
    mov     rax, rsp
    ret

execute_analysis_code:
    ; Function prologue
    push    rbp
    mov     rbp, rsp
    
    ; Get parameters
    mov     rax, rdi        ; First argument: code pointer
    mov     rcx, rsi        ; Second argument: size
    
    ; Verify size
    test    rcx, rcx
    jz      .done
    
    ; Execute code
    call    rax
    
.done:
    ; Function epilogue
    leave
    ret

validate_stack_frame:
    push    rbp
    mov     rbp, rsp
    
    ; Check frame pointer chain
    mov     rax, rbp
    
.check_loop:
    ; Check if we've reached the top
    test    rax, rax
    jz      .valid
    
    ; Load next frame pointer
    mov     rax, [rax]
    
    ; Check alignment
    test    rax, 0xf
    jnz     .invalid
    
    ; Check if pointer is reasonable
    cmp     rax, rbp
    jbe     .invalid
    
    jmp     .check_loop
    
.invalid:
    xor     rax, rax        ; Return 0 for invalid
    jmp     .exit
    
.valid:
    mov     rax, 1          ; Return 1 for valid
    
.exit:
    leave
    ret

section .data
    align 16
    stack_magic: dq 0x4D4152465F535441  ; "MARF_STA"
    frame_sig:   dq 0x434B5F4652414D45  ; "CK_FRAME"