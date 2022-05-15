/* controller.v
 * 
 * Read instruction when en_i is high, write control signals for BRAM, SuperBRAM
 * and DSP out.
 */
`define IDLE 2'h0
`define RD   2'h1
`define PROC 2'h2
`define WB   2'h3

module controller (
  input  clk_i,
  input  rst_ni,
  input  en_i,
  output busy_o,
  output valid_o,

  // Input instruction
  input [31:0] ins_i,

  // BRAM control interface
  output reg [9:0] bram_addrb,
  output reg       bram_enb,

  // SuperBRAM control interface
  output reg [9:0] super_bram_addrb,
  output reg [3:0] super_bram_web,
  output reg       super_bram_enb,

  // DSP control interface
  output reg [3:0] dsp_alumode_o,
  output reg [6:0] dsp_opmode_o,
  output reg [4:0] dsp_inmode_o
);

endmodule
