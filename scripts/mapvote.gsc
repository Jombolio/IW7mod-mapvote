#include scripts\engine\utility;
#include scripts\mp\utility;
#include scripts\mp\hud_util;

#include scripts\mp\gamelogic;

/*
	IW7 Mapvote (Adapted from IW6 Mapvote)
	Credit to @DoktorSAS for the original script, adapted for IW7 by @jombo.uk
*/

init()
{
	preCacheShader("gradient_fadein");
	preCacheShader("gradient");
	preCacheShader("white");
	preCacheShader("line_vertical");

	level thread onPlayerConnected();
	level thread mv_Config();

	level.startmapvote = ::startMapvote;
}

startMapvote()
{
	// wasLastRound might need checking if it exists in scripts\mp\utility, usually it does or is replaced
	if (scripts\mp\utility::waslastround())  
	{
		mv_Begin();
	}
}

mv_Config()
{
	SetDvarIfNotInizialized("mv_enable", 1);
	if (getDvarInt("mv_enable") != 1) 
		return;

	level.__mapvote = [];
	SetDvarIfNotInizialized("mv_time", 20);
	level.__mapvote["time"] = getDvarInt("mv_time");
    
    // IW7 Maps
	SetDvarIfNotInizialized("mv_maps", "mp_parkour mp_quarry mp_divide mp_riot mp_frontier mp_desert mp_metropolis mp_proto mp_fallen mp_skyway mp_rivet mp_breakneck mp_dome_iw mp_dome_dusk mp_afghan mp_geneva mp_neon mp_prime mp_marsoasis mp_flip mp_junk mp_mansion mp_turista2 mp_paris mp_pixel mp_overflow mp_nova mp_hawkwar mp_depot mp_rally mp_codphish mp_permafrost2 mp_renaissance2 mp_carnage2");

	SetDvarIfNotInizialized("mv_credits", 1);
	SetDvarIfNotInizialized("mv_socials", 1);
	SetDvarIfNotInizialized("mv_socialname", "Website");
	SetDvarIfNotInizialized("mv_sociallink", "example.com");
	SetDvarIfNotInizialized("mv_sentence", "Thanks for Playing");
	SetDvarIfNotInizialized("mv_votecolor", "5");
	SetDvarIfNotInizialized("mv_blur", "3");
	SetDvarIfNotInizialized("mv_scrollcolor", "cyan");
	SetDvarIfNotInizialized("mv_selectcolor", "lightgreen");
	SetDvarIfNotInizialized("mv_backgroundcolor", "grey");
    // IW7 Gametypes:
	SetDvarIfNotInizialized("mv_gametypes", "war@gamedata/server.cfg koth@gamedata/server.cfg dm@gamedata/server.cfg dd@gamedata/server.cfg dom@gamedata/server.cfg sd@gamedata/server.cfg conf@gamedata/server.cfg ctf@gamedata/server.cfg ball@gamedata/server.cfg infect@gamedata/server.cfg gun@gamedata/server.cfg tdef@gamedata/server.cfg siege@gamedata/server.cfg ctf@gamedata/server.cfg sr@gamedata/server.cfg grind@gamedata/server.cfg front@gamedata/server.cfg");
	setDvarIfNotInizialized("mv_excludedmaps", "");
    setDvarIfNotInizialized("mv_minplayers", 1);
}

