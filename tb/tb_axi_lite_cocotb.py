#******************************************************************************
# file:    tb_axi_lite_cocotb.py
#
# author:  JAY CONVERTINO
#
# date:    2024/12/09
#
# about:   Brief
# Cocotb test bench
#
# license: License MIT
# Copyright 2024 Jay Convertino
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#
#******************************************************************************

import random
import itertools

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer, Event
from cocotb.binary import BinaryValue
from cocotbext.axi import (AxiLiteBus, AxiLiteMaster)

# Function: random_bool
# Return a infinte cycle of random bools
#
# Returns: List
def random_bool():
  temp = []

  for x in range(0, 256):
    temp.append(bool(random.getrandbits(1)))

  return itertools.cycle(temp)

# Function: start_clock
# Start the simulation clock generator.
#
# Parameters:
#   dut - Device under test passed from cocotb test function
def start_clock(dut):
  cocotb.start_soon(Clock(dut.aclk, 2, units="ns").start())

# Function: reset_dut
# Cocotb coroutine for resets, used with await to make sure system is reset.
async def reset_dut(dut):
  dut.arstn.value = 0
  await Timer(5, units="ns")
  dut.arstn.value = 1

# Function: single_word
# Coroutine that is identified as a test routine. This routine tests for writing a single word, and
# then reading a single word.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def single_word(dut):

    start_clock(dut)

    axi_lite_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"), dut.aclk, dut.arstn, False)

    await reset_dut(dut)

    for x in range(0, dut.DEPTH.value):
        data = x.to_bytes(length = 1, byteorder='little') * dut.BUS_WIDTH.value
        await axi_lite_master.write(x, data)

        read_response = await axi_lite_master.read(x, dut.BUS_WIDTH.value)

        assert read_response.data == data, "Input data does not match read data"

    await RisingEdge(dut.aclk)

    assert dut.s_axi_awready.value.integer == 0, "s_axi_awready is 0!"
    assert dut.s_axi_wready.value.integer == 0, "s_axi_wready is 0!"
    assert dut.s_axi_arready.value.integer == 0, "s_axi_arready is 0!"

# Function: bulk_test
# Coroutine that is identified as a test routine. This routine tests streaming data to the axi lite device.
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def bulk_test(dut):

    start_clock(dut)

    axi_lite_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"), dut.aclk, dut.arstn, False)

    await reset_dut(dut)

    for x in range(0, dut.DEPTH.value):

        data = x.to_bytes(length = 1, byteorder='little') * ((dut.BUS_WIDTH.value * (dut.DEPTH.value - x)))
        await axi_lite_master.write(x, data)

        read_response = await axi_lite_master.read(x, ((dut.BUS_WIDTH.value * (dut.DEPTH.value - x))))

        assert read_response.data == data

    await RisingEdge(dut.aclk)

    assert dut.s_axi_awready.value.integer == 0, "s_axi_awready is 0!"
    assert dut.s_axi_wready.value.integer == 0, "s_axi_wready is 0!"
    assert dut.s_axi_arready.value.integer == 0, "s_axi_arready is 0!"

# Function: random_ready_bulk
# Coroutine that is identified as a test routine. This routine tests streaming data to the axi lite device with random ready.
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def random_ready_bulk(dut):

    start_clock(dut)

    axi_lite_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"), dut.aclk, dut.arstn, False)

    axi_lite_master.write_if.aw_channel.set_pause_generator(random_bool())
    axi_lite_master.write_if.w_channel.set_pause_generator(random_bool())
    axi_lite_master.write_if.b_channel.set_pause_generator(random_bool())
    axi_lite_master.read_if.ar_channel.set_pause_generator(random_bool())
    axi_lite_master.read_if.r_channel.set_pause_generator(random_bool())

    await reset_dut(dut)

    for x in range(0, dut.DEPTH.value):

        data = x.to_bytes(length = 1, byteorder='little') * ((dut.BUS_WIDTH.value * (dut.DEPTH.value - x)))
        await axi_lite_master.write(x, data)

        read_response = await axi_lite_master.read(x, ((dut.BUS_WIDTH.value * (dut.DEPTH.value - x))))

        assert read_response.data == data

    await RisingEdge(dut.aclk)

    assert dut.s_axi_awready.value.integer == 0, "s_axi_awready is 0!"
    assert dut.s_axi_wready.value.integer == 0, "s_axi_wready is 0!"
    assert dut.s_axi_arready.value.integer == 0, "s_axi_arready is 0!"

# Function: in_reset
# Coroutine that is identified as a test routine. This routine tests if device stays
# in unready state when in reset.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def in_reset(dut):

    start_clock(dut)

    dut.arstn.value = 0

    await Timer(10, units="ns")

    assert dut.s_axi_awready.value.integer == 0, "s_axi_awready is 1!"
    assert dut.s_axi_wready.value.integer == 0, "s_axi_wready is 1!"
    assert dut.s_axi_arready.value.integer == 0, "s_axi_arready is 1!"

# Function: no_clock
# Coroutine that is identified as a test routine. This routine tests if no ready when clock is lost
# and device is left in reset.
#
# Parameters:
#   dut - Device under test passed from cocotb.
@cocotb.test()
async def no_clock(dut):

    dut.arstn.value = 0

    dut.aclk.value = 0

    await Timer(5, units="ns")

    assert dut.s_axi_awready.value.integer == 0, "s_axi_awready is 1!"
    assert dut.s_axi_wready.value.integer == 0, "s_axi_wready is 1!"
    assert dut.s_axi_arready.value.integer == 0, "s_axi_arready is 1!"
