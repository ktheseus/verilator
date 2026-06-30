// test_internal/patch_edge_cases/t_struct_cross.sv
typedef struct packed {
  logic [3:0] field1;
  logic [3:0] field2;
} packed_struct_t;

typedef struct {
  logic [3:0] field1;
  logic [3:0] field2;
} unpacked_struct_t;

class struct_class;
  packed_struct_t p_struct;
  unpacked_struct_t u_struct;

  covergroup cg_struct;
    cp_p1: coverpoint p_struct.field1;
    cp_p2: coverpoint p_struct.field2;
    cp_u1: coverpoint u_struct.field1;
    cp_u2: coverpoint u_struct.field2;

    cross cp_p1, cp_p2;
    cross cp_u1, cp_u2;
  endgroup

  function new();
    cg_struct = new();
  endfunction
endclass

module t_struct_cross;
  initial begin
    automatic struct_class sc = new();
    sc.p_struct.field1 = 4'ha;
    sc.p_struct.field2 = 4'hb;
    sc.u_struct.field1 = 4'hc;
    sc.u_struct.field2 = 4'hd;
    sc.cg_struct.sample();
    $display("get_inst_coverage() = %f", sc.cg_struct.get_inst_coverage());
    $display("cg_struct::get_coverage() = %f", sc.cg_struct.get_coverage());
    $display("PASS: struct coverpoint crossing — OK");
    $finish;
  end
endmodule