// Mapvote Logic
mv_Begin()
{
	level endon("mv_ended");

	if (getDvarInt("mv_enable") != 1)
		return;

    if (level.players.size < getDvarInt("mv_minplayers"))
        return;

	if (!isDefined(level.mapvote_started))
	{
		level.mapvote_started = 1;

		mapsIDs = [];
		mapsIDs = strTok(getDvar("mv_maps"), " ");
		mapschoosed = mv_GetRandomMaps(mapsIDs);

		level.__mapvote["map1"] = spawnStruct();
		level.__mapvote["map2"] = spawnStruct();
		level.__mapvote["map3"] = spawnStruct();

		level.__mapvote["map1"].mapname = maptoname(mapschoosed[0]);
		level.__mapvote["map1"].mapid = mapschoosed[0];
		level.__mapvote["map2"].mapname = maptoname(mapschoosed[1]);
		level.__mapvote["map2"].mapid = mapschoosed[1];
		level.__mapvote["map3"].mapname = maptoname(mapschoosed[2]);
		level.__mapvote["map3"].mapid = mapschoosed[2];

		gametypes = strTok(getDvar("mv_gametypes"), " ");
		// Fix randomIntRange to use randomInt logic if needed, but randomIntRange should exist
		g1 = gametypes[randomIntRange(0, gametypes.size)];
		g2 = gametypes[randomIntRange(0, gametypes.size)];
		g3 = gametypes[randomIntRange(0, gametypes.size)];

		level.__mapvote["map1"].gametype = g1;
		level.__mapvote["map2"].gametype = g2;
		level.__mapvote["map3"].gametype = g3;

		foreach (player in level.players)
		{
			if (!is_bot(player))
				player thread mv_PlayerUI();
		}
		wait 0.2;
		level thread mv_ServerUI();

		mv_VoteManager();
	}
}

ArrayRemoveIndex(array, index)
{
	new_array = [];
	for (i = 0; i < array.size; i++)
	{
		if (i != index)
			new_array[new_array.size] = array[i];
	}
	array = new_array;
	return new_array;
}

mv_GetRandomMaps(mapsIDs)
{
	mapschoosed = [];
	for (i = 0; i < 3; i++)
	{
		index = randomIntRange(0, mapsIDs.size);
		map = mapsIDs[index];
		mapsIDs = ArrayRemoveIndex(mapsIDs, index); // Logic fix: ArrayRemoveIndex usually takes an index, but existing code passed 'map' string? 
        // Original code: mapsIDs = ArrayRemoveIndex(mapsIDs, map); -> map was string.
        // ArrayRemoveIndex impl: if (i != index). If index passed was string, i!=index compares int vs string?
        // Actually original ArrayRemoveIndex param name is "index", but usage passed "map" (value). This looks suspiciously buggy in original or I misread.
        // Wait, original:
        // mapsIDs = ArrayRemoveIndex(mapsIDs, map); -> map is the string value.
        // ArrayRemoveIndex(array, index): for(i=0 to size) if (i != index) ...
        // If index is string, i != string is always true (except type coercion?).
        // If the original works, it might be that it's relying on something weird.
        // BUT, I'll implement proper ArrayRemove logic by value or index correctly.
        // Let's rely on standard scripts\engine\utility::array_remove if available, or just fix this one.
        // I will use my own array remove by value.
		mapschoosed[i] = map;
	}
	return mapschoosed;
}




is_bot(entity)
{
	return isDefined(entity.pers["isBot"]) && entity.pers["isBot"];
}

