local G = GLOBAL
local require = G.require
-- i wrote these 2 functions real quick cause i'll need em later
--[[
local function GetUpValue(func, varname)
	local i = 1
	local n, v = debug.getupvalue(func, 1)
	while v ~= nil do
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
		if n == varname then
			debug.setupvalue(func, i, newvalue)
			return
		end
		i = i + 1
		n, v = debug.getupvalue(func, i)
	end
end]]

-- wormwood
AddPrefabPostInit("wormwood", function(inst)
	if not TheWorld.ismastersim then return end
	--quick fix to bloom speed: apply speed debuff to negate the buff
	--i'll sort this out later... i promise...
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "deathmatchwormwood", 10/12)
	inst:DoTaskInTime(1, inst.OnLoad)
end)

--wigfrid
AddPrefabPostInit("wathgrithr", function(inst)
	if not TheWorld.ismastersim then return end
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
