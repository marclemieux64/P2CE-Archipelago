import sys
import os

# Resolve absolute paths to this client bundle directory
base_dir = os.path.dirname(os.path.abspath(__file__))

# Inject core and game libraries into the python runtime path
sys.path.insert(0, base_dir)
sys.path.insert(0, os.path.join(base_dir, "core"))

# Set local_path cached_path to base_dir so that logs and config are in P2CEClient directly
import Utils
Utils.local_path.cached_path = base_dir

from Utils import init_logging
init_logging("Portal2Client", exception_logger="Portal2Client")

from game.client.Launch import launch_portal_2_client

if __name__ == "__main__":
    print("Launching independent Portal 2 P2CE Archipelago Client...")
    launch_portal_2_client(*sys.argv[1:])

