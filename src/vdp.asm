; =============================================================================
; COLECOVISION VDP MODULE (TMS9918A)
; =============================================================================

; VDP Register Values for Text Mode (40x24)
; Mode: Text mode (40 columns, no sprites)
; Pattern table at $0000
; Name table at $0800

; Screen dimensions (text mode)
SCREEN_COLS     equ     40
SCREEN_ROWS     equ     24

; VRAM addresses
NAME_TABLE      equ     $0800
PATTERN_TABLE   equ     $0000

; =============================================================================
; Initialize VDP
; =============================================================================
vdp_init:
        ; Set VDP registers for text mode
        ld      hl, vdp_regs
        ld      b, 8
        ld      c, 0
vdp_reg_loop:
        ld      a, (hl)
        out     (VDP_CTRL), a
        ld      a, c
        or      $80
        out     (VDP_CTRL), a
        inc     hl
        inc     c
        djnz    vdp_reg_loop

        ; Load font patterns
        call    load_font

        ; Clear screen
        call    clear_screen
        ret

vdp_regs:
        db      $00             ; R0: Mode 0 (text mode)
        db      $D0             ; R1: 16KB, display on, no interrupt, text mode
        db      $02             ; R2: Name table at $0800
        db      $00             ; R3: Color table (not used in text mode)
        db      $00             ; R4: Pattern table at $0000
        db      $00             ; R5: Sprite attribute (not used)
        db      $00             ; R6: Sprite pattern (not used)
        db      $F1             ; R7: Text color white on black

; =============================================================================
; Load Font Patterns
; =============================================================================
load_font:
        ; Set VRAM write address to pattern table
        xor     a
        out     (VDP_CTRL), a
        ld      a, $40          ; Write mode
        out     (VDP_CTRL), a

        ; Skip first 32 patterns (control chars)
        ld      b, 0            ; 256 bytes = 32 patterns * 8
font_skip:
        xor     a
        out     (VDP_DATA), a
        djnz    font_skip

        ; Copy font data (96 characters, 8 bytes each)
        ld      hl, font_data
        ld      de, 768         ; 96 * 8
font_copy:
        ld      a, (hl)
        out     (VDP_DATA), a
        inc     hl
        dec     de
        ld      a, d
        or      e
        jr      nz, font_copy
        ret

; =============================================================================
; Clear Screen
; =============================================================================
clear_screen:
        ; Set VRAM write address to name table ($0800)
        ld      a, $00
        out     (VDP_CTRL), a
        ld      a, $48          ; ($08 & $3F) | $40
        out     (VDP_CTRL), a

        ; Fill with spaces
        ld      bc, SCREEN_COLS * SCREEN_ROWS
        ld      a, ' '
clear_scr_loop:
        out     (VDP_DATA), a
        dec     bc
        ld      a, b
        or      c
        ld      a, ' '
        jr      nz, clear_scr_loop
        ret

; =============================================================================
; Set Cursor Position (B=X, C=Y)
; =============================================================================
set_cursor:
        ld      a, b
        ld      (cursor_x), a
        ld      a, c
        ld      (cursor_y), a
        ret

; =============================================================================
; Print String (HL = string address)
; =============================================================================
print_string:
        push    hl
        ; Calculate VRAM address: NAME_TABLE + Y*40 + X
        ld      a, (cursor_y)
        ld      h, 0
        ld      l, a
        ; Multiply by 40 = 32 + 8 = (Y << 5) + (Y << 3)
        add     hl, hl          ; *2
        add     hl, hl          ; *4
        add     hl, hl          ; *8
        ld      d, h
        ld      e, l            ; DE = Y*8
        add     hl, hl          ; *16
        add     hl, hl          ; *32
        add     hl, de          ; HL = Y*40
        ld      a, (cursor_x)
        add     a, l
        ld      l, a
        jr      nc, print_no_carry
        inc     h
print_no_carry:
        ld      de, NAME_TABLE
        add     hl, de

        ; Set VRAM address
        ld      a, l
        out     (VDP_CTRL), a
        ld      a, h
        and     $3F
        or      $40
        out     (VDP_CTRL), a
        pop     hl

print_loop:
        ld      a, (hl)
        or      a
        ret     z
        out     (VDP_DATA), a
        inc     hl
        jr      print_loop

; =============================================================================
; Print Character (A = char)
; =============================================================================
print_char:
        push    hl
        push    af
        push    bc

        ; Calculate VRAM address
        ld      a, (cursor_y)
        ld      h, 0
        ld      l, a
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      d, h
        ld      e, l
        add     hl, hl
        add     hl, hl
        add     hl, de
        ld      a, (cursor_x)
        add     a, l
        ld      l, a
        jr      nc, pchar_no_carry
        inc     h
