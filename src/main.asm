; =============================================================================
; COLECOVISION RACHEL CLIENT
; Main entry point
; =============================================================================

; Platform ID: 0x00C5 (197)
PLATFORM_ID_HI  equ     $00
PLATFORM_ID_LO  equ     $C5

; =============================================================================
; Memory Map
; =============================================================================
; $0000-$1FFF  BIOS ROM (8KB)
; $2000-$5FFF  Cartridge ROM (16KB, expandable)
; $6000-$63FF  RAM (1KB)
; $7000-$7FFF  Cartridge RAM (optional)

RAM_START       equ     $6000

; =============================================================================
; VDP Ports (TMS9918A)
; =============================================================================
VDP_DATA        equ     $BE
VDP_CTRL        equ     $BF

; =============================================================================
; Controller Ports
; =============================================================================
CTRL_MODE       equ     $80
CTRL_READ1      equ     $FC
CTRL_READ2      equ     $FF

; =============================================================================
; RUBP Constants
; =============================================================================
RUBP_VERSION    equ     1
MSG_HELLO       equ     $01
MSG_GAME_STATE  equ     $10
MSG_PLAY_CARD   equ     $20
MSG_DRAW_CARD   equ     $21
HEADER_SIZE     equ     16
PAYLOAD_START   equ     16
PAYLOAD_SIZE    equ     48

; =============================================================================
; Game States
; =============================================================================
STATE_TITLE     equ     0
STATE_CONNECT   equ     1
STATE_GAME      equ     2

; =============================================================================
; Cartridge Header
; =============================================================================
        org     $8000

; Jump table
        jp      start           ; Reset
        jp      nmi_handler     ; NMI
        jp      0               ; Timer (unused)
        jp      0               ; Pause (unused)

; Cartridge info
        db      $AA, $55        ; Cartridge present
        dw      0               ; Sprite table pointer
        dw      0               ; Sprite attribute
        dw      0               ; Work RAM
        dw      0               ; Controller buffer
        dw      start           ; Start address
        dw      0               ; RST 08
        dw      0               ; RST 10
        dw      0               ; RST 18
        dw      0               ; RST 20
        dw      0               ; RST 28
        dw      0               ; RST 30
        dw      nmi_handler     ; NMI
        db      "RACHEL      "  ; Title (12 chars)

; =============================================================================
; NMI Handler
; =============================================================================
nmi_handler:
        push    af
        in      a, (VDP_CTRL)   ; Acknowledge VDP interrupt
        ld      a, 1
        ld      (vblank_flag), a
        pop     af
        retn

; =============================================================================
; Main Entry Point
; =============================================================================
start:
        di
        ld      sp, $63FF       ; Stack at top of RAM

        ; Initialize VDP
        call    vdp_init

        ; Initialize variables
        call    init_vars

        ; Initialize network
        call    net_init

        ; Show title
        call    show_title

        ; Set initial state
        ld      a, STATE_TITLE
        ld      (game_state), a

        ; Enable interrupts
        ei

; =============================================================================
; Main Loop
; =============================================================================
main_loop:
        call    wait_vblank
        call    read_controller

        ld      a, (game_state)
        cp      STATE_TITLE
        jp      z, handle_title
        cp      STATE_CONNECT
        jp      z, handle_connect
        cp      STATE_GAME
        jp      z, handle_game

        jp      main_loop

; =============================================================================
; State Handlers
; =============================================================================
handle_title:
        ld      a, (joypad_new)
        and     $40             ; Fire button
        jp      z, main_loop

        call    show_connecting
        ld      a, STATE_CONNECT
        ld      (game_state), a
        jp      main_loop

handle_connect:
        call    net_connect
        or      a
        jr      nz, connect_fail

        call    send_hello
        ld      a, STATE_GAME
        ld      (game_state), a
        jp      main_loop

connect_fail:
        call    show_title
        ld      a, STATE_TITLE
        ld      (game_state), a
        jp      main_loop

handle_game:
        call    net_recv
        or      a
        jr      nz, game_no_data

        call    rubp_validate
        or      a
        jr      nz, game_no_data

        call    get_message_type
        cp      MSG_GAME_STATE
        jr      nz, game_no_data

        call    process_game_state
        call    render_game

game_no_data:
        call    handle_game_input
        jp      main_loop

; =============================================================================
; Initialize Variables
; =============================================================================
init_vars:
        ld      hl, RAM_START
        ld      bc, 256
        xor     a
init_clear:
        ld      (hl), a
        inc     hl
        dec     bc
        ld      a, b
        or      c
        jr      nz, init_clear
        ret

; =============================================================================
; Wait for VBlank
; =============================================================================
wait_vblank:
        xor     a
        ld      (vblank_flag), a
wait_vb_loop:
        ld      a, (vblank_flag)
        or      a
        jr      z, wait_vb_loop
        ret

; =============================================================================
; Include other modules
; =============================================================================
        include "vdp.asm"
        include "input.asm"
        include "game.asm"
        include "rubp.asm"
        include "net/serial.asm"
