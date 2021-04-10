local G = GLOBAL
local tonumber = G.tonumber

local UpValues = require("deathmatch_upvaluehacker")
local GetUpValue = UpValues.Get
local ReplaceUpValue = UpValues.Replace

local function GetPositions(inst)
    local pt = G.Vector3(G.TheWorld.centerpoint.Transform:GetWorldPosition())
    local theta = inst.theta
    local radius = 20
    local steps = 30
	local offset = G.Vector3(radius * math.cos(theta), 0, -radius * math.sin(theta))
	
	return pt + offset
end

local function CircleShoal(inst)
    if (inst.brain and not inst.brain.stopped) and (inst.sg and not inst.sg:HasStateTag("swoop")) then
		local targetpos = GetPositions(inst)
        local x, y, z = inst.Transform:GetWorldPosition()
        local dist = G.VecUtil_Length(targetpos.x - x, targetpos.z - z)

        inst:FacePoint(targetpos.x, 0, targetpos.z)
        inst.components.locomotor:WalkForward(true)
		
		inst.theta = inst.theta + (0.1)
    end
end

AddBrainPostInit("malbatrossbrain", function(self)
	local root = G.PriorityNode(
    {
        G.WhileNode(function() return not self.inst.sg:HasStateTag("swoop") and not self.inst.circle_task end, "not swooping",
            G.PriorityNode({
                --[[GLOBAL.RunAway(self.inst, function() return CheckForFleeAndDive(self.inst) end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),

                GLOBAL.FaceEntity(self.inst, GetCombatFaceTargetFn, KeepCombatFaceTargetFn),                        

                GLOBAL.ChaseAndAttack(self.inst, CHASE_TIME, CHASE_DIST),
                GLOBAL.DoAction(self.inst, GetEatAction, "Dive For Fish"),
                GLOBAL.Wander(self.inst, GetWanderPos, 30, {minwaittime = 6}),]]
            }, 1)),
    }, 1)
    
    self.bt = G.BT(self.inst, root)
end)

local function Swoop(inst, data)
	local timer_name = data and data.name or nil
	if timer_name == "deathmatch_swoop" then
		local centerpoint = G.TheWorld.centerpoint
		if centerpoint then
			inst.sg:GoToState("swoop_pre", centerpoint)
		end
		inst.components.timer:StartTimer("deathmatch_swoop", math.random(25, 30))
	end
end

AddPrefabPostInit("malbatross", function(inst)
	inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(G.COLLISION.GROUND)

	if not G.TheWorld.ismastersim then
		return
	end
	
	inst:RemoveComponent("lootdropper")
	inst:AddComponent("lootdropper")
	
	inst.components.timer:StartTimer("deathmatch_swoop", math.random(10, 15))
	inst.components.health:SetAbsorptionAmount(1)
	
	inst.theta = math.random() * 2 * G.PI
	
	inst.circle_task = inst:DoPeriodicTask(15 * G.FRAMES, CircleShoal)
	
	inst:ListenForEvent("timerdone", Swoop)
end)

AddPrefabPostInit("malbatross_feather", function(inst)
	inst:AddTag("malbatross_feather")
end)

local function getPlayerCount(onlyalive)
	local count = 0
	for k, v in pairs(G.AllPlayers) do
		if not v:HasTag("spectator") and (not onlyalive or not v.components.health:IsDead()) then
			count = count + 1
		end
	end
	return count
end

local STALKERBLOOM_TAGS = { "stalkerbloom" }
local function DoPlantBloom(inst)  --replacing, awesome
	local count = getPlayerCount(true)
    local x, y, z = inst.Transform:GetWorldPosition()
    local map = G.TheWorld.Map
    local offset = G.FindValidPositionByFan(
        math.random() * 2 * G.PI,
        math.random() * 3,
        8,
        function(offset)
            local x1 = x + offset.x
            local z1 = z + offset.z
            return map:IsPassableAtPoint(x1, 0, z1)
                and map:IsDeployPointClear(G.Vector3(x1, 0, z1), nil, 1)
                and #G.TheSim:FindEntities(x1, 0, z1, 2.5, STALKERBLOOM_TAGS) < 4
        end
    )
	
	local BLOOM_CHOICES =
	{
		["stalker_bulb"] = .3 + (.05 * count),
		["stalker_bulb_double"] = .3 + (.05 * count),
		["stalker_berry"] = 1,
		["stalker_fern"] = 8,
	}

    if offset ~= nil then
        G.SpawnPrefab(G.weighted_random_choice(BLOOM_CHOICES)).Transform:SetPosition(x + offset.x, 0, z + offset.z)
    end
