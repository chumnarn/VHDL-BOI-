// covergroup_alu.sv
// SystemVerilog covergroup for ALU functional coverage
// Compile separately and reference from SystemVerilog testbench wrapper

module cg_alu_wrapper (
    input  logic        clk,
    input  logic [7:0]  a, b,
    input  logic [1:0]  op,
    input  logic [7:0]  y
);
    covergroup cg_alu @(posedge clk);
        cp_op    : coverpoint op {
            bins ADD = {2'b00};
            bins SUB = {2'b01};
            bins AND = {2'b10};
            bins OR  = {2'b11};
        }
        cp_a     : coverpoint a {
            bins low    = {[8'h00 : 8'h3F];
            bins mid    = {[8'h40 : 8'hBF];
            bins high   = {[8'hC0 : 8'hFF];
        }
        cp_b     : coverpoint b {
            bins low    = {[8'h00 : 8'h3F];
            bins mid    = {[8'h40 : 8'hBF];
            bins high   = {[8'hC0 : 8'hFF];
        }
        cp_zero  : coverpoint (y == 8'h00) {
            bins zero      = {1'b1};
            bins non_zero  = {1'b0};
        }
        // Cross coverage
        cx_op_a : cross cp_op, cp_a;
    endgroup
    cg_alu cg_alu_inst;
endmodule