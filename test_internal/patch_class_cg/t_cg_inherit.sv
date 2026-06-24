class base_t;
  rand logic [3:0] data;
endclass
class derived_t extends base_t;
  rand logic [1:0] ctrl;
  covergroup cg_derived;
    cp_data: coverpoint data;
    cp_ctrl: coverpoint ctrl;
    cx_dc:   cross cp_data, cp_ctrl;
  endgroup
  function new(); cg_derived = new(); endfunction
  function void sample_it(); cg_derived.sample(); endfunction
endclass
module t_cg_inherit_tb;
  initial begin
    derived_t d = new();
    repeat(128) begin assert(d.randomize()); d.sample_it(); end
    $display("PASS: t_cg_inherit"); $finish;
  end
endmodule
