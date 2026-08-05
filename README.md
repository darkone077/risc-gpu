# risc-gpu

A SIMT-style RISC-V GPU experiment written in SystemVerilog. Threads get grouped into blocks, blocks get scheduled onto a bank of in-order RV32IM cores, and a multi-channel memory controller arbitrates their memory access. Not a product — mostly a way to figure out how far you can push a small in-order core before it becomes the bottleneck.

## Layout

- `src/main_controller.sv` — the block scheduler. Works out `ceil(thread_count / threads_per_block)` and hands out the next pending block to any slot that reports `completed`. Handles a partially-filled last block, and raises `done` once every block has been issued and finished.
- `src/core.sv` — a bank of `THREADS` RV32IM processing units plus a `scheduler` that derives `thread_en` from `thread_count`. `core_done` goes high when every enabled thread finishes.
- `src/thread.sv` — thin wrapper around the RV32IM core from `pu/in_order/`, wired up with block/thread id registers.
- `src/mem_controller.sv` — multi-channel memory arbiter with round-robin priority across requesting cores and per-channel IDLE/READ/WRITE states.
- `pu/in_order/` — a 5-stage in-order RV32IM core. It's its own thing (with its own testbench); the GPU glue around it is what this repo is really about.
- `tb/` — cocotb testbenches and `tb_runner.py`.

## How it fits together

A host sets `thread_count`. `main_controller` turns that into a grid of blocks, then watches the `completed` lines. Whenever a core finishes a block, the controller pops the next block id into that slot and updates the per-slot thread count (the last block is usually smaller than `threads_per_block`). Each core runs its threads to completion and raises `core_done`; once all blocks are issued and everything reports done, the controller raises `done`.

One quirk worth knowing: the controller has a one-cycle delay between a `completed` assertion and issuing the next block, and `done` shows up on a cycle where nothing new gets issued. The testbench just models this explicitly rather than pretending otherwise.

## Running the tests

```bash
python -m venv .venv
.venv/bin/pip install cocotb cocotb-tools
SIM=verilator .venv/bin/python -m tb.tb_runner core
SIM=verilator .venv/bin/python -m tb.tb_runner main_controller
```

Requires Verilator on the host. The testbenches are self-checking; `main_controller_test.py` compares every scheduling edge against a Python reference model.