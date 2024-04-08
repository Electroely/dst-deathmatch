
--putting all the strings here would make it more organized and allow for
--easier translation in case that becomes a thing
return {

	STARTMATCH = "Start Match",
	STOPMATCH = "Stop Match",
	TEAMSELECT = "Team Select",
	TEAMMODE = "Game Mode",
	ARENAS = "Arena Select",
	
	RANDOM = "Random",
	
	TEAMMODE_FFA = "Free For All",
	TEAMMODE_RVB = "Red vs. Blue",
	TEAMMODE_2PT = "2-Player Teams",
	TEAMMODE_CUSTOM = "Custom Teams",
	
	ARENA_ATRIUM = "The Atrium",
	ARENA_DESERT = "The Badlands",
	ARENA_MOONISLAND = "Lunar Island",
	ARENA_STALKER = "The Forest",
	ARENA_PIGVILLAGE = "Pig King's Village",
	ARENA_RANDOM = "Random",
	
	GOBACK = "Go Back",
	DESPAWN = "Change Characters",
	RESPEC = "Reset Insight",
	SETSTATE = "Change Look",
	TIPS_BUTTON = "Tips",

	MATCH_STARTING_HURRY = "A new match starts in %s, hurry up!",
	
	DEAD_ALONE_PROMPT = "You're out! Wait for the next match.",
	DEAD_TEAM_PROMPT = "If you have any teammates, tell them to revive you!",
	SKILLTREETOAST_PROMPT = "Insight Available!",

	CANT_DITCH_TEAMMATES_SPECTATE = "Your teammates can save you! You can't spectate now.",

	STATUS = {
		TITLE = "Deathmatch Status:",
		MATCHSTATUS = {
			[0] = "Waiting for next match...",
			[1] = "Match in progress!",
			[2] = "Preparing next match...",
			[3] = "Starting next match...",
		}
	},
	WARNINGS = {
		AFK_MANUAL = "You're AFK. You will spectate matches until you type /afk again.",
		AFK_AUTO =  "You're AFK. You will spectate matches until you move again.",
		REVIVE_TEAMMATE = "A member of your team has fallen. Revive them!",
		SKILLTREE = "You have unused Insight!",
	},

	BUFFS = {
		buff_pickup_lightdamaging = {
			TITLE = "Damage Boost",
			DESC = "+50% damage dealt",
		},
		buff_pickup_lightdefense = {
			TITLE = "Defense Boost",
			DESC = "-50% damage taken",
		},
		buff_pickup_lightspeed = {
			TITLE = "Speed Boost",
			DESC = "+50% movement speed"
		},
		buff_healingstaff_ally = {
			TITLE = "Life Blossoms",
			DESC = subfmt("-{reduction}% damage taken", {reduction=math.floor((1-DEATHMATCH_TUNING.FORGE_MAGE_HEALBLOOMS_DEFENSE)*100)})
		},
		buff_healingstaff_enemy = {
			TITLE = "Hindering Life Blossoms",
			DESC = "-40% movement speed"
		},
		buff_deathmatch_damagestack = {
			TITLE = "Strengthening Attacks",
			DESC = "+%2d%% damage dealt"
		},
		TIMERSTRING = "%2d seconds remaining",
	},

	CHARACTER_DESCRIPTIONS = "*Is a capable fighter",
	CHARACTER_SURVIVABILITY = "Slim",
	STARTING_ITEMS_TITLE = "Enters the Arena With",
	STARTING_ITEMS_NONE = "Various weapons",
	
	SKILLTREE_DESC = "Become a powerful fighter!",
	SKILLTREE = {
		PANELS = {
			SPELLCASTER = "SPECIAL",
			BRAWLER = "DAMAGE",
			IMPROVISER = "HEARTHSFIRE\nCRYSTALS",
			LOADOUT = "LOADOUTS",
		},
		LOADOUT_PICKONE_LOCK = "Choose a loadout before selecting any skills.",
		LOADOUT_ONLYONE_LOCK = "You can choose one loadout to take to battle.",
		
		SPELLCASTER_COOLDOWN_ONE_TITLE = "Reduced Cooldowns 1",
		SPELLCASTER_COOLDOWN_TWO_TITLE = "Reduced Cooldowns 2",
		SPELLCASTER_REFRESH_ON_HIT_TITLE = "Refreshing Attacks",
		BRAWLER_DAMAGE_ONE_TITLE = "Increased Damage 1",
		BRAWLER_DAMAGE_TWO_TITLE = "Increased Damage 2",
		BRAWLER_BUFF_ON_HIT_TITLE = "Strengthening Attacks",
		IMPROVISER_BOUNCING_BOMBS_TITLE = "Bouncing Bottles",
		IMPROVISER_HOMING_BOMBS_TITLE = "Homing Crystals",
		IMPROVISER_PASSIVE_BOMBS_TITLE = "Pocket Bombs",
		IMPROVISER_BURNING_BOMBS_TITLE = "Lingering Flames",
		LOADOUT_FORGE_MELEE_TITLE = "Forge Warrior",
		LOADOUT_FORGE_MAGE_TITLE = "Forge Warlock",
		
		SPELLCASTER_COOLDOWN_ONE_DESC = "Reduces special attack cooldowns by %d%%.",
		SPELLCASTER_COOLDOWN_TWO_DESC = "Reduces special attack cooldowns by %d%%.",
		SPELLCASTER_REFRESH_ON_HIT_DESC = "Regular attacks shorten all active special attack cooldowns.",
		
		BRAWLER_DAMAGE_ONE_DESC = "Increases all damage dealt by %d%%.",
		BRAWLER_DAMAGE_TWO_DESC = "Increases all damage dealt by %d%%.",
		BRAWLER_BUFF_ON_HIT_DESC = "Regular attacks temporarily increase your damage by %d%%, stacking up to %d times.",
		
		IMPROVISER_BOUNCING_BOMBS_DESC = "Hearthsfire crystals will bounce in the air when landing after being thrown, causing them to explode again. Charging the crystals before throwing them causes them to bounce more times.",
		IMPROVISER_PASSIVE_BOMBS_DESC = "Hearthsfire crystals will charge when you land regular attacks. Getting hit causes charged crystals to explode, damaging nearby enemies.",
		IMPROVISER_HOMING_BOMBS_DESC = "Thrown Hearthsfire crystals will home in on nearby opponents. Crystals are thrown at a higher arc when this skill is active.",
		IMPROVISER_BURNING_BOMBS_DESC = "Hearthsfire crystals will leave a ring of fire after exploding, dealing piercing damage to players inside. Charging the crystals before throwing them increases the damage.",
		
		LOADOUT_FORGE_MELEE_DESC = "The Forge's warriors use many melee weapons specializing in different situations for highly effective close-range combat.",
		LOADOUT_FORGE_MAGE_DESC = "The Forge's warlocks make up for their lack of defensive capabilities with long range and powerful magic attacks.",
	},

	CHATMESSAGES = {
		DESPAWN_MIDMATCH = "Can't despawn during a match!",
		DESPAWN_STARTING = "Can't despawn during match startup!",
		STARTMATCH_VOTEACTIVE = "Can't start deathmatch while vote is active.",
		
		JOIN_MIDMATCH = "A match is currently in progress. Please wait until it ends or spectate using /spectate.",
		JOIN_ALONE = "Two or more people are required to play. Use \"/dm start\" to start.",
		JOIN_LOBBY = "Welcome to Deathmatch! Use \"/dm start\" to start a match.",
	},
	ANNOUNCE = {
		MATCHOVER = "Match is over!",
		MATCHRESET = "Starting next match in 10 seconds...",
		MATCHINIT = "Preparing players for next match...",
		MATCHBEGIN = "Match started!",
		LATEJOIN = "A player joined late! Restarting match initiation!",
		NEARSTARTDESPAWN = "Restarting match initiation for despawning player.",

		WINNER_TEAM = "{team} wins!",
		WINNER_SOLO = "{player} wins with {health} health remaining!",
		WINNER_DUO = "{player1} and {player2} win!",
		
		SETTEAMMODE = "Set team mode to %s.",
		SETTEAMMODE_CUSTOM = "Set mode to custom. Use /setteam before a match starts to assign custom teams.",
		SETTEAMMODE_RVB = "Set mode to %s. Use /team to pick a side, or stay neutral to be randomized.",
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
	TIPS = { --newlines and tabs are ignored when loading body strings
				--*NEWLINE gets parsed into a newline
		WELCOME = {
			TITLE = "Deathmatch",
			BODY = [[
				Fight to the death!*NEWLINE*NEWLINE
				The objective is simple. Be the last one standing.*NEWLINE
				All the characters are the same. Every weapon has a unique special attack. Stay near where the items show up to get an edge in battle!*NEWLINE*NEWLINE
				To change the mode or arena, use the top right buttons! Most players must agree on the same options. By default, the game is a Free For All at The Atrium.
			]]
		},
		TEAMS = {
			TITLE = "Team Matches",
			BODY = [[
				Using the buttons in the top right, you can change the team mode to choose between Free For All, Red vs. Blue or 2-Player Teams.*NEWLINE*NEWLINE
				- In a Free For All, it's every survivor for themselves! Kill everyone else and stay the last one standing.*NEWLINE*NEWLINE
				- In Red vs. Blue, everyone is split into two teams. Teammates can't hurt each other, and if one falls another can come to the rescue and revive them using 
				either their bare hands or a Telltale Heart.*NEWLINE*NEWLINE
				- The rules for 2-Player Teams are the same as Red vs. Blue. Only the grouping of players is different - everyone is paired with one other player to form a team.
			]]
		},
		ARENAS = {
			TITLE = "Arenas",
			BODY = [[
				Using the buttons in the top right, you can change the battle arena to choose between The Atrium, The Badlands and Pig King's Village.*NEWLINE*NEWLINE
				- In The Atrium, The Badlands and Pig King's Village, you might fight over control of the center of the map to gain powerful items.*NEWLINE*NEWLINE
				- In the Lunar Island and The Forest, items don't always spawn in the center - follow their source to stay at the top!
			]]
		},
		SKILLTREE = {
			TITLE = "Insight",
			BODY = [[
				You can use insight to get stronger! You start with 6 points, one of which must be used to select a loadout.*NEWLINE
				Loadouts are sets of weapons you take to battle. By default, you use the Forge's Warrior loadout.*NEWLINE*NEWLINE
				On the left, you can choose between stat increases, culminating in a powerful effect that activates every time you attack an enemy.*NEWLINE
				In the middle, you can choose skills to improve Hearthsfire Crystals - powerful consumable items picked up during a match.
			]]
		},
		FIREBOMB = {
			TITLE = "Hearthsfire Crystals",
			BODY = subfmt([[
				DAMAGE (REGULAR): {melee} - DAMAGE (EXPLOSION): {explosion} - DAMAGE (SPECIAL): {special}*NEWLINE*NEWLINE
				Hearthsfire crystals are powerful consumable items you can pick up during a match.*NEWLINE*NEWLINE
				Hearthsfire crystals will build up charge when attacking other players. When fully charged - after 3 hits - attacking with them again will 
				cause them to explode, dealing lots of damage and stunning the target for a long time. Alternatively, they can be thrown to deal even more damage regardless of charge 
				level. 
			]], {melee = DEATHMATCH_TUNING.FIREBOMB_MELEE_DAMAGE, explosion = DEATHMATCH_TUNING.FIREBOMB_MELEE_EXPLOSION_DAMAGE, special = DEATHMATCH_TUNING.FIREBOMB_THROW_EXPLOSION_DAMAGE})
		},
		REVIVERHEART = {
			TITLE = "Telltale Hearts",
			BODY = [[
				In team battles, Telltale Hearts will appear. Telltale hearts can be used to revive fallen teammates. Reviving a teammate
				while holding one will greatly increase your revival speed, but they can also be thrown at their corpse to bring them back to life - but that comes at 
				a cost of their health.
			]]
		},
		FORGE_MELEE = {
			TITLE = "The Forge's Warrior",
			BODY = subfmt([[
				Starts with: Pith Pike, Spiral Spear, Forging Hammer, Blacksmith's Edge.*NEWLINE
				Max Health: {health}*NEWLINE*NEWLINE
				The Forge's Warrior is a loadout with a variety of melee weapons that can put up a fight in any scenario.*NEWLINE*NEWLINE
				The weapons allow for a lot of mobility which allows the user to dodge attacks and retaliate - sometimes at the same time! 
				It's good at keeping constant pressure while also defending from incoming attackers.
			]], {health = DEATHMATCH_TUNING.FORGE_MELEE_HEALTH})
		},
		PITHPIKE = {
			TITLE = "Pith Pike",
			BODY = subfmt([[
				DAMAGE (REGULAR): {melee} - DAMAGE (SPECIAL): {special} - COOLDOWN: 12*NEWLINE*NEWLINE
				The Pith Pike is a melee weapon that allows its user to dash in a straight line, damaging everything on the way.*NEWLINE*NEWLINE
				It can be used while running away from someone to deal damage to them and change directions. It can also traverse short gaps 
				and, with some prediction, hit someone trying to run away. It's very versatile!
			]], {melee = DEATHMATCH_TUNING.FORGE_MELEE_DAMAGE, special = DEATHMATCH_TUNING.FORGE_MELEE_PIKE_DAMAGE})
		},
		SPIRALSPEAR = {
			TITLE = "Spiral Spear",
			BODY = subfmt([[
				DAMAGE (REGULAR): {melee} - DAMAGE (SPECIAL): {special} - COOLDOWN: 12*NEWLINE*NEWLINE
				The Spiral Spear is a melee weapon with a high damage, long range jump that hits a small area.*NEWLINE*NEWLINE
				It can be used to dodge attacks, since the user is invulnerable while in the air. Dealing damage with it is 
				very reliant on prediction, but to do it successfully is very rewarding as it deals high damage and stuns those 
				hit by its special attack.
			]], {melee = DEATHMATCH_TUNING.FORGE_MELEE_DAMAGE, special = DEATHMATCH_TUNING.FORGE_MELEE_SPEAR_DAMAGE})
		},
		FORGINGHAMMER = {
			TITLE = "Forging Hammer",
			BODY = subfmt([[
				DAMAGE (REGULAR): {melee} - DAMAGE (SPECIAL): {special} - COOLDOWN: 12*NEWLINE*NEWLINE
				The Forging Hammer is a melee weapon with a special attack that hits a wide area, stunning those it hits.*NEWLINE*NEWLINE
				While it doesn't deal as much damage as the other special attacks, its wide area of effect makes it easy to corner enemies and stun them, allowing for easier 
				follow-up attacks.
			]], {melee = DEATHMATCH_TUNING.FORGE_MELEE_DAMAGE, special = DEATHMATCH_TUNING.FORGE_MELEE_HAMMER_DAMAGE})
		},
		BLACKSMITHSEDGE = {
			TITLE = "Blacksmith's Edge",
			BODY = subfmt([[
				DAMAGE (REGULAR): {melee} - COOLDOWN: 12*NEWLINE*NEWLINE
				The Blacksmith's Edge is a melee weapon that allows the user to parry attacks, reflecting the full damage back at the attacker.*NEWLINE*NEWLINE
				While it's best used to parry special attacks, using it on a regular attack will add a stunning effect to the reflected damage.
			]], {melee = DEATHMATCH_TUNING.FORGE_MELEE_DAMAGE})
		},
		FORGE_MAGE = {
			TITLE = "The Forge's Warlock",
			BODY = subfmt([[
				Starts with: Infernal Staff, Living Staff, Tome of Beckoning, Crown of Teleportation*NEWLINE
				Max Health: {health}*NEWLINE*NEWLINE
				The Forge's Warlock is a loadout that specializes in area control.*NEWLINE*NEWLINE
				Using powerful spells from a long distance, Warlocks can set up the battlefield in their favor to take advantage of 
				their increased attack range and items that appear during a match. If forced into close combat quarters, they can use the 
				Tome of Beckoning to summon a Magma Golem to assist, or skip the reading and bash someone away with it! The Crown of Teleportation 
				has a near-instant teleport that can give you an opening to cast one of the spells - they're not very quick to cast.
			]], {health = DEATHMATCH_TUNING.FORGE_MAGE_HEALTH})
		},
		INFERNALSTAFF = {
			TITLE = "Infernal Staff",
			BODY = subfmt([[
				DAMAGE (REGULAR): {melee} - DAMAGE (SPECIAL): {special} - COOLDOWN: 12*NEWLINE*NEWLINE
				The Infernal Staff is a ranged weapon capable of calling a meteor that deals a massive amount of damage after a short delay.*NEWLINE*NEWLINE
				The long time it takes to cast the meteor spell can make it difficult to land, but with its high casting range, the whereabouts of the meteor 
				can catch opponents off guard.
			]], {melee = DEATHMATCH_TUNING.FORGE_MAGE_DAMAGE, special = DEATHMATCH_TUNING.FORGE_MAGE_METEOR_DAMAGE})
		},
		LIVINGSTAFF = {
			TITLE = "Living Staff",
			BODY = subfmt([[
				DAMAGE (REGULAR): {melee} - COOLDOWN: 24*NEWLINE*NEWLINE
				The Living Staff is a ranged weapon capable of creating a field of Life Blossoms that reduce the damage taken by allies and slow the movement speed of opponents 
				inside.*NEWLINE*NEWLINE
				Opponents caught within the Life Blossoms are susceptible to ranged attacks.
				The protection they offer can be helpful for casting other spells without too much risk. 
			]], {melee = DEATHMATCH_TUNING.FORGE_MAGE_DAMAGE})
		},
		TOMEOFBECKONING = {
			TITLE = "Tome of Beckoning",
			BODY = subfmt([[
				DAMAGE (REGULAR): {melee} - COOLDOWN: 24*NEWLINE
				DAMAGE (SUMMON): {mindamage}-{damage} - HEALTH (SUMMON): {health}*NEWLINE*NEWLINE
				The Tome of Beckoning summons a Magma Golem that guards the area surrounding it, pelting opponents with fireballs.*NEWLINE*NEWLINE
				The Magma Golem can be used as a guardian when being chased by an opponent - if there's no room to cast it, the tome can be used as 
				a melee weapon to knock back opponents. The Magma Golem benefits from the Healing Staff's life blossoms, greatly increasing its survivability 
				against opposing Magma Golems or the Pith Pike's Pyre Poker attack.
			]], {melee = DEATHMATCH_TUNING.FORGE_MAGE_BOOK_DAMAGE, damage = DEATHMATCH_TUNING.FORGE_MAGE_SUMMON_DAMAGE,
			 mindamage = math.floor(DEATHMATCH_TUNING.FORGE_MAGE_SUMMON_DAMAGE*DEATHMATCH_TUNING.FORGE_MAGE_SUMMON_DAMAGE_PENALTY), health = DEATHMATCH_TUNING.FORGE_MAGE_SUMMON_HEALTH})
		},
		CROWNOFTELEPORTATION = {
			TITLE = "Crown of Teleportation",
			BODY = [[
				COOLDOWN: 12*NEWLINE*NEWLINE
				The Crown of Teleportation is a spell that can be used to teleport to a desired location almost instantly.*NEWLINE*NEWLINE
				As this is the Warlock's only form of mobility, it's best saved for when it's most important, such as when cornered or needing to 
				get an item before anyone else can get to it.

			]]
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
