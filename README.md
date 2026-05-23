![Portal 2 CE Archipelago Mod](.assets/Portal2pelago-LOGO.png)

`Version 1.0.0`

`Stable` ` Development`

This is a Portal 2 Community Edition mod designed for use with Archipelago, a multi-game collaborative randomiser.

This must be used with the [P2CE APWorld and Client]().

> [!WARNING]
> This mod is not compatible with SteamOS.

***
*\*Cough cough\**

Cave Johnson here.

We have a **BIG** problem on our hands.
I'm gonna bet most of you here already know about the whole multiverse thing. Remember - "infinite earths, with an infinite number of Apertures"?

Well, *some* of those outer-world Apertures had decided they've had enough of our borrowing, and began stealing testing elements right back from us! **AND** replacing them with all sorts of weird junk that not even my father would be able to decipher!

Anyway, we're bankrupt. Again. Even more so now than before.
But there's no reason to panic! The lab boys and I have been bashing our heads against the wall for a while, but we've found a way to bring it back under control.

That's where you come in. We're going to send a rescue squad through the multiverse to get our precious buttons and cubes back! ...Oh, and my coffee mug. If you see that, bring that back too.

Now, we do need at least a few thousand people back here to manage the place, and one lucky son of a gun to oversee the return of the testing apparatus, so we can't send out everyone.

But if **YOU** want to be part of the **Archipelago Exploration Unit**, sign the relevant papers at the reception, then jump into that gaping hole in reality by the water cooler.

Seriously, though, we'll need everyone we can get on this. And fast. Before we have a repeat of what happened wi...

**[ ▮▮▮▮ AUDIO LOST ▮▮▮▮ ]**
***

# How does Portal 2 work in Archipelago

You play through a randomised chapters completing maps. Initially the puzzle elements (e.g. Upgraded Portal Gun, Weighted Storage Cube) will be unavailable and you will gain them as you play gaining the ability to complete more levels that require these puzzle elements.

## Locations

The base locations in the game are completing maps, some of these maps are test chambers and some are locations in aperture laboratories, basically each new loading zone in the game is a separate map.
Additional optional locations include:
- "Cutscene" maps, those that require no input from the player (removed by default)
- Breaking **Wheatley Monitors** in Chapter 8 (and one in Chapter 9)
- Custom buttons in **Ratman Dens**
- Vitrified doors

## Items

Items are test chamber elements e.g. Floor Button, Gels, PotatOS.

The junk filler items include Moon Dust, Slice of Cake and Lemon.

Traps are also in the game and can be set and adjusted in the yaml options.


## The Goal

At the moment the only goal is to finish the final level in Chapter 9 (Chapter 9 is not randomised)

## Enchancement currently included
- Better message system visual
- Better Archipelago Maps menu
- Can access Archipelago Maps menu from pause menu
- Finishing a map bring you to Archipelago maps menu instead of the main menu
- Transtion system
- Hint page
- Tracker included
- Option menu
- Quality of life if you do some wheatley monitor screens you get telported to prevent you death
- Multi Language support (English and French currently)
- Simple setup

# Using the Mod

## Installation

To use this mod you must first have a copy of Portal 2 and Portal 2 Community Edition downloaded in your Steam library.

1. Download and install [Steam](https://store.steampowered.com/about/) and install [Portal 2](https://store.steampowered.com/app/620/Portal_2/).
2. Download and install [Portal 2 Community Edition](https://store.steampowered.com/app/440000/Portal_2_Community_Edition/).
3. Download the [latest Zip archive release of the p2ce-archipelago](https://github.com/marclemieux64/P2CE-Archipelago/releases).
4. Extract the top-level folder from the Zip file.
5. Place the `p2ce-archipelago` folder in the `sourcemods` Steam folder.
    - On Windows, this may be found at:
        - `C:\Program Files (x86)\Steam\steamapps\sourcemods`
    - On Linux, this may be found at:
        - `~/.local/share/Steam/steamapps/sourcemods/`

The folder structure should look like this:

```
sourcemods
|   
└─── p2ce-archipelago 
    |  GameInfo.txt
    |   ...
    └─── cfg
    └─── ...
```
6. Open Steam, and you should see a new game named "Portal 2 Community Editon - Archipelago" in your game library.
> [!NOTE]
> If the game does not appear in your Steam game library, please exit (completely closing) Steam and re-launch Steam.
7. We need to change the properties of the game in order to connect to the Archipelago Portal 2 APWorld client. Right-click the "Portal 2 Community Edition - Archipelago" game in your Library, and select the "Properties..." menu option.
8. In the dialog that appears, navigate to the "General" menu item, then in the right pane of the dialog navigate to "Launch Options". In the text input:
    - On Windows, put:
        - `"C:\Program Files (x86)\Steam\steamapps\sourcemods\p2ce-archipelago\RunArchipelago.bat" %command%`
    - On Linux, put: 
        - `"~/.steam/steam/steamapps/sourcemods/p2ce-archipelago/RunArchipelago.sh" %command%`

> [!TIP]
> If on Linux, and you cannot get the game to open as expected, you may need to run the game using Proton, following the Windows install steps.
9. Download and install the [`p2ce.apworld`]() file into the Archipelago launcher using the "Install APWorld" option

## Running
1. Launch Portal 2: Community Edition - Archipelago from your library
2. Enjoy!



# Portal 2 Client Commands

**/check_connection** - Displays if the client is able to communicate with Portal 2

**/deathlink** - Toggles deathlink

**/refresh_menu** - Refreshes the menu if it is displaying incorrect information - especially useful after a reconnect

**/needed {location_name}** - Displays information about the item requirements for in logic check completion


# FAQ

# Acknowledgements

## Mod Creators

### Portal 2 Mod

- **GlassToadstool** - Lead Developer
- **Clone Fighter** - Loading Screens, Logo Graphics, and Cave Johnson Speech
- **LimeDreaming** - Custom Font and Models
- **JD** - Icon Graphics
- **Kit Lemonfoot** - Documenting Gels for Split

### APWorld

- **GlassToadstool** - Lead Developer
- **Proplayen** - Initial Logic Design
- **Kaito Kid** - Assistance
- **studkid** - Initial UT Support
- **Charged_Neon** - Documentation
- **James** - Major Bug Fixing and UT updates

### Initial Testers

**22TwentyTwo, ahhh reptar, Bfbfan26, buzzman5001, ChaiMint, Default Miserable, Fewffwa, Fox, Grenhunterr, Kit Lemonfoot, Knux, MarioXTurn, miketizzle411, Pigmaster100, Rya, Scrungip**

### P2CE Mod
- **marclemieux64** - Lead Tinkerer


### P2CE Mod Repo Foundation
- [p2ce-mod-ui](https://github.com/marclemieux64/p2ce-mod-ui)
- [p2ce-mod-template](https://github.com/marclemieux64/p2ce-mod-template)
- [Portal2ArchipelagoMod](https://github.com/marclemieux64/Portal2ArchipelagoMod)

(This mod was made using AI)




