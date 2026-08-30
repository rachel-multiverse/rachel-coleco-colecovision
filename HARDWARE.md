# ColecoVision network adapter contract

Status: **buildable proposal; no prototype or hardware evidence**.

The client reserves expansion I/O ports `$50-$52`. These are Rachel-defined
registers, not a ColecoVision standard and not a claim that compatible hardware
is on sale.

| I/O port | Direction | Contract |
|---|---|---|
| `$50` | read/write | RX/TX byte FIFO |
| `$51` | read/write | control/firmware command register |
| `$52` | read | bit 0 TX ready, bit 1 RX ready, bit 2 TCP connected, bit 7 error |

A practical adapter is a 5 V-tolerant expansion-bus interface plus an MCU with
at least 128 bytes of RX and TX buffering. The MCU can either proxy ESP-AT or
own WiFi and raw TCP itself. It must connect to port 6502 and must never expose
AT status text inside the RUBP byte stream.

The current driver only consumes status bits 0/1 and directly emits ESP-AT
commands; control, connected and error semantics are reserved for the repair.
It also has a hard-coded server address. Those software gaps must be closed
before calling the client playable.

Before manufacture: verify expansion connector pinout and I/O decode, buffer
the Z80 bus, translate 5 V/3.3 V safely, budget power, add ESD protection, and
test alongside common controllers/expansions. Evidence must include schematic
revision, firmware/client commits, a logic trace, HELLO through GAME_STATE, a
play/draw action, and PLAYER_WON.
