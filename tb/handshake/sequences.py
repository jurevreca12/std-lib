# SPDX-License-Identifier: MIT
# Copyright (c) 2023-2024 Vypercore. All Rights Reserved

# Common sequences used by testcases in stream
import forastero
from forastero.driver import DriverEvent
from forastero.monitor import MonitorEvent
from forastero.sequence import SeqContext, SeqProxy

from .requestor import HandshakeRequestMonitor
from .requestor import HandshakeRequestDriver
from .responder import HandshakeResponderDriver
from .transaction import HandshakeValid, HandshakeReady

@forastero.sequence(auto_lock=True)
@forastero.requires("valid_mon", HandshakeRequestMonitor)
@forastero.requires("ready_drv", HandshakeResponderDriver)
async def handshake_ready_seq(
    ctx: SeqContext,
    valid_mon: SeqProxy[HandshakeRequestMonitor],
    ready_drv: SeqProxy[HandshakeResponderDriver],
    delay_range: tuple[int, int] = (1, 1),
) -> None:
    min_delay, max_delay = min(delay_range), max(delay_range)
    while True:
        await valid_mon.wait_for(MonitorEvent.CAPTURE)
        await ready_drv.enqueue(
            HandshakeReady(ready=True, delay=ctx.random.randint(min_delay, max_delay)),
            wait_for=DriverEvent.POST_DRIVE,
        ).wait()


@forastero.sequence(auto_lock=True)
@forastero.requires('inp_drv', HandshakeRequestDriver)
async def handshake_req_seq(
    ctx: SeqContext,
    inp_drv: SeqProxy[HandshakeRequestDriver],
    data_range: tuple[int, int] = (1, 1),
) -> None:
    min_data, max_data = min(data_range), max(data_range)
    while True:
        await inp_drv.enqueue(
            HandshakeValid(data=ctx.random.randint(min_data, max_data)),
            wait_for=DriverEvent.POST_DRIVE
        ).wait()