pchar_no_carry:
        ld      de, NAME_TABLE
        add     hl, de

        ; Set VRAM address
        ld      a, l
        out     (VDP_CTRL), a
        ld      a, h
        and     $3F
        or      $40
        out     (VDP_CTRL), a

        pop     bc
        pop     af
        out     (VDP_DATA), a

        ; Advance cursor
        ld      a, (cursor_x)
        inc     a
        ld      (cursor_x), a
        pop     hl
        ret

; =============================================================================
; Show Title Screen
; =============================================================================
show_title:
        call    clear_screen

        ld      b, 12
        ld      c, 10
        call    set_cursor
        ld      hl, msg_title
        call    print_string

        ld      b, 12
        ld      c, 14
        call    set_cursor
        ld      hl, msg_press_fire
        call    print_string
        ret

; =============================================================================
; Show Connecting
; =============================================================================
show_connecting:
        call    clear_screen

        ld      b, 13
        ld      c, 11
        call    set_cursor
        ld      hl, msg_connecting
        call    print_string
        ret

; =============================================================================
; Messages
; =============================================================================
msg_title:
        db      "RACHEL - COLECO", 0

msg_press_fire:
        db      "PRESS FIRE", 0

msg_connecting:
        db      "CONNECTING...", 0

; =============================================================================
; Font Data (8x8, ASCII 32-127)
; =============================================================================
font_data:
; Space
        db      $00,$00,$00,$00,$00,$00,$00,$00
; !
        db      $18,$18,$18,$18,$18,$00,$18,$00
; "
        db      $6C,$6C,$00,$00,$00,$00,$00,$00
; # to /
        db      $6C,$FE,$6C,$6C,$FE,$6C,$00,$00
        db      $18,$7E,$C0,$7C,$06,$FC,$18,$00
        db      $C6,$CC,$18,$30,$66,$C6,$00,$00
        db      $38,$6C,$38,$76,$DC,$76,$00,$00
        db      $18,$18,$30,$00,$00,$00,$00,$00
        db      $0C,$18,$30,$30,$30,$18,$0C,$00
        db      $30,$18,$0C,$0C,$0C,$18,$30,$00
        db      $00,$66,$3C,$FF,$3C,$66,$00,$00
        db      $00,$18,$18,$7E,$18,$18,$00,$00
        db      $00,$00,$00,$00,$18,$18,$30,$00
        db      $00,$00,$00,$7E,$00,$00,$00,$00
        db      $00,$00,$00,$00,$00,$18,$18,$00
        db      $06,$0C,$18,$30,$60,$C0,$00,$00
; 0-9
        db      $7C,$C6,$CE,$D6,$E6,$C6,$7C,$00
        db      $18,$38,$18,$18,$18,$18,$7E,$00
        db      $7C,$C6,$06,$1C,$30,$60,$FE,$00
        db      $7C,$C6,$06,$3C,$06,$C6,$7C,$00
        db      $1C,$3C,$6C,$CC,$FE,$0C,$0C,$00
        db      $FE,$C0,$FC,$06,$06,$C6,$7C,$00
        db      $3C,$60,$C0,$FC,$C6,$C6,$7C,$00
        db      $FE,$C6,$0C,$18,$30,$30,$30,$00
        db      $7C,$C6,$C6,$7C,$C6,$C6,$7C,$00
        db      $7C,$C6,$C6,$7E,$06,$0C,$78,$00
; : to @
        db      $00,$18,$18,$00,$18,$18,$00,$00
        db      $00,$18,$18,$00,$18,$18,$30,$00
        db      $0C,$18,$30,$60,$30,$18,$0C,$00
        db      $00,$00,$7E,$00,$7E,$00,$00,$00
        db      $30,$18,$0C,$06,$0C,$18,$30,$00
        db      $7C,$C6,$0C,$18,$18,$00,$18,$00
        db      $7C,$C6,$DE,$DE,$DC,$C0,$7C,$00
