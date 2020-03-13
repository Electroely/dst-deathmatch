
--putting all the strings here would make it more organized and allow for
--easier translation in case that becomes a thing
return {
	CHATMESSAGES = {
		DESPAWN_MIDMATCH = "Can't despawn during a match!",
		DESPAWN_STARTING = "Can't despawn during match startup!",
		STARTMATCH_VOTEACTIVE = "Can't start deathmatch while vote is active.",
		
		JOIN_MIDMATCH = "A match is currently in progress. Please wait until it ends or spectate using /spectate.",
		JOIN_ALONE = "Two or more people are required to play. Use \"/dm start\" to start.",
	},
	ANNOUNCE = {
		MATCHOVER = "Deathmatch is over!",
		MATCHRESET = "Starting next deathmatch in 10 seconds...",
		MATCHINIT = "Preparing players for next match...",
		MATCHBEGIN = "Deathmatch started!",
		LATEJOIN = "Player joined late! Restarting deathmatch initiation!",
		NEARSTARTDESPAWN = "Restarting deathmatch initiation for despawning player.",
		
		SETTEAMMODE = "Set deathmatch team mode to %s.",
		SETTEAMMODE_CUSTOM = "Set deathmatch mode to custom. Use /setteam before a match starts to assign custom teams.",
		SETTEAMMODE_RVB = "Set deathmatch mode to %s. Use /team to pick a side, or stay neutral to be randomized.",
	},
	USERCOMMANDS = {
		SETTEAM = {
			NAME = "Set Team",
			DESC = "Change your team to red, blue, yellow, green, orange, cyan, pink, or black."
		},
		SPECTATE = {
			NAME = "Spectate",
			DESC = "Turn into a ghost player to spectate on the match.",
		},
		AFK = {
			NAME = "Toggle AFK",
			DESC = "Toggle permanent spectator mode."
		},
		SETSTATE = {
			NAME = "Change Look",
			DESC = "Change your look to another your character can take.",
		},
		DEATHMATCH = {
			NAME = "Deathmatch Action",
			DESC = "Valid actions: start, stop"
		},
		DESPAWN = {
			NAME = "Despawn",
			DESC = "Go back to the character selection screen."
		},
		SETTEAMMODE = {
			NAME = "Team Mode",
			DESC = "Change deathmatch team mode to Free for all, Red VS Blue or 2-Player Teams.",
			VOTENAME = "Change Team Mode",
			VOTETITLE = "Change team mode to...",
		},
		SETARENA = {
			NAME = "Change Arena",
			DESC = "Choose between the available arenas in the game.",
			VOTENAME = "Change Arena",
			VOTETITLE = "Change arena to...",
		},
	},
	
	PAIRWITH_ACTION = {
		GENERIC = "Team up with",
		DISBAND = "Disband"
	},
	POPUPS = { --newlines and tabs are ignored when loading body strings
				--*NEWLINE gets parsed into a newline
		WELCOME = {
			TITLE = "Welcome to Deathmatch!",
			BODY = [[
				Welcome to Deathmatch! In this mode, you can fight 
				other players in battle arenas using weapons from 
				The Forge! This window will show you various tips as 
				new things happen while you play. You can view all 
				tips by typing "/dm help" in chat. 
				You'll need two or more people to play. Once ready, you 
				can type "/dm start" to start a match. Have fun!
			]]
		},
		TEAMS_ENABLED = { --shows up when a match actually starts or when player enters a team
			TITLE = "Team Battles",
			BODY = [[
				In team battles, your goal is to be the last team standing. 
				You can't hurt your teammates with any attacks.*NEWLINE
				You can revive fallen teammates, too. Reviving someone the first time 
				only takes a couple of seconds, but the time it takes doubles every 
				time someone's revived. Reviving with a Telltale Heart equipped 
				will always take 2 seconds, but comes with a cost...
			]]
		},
		--teammode specific popups happen when the player enters lobby
		--the first time after the teammode is enabled
		TEAMMODE_HALF = {
			TITLE = "Red vs. Blue",
			BODY = [[
				In the Red vs. Blue team mode, you're placed into one of 
				two teams. You can type "/team" followed by "red", "blue", 
				or "none" before a match starts to pick whether you want to be 
				on a specific team or if you could go either way.*NEWLINE
				It'd be a good idea to make sure none of your teammates are 
				left alone. A numbers disadvantage is the last thing you'd want.
			]]
		},
		TEAMMODE_PAIRS = {
			TITLE = "2-Player Teams",
			BODY = [[
				In the 2-Player Teams team mode, you're paired up with one 
				other person. You can choose who to be paired with by clicking 
				the player in the lobby, and telling them to do the same. *NEWLINE
				Make sure to be there for your teammate when they need you, 
				and revive them if they die!
			]]
		},
		--if a player goes for too long without using a weapon ability
		CASTAOEEXPLAIN = {
			TITLE = "Using the Weapons",
			BODY = [[
				The weapons you can use in this game mode each have a unique 
				ability. You can use this ability by pressing the right mouse button 
				with your weapon equipped. Different abilities are good at different 
				jobs, so try to make use of them all. 
			]]
		},
		--when a player picks up a firebomb
		FIREBOMBEXPLAIN = {
			TITLE = "Hearthsfire Crystals",
			BODY = [[
			
			]]
		},
		--when a player picks up a telltale heart
		REVIVERHEARTEXPLAIN = {
			TITLE = "Telltale Hearts",
			BODY = [[
			
			]]
		},
		
		------ below this line are tips only available through /dm help
		PICKUPEXPLAIN = {
			TITLE = "About Powerups",
			BODY = [[
				
			]]
		},
		DESPAWNEXPLAIN = {
			TITLE = "Changing Characters",
			BODY = [[
			
			]]
		},
		
		SIZETEST = {
			TITLE = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
			BODY = [[
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			]],
		},
	},
}
