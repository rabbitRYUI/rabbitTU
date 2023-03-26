import discord
import logging
import yarl

from rich import print
from typing import cast
from datetime import datetime

from discord import app_commands
from discord.ext import commands
from discord.gateway import DiscordWebSocket

from ballsdex.core.dev import Dev
from ballsdex.core.metrics import PrometheusServer
@@ -113,6 +115,30 @@ async def load_special_cache(self):
        now = datetime.now()
        self.special_cache = await Special.filter(start_date__lte=now, end_date__gt=now)

    async def launch_shards(self) -> None:
        # override to add a log call on the number of shards that needs connecting
        if self.is_closed():
            return

        if self.shard_count is None:
            self.shard_count: int
            self.shard_count, gateway_url = await self.http.get_bot_gateway()
            log.info(
                f"Logged in to Discord, initiating connection. {self.shard_count} shards needed"
            )
            gateway = yarl.URL(gateway_url)
        else:
            gateway = DiscordWebSocket.DEFAULT_GATEWAY

        self._connection.shard_count = self.shard_count

        shard_ids = self.shard_ids or range(self.shard_count)
        self._connection.shard_ids = shard_ids

        for shard_id in shard_ids:
            initial = shard_id == shard_ids[0]
            await self.launch_shard(gateway, shard_id, initial=initial)

    async def on_ready(self):
        assert self.user
        log.info(f"Successfully logged in as {self.user} ({self.user.id})!")
