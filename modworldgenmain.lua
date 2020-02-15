local G = GLOBAL
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
AddClassPostConstruct("widgets/redux/worldcustomizationtab", function(self)
	G.EVENTSERVER_LEVEL_LOCATIONS["DEATHMATCH"] = {"deathmatch"}
end)

--[[ disabling mod whitelist for now because it's buggy and i don't like it
main reason i made this in the first place is because the darkness gimmick of atrium
is ruined by the nicknames mod, which a lot of people regularly use
i might just make the mod disable that mod (and a few others if necessary) and show an
ingame popup when that happens
local mods_whitelist = {
	["workshop-352373173"]=true, 
	["workshop-343753877"]=true 
}
local modidx_cptbasjdn = G.KnownModIndex.IsModCompatibleWithMode --mashed keyboard on that last part
G.KnownModIndex.IsModCompatibleWithMode = function(self, modname, dlc)
	if (not mods_whitelist[modname]) and self.savedata.known_mods[modname] and self.savedata.known_mods[modname].disabled_incompatible_with_mode then
		return false
	end
	return modidx_cptbasjdn(self, modname, dlc)
end
for k, v in pairs(G.KnownModIndex:GetClientModNames()) do
	--G.KnownModIndex:DisableBecauseIncompatibleWithMode(v)
	G.KnownModIndex.savedata.known_mods[v].disabled_incompatible_with_mode = true
end
]]

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

AddLevel("DEATHMATCH", {
        id = "DEATHMATCH",
        name = "Deathmatch Arena Set",
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
        },
        background_node_range = {0,1},
    })
	
