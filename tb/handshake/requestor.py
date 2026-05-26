# SPDX-License-Identifier: MIT
# Copyright (c) 2023-2024 Vypercore. All Rights Reserved

from cocotb.triggers import RisingEdge
from forastero.driver import BaseDriver
from forastero.monitor import BaseMonitor

from .transaction import HandshakeValid


class HandshakeRequestDriver(BaseDriver):
    async def drive(self, transaction: HandshakeValid):
        # Setup the transaction
        self.io.set("data", transaction.data)
        self.io.set("valid", transaction.valid)
        # Wait one cycle for setup
        await RisingEdge(self.clk)
        # Wait for the acknowledgement
        while self.io.get("ready") == 0:
            await RisingEdge(self.clk)
        # Clear the validuest
        self.io.set("valid", 0)


class HandshakeRequestMonitor(BaseMonitor):
    async def monitor(self, capture):
        while True:
            await RisingEdge(self.clk)
            if self.rst.value == 0:
                continue
            if self.io.get("valid"):
                capture(HandshakeValid(data=self.io.get("data"), valid=True))
                while self.io.get("ready") == 0:
                    await RisingEdge(self.clk)
