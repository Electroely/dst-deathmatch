
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
		welcome = {
			"Welcome to Deathmatch",
			[[Fight other players using weapons from The Forge in this arena-based player vs player gamemode!
			Please read the Info Sign for more information.
			]] 
			},
		welcome_loner = {
			"Welcome to Deathmatch",
			[[This is a PvP game mode, so you'll need other players to play.
			Please read the Info Sign for more information.
			]]
		},
		infosign_1 = {
			"Starting a match",
			[[You can start a Deathmatch by typing the chat command '/dm start'.
			(The Info Sign will show more info if read again)
			]]
		},
		infosign_2 = {
			"Spectating (1)",
			[[If you die, you can spectate by selecting which player you want to watch on-screen.
			You can also turn yourself into a ghost by typing /spectate. 
			]]
		},
		infosign_3 = {
			"Spectating (2)",
			[[Please note that you cannot be revived in team battles if you're a ghost.
			Also note that you can return to the lobby by typing /spectate as a ghost.]]
		},
		infosign_4 = {
			"Combat",
			[[You have access to 4 weapons. 
			They all do the same damage in a melee attack, but each has a unique ability you can use by right-clicking.]],
		},
		infosign_5 = {
			"Playing in Teams",
			[[You can start a vote to enable or disable teams. There's two options:
			Red vs Blue splits the players into two teams.
			2-Player Teams groups the players in pairs.]]
		},
		infosign_6 = {
			"Changing the Arena",
			[[You can start a vote to change the selected arena. There are 3 options:
			Atrium, Desert and Pig Village.
			Voting for an arena mid-match will apply the change in the next match.]]
		},
		infosign_7 = {
			"Items",
			[[You can pick up various stat boosts that spawn in the middle of the arena.
			You can also find one-time use weapons like the Hearthsfire Crystals.]]
		}
	}
}
