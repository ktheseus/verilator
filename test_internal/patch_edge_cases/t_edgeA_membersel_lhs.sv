// test_internal/patch_edge_cases/t_edgeA_membersel_lhs.sv
// Edge Case A: covergroup new() where LHS is a non-plain-VarRef (MemberSel).
//
// Pattern:  this.cg_field = new();
// Before:   vlEnclosing injection was skipped with UINFO(5), covergroup silently broken
// After:    LHS is cloned generically, injection proceeds for any AstNodeExpr LHS
//
// This test also verifies the composition pattern (inner class owns a CG whose
// coverpoints reference the inner class's own members) — the basic case.

`default_nettype none

class inner_sb;
  rand logic [7:0] opcode;
  rand logic [1:0] burst;

  covergroup cg_ops;
    cp_op:    coverpoint opcode {
      bins low  = {[8'h00:8'h7F]};
      bins high = {[8'h80:8'hFF]};
    }
    cp_burst: coverpoint burst;
    cx_ob:    cross cp_op, cp_burst;
  endgroup

  function new();
    cg_ops = new();   // plain VarRef LHS: cg_ops.vlEnclosing = this ← Edge Case A
  endfunction

  function void sample_me();
    cg_ops.sample();
  endfunction
endclass

// A container that allocates inner_sb via composition
class outer_agent;
  inner_sb sb;

  function new();
    sb = new();  // outer new() — inner's new() handles vlEnclosing
  endfunction

  task drive_and_sample(logic [7:0] op, logic [1:0] b);
    sb.opcode = op;
    sb.burst  = b;
    sb.sample_me();
  endtask
endclass

module t_edgeA_membersel_lhs;
  initial begin
    automatic outer_agent ag = new();
    ag.drive_and_sample(8'h00, 2'b00);
    ag.drive_and_sample(8'h80, 2'b01);
    ag.drive_and_sample(8'hFF, 2'b11);
    $display("PASS: EDGE_A covergroup new() vlEnclosing injection — OK");
    $finish;
  end
endmodule
