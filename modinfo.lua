--The name of the mod displayed in the 'mods' screen.
name = "Deathmatch"
if folder_name == "dst-deathmatch" then
	name = "Deathmatch (GIT)"
end
--A description of the mod.
description = [[A new gamemode where you can fight your friends using weapons from the Forge!

Create a new world with the mod enabled to get started!

If any issues arise, please ensure the game mode is set to "Deathmatch" and that PvP is enabled.
]]
--Who wrote this awesome mod?
author = "Electroely"

--A version number so you can ask people if they are running an old version of your mod.
version = "1"

--This lets other players know if your mod is out of date. This typically needs to be updated every time there's a new game update.
api_version = 10

dst_compatible = true

--This lets clients know if they need to get the mod from the Steam Workshop to join the game
all_clients_require_mod = true

--This determines whether it causes a server to be marked as modded (and shows in the mod list)
client_only_mod = false

--This lets people search for servers with this mod by these tags
server_filter_tags = {"deathmatch", "arena", "arenas", "brawl", "arena brawl"}

icon_atlas = "modicon.xml"
icon = "modicon.tex"

configuration_options = {}

game_modes = {
	{ name = "deathmatch",
		label = "Deathmatch",
		description = [[Last one standing wins!

*Fight in Deathmatch Arenas using weapons from The Forge!
*Stay near the middle to pick up boosts and gain an advantage!
*Brawl in a free-for-all or team up with your friends!]],
		settings = {
			level_type = "DEATHMATCH",
			spawn_mode = "fixed",
			resource_renewal = false,
			ghost_sanity_drain = false,
			ghost_enabled = false,
			revivable_corpse = true, 
			spectator_corpse = false, -- custom spectator corpse component, no need for this
			portal_rez = false,
			reset_time = nil,
			invalid_recipes = nil,
			--
			override_item_slots = 9,
			no_air_attack = true,
			no_crafting = true,
			no_minimap = true,
			no_hunger = true,
			no_sanity = true,
			no_avatar_popup = true,
			no_morgue_record = true,
			--override_normal_mix = "lavaarena_normal",
			--override_lobby_music = "dontstarve/creatures/together/hutch/one_man_band",
			--lobbywaitforallplayers = true,
			--hide_worldgen_loading_screen = true,
			--hide_received_gifts = true,
			--skin_tag = "LAVA",
		},
	}
}

priority = 999999999999999
