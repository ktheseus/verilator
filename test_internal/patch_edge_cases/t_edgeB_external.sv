// test_internal/patch_edge_cases/t_edgeB_external.sv
// Edge Case B: covergroup new() called from outside the class context.

class inner_class;
  rand logic [3:0] val;

  covergroup cg_inner;
    cp: coverpoint val;
  endgroup

  // No cg_inner = new() in constructor!
endclass

module t_edgeB_external;
  initial begin
    automatic inner_class obj = new();
    
    // Construct covergroup externally
    obj.cg_inner = new();
    
    obj.val = 4'ha;
    obj.cg_inner.sample();
    
    $display("PASS: EDGE_B external covergroup construction — OK");
    $finish;
  end
endmodule
