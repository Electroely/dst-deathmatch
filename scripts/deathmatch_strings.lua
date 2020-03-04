
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
	POPUPS = {
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
		}
	},
	
	INFO_POPUPS = {
		JOIN = {
			icon = "spear_rose.tex",
			title = "Welcome!",
			text_body = "Say pal, looks like you're new 'round here! Welcome to the Deathmatch Arena! Here you'll be able to fight others in different arenas to claim victory of number one spot. As you do things these info boxes will popup to give you information on the several mechancis and items in Deathmatch."
		}
	}
}
