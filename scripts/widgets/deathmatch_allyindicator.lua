local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"

local DEFAULT_ATLAS = "images/avatars.xml"

local ARROW_OFFSET = 20
local ARROW_OFFSET_CORPSE = 150

local function IsAlly(owner, target)
	return target and target.components.teamer and target.components.teamer:IsTeamedWith(owner) or target:HasTag("deadteammatetest")
end
local function IsDead(target)
	return target and target.AnimState:IsCurrentAnimation("death2_idle")
end
local function isOffScreen(target)
	return ThePlayer and ThePlayer.components.hudindicatorwatcher and target and table.contains(ThePlayer.components.hudindicatorwatcher.offScreenItems, target)
end

local function CreateStand()
    local inst = CreateEntity()

    --[[Non-networked entity]]
    if not TheWorld.ismastersim then
        inst.entity:SetCanSleep(false)
    end

    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.AnimState:SetBank("poi_stand")
    inst.AnimState:SetBuild("flint")
    inst.AnimState:PlayAnimation("idle")

    inst.alpha = 1
    inst.scale = 1

    return inst
end
local function CreateIndicator(target)
	local stand = CreateStand()
	target:AddChild(stand)

    local inst = CreateEntity()

    --[[Non-networked entity]]
    if not TheWorld.ismastersim then
        inst.entity:SetCanSleep(false)
    end

    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
	inst.entity:AddFollower()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")

    inst.AnimState:SetBank("poi_marker")
    inst.AnimState:SetBuild("poi_marker")
    inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetLightOverride(1)
	inst.AnimState:SetLayer(LAYER_WORLD_DEBUG)

	local scale = 1.5
    inst.Transform:SetScale(scale,scale,scale)
	
	inst.stand = stand
	stand.marker = inst

	function stand:SetHeight(h)
		if self.height == nil or self.height ~= h then
			self.height = h
			self.marker.Follower:FollowSymbol(stand.GUID, "marker", 0, h, 0)
		end
	end
	stand:SetHeight(ARROW_OFFSET)

	inst:ListenForEvent("onremove", function() inst:Remove() end, stand)

    return stand
end


local UPDATE_PERIOD = 10*FRAMES
local function OnUpdate(inst, self)
	if self.owner == nil then
		self.owner = ThePlayer
	end
	for k, v in pairs(AllPlayers) do
		if v ~= self.owner and IsAlly(self.owner, v) and not isOffScreen(v) then
			if self.arrows[v] == nil then
				local indicator = CreateIndicator(v)
				self.arrows[v] = indicator
				indicator:ListenForEvent("onremove", function() indicator:Remove() end, self.inst)
			end
			if IsDead(v) then
				self.arrows[v]:SetHeight(ARROW_OFFSET_CORPSE)
				self.arrows[v].marker.AnimState:OverrideSymbol("circle", "deathmatch_poi_marker", "circle_revive")
			else
				self.arrows[v]:SetHeight(ARROW_OFFSET)
				self.arrows[v].marker.AnimState:OverrideSymbol("circle", "deathmatch_poi_marker", "circle_friend")
			end
		else
			if self.arrows[v] then
				self.arrows[v]:Remove()
				self.arrows[v] = nil
			end
		end
	end
end
local Deathmatch_AllyIndicator = Class(Widget, function(self, owner)
	Widget._ctor(self, "Deathmatch_AllyIndicator")

	self.owner = owner

	self.arrows = {}

	--self:StartUpdating()
	self.inst:DoPeriodicTask(UPDATE_PERIOD, OnUpdate, 0, self)
end)

return Deathmatch_AllyIndicator