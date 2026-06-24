class pkt;
  rand logic [3:0] op;
  rand logic [1:0] sz;
  covergroup cg_pkt;
    cp_op: coverpoint op {
      bins low  = {4'h0, 4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7};
      bins high = {4'h8, 4'h9, 4'ha, 4'hb, 4'hc, 4'hd, 4'he, 4'hf};
    }
    cp_sz: coverpoint sz;
  endgroup
  function new(); cg_pkt = new(); endfunction
  function void sample(); cg_pkt.sample(); endfunction
endclass
module t_cg_simple_tb;
  initial begin
    pkt p = new();
    repeat(64) begin assert(p.randomize()); p.sample(); end
    $display("PASS: t_cg_simple"); $finish;
  end
endmodule
