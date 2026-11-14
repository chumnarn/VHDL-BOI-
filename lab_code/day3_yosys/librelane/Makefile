# Makefile - เรียก LibreLane flow แบบสั้น
#
#   make flow   -> รัน flow ทั้งหมด (ครั้งแรกจะดาวน์โหลด PDK)
#   make clean  -> ล้าง runs/

PDK ?= sky130A

.PHONY: flow clean

flow:
	librelane --volare-pdk -p $(PDK) config.yaml

clean:
	rm -rf runs
