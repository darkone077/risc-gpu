import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

RET_INSTR = 0x0000100f


@cocotb.test()
async def test_core_no_threads(dut):
    """core_done goes high immediately when no threads are enabled."""
    cocotb.start_soon(Clock(dut.clk, 10, 'ns').start())
    dut.rst_n.value = 0
    dut.thread_count.value = 0
    dut.blk_id.value = 0
    dut.inst_valid.value = 0b1111
    dut.data_valid.value = 0b1111
    for i in range(4):
        dut.read_data[i].value = 0
        dut.inst[i].value = 0

    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    assert dut.core_done.value == 1, "core_done should be 1 with thread_count=0"


@cocotb.test()
async def test_core_one_thread(dut):
    """One thread executes RET and core_done goes high."""
    cocotb.start_soon(Clock(dut.clk, 10, 'ns').start())
    dut.rst_n.value = 0
    dut.thread_count.value = 1
    dut.blk_id.value = 0
    dut.inst_valid.value = 0b1111
    dut.data_valid.value = 0b1111
    for i in range(4):
        dut.read_data[i].value = 0
        dut.inst[i].value = 0
    dut.inst[0].value = RET_INSTR  # Pre-load instruction

    await ClockCycles(dut.clk, 3)  # Let reset settle
    dut.rst_n.value = 1           # Release reset

    # Pipeline should execute RET in ~5 cycles
    for _ in range(50):
        await RisingEdge(dut.clk)
        if dut.core_done.value == 1:
            break

    assert dut.core_done.value == 1, "core_done never went high"


@cocotb.test()
async def test_core_all_threads(dut):
    """All 4 threads execute RET and core_done goes high."""
    cocotb.start_soon(Clock(dut.clk, 10, 'ns').start())
    dut.rst_n.value = 0
    dut.thread_count.value = 4
    dut.blk_id.value = 0
    dut.inst_valid.value = 0b1111
    dut.data_valid.value = 0b1111
    for i in range(4):
        dut.read_data[i].value = 0
        dut.inst[i].value = RET_INSTR  # Pre-load all threads

    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1

    for _ in range(100):
        await RisingEdge(dut.clk)
        if dut.core_done.value == 1:
            break

    assert dut.core_done.value == 1, "core_done never went high"


@cocotb.test()
async def test_core_partial_threads(dut):
    """Only threads 0-1 enabled; core_done completes when both finish."""
    cocotb.start_soon(Clock(dut.clk, 10, 'ns').start())
    dut.rst_n.value = 0
    dut.thread_count.value = 2
    dut.blk_id.value = 0
    dut.inst_valid.value = 0b1111
    dut.data_valid.value = 0b1111
    for i in range(4):
        dut.read_data[i].value = 0
        dut.inst[i].value = RET_INSTR if i < 2 else 0

    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1

    for _ in range(100):
        await RisingEdge(dut.clk)
        if dut.core_done.value == 1:
            break

    assert dut.core_done.value == 1, "core_done never went high"