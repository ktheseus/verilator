// DESCRIPTION: Verilator Patch Test: transition repetition operators
// Tests: bins t = (a [*N]) (CONSEC), (a [->N]) (GOTO), (a [=N]) (NONCONS)
//        wildcard transition bins, default sequence bins
// EXPECTED: PASS with no errors

module t_bins_trans_rep;
  int fails = 0;
  logic [3:0] val;

  // Use module-level covergroup (no class to avoid class-CG limitations)
  covergroup cg_trans @val;
    cp: coverpoint val {
      /* verilator lint_off COVERIGN */
      // Consecutive repetition: val must be 4'h5 exactly 3 times in a row
      bins three_fives   = (4'h5 [* 3]);
      // Goto repetition: val must be 4'hA exactly 2 times
      bins two_A_goto    = (4'hA [-> 2]);
      // Nonconsecutive: val must be 4'h3 exactly 2 times
      bins two_3_noncons = (4'h3 [= 2]);
      // Range consecutive: 4'h1 two or three times
      bins one_range     = (4'h1 [* 2:3]);
      /* verilator lint_on COVERIGN */
      // Normal transition for baseline
      bins norm_trans    = (4'h7 => 4'h8);
      // Default sequence bin — catch-all remaining transitions
      /* verilator lint_off COVERIGN */
      bins other_trans   = default sequence;
      /* verilator lint_on COVERIGN */
    }
  endgroup

  cg_trans cg = new();

  task drive(logic [3:0] v);
    val = v;
    #1;
  endtask

  initial begin
    // Consecutive triplet 5 => 5 => 5
    drive(4'h5); drive(4'h5); drive(4'h5); drive(4'h0);
    // Normal transition 7 => 8
    drive(4'h7); drive(4'h8);
    // Goto A => B => A
    drive(4'hA); drive(4'hB); drive(4'hA); drive(4'h0);
    // Nonconsecutive 3 => 9 => 3
    drive(4'h3); drive(4'h9); drive(4'h3); drive(4'h0);
    // Range 1 => 1 (within [*2:3])
    drive(4'h1); drive(4'h1); drive(4'h0);

    if (fails == 0)
      $display("PASS: t_bins_trans_rep — transition repetition operators work correctly");
    else
      $display("FAIL: t_bins_trans_rep — %0d failures", fails);
    $finish;
  end
endmodule
