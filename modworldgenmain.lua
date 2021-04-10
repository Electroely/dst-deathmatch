local G = GLOBAL
local FrontEndExists = false
for k, v in pairs(G) do
	if k == "TheFrontEnd" then
		FrontEndExists = true
	end
end
local Layouts = GLOBAL.require("map/layouts").Layouts
local StaticLayout = GLOBAL.require("map/static_layout")
local LOCKS = GLOBAL.LOCKS
local KEYS = GLOBAL.KEYS
Layouts["DeathmatchArena"] = StaticLayout.Get("map/static_layouts/arena_lobby", {
            start_mask = G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
            fill_mask = G.PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
            layout_position = G.LAYOUT_POSITION.CENTER,
        })
Layouts["DeathmatchArena"].ground_types[17] = G.GROUND.DECIDUOUS
Layouts["DeathmatchArena"].ground_types[18] = G.GROUND.DESERT_DIRT
Layouts["DeathmatchArena"].ground_types[19] = G.GROUND.OCEAN_SWELL
Layouts["DeathmatchArena"].ground_types[20] = G.GROUND.OCEAN_ROUGH
Layouts["DeathmatchArena"].ground_types[34] = G.GROUND.FUNGUSMOON
Layouts["DeathmatchArena"].ground_types[37] = G.GROUND.PEBBLEBEACH

G.EVENTSERVER_LEVEL_LOCATIONS["DEATHMATCH"] = {"deathmatch"}

local worldtiledefs = require("worldtiledefs")
local index_to_remove = nil
local removed_item = nil
local index_to_insert_at = nil
for k, v in pairs(worldtiledefs.ground) do
	if v[1] == G.GROUND.QUAGMIRE_GATEWAY then
		index_to_remove = k
		removed_item = v
	elseif v[1] == G.GROUND.QUAGMIRE_SOIL then
		index_to_insert_at = k
	end
end
table.remove(worldtiledefs.ground, index_to_remove)
table.insert(worldtiledefs.ground, index_to_insert_at, removed_item)
--[[ disabling mod whitelist for now because it's buggy and i don't like it
main reason i made this in the first place is because the darkness gimmick of atrium
is ruined by the nicknames mod, which a lot of people regularly use
i might just make the mod disable that mod (and a few others if necessary) and show an
ingame popup when that happens
update: looks like some people crash because of client mods... should i bring this back?
ill convert it to a blacklist... curse you, item info!]]
local mods_blacklist = {
	["workshop-347079953"]=true,
	["workshop-836583293"]=true,
	["workshop-1901927445"]=true,
	["workshop-2049203096"]=true,
	["workshop-2316507379"]=true,
	["workshop-1603516353"]=true,
}
local IsModCompatibleWithMode_old = G.KnownModIndex.IsModCompatibleWithMode 
G.KnownModIndex.IsModCompatibleWithMode = function(self, modname, dlc)
	--if (not mods_whitelist[modname]) and self.savedata.known_mods[modname] and self.savedata.known_mods[modname].disabled_incompatible_with_mode then
	if mods_blacklist[modname] then
		print("disabling ",modname," for being incompatible")
		return false
	end
	return IsModCompatibleWithMode_old(self, modname, dlc)
end
-- for k, v in pairs(G.KnownModIndex:GetClientModNames()) do
	-- --G.KnownModIndex:DisableBecauseIncompatibleWithMode(v)
	-- G.KnownModIndex.savedata.known_mods[v].disabled_incompatible_with_mode = true
-- end


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

AddTask("Deathmatch_WorldTask", {
    locks = {},
    keys_given = {},
    room_choices = {
        ["Blank"] = 1,
    },
    background_room = "Blank",
    room_bg = G.GROUND.IMPASSABLE,
    colour = {r=1,g=0,b=1,a=1},
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

G.LEVELTYPE.DEATHMATCH = "DEATHMATCH"
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
--you've forced my hand, klei.
local levels = require("map/levels")
local GetDefaultLevelData_old = levels.GetDefaultLevelData
function levels.GetDefaultLevelData(leveltype, location, ...)
	if leveltype == "DEATHMATCH" then
		location = "deathmatch"
	end
	return GetDefaultLevelData_old(leveltype, location, ...)
end
	
--atrium bacons get removed because they're too close to the ocean, this should fix that
G.require("map/graphnode")
local Node_AddEntity_old = G.Node.AddEntity
function G.Node:AddEntity(prefab, points_x, points_y, current_pos_idx, entitiesOut, width, height, prefab_list, prefab_data, rand_offset)
	local tile = G.WorldSim:GetTile(points_x[current_pos_idx], points_y[current_pos_idx]) 
	G.PopulateWorld_AddEntity(prefab, points_x[current_pos_idx], points_y[current_pos_idx], tile, entitiesOut, width, height, prefab_list, prefab_data, rand_offset)
end