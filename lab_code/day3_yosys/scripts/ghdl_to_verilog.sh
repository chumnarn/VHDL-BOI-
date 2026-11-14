#!/usr/bin/env bash
# ghdl_to_verilog.sh
# สะพาน VHDL -> Verilog ด้วย GHDL front-end เพื่อให้นำ RTL ที่เขียนเป็น VHDL
# เข้า Yosys / LibreLane ได้
#
# ขั้นตอน:
#   1. ghdl -a            : วิเคราะห์ VHDL (ยังไม่สังเคราะห์)
#   2. ghdl --out=verilog : สร้างโมดูล Verilog จาก VHDL
#   3. yosys               : อ่าน Verilog ที่ได้แล้วสังเคราะห์ต่อ
#
# ทางเลือกอื่น: ใช้ yosys-ghdl plugin โดยตรง
#   yosys -m ghdl -p "ghdl --std=08 rtl/adder8.vhd -e adder8; synth -top adder8"
#
# ใช้งาน:  bash scripts/ghdl_to_verilog.sh [entity_name]

set -euo pipefail

TOP="${1:-adder8}"
STD="${STD:-08}"
SRC="rtl/${TOP}.vhd"
OUT_DIR="build"
WORK_DIR="build/ghdl_work"

echo "=== [1/3] GHDL analyse: $SRC (std=$STD) ==="
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$OUT_DIR"
( cd "$WORK_DIR" && ghdl -a "--std=$STD" "../../$SRC" )

echo "=== [2/3] GHDL -> Verilog ==="
# หมายเหตุ: GHDL 5.x ใช้คำสั่ง "synth" และพิมพ์ Verilog ออกที่ stdout
#   (ต้อง redirect เอง - ไม่มีตัวเลือกให้ระบุชื่อไฟล์)
( cd "$WORK_DIR" && ghdl synth "--std=$STD" --out=verilog "$TOP" > "${TOP}.v" )

if [ ! -s "$WORK_DIR/${TOP}.v" ]; then
    echo "ERROR: GHDL ไม่ได้สร้างไฟล์ Verilog"
    exit 1
fi

cp "$WORK_DIR/${TOP}.v" "$OUT_DIR/${TOP}_from_vhdl.v"

echo "=== [3/3] ตรวจสอบไฟล์ที่ได้ ==="
head -20 "$OUT_DIR/${TOP}_from_vhdl.v"
echo "..."
echo "บันทึกไว้ที่: $OUT_DIR/${TOP}_from_vhdl.v"