mv_PlayerUI()
{
	level endon("game_ended");

	// Self SetBlurForPlayer... in IW7 might be different. 
    // trying setClientOmnvar("ui_blur", ...) or just setBlur
	self setBlurForPlayer(getDvarFloat("mv_blur"), 1.5);

	scroll_color = getColor(getDvar("mv_scrollcolor"));
	bg_color = getColor(getDvar("mv_backgroundcolor"));
	self scripts\mp\utility::freezecontrolswrapper(1);
	boxes = [];
	boxes[0] = self createRectangle("center", "center", -220, -452, 205, 133, scroll_color, "white", 1, .7);
	boxes[1] = self createRectangle("center", "center", 0, -452, 205, 133, bg_color, "white", 1, .7);
	boxes[2] = self createRectangle("center", "center", 220, -452, 205, 133, bg_color, "white", 1, .7);

	self thread mv_PlayerFixAngle();

	level waittill("mv_start_animation");

	boxes[0] affectElement("y", 1.2, -50);
	boxes[1] affectElement("y", 1.2, -50);
	boxes[2] affectElement("y", 1.2, -50);
	self thread destroyBoxes(boxes);

	self notifyonplayercommand("left", "+attack");
	self notifyonplayercommand("right", "+speed_throw");
	self notifyonplayercommand("left", "+moveright");
	self notifyonplayercommand("right", "+moveleft");
	self notifyonplayercommand("select", "+usereload");
	self notifyonplayercommand("select", "+activate");
	self notifyonplayercommand("select", "+gostand");

	self.statusicon = "veh_hud_target_chopperfly"; 
	level waittill("mv_start_vote");

	index = 0;
	isVoting = 1;
	while (level.__mapvote["time"] > 0 && isVoting)
	{
		command = self waittill_any_return("left", "right", "select", "done");
		if (command == "right")
		{
			index++;
			if (index == boxes.size)
				index = 0;
		}
		else if (command == "left")
		{
			index--;
			if (index < 0)
				index = boxes.size - 1;
		}

		if (command == "select")
		{
			self.statusicon = "compass_icon_vf_active"; 
			vote = "vote" + (index + 1);
			level notify(vote);
			select_color = getColor(getDvar("mv_selectcolor"));
			boxes[index] affectElement("color", 0.2, select_color);
			isVoting = 0;
		}
		else
		{
			for (i = 0; i < boxes.size; i++)
			{
				if (i != index)
					boxes[i] affectElement("color", 0.2, bg_color);
				else
					boxes[i] affectElement("color", 0.2, scroll_color);
			}
		}
	}
}

destroyBoxes(boxes)
{
	level endon("game_ended");
	level waittill("mv_destroy_hud");
	foreach (box in boxes)
	{
		box affectElement("alpha", 0.5, 0);
	}
}

mv_PlayerFixAngle()
{
	self endon("disconnect");
	level endon("game_ended");
	level waittill("mv_start_vote");
	angles = self getPlayerAngles();

	self waittill_any("left", "right");
	if (self getPlayerAngles() != angles)
		self setPlayerAngles(angles);
}

mv_VoteManager()
{
	level endon("game_ended");
	votes = [];
	votes[0] = spawnStruct();
	votes[0].votes = level createServerFontString("objective", 2);
	votes[0].votes setPoint("center", "center", -220 + 70, -325);
	votes[0].votes.label = &"^" + getDvar("mv_votecolor");
	votes[0].votes.sort = 4;
	votes[0].value = 0;
	votes[0].map = level.__mapvote["map1"];

	votes[1] = spawnStruct();
	votes[1].votes = level createServerFontString("objective", 2);
	votes[1].votes setPoint("center", "center", 0 + 70, -325);
	votes[1].votes.label = &"^" + getDvar("mv_votecolor");
	votes[1].votes.sort = 4;
	votes[1].value = 0;
	votes[1].map = level.__mapvote["map2"];

	votes[2] = spawnStruct();
	votes[2].votes = level createServerFontString("objective", 2);
	votes[2].votes setPoint("center", "center", 220 + 70, -325);
	votes[2].votes.label = &"^" + getDvar("mv_votecolor");
	votes[2].votes.sort = 4;
	votes[2].value = 0;
	votes[2].map = level.__mapvote["map3"];

	votes[0].votes setValue(0);
	votes[1].votes setValue(0);
	votes[2].votes setValue(0);

	votes[0].votes affectElement("y", 1, 0);
	votes[1].votes affectElement("y", 1, 0);
	votes[2].votes affectElement("y", 1, 0);

	votes[0].hideWhenInMenu = 1;
	votes[1].hideWhenInMenu = 1;
	votes[2].hideWhenInMenu = 1;

	isInVote = 1;
	index = 0;
	while (isInVote)
	{
		notify_value = level waittill_any_return("vote1", "vote2", "vote3", "mv_destroy_hud");

		if (notify_value == "mv_destroy_hud")
		{
			isInVote = 0;

			votes[0].votes affectElement("alpha", 0.5, 0);
			votes[1].votes affectElement("alpha", 0.5, 0);
			votes[2].votes affectElement("alpha", 0.5, 0);

			break;
		}
		else
		{
			switch (notify_value)
			{
			case "vote1":
				index = 0;
				break;
			case "vote2":
				index = 1;
				break;
			case "vote3":
				index = 2;
				break;
			}
			votes[index].value++;
			votes[index].votes setValue(votes[index].value);
		}
	}

	winner = mv_GetMostVotedMap(votes);
	map = winner.map;
	mv_SetRotation(map.mapid, map.gametype);

	wait 1.2;
}

