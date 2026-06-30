// t_p1_pkg_fwdref.sv — regression test for P1 fix:
// "V3LinkDot: skip forward-ref check for package-imported types"
//
// Verifies that types defined in a package and imported via 'import pkg::*'
// into a module can be used as class member types and local variable types
// without triggering "Reference before declaration" errors.
//
// Also validates P2 implicit fix: class-embedded covergroup with rand member
// VarRefs compiles without COVERIGN when enclosing class is properly linked.
//
// Expected: zero %Error, zero %Warning-COVERIGN
// (only acceptable warnings: IMPLICITSTATIC, WIDTHTRUNC from randomize())

package test_types_pkg;
  class type_a;
    int val;
    function new(); val = 42; endfunction
  endclass

  class type_b extends type_a;
    logic [3:0] code;
    function new(); super.new(); code = 4'hA; endfunction
  endclass
endpackage

module t_p1_pkg_fwdref;
  import test_types_pkg::*;

  // P1 test 1: package-imported types at module scope
  type_a a_inst;
  type_b b_inst;

  // P1 test 2: class extending package type, with class-embedded covergroup
  class my_container extends type_b;
    rand logic [2:0] state;

    // P2 test: covergroup referencing rand member of enclosing class
    covergroup state_cg;
      cp_state: coverpoint state;
    endgroup

    function new();
      super.new();
      state_cg = new();
    endfunction

    task run();
      int i;
      for (i = 0; i < 8; i++) begin
        assert(this.randomize());
        state_cg.sample();
      end
    endtask
  endclass

  // P1 test 3: class-type var in begin/end block
  initial begin
    my_container c;
    c = new();
    c.run();
    $display("P1/P2 test PASS: pkg types, class cg, begin-block decl all OK");
    $finish;
  end
endmodule
