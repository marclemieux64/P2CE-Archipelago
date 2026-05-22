import time
import asyncio
import logging

logger = logging.getLogger("Portal2Client")

class DeathLinkHandler:
    def __init__(self, ctx):
        # ONLY initialize DeathLink-related variables
        self.ctx = ctx
        self.deathlink_queue = []
        self.last_death_link_executed = 0
        self.ping_in_progress = False
        self.loop_task = None

    def start(self):
        """Starts the asynchronous background loop for processing queued deaths."""
        if self.loop_task is None or self.loop_task.done():
            self.loop_task = asyncio.create_task(self.queue_loop())

    def stop(self):
        """Cancels the running background loop task."""
        if self.loop_task and not self.loop_task.done():
            self.loop_task.cancel()

    def enqueue_death(self, cause: str):
        """Appends an incoming server death cause to the processing queue."""
        self.deathlink_queue.append(cause)
        logger.debug(f"DeathLink received: {cause}")

    async def queue_loop(self):
        """Periodically runs targeted verification pings through netcon if items are queued."""
        while not self.ctx.exit_event.is_set():
            try:
                # We only check the deathlink_queue here
                if self.deathlink_queue and self.ctx.check_game_connection() and not self.ping_in_progress:
                    current_time = time.time()
                    if current_time - self.last_death_link_executed >= 6.0:
                        self.ctx.command_queue.append("AP_PingReady\n")
            except Exception as e:
                logger.error(f"Error in DeathLink handler loop: {e}")
            await asyncio.sleep(1.0)

    def process_pong(self):
        """Triggers game kill commands and UI notifications safely."""
        if not self.deathlink_queue:
            return

        self.ping_in_progress = True
        current_cause = self.deathlink_queue.pop(0)
        
        self.last_death_link_executed = time.time()
        
        self.ctx.command_queue.append("AP_SetMutedDeath 1\n")
        
        fake_data = [{"text": f"DEATHLINK: {current_cause}", "is_death": True}]
        # This will be picked up by Notifications.py and logged exactly once
        self.ctx.notifier.on_print_silently(f"DEATHLINK: {current_cause}", fake_data, mirror_to_hud=True)
        
        self.ctx.command_queue.append("kill\n")
        self.ping_in_progress = False