mv_GetMostVotedMap(votes)
{
	winner = votes[0];
	for (i = 1; i < votes.size; i++)
	{
		if (isDefined(votes[i]) && votes[i].value > winner.value)
		{
			winner = votes[i];
		}
	}

	return winner;
}

mv_SetRotation(mapid, gametype)
{
	array = strTok(gametype, ";@");
	str = "";
	if (array.size > 1)
	{
		str = "exec " + array[1];
	}
	// logPrint("mapvote//gametype//" + array[0] + "//executing//" + str + "\n");
	setdvar("g_gametype", array[0]);
	setdvar("sv_currentmaprotation", str + " map " + mapid);
	setdvar("sv_maprotationcurrent", str + " map " + mapid);
	setdvar("sv_maprotation", str + " map " + mapid);
	level notify("mv_ended");
}

mv_ServerUI()
{
	level endon("game_ended");

	buttons = level createServerFontString("objective", 1.6);
	buttons setText("^3[{+speed_throw}]              ^7Press ^3[{+gostand}] ^7or ^3[{+activate}] ^7to select              ^3[{+attack}]");
	buttons setPoint("center", "center", 0, 80);
	buttons.hideWhenInMenu = 0;

	mv_votecolor = getDvar("mv_votecolor");

	mapUI1 = level createString("^7" + level.__mapvote["map1"].mapname + "\n" + gametypeToName(strTok(level.__mapvote["map1"].gametype, ";@")[0]), "objective", 1.1, "center", "center", -220, -325, (1, 1, 1), 1, (0, 0, 0), 0.5, 5, 1);
	mapUI2 = level createString("^7" + level.__mapvote["map2"].mapname + "\n" + gametypeToName(strTok(level.__mapvote["map2"].gametype, ";@")[0]), "objective", 1.1, "center", "center", 0, -325, (1, 1, 1), 1, (0, 0, 0), 0.5, 5, 1);
	mapUI3 = level createString("^7" + level.__mapvote["map3"].mapname + "\n" + gametypeToName(strTok(level.__mapvote["map3"].gametype, ";@")[0]), "objective", 1.1, "center", "center", 220, -325, (1, 1, 1), 1, (0, 0, 0), 0.5, 5, 1);

	mapUIBTXT1 = level createRectangle("center", "center", -220, 0, 205, 32, (1, 1, 1), "black", 3, 0, 1);
	mapUIBTXT2 = level createRectangle("center", "center", 0, 0, 205, 32, (1, 1, 1), "black", 3, 0, 1);
	mapUIBTXT3 = level createRectangle("center", "center", 220, 0, 205, 32, (1, 1, 1), "black", 3, 0, 1);

	level notify("mv_start_animation");
	mapUI1 affectElement("y", 1.2, -6);
	mapUI2 affectElement("y", 1.2, -6);
	mapUI3 affectElement("y", 1.2, -6);
	mapUIBTXT1 affectElement("alpha", 1.5, 0.8);
	mapUIBTXT2 affectElement("alpha", 1.5, 0.8);
	mapUIBTXT3 affectElement("alpha", 1.5, 0.8);

	wait 1;
	level notify("mv_start_vote");

	mv_sentence = getDvar("mv_sentence");
	mv_socialname = getDvar("mv_socialname");
	mv_sociallink = getDvar("mv_sociallink");
	credits = level createServerFontString("objective", 1.2);
	credits setPoint("center", "center", -300, 150);
	credits setText(mv_sentence + "\nAdapted by @^5jombo.uk ^7\n" + mv_socialname + ": " + mv_sociallink);

	timer = level createServerFontString("objective", 2);
	timer setPoint("center", "center", 0, -140);
	timer setTimer(level.__mapvote["time"]);
	wait level.__mapvote["time"];
	level notify("mv_destroy_hud");

	credits affectElement("alpha", 0.5, 0);
	buttons affectElement("alpha", 0.5, 0);
	mapUI1 affectElement("alpha", 0.5, 0);
	mapUI2 affectElement("alpha", 0.5, 0);
	mapUI3 affectElement("alpha", 0.5, 0);
	mapUIBTXT1 affectElement("alpha", 0.5, 0);
	mapUIBTXT2 affectElement("alpha", 0.5, 0);
	mapUIBTXT3 affectElement("alpha", 0.5, 0);
	timer affectElement("alpha", 0.5, 0);

	foreach (player in level.players)
	{
		player notify("done");
		player SetBlurForPlayer(0, 0);
	}
}

