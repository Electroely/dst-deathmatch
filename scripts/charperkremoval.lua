local G = GLOBAL
local require = G.require

local UpValues = require("deathmatch_upvaluehacker")
local GetUpValue = UpValues.Get
local ReplaceUpValue = UpValues.Replace
--here comes the worst hack i've ever had to do ever
local beardfns = {}
function G.require(modulename, ...)
	--using the local version of require since it isn't replaced
	local val = require(modulename, ...) 
	if modulename == "prefabs/player_common" then
		local val_old = val
		function val(name, customprefabs, customassets, common_postinit, master_postinit, ...)
			if (name == "wilson" or name == "webber") and master_postinit ~= nil then
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

local function IsValidSkin(inst)
	if inst.components.skinner == nil then
		return false
	end
	local base_skin = inst.components.skinner:GetClothing().base
	return base_skin ~= nil and G.Prefabs[base_skin] ~= nil and
		G.Prefabs[base_skin].base_prefab == inst.prefab
end

-- wormwood
AddPrefabPostInit("wormwood", function(inst)
	if not G.TheWorld.ismastersim then return end
	inst.OnLoad = nil
	inst.OnNewSpawn = nil
	inst.OnPreLoad = nil
	inst._forcestage = true
	--perk modification code
	inst.components.bloomness.calcratefn = function() return 0 end
	ReplaceUpValue(inst.UpdateBloomStage, "SetStatsLevel", function() end)
	inst:ListenForEvent("ms_becameghost", function(inst)
		inst:DoTaskInTime(0, function(inst)
			inst:ChangeCosmeticState(inst.cosmeticstate)
		end)
	end)
	--new function for /setstate
	inst.cosmeticstate = inst.cosmeticstate or 1
	function inst:ChangeCosmeticState(num) --input: number 1-4
		if not IsValidSkin(self) then return end
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
			if not IsValidSkin(self) then return end
			if num >= 1 and num <= 4 and self.beardfns ~= nil then
				self.cosmeticstate = num
				self.beardfns[num](self, self.components.beard and self.components.beard.skinname or nil)
			end
		end
		CosmeticSaveData(inst)
		if G.TheWorld.ismastersim then
			local SetBeardSkin = inst.components.beard.SetSkin
			inst.components.beard.SetSkin = function(self, skin)
				self.skinname = skin
				inst.beardfns[inst.cosmeticstate](inst, skin)
			end
		end
	end)
end

--wigfrid
AddPrefabPostInit("wathgrithr", function(inst)
	if not G.TheWorld.ismastersim then return end
	inst.event_listeners.onattackother[inst][3] = function() end
end)

--wolfgang
AddPrefabPostInit("wolfgang", function(inst)
	inst.OnLoad = nil
	inst.OnNewSpawn = nil
	inst.OnPreLoad = nil
	
	inst.cosmeticstate = inst.cosmeticstate or 2
	function inst:ChangeCosmeticState(num)--1-3: wimpy, normal, mighty
		if not IsValidSkin(self) then return end
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
		if not IsValidSkin(self) then return end
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

--walter
AddPrefabPostInit("wobysmall", function(inst)
	if G.TheWorld.ismastersim and inst.components.container then
		inst:DoTaskInTime(0, function(inst)
			inst.components.container.canbeopened = false
		end)
	end
end)

--beardmen skins
AddComponentPostInit("beard", function(self)
	local OnRespawn = GetUpValue(self.OnRemoveFromEntity, "OnRespawn")
	self.inst:RemoveEventCallback("ms_respawnedfromghost", OnRespawn)
end)