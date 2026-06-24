// Edge Case C: covergroup with clocking event referencing a class member
// Expected: COVERIGN warning, covergroup silently dropped — no crash
class clocked_cg;
  rand logic [1:0] op;
  logic            clk_ev;  // member used as clocking event
  // @(clk_ev) — references a class member variable
  covergroup cg_clocked @(clk_ev);
    cp_op: coverpoint op;
  endgroup
  function new(); cg_clocked = new(); endfunction
endclass
module t_edgeC_clocking_member_tb;
  initial begin
    clocked_cg c = new();
    $display("PASS: t_edgeC compile OK (covergroup dropped with COVERIGN as expected)");
    $finish;
  end
endmodule
