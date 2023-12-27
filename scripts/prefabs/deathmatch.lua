local ARENA_DEFS = require("prefabs/arena_defs").CONFIGS
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

local EXTRA_CONFIGS = { --hornet: improve this plz
	pigvillage_fm = {
		colourcube = "purple_moon_cc",
		lighting = {84 / 255, 122 / 255, 156 / 255},
	}
}

local function PushConfig(name)
	--rewrote this function to be significantly less painful to look at
	if TheNet:IsDedicated() or ThePlayer == nil then return end
	local data = EXTRA_CONFIGS[name] or ARENA_DEFS[name].CONFIGS
	
	--apply lighting
	TheSim:SetVisualAmbientColour(unpack(data.lighting))
	
	--apply colorcube
	if data.colourcube ~= nil then
		local path = softresolvefilepath("images/colour_cubes/"..data.colourcube..".tex")
		if path ~= nil then
			ThePlayer.components.playervision:SetCustomCCTable({ day=path, dusk=path, night=path, full_moon=path })
		end
	elseif data.cctable ~= nil then
		ThePlayer.components.playervision:SetCustomCCTable(data.cctable)
		if data.ccphasefn ~= nil then
			ThePlayer.components.playervision.currentccphasefn = data.ccphasefn
			ThePlayer:PushEvent("ccphasefn", data.ccphasefn)
		end
	end
	
	--apply music
	local music = data.music
	if music ~= nil then --maps without music will have to input an empty string
		local old_music = ThePlayer._currentarenamusic
		if music ~= old_music then
			ThePlayer.SoundEmitter:KillSound("bgm")
			ThePlayer.SoundEmitter:PlaySound(music, "bgm")
			ThePlayer._currentarenamusic = music
		end
	end
	
	--apply oceancolor
	-- if data.oceancolor then
		-- TheWorld.Map:SetClearColor(data.oceancolor[1], data.oceancolor[2], data.oceancolor[3], data.oceancolor[4])    
	-- else
		-- TheWorld.Map:SetClearColor(0,0,0,1)
	-- end
	
	--apply waves
	if data.waves then
		TheWorld:DoTaskInTime(0, function(wrld)
			wrld.WaveComponent:SetWaveSize(80, 3.5)
			wrld.WaveComponent:Init(0,0)
		end)
	elseif data.waves == false then --waves = nil means don't change current
		TheWorld:DoTaskInTime(0, function(wrld)
			wrld.WaveComponent:SetWaveSize(0, 0)
			wrld.WaveComponent:Init(0,0)
		end)
	end
	
	-- if data.has_ocean then
		-- TheWorld.Map:SetTransparentOcean(true)
		-- TheWorld.Map:SetUndergroundFadeHeight(5)
	-- else
		-- TheWorld.Map:SetTransparentOcean(false)
		-- TheWorld.Map:SetUndergroundFadeHeight(0)
	-- end
	
	-- if data.fadeheight ~= nil then
		-- TheWorld.Map:SetUndergroundFadeHeight(data.fadeheight)
	-- end
end
-----------------------------------------
local function GetWaveBearing(ex, ey, ez, lines)
	local offs =
	{
		{-2,-2}, {-1,-2}, {0,-2}, {1,-2}, {2,-2},
		{-2,-1}, {-1,-1}, {0,-1}, {1,-1}, {2,-1},
		{-2, 0}, {-1, 0},		  {1, 0}, {2, 0},
		{-2, 1}, {-1, 1}, {0, 1}, {1, 1}, {2, 1},
		{-2, 2}, {-1, 2}, {0, 2}, {1, 2}, {2, 2}
	}

	local map = TheWorld.Map
	local width, height = map:GetSize()
	local halfw, halfh = 0.5 * width, 0.5 * height
	local x, y = map:GetTileXYAtPoint(ex, ey, ez)
	local xtotal, ztotal, n = 0, 0, 0
	for i = 1, #offs, 1 do
		local ground = map:GetTile( x + offs[i][1], y + offs[i][2] )
		if IsLandTile(ground) then
			xtotal = xtotal + ((x + offs[i][1] - halfw) * TILE_SCALE)
			ztotal = ztotal + ((y + offs[i][2] - halfh) * TILE_SCALE)
			n = n + 1
		end
	end

	local bearing = nil
	if n > 0 then
		local a = math.atan2(ztotal/n - ez, xtotal/n - ex)
		bearing = -a/DEGREES - 90
	end

	return bearing
end

local function SpawnWaveShore(inst, x, y, z)
	local bearing = GetWaveBearing(x, y, z)
	if bearing then
		local wave = SpawnPrefab("wave_shore")
		wave.Transform:SetPosition( x, y, z )
		wave.Transform:SetRotation(bearing)
		wave:SetAnim()
	end
