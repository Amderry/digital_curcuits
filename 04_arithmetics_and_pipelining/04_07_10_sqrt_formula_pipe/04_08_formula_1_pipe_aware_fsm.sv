//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe_aware_fsm
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    // isqrt interface

    output logic        isqrt_x_vld,
    output logic [31:0] isqrt_x,

    input               isqrt_y_vld,
    input        [15:0] isqrt_y
);
    // Task:
    //
    // Implement a module formula_1_pipe_aware_fsm
    // with a Finite State Machine (FSM)
    // that drives the inputs and consumes the outputs
    // of a single pipelined module isqrt.
    //
    // The formula_1_pipe_aware_fsm module is supposed to be instantiated
    // inside the module formula_1_pipe_aware_fsm_top,
    // together with a single instance of isqrt.
    //
    // The resulting structure has to compute the formula
    // defined in the file formula_1_fn.svh.
    //
    // The formula_1_pipe_aware_fsm module
    // should NOT create any instances of isqrt module,
    // it should only use the input and output ports connecting
    // to the instance of isqrt at higher level of the instance hierarchy.
    //
    // All the datapath computations except the square root calculation,
    // should be implemented inside formula_1_pipe_aware_fsm module.
    // So this module is not a state machine only, it is a combination
    // of an FSM with a datapath for additions and the intermediate data
    // registers.
    //
    // Note that the module formula_1_pipe_aware_fsm is NOT pipelined itself.
    // It should be able to accept new arguments a, b and c
    // arriving at every N+3 clock cycles.
    //
    // In order to achieve this latency the FSM is supposed to use the fact
    // that isqrt is a pipelined module.
    //
    // For more details, see the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

    typedef enum bit [3:0]
    {
      ST_IDLE   = 4'd0,
      ST_A      = 4'd1,
      ST_B      = 4'd2,
      ST_C      = 4'd3,
      ST_WAIT   = 4'd4,
      ST_RES_A  = 4'd5,
      ST_RES_B  = 4'd6,
      ST_RES_C  = 4'd7,
      ST_DONE   = 4'd8
    } state_e;

    state_e state, next_state;
    logic [31:0] result;

    always_ff @(posedge clk)
      if(rst)
	state <= ST_IDLE;
      else
	state <= next_state;

    always_comb
    begin
      next_state = state;
      case(state)
	ST_IDLE: if(arg_vld)      next_state = ST_A;
	ST_A:                     next_state = ST_B;
	ST_B:                     next_state = ST_C;
	ST_C:                     next_state = ST_WAIT;
	ST_WAIT: if(isqrt_y_vld)  next_state = ST_RES_A;
	ST_RES_A:		  next_state = ST_RES_B;
	ST_RES_B:                 next_state = ST_RES_C;
	ST_RES_C:                 next_state = ST_DONE;
	ST_DONE:                  next_state = ST_IDLE;
      endcase
    end

    always_comb
      case(state)
	ST_IDLE:
	begin
	  res_vld = 1'b0;
	end
	ST_A: 
        begin
	  isqrt_x = a;
	  isqrt_x_vld = 1'b1;
	end
	ST_B:
	begin
	  isqrt_x = b;
	  isqrt_x_vld = 1'b1;
	end
	ST_C:
	begin
	  isqrt_x = c;
	  isqrt_x_vld = 1'b1;
	end
	ST_WAIT:
	begin
	  isqrt_x_vld = 1'b0;
	end
	ST_DONE:
	begin
	  res = result;
	  res_vld = 1'b1;
	end
      endcase

    //Накопление результата
    always_ff @(posedge clk)
      if(arg_vld)
	result <= 32'd0;
      else if(isqrt_y_vld)
	result <= result + isqrt_y;
	

endmodule
