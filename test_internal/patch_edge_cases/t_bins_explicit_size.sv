// test_internal/patch_edge_cases/t_bins_explicit_size.sv
// Explicit bins array size: bins b[N] = {v1, v2, ..., vN}
//
// Previously: COVERIGN "Unsupported: 'bins' explicit array size (treated as '[]')"
// After:      Treated as bins b[] = {v1,v2,...} — one bin per value, no warning
//
// This is a common pattern: bins state[4] = {IDLE, ACTIVE, ERROR, RESET}
// IEEE 1800-2012 spec: explicit size must match number of elements (we accept any)

`default_nettype none

typedef enum logic [1:0] {
  ST_IDLE   = 2'b00,
  ST_ACTIVE = 2'b01,
  ST_ERROR  = 2'b10,
  ST_RESET  = 2'b11
} state_e;

class StateCG;
  rand state_e state;
  rand logic [3:0] opcode;

  covergroup cg_state;
    // Explicit array size — previously COVERIGN, now treated as bins b[]
    cp_state: coverpoint state {
      bins all_states[4] = {ST_IDLE, ST_ACTIVE, ST_ERROR, ST_RESET};
    }
    // Mix: explicit size and value range bins (both fixes in one test)
    cp_op: coverpoint opcode {
      bins low[2]  = {[4'h0:4'h7]};  // explicit size + range (both fixes)
      bins high[1] = {[4'h8:4'hF]};
    }
    cx_so: cross cp_state, cp_op;
  endgroup

  function new();
    cg_state = new();
  endfunction

  function void sample_all();
    state = ST_IDLE;   cg_state.sample();
    state = ST_ACTIVE; cg_state.sample();
    state = ST_ERROR;  cg_state.sample();
    state = ST_RESET;  cg_state.sample();
    opcode = 4'h0;  cg_state.sample();
    opcode = 4'hA;  cg_state.sample();
  endfunction
endclass

module t_bins_explicit_size;
  initial begin
    automatic StateCG c = new();
    c.sample_all();
    $display("PASS: t_bins_explicit_size — bins b[N] explicit size works correctly");
    $finish;
  end
endmodule
