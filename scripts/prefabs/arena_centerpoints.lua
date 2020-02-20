local prefabs = {}

local assets = {}

local function onnear(inst, player)
	if player and player.player_classified then
		player.player_classified._arenaeffects:set(inst.presetname)
	end
end
local function onfar(inst, player)
	if player and player.player_classified then
		player.player_classified._arenaeffects:set("lobby")
	end
end

local function onsandstormchange(inst, player) -- ill rely on non-dirty variables not getting resent
	if player and player.player_classified then
		if inst.players_storm[player] then
			player.player_classified.sandstormlevel:set(7)
			player.components.locomotor:SetExternalSpeedMultiplier(inst, "fortnite", 0.2)
		else
			player.player_classified.sandstormlevel:set(0)
			player.components.locomotor:SetExternalSpeedMultiplier(inst, "fortnite", 1)
		end
	end
end

local common_fn = function()

	local inst = CreateEntity()

	inst.entity:AddTransform()
	--inst.entity:AddNetwork()
	
	inst:AddTag("CLASSIFIED")
	inst.setting = nil
	
	
	if not TheWorld.ismastersim then
		return inst
	end
	--[[ playerprox is unreliable, onfar fn doesn't include player that went far which is a bit bs
	inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(4, 5)
    inst.components.playerprox.onnear = onnear
    inst.components.playerprox.onfar = onfar
	]]
	inst.range = inst.range or 52
	inst.players_inside = {}
	inst.players_storm = {}
	inst.storm_range = inst.storm_range or 52
	inst.min_storm_range = inst.min_storm_range or 16
	inst.storm_shrinking = false
	inst.onnear = onnear
	inst.onfar = onfar
	
	inst.storm_circle = SpawnPrefab("reticuleaoehostiletarget")
	inst.storm_circle.scale = function(inst, scale)
		local s = math.sqrt(scale/4)
		inst.Transform:SetScale(s,s,s)
	end
	inst.storm_circle:scale(inst.storm_range)
	inst:DoTaskInTime(0, function(inst) inst.storm_circle.Transform:SetPosition(inst.Transform:GetWorldPosition()) end)
	inst.storm_circle:Hide()
	
	local dt = 0
	local lasttime = GetTime()
	--[[this unused code is just gunna be a huge performance hit
	inst._detecttask = inst:DoPeriodicTask(2/10, function(inst)
		local x, y, z = inst:GetPosition():Get()
		local ents = TheSim:FindEntities(x, y, z, inst.range, {"player"})
		local players_found = {}
		for k, v in pairs(ents) do
			if not inst.players_inside[v] then
				if inst.onnear then inst.onnear(inst, v) end
				inst.players_inside[v] = true
			end
			players_found[v] = true
		end
		
		local currenttime = GetTime()
		dt = currenttime - lasttime
		lasttime = currenttime
		if inst.storm_shrinking and inst.storm_range > inst.min_storm_range then
		-- shrink at 0.5 unit/sec
			inst.storm_range = inst.storm_range - 0.5*dt
			inst.storm_circle:scale(inst.storm_range)
		end
		
		
		for k, v in pairs(inst.players_inside) do
			if v and not players_found[k] then
				if inst.onfar then inst.onfar(inst, k) end
				inst.players_inside[k] = nil
				break
			end
			inst.players_storm[k] = not k:IsNear(inst, inst.storm_range)
			onsandstormchange(inst, k)
		end
	end)]]
	
	return inst
end

local function lobby_postinit(inst)
	inst.onfar = nil
	if TheWorld.ismastersim then
		TheWorld.lobbypoint = inst
	end
end

local function pigvillage_postinit(inst)
	TheWorld:ListenForEvent("fakefullmoon", function(wrld, shouldpush)
		if shouldpush then
			inst.presetname = "pigvillage_fm"
		else
			inst.presetname = "pigvillage"
		end
		for k, v in pairs(inst.players_inside) do
			inst:onnear(k)
		end
	end)
end

local function MakeArenaCenterpoint(name, custom_postinit)
	local function fn()
		local inst = common_fn()
		inst.presetname = name
		if custom_postinit ~= nil then
			custom_postinit(inst)
		end
		return inst
	end
	
	return Prefab("arena_centerpoint_"..name, fn, assets, prefabs)
end

return MakeArenaCenterpoint("atrium"), 
	MakeArenaCenterpoint("lobby", lobby_postinit),
	MakeArenaCenterpoint("desert"),
	MakeArenaCenterpoint("spring"),
	MakeArenaCenterpoint("pigvillage", pigvillage_postinit),
	MakeArenaCenterpoint("cave")
	
	--[[when adding new arenas, make sure to update:
	this file
	dm world
	dm manager
	dm status
	vote options
	
	TODO: just make a fucking global table elec please
	]]
