local G = GLOBAL
local tonumber = G.tonumber

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
for k, v in pairs({"berrybush", "flower", "cactus", "marsh_bush" }) do
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
for k, v in pairs({"beehive", "evergreen"}) do
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
for k, v in pairs({"tentacle", "pigman"}) do
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

