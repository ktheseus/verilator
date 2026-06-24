// Moore FSM with registered outputs — both state and output regs reset
module t_fsm_cov_moore (input clk, rst_n, a, output logic y);
  typedef enum logic {S0=0, S1=1} st_e;
  st_e cur, nxt;
  logic out_r;
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin cur <= S0; out_r <= 0; end  // multi-assign reset branch
    else        begin cur <= nxt; out_r <= (cur == S1); end
  always_comb nxt = a ? S1 : S0;
  assign y = out_r;
endmodule
module t_fsm_cov_moore_tb;
  logic clk=0,rst_n=0,a=0,y;
  t_fsm_cov_moore dut(.clk,.rst_n,.a,.y);
  always #5 clk=~clk;
  initial begin
    #12 rst_n=1;
    repeat(8) begin @(posedge clk); a=$random; end
    $display("PASS: t_fsm_cov_moore y=%0b", y); $finish;
  end
endmodule
