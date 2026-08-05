import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


def ref_edges(thread_count, tpb, blocks):
    """Model the controller edge-by-edge with completed=all-ones.

    Mirrors the RTL exactly:
      - once block_counter == total_blocks, done is asserted on the next edge
      - otherwise the free slots are filled with consecutive block ids
    Returns a list of (en, blk_id, threads, done) per edge.
    """
    total_blocks = -(-thread_count // tpb)  # ceil
    block_counter = 0
    edges = []

    while True:
        if block_counter == total_blocks:
            edges.append(([0] * blocks, [0] * blocks, [0] * blocks, 1))
            break

        blocks_requested = 0
        en = []
        blk_id = []
        threads = []
        for i in range(blocks):
            if block_counter + blocks_requested < total_blocks:
                en.append(1)
                blk_id.append(block_counter + blocks_requested)
                blocks_requested += 1
                idx = block_counter + blocks_requested - 1
                threads.append(
                    thread_count - (total_blocks - 1) * tpb
                    if idx + 1 == total_blocks
                    else tpb
                )
            else:
                en.append(0)
                blk_id.append(0)
                threads.append(0)
        block_counter += blocks_requested
        edges.append((en, blk_id, threads, 0))

    return edges


def en_bit(val, i):
    return (int(val) >> i) & 1


async def setup(dut, thread_count):
    """Clock + reset, then configure thread_count; one settle edge follows."""
    cocotb.start_soon(Clock(dut.clk, 10, 'ns').start())
    dut.rst_n.value = 0
    dut.thread_count.value = thread_count
    dut.completed.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


async def settle(dut, completed):
    """Assert all slots free and wait the controller's one-cycle latency."""
    dut.completed.value = completed
    await RisingEdge(dut.clk)


@cocotb.test()
async def test_reset_clears_outputs(dut):
    """After reset all enables/ids/thread-counts are zero and done is low."""
    await setup(dut, 0)
    dut.completed.value = 0
    await RisingEdge(dut.clk)

    for i in range(int(dut.BLOCKS.value)):
        assert en_bit(dut.block_en.value, i) == 0, f"block_en[{i}] not cleared"
        assert dut.block_id[i].value == 0, f"block_id[{i}] not cleared"
        assert dut.total_threads_per_block[i].value == 0, \
            f"total_threads_per_block[{i}] not cleared"
    assert dut.done.value == 0, "done should be low after reset"


@cocotb.test()
async def test_no_threads_done_immediately(dut):
    """With thread_count=0 the controller finishes with no blocks issued."""
    await setup(dut, 0)
    await settle(dut, (1 << int(dut.BLOCKS.value)) - 1)
    await RisingEdge(dut.clk)  # processing edge where done is asserted

    assert dut.done.value == 1, "done should be high when no blocks remain"
    for i in range(int(dut.BLOCKS.value)):
        assert en_bit(dut.block_en.value, i) == 0, "no block should be enabled"


@cocotb.test()
async def test_exact_multiple_of_threads(dut):
    """thread_count == THREADS_PER_BLOCK*BLOCKS fills every block in one shot."""
    tpb = int(dut.THREADS_PER_BLOCK.value)
    blocks = int(dut.BLOCKS.value)
    thread_count = tpb * blocks

    await setup(dut, thread_count)
    await settle(dut, (1 << blocks) - 1)
    await RisingEdge(dut.clk)

    for i in range(blocks):
        assert en_bit(dut.block_en.value, i) == 1, f"block_en[{i}] should be enabled"
        assert dut.block_id[i].value == i, f"block_id[{i}] should be {i}"
        assert dut.total_threads_per_block[i].value == tpb, \
            f"total_threads_per_block[{i}] should be full"


@cocotb.test()
async def test_partial_last_block(dut):
    """Partial last block carries only the remainder threads."""
    tpb = int(dut.THREADS_PER_BLOCK.value)
    blocks = int(dut.BLOCKS.value)
    remainder = tpb - 2
    thread_count = tpb * (blocks - 1) + remainder

    await setup(dut, thread_count)
    await settle(dut, (1 << blocks) - 1)
    await RisingEdge(dut.clk)

    for i in range(blocks - 1):
        assert dut.total_threads_per_block[i].value == tpb, \
            f"block {i} should be full, got {dut.total_threads_per_block[i].value}"
    assert dut.total_threads_per_block[blocks - 1].value == remainder, \
        "last block should hold the remainder threads"


@cocotb.test()
async def test_full_schedule_matches_reference(dut):
    """Drive completed=all-ones and verify every edge against the reference."""
    tpb = int(dut.THREADS_PER_BLOCK.value)
    blocks = int(dut.BLOCKS.value)
    thread_count = tpb * 3 + 2  # 4 blocks, last one partial

    await setup(dut, thread_count)
    await settle(dut, (1 << blocks) - 1)

    ref = ref_edges(thread_count, tpb, blocks)
    assert len(ref) > 1, "reference should span multiple edges"

    for edge, (exp_en, exp_id, exp_t, exp_done) in enumerate(ref):
        await RisingEdge(dut.clk)
        for i in range(blocks):
            got_en = en_bit(dut.block_en.value, i)
            assert got_en == exp_en[i], \
                f"edge {edge} block_en[{i}]: got {got_en} exp {exp_en[i]}"
            if exp_en[i]:
                assert dut.block_id[i].value == exp_id[i], \
                    f"edge {edge} block_id[{i}]: got {dut.block_id[i].value} exp {exp_id[i]}"
                assert dut.total_threads_per_block[i].value == exp_t[i], \
                    f"edge {edge} threads[{i}]: got {dut.total_threads_per_block[i].value} exp {exp_t[i]}"
        assert dut.done.value == exp_done, \
            f"edge {edge}: done got {dut.done.value} exp {exp_done}"