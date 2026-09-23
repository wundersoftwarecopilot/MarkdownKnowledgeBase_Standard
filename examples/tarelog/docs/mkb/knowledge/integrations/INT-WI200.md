---
id: INT-WI200
type: integration
summary: Ponderix WI-200 weighing indicator frames - ST/US status, 64-byte converter chunks, ETX, checksum, FrameError
code: [src/tarelog/gateway/wi200.py]
verified: 2026-09-22
related: [SERVICE-GATEWAY, TASK-002]
---
# INT-WI200: Ponderix WI-200 weighing indicator

## Purpose
Two Ponderix WI-200 weighing indicators, one per weighbridge lane, send the weight on the platform to the reader service (SERVICE-GATEWAY).
The quarry owns both units; Ponderix support is reached through its local dealer, who also holds the legal-for-trade seal of the calibration settings.
The communication settings (menu `COM`) are outside the seal and may be changed on site.
Vendor documentation: [WI-200 protocol manual, section 4.2](https://example.com/wi200-manual.pdf).

## Contract
- Serial side: RS-232, 9600 baud, 8 data bits, no parity, 1 stop bit, continuous output mode (`OUT=CONT`), about 10 frames per second.
- Network side: one serial-to-Ethernet converter per lane in raw TCP server mode on port 4001; the reader connects as the only client (entries `gateway.lane` in `/etc/tarelog/tarelog.toml`).
- A frame is ASCII between STX (0x02) and ETX (0x03), 18 bytes without checksum:

```text
<STX>ST,GS,+0012380kg<ETX>
```

| Field | Bytes | Values |
|---|---|---|
| status | 2 | `ST` stable, `US` unstable (platform moving), `OL` overload or underload |
| separator | 1 | `,` |
| mode | 2 | `GS` gross, `NT` net (a tare is set on the indicator) |
| separator | 1 | `,` |
| weight | 8 | sign and 7 digits, kilograms, leading zeros |
| unit | 2 | always `kg` on these units |
| checksum | 3 | optional: `*` and two hex digits (section Checksum) |

- Only `ST` frames may become readings; `US` and `OL` frames feed the live display and are never stored, because tickets are legal-for-trade records ([project/CONSTRAINTS.md](../../project/CONSTRAINTS.md), section Regulatory and legal).
- The converters do not forward frame by frame: the lane 2 converter packs the stream into 64-byte chunks and the lane 1 converter forwards after a 5 ms gap, so a frame can be split across two TCP reads and one read can hold several frames.
- `src/tarelog/gateway/wi200.py` (`parse_frame()`) therefore keeps one byte buffer per lane and cuts frames at STX and ETX, never at read boundaries.
- A frame with no ETX within 24 bytes after its STX, or with a new STX before its ETX, raises `FrameError: missing ETX`; the parser drops the bytes up to the next STX and continues.

### Checksum
- Firmware 2.4 and later append a checksum before ETX when the `COM` menu setting `CS=ON` is set: `*` followed by two uppercase hex digits.
- The value is the XOR of every byte after STX up to the byte before `*`; the frame above becomes `<STX>ST,GS,+0012380kg*0C<ETX>`.
- Lane 2 runs firmware 2.4 with `CS=ON` since 2026-09-14; lane 1 runs firmware 2.2 and cannot send a checksum, so the parser accepts frames with and without one.
- A frame whose checksum does not match raises `FrameError: bad checksum` and is dropped like a frame without ETX; it never becomes a reading.

## Authentication
None.
The converters accept any TCP client on the office network; see section Limits and failure modes for why only the reader may connect.

## Limits and failure modes
- One TCP client per converter port: while the reader is connected, a second client (a test script, a terminal program) gets `ConnectionRefusedError: [Errno 111] Connection refused`.
- A converter restarts after a power dip; the reader sees the connection close and reconnects on its own (SERVICE-GATEWAY, section Operations).
- The indicator sends `US` for as long as a truck moves on the platform; a reading waits for several identical `ST` frames (SERVICE-GATEWAY, section Configuration).
- Weights above 60000 kg are sent as `OL`; no truck admitted to the quarry reaches it.

## Test environment
- `tests/fixtures/wi200/` holds recorded TCP captures from both lanes, including split frames, noise and checksummed lane 2 frames.
- `python -m tests.sim.wi200 --port 4001 --chunk 64 tests/fixtures/wi200/lane2-busy.bin` replays a capture as a fake converter; point `gateway.lane` at `127.0.0.1` to read from it.
- `pytest -m sim` runs the tests that need the simulator.

## Gotchas
- Lane 2 readings missing with no error logged -> a parser that expects one whole frame per TCP read drops frames split across 64-byte chunks (the old regex parser did) -> parse from the byte buffer; never read one frame per `recv()` call.
- `FrameError: missing ETX` now and then in the reader log -> a converter restart or line noise cut a frame -> nothing to do; more than one per minute on a lane means checking that lane's cable and converter.
- `FrameError: bad checksum` on lane 2 -> noise on the serial cable that runs along the conveyor -> same as above; a replacement lane 2 unit needs `CS=ON` again.
