/* controller.v
 * 
 * Read instruction when en_i is high, write control signals for BRAM, SuperBRAM
 * and DSP out.
 */
`define IDLE 3'h0
`define RD   3'h1
`define PROC 3'h2
`define WB   3'h3
`define DONE 3'h4

`define BRAM_RDADDR       4:0
`define SUPER_BRAM_RDADDR 9:5
`define SUPER_BRAM_WRADDR 14:10
`define DSP_INMODE        19:15
`define DSP_OPMODE        26:20
`define DSP_ALUMODE       30:27
`define EXECUTE           31

module controller #(
  DSPLatency = 3  // may be 3 or 4, can tune later on by modifying this
) (
  input  clk_i,
  input  rst_ni,
  input  en_i,
  output busy_o,
  output valid_o,

  // Input instruction
  input [31:0] ins_i,

  // BRAM control interface
  output reg [9:0] bram_addrb_o,
  output reg       bram_enb_o,

  // SuperBRAM control interface
  output reg [9:0] super_bram_addrb_o,
  output reg [3:0] super_bram_web_o,
  output reg       super_bram_enb_o,

  // DSP control interface
  output reg [3:0] dsp_alumode_o,
  output reg [6:0] dsp_opmode_o,
  output reg [4:0] dsp_inmode_o
);

  reg [30:0] ins_buf;

  reg [2:0] state_q, state_d;
  reg [1:0] proc_cnt_q, proc_cnt_d;

  assign busy_o  = state_q != `IDLE;
  assign valid_o = state_q == `DONE;

  /* Input buffer */
  always @(posedge clk_i) begin
    if (!rst_ni) begin
      ins_buf <= 31'd0;
    end else begin
      if (state_q == `IDLE && en_i) begin
        ins_buf <= ins_i[30:0];
      end
    end
  end

  /* State machine */
  always @(posedge clk_i) begin
    if (!rst_ni) begin
      state_q <= `IDLE;
    end else begin
      state_q <= state_d;
    end
  end

  always @(*) begin
    case (state_q)
      `IDLE:
        if (en_i) begin  
          if (ins_i[`EXECUTE]) begin
            state_d = `RD;
          end else begin
            state_d = `DONE;  // instruction doesn't need to be executed
          end
        end else begin
          state_d = `IDLE;
        end
      `RD:
        state_d = `PROC;
      `PROC:
        if (proc_cnt_q == DSPLatency - 1) begin
          state_d = `WB;
        end else begin
          state_d = `PROC;
        end
      `WB:
        state_d = `DONE;
      `DONE:
        state_d = `IDLE;
      default:
        state_d = `IDLE;
    endcase
  end

  /* Process counter */
  always @(posedge clk_i) begin
    if (!rst_ni) begin
      proc_cnt_q <= 2'd0;
    end else begin
      proc_cnt_q <= proc_cnt_d;
    end
  end

  always @(*) begin
    if (state_q == `PROC) begin
      if (proc_cnt_q == DSPLatency - 1) begin
        proc_cnt_d = 2'd0;
      end else begin
        proc_cnt_d = proc_cnt_q + 2'd1;
      end
    end else begin
      proc_cnt_d = 2'd0;
    end
  end

  /* BRAM control signals */
  always @(*) begin
    if (state_q == `RD) begin
      bram_addrb_o = {5'd0, ins_buf[`BRAM_RDADDR]};
      bram_enb_o   = 1'b1;
    end else begin
      bram_addrb_o = 10'd0;
      bram_enb_o   = 1'b0;
    end
  end

  /* DSP control signals */
  always @(*) begin
    if (state_q == `PROC) begin
      dsp_inmode_o  = ins_buf[`DSP_INMODE];
      dsp_opmode_o  = ins_buf[`DSP_OPMODE];
      dsp_alumode_o = ins_buf[`DSP_ALUMODE];
    end else begin
      dsp_inmode_o  = 5'd0;
      dsp_opmode_o  = 7'd0;
      dsp_alumode_o = 4'd0;
    end
  end

  /* SuperBRAM control signals */
  always @(*) begin
    if (state_q == `RD) begin
      super_bram_addrb_o = {5'd0, ins_buf[`SUPER_BRAM_RDADDR]};
      super_bram_web_o   = 4'h0;
      super_bram_enb_o   = 1'b1;
    end else if (state_q == `WB) begin
      super_bram_addrb_o = {5'd0, ins_buf[`SUPER_BRAM_WRADDR]};
      super_bram_web_o   = 4'hf;
      super_bram_enb_o   = 1'b0;
    end else begin
      super_bram_addrb_o = 10'd0;
      super_bram_web_o   = 4'h0;
      super_bram_enb_o   = 1'b0;
    end
  end

endmodule
