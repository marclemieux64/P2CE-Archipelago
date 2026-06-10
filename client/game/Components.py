# Complete, stripped-down implementation for in-game client architectures
try:
    from worlds.LauncherComponents import Component, Type, components
    LAUNCHER_AVAILABLE = True
except ImportError:
    LAUNCHER_AVAILABLE = False

# We intentionally do not append a Type.CLIENT component here because 
# the client interface is fully integrated directly in-game.
# This prevents the Archipelago Launcher from showing an unused external launcher button.
if LAUNCHER_AVAILABLE:
    pass