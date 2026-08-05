from pathlib import Path
from cocotb_tools.runner import get_runner
import os

def tb_runner(mod):
    sim=os.getenv("SIM","verilator")
    path=Path(__file__).resolve().parent.parent
    srcs=[path/f"src/{mod}.sv"]
    runner=get_runner(sim)
    runner.build(hdl_toplevel=f"{mod}",sources=srcs,build_args=["-Wno-UNOPTFLAT"])
    
    test_dir = path / "tb"
    runner.test(
        hdl_toplevel=f"{mod}",
        test_module=f'{mod}_test',
        test_dir=str(test_dir),
        extra_env={"PYTHONPATH": str(test_dir)},
    )
    
if __name__=="__main__":
    import sys
    mod = sys.argv[1] if len(sys.argv) > 1 else 'core'
    tb_runner(mod)