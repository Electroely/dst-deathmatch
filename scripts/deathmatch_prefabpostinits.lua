local G = GLOBAL
local tonumber = G.tonumber
local unpack = G.unpack

local UpValues = require("deathmatch_upvaluehacker")
local GetUpValue = UpValues.Get
local ReplaceUpValue = UpValues.Replace

local COMPONENT_ACTIONS = GetUpValue(G.EntityScript.CollectActions, "COMPONENT_ACTIONS")
if COMPONENT_ACTIONS and COMPONENT_ACTIONS.INVENTORY then
	local equippable_fn_old = COMPONENT_ACTIONS.INVENTORY.equippable
	COMPONENT_ACTIONS.INVENTORY.equippable = function(inst, doer, actions, ...)
		local rtn = {equippable_fn_old(inst, doer, actions, ...)}
		if actions then
			for k, v in pairs(actions) do
				if v == G.ACTIONS.UNEQUIP then
					table.remove(actions, k)
					break
				end
			end
		end
		return unpack(rtn)
	end
	local inventory_inspectable_fn_old = COMPONENT_ACTIONS.INVENTORY.inspectable
	COMPONENT_ACTIONS.INVENTORY.inspectable = function(inst, doer, actions, ...)
		local rtn = {inventory_inspectable_fn_old(inst, doer, actions, ...)}
		if actions and inst.replica.equippable and inst.replica.equippable:IsEquipped() then
			for k, v in pairs(actions) do
				if v == G.ACTIONS.LOOKAT then
					table.remove(actions, k)
					break
				end
			end
		end
		return unpack(rtn)
	end
	local scene_inspectable_fn_old = COMPONENT_ACTIONS.SCENE.inspectable
	COMPONENT_ACTIONS.SCENE.inspectable = function(inst, doer, actions, ...)
		local rtn = {scene_inspectable_fn_old(inst, doer, actions, ...)}
		if actions and inst:HasTag("player") and GLOBAL.TheWorld.net:IsPlayerInMatch(doer.userid) then
			for k, v in pairs(actions) do
				if v == G.ACTIONS.LOOKAT then
					table.remove(actions, k)
					break
				end
			end
		end
		return unpack(rtn)
	end
end

AddPrefabPostInit("punchingbag", function(inst)
	inst:AddTag("deathmatch_punchingbag")
end)
AddPrefabPostInit("dead_sea_bones", function(inst)
	if inst.Physics ~= nil then
		inst.Physics:SetActive(false)
	end
end)

local function GetPositions(inst)
    local pt = G.Vector3(G.TheWorld.centerpoint.Transform:GetWorldPosition())
    local theta = inst.theta
    local radius = 15
    local steps = 30
	local offset = G.Vector3(radius * math.cos(theta), 0, -radius * math.sin(theta))
	
	return pt + offset
end

