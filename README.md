# AXI_protocol_systemverilog

AXI Master–Slave RTL in SystemVerilog
A hands-on SystemVerilog project exploring AXI-style master and slave designs through four progressively developed versions. The examples introduce channel handshakes, read and write transactions, burst transfers, concurrent paths, transaction queues, IDs, and simulation testbenches.

Project overview
The repository is organized as a progression of designs. Each version includes a master, a slave, and a testbench so the RTL and its behavior can be explored together.

Topics covered include:

AXI write address, write data, write response, read address, and read data channels
VALID/READY handshakes
Single-beat and burst transactions
Fixed and incrementing burst behavior
Independent read and write control paths
Request and outstanding-transaction queues
Transaction IDs and parameterized widths in the later design
Memory-backed slave models and simulation testbenches
Design progression
v1 — Initial FSM flow
A compact write-then-read example using a basic master state machine and a memory-backed slave. The testbench checks the returned data for the demonstration transaction.

v2 — Independent read and write paths
Separate read and write state machines allow read and write activity to progress independently. This version introduces burst lengths, fixed and incrementing burst experiments, and concurrent request stimulus.

v3 — Concurrent, queued transactions
The master and slave are extended with transaction queues and separate read/write paths. The testbench exercises independent operations, concurrent traffic, and multiple queued requests.

v4 — Parameterized AXI4-style design
A more configurable master/slave example with parameterized address, data, ID, and strobe widths. It includes request queues, transaction IDs, byte strobes, burst transfers, user-side request/response signals, and a self-checking testbench.

Repository contents
Each version folder contains the corresponding RTL and testbench files:

AXI_master_v1.sv, AXI_slave_v1.sv, AXI_tb_v1.sv
AXI_master_v2.sv, AXI_slave_v2.sv, AXI_tb_v2.sv
AXI_master_v3.sv, AXI_slave_v3.sv, AXI_tb_v3.sv
AXI_master_v4.sv, AXI_slave_v4.sv, AXI_tb_v4.sv
The testbench top modules are:

Version	Testbench top
v1	axi_testbench
v2	tb_axi_concurrent
v3	tb_axi
v4	axi4_tb
Running a simulation
Use a SystemVerilog-capable simulator, such as Icarus Verilog, Questa/ModelSim, or Verilator. Compile a version's master, slave, and testbench together. The general Icarus Verilog command format is:

Shell

iverilog -g2012 -s <testbench_top> -o sim_out \
  <master_file>.sv <slave_file>.sv <testbench_file>.sv
vvp sim_out
For example, for v1:

Shell

iverilog -g2012 -s axi_testbench -o sim_v1 \
  <path-to-v1>/AXI_master_v1.sv \
  <path-to-v1>/AXI_slave_v1.sv \
  <path-to-v1>/AXI_tb_v1.sv
vvp sim_v1
The v1–v3 examples reuse module names, so compile one version at a time. Replace <path-to-v1> with the actual v1 folder name in your repository.

Learning goals
This project is intended as a practical reference for studying how a design can grow from a small FSM-based transaction into more structured read/write engines with bursts, queues, and IDs. The versions and testbenches can be used to experiment with RTL organization, handshake timing, burst sequencing, and simulation-based verification.
