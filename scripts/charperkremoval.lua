local G = GLOBAL
local require = G.require
local unpack = G.unpack

local EQUIPSLOTS = G.EQUIPSLOTS

local UpValues = require("deathmatch_upvaluehacker")
local GetUpValue = UpValues.Get
local ReplaceUpValue = UpValues.Replace
--here comes the worst hack i've ever had to do ever
local custom_common_postinits = {
	wolfgang = function(inst)
		
	end,
	wendy = function(inst)
		inst.AnimState:AddOverrideBuild("wendy_channel")
		inst.AnimState:AddOverrideBuild("player_idles_wendy")
	end,
	woodie = function(inst)
		inst.AnimState:OverrideSymbol("round_puff01", "round_puff_fx", "round_puff01")
	end,
	wathgrithr = function(inst)
		inst.AnimState:AddOverrideBuild("wathgrithr_sing")
		inst.customidleanim = "idle_wathgrithr"

		inst.components.talker.mod_str_fn = G.Umlautify
	end,
	webber = function(inst)
		inst.AnimState:AddOverrideBuild("player_idles_webber")
		inst.AnimState:AddOverrideBuild("webber_spiderwhistle")
		inst.AnimState:AddOverrideBuild("player_spider_repellent")
	end,
	wortox = function(inst)

	end,
	wanda = function(inst)
		inst.AnimState:AddOverrideBuild("player_idles_wanda")
		inst.AnimState:AddOverrideBuild("wanda_basics")
		inst.AnimState:AddOverrideBuild("wanda_attack")
	end,
	wonkey = function(inst)

	end,
}
local custom_master_postinits = {
	wilson = nil,
	willow = function(inst)
		inst.customidleanim = function(inst)
			local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			return item ~= nil and item.prefab == "bernie_inactive" and "idle_willow" or nil
		end
	end,
	wolfgang = function(inst)
		inst.customidleanim = "idle_wolfgang"
		inst.talksoundoverride = nil
		inst.hurtsoundoverride = nil
	end,
	wendy = function(inst)
		inst.customidleanim = "idle_wendy"
	end,
	wx78 = function(inst)
		inst.customidlestate = "wx78_funnyidle"
	end,
	wickerbottom = function(inst)
		inst.customidleanim = function(inst)
			return inst.AnimState:CompareSymbolBuilds("hand", "hand_wickerbottom") and "idle_wickerbottom" or nil
		end
	end,
	woodie = function(inst)
		inst.customidleanim = function(inst)
			local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			return item ~= nil and item.prefab == "lucy" and "idle_woodie" or nil
		end
	end,
	wes = function(inst)
		inst.customidlestate = "wes_funnyidle"
	end,
	waxwell = function(inst)
		inst.customidlestate = "waxwell_funnyidle"
	end,
	wathgrithr = function(inst)
		inst.talker_path_override = "dontstarve_DLC001/characters/"
	end,
	webber = nil,
	winona = nil,
	warly = nil,
	wortox = function(inst)
		inst.customidleanim = "idle_wortox"
	end,
	wormwood = function(inst)
		inst.endtalksound = "dontstarve/characters/wormwood/end"
		inst.customidleanim = function(inst)
			return inst.AnimState:CompareSymbolBuilds("hand", "hand_idle_wormwood") and "idle_wormwood" or nil
		end
	end,
	wurt = function(inst)

	end,
	walter = nil, --he gets to keep woby
	wanda = function(inst)
		inst.customidleanim = "idle_wanda"
		inst.talker_path_override = "wanda2/characters/"
	end,
	wonkey = function(inst)
		inst.customidleanim = "idle_wonkey"
		inst.talker_path_override = "monkeyisland/characters/"
	end,
}
local beardfns = {}
function G.require(modulename, ...)
	--using the local version of require since it isn't replaced
	local val = {require(modulename, ...)}
	if modulename == "prefabs/player_common" then
		local val_old = val[1]
		local function newval(name, customprefabs, customassets, common_postinit, master_postinit, ...)
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
		val[1] = newval
	end
	return unpack(val)
end
require("prefabs/wormwood")
require("prefabs/wilson")
require("prefabs/webber")
G.require = require --putting in back the original because i dont want to perma replace
local MakePlayerCharacter_old = require("prefabs/player_common")
local function MakePlayerCharacter(name, customprefabs, customassets, common_postinit, master_postinit, ...)
	if custom_common_postinits[name] ~= nil then
		print("loading custom common postinit for",name)
		common_postinit = custom_common_postinits[name]
	end
	if custom_master_postinits[name] ~= nil then
		print("loading custom master postinit for",name)
		master_postinit = custom_master_postinits[name]
	end
	return MakePlayerCharacter_old(name, customprefabs, customassets, common_postinit, master_postinit, ...)
end
G.package.loaded["prefabs/player_common"] = MakePlayerCharacter
for k, v in pairs(G.DST_CHARACTERLIST) do
	G.package.loaded["prefabs/"..v] = nil
	G.Prefabs[v] = require("prefabs/"..v)
end

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
local function SetUserFlagLevel(inst, level)
    --No bit ops support, but in this case, + results in same as |
    local flags = GLOBAL.USERFLAGS.CHARACTER_STATE_1 + GLOBAL.USERFLAGS.CHARACTER_STATE_2 + GLOBAL.USERFLAGS.CHARACTER_STATE_3
    if level > 0 then
        local addflag = GLOBAL.USERFLAGS["CHARACTER_STATE_"..tostring(level)]
        --No bit ops support, but in this case, - results in same as &~
        inst.Network:RemoveUserFlag(flags - addflag)
        inst.Network:AddUserFlag(addflag)
    else
        inst.Network:RemoveUserFlag(flags)
    end