local function CircleShoal(inst)
	if inst.sg and inst.sg.currentstate and inst.sg.currentstate.name == "taunt" then
		return
	end

    if (inst.brain and not inst.brain.stopped) and (inst.sg and not inst.sg:HasStateTag("swoop")) and (inst.components.health and not inst.components.health:IsDead()) then
		local targetpos = GetPositions(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        local dist = G.VecUtil_Length(targetpos.x - x, targetpos.z - z)

        inst:ForceFacePoint(targetpos.x, 0, targetpos.z)
        inst.components.locomotor:WalkForward(true)
		
		inst.theta = inst.theta + (0.1)
    end
end

local function Swoop(inst, data)
	local timer_name = data and data.name or nil
	if timer_name == "deathmatch_swoop" and (inst.components.health and not inst.components.health:IsDead()) then
		local centerpoint = G.TheWorld.centerpoint
		if centerpoint then
			inst.sg:GoToState("swoop_pre", centerpoint)
			inst.drop_feathers_during_swoop = inst:DoPeriodicTask(12 * G.FRAMES, function()
				if inst.sg and inst.sg.currentstate and inst.sg.currentstate.name == "swoop_pst" then
					inst.drop_feathers_during_swoop:Cancel()
					inst.drop_feathers_during_swoop = nil
					return
				end
				if inst.sg and inst.sg:HasStateTag("swoop") then
					for i=1,3 do
						if math.random() <= 0.7 then
							inst.spawnfeather(inst,0.4)
						end
					end
				else
					inst.drop_feathers_during_swoop:Cancel()
					inst.drop_feathers_during_swoop = nil
				end
			end)
		end
		inst.components.timer:StartTimer("deathmatch_swoop", math.random(25, 30))
	end
end

local function OnAttacked(inst, data)
	if data ~= nil then
		local damage = data.damage
		if damage ~= nil and damage > 0 then
			for i=1,math.floor(damage/25) do
				if math.random() < 0.20 then
					inst.spawnfeather(inst,0.4)
				end
			end
		end
	end
end

AddPrefabPostInit("malbatross", function(inst)
	inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(G.COLLISION.GROUND)
	
	inst:AddTag("notarget")

	if not G.TheWorld.ismastersim then
		return
	end
	
	inst:SetBrain(require("brains/deathmatch_malbatrossbrain"))
	
	inst:RemoveComponent("lootdropper")
	inst:AddComponent("lootdropper")
	
	inst.components.timer:StartTimer("deathmatch_swoop", math.random(10, 15))
	inst.components.health:SetAbsorptionAmount(1)
	
	inst.theta = math.random() * 2 * G.PI
	
	inst.circle_task = inst:DoPeriodicTask(15 * G.FRAMES, CircleShoal)
	
	inst:ListenForEvent("timerdone", Swoop)
	inst:ListenForEvent("attacked", OnAttacked)
end)

AddPrefabPostInit("malbatross_feather", function(inst)
	inst:AddTag("malbatross_feather")
	inst:AddTag("deathmatch_pickup")
	
	if not G.TheWorld.ismastersim then
		return
	end
	
	if inst.components.stackable then
		inst.components.stackable.maxsize = G.TUNING.STACK_SIZE_MEDITEM
	end
end)

for k, v in pairs({"stalker_bulb", "stalker_bulb_double","stalker_fern", "stalker_berry"}) do
	AddPrefabPostInit(v, function(inst)
		if G.TheNet:GetServerGameMode() == "deathmatch" then
			inst:ListenForEvent("animover", function()
				inst.components.pickable.caninteractwith = false
			end)
		end
	end)
end

AddPrefabPostInit("lavaarena_armormediumdamager", function(inst)
	if G.TheWorld.ismastersim then
		inst.components.equippable.damagemult = nil
		inst.components.armor:InitIndestructible(0.8)
	end
end)
G.STRINGS.NAME_DETAIL_EXTENTION.LAVAARENA_ARMORMEDIUMDAMAGER = "80% Protection"
AddPrefabPostInit("lavaarena_armormediumrecharger", function(inst)
	if G.TheWorld.ismastersim then
		inst.components.equippable.cooldownmultiplier = nil
		inst.components.armor:InitIndestructible(0.8)
	end
end)
G.STRINGS.NAME_DETAIL_EXTENTION.LAVAARENA_ARMORMEDIUMRECHARGER = "80% Protection"
AddPrefabPostInit("lavaarena_rechargerhat", function(inst)
	if G.TheWorld.ismastersim then
		inst.components.equippable.cooldownmultiplier = nil
	end
end)
G.STRINGS.NAME_DETAIL_EXTENTION.LAVAARENA_RECHARGERHAT = nil
local range_postinits = {
	fireballstaff = 24,
	healingstaff = 24,
}
for prefab, range in pairs(range_postinits) do
	AddPrefabPostInit(prefab, function(inst)
		if inst.components.aoetargeting then
			inst.components.aoetargeting:SetRange(range)
		end
	end)
end
local range_display_weapons = {
	"hammer_mjolnir",
	"spear_lance",
	"book_elemental",
	"fireballstaff",
	"healingstaff",
	"teleporterhat",
	"lavaarena_firebomb",
}
for k, prefab in pairs(range_display_weapons) do
	AddPrefabPostInit(prefab, function(inst)
		local StartTargeting_old = inst.components.aoetargeting.StartTargeting
		inst.components.aoetargeting.StartTargeting = function(self, ...)
			local indicator = GLOBAL.SpawnPrefab("deathmatch_range_indicator")
			indicator:SetPlayer(GLOBAL.ThePlayer, self.range)
			return StartTargeting_old(self, ...)
		end
	end)
end

AddPrefabPostInit("lavaarena_firebomb_projectile", function(inst)
	inst.entity:AddDynamicShadow()
	inst.DynamicShadow:SetSize(1.3, 1)
end)
AddPrefabPostInit("glommer", function(inst)
	if not G.TheWorld.ismastersim then
		return
	end
	inst:RemoveComponent("lootdropper")
	inst:AddComponent("lootdropper")
end)

local function launchitem(item, angle)
    local speed = math.random() * 1.5 + 5
    angle = angle * G.DEGREES --(angle + math.random() * 60 - 30) * G.DEGREES
    item.Physics:SetVel(speed * math.sin(angle), math.random() * 2 + 8, speed * math.cos(angle))
end

local function SpawnPickup(inst)
	local pos = G.TheWorld.centerpoint:GetPosition()
	local items, players_in_peril = G.TheWorld.components.deathmatch_manager:GetPickUpItemList(pos)
	
	for k, v in pairs(items) do
		local angle = math.random(360)
		local item = G.SpawnPrefab(v)
		item.Transform:SetPosition(pos.x, 4.5, pos.z)
		launchitem(item, angle)
		table.insert(G.TheWorld.components.deathmatch_manager.spawnedpickups, item)
		if item.Fade ~= nil then item:DoTaskInTime(15, item.Fade) end
	end
	for k, v in pairs(players_in_peril) do
		local angle = inst:GetAngleToPoint(v.Transform:GetWorldPosition())+90
		local item = G.SpawnPrefab(G.TheWorld.components.deathmatch_manager.perilpickup)
		item.Transform:SetPosition(pos.x, 4.5, pos.z)
		launchitem(item, angle)
		table.insert(G.TheWorld.components.deathmatch_manager.spawnedpickups, item)
		if item.Fade ~= nil then item:DoTaskInTime(2, item.Fade) end
	end
	
end

AddPrefabPostInit("pigking", function(inst)
	if not G.TheWorld.ismastersim then
		return
	end
	
	inst.poweruptask = inst:DoPeriodicTask(11, function()
		if G.TheWorld.components.deathmatch_manager.arena == "pigvillage" and G.TheWorld.components.deathmatch_manager.matchinprogress then
			inst.sg:GoToState("cointoss")
			inst:DoTaskInTime(2 / 3, SpawnPickup)
		end
	end)
end)
-----------------------------------------------------------------------------------------

-- teamer entities
for k, v in pairs({ "lavaarena_elemental", "abigail", "balloon", "boaron" }) do
	AddPrefabPostInit(v, function(inst)
		inst:AddComponent("teamer")
	end)
end
-- non pickable entities
for k, v in pairs({"berrybush", "flower", "cactus", "oasis_cactus", "marsh_bush", "sapling", "sapling_moon" }) do
	AddPrefabPostInit(v, function(inst)
		if G.TheNet:GetServerGameMode() == "deathmatch" then
			inst:RemoveComponent("pickable")
			if v == "cactus" or v == "oasis_cactus" then
				inst.OnEntityWake = nil
			end
		end
	end)
end
-- indestructable entities
for k, v in pairs({"beehive", "evergreen", "deciduoustree"}) do
	AddPrefabPostInit(v, function(inst)
		if G.TheNet:GetServerGameMode() == "deathmatch" then
			if inst.components.workable then 
				inst:RemoveComponent("workable")
			end
			if inst.components.combat then
				inst:RemoveComponent("combat")
			end
		end
	end)
end
-- invincible entities
for k, v in pairs({"tentacle", "pigman", "stalker_forest"}) do
	AddPrefabPostInit(v, function(inst)
		if G.TheNet:GetServerGameMode() == "deathmatch" then
			if inst.components.health then
				inst.components.health:SetAbsorptionAmount(1)
			end
			inst:AddTag("notarget")
		end
	end)
end
--special pigman behavior for the pig village map
local function OnPigmanTryToHitOther(inst)
	if inst.components.werebeast:IsInWereState() then
		inst.forcetaunt = true
	else
		inst.components.combat:DropTarget()
	end
end
AddPrefabPostInit("pigman", function(inst)
	if not G.TheWorld.ismastersim then
		return
	end
	inst:ListenForEvent("onmissother", OnPigmanTryToHitOther)
	inst:ListenForEvent("onattackother", OnPigmanTryToHitOther)
end)
AddStategraphPostInit("werepig", function(self)
	self.states.attack.events.animqueueover.fn = function(inst)
		inst.sg:GoToState("howl")
	end
end)


local function makeActiveSlotItemOnly(inst)
	if G.TheWorld.ismastersim then
		local function onattacked(player)
			if player and player.components.inventory and player.components.inventory.activeitem == inst then
				player.components.inventory:DropItem(inst)
			end
		end
		local function onpickup(inst, doer)
			inst:DoTaskInTime(0, function(inst)
				if doer and doer.components.inventory then
					if inst._light then
						inst._light.entity:SetParent(doer.entity)
						doer:ListenForEvent("attacked", onattacked)
					end
					if doer.components.inventory.activeitem == nil then
						doer.components.inventory:DropItem(inst)
						doer.components.inventory:GiveActiveItem(inst)
					elseif inst.components.inventoryitem.cangoincontainer then
						doer.components.inventory:DropItem(inst)
					end
					inst.components.inventoryitem.cangoincontainer = false
				end
			end)
		end
		local function ondropped(inst)
			inst.components.inventoryitem.cangoincontainer = true
			if inst._light then
				inst._light.entity:SetParent(inst.entity)
			end
		end
		inst.components.inventoryitem:SetOnPutInInventoryFn(onpickup)
		inst.components.inventoryitem:SetOnDroppedFn(ondropped)
		local clearowner_old = inst.components.inventoryitem.ClearOwner
		inst.components.inventoryitem.ClearOwner = function(self, ...)
			if self.owner then self.owner:RemoveEventCallback("attacked", onattacked) end
			clearowner_old(self, ...)
		end
	end
end
AddPrefabPostInit("atrium_key", function(inst)
	if G.TheNet:GetServerGameMode() == "deathmatch" then
		makeActiveSlotItemOnly(inst)
		if G.TheWorld.ismastersim then
			inst._light = G.SpawnPrefab("atrium_key_light")
			inst._light.entity:SetParent(inst.entity)
			inst:ListenForEvent("onremove", function(inst)
				inst._light:Remove()
			end)
		end
	end
end)

-- AddPrefabPostInit("wardrobe", function(inst)
	-- if G.TheWorld.ismastersim then
		-- inst.components.wardrobe.canbeshared = true
	-- end
-- end)
-- register centerpoint client-side as well as server (server-side is already handled by the prefab)
-- why is it being registered client-side is the real question here
AddPrefabPostInit("lavaarena_center", function(inst)
	if not G.TheWorld.ismastersim then
		G.TheWorld:PushEvent("ms_register_lavaarenacenter", inst)
	end
end)