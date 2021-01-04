local G = GLOBAL
local require = G.require
local debug = G.debug


local function GetUpValue(func, varname)
	local i = 1
	local n, v = debug.getupvalue(func, 1)
	while v ~= nil do
		--print("UPVAL GET", varname ,n, v)
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
		--print("UPVAL REPLACE",varname,n, v)
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
local beardfns = {}
function G.require(modulename, ...)
	--using the local version of require since it isn't replaced
	local val = require(modulename, ...) 
	if modulename == "prefabs/player_common" then
		local val_old = val
		function val(name, customprefabs, customassets, common_postinit, master_postinit, ...)
			if name == "wormwood" and master_postinit ~= nil then
				--i hate this. i'm gunna need to do a chain of upvalues
				--local OnRespawnedFromGhost = GetUpValue(master_postinit, "OnRespawnedFromGhost")
				--local OnSeasonProgress = GetUpValue(OnRespawnedFromGhost, "OnSeasonProgress")
				--SetBloomStage = GetUpValue(OnSeasonProgress, "SetBloomStage")
				--local EnableFullBloom = GetUpValue(SetBloomStage, "EnableFullBloom") --i think i can just override this with an empty fn but i want pollen
				local UpdateBloomStage = GetUpValue(master_postinit, "UpdateBloomStage")
				
				--no more ground plants (they annoying) and no speed boost (keeping pollen for now)
				--ReplaceUpValue(master_postinit, "OnNewSpawn", function() end)
				--ReplaceUpValue(master_postinit, "OnRespawnedFromGhost", function() end)
				-- temp comment: ReplaceUpValue(EnableFullBloom, "PlantTick", function() end)
				ReplaceUpValue(UpdateBloomStage, "SetStatsLevel", function() end)
				-- outdated: ReplaceUpValue(OnRespawnedFromGhost, "OnSeasonProgress", function() end)
				
			elseif (name == "wilson" or name == "webber") and master_postinit ~= nil then
				beardfns[name] = {
					GetUpValue(master_postinit, "OnResetBeard"),
					GetUpValue(master_postinit, "OnGrowShortBeard"),
					GetUpValue(master_postinit, "OnGrowMediumBeard"),
					GetUpValue(master_postinit, "OnGrowLongBeard"),
				}
			end
			return val_old(name, customprefabs, customassets, common_postinit, master_postinit, ...)
		end
	end
	return val
end
require("prefabs/wormwood")
require("prefabs/wilson")
require("prefabs/webber")
G.require = require --putting in back the original because i dont want to perma replace

local function CosmeticSaveData(inst)
	if not G.TheWorld.ismastersim then return end
	local OnSave_old = inst.OnSave
	function inst:OnSave(data, ...)
		if OnSave_old then OnSave_old(self, data, ...) end
		data.cosmeticstate = self.cosmeticstate
	end
	local OnLoad_old = inst.OnLoad
	function inst:OnLoad(data, ...)
		if data and data.cosmeticstate ~= nil then
			self.cosmeticstate = data.cosmeticstate
			self:DoTaskInTime(0, function()
				self:ChangeCosmeticState(data.cosmeticstate)
				if inst._forcestage then inst._forcestage = nil end
			end)
		end
		if OnLoad_old then OnLoad_old(self, data, ...) end
	end
end

-- wormwood
AddPrefabPostInit("wormwood", function(inst)
	if not G.TheWorld.ismastersim then return end
	--inst.SetBloomStage = SetBloomStage
	inst.OnLoad = nil
	inst.OnNewSpawn = nil
	inst.OnPreLoad = nil
	inst._forcestage = true
	inst.components.bloomness.calcratefn = function() return 0 end
	--new function for /setstate
	inst.cosmeticstate = inst.cosmeticstate or 1
	function inst:ChangeCosmeticState(num) --input: number 1-4
		if num >= 1 and num <= 4 and self.components.bloomness then
			--self:SetBloomStage(num-1)
			self.components.bloomness:SetLevel(num-1)
			self.cosmeticstate = num
		end
	end
	CosmeticSaveData(inst)
end)

--beard men
for k, v in pairs({"wilson", "webber"}) do
	AddPrefabPostInit(v, function(inst)
		inst.beardfns = beardfns[v]
		inst.cosmeticstate = inst.cosmeticstate or 1
		function inst:ChangeCosmeticState(num)
			if num >= 1 and num <= 4 and inst.beardfns ~= nil then
				inst.cosmeticstate = num
				inst.beardfns[num](inst)
			end
		end
		CosmeticSaveData(inst)
	end)
end

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
	
	inst.cosmeticstate = inst.cosmeticstate or 2
	function inst:ChangeCosmeticState(num)--1-3: wimpy, normal, mighty
		if num >= 1 and num <= 3 then
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
	CosmeticSaveData(inst)
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
	
	inst.cosmeticstate = inst.cosmeticstate or 1
	function inst:ChangeCosmeticState(num)
		if num >= 1 and num <= 2 then
			if num ~= self.cosmeticstate then
				local fx = G.SpawnPrefab("small_puff") --fx because it looks awkward
				fx.Transform:SetScale(1.5, 1.5, 1.5)
				fx.Transform:SetPosition(self.Transform:GetWorldPosition())
			end
			if num == 1 then
				self.components.skinner:SetSkinMode("normal_skin", "wurt")
			else
				self.components.skinner:SetSkinMode("powerup", "wurt_stage2")
			end
			self.cosmeticstate = num
		end
	end
	CosmeticSaveData(inst)
end)

AddPrefabPostInit("woodie", function(inst)
	--this does nothing now
	--if inst.components.beaverness then inst.components.beaverness:StopTimeEffect() end
	
	--i'll need to fix the weremeter showing up eventually so here's this
end)
-- wortox
AddPrefabPostInit("wortox_soul_spawn", function(inst)
	inst:DoTaskInTime(0, inst.Remove)
end)
