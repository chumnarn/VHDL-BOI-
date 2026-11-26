onerror {quit -code 1}
onbreak {quit -code 1}

if {![file isdirectory work]} {
    vlib work
}

switch -- $1 {
    rtl {
        vcom -2008 ../../seq_det_101.vhd
    }
    gls {
        vlog ../generic_cells.v ../seq_det_101_mapped.v
    }
    default {
        puts stderr "Usage: Run questa.do with rtl or gls"
        quit -code 2
    }
}

vcom -2008 ../../tb_seq_det_101.vhd
vsim -t 1ps -voptargs=+acc work.tb_seq_det_101
log -r sim:/tb_seq_det_101/*
run -all
if {![string equal -nocase [examine sim:/tb_seq_det_101/done] "true"]} {
    puts stderr "FAIL: testbench did not reach completion"
    quit -code 1
}
quit -code 0
