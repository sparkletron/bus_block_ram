//******************************************************************************
// file:    tb_axi_lite_slave.v
//
// author:  JAY CONVERTINO
//
// date:    2025/01/17
//
// about:   Brief
// Test bench for axi lite slave
//
// license: License MIT
// Copyright 2025 Jay Convertino
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
 * Module: tb_axi_lite_slave
 *
 * Test bench for axi lite slave
 *
 */
module tb_axi_lite_slave ();

  integer write_address = 0;
  integer read_address  = 0;
  
  reg             tb_data_clk = 0;
  reg             tb_rstn = 0;

  reg             tb_s_axi_awvalid;
  reg    [31:0]   tb_s_axi_awaddr;
  reg    [ 2:0]   tb_s_axi_awprot;
  wire            tb_s_axi_awready;
  reg             tb_s_axi_wvalid;
  reg    [31:0]   tb_s_axi_wdata;
  reg    [ 3:0]   tb_s_axi_wstrb;
  wire            tb_s_axi_wready;
  wire            tb_s_axi_bvalid;
  wire   [ 1:0]   tb_s_axi_bresp;
  reg             tb_s_axi_bready;
  reg             tb_s_axi_arvalid;
  reg    [31:0]   tb_s_axi_araddr;
  reg    [ 2:0]   tb_s_axi_arprot;
  wire            tb_s_axi_arready;
  wire            tb_s_axi_rvalid;
  wire   [31:0]   tb_s_axi_rdata;
  wire   [ 1:0]   tb_s_axi_rresp;
  reg             tb_s_axi_rready;


  //1ns
  localparam CLK_PERIOD = 20;

  localparam RST_PERIOD = 500;

  // Module: axi_lite_block_ram
  //
  // Module instance of axi_lite_block_ram
  axi_lite_block_ram #(
    .ADDRESS_WIDTH(32),
    .BUS_WIDTH(4),
    .DEPTH(256)
  ) dut (
    .aclk(tb_data_clk),
    .arstn(tb_rstn),
    .s_axi_awvalid(tb_s_axi_awvalid),
    .s_axi_awaddr(tb_s_axi_awaddr),
    .s_axi_awprot(tb_s_axi_awprot),
    .s_axi_awready(tb_s_axi_awready),
    .s_axi_wvalid(tb_s_axi_wvalid),
    .s_axi_wdata(tb_s_axi_wdata),
    .s_axi_wstrb(tb_s_axi_wstrb),
    .s_axi_wready(tb_s_axi_wready),
    .s_axi_bvalid(tb_s_axi_bvalid),
    .s_axi_bresp(tb_s_axi_bresp),
    .s_axi_bready(tb_s_axi_bready),
    .s_axi_arvalid(tb_s_axi_arvalid),
    .s_axi_araddr(tb_s_axi_araddr),
    .s_axi_arprot(tb_s_axi_arprot),
    .s_axi_arready(tb_s_axi_arready),
    .s_axi_rvalid(tb_s_axi_rvalid),
    .s_axi_rdata(tb_s_axi_rdata),
    .s_axi_rresp(tb_s_axi_rresp),
    .s_axi_rready(tb_s_axi_rready)
  );
  
  //axis clock
  always
  begin
    tb_data_clk <= ~tb_data_clk;
    
    #(CLK_PERIOD/2);
  end
  
  //reset
  initial
  begin
    tb_rstn <= 1'b0;
    
    #RST_PERIOD;
    
    tb_rstn <= 1'b1;
  end
  
  //copy pasta, fst generation
  initial
  begin
    $dumpfile("tb_axi_lite_slave.fst");
    $dumpvars(0,tb_axi_lite_slave);
  end

  //axi lite
  always @(posedge tb_data_clk)
  begin
    if(!tb_rstn)
    begin
      tb_s_axi_awvalid <= 1'b0;
      tb_s_axi_awaddr  <= 0;
      tb_s_axi_awprot  <= 0;

      tb_s_axi_wvalid  <= 1'b0;
      tb_s_axi_wdata   <= 0;
      tb_s_axi_wstrb   <= 0;

      tb_s_axi_bready  <= 1'b0;

      tb_s_axi_arvalid <= 1'b0;
      tb_s_axi_araddr  <= 0;
      tb_s_axi_arprot  <= 0;

      tb_s_axi_rready  <= 1'b0;
    end else begin
      tb_s_axi_bready   <= 1'b0;
      tb_s_axi_awvalid  <= 1'b0;
      tb_s_axi_awaddr   <= 0;
      tb_s_axi_awprot   <= 0;
      tb_s_axi_wvalid   <= 1'b0;
      tb_s_axi_wstrb    <= 0;

      //setup write write_address
      if(write_address < 256)
      begin
        tb_s_axi_bready  <= 1'b1;

        tb_s_axi_awvalid <= 1'b1;
        tb_s_axi_awaddr  <= write_address;
        tb_s_axi_awprot  <= 3'b010;

        tb_s_axi_wvalid  <= 1'b1;
        tb_s_axi_wdata   <= write_address;
        tb_s_axi_wstrb   <= ~0;

        if(tb_s_axi_bvalid)
        begin
          if(tb_s_axi_bresp == 2'b00)
          begin
            write_address <= write_address + 4;
          end
        end
      end else if(read_address < 256) begin
        tb_s_axi_arvalid <= 1'b1;
        tb_s_axi_araddr  <= read_address;
        tb_s_axi_arprot  <= 3'b010;

        tb_s_axi_rready  <= 1'b1;

        if(tb_s_axi_arready)
        begin
          read_address <= read_address + 4;
        end
      end else begin
        $finish();
      end
    end
  end

endmodule