end

local function SpawnWaveShimmerMedium(inst, x, y, z)
	local is_surrounded_by_water = TheWorld.Map:IsSurroundedByWater(x, y, z, 4.5)

	if is_surrounded_by_water then
		local wave = SpawnPrefab( "wave_shimmer_med" )
		wave.Transform:SetPosition( x, y, z )
	else
		local is_nearby_ground = not TheWorld.Map:IsSurroundedByWater(x, y, z, 3.5)
		if is_nearby_ground then
			local is_nearby_surrounded_by_water = TheWorld.Map:IsSurroundedByWater(x, y, z, 2.5)
			if is_nearby_surrounded_by_water then
				SpawnWaveShore(inst, x,y,z)
			end
		end
	end
end

local function SpawnWaveShimmerDeep(inst, x, y, z)
	local is_surrounded_by_water = TheWorld.Map:IsSurroundedByWater(x, y, z, 4.5)

	if is_surrounded_by_water then
		local wave = SpawnPrefab( "wave_shimmer_deep" )
		wave.Transform:SetPosition( x, y, z )
	else
		local is_nearby_ground = not TheWorld.Map:IsSurroundedByWater(x, y, z, 3.5)
		if is_nearby_ground then
			local is_nearby_surrounded_by_water = TheWorld.Map:IsSurroundedByWater(x, y, z, 2.5)
			if is_nearby_surrounded_by_water then
				SpawnWaveShore(inst, x,y,z)
			end
		end
	end
end

local function checkground(inst, map, x, y, z, ground)
	local is_ground = map:GetTileAtPoint( x, y, z ) == ground
	if not is_ground then return false end

	local radius = 2
	return map:IsValidTileAtPoint( x - radius, y, z ) 
			and map:IsValidTileAtPoint( x + radius, y, z )
			and map:IsValidTileAtPoint( x, y, z - radius )
			and map:IsValidTileAtPoint( x, y, z + radius )
