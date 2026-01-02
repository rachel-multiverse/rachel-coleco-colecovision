; =============================================================================
; COLECOVISION INPUT MODULE
; =============================================================================

; Controller bits (active low after processing):
; Bit 0: Up
; Bit 1: Down
; Bit 2: Left
; Bit 3: Right
; Bit 4: Fire left
; Bit 5: Fire right
; Bit 6: Arm button

; =============================================================================
; Read Controller
; =============================================================================
read_controller:
        ; Save old state
        ld      a, (joypad)
        ld      (joypad_old), a

        ; Select joystick mode
        ld      a, $00
        out     (CTRL_MODE), a

        ; Small delay
        ld      b, 10
ctrl_delay1:
        djnz    ctrl_delay1

        ; Read controller 1
        in      a, (CTRL_READ1)

        ; Process bits (active low on hardware)
        cpl
        and     $7F
        ld      (joypad), a

        ; Calculate newly pressed
        ld      b, a
        ld      a, (joypad_old)
        cpl
        and     b
        ld      (joypad_new), a
        ret
