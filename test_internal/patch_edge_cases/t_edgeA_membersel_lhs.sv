// Edge Case A: cg handle is a class member, assigned via "this.cg = new()"
// Our patch does VN_CAST(lhsp, VarRef) → nullptr → silently skips injection
// Expected: compiles with COVERIGN (member access in coverpoint, no enclosing ptr)
class holder;
  rand logic [2:0] val;
  logic            valid;
  covergroup cg_holder;
    cp_val:   coverpoint val;
    cp_valid: coverpoint valid;
  endgroup
  function new(); this.cg_holder = new(); endfunction
  function void sample_it(); this.cg_holder.sample(); endfunction
endclass
module t_edgeA_membersel_lhs_tb;
  initial begin
    holder h = new();
    // coverpoints reference 'val' and 'valid' — enclosing class members
    // with MemberSel LHS, vlEnclosing injection is skipped gracefully
    $display("PASS: t_edgeA compile OK (runtime skipped — known edge case A)");
    $finish;
  end
endmodule
