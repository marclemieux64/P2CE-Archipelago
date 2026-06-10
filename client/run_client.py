import sys
import os
import warnings

# Suppress harmless warnings about compiled C++ speedups not being pre-compiled
warnings.filterwarnings("ignore", message=".*_speedups not available.*")

# Resolve absolute paths to this client bundle directory
base_dir = os.path.dirname(os.path.abspath(__file__))

# Inject core and game libraries into the python runtime path
sys.path.insert(0, base_dir)
sys.path.insert(0, os.path.join(base_dir, "core"))

# Set local_path cached_path to base_dir so that logs and config are in P2CEClient directly
import Utils
Utils.local_path.cached_path = base_dir

from Utils import init_logging
init_logging("P2CEClient", exception_logger="P2CEClient")

from game.client.Launch import launch_p2ce_client

if __name__ == "__main__":
    print("Launching independent P2CE Archipelago Client...")
    launch_p2ce_client(*sys.argv[1:])