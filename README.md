# Rachel - ColecoVision Client

A Rachel card game client for the ColecoVision.

> **Compatibility status:** the ROM builds, but ports `$50-$52` describe a
> proposed expansion-bus adapter rather than known commercial hardware. The
> adapter has not been built or electrically validated. See
> [HARDWARE.md](HARDWARE.md).

## Platform Details

- **CPU**: Zilog Z80 @ 3.58 MHz
- **RAM**: 1KB
- **Graphics**: TMS9918A VDP (Text Mode, 40x24)
- **Platform ID**: `0x00C5` (197)
- **Player Name**: "COLECOVISION"

## Building

Requires [pasmo](http://pasmo.speccy.org/) Z80 assembler:

```bash
make
```

Output: `build/rachel.col`

Launch it with the matching Emu198x core:

```bash
tools/run-emulator
```

Set `EMU198X_ROOT` if the Emu198x workspace is not at the usual sibling
`Projects/198x/Emu198x/emu198x` path. Extra arguments are passed to the core.

## Hardware Notes

The ColecoVision uses the TMS9918A VDP, the predecessor to the SMS's VDP:
- Text mode: 40 columns x 24 rows
- Pattern-based graphics
- 16 fixed colors

## Controls

- **Joystick**: Navigate hand
- **Left Fire**: Select/deselect card
- **Right Fire**: Play selected cards
- **Joystick Up**: Draw card

## Protocol

Uses RUBP (Rachel Unified Binary Protocol):
- 64-byte fixed-size messages
- 16-byte header with "RACH" magic
- 48-byte payload

Full specification: [rachel-multiverse/protocol](https://github.com/rachel-multiverse/protocol) — also rendered at <https://rachel.stevehill.xyz/protocol>.

## Memory Constraints

With only 1KB of RAM, the ColecoVision client uses:
- ~180 bytes for game state and variables
- Network buffers consume most of the RAM
- Careful memory management required
