; =============================================================================
; COLECOVISION SERIAL MODULE
; =============================================================================

; Expansion port could be used for serial communication
; Would require custom hardware adapter

SERIAL_DATA     equ     $50
SERIAL_CTRL     equ     $51
SERIAL_STATUS   equ     $52

; =============================================================================
; Initialize Network
; =============================================================================
net_init:
        ret

; =============================================================================
; Connect to Server
; =============================================================================
net_connect:
        ld      hl, at_cipstart
        call    send_at_string

        ld      hl, ip_string
        call    send_at_string

        ld      hl, at_port
        call    send_at_string

        call    wait_response
        ret

; =============================================================================
; Send AT String (HL = string)
; =============================================================================
send_at_string:
at_loop:
        ld      a, (hl)
        or      a
        ret     z
        call    serial_write_byte
        inc     hl
        jr      at_loop

; =============================================================================
; Write Byte via Serial
; =============================================================================
serial_write_byte:
        push    af
wait_tx:
        in      a, (SERIAL_STATUS)
        bit     0, a
        jr      z, wait_tx
        pop     af
        out     (SERIAL_DATA), a
        ret

; =============================================================================
; Read Byte via Serial
; =============================================================================
serial_read_byte:
        push    bc              ; Caller owns frame/response loop counters
        ld      bc, 10000
wait_rx:
        in      a, (SERIAL_STATUS)
        bit     1, a
        jr      nz, got_data
        dec     bc
        ld      a, b
        or      c
        jr      nz, wait_rx
        scf
        pop     bc              ; POP preserves A and carry
        ret
got_data:
        in      a, (SERIAL_DATA)
        or      a
        pop     bc              ; POP preserves A and carry
        ret

; =============================================================================
; Wait for OK Response
; =============================================================================
wait_response:
        ld      b, 200
wait_resp_loop:
        call    serial_read_byte
        jr      c, next_try
        cp      'O'
        jr      nz, next_try
        call    serial_read_byte
        jr      c, next_try
        cp      'K'
        jr      nz, next_try
        xor     a
        ret
next_try:
        djnz    wait_resp_loop
        ld      a, 1
        ret

; =============================================================================
; Send 64-byte Buffer
; =============================================================================
net_send:
        ld      hl, at_cipsend
        call    send_at_string

        ld      hl, net_buffer_tx
        ld      b, 64
send_loop:
        ld      a, (hl)
        call    serial_write_byte
        inc     hl
        djnz    send_loop
        ret

; =============================================================================
; Receive 64-byte Buffer
; =============================================================================
net_recv:
        ld      hl, net_buffer_rx
        ld      b, 64
        ld      c, 0

recv_loop:
        call    serial_read_byte
        jr      c, recv_timeout
        ld      (hl), a
        inc     hl
        inc     c
        djnz    recv_loop
        xor     a
        ret

recv_timeout:
        ld      a, c
        or      a
        jr      z, recv_no_data
        ld      a, 1
        ret
recv_no_data:
        ld      a, 2
        ret

; =============================================================================
; AT Command Strings
; =============================================================================
at_cipstart:
        db      "AT+CIPSTART=\"TCP\",\"", 0
at_port:
        db      "\",6502", 13, 0
at_cipsend:
        db      "AT+CIPSEND=64", 13, 0
ip_string:
        db      "192.168.1.100", 0

; =============================================================================
; RAM Variables (EQU to avoid binary padding)
; =============================================================================
vblank_flag     equ     RAM_START + 0
game_state      equ     RAM_START + 1
joypad          equ     RAM_START + 2
joypad_old      equ     RAM_START + 3
joypad_new      equ     RAM_START + 4
cursor_x        equ     RAM_START + 5
cursor_y        equ     RAM_START + 6
msg_sequence    equ     RAM_START + 7

net_buffer_tx   equ     RAM_START + 8
net_buffer_rx   equ     RAM_START + 72

current_turn    equ     RAM_START + 136
my_index        equ     RAM_START + 137
discard_top     equ     RAM_START + 138
current_suit    equ     RAM_START + 139
draw_count      equ     RAM_START + 140
hand_count      equ     RAM_START + 141
hand_cursor     equ     RAM_START + 142
hand_cards      equ     RAM_START + 143
hand_selected   equ     RAM_START + 163
