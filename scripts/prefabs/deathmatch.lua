require("prefabs/world")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/world.lua"),

    Asset("IMAGE", "images/colour_cubes/day05_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/dusk03_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/night03_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/snow_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/snowdusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/night04_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/summer_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/summer_dusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/summer_night_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/spring_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/spring_dusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/spring_night_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/insane_day_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/insane_dusk_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/insane_night_cc.tex"),
    Asset("IMAGE", "images/colour_cubes/purple_moon_cc.tex"),

    Asset("ANIM", "anim/snow.zip"),
    Asset("ANIM", "anim/lightning.zip"),

    Asset("SOUND", "sound/forest_stream.fsb"),
    Asset("SOUND", "sound/amb_stream.fsb"),

    Asset("IMAGE", "levels/textures/snow.tex"),
    Asset("IMAGE", "levels/textures/mud.tex"),
    Asset("IMAGE", "images/wave.tex"),
}

local prefabs =
{
    "cave",
    "forest_network",
    "adventure_portal",
    "resurrectionstone",
    "deer",
    "deerspawningground",
    "deerclops",
    "gravestone",
    "flower",
    "animal_track",
    "dirtpile",
    "beefaloherd",
    "beefalo",
    "penguinherd",
    "penguin_ice",
    "penguin",
    "koalefant_summer",
    "koalefant_winter",
    "beehive",
    "wasphive",
    "walrus_camp",
    "pighead",
    "mermhead",
    "rabbithole",
    "molehill",
    "carrot_planted",
    "tentacle",
    "wormhole",
    "cave_entrance",
    "teleportato_base",
    "teleportato_ring",
    "teleportato_box",
    "teleportato_crank",
    "teleportato_potato",
    "pond", 
    "marsh_tree", 
    "marsh_bush", 
    "burnt_marsh_bush",
    "reeds", 
    "mist",
    "snow",
    "rain",
    "pollen",
    "marblepillar",
    "marbletree",
    "statueharp",
    "statuemaxwell",
    "beemine_maxwell",
    "trap_teeth_maxwell",
    "sculpture_knight",
    "sculpture_bishop",
    "sculpture_rook",
    "statue_marble",
    "eyeplant",
    "lureplant",
    "purpleamulet",
    "monkey",
    "livingtree",
    "tumbleweed",
    "rock_ice",
    "catcoonden",
    "shadowmeteor",
    "meteorwarning",
    "warg",
    "claywarg",
    "spat",
    "multiplayer_portal",
    "lavae",
    "lava_pond",
    "scorchedground",
    "scorched_skeleton",
    "lavae_egg",
    "terrorbeak",
    "crawlinghorror",
    "creepyeyes",
    "shadowskittish",
    "shadowwatcher",
    "shadowhand",
    "stagehand",
    "tumbleweedspawner",
    "meteorspawner",
    "dragonfly_spawner",
    "moose",
    "mossling",
    "bearger",
    "dragonfly",
    "chester",
    "grassgekko",
    "petrify_announce",
    "moonbase",
    "moonrock_pieces",
    "shadow_rook",
    "shadow_knight",
    "shadow_bishop",
    "beequeenhive",
    "klaus_sack",
    "antlion_spawner",
    "oasislake",
    "succulent_plant",
}

