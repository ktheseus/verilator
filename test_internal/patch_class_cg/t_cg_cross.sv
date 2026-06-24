class xact;
  rand logic [1:0] kind;
  rand logic [1:0] sz;
  rand logic       err;
  covergroup cg_xact;
    cp_kind: coverpoint kind;
    cp_sz:   coverpoint sz;
    cp_err:  coverpoint err;
    cx_ks:   cross cp_kind, cp_sz;
    cx_ke:   cross cp_kind, cp_err;
  endgroup
  function new(); cg_xact = new(); endfunction
  function void sample_it(); cg_xact.sample(); endfunction
endclass
module t_cg_cross_tb;
  initial begin
    xact x = new();
    repeat(256) begin assert(x.randomize()); x.sample_it(); end
    $display("PASS: t_cg_cross"); $finish;
  end
endmodule