end

-- wormwood
AddPrefabPostInit("wormwood", function(inst)
	if not G.TheWorld.ismastersim then return end
	--new function for /setstate
	inst.cosmeticstate = inst.cosmeticstate or 1
	inst.maxcosmeticstate = 4
	function inst:ChangeCosmeticState(num) --input: number 1-4
		if not IsValidSkin(self) then return end
		if num >= 1 and num <= 4 then
			--self:SetBloomStage(num-1)
			if num == 1 then
				self.components.skinner:SetSkinMode("normal_skin", "wormwood")
			else
				self.components.skinner:SetSkinMode("stage_"..tostring(num), "wormwood")
			end
			SetUserFlagLevel(inst,num-1)
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
		inst.maxcosmeticstate = 4
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

--wolfgang
AddPrefabPostInit("wolfgang", function(inst)
	inst.OnLoad = nil
	inst.OnNewSpawn = nil
	inst.OnPreLoad = nil
	
	inst.cosmeticstate = inst.cosmeticstate or 2
	inst.maxcosmeticstate = 3
	function inst:ChangeCosmeticState(num)--1-3: wimpy, normal, mighty
		if not IsValidSkin(self) then return end
		if num >= 1 and num <= 3 then
			if num == 1 then
				self.components.skinner:SetSkinMode("wimpy_skin", "wolfgang_skinny")
				self.talksoundoverride = "dontstarve/characters/wolfgang/talk_small_LP"
				self.hurtsoundoverride = "dontstarve/characters/wolfgang/hurt_small"
				self.customidleanim = "idle_wolfgang_skinny"
				self.AnimState:SetScale(0.9, 0.9, 0.9)
				SetUserFlagLevel(inst, 1)
			elseif num == 2 then
				self.components.skinner:SetSkinMode("normal_skin", "wolfgang")
				self.talksoundoverride = nil
				self.hurtsoundoverride = nil
				self.customidleanim = "idle_wolfgang"
				self.AnimState:SetScale(1,1,1)
				SetUserFlagLevel(inst, 0)
			else
				self.components.skinner:SetSkinMode("mighty_skin", "wolfgang_mighty")
				self.talksoundoverride = "dontstarve/characters/wolfgang/talk_large_LP"
				self.hurtsoundoverride = "dontstarve/characters/wolfgang/hurt_large"
				self.customidleanim = "idle_wolfgang_mighty"
				self.AnimState:SetScale(1.2,1.2,1.2)
				SetUserFlagLevel(inst, 2)
			end
			self.cosmeticstate = num
		end
	end
	CosmeticSaveData(inst)
end)

AddPrefabPostInit("wanda", function(inst)
	inst.cosmeticstate = 2
	inst.maxcosmeticstate = 3
	function inst:ChangeCosmeticState(num)--1-3: young, normal, old
		if not IsValidSkin(self) then return end
		if num >= 1 and num <= 3 then
			if num == 1 then
				inst.components.skinner:SetSkinMode("young_skin", "wilson")
				inst.talksoundoverride = "wanda2/characters/wanda/talk_young_LP"
				--inst.hurtsoundoverride = "dontstarve/characters/wolfgang/hurt_large"
				SetUserFlagLevel(inst, 1)
			elseif num == 2 then
				inst.components.skinner:SetSkinMode("normal_skin", "wilson")
				inst.talksoundoverride = nil
				inst.hurtsoundoverride = nil
				SetUserFlagLevel(inst, 0)
			elseif num == 3 then
				inst.components.skinner:SetSkinMode("old_skin", "wilson")
				inst.talksoundoverride = "wanda2/characters/wanda/talk_old_LP"
				--inst.hurtsoundoverride = "dontstarve/characters/wolfgang/hurt_small"
				SetUserFlagLevel(inst, 2)
			end
			inst.cosmeticstate = num
		end
	end
	CosmeticSaveData(inst)
end)

AddPrefabPostInit("willow", function(inst)
	inst:RemoveTag("heatresistant")
end)

AddPrefabPostInit("wx78", function(inst)
	inst:RemoveTag("batteryuser")
	inst:RemoveTag("electricdamageimmune")
	inst:RemoveTag("HASHEATER")
	inst:RemoveTag("upgrademoduleowner")
end)

--webber
AddPrefabPostInit("webber", function(inst)
	inst:RemoveTag("monster")
end)

--wortox
AddPrefabPostInit("wortox", function(inst)
	inst:RemoveTag("monster")
end)

--wurt
AddPrefabPostInit("wurt", function(inst)
	inst:RemoveTag("merm")
	
	inst.cosmeticstate = inst.cosmeticstate or 1
	inst.maxcosmeticstate = 2
	function inst:ChangeCosmeticState(num)
		if not IsValidSkin(self) then return end
		if num >= 1 and num <= 2 then
			if num == 1 then
				self.components.skinner:SetSkinMode("normal_skin", "wurt")
				SetUserFlagLevel(inst, 0)
			else
				self.components.skinner:SetSkinMode("powerup", "wurt_stage2")
				SetUserFlagLevel(inst, 1)
			end
			self.cosmeticstate = num
		end
	end
	CosmeticSaveData(inst)
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