onPlayerConnected()
{
	level endon("game_ended");
	for (;;)
	{
		level waittill("connected", player);
		player thread FixBlur();
	}
}

FixBlur() 
{
	self endon("disconnect");
	level endon("game_ended");
	self waittill("spawned_player");
	self SetBlurForPlayer(0, 0);
}

main()
{
    // Try to replace regular mp endgame
	replacefunc(scripts\mp\gamelogic::endgame, ::stub_endgame_regularmp);
}

stub_endgame_regularmp(var_0, var_1, var_2)
{
	if (!isdefined(var_2))
		var_2 = 0;

    // Use scripts\mp\utility::gameFlag instead of level.gtnw checks if unsure, but let's stick to simple checks
	if (game["state"] == "postgame" || level.gameEnded)
		return;

	// setomnvar("ui_pause_menu_show", 0);
	game["state"] = "postgame";
	setdvar("ui_game_state", "postgame");
	level.gameendtime = gettime();
	level.gameended = 1;
	level.ingraceperiod = 0;
	level notify("game_ended", var_0);
    
    // IW7 utility calls
	scripts\mp\utility::gameflagset("game_over");
	scripts\mp\utility::gameflagset("block_notifies");
	
    scripts\engine\utility::waitframe();
    
	setgameendtime(0);
    
    // Some stats handling, might be broken if functions differ, but try:
    /*
	var_3 = getmatchdata("gameLength");
	var_3 += int(scripts\mp\utility::getsecondspassed());
	setmatchdata("gameLength", var_3);
    */

	if (isdefined(var_0) && isstring(var_0) && var_0 == "overtime")
	{
		level.finalkillcam_winner = "none";
        // Assuming endgameovertime exists and is accessible
		// scripts\mp\gamelogic::endgameovertime(var_0, var_1);
		return;
	}

	if (isdefined(var_0) && isstring(var_0) && var_0 == "halftime")
	{
		level.finalkillcam_winner = "none";
		// scripts\mp\gamelogic::endgamehalftime();
		return;
	}

    // Skipping stat persistence complexity for safe adaptation first
	
    // Round Logic
    /*
	if (level.teambased)
	{
		if (var_0 == "axis" || var_0 == "allies")
			game["roundsWon"][var_0]++;

		scripts\mp\gamescore::updateteamscore("axis");
		scripts\mp\gamescore::updateteamscore("allies");
	}
    */
    
	foreach (var_5 in level.players)
	{
		var_5 setclientdvar("ui_opensummary", 1);
		if (scripts\mp\utility::wasonlyround() || scripts\mp\utility::waslastround())
        {
             // Clear killstreaks?
             // var_5 scripts\mp\killstreaks\killstreaks::clearkillstreaks();
        }
			
	}

	setdvar("g_deadChat", 1);
	setdvar("ui_allow_teamchange", 0);
	setdvar("bg_compassShowEnemies", 0);
	// freezeallplayers replacement
	foreach (player in level.players)
		player scripts\mp\utility::freezecontrolswrapper(1);

	// if (!var_2)
	// 	visionsetnaked("mpOutro", 0.5);

	if (!scripts\mp\utility::wasonlyround() && !var_2)
	{
		// displayroundend(var_0, var_1);
        // ... Round switch logic ...
	}

    // Killcam logic simplified
	victim = undefined;
	attacker = undefined;
	if (isdefined(level.finalkillcam_winner) && isdefined(level.finalkillcam_victim) && isdefined(level.finalkillcam_victim[level.finalkillcam_winner]))
		victim = level.finalkillcam_victim[level.finalkillcam_winner];
	if (isdefined(level.finalkillcam_winner) && isdefined(level.finalkillcam_attacker) && isdefined(level.finalkillcam_attacker[level.finalkillcam_winner]))
		attacker = level.finalkillcam_attacker[level.finalkillcam_winner];

	wait 2;
	killcamExist = 0; // Force skip killcam for now to ensure mapvote shows
	
	scripts\mp\utility::gameflagclear("block_notifies");

    // START MAPVOTE
	[[level.startmapvote]] ();
    
    // After mapvote
	level.intermission = 1;
	level notify("start_custom_ending");
	level notify("spawning_intermission");

	foreach (var_5 in level.players)
	{
		var_5 notify("reset_outcome");
		var_5 thread scripts\mp\playerlogic::spawnintermission();
	}

	wait(min(10.0, 4.0 + level.postGameNotifies));

	setnojipscore(0);
	setnojiptime(0);
	level notify("exitLevel_called");
	exitlevel(0); // This rotates the map
}


