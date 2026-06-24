class multi_cg;
  rand logic [3:0] addr;
  rand logic [1:0] prot;
  rand logic       hit;
  covergroup cg_addr; cp_a: coverpoint addr; endgroup
  covergroup cg_prot; cp_p: coverpoint prot; endgroup
  covergroup cg_hit;  cp_h: coverpoint hit;  endgroup
  function new();
    cg_addr = new(); cg_prot = new(); cg_hit = new();
  endfunction
  function void sample();
    cg_addr.sample(); cg_prot.sample(); cg_hit.sample();
  endfunction
endclass
module t_cg_multi_tb;
  initial begin
    multi_cg m = new();
    repeat(64) begin assert(m.randomize()); m.sample(); end
    $display("PASS: t_cg_multi"); $finish;
  end
endmodule
