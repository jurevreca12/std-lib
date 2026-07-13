import os
import json
import queue
import subprocess
from pathlib import Path
from forastero.io import IORole, io_suffix_style
from forastero import BaseBench
from forastero.monitor import MonitorEvent
from forastero.driver import DriverEvent
from cocotb.triggers import ClockCycles, RisingEdge
from handshake.io import HandshakeIO
from handshake.requestor import HandshakeRequestDriver, HandshakeRequestMonitor
from handshake.responder import HandshakeResponderDriver
from handshake.sequences import handshake_ready_seq, handshake_req_seq
from handshake.transaction import HandshakeValid
from cocotb_tools.runner import get_runner

LANGUAGE = os.getenv("HDL_TOPLEVEL_LANG", "verilog").lower().strip()
WAVES = os.getenv("WAVES", default=False)
RVFI = os.getenv("RVFI", default=True)
RVFI_TRACE = os.getenv("RVFI_TRACE", default=False)
ASSERTIONS = os.getenv("ASSERTIONS", default=True)


class FifoTB(BaseBench):
    def __init__(self, dut):
        super().__init__(dut, clk=dut.clk_i, rst=dut.rstn_i, rst_active_high=False)
        inp_io = HandshakeIO(dut, 'input', IORole.RESPONDER, io_style=io_suffix_style)
        out_io = HandshakeIO(dut, 'output', IORole.INITIATOR, io_style=io_suffix_style)
        self.register(
            "inp_drv",
            HandshakeRequestDriver(self, inp_io, self.clk, self.rst, blocking=False)
        )
        self.register(
            "out_mon",
            HandshakeRequestMonitor(self, out_io, self.clk, self.rst)
        )
        self.register(
            "rsp_drv",
            HandshakeResponderDriver(self, out_io, self.clk, self.rst)
        )
        self.queue = queue.Queue()
        self.inp_drv.subscribe(DriverEvent.POST_DRIVE, self.enqueue_ref)
        self.out_mon.subscribe(MonitorEvent.CAPTURE, self.push_ref)
    
    def enqueue_ref(self, driver, event, obj):
        self.queue.put(obj)

    def push_ref(self, driver, event, obj):
        self.scoreboard.channels['out_mon'].push_reference(
            self.queue.get()
        )
    

        
    async def initialise(self) -> None:
        """Initialise the DUT's I/O"""
        self.rst.value = 0
        for comp in self._components.values():
            comp.io.initialise(IORole.opposite(comp.io.role))

    async def reset(self, init=True, wait_during=10, wait_after=1) -> None:
        """
        Reset the DUT.

        :param init:        Initialise the DUT's I/O
        :param wait_during: Clock cycles to hold reset active for (defaults to 20)
        :param wait_after:  Clock cycles to wait after lowering reset (defaults to 1)
        """
        # Drive reset high
        self.rst.value = 0
        # Initialise I/O
        if init:
            await self.initialise()
        # Wait before dropping reset
        if wait_during > 0:
            await ClockCycles(self.clk, wait_during)
        # Drop reset
        self.rst.value = 1
        # Wait for a bit
        if wait_after > 0:
            self.info(f"Waiting for {wait_after} cycles")
            await ClockCycles(self.clk, wait_after)


@FifoTB.testcase(
    reset_wait_during=2,
    reset_wait_after=0,
    timeout=100,
    shutdown_delay=1,
    shutdown_loops=2,

)
async def smoke(tb: FifoTB, log):
    await ClockCycles(tb.clk, 10)


@FifoTB.testcase(
    reset_wait_during=2,
    reset_wait_after=0,
    timeout=10000,
    shutdown_delay=1,
    shutdown_loops=2,

)
async def random_data(tb: FifoTB, log):
    log.info("Scheduling random backpressure on the output.")
    delay_range=(0, 8) # max greater than fifo size
    tb.schedule(
        handshake_ready_seq(valid_mon=tb.out_mon, ready_drv=tb.rsp_drv, delay_range=delay_range), 
        blocking=False),
    log.info("Schedule random input")
    tb.schedule(handshake_req_seq(inp_drv=tb.inp_drv, data_range=(1, 200)), blocking=False)
    await ClockCycles(tb.clk, 5000)



def get_rtl_files():
    rtl_files = []
    sources = subprocess.run(
        "bender sources -t sim --flatten", 
        capture_output=True, 
        shell=True
    )
    sources = json.loads(sources.stdout)
    for src_pkg in sources:
        for file in src_pkg['files']:
            rtl_files.append(Path(file))
    return rtl_files


if __name__ == "__main__":
    sim = os.getenv("SIM", default="verilator")
    build_args = ["-Wno-fatal", "--no-stop-fail", "-Wno-REDEFMACRO"]
    if WAVES:
        build_args += ["--trace-fst"]
    if RVFI:
        build_args += [f"-DRVFI"]
    if RVFI_TRACE:
        build_args += [f"-DRVFI_TRACE"]
    if ASSERTIONS:
        build_args += [f"-DASSERTIONS"]
    runner = get_runner(sim)
    runner.build(
        sources=get_rtl_files(),
        includes=[],
        build_args=build_args,
        hdl_toplevel="fifo_handshake",
        parameters={},
        always=True,
        waves=False,
    )
    runner.test(
        hdl_toplevel="fifo", 
        test_module="test_fifo",
        plusargs=[]
    )
  