maptoname(mapid)
{
	mapid = tolower(mapid);
    
    // IW7 Map Names
	if (mapid == "mp_parkour") return "Breakout";
	if (mapid == "mp_quarry") return "Crusher";
	if (mapid == "mp_divide") return "Scorch";
	if (mapid == "mp_riot") return "Retaliation";
	if (mapid == "mp_frontier") return "Frontier";
	if (mapid == "mp_desert") return "Grounded";
	if (mapid == "mp_metropolis") return "Frost";
	if (mapid == "mp_proto") return "Prototype";
	if (mapid == "mp_fallen") return "Fallen";
	if (mapid == "mp_skyway") return "Terminal";
	if (mapid == "mp_rivet") return "Skydock";
	if (mapid == "mp_breakneck") return "Mayday";
	if (mapid == "mp_dome_iw") return "Genesis";
	if (mapid == "mp_dome_dusk") return "Genesis Dusk";
	if (mapid == "mp_afghan") return "Afghan";
	if (mapid == "mp_geneva") return "Renaissance";
	if (mapid == "mp_neon") return "Neon";
	if (mapid == "mp_prime") return "Noir";
	if (mapid == "mp_marsoasis") return "Turista";
	if (mapid == "mp_flip") return "Archive";
	if (mapid == "mp_junk") return "Scrap";
	if (mapid == "mp_mansion") return "Hartmann";
	if (mapid == "mp_turista2") return "Turista 2";
	if (mapid == "mp_paris") return "Ember";
	if (mapid == "mp_pixel") return "Bermuda";
	if (mapid == "mp_overflow") return "Fore";
	if (mapid == "mp_nova") return "Permafrost";
	if (mapid == "mp_hawkwar") return "Heartland";
	if (mapid == "mp_depot") return "Depot 22";
	if (mapid == "mp_rally") return "Carnage";
	if (mapid == "mp_codphish") return "Altitude";
	if (mapid == "mp_permafrost2") return "Permafrost 2";
	if (mapid == "mp_renaissance2") return "Renaissance 2";
	if (mapid == "mp_carnage2") return "Carnage 2";

	return mapid;
}

gametypeToName(gametype)
{
	switch (tolower(gametype))
	{
	case "war": return "Team Deathmatch";
	case "dm": return "Free for all";
	case "dom": return "Domination";
	case "conf": return "Kill Confirmed";
	case "sd": return "Search & Destroy";
	case "ctf": return "Capture the Flag";
    case "ball": return "Uplink";
    case "infect": return "Infected";
    case "gun": return "Gun Game";
    case "tdef": return "Defender";
    case "siege": return "Reinforce";
    case "sr": return "Search & Rescue";
    case "grind": return "Grind";
    case "front": return "Frontline";
	}
	return gametype;
}