end
------------------------------------------------------
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
		
		-- inst:AddComponent("wavemanager")
		-- inst.components.wavemanager.shimmer[GROUND.OCEAN_SWELL] = {per_sec = 80, spawn_rate = 0, checkfn = checkground, spawnfn = SpawnWaveShimmerMedium}
		-- inst.components.wavemanager.shimmer[GROUND.OCEAN_ROUGH] = {per_sec = 80, spawn_rate = 0, checkfn = checkground, spawnfn = SpawnWaveShimmerDeep}
		-- inst.components.wavemanager.shimmer[GROUND.OCEAN_HAZARDOUS] = {per_sec = 80, spawn_rate = 0, checkfn = checkground, spawnfn = SpawnWaveShimmerDeep}
		
		--inst.Map:SetTransparentOcean(true)

		--[[inst:ListenForEvent("registerlobbypoint", function(world, point)
			world.lobbypoint = point
		end)]]
    end
	
	inst:DoTaskInTime(0, function(inst)
		--no more of that wormwood bloom (also spring map is dead now)
		--inst.state.isspring = true 
		inst.state.isautumn = true
	end)
	
	inst.Map:SetUndergroundFadeHeight(5)
	
	-- local _Finalize = getmetatable(inst.Map).__index["Finalize"]
	-- getmetatable(inst.Map).__index["Finalize"] = function(self, number)
		-- if self == inst.Map then
			-- --inst.has_ocean = true
			
			-- local tuning = TUNING.OCEAN_SHADER
            -- self:SetOceanEnabled(inst.has_ocean or false)
			-- self:SetOceanTextureBlurParameters(tuning.TEXTURE_BLUR_PASS_SIZE, tuning.TEXTURE_BLUR_PASS_COUNT)
            -- self:SetOceanNoiseParameters0(tuning.NOISE[1].ANGLE, tuning.NOISE[1].SPEED, tuning.NOISE[1].SCALE, tuning.NOISE[1].FREQUENCY)
            -- self:SetOceanNoiseParameters1(tuning.NOISE[2].ANGLE, tuning.NOISE[2].SPEED, tuning.NOISE[2].SCALE, tuning.NOISE[2].FREQUENCY)
            -- self:SetOceanNoiseParameters2(tuning.NOISE[3].ANGLE, tuning.NOISE[3].SPEED, tuning.NOISE[3].SCALE, tuning.NOISE[3].FREQUENCY)

			-- local waterfall_tuning = TUNING.WATERFALL_SHADER.NOISE

			-- self:SetWaterfallFadeParameters(TUNING.WATERFALL_SHADER.FADE_COLOR[1] / 255, TUNING.WATERFALL_SHADER.FADE_COLOR[2] / 255, TUNING.WATERFALL_SHADER.FADE_COLOR[3] / 255, TUNING.WATERFALL_SHADER.FADE_START)
			-- self:SetWaterfallNoiseParameters0(waterfall_tuning[1].SCALE, waterfall_tuning[1].SPEED, waterfall_tuning[1].OPACITY, waterfall_tuning[1].FADE_START)
			-- self:SetWaterfallNoiseParameters1(waterfall_tuning[2].SCALE, waterfall_tuning[2].SPEED, waterfall_tuning[2].OPACITY, waterfall_tuning[2].FADE_START)

			-- local minimap_ocean_tuning = TUNING.OCEAN_MINIMAP_SHADER

			-- self:SetMinimapOceanEdgeColor0(minimap_ocean_tuning.EDGE_COLOR0[1] / 255, minimap_ocean_tuning.EDGE_COLOR0[2] / 255, minimap_ocean_tuning.EDGE_COLOR0[3] / 255)
			-- self:SetMinimapOceanEdgeParams0(minimap_ocean_tuning.EDGE_PARAMS0.THRESHOLD, minimap_ocean_tuning.EDGE_PARAMS0.HALF_THRESHOLD_RANGE)

			-- self:SetMinimapOceanEdgeColor1(minimap_ocean_tuning.EDGE_COLOR1[1] / 255, minimap_ocean_tuning.EDGE_COLOR1[2] / 255, minimap_ocean_tuning.EDGE_COLOR1[3] / 255)
			-- self:SetMinimapOceanEdgeParams1(minimap_ocean_tuning.EDGE_PARAMS1.THRESHOLD, minimap_ocean_tuning.EDGE_PARAMS1.HALF_THRESHOLD_RANGE)

			-- self:SetMinimapOceanEdgeShadowColor(minimap_ocean_tuning.EDGE_SHADOW_COLOR[1] / 255, minimap_ocean_tuning.EDGE_SHADOW_COLOR[2] / 255, minimap_ocean_tuning.EDGE_SHADOW_COLOR[3] / 255)
			-- self:SetMinimapOceanEdgeShadowParams(minimap_ocean_tuning.EDGE_SHADOW_PARAMS.THRESHOLD, minimap_ocean_tuning.EDGE_SHADOW_PARAMS.HALF_THRESHOLD_RANGE, minimap_ocean_tuning.EDGE_SHADOW_PARAMS.UV_OFFSET_X, minimap_ocean_tuning.EDGE_SHADOW_PARAMS.UV_OFFSET_Y)

			-- self:SetMinimapOceanEdgeFadeParams(minimap_ocean_tuning.EDGE_FADE_PARAMS.THRESHOLD, minimap_ocean_tuning.EDGE_FADE_PARAMS.HALF_THRESHOLD_RANGE, minimap_ocean_tuning.EDGE_FADE_PARAMS.MASK_INSET)

			-- self:SetMinimapOceanEdgeNoiseParams(minimap_ocean_tuning.EDGE_NOISE_PARAMS.UV_SCALE)
		
			-- self:SetMinimapOceanTextureBlurParameters(minimap_ocean_tuning.TEXTURE_BLUR_SIZE, minimap_ocean_tuning.TEXTURE_BLUR_PASS_COUNT, minimap_ocean_tuning.TEXTURE_ALPHA_BLUR_SIZE, minimap_ocean_tuning.TEXTURE_ALPHA_BLUR_PASS_COUNT)
			-- self:SetMinimapOceanMaskBlurParameters(minimap_ocean_tuning.MASK_BLUR_SIZE, minimap_ocean_tuning.MASK_BLUR_PASS_COUNT)
		-- end
		
		-- _Finalize(self, number)
	-- end
end

local function OnSave(inst, data)
	data.despawnplayerdata = inst.despawnplayerdata
end
local function OnLoad(inst, data)
	if data.despawnplayerdata ~= nil then
		inst.despawnplayerdata = data.despawnplayerdata
	end
end
local function master_postinit(inst)
	inst.despawnplayerdata = {} --for saving day count in /despawn
	inst:ListenForEvent("ms_newplayercharacterspawned", function(inst, data)
		local player = data.player
		inst:DoTaskInTime(0, function(inst)
			if inst.despawnplayerdata[player.userid] ~= nil then
				if player.LoadForReroll ~= nil then
					player:LoadForReroll(inst.despawnplayerdata[player.userid])
				end
				inst.despawnplayerdata[player.userid] = nil
			end
		end)
	end)
	
	inst.OnSave = OnSave --does this even work with worlds? Hornet: Yes, it does. I believe OnSave and OnLoad works for entities with the Transform functions
	inst.OnLoad = OnLoad
end

return MakeWorld("deathmatch", prefabs, assets, common_postinit, master_postinit, {"deathmatch"})
