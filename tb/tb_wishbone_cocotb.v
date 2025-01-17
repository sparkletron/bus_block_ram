//******************************************************************************
// file:    tb_wishbone_cocotb.v
//
// author:  JAY CONVERTINO
//
// date:    2024/12/10
//
// about:   Brief
// Test bench wrapper for cocotb
//
// license: License MIT
// Copyright 2024 Jay Convertino
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//
//******************************************************************************

`timescale 1ns/100ps

/*
 * Module: tb_cocotb
 *
 * Test bench for wishbone.
 *
 * Parameters:
 *
 *   ADDRESS_WIDTH   - Width of the axi address bus in bits.
 *   BUS_WIDTH       - Bus width for data paths in bytes.
 *   DEPTH           - Depth of the RAM in terms of data width words.
 *   RAM_TYPE        - Used to set the ram_style atribute.
 *   HEX_FILE        - Hex file to write to RAM.
 *
 * Ports:
 *
 *   clk            - Clock for all devices in the core
 *   rst            - Positive reset
 *   s_wb_cyc       - Bus Cycle in process
 *   s_wb_stb       - Valid data transfer cycle
 *   s_wb_we        - Active High write, low read
 *   s_wb_addr      - Bus address
 *   s_wb_data_i    - Input data
 *   s_wb_sel       - Device Select
 *   s_wb_bte       - Burst Type Extension
 *   s_wb_cti       - Cycle Type
 *   s_wb_ack       - Bus transaction terminated
 *   s_wb_data_o    - Output data
 *   s_wb_err       - Active high when a bus error is present
 */
module tb_cocotb #(
    parameter ADDRESS_WIDTH     = 32,
    parameter BUS_WIDTH         = 4,
    parameter DEPTH             = 512,
    parameter RAM_TYPE          = "block",
    parameter HEX_FILE          = ""
  )
  (
    input                       clk,
    input                       rst,
    input                       s_wb_cyc,
    input                       s_wb_stb,
    input                       s_wb_we,
    input   [ADDRESS_WIDTH-1:0] s_wb_addr,
    input   [BUS_WIDTH*8-1:0]   s_wb_data_i,
    input   [BUS_WIDTH-1:0]     s_wb_sel,
    input   [ 1:0]              s_wb_bte,
    input   [ 2:0]              s_wb_cti,
    output                      s_wb_ack,
    output  [BUS_WIDTH*8-1:0]   s_wb_data_o,
    output                      s_wb_err
  );

  // fst dump command
  initial begin
    $dumpfile ("tb_cocotb.fst");
    $dumpvars (0, tb_cocotb);
    #1;
  end

  //Group: Instantiated Modules

  /*
   * Module: dut
   *
   * Device under test, wishbone_classic_block_ram
   */
  wishbone_classic_block_ram #(
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .BUS_WIDTH(BUS_WIDTH),
    .DEPTH(DEPTH),
    .RAM_TYPE(RAM_TYPE),
    .HEX_FILE(HEX_FILE)
  ) dut (
    .clk(clk),
    .rst(rst),
    .s_wb_cyc(s_wb_cyc),
    .s_wb_stb(s_wb_stb),
    .s_wb_we(s_wb_we),
    .s_wb_addr(s_wb_addr),
    .s_wb_data_i(s_wb_data_i),
    .s_wb_sel(s_wb_sel),
    .s_wb_cti(s_wb_cti),
    .s_wb_bte(s_wb_bte),
    .s_wb_ack(s_wb_ack),
    .s_wb_data_o(s_wb_data_o)
  );
  
endmodule