// UI Utils
isValidColor(value)
{
	return value == "0" || value == "1" || value == "2" || value == "3" || value == "4" || value == "5" || value == "6" || value == "7";
}

GetColor(color)
{
	switch (tolower(color))
	{
	case "red": return (0.960, 0.180, 0.180);
	case "black": return (0, 0, 0);
	case "grey": return (0.035, 0.059, 0.063);
	case "purple": return (1, 0.282, 1);
	case "pink": return (1, 0.623, 0.811);
	case "green": return (0, 0.69, 0.15);
	case "blue": return (0, 0, 1);
	case "lightblue": 
	case "light blue": return (0.152, 0.329, 0.929);
	case "lightgreen": 
	case "light green": return (0.09, 1, 0.09);
	case "orange": return (1, 0.662, 0.035);
	case "yellow": return (0.968, 0.992, 0.043);
	case "brown": return (0.501, 0.250, 0);
	case "cyan": return (0, 1, 1);
	case "white": return (1, 1, 1);
	}
    return (1,1,1);
}

CreateString(input, font, fontScale, align, relative, x, y, color, alpha, glowColor, glowAlpha, sort, isLevel)
{
	if (!isDefined(isLevel))
		hud = self createFontString(font, fontScale);
	else
		hud = level createServerFontString(font, fontScale);

	hud setText(input);
	hud.x = x;
	hud.y = y;
	hud.align = align;
	hud.horzalign = align;
	hud.vertalign = relative;
	hud setPoint(align, relative, x, y);
	hud.color = color;
	hud.alpha = alpha;
	hud.glowColor = glowColor;
	hud.glowAlpha = glowAlpha;
	hud.sort = sort;
	hud.alpha = alpha;
	hud.archived = 0;
	hud.hideWhenInMenu = 0;
	return hud;
}

CreateRectangle(align, relative, x, y, width, height, color, shader, sort, alpha, islevel)
{
	if (isDefined(isLevel))
		boxElem = newhudelem();
	else
		boxElem = newclienthudelem(self);
	
	boxElem.elemtype = "icon"; // Changed from 'bar' which requires a .bar child to prevent script runtime errors
	boxElem.width = width;
	boxElem.height = height;
	boxElem.align = align;
	boxElem.relative = relative;
	boxElem.horzalign = align;
	boxElem.vertalign = relative;
	boxElem.xOffset = 0;
	boxElem.yOffset = 0;
	boxElem.children = [];
	boxElem.sort = sort;
	boxElem.color = color;
	boxElem.alpha = alpha;
	boxElem setParent(level.uiparent);
	boxElem setShader(shader, width, height);
	boxElem.hidden = 0;
	boxElem setPoint(align, relative, x, y);
	boxElem.hideWhenInMenu = 0;
	boxElem.archived = 0;
	return boxElem;
}

createServerFontString(font, fontScale) 
{
	hud = newHudElem();
	hud.elemtype = "font";
	hud.font = font;
	hud.fontscale = fontScale;
	hud.x = 0;
	hud.y = 0;
	hud.width = 0;
	hud.height = int(level.fontheight * fontScale);
	hud.xOffset = 0;
	hud.yOffset = 0;
	hud.children = [];
	hud setParent(level.uiparent);
	hud.hidden = 0;
	return hud;
}

SetDvarIfNotInizialized(dvar, value)
{
	if (!isDefined(getDvar(dvar)) || getDvar(dvar) == "")
		setDvar(dvar, value);
}

affectElement(type, time, value)
{
    if (type == "x" || type == "y")
    {
        self moveOverTime(time);
        if (type == "x") self.x = value;
        if (type == "y") self.y = value;
    }
    else if (type == "alpha")
    {
        self fadeOverTime(time);
        self.alpha = value;
    }
    else if (type == "color")
    {
        // Color transition not natively supported by simple command usually, just set it for now or implement thread if needed
        self.color = value;
    }
}