; A-Z
        db      $38,$6C,$C6,$C6,$FE,$C6,$C6,$00
        db      $FC,$C6,$C6,$FC,$C6,$C6,$FC,$00
        db      $7C,$C6,$C0,$C0,$C0,$C6,$7C,$00
        db      $F8,$CC,$C6,$C6,$C6,$CC,$F8,$00
        db      $FE,$C0,$C0,$F8,$C0,$C0,$FE,$00
        db      $FE,$C0,$C0,$F8,$C0,$C0,$C0,$00
        db      $7C,$C6,$C0,$CE,$C6,$C6,$7C,$00
        db      $C6,$C6,$C6,$FE,$C6,$C6,$C6,$00
        db      $7E,$18,$18,$18,$18,$18,$7E,$00
        db      $1E,$06,$06,$06,$C6,$C6,$7C,$00
        db      $C6,$CC,$D8,$F0,$D8,$CC,$C6,$00
        db      $C0,$C0,$C0,$C0,$C0,$C0,$FE,$00
        db      $C6,$EE,$FE,$D6,$C6,$C6,$C6,$00
        db      $C6,$E6,$F6,$DE,$CE,$C6,$C6,$00
        db      $7C,$C6,$C6,$C6,$C6,$C6,$7C,$00
        db      $FC,$C6,$C6,$FC,$C0,$C0,$C0,$00
        db      $7C,$C6,$C6,$C6,$D6,$CC,$76,$00
        db      $FC,$C6,$C6,$FC,$D8,$CC,$C6,$00
        db      $7C,$C6,$C0,$7C,$06,$C6,$7C,$00
        db      $7E,$18,$18,$18,$18,$18,$18,$00
        db      $C6,$C6,$C6,$C6,$C6,$C6,$7C,$00
        db      $C6,$C6,$C6,$C6,$6C,$38,$10,$00
        db      $C6,$C6,$C6,$D6,$FE,$EE,$C6,$00
        db      $C6,$6C,$38,$38,$38,$6C,$C6,$00
        db      $66,$66,$66,$3C,$18,$18,$18,$00
        db      $FE,$0C,$18,$30,$60,$C0,$FE,$00
; [ to `
        db      $3C,$30,$30,$30,$30,$30,$3C,$00
        db      $C0,$60,$30,$18,$0C,$06,$00,$00
        db      $3C,$0C,$0C,$0C,$0C,$0C,$3C,$00
        db      $10,$38,$6C,$C6,$00,$00,$00,$00
        db      $00,$00,$00,$00,$00,$00,$FE,$00
        db      $30,$18,$0C,$00,$00,$00,$00,$00
; a-z
        db      $00,$00,$78,$0C,$7C,$CC,$76,$00
        db      $C0,$C0,$FC,$C6,$C6,$C6,$FC,$00
        db      $00,$00,$7C,$C6,$C0,$C6,$7C,$00
        db      $06,$06,$7E,$C6,$C6,$C6,$7E,$00
        db      $00,$00,$7C,$C6,$FE,$C0,$7C,$00
        db      $1C,$30,$7C,$30,$30,$30,$30,$00
        db      $00,$00,$7E,$C6,$C6,$7E,$06,$7C
        db      $C0,$C0,$FC,$C6,$C6,$C6,$C6,$00
        db      $18,$00,$38,$18,$18,$18,$3C,$00
        db      $0C,$00,$0C,$0C,$0C,$0C,$CC,$78
        db      $C0,$C0,$CC,$D8,$F0,$D8,$CC,$00
        db      $38,$18,$18,$18,$18,$18,$3C,$00
        db      $00,$00,$EC,$FE,$D6,$C6,$C6,$00
        db      $00,$00,$FC,$C6,$C6,$C6,$C6,$00
        db      $00,$00,$7C,$C6,$C6,$C6,$7C,$00
        db      $00,$00,$FC,$C6,$C6,$FC,$C0,$C0
        db      $00,$00,$7E,$C6,$C6,$7E,$06,$06
        db      $00,$00,$DC,$E6,$C0,$C0,$C0,$00
        db      $00,$00,$7C,$C0,$7C,$06,$7C,$00
        db      $30,$30,$7C,$30,$30,$30,$1C,$00
        db      $00,$00,$C6,$C6,$C6,$C6,$7E,$00
        db      $00,$00,$C6,$C6,$6C,$38,$10,$00
        db      $00,$00,$C6,$C6,$D6,$FE,$6C,$00
        db      $00,$00,$C6,$6C,$38,$6C,$C6,$00
        db      $00,$00,$C6,$C6,$C6,$7E,$06,$7C
        db      $00,$00,$FE,$0C,$38,$60,$FE,$00
; { | } ~ DEL
        db      $0E,$18,$18,$70,$18,$18,$0E,$00
        db      $18,$18,$18,$18,$18,$18,$18,$00
        db      $70,$18,$18,$0E,$18,$18,$70,$00
        db      $76,$DC,$00,$00,$00,$00,$00,$00
        db      $00,$00,$00,$00,$00,$00,$00,$00
