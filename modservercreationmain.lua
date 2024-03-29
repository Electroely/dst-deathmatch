GLOBAL.EVENTSERVER_LEVEL_LOCATIONS["DEATHMATCH"] = {"deathmatch"}
--These things need to exist for the ServerSettingsScreen to apply the game mode properly
--modservercreationmain.lua is loaded before modworldgenmain.lua, so how exactly do i do this
--without defining all the same things twice?
AddTaskSet("deathmatch_taskset", {
    name = "Deathmatch Arenas",
    location = "forest",
    tasks = {
        "Deathmatch_WorldTask",
    },
    valid_start_tasks = {
        "Deathmatch_WorldTask",
    },
	set_pieces = {
	},
	has_ocean = true,
})
AddLocation({
    location = "deathmatch",
    version = 2,
    overrides = {
        task_set = "deathmatch_taskset",
        start_location = "deathmatch",
        season_start = "default",
        world_size = "small",
        layout_mode = "RestrictNodesByKey",
        keep_disconnected_tiles = true,
        wormhole_prefab = nil,
        roads = "never",
    },
    required_prefabs = {
    },
})
AddStartLocation("deathmatch", {
    name = "Deathmatch",
    location = "deathmatch",
    start_setpeice = "DeathmatchArena",
    start_node = "Blank",
})
GLOBAL.LEVELTYPE.DEATHMATCH = "DEATHMATCH"
AddLevel("DEATHMATCH", {
        id = "DEATHMATCH",
        name = "Deathmatch Arenas",
        desc = "Duke it out with your friends in a redesigned Player vs Player gamemode!",
        location = "deathmatch", -- this is actually the prefab name
        version = 3,
        overrides={
			boons = "never",
			touchstone = "never",
            traps = "never",
            poi = "never",
            protected = "never",
			disease_delay = "none",
			prefabswaps_start = "classic",
            petrification = "none",
			wildfires = "never",
			world_size = "huge",
        },
        background_node_range = {0,1},
    })

local servercreationscreen = GLOBAL.TheFrontEnd:GetActiveScreen()
if servercreationscreen and servercreationscreen.name == "ServerCreationScreen" then
	local server_settings = servercreationscreen.server_settings_tab
	local server_name = server_settings.server_name
	if server_name.textbox:GetString() == GLOBAL.TheNet:GetLocalUserName().."'s World" then
		print("default server name, changing")
		local new_name = GLOBAL.TheNet:GetLocalUserName().."'s Arena"
		server_name.textbox:SetString(new_name)
		server_name.textbox:OnTextInputted()
	end
	server_settings:UpdateModeSpinner()
	local game_mode = server_settings.game_mode
	game_mode.spinner:SetSelected("deathmatch")
	local pvp = server_settings.pvp
	pvp.spinner:SetSelected(true)
else
	
end
