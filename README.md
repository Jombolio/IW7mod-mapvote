
# IW7-Mod: Call of Duty - Infinite Warfare Mapvote
Source Code Developed by [@DoktorSAS](https://twitter.com/DoktorSAS)  
Adapted for IW7-Mod by [@jombo.uk](https://jombo.uk/)

## Requirements

- This script is designed for **Dedicated Servers**. It may not function correctly in private matches.
- IW7-Mod by AuroraDev

## Installation & Usage

1.  Place the `scripts/mapvote.gsc` file into your server's scripts folder (typically `".../Call of Duty - Infinite Warfare/iw7-mod/custom_scripts/mp/"`).
2.  Ensure your `server.cfg` (or specific gametype config) includes the necessary DVAR configurations.
3.  The mapvote will automatically trigger at the end of the match, freezing players and showing the mapvote UI.

## Configuration

You can customize the mapvote behavior using the following DVARs in your server configuration file.

### General Settings

| DVAR | Default | Description |
| :--- | :--- | :--- |
| `mv_enable` | `1` | Toggles the mapvote system. |
| `mv_time` | `20` | Duration of the voting phase in seconds. |
| `mv_minplayers` | `1` | Minimum number of players required to trigger the mapvote. |
| `mv_blur` | `3` | Strength of the background blur during voting. |

### Map & Gametype Pool

| DVAR | Default | Description |
| :--- | :--- | :--- |
| `mv_maps` | (List of maps) | A space-separated list of map codenames available for voting. |
| `mv_excludedmaps` | `""` | A space-separated list of maps to exclude from the vote generation. |
| `mv_gametypes` | (See below) | A list of gametypes and their config files. |

**`mv_gametypes` Format:**
The format is `gametype@config`, with multiple entries separated by spaces.
Example: `war@gamedata/server.cfg dom@gamedata/server.cfg conf@gamedata/server.cfg`
*Note: Ensure the config files exist in your server's iw7-mod folder in the directory of your dedicated server instance, for example ".../Call of Duty - Infinite Warfare/iw7-mod/gamedata/server.cfg"*

### UI & Aesthetics

| DVAR | Default | Description |
| :--- | :--- | :--- |
| `mv_votecolor` | `5` (Cyan) | Color code for the vote count numbers (e.g., 0-9). |
| `mv_scrollcolor` | `cyan` | Color of the selection box when highlighting an option. |
| `mv_selectcolor` | `lightgreen` | Color of the selection box after voting. |
| `mv_backgroundcolor` | `grey` | Background color of the map cards. |

**Available Colors:** `red`, `black`, `grey`, `purple`, `pink`, `green`, `blue`, `lightblue`, `lightgreen`, `orange`, `yellow`, `brown`, `cyan`, `white`.

### Credits & Socials

| DVAR | Default | Description |
| :--- | :--- | :--- |
| `mv_credits` | `1` | Toggles the display of credits. |
| `mv_socials` | `1` | Toggles the display of social media text. |
| `mv_socialname` | `Discord` | Label for the social link (e.g., "Discord", "Website"). |
| `mv_sociallink` | `...` | The actual link or text to display. |
| `mv_sentence` | `Thanks for Playing` | Custom message displayed above the credits. |

## Example Config

```cfg
set mv_enable "1"
set mv_time "20"
set mv_minplayers "4"
set mv_gametypes "war@gamedata/server.cfg dom@gamedata/server.cfg"
set mv_maps "mp_frontier mp_metropolis mp_fallen mp_dome_iw"
set mv_socialname "Discord"
set mv_sociallink "discord.gg/yourserver"
```
