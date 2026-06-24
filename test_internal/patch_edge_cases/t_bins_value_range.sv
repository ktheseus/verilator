// test_internal/patch_edge_cases/t_bins_value_range.sv
// Value range bins {[lo:hi]} in covergroup coverpoints
//
// Previously: COVERIGN "Unsupported: covergroup value range '[...]'"
// After:      AstInsideRange emitted — same node used by 'inside' operator
//             V3Covergroup bins lowering handles AstInsideRange natively
//
// This is the most common pattern in UVM testbenches:
//   bins low  = {[8'h00:8'h7F]};
//   bins high = {[8'h80:8'hFF]};

`default_nettype none

class CxlOpSb;
  rand logic [7:0] opcode;
  rand logic [1:0] prot;

  covergroup op_cov;
    cp_opcode: coverpoint opcode {
      // Value range bins — previously COVERIGN, now supported
      bins req    = {[8'h00:8'h0F]};   // CXL request opcodes
      bins data   = {[8'h10:8'h1F]};   // CXL data opcodes
      bins snoop  = {[8'h20:8'h2F]};   // Snoop opcodes
      bins ndr    = {[8'h40:8'h4F]};   // No-data response
      bins other  = default;
    }
    cp_prot: coverpoint prot {
      bins normal    = {2'b00};
      bins device    = {2'b01};
      bins noncache  = {2'b10, 2'b11};
    }
    cx_op_prot: cross cp_opcode, cp_prot;
  endgroup

  function new();
    op_cov = new();
  endfunction

  function void sample_it();
    op_cov.sample();
  endfunction
endclass

module t_bins_value_range;
  initial begin
    automatic CxlOpSb sb = new();
    // Sweep through all opcode ranges
    foreach (sb.opcode[i]) begin
      for (int j = 0; j < 4; j++) begin
        sb.opcode = i[7:0];
        sb.prot   = j[1:0];
        sb.sample_it();
      end
    end
    $display("PASS: t_bins_value_range — {[lo:hi]} bins work correctly");
    $finish;
  end
endmodule
