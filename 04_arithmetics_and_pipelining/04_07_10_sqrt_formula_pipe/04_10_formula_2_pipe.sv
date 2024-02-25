//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);
    // Task:
    //
    // Implement a pipelined module formula_2_pipe that computes the result
    // of the formula defined in the file formula_2_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_2_pipe has to be pipelined.
    //
    // It should be able to accept a new set of arguments a, b and c
    // arriving at every clock cycle.
    //
    // It also should be able to produce a new result every clock cycle
    // with a fixed latency after accepting the arguments.
    //
    // 2. Your solution should instantiate exactly 3 instances
    // of a pipelined isqrt module, which computes the integer square root.
    //
    // 3. Your solution should save dynamic power by properly connecting
    // the valid bits.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

    logic [31:0] a_res;
    logic [31:0] b_res;
    logic [31:0] c_res;

    //сдвиговый регистр для b
    logic [31:0] b_shift [0:15];
    always_ff @(posedge clk)
    begin
      b_shift[0] <= b;
      for(int i = 1; i < 16; i ++)
	b_shift[i] <= b_shift[i - 1];
    end

    //сдвиговый регистр для a
    logic [31:0] a_shift [0:32];
    always_ff @(posedge clk)
    begin
      a_shift[0] <= a;
      for(int i = 1; i < 33; i ++)
	a_shift[i] <= a_shift[i - 1];
    end

    //регистр для флага действительных данных корня c
    logic c_vld;
    logic c_vld_ff;
    always_ff @(posedge clk)
      if(rst)
	c_vld_ff <= 1'b0;
      else
	c_vld_ff <= c_vld;

    //регистр для флага действительных данных корня -_/(b + -_/c)
    logic b_vld;
    logic b_vld_ff;
    always_ff @(posedge clk)
      if(rst)
	b_vld_ff <= 1'b0;
      else
	b_vld_ff <= b_vld;

    //регистр для суммы b + -_/c
    logic [31:0] bc_sum;
    always_ff @(posedge clk)
      if(c_vld)
	bc_sum <= c_res + b_shift[15];

    //регистр для суммы a + -_/(b + -_/c)
    logic [31:0] abc_sum;
    always_ff @(posedge clk)
      if(b_vld)
	abc_sum <= b_res + a_shift[32];

    //подключение регистров к модулям
    isqrt i1(.clk(clk), .rst(rst), .x_vld(arg_vld),  .x(c),       .y_vld(c_vld), .y(c_res));
    isqrt i2(.clk(clk), .rst(rst), .x_vld(c_vld_ff), .x(bc_sum),  .y_vld(b_vld), .y(b_res));
    isqrt i3(.clk(clk), .rst(rst), .x_vld(b_vld_ff), .x(abc_sum), .y_vld(a_vld), .y(a_res));

    assign res = a_res;
    assign res_vld = a_vld;

endmodule
