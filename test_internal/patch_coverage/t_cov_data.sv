class cov_item;
  rand logic [2:0] id;
  rand logic       valid;
  covergroup cg_item;
    cp_id:    coverpoint id;
    cp_valid: coverpoint valid;
    cx_iv:    cross cp_id, cp_valid;
  endgroup
  function new(); cg_item = new(); endfunction
  function void sample(); cg_item.sample(); endfunction
endclass
module t_cov_data_tb;
  initial begin
    cov_item c = new();
    repeat(512) begin assert(c.randomize()); c.sample(); end
    $display("PASS: t_cov_data"); $finish;
  end
endmodule
