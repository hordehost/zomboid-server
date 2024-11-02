# zomboid-server

## Usage

The following environment variables control the server itself:

| Environment variable            | Description                        | Default              |
| ------------------------------- | ---------------------------------- | -------------------- |
| `ZOMBOID_JVM_MAX_HEAP`          | Maximum heap size for the Java VM  | `3072m`              |
| `ZOMBOID_SERVER_DEBUG`          | Enable debug mode                  | (disabled)           |
| `ZOMBOID_SERVER_DISABLE_LOG`    | Disable specific debug log filters | (none)               |
| `ZOMBOID_SERVER_DEBUG_LOG`      | Enable specific debug log filters  | (none)               |
| `ZOMBOID_SERVER_NAME`           | Name of the server                 | `my-zomboid-server`  |
| `ZOMBOID_SERVER_ADMIN_USERNAME` | Admin username                     | `admin`              |
| `ZOMBOID_SERVER_ADMIN_PASSWORD` | Admin password                     | (randomly generated) |

Game data will be stored at the path `/game-data/` in the container, and this is
where you can mount in the server's `.ini` file or the sandbox Lua scripts.

## Notes about configuring Project Zomboid

There are several layers of configuration, each of which is handled differently,
either stored in files or passed as server arguments. This information is
current as of build 41.78.11.

The general approach to adapt the Project Zomboid server to container
environments is to move most settings to environment variables, following a
naming convention that identifies where those settings apply. The wrapper script
`server` will idempotently adjust the appropriate configuration files or pass
the appropriate arguments, so as much as possible can be specified by
environment variables.

More complex files, like the sandbox Lua scripts, will need to be mounted into
the image at `/server/Server/`.

### The Java virtual machine

The file `/server/ProjectZomboid64.json` sets the arguments to the JVM,
including the entrypoint class and classpath, which should not be changed.
However the `vmArgs` key includes arguments that control memory and other
lower-level settings. Most of these should also be left intact, but this is
where we can set `-Xmx` to match the memory quota set by the container runtime.

| Environment variable   | JVM argument |
| ---------------------- | ------------ |
| `ZOMBOID_JVM_MAX_HEAP` | `-Xmx`       |

### Startup arguments to the server

These are additional arguments that are passed to the game server itself, which
start to get into some of the low-level server settings. The current [list of
startup parameters](https://pzwiki.net/wiki/Startup_parameters) are maintained
on the wiki. These need to be passed as arguments to the `/server/start-server.sh` script.

| Environment variable            | Server argument           | Description                                                                                                                          |
| ------------------------------- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| _n/a, always use Steam_         | `-nosteam`                | Disables Steam integration on client/server                                                                                          |
| _n/a, must be /game-data_       | `-cachedir=<path>`        | Sets the path for the game data cache dir (e.g. `-cachedir="C:\Zomboid"`)                                                            |
| _n/a, must be default_          | `-modfolders`             | Controls where mods are loaded from. Any of the 3 keywords (workshop,steam,mods) may be left out and may appear in any order         |
| `ZOMBOID_SERVER_DEBUG`          | `-debug`                  | Launches the game in debug mode                                                                                                      |
| `ZOMBOID_SERVER_DISABLE_LOG`    | `-disablelog=<DebugType>` | Disables specified filters in console log. Takes comma-separated list (e.g. `-disablelog=All` or `-disablelog=Network,Sound`)        |
| `ZOMBOID_SERVER_DEBUG_LOG`      | `-debuglog=<DebugType>`   | Enables specified filters in console log. Takes comma-separated list (e.g. `-debuglog=All` or `-debuglog=Network,Sound`)             |
| `ZOMBOID_SERVER_ADMIN_USERNAME` | `-adminusername`          | Sets a different username for the default admin user when creating a server                                                          |
| `ZOMBOID_SERVER_ADMIN_PASSWORD` | `-adminpassword`          | Bypasses the enter-a-password prompt when creating a server                                                                          |
| `ZOMBOID_SERVER_NAME`           | `-servername`             | Sets a custom server name when starting the server                                                                                   |
| _n/a, must be default_          | `-ip <ip>`                | Handles multiple network cards (e.g. `-ip 127.0.0.1`)                                                                                |
| _n/a, must be default_          | `-port <port>`            | Overrides the .ini option "DefaultPort"                                                                                              |
| _n/a, must be default_          | `-udpport <port>`         | Overrides the .ini option "UDPPort"                                                                                                  |
| _n/a, Steam VAC is always on_   | `-steamvac <true/false>`  | Enables/disables VAC on Steam servers. Can also be set in INI file as `SteamVAC=true/false`                                          |
| _n/a, usage unclear_            | `-steamport1 <port>`      | Sets first required Steam server port                                                                                                |
| _n/a, usage unclear_            | `-steamport2 <port>`      | Sets second required Steam server port. Both Steam ports can also be specified in server INI file as `SteamPort1=` and `SteamPort2=` |

### Server and multiplayer settings

These settings control the general behavior of the server, how it appears on
public listings (or not), how users are handled, and includes some settings
relating to the in-sandbox multiplayer experience (like whether PvP is allowe).
These are applied to the `<servername>.ini` file. There is some overlap with the
server arguments (like `DefaultPort` and `UDPPort`), so in those cases the value
is passed as a server argument and not used from the `.ini` file.

Because many of these settings can be changed at runtime (using RCON to
`changeoption`, for example) and saved to the `/game-data/` volume, they should
generally not be set from environment variables.

### Project Zomboid sandbox settings

These settings control the world simulation of Project Zomboid, separately from
the multiplayer settings. These are the familiar in-game settings about things
like how the infection spreads or what spawn points are available.

These are implemented by the Project Zomboid server as Lua scripts and are too
complex to be represented by environment variables. Additionally, they can be
changed and reloaded at runtime.

- `/game-data/Server/<severname>_SandboxVars.lua`
- `/game-data/Server/<servername>_spawnpoints.lua`
- `/game-data/Server/<servername>_spawnregions.lua`
