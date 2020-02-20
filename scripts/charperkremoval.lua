local G = GLOBAL
local require = G.require
local debug = G.debug

local function GetUpValue(func, varname)
	local i = 1
	local n, v = debug.getupvalue(func, 1)
	while v ~= nil do
		print("checking",n, v, "to fetch")
		if n == varname then
			return v
		end
		i = i + 1
		n, v = debug.getupvalue(func, i)
	end
end
local function ReplaceUpValue(func, varname, newvalue)
	local i = 1
	local n, v = debug.getupvalue(func, 1)
	while v ~= nil do
		print("checking",n, v, "to replace")
		if n == varname then
			debug.setupvalue(func, i, newvalue)
			return
		end
		i = i + 1
		n, v = debug.getupvalue(func, i)
	end
end

--here comes the worst hack i've ever had to do ever
local SetBloomStage = nil
function G.require(modulename, ...)
	--using the local version of require since it isn't replaced
	local val = require(modulename, ...) 
	--there's a probably a better way to do this so TODO
	if val == require("prefabs/player_common") then
		local val_old = val
		function val(name, customprefabs, customassets, common_postinit, ...)
			if name == "wormwood" then
				--no more ground plants (they annoying) and no speed boost
				ReplaceUpValue(common_postinit, "PlantTick", function() end)
				ReplaceUpValue(common_postinit, "SetStatsLevel", function() end)
				SetBloomStage = GetUpValue(common_postinit, "SetBloomStage")
			end
		end
	end
end

-- wormwood
AddPrefabPostInit("wormwood", function(inst)
	if not G.TheWorld.ismastersim then return end
	inst.SetBloomStage = SetBloomStage
	--old wormwood speed removal code
	--i will now just make world not perma spring (TODO) and let /setstate control bloom
	--TODO: make /setstate save
	--inst.components.locomotor:SetExternalSpeedMultiplier(inst, "deathmatchwormwood", 10/12)
	--inst:DoTaskInTime(1, inst.OnLoad)
	inst.OnLoad = nil
	inst.OnNewSpawn = nil
	inst.OnPreLoad = nil
end)

--wigfrid
AddPrefabPostInit("wathgrithr", function(inst)
	if not G.TheWorld.ismastersim then return end
	inst.event_listeners.onattackother[inst][2] = nil
end)

--wolfgang
AddPrefabPostInit("wolfgang", function(inst)
	inst.OnLoad = nil
	inst.OnNewSpawn = nil
	inst.OnPreLoad = nil
end)

--webber
AddPrefabPostInit("webber", function(inst)
	inst:RemoveTag("monster")
end)

--wortox
AddPrefabPostInit("wortox", function(inst)
	inst:RemoveTag("monster")
	--souls should probably be removed here
end)

--wurt
AddPrefabPostInit("wurt", function(inst)
	inst:RemoveTag("merm")
end)

AddPrefabPostInit("woodie", function(inst)
	--this does nothing now
	--if inst.components.beaverness then inst.components.beaverness:StopTimeEffect() end
	
	--i'll need to fix the weremeter showing up eventually so here's this
end)
