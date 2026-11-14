# Makefile - เรียก LibreLane flow แบบสั้น
#
#   make flow   -> รัน flow ทั้งหมด (ครั้งแรกจะดาวน์โหลด PDK)
#   make clean  -> ล้าง runs/
#
# nix profile ไม่ถูกโหลดอัตโนมัติใน non-interactive shell
# จึงค้นหา binary เองก่อนเรียก

PDK ?= sky130A

LIBRELANE_BIN := $(shell command -v librelane 2>/dev/null || \
                   ls -1 $${HOME}/.nix-profile/bin/librelane /root/.nix-profile/bin/librelane 2>/dev/null | head -1)

.PHONY: flow clean

flow:
	@if [ -z "$(LIBRELANE_BIN)" ]; then \
	  echo "ไม่พบคำสั่ง librelane - ติดตั้งด้วย: nix profile install nixpkgs#librelane"; \
	  echo "แล้วเพิ่ม PATH: export PATH=\"$$HOME/.nix-profile/bin:$$PATH\""; \
	  exit 1; \
	fi
	$(LIBRELANE_BIN) --volare-pdk -p $(PDK) config.yaml

clean:
	rm -rf runs
