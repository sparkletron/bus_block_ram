//******************************************************************************
//  file:     wishbone_classic_block_ram.v
//
//  author:   JAY CONVERTINO
//
//  date:     2024/03/07
//
//  about:    Brief
//  Wishbone classic block RAM core.
//
//  license: License MIT
//  Copyright 2024 Jay Convertino
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//******************************************************************************

`timescale 1ns/100ps

/*
 * Module: wishbone_classic_block_ram
 *
 * Wishbone classic block RAM core.
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
module wishbone_classic_block_ram #(
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

  `include "util_helper_math.vh"

  // var: c_PWR_RAM
  // power of 2 conversion of DEPTH
  localparam c_PWR_RAM  = clogb2(DEPTH);
  // var: c_RAM_DEPTH
  // create RAM depth based on power of two depth size.
  localparam c_RAM_DEPTH = 2 ** c_PWR_RAM;

  // var: up_rreq
  // uP read bus request
  wire                      up_rreq;
  // var: up_rack
  // uP read bus acknowledge
  reg                       up_rack;
  // var: up_raddr
  // uP read bus address
  wire  [ADDRESS_WIDTH-(ADDRESS_WIDTH/16)-1:0] up_raddr;
  // var: up_rdata
  // uP read bus request
  wire  [(BUS_WIDTH*4)-1:0] up_rdata;

  // var: up_wreq
  // uP write bus request
  wire                      up_wreq;
  // var: up_wack
  // uP write bus acknowledge
  reg                       up_wack;
  // var: up_waddr
  // uP write bus address
  wire  [ADDRESS_WIDTH-(ADDRESS_WIDTH/16)-1:0] up_waddr;
  // var: up_wdata
  // uP write bus data
  wire  [(BUS_WIDTH*4)-1:0] up_wdata;

  //Group: Instantianted Modules

  // Module: inst_up_wishbone_classic
  //
  // Module instance of up_wishbone_classic for the Wishbone Classic bus to the uP bus.
  up_wishbone_classic #(
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .BUS_WIDTH(BUS_WIDTH)
  ) inst_up_wishbone_classic (
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
    .s_wb_data_o(s_wb_data_o),
    .s_wb_err(s_wb_err),
    .up_rreq(up_rreq),
    .up_rack(up_rack),
    .up_raddr(up_raddr),
    .up_rdata(up_rdata),
    .up_wreq(up_wreq),
    .up_wack(up_wack),
    .up_waddr(up_waddr),
    .up_wdata(up_wdata)
  );

  // Module: inst_dc_block_ram
  //
  // Module instance of dc_block_ram that connects to the uP BUS directly.
  dc_block_ram #(
    .RAM_DEPTH(c_RAM_DEPTH),
    .BYTE_WIDTH(BUS_WIDTH),
    .ADDR_WIDTH(c_PWR_RAM),
    .HEX_FILE(HEX_FILE),
    .RAM_TYPE(RAM_TYPE)
  ) inst_dc_block_ram (
    .rd_clk(clk),
    .rd_rstn(~rst),
    .rd_en(up_rreq),
    .rd_data(up_rdata),
    .rd_addr(up_raddr[c_PWR_RAM-1:0]),
    .wr_clk(clk),
    .wr_rstn(~rst),
    .wr_en(up_wreq),
    .wr_ben(s_wb_sel),
    .wr_data(up_wdata),
    .wr_addr(up_waddr[c_PWR_RAM-1:0])
  );

  // register reqest to the ack since it will always happen, even if the RAM address is invalid.
  always @(posedge clk)
  begin
    if(rst)
    begin
      up_wack <= 1'b0;
      up_rack <= 1'b0;
    end else begin
      up_wack <= up_wreq;
      up_rack <= up_rreq;
    end
  end

endmodule
