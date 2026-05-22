import time
import asyncio
import logging

logger = logging.getLogger("Portal2Client")

class TrapHandler:
    def __init__(self, ctx):
        self.ctx = ctx
        self.trap_queue = []
        self.held_trap_queue = []
        self.last_trap_executed = 0
        self.ping_in_progress = False
        self.is_map_transition_active = False
        self.loop_task = None

    def start(self):
        """Starts the asynchronous background verification loop for standard traps."""
        if self.loop_task is None or self.loop_task.done():
            self.loop_task = asyncio.create_task(self.queue_loop())

    def stop(self):
        """Cancels the background loop task."""
        if self.loop_task and not self.loop_task.done():
            self.loop_task.cancel()

    def set_map_transition_state(self, active: bool):
        """Sets whether a map shift is active to release or hold incoming traps."""
        self.is_map_transition_active = active
        if not active and self.held_trap_queue:
            logger.info(f"Map transition completed. Unfreezing {len(self.held_trap_queue)} postponed traps into active queue.")
            self.trap_queue.extend(self.held_trap_queue)
            self.held_trap_queue.clear()

    def enqueue_trap(self, trap_command: str):
        """Enqueues a trap command or postpones it if a transition is active."""
        if self.is_map_transition_active:
            self.held_trap_queue.append(trap_command)
            logger.info(f"Trap received during map completion check. Postponing: {trap_command.strip()}")
        else:
            self.trap_queue.append(trap_command)
            logger.info(f"Trap received during normal gameplay. Processing: {trap_command.strip()}")

    async def queue_loop(self):
        """Periodically polls game availability before executing active traps sequentially."""
        while not self.ctx.exit_event.is_set():
            try:
                if self.trap_queue and self.ctx.check_game_connection() and not self.ping_in_progress and not self.is_map_transition_active:
                    current_time = time.time()
                    if current_time - self.last_trap_executed >= 4.0:
                        self.ctx.command_queue.append("AP_PingReady\n")
            except Exception as e:
                logger.error(f"Error in TrapHandler background loop: {e}")
            await asyncio.sleep(1.0)

    def process_pong(self):
        """Pops and dispatches the oldest ready trap down into the netcon console stream."""
        if not self.trap_queue or self.is_map_transition_active:
            return

        self.ping_in_progress = True
        trap_cmd = self.trap_queue.pop(0)
        logger.info(f"Game confirmed ready! Dispatched trap command string: {trap_cmd.strip()}")

        self.last_trap_executed = time.time()
        self.ctx.command_queue.append(trap_cmd)
        self.ping_in_progress = False