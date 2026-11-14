# Mini Project Final Report Template – UART TX

## 1. Design Specification

| Parameter | Value |
| --- | --- |
| Function | UART Transmitter |
| Baud rate | 115,200 |
| Frame format | 8-N-1 (1 start, 8 data, 1 stop, no parity) |
| System clock | 100 MHz |
| Data interface | Parallel 8-bit + din_vld/din_rdy handshake |

## 2. RTL Design

| File | Purpose |
| --- | --- |
| `baud_gen.vhd` | Programmable baud generator (tick at 115200 Hz) |
| `uart_tx.vhd` | FSM-based transmitter (IDLE → START → DATA → STOP) |
| `uart_top.vhd` | Top wrapper that wires baud_gen and uart_tx |

## 3. Verification

### 3.1 Test Plan

| Test case | Description | Pass criteria |
| --- | --- | --- |
| Reset | rst=1 for 5 cycles | tx=1, din_rdy=1 |
| 0x00 transmission | send 0x00, observe 10 bits | start=0, bits=00000000, stop=1 |
| 0xFF transmission | send 0xFF, observe 10 bits | start=0, bits=11111111, stop=1 |
| Alternating pattern 0x55 | send 0x55 | bits=01010101 |
| Alternating pattern 0xAA | send 0xAA | bits=10101010 |
| Mixed value 0x42 | send 0x42 | bits=01000010 |
| Mixed value 0x3C | send 0x3C | bits=00111100 |
| Back-to-back | send several bytes back to back | no extra bits between frames |

### 3.2 Functional Coverage (recommended extension)

```systemverilog
covergroup cg_uart @(posedge clk);
    cp_din : coverpoint din {
        bins zero  = {8'h00};
        bins ff    = {8'hFF};
        bins alt1  = {8'h55};
        bins alt2  = {8'hAA};
        bins other = default;
    }
    cp_back_to_back : coverpoint (din_vld && last_din_vld);
endgroup
```

### 3.3 Result Summary

| Metric | Value |
| --- | --- |
| Functional pass | 6/6 |
| Failure count | 0 |
| Waveform captured | `wave_*.vcd` |

## 4. Synthesis Result

After running `precision -shell -file synth_uart.tcl`:

| Metric | Value |
| --- | --- |
| Target clock period | 10 ns |
| Worst-case slack (max) | +X.XX ns |
| Worst-case slack (min) | +Y.YY ns |
| Total area | N gates / X μm² |
| Dynamic power | N μW @ 25°C |

See `reports/area_uart.rpt`, `reports/timing_max_uart.rpt`, `reports/timing_min_uart.rpt`, `reports/power_uart.rpt`

## 5. Gate-Level Simulation

Performed with SDF back-annotation (`run_gls_uart.do`):

| Item | Status |
| --- | --- |
| RTL vs GLS bit compare | FAIL (0 mismatches) |
| Setup violation warnings | 0 |
| Hold violation warnings | 0 |
| X-propagation | None |

## 6. Conclusion

โปรเจกต์นี้แสดงให้เห็น ASIC flow ครบวงจรตั้งแต่:
- RTL design (VHDL)
- Self-checking testbench
- Synthesis (Precision RTL)
- Gate-Level Simulation with SDF
- Coverage-driven verification (functional coverage)

ผู้เข้าอบรมสามารถใช้เป็น template สำหรับโปรเจกต์ ASIC ที่ซับซ้อนยิ่งขึ้นในอนาคต

## 7. Files Delivered

```
day5/
├── rtl/
│   ├── baud_gen.vhd
│   ├── uart_tx.vhd
│   └── uart_top.vhd
├── tb/
│   └── tb_uart_top.vhd
├── constraints/
│   └── constraints_uart.sdc
├── scripts/
│   ├── synth_uart.tcl
│   └── run_gls_uart.do
├── reports/             (after running synth_uart.tcl)
├── netlist/             (after running synth_uart.tcl)
└── final_report.md
```