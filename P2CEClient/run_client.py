import sys
import os

# Resolve absolute paths to this client bundle directory
base_dir = os.path.dirname(os.path.abspath(__file__))

# Inject core and game libraries into the python runtime path
sys.path.insert(0, base_dir)
sys.path.insert(0, os.path.join(base_dir, "core"))

from game.client.Launch import launch_portal_2_client

if __name__ == "__main__":
    print("Launching independent Portal 2 P2CE Archipelago Client...")
    launch_portal_2_client(*sys.argv[1:])