end

AddPrefabPostInit("stalker_forest", function(inst)
	if G.TheWorld.ismastersim then
		inst:DoTaskInTime(1/30, function()
			inst._bloomtask = inst:DoPeriodicTask(3 * G.FRAMES, DoPlantBloom, 2 * G.FRAMES)
		end)
	end
end)

for k, v in pairs({"stalker_bulb", "stalker_bulb_double"}) do
	AddPrefabPostInit(v, function(inst)
		if G.TheNet:GetServerGameMode() == "deathmatch" then
			inst:ListenForEvent("animover", function()
				if inst._killtask ~= nil then
					local _fn = inst._killtask.fn
					inst._killtask.fn = function(inst, ...)
						_fn(inst, ...)
						inst.components.pickable.caninteractwith = true
					end
				end
			end)
		end
	end)
end

for k, v in pairs({"stalker_fern", "stalker_berry"}) do
	AddPrefabPostInit(v, function(inst)
		if G.TheNet:GetServerGameMode() == "deathmatch" then
			inst:ListenForEvent("animover", function()
				inst.components.pickable.caninteractwith = false
			end)
		end
	end)
end

local powerups = {
	"cooldown",
	"damage",
	"defense",
	"heal",
	"speed",
}
	
local buffs = {
	["damage"] = "pickup_lightdamaging",
	["defense"] = "pickup_lightdefense",
	["speed"] = "pickup_lightspeed",
	["heal"] = "pickup_lighthealing",
	["cooldown"] = "pickup_cooldown",
}

for k, v in pairs({"stalker_bulb", "stalker_bulb_double"}) do
	AddPrefabPostInit(v, function(inst)
		function inst:GetBasicDisplayName() --i cant just set inst.name so woo yeah hack time
			return "Power Flower"
		end	

		if G.TheWorld.ismastersim and G.TheNet:GetServerGameMode() == "deathmatch" then
			inst.powerup = G.GetRandomItem(powerups)
			inst.AnimState:OverrideSymbol("bulb", "powerflier_bulbs", inst.powerup.."bulb")

			local _OnPicked = inst.components.pickable.onpickedfn
			inst.components.pickable.onpickedfn = function(inst, picker, ...)
				if _OnPicked ~= nil then
					_OnPicked(inst, picker, ...)
					
					local powerup = G.SpawnPrefab(buffs[inst.powerup])
					powerup.components.inventoryitem.onpickupfn(powerup, picker)
				end
			end
			
			inst.components.pickable.quickpick = true
			inst.components.pickable:SetUp(nil, 1000000)
		end
	end)
end

AddPrefabPostInit("beehive", function(inst)
	if G.TheWorld.ismastersim and G.TheNet:GetServerGameMode() == "deathmatch" then
		inst:DoTaskInTime(0, function(inst)
			inst.components.childspawner:SetRegenPeriod(5)
			inst.components.childspawner:SetSpawnPeriod(5)
			inst.components.childspawner:SetMaxChildren(1)
		inst.components.childspawner.emergencychildrenperplayer = 0
		inst.components.childspawner:SetMaxEmergencyChildren(0)
		inst.components.childspawner:SetEmergencyRadius(0)
		end)
	end
end)

local function beepostinit(inst)
	if G.TheWorld.ismastersim and G.TheNet:GetServerGameMode() == "deathmatch" then
		inst:RemoveComponent("lootdropper")
		inst:AddComponent("lootdropper")
		for k, v in pairs(G.TheWorld.components.deathmatch_manager.pickupprefabs) do
			inst.components.lootdropper:AddRandomLoot(v, 1)
		end
		inst.components.lootdropper.numrandomloot = 1
		inst:ListenForEvent("death", function(inst)
			G.SpawnPrefab("small_puff").Transform:SetPosition(inst:GetPosition():Get())
		end)
		local flinglootfn_old = inst.components.lootdropper.FlingItem
		function inst.components.lootdropper:FlingItem(loot, pt)
			flinglootfn_old(self, loot, pt)
			if loot.Fade ~= nil then
				loot:DoTaskInTime(15, loot.Fade)
			end
		end
		
		inst.components.health:SetMaxHealth(400)
	end
