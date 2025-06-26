# BUS Block RAM
### Create block RAM using various bus interfaces (Wishbone Classic, AXI LITE)
---

![image](docs/manual/img/AFRL.png)

---

  author: Jay Convertino  
  
  date: 2024.03.11
  
  details: Generic DC block RAM wrapped with a bus interface conversion.
  
  license: MIT   
   
  Actions:  

  [![Lint Status](../../actions/workflows/lint.yml/badge.svg)](../../actions)  
  [![Manual Status](../../actions/workflows/manual.yml/badge.svg)](../../actions)  
  
---

### Version
#### Current
  - V1.0.0 - initial

#### Previous
  - none

### DOCUMENTATION
  For detailed usage information, please navigate to one of the following sources. They are the same, just in a different format.

  - [bus_block_ram.pdf](docs/manual/bus_block_ram.pdf)
  - [github page](https://johnathan-convertino-afrl.github.io/bus_block_ram/)
  
### PARAMETERS

* ADDRESS_WIDTH : Address width of bus
* BUS_WIDTH     : Data bus width in bytes
* DEPTH         : How many words deep the RAM will be (word = BUS_WIDTH).
* HEX_FILE      : HEX text File to initialize RAM with ("" = none).
* RAM_TYPE      : Set the RAM type of the fifo.

### COMPONENTS
#### SRC

* axi_lite_block_ram.v
* wishbone_classic_block_ram.v
  
#### TB

* tb_wishbone_slave.v
* tb_axi_lite_slave.v
* tb_axi_lite_cocotb
* tb_wishbone_cocotb
  
### FUSESOC

* axi_lite_block_ram.core created for axi.
* wishbone_classic_block_ram.core create for wishbone classic.
* Simulation uses icarus to run data through the core.

#### Targets

* RUN WITH: (fusesoc run --target=sim VENDER:CORE:NAME:VERSION)
  - default (for IP integration builds)
  - lint
  - sim
  - sim_cocotb
