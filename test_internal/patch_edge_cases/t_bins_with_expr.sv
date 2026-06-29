// test_internal/patch_edge_cases/t_bins_with_expr.sv
// bins with(expr) — filtered bins in covergroup
//
// IEEE 1800-2012 §19.7.1: bins b = {range_list} with (bool_expr)
// 'item' refers to each value being evaluated from range_list.
//
// Previously: COVERIGN "Unsupported: 'with' in cover bin (bin created without filter)"
//             The filter was ignored — ALL values were included.
//
// After: AstCoverBin.iffp() stores the filter.
//        V3Covergroup::applyWithFilter() evaluates per-value:
//          1. Clone filter expr
//          2. Substitute item → const value
//          3. Constant-fold (V3Const::constifyEdit)
//          4. Keep if non-zero, discard otherwise
//
// Test patterns:
//   bins even  = {[0:15]} with (item % 2 == 0)   → bins covering 0,2,4,6,8,10,12,14
//   bins upper = {[0:15]} with (item > 7)         → bins covering 8..15
//   bins not3  = {0,1,2,3} with (item != 2)       → bins covering 0,1,3

`default_nettype none

class FilteredCG;
  rand logic [3:0] val;

  covergroup cg_filtered;
    // Pattern 1: Modulo filter — even values from [0:15]
    cp_val: coverpoint val {
      /* verilator lint_off COVERIGN */
      bins even_vals[8] = {[4'h0:4'hF]} with (item % 2 == 0);
      bins odd_vals[8]  = {[4'h0:4'hF]} with (item % 2 != 0);
      /* verilator lint_on COVERIGN */
    }
    // Pattern 2: Threshold filter — high nibble only
    cp_high: coverpoint val {
      /* verilator lint_off COVERIGN */
      bins high = {[4'h0:4'hF]} with (item > 4'h7);
      bins low  = {[4'h0:4'hF]} with (item <= 4'h7);
      /* verilator lint_on COVERIGN */
    }
    // Pattern 3: Exclusion from explicit list
    cp_excl: coverpoint val {
      /* verilator lint_off COVERIGN */
      bins not_zero = {4'h0, 4'h1, 4'h2, 4'h3} with (item != 4'h0);
      /* verilator lint_on COVERIGN */
    }
  endgroup

  function new();
    cg_filtered = new();
  endfunction

  function void sample_all();
    for (int i = 0; i < 16; i++) begin
      val = i[3:0];
      cg_filtered.sample();
    end
  endfunction
endclass

module t_bins_with_expr;
  initial begin
    automatic FilteredCG cg = new();
    cg.sample_all();
    $display("PASS: t_bins_with_expr — bins with(expr) filter works correctly");
    $finish;
  end
endmodule