local configs = {
	lobby = {
		lighting = {200 / 255, 200 / 255, 200 / 255},
		colourcube = "day05_cc",
		waves = true,
		music = "dontstarve/music/gramaphone_ragtime",
	},
	atrium = {
		lighting = {0.1,0.1,0.1},
		--colourcube = "ruins_dark_cc",
		cctable = { ["true"]=resolvefilepath("images/colour_cubes/ruins_light_cc.tex"), ["false"]=resolvefilepath("images/colour_cubes/ruins_dark_cc.tex") },
		ccphasefn = { blendtime = 2, events = { "atriumactivechanged" },fn = function() return tostring(TheWorld.state.atrium_active) end},
		music = "dontstarve/music/music_epicfight_stalker", 
		waves = false,
	},
	desert = {
		lighting = {200 / 255, 200 / 255, 200 / 255},
		colourcube = "summer_day_cc",
		music = "dontstarve_DLC001/music/music_epicfight_summer",
		waves = true,
	},
	spring = {
		lighting = {200 / 255, 200 / 255, 200 / 255},
		colourcube = "spring_day_cc",
		music = "dontstarve_DLC001/music/music_epicfight_spring",
		waves = true,
	},
	pigvillage = {
		lighting = {200 / 255, 200 / 255, 200 / 255},
		colourcube = "day05_cc",
		music = "dontstarve/music/music_pigking_minigame",
		waves = true,
	},
	pigvillage_fm = {
		--music = "dontstarve/music/gramaphone_efs",
		--waves = true,
		specific = true,
		colourcube = "purple_moon_cc",
		lighting = {84 / 255, 122 / 255, 156 / 255},
	},
	cave = {
		colourcube = "sinkhole_cc",
		lighting = {0.1,0.1,0.1},
		music = "",
		waves = false,
	},
}
local function PushConfig(config)
	--TODO: am i not storing the previous config in any way?!
	--i could make it so that music doesn't restart if switching
	--from non-specific to specific
	--though i may have to set up some "relationships" code so that
	--it doesn't play hog music in lobby
	if not TheNet:IsDedicated() and ThePlayer ~= nil then
		if not configs[config].specific then
			ThePlayer.SoundEmitter:KillSound("bgm")
		end
		TheSim:SetVisualAmbientColour(unpack(configs[config].lighting))
		if configs[config].colourcube ~= nil then
			print("changing colorcube...")
			local path = softresolvefilepath("images/colour_cubes/"..configs[config].colourcube..".tex")
			if path ~= nil then
				ThePlayer.components.playervision:SetCustomCCTable({ day=path, dusk=path, night=path, full_moon=path })
			end
		elseif configs[config].cctable ~= nil then
			print("changing colorcube table...")
			ThePlayer.components.playervision:SetCustomCCTable(configs[config].cctable)
			if configs[config].ccphasefn ~= nil then
				ThePlayer.components.playervision.currentccphasefn = configs[config].ccphasefn
				ThePlayer:PushEvent("ccphasefn", configs[config].ccphasefn)
			end
		elseif not configs[config].specific then
			ThePlayer.components.playervision:SetCustomCCTable(nil)
		end
		if configs[config].music ~= nil then
			if configs[config].specific then
				ThePlayer.SoundEmitter:KillSound("bgm")
			end
			ThePlayer.SoundEmitter:PlaySound(configs[config].music, "bgm")
		end
		if TheWorld.WaveComponent ~= nil then
			if configs[config].waves then
				TheWorld.WaveComponent:SetWaveSize(80, 3.5)
			elseif (configs[config].specific and configs[config].waves == false) or (not configs[config].specific and not configs[config].waves) then
				TheWorld.WaveComponent:SetWaveSize(0,0)
			end
			TheWorld.WaveComponent:Init(0,0)
		end
	end
end


local function common_postinit(inst)
    --Add waves
    inst.entity:AddWaveComponent() --klei hasn't removed this...? --Hornet: Their is still waves in the world, the dark ones the waterfalls go into in RoT
    inst.WaveComponent:SetWaveParams(13.5, 2.5)						-- wave texture u repeat, forward distance between waves
    inst.WaveComponent:SetWaveSize(80, 3.5)							-- wave mesh width and height
    inst.WaveComponent:SetWaveTexture("images/wave.tex")
    --See source\game\components\WaveRegion.h
    inst.WaveComponent:SetWaveEffect("shaders/waves.ksh")
    --inst.WaveComponent:SetWaveEffect("shaders/texture.ksh")

    --Initialize lua components
    inst:AddComponent("ambientlighting")
	inst.state.atrium_active = false


    --Dedicated server does not require these components
    --NOTE: ambient lighting is required by light watchers
    if not TheNet:IsDedicated() then
        inst:AddComponent("colourcube")
		inst:ListenForEvent("applyarenaeffects", function(inst, fxname)
			PushConfig(fxname)
		end)
		
		--[[inst:ListenForEvent("registerlobbypoint", function(world, point)
			world.lobbypoint = point
		end)]]
    end
	
	inst:DoTaskInTime(0, function(inst)
		--no more of that wormwood bloom (also spring map is dead now)
		--inst.state.isspring = true 
		inst.state.isautumn = true
	end)
end

local function OnSave(inst, data)
	data.despawnplayerdata = despawnplayerdata
end
local function OnLoad(inst, data)
	if data.despawnplayerdata ~= nil then
		inst.despawnplayerdata = data.despawnplayerdata
	end
end
local function master_postinit(inst)
	inst.despawnplayerdata = {} --for saving day count in /despawn
	inst:ListenForEvent("ms_newplayerspawned", function(world, player)
		if inst.despawnplayerdata[player.userid] ~= nil then
			if player.LoadForReroll ~= nil then
				player:LoadForReroll(inst.despawnplayerdata[player.userid])
			end
			inst.despawnplayerdata[player.userid] = nil
		end
	end)
	
	inst.OnSave = OnSave --does this even work with worlds?
	inst.OnLoad = OnLoad
end

return MakeWorld("deathmatch", prefabs, assets, common_postinit, master_postinit, {"deathmatch"})