end
AddPrefabPostInit("bee", beepostinit)
AddPrefabPostInit("killerbee", beepostinit)
AddPrefabPostInit("lavaarena_armormediumdamager", function(inst)
	if G.TheWorld.ismastersim then
		inst.components.equippable.damagemult = 1.25
		inst.components.armor:InitIndestructible(0.8)
	end
end)
G.STRINGS.NAME_DETAIL_EXTENTION.LAVAARENA_ARMORMEDIUMDAMAGER = "80% Protection\n+25% Physical Damage"
AddPrefabPostInit("lavaarena_armormediumrecharger", function(inst)
	if G.TheWorld.ismastersim then
		inst.components.equippable.cooldownmultiplier = 0.25
		inst.components.armor:InitIndestructible(0.8)
	end
end)
G.STRINGS.NAME_DETAIL_EXTENTION.LAVAARENA_ARMORMEDIUMRECHARGER = "80% Protection\n+25% Faster Cooldown"
 
AddPrefabPostInit("glommer", function(inst)
	if not G.TheWorld.ismastersim then
		return
	end
	inst:RemoveComponent("lootdropper")
	inst:AddComponent("lootdropper")
end)

local function getPlayerCount(onlyalive)
	local count = 0
	for k, v in pairs(G.AllPlayers) do
		if not v:HasTag("spectator") and (not onlyalive or not v.components.health:IsDead()) then
			count = count + 1
		end
	end
	return count
end

local function launchitem(item, angle)
    local speed = math.random() * 1.5 + 5
    angle = (angle + math.random() * 60 - 30) * G.DEGREES
    item.Physics:SetVel(speed * math.cos(angle), math.random() * 2 + 8, speed * math.sin(angle))
end

local function SpawnPickup(inst)
	local pos = G.TheWorld.centerpoint:GetPosition()
	local items = G.TheWorld.components.deathmatch_manager:GetPickUpItemList(pos)
	
	for k, v in pairs(items) do
		local angle = math.random(360)
		local item = G.SpawnPrefab(v)
		item.Transform:SetPosition(pos.x, 4.5, pos.z)
		launchitem(item, angle)
		table.insert(G.TheWorld.components.deathmatch_manager.spawnedpickups, item)
		if item.Fade ~= nil then item:DoTaskInTime(15, item.Fade) end
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
for k, v in pairs({ "abigail", "balloon", "boaron" }) do
	AddPrefabPostInit(v, function(inst)
		inst:AddComponent("teamer")
	end)
end
-- non pickable entities
for k, v in pairs({"berrybush", "flower", "cactus", "marsh_bush"}) do
	AddPrefabPostInit(v, function(inst)
		if G.TheNet:GetServerGameMode() == "deathmatch" then
			inst:RemoveComponent("pickable")
			if v == "cactus" then
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

AddPrefabPostInit("world", function(inst) --can't this just go into prefabs/deathmatch.lua?
	if inst.ismastersim and G.TheNet:GetServerGameMode() == "deathmatch" then
		inst:AddComponent("deathmatch_manager")
		inst:DoTaskInTime(0, function(inst)
			inst.components.deathmatch_manager:SetGamemode(1)
			inst.components.deathmatch_manager:SetNextArena("random")
			G.print("remember to announce on steam group!") --TODO: remove
		end)
		inst:ListenForEvent("wehaveawinner", function(world, winner)
			if type(winner) == "number" then
				G.TheNet:Announce(G.DEATHMATCH_TEAMS[winner].name .. " Team wins!")
			elseif type(winner) == "table" then
				G.TheNet:Announce(winner:GetDisplayName() .. " wins with "..tostring(math.ceil(winner.components.health.currenthealth)).." health remaining!")
			end
		end)
		inst:ListenForEvent("ms_playerjoined", function(inst)
			inst.net:PushEvent("deathmatch_timercurrentchange", inst.components.deathmatch_manager.timer_current)
			inst.net:PushEvent("deathmatch_matchmodechange", inst.components.deathmatch_manager.gamemode == 0 and 4 or inst.components.deathmatch_manager.gamemode)
			inst.net:PushEvent("deathmatch_matchstatuschange", inst.net.deathmatch_netvars.globalvars.matchstatus:value())
		end)
	end
	inst:ListenForEvent("ms_register_lavaarenacenter", function(world, center)
		world.centerpoint = center
	end)
end)

