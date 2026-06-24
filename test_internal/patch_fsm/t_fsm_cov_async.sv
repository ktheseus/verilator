// async-reset FSM — tests that MULTI_SAME_STATE path still works
module t_fsm_cov_async (input clk, rst_n, input [1:0] cmd, output logic [2:0] st);
  typedef enum logic [2:0] {S0=0,S1=1,S2=2,S3=3,S4=4,S5=5,S6=6,S7=7} st_e;
  st_e cur, nxt;
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) cur <= S0;
    else        cur <= nxt;
  always_comb begin
    nxt = cur;
    case (cur)
      S0: nxt = (cmd==0) ? S1 : S2;
      S1: nxt = S3;
      S2: nxt = S4;
      S3: nxt = S5;
      S4: nxt = S6;
      S5: nxt = S7;
      S6: nxt = S0;
      S7: nxt = S0;
    endcase
  end
  assign st = cur;
endmodule
module t_fsm_cov_async_tb;
  logic clk=0,rst_n=0; logic[1:0] cmd=0; logic[2:0] st;
  t_fsm_cov_async dut(.clk,.rst_n,.cmd,.st);
  always #5 clk=~clk;
  initial begin
    #12 rst_n=1;
    repeat(16) begin @(posedge clk); cmd=$random; end
    $display("PASS: t_fsm_cov_async st=%0d", st); $finish;
  end
endmodule
