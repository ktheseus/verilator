// test_internal/patch_edge_cases/t_new_features.sv
// Tests explicit cross bins and transition repetition range bounds.

class feature_sb;
  logic [1:0] val1;
  logic [1:0] val2;

  covergroup cg_cross;
    cp1: coverpoint val1 {
      bins b0 = {0};
      bins b1 = {1};
      bins b2 = {2};
    }
    cp2: coverpoint val2 {
      bins b0 = {0};
      bins b1 = {1};
      bins b2 = {2};
    }
    
    // Explicit cross bins, including ignore_bins and illegal_bins
    cross cp1, cp2 {
      bins cross_0_0 = binsof(cp1) intersect {0} && binsof(cp2) intersect {0};
      bins cross_0_1 = binsof(cp1) intersect {0} && binsof(cp2) intersect {1};
      ignore_bins ignore_2 = binsof(cp1) intersect {2} || binsof(cp2) intersect {2};
    }
  endgroup

  covergroup cg_trans;
    cp_t: coverpoint val1 {
      // Transition repetition range [2:4]
      bins trans_rep = (0 => 1 [* 2:4] => 0);
    }
  endgroup

  function new();
    cg_cross = new();
    cg_trans = new();
  endfunction

  function void sample(logic [1:0] v1, logic [1:0] v2);
    val1 = v1;
    val2 = v2;
    cg_cross.sample();
    cg_trans.sample();
  endfunction
endclass

module t_new_features;
  initial begin
    automatic feature_sb sb = new();
    
    // Sample combinations to exercise cross bins
    sb.sample(0, 0); // cross_0_0
    sb.sample(0, 1); // cross_0_1
    sb.sample(1, 1); // ignored
    sb.sample(2, 2); // ignored
    
    // Sample sequence for transition repetition: 0 => 1 => 1 => 0 (length 2 repetition)
    sb.sample(0, 0);
    sb.sample(1, 0);
    sb.sample(1, 0);
    sb.sample(0, 0); // should hit trans_rep (length 2)

    // Sample sequence: 0 => 1 => 1 => 1 => 0 (length 3 repetition)
    sb.sample(0, 0);
    sb.sample(1, 0);
    sb.sample(1, 0);
    sb.sample(1, 0);
    sb.sample(0, 0); // should hit trans_rep (length 3)

    // Sample sequence: 0 => 1 => 1 => 1 => 1 => 0 (length 4 repetition)
    sb.sample(0, 0);
    sb.sample(1, 0);
    sb.sample(1, 0);
    sb.sample(1, 0);
    sb.sample(1, 0);
    sb.sample(0, 0); // should hit trans_rep (length 4)
    
    $display("PASS: explicit cross bins and transition repetition ranges compiled and executed successfully");
    $finish;
  end
endmodule
