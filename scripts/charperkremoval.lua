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
	if modulename == "prefabs/player_common" then
		local val_old = val
		function val(name, customprefabs, customassets, common_postinit, master_postinit, ...)
			if name == "wormwood" and master_postinit ~= nil then
				--i hate this. i'm gunna need to do a chain of upvalues
				local OnRespawnedFromGhost = GetUpValue(master_postinit, "OnRespawnedFromGhost")
				local OnSeasonProgress = GetUpValue(OnRespawnedFromGhost, "OnSeasonProgress")
				SetBloomStage = GetUpValue(OnSeasonProgress, "SetBloomStage")
				local EnableFullBloom = GetUpValue(SetBloomStage, "EnableFullBloom") --i think i can just override this with an empty fn but i want pollen
				
				
				--no more ground plants (they annoying) and no speed boost (keeping pollen for now)
				ReplaceUpValue(EnableFullBloom, "PlantTick", function() end)
				ReplaceUpValue(SetBloomStage, "SetStatsLevel", function() end)
				ReplaceUpValue(OnRespawnedFromGhost, "OnSeasonProgress", function() end)
				
			end
			return val_old(name, customprefabs, customassets, common_postinit, master_postinit, ...)
		end
	end
	return val
end
require("prefabs/wormwood")
G.require = require --putting in back the original because i dont want to perma replace

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
	
	--new function for /setstate
	inst.cosmeticstate = 1
	function inst:ChangeCosmeticState(num) --input: number 1-4
		num = num -1
		if num >= 0 and num <= 3 and self.SetBloomStage then
			self:SetBloomStage(num)
			self.cosmeticstate = num
		end
	end
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
	
	inst.cosmeticstate = 2
	function inst:ChangeCosmeticState(num)--1-3: wimpy, normal, mighty
		if num ~= self.cosmeticstate and num >= 1 and num <= 3 then
			if num == 1 then
				self.components.skinner:SetSkinMode("wimpy_skin", "wolfgang_skinny")
			elseif num == 2 then
				self.components.skinner:SetSkinMode("normal_skin", "wolfgang")
			else
				self.components.skinner:SetSkinMode("mighty_skin", "wolfgang_mighty")
			end
			self.cosmeticstate = num
		end
	end
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
	
	inst.cosmeticstate = 1
	function inst:ChangeCosmeticState(num)
		if num ~= self.cosmeticstate and num >= 1 and num <= 2 then
			local fx = G.SpawnPrefab("small_puff") --fx because it looks awkward
			fx.Transform:SetScale(1.5, 1.5, 1.5)
			fx.Transform:SetPosition(self.Transform:GetWorldPosition())
			if num == 1 then
				self.components.skinner:SetSkinMode("normal_skin", "wurt")
			else
				self.components.skinner:SetSkinMode("powerup", "wurt_stage2")
			end
			self.cosmeticstate = num
		end
	end
end)

AddPrefabPostInit("woodie", function(inst)
	--this does nothing now
	--if inst.components.beaverness then inst.components.beaverness:StopTimeEffect() end
	
	--i'll need to fix the weremeter showing up eventually so here's this
end)
