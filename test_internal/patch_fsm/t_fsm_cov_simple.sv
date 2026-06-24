// t_fsm_cov_simple.sv — simple 4-state FSM + sync reset + --coverage
// Reproduces original UASSERT crash in V3FsmDetect::collectConstStateAssigns
module t_fsm_cov_simple (
  input  logic clk, rst_n, go,
  output logic [1:0] state_out
);
  typedef enum logic [1:0] {IDLE=0, FETCH=1, EXEC=2, DONE=3} st_e;
  st_e cur, nxt;
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) cur <= IDLE;   // reset branch — the crash site
    else        cur <= nxt;
  always_comb begin
    nxt = cur;
    case (cur)
      IDLE:  if (go) nxt = FETCH;
      FETCH:         nxt = EXEC;
      EXEC:          nxt = DONE;
      DONE:          nxt = IDLE;
      default:       nxt = IDLE;
    endcase
  end
  assign state_out = cur;
endmodule
module t_fsm_cov_simple_tb;
  logic clk=0, rst_n=0, go=0; logic [1:0] state;
  t_fsm_cov_simple dut(.clk,.rst_n,.go,.state_out(state));
  always #5 clk=~clk;
  initial begin
    #12 rst_n=1; #10 go=1; #10 go=0; #50;
    $display("PASS: t_fsm_cov_simple state=%0d", state); $finish;
  end
endmodule
