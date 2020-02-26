local G = GLOBAL
local tonumber = G.tonumber
local gamemodename = "deathmatch" 
G.DEATHMATCH_STRINGS = G.require("deathmatch_strings")
local DEATHMATCH_STRINGS = G.DEATHMATCH_STRINGS
local DEATHMATCH_POPUPS = DEATHMATCH_STRINGS.POPUPS
local ARENAS = G.require("deathmatch_arenadefs")

local PopupDialogScreen = G.require("screens/redux/popupdialog")
AddPrefabPostInit("player_classified", function(inst)
	if G.TheNet:GetServerGameMode() == gamemodename then
		inst._arenaeffects = G.net_string(inst.GUID, "deathmatch.arenaeffect", "arenachanged")
		inst:ListenForEvent("arenachanged", function(inst, data)
			G.TheWorld:PushEvent("applyarenaeffects", inst._arenaeffects:value())
		end)
		inst._choosinggear = G.net_bool(inst.GUID, "deathmatch.choosinggear", "choosinggearchanged")
		if not G.TheWorld.ismastersim then
			inst:ListenForEvent("choosinggearchanged", function(inst, data)
				if inst._parent.HUD and inst._choosinggear:value() then
					inst._parent.HUD.controls.deathmatch_chooseyourgear:Show()
				elseif inst._parent.HUD then
					inst._parent.HUD.controls.deathmatch_chooseyourgear:Hide()
				end
			end)
		end
		G.TheWorld:ListenForEvent("startchoosinggear", function() inst._choosinggear:set(true) end)
		G.TheWorld:ListenForEvent("donechoosinggear", function() inst._choosinggear:set(false) end)
		inst._privatemessage = G.net_string(inst.GUID, "deathmatch.privatemessage", "pmdirty")
		inst._privatemessage_sender = G.net_string(inst.GUID, "deathmatch.privatemessage_sender")
		inst._privatemessage_team = G.net_byte(inst.GUID, "deathmatch.privatemessage_team")
		
		inst._deathmatchpopup = G.net_string(inst.GUID, "deathmatch.popupname", "ondeathmatchpopup")
		if G.TheWorld.ismastersim then
			inst:ListenForEvent("pushdeathmatchpopup", function(inst, popupname)
				inst._deathmatchpopup:set(popupname)
				inst._deathmatchpopup:set_local("") --to make sure it's always dirty
			end, inst._parent)
		end
		if not G.TheNet:IsDedicated() then
			inst:ListenForEvent("ondeathmatchpopup", function(inst)
				--i might need to code special cases for welcome and welcome_loner so
				--they're saved clientside and no player has to see on every time they
				--join a server
				local n = inst._deathmatchpopup:value()
				G.TheFrontEnd:PushScreen(PopupDialogScreen(DEATHMATCH_POPUPS[n][1], DEATHMATCH_POPUPS[n][2],
					{
						{text="Close", cb = function() G.TheFrontEnd:PopScreen() end}
					}))
			end)
		end
	end
end)
--G.getmetatable(G.TheNet).__index.GetDefaultVoteEnabled = function() return true end
local announce_old = G.getmetatable(G.TheNet).__index.AnnounceResurrect
G.getmetatable(G.TheNet).__index.AnnounceResurrect = function(self, announcement, ...)
	if announcement and string.find(announcement, "by Shenanigans") then
		return 
	end
	return announce_old(self, announcement, ...)
end

G.DEATHMATCH_TEAMS = {
{name="Red", colour={1,0.5,0.5,1}},
{name="Blue", colour={0.5,0.5,1,1}},
{name="Yellow", colour={1,1,0.5,1}},
{name="Green", colour={0.5,1,0.5,1}},
{name="Orange", colour={1,0.5,0,1}},
{name="Cyan", colour={0.5,1,1,1}},
{name="Pink", colour={1,0.5,1,1}},
{name="Black", colour={97/255, 80/255, 132/255, 1}},
}

PrefabFiles = {
	"lavaarena", --to load the assets
	"quagmire",
	"deathmatch_pickups",
	"explosiveballoons_empty",
	"teleporterhat",
	"armorstealth",
	"laserhat",
	"armorjump",
	"blowdart_lava_temp",
	"snortoisehat",
	"fakesnortoise",
	"deathmatch",
	"deathmatch_network",
	"deathmatch_infosign",
	"arena_centerpoints",
	"atrium_key_light",
	"fakeplayer",
	"deathmatch_oneusebomb",
	"shadowweapons",
	"boatspawner",
}
Assets = {
	Asset("ANIM", "anim/hat_snortoise.zip")
}
local function UserOnline(clienttable, userid)
	local found = false
	for k, v in pairs(clienttable) do
		if v.userid == userid then
			found = true
		end
	end
	return found
end
local function GetPlayerTable()
	local clienttbl = G.TheNet:GetClientTable()
	if clienttbl == nil then
		return {}
	elseif G.TheNet:GetServerIsClientHosted() then
		return clienttbl
	end
	
    for i, v in ipairs(clienttbl) do
        if v.performance ~= nil then
            table.remove(clienttbl, i)
            break
        end
    end
    return clienttbl
end
local function SetDirty(netvar, val)
	netvar:set_local(val)
	netvar:set(val)
end
function G.GetNetDMDataTable(userid)
	for _, v in pairs(G.TheWorld.net.deathmatch_netvars) do
		if v.userid and v.userid:value() == userid then
			return v
		end
	end
	return nil
end
local GetNetDMDataTable = G.GetNetDMDataTable

local function InitDeathmatchData(userid)
	G.TheWorld.net.deathmatch[userid] = { 
		--kills=G.net_byte(G.TheWorld.net.GUID, "deathmatch."..tostring(userid).."_kills", "deathmatch_killsdirty"),
		kills_local=0,
		--deaths=G.net_byte(G.TheWorld.net.GUID, "deathmatch."..tostring(userid).."_deaths", "deathmatch_deathsdirty"),
		--deaths_local=0,
		--team=G.net_byte(G.TheWorld.net.GUID, "deathmatch."..tostring(userid).."_team", "deathmatch_teamdirty"),
		team_local=0
	}
end

local function OnKillOther(inst, data)
	G.TheWorld.net:PushEvent("deathmatch_kill", { inst=inst, data=data })
end

local function OnDeath(inst, data)
	--G.TheWorld.net:PushEvent("deathmatch_death", { inst=inst, data=data })
	G.TheWorld:PushEvent("playerdied")
end

AddComponentPostInit("healthsyncer", function(self, inst)
	local oldGetpct = self.GetPercent
	self.GetPercent = function(self)
		if self.inst:HasTag("playerghost") or self.inst:HasTag("spectator") then
			return 0
		else
			return oldGetpct(self)
		end
	end
end)

AddComponentPostInit("combat", function(self, inst)
	if G.TheNet:GetServerGameMode() == gamemodename then
		local engage_old = self.EngageTarget
		self.EngageTarget = function(self, target)
			if not inst:HasTag("player") and target and target:HasTag("player") then
				target.numattackers = target.numattackers + 1
			end
			return engage_old(self, target)
		end
		
		local drop_old = self.DropTarget
		self.DropTarget = function(self, hasnexttarget)
			if not inst:HasTag("player") and self.target and self.target:HasTag("player") then
				self.target.numattackers = self.target.numattackers - 1
			end
			return drop_old(self, hasnexttarget)
		end
		
		local validt_old = self.IsValidTarget
		self.IsValidTarget = function(self, target)
			if target and not inst:HasTag("player") and target:HasTag("player") and target.numattackers >= 2 then
				--print("player has too many attackers")
				return false
			end
			return validt_old(self, target)
		end
	end
end)

AddClassPostConstruct("components/combat_replica", function(self, inst)
	if G.TheNet:GetServerGameMode() == "deathmatch" then
		local IsValidTarget_Old = self.IsValidTarget
		self.IsValidTarget = function(self, target)
			if target ~= nil and target.components and 
				((target.components.teamer and target.components.teamer:IsTeamedWith(self.inst))
				or (target:HasTag("spectator") or self.inst:HasTag("spectator"))) then
					return false
			else
				return IsValidTarget_Old(self, target)
			end
		end
		
		local IsAlly_Old = self.IsAlly
		self.IsAlly = function(self, guy)
			if guy and guy.components and
			guy.components.teamer and guy.components.teamer:IsTeamedWith(self.inst) then
				return true
			else
				return IsAlly_Old(self, guy)
			end
		end
		
		local CanBeAttacked_Old = self.CanBeAttacked
		self.CanBeAttacked = function(self, attacker)
			if attacker and (attacker.components and attacker.components.teamer and
			attacker.components.teamer:IsTeamedWith(self.inst) or
			self.inst:HasTag("spectator") or attacker:HasTag("spectator")) then
				return false
			else
				return CanBeAttacked_Old(self, attacker)
			end
		end
	end
end)

AddComponentPostInit("playeractionpicker", function(self)
	local GetRightClickActions_Old = self.GetRightClickActions
	self.GetRightClickActions = function(self, position, target)
		local actions = {}
		if self.inst.components.playercontroller and self.inst.components.playercontroller.reticule and
			self.inst.components.playercontroller.reticule.inst and self.inst.components.playercontroller.reticule.reticule then
			local equipitem = self.inst.components.playercontroller.reticule.inst
			if equipitem ~= nil and equipitem:IsValid() then
				actions = self:GetPointActions(position, equipitem, true)

				if equipitem.components.aoetargeting ~= nil then
					return (#actions <= 0 or actions[1].action == G.ACTIONS.CASTAOE) and actions or {}
				end
			end
		elseif self.inst.components.playercontroller.reticuleitemslot ~= nil then
			local equipitem = self.inst.replica.inventory:GetEquippedItem(self.inst.components.playercontroller.reticuleitemslot)
			if equipitem ~= nil and equipitem:IsValid() then
				actions = self:GetPointActions(position, equipitem, true)

				if equipitem.components.aoetargeting ~= nil then
					return (#actions <= 0 or actions[1].action == G.ACTIONS.CASTAOE) and actions or {}
				end
			end
		else
			actions = GetRightClickActions_Old(self, position, target)
		end
		return actions or {}
	end
end)

AddComponentPostInit("playercontroller", function(self) -- aoetargeting compability for non-hand slot items
	local HasAOETargeting_Old = self.HasAOETargeting
	self.HasAOETargeting = function(self)
		local test = HasAOETargeting_Old(self)
		if not test then
			local item = self.inst.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.HEAD)
			item = item or self.inst.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.BODY)
			return item ~= nil
				and item.components.aoetargeting ~= nil
				and item.components.aoetargeting:IsEnabled()
				and not (self.inst.replica.rider ~= nil and self.inst.replica.rider:IsRiding())
		end
		return test
	end
	
	local TryAOETargeting_Old = self.TryAOETargeting
	self.TryAOETargeting = function(self, slot)
		if slot == nil then
			TryAOETargeting_Old(self)
			SendModRPCToServer(GetModRPC(modname, "deathmatch_currentreticule_change"), G.EQUIPSLOTS.HANDS)
			self.reticuleitemslot = G.EQUIPSLOTS.HANDS
		else 
			local item = self.inst.replica.inventory:GetEquippedItem(G.EQUIPSLOTS[string.upper(slot)])
			if item ~= nil and
				item.components.aoetargeting ~= nil and
				item.components.aoetargeting:IsEnabled() and
				not (self.inst.replica.rider ~= nil and self.inst.replica.rider:IsRiding()) then
				SendModRPCToServer(GetModRPC(modname, "deathmatch_currentreticule_change"), G.EQUIPSLOTS[string.upper(slot)])
				self.reticuleitemslot = G.EQUIPSLOTS[string.upper(slot)]
				item.components.aoetargeting:StartTargeting()
			end
		end
	end
	
	local RefreshReticule_Old = self.RefreshReticule
	self.RefreshReticule = function(self)
		RefreshReticule_Old(self)
		if self.reticule == nil then
			local item = self.inst.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.HEAD)
			if item and item.components.reticule ~= nil then
				self.reticule = item.components.reticule
			else
				item = self.inst.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.BODY)
				if item and item.components.reticule ~= nil then
					self.reticule = item.components.reticule
				else
					self.reticule = nil
				end
			end
		end
		if self.reticule ~= nil and self.reticule.reticule == nil and (self.reticule.mouseenabled or G.TheInput:ControllerAttached()) then
			self.reticule:CreateReticule()
		end
	end
end)

AddComponentPostInit("drownable", function(self)
	local _Teleport = self.Teleport
	function self:Teleport()
		if G.TheWorld.components.deathmatch_manager.arena == "ocean" then
			local boats = {}
		
			for k, v in pairs(G.Ents) do
				if v and v.prefab == "boat" then
					table.insert(boats, v)
				end
			end
		
			local pos = boats[math.random(#boats)]:GetPosition()

			if self.inst.Physics ~= nil and pos ~= nil then
				self.inst.Physics:Teleport(pos.x, pos.y, pos.z)
			elseif self.inst.Transform ~= nil and pos ~= nil then
				self.inst.Transform:SetPosition(pos.x, pos.y, pos.z)
			end
		else
			return _Teleport(self)
		end
	end
	
	function self:OnFallInOcean(shore_x, shore_y, shore_z)
		self.src_x, self.src_y, self.src_z = self.inst.Transform:GetWorldPosition()
		
		if shore_x == nil then
			shore_x, shore_y, shore_z = G.FindRandomPointOnShoreFromOcean(self.src_x, self.src_y, self.src_z)
		end

		self.dest_x, self.dest_y, self.dest_z = shore_x, shore_y, shore_z
	end
	
	function self:DropInventory()
		--no drop inventory, bad
	end
end)

G.require("player_postinits_deathmatch") --so... why did i separate this into its own thing if im adding a postinit here regardless...?
--TODO: move all of the code here to player_postinits_deathmatch and organize it better
--character-specific changes go into charperkremoval.lua
modimport("scripts/charperkremoval")
AddPlayerPostInit(function(inst)
	inst.requestmousepos = G.net_event(inst.GUID, "net_locationrequest")
	inst.numattackers = 0
	if not G.TheWorld.ismastersim then
		inst:ListenForEvent("net_locationrequest", function(inst)
			if inst == G.ThePlayer then
				local x, y, z = (G.TheInput:GetWorldPosition() - inst:GetPosition()):Get()
				SendModRPCToServer(GetModRPC(modname, "locationrequest"), x, z)
			end
		end)
	end
	if G.TheNet:GetServerGameMode() == "deathmatch" then
		
		inst:AddTag("soulless")
		
		inst.components.playervision.SetGhostVision = function() end
		inst:ListenForEvent("killed", OnKillOther)
		inst:ListenForEvent("death", OnDeath)
		inst:AddComponent("healthsyncer")
		inst:AddComponent("teamer")
		if not G.TheNet:IsDedicated() then
			inst._teamindicator = G.SpawnPrefab("reticule")
			inst._teamindicator.entity:SetParent(inst.entity)
			local function onteamchange(inst)
				local team = inst.components.teamer.team
				local colour
				if team == 0 then
					inst._teamindicator:Hide()
				else
					inst._teamindicator:Show()
					colour = G.DEATHMATCH_TEAMS[team].colour
					inst._teamindicator.AnimState:SetMultColour(G.unpack(colour))
				end
			end
			inst:ListenForEvent("teamdirty", onteamchange)
			onteamchange(inst)
		end
		inst:AddComponent("deathmatch_spectatorcorpse")

		if inst.components.revivablecorpse then
			inst.components.revivablecorpse:SetCanBeRevivedByFn(function(inst, reviver)
				return inst.components.teamer:IsTeamedWith(reviver)
			end)
		end
		
		if G.TheWorld.ismastersim then
			inst.deathmatch_pickuptasks = {}
			inst.components.combat.damagemultiplier = 1
			inst.components.combat:SetPlayerStunlock(G.PLAYERSTUNLOCK.SOMETIMES)
			inst.components.health:SetAbsorptionAmount(0)
			inst:DoTaskInTime(1, function(inst)
				if G.TheWorld.net.deathmatch[inst.userid] then
					inst.components.teamer:SetTeam(G.TheWorld.net.deathmatch[inst.userid].team_local)
				end
			end)
			
			inst:ListenForEvent("onhitother", function(inst, data)
				if data.target and data.target:HasTag("player") then
					G.TheWorld:PushEvent("registerdamagedealt", {player = inst, damage = data.damage})
				end
				if data and data.damage then
					local ind = G.SpawnPrefab("damagenumber")
					ind:Push(inst, data.target, data.damage, false)
				end
			end)
			local health = 150
			inst.components.health:SetMaxHealth(health)
			inst.components.combat.hitrange = 2.5
			inst.components.combat.playerdamagepercent = 1
		end
		---------- character perks
		G.require("player_postinits_deathmatch")(inst, inst.prefab)
		inst.starting_inventory = {}
	end
end)

-----------------------------------------------------------------------------------------
--TODO: move all of these prefab postinits into their own file
--also, wortox soul removal should go into charperkremoval
AddPrefabPostInit("wortox_soul_spawn", function(inst)
	inst:DoTaskInTime(0, inst.Remove)
end)

AddPrefabPostInit("beehive", function(inst)
	if G.TheWorld.ismastersim and G.TheNet:GetServerGameMode() == gamemodename then
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
if G.TheNet and  G.TheNet:GetServerGameMode() == gamemodename then
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
end

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
    local speed = math.random() * 4 + 2
    angle = (angle + math.random() * 60 - 30) * G.DEGREES
    item.Physics:SetVel(speed * math.cos(angle), math.random() * 2 + 8, speed * math.sin(angle))
end

local function SpawnPickup(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
	local pos = G.TheWorld.centerpoint:GetPosition()
	local count = getPlayerCount(true)
    local angle = math.random(360)
	local nearbyplayers = 0
	for k, v in pairs(G.TheWorld.components.deathmatch_manager.players_in_match) do
		if v and v:IsValid() and not v.components.health:IsDead() and v:GetDistanceSqToPoint(pos) <= 25 then
			nearbyplayers = nearbyplayers + 1
		end
	end
	
	if G.TheWorld.components.deathmatch_manager.enabledarts and nearbyplayers ~= 0 and nearbyplayers <= count/2 then
		local bomb = G.SpawnPrefab("deathmatch_oneusebomb")
        bomb.Transform:SetPosition(x, 4.5, z)
        launchitem(bomb, angle)
	end

    for k = 1, math.floor(count/2) do
        local pickup = G.SpawnPrefab(G.GetRandomItem(G.TheWorld.components.deathmatch_manager.pickupprefabs))
        pickup.Transform:SetPosition(x, 4.5, z)
        launchitem(pickup, angle)
		if pickup.Fade ~= nil then
			pickup:DoTaskInTime(15, pickup.Fade)
		end
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

AddPrefabPostInit("oar", function(inst)
	if not G.TheWorld.ismastersim then
		return
	end
	
	inst.components.oar.force = 2 --Oars are way too weak right now, they should be stronger
	
	inst:RemoveComponent("finiteuses")
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
		if G.TheNet:GetServerGameMode() == gamemodename then
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
		if G.TheNet:GetServerGameMode() == gamemodename then
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
		if G.TheNet:GetServerGameMode() == gamemodename then
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
	if G.TheNet:GetServerGameMode() == gamemodename then
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
AddPrefabPostInit("lavaarena_center", function(inst)
	if not G.TheWorld.ismastersim then
		G.TheWorld:PushEvent("ms_register_lavaarenacenter", inst)
	end
end)

AddPrefabPostInit("world", function(inst)
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


---------------------------------------------------------------------
local Text = G.require("widgets/text")
local Deathmatch_LobbyTimer = G.require("widgets/deathmatch_lobbytimer")

AddClassPostConstruct("widgets/controls", function(self, owner)
	if G.TheNet:GetServerGameMode() == "deathmatch" then
		self.deathmatch_playerlist = self.topleft_root:AddChild(G.require("widgets/deathmatch_playerlist")(owner))
		self.deathmatch_status = self.topright_root:AddChild(G.require("widgets/deathmatch_status")(owner))
		self.deathmatch_status:SetPosition(-150,-20)
		self.deathmatch_status.inst:DoPeriodicTask(3, function() self.deathmatch_status:Refresh() end)
		
		self.deathmatch_spectatorspinner = self.bottom_root:AddChild(G.require("widgets/deathmatch_spectatorspinner")(owner))
		self.deathmatch_spectatorspinner:SetPosition(0,150)
		if owner.components.deathmatch_spectatorcorpse and owner.components.deathmatch_spectatorcorpse.active then
			self.deathmatch_spectatorspinner:Show()
		else
			self.deathmatch_spectatorspinner:Hide()
		end
		
		self.deathmatch_chooseyourgear = self.bottom_root:AddChild(G.require("widgets/deathmatch_chooseyourgear")(owner))
		self.deathmatch_chooseyourgear:SetPosition(0,300)
		self.deathmatch_chooseyourgear:Hide()
		
		self.clock:Hide()
		self.status.stomach:Hide()
		self.status.stomach.Show = function() end
		self.status.brain:Hide()
		self.status.brain.Show = function() end -- im gay
	end
end)

AddClassPostConstruct("screens/redux/lobbyscreen", function(self)
	self.deathmatch_timer = self.root:AddChild(Deathmatch_LobbyTimer())
	self.deathmatch_timer:SetPosition(40, 310, 0)
end)

---------------------------------------------------------------------
local _name = GLOBAL.STRINGS.NAMES

_name.PICKUP_LIGHTDAMAGING = "Damage Boost\n+50% Damage Dealt\nLasts 10 Seconds"
_name.PICKUP_LIGHTDEFENSE = "Defense Boost\n-50% Damage Taken\nLasts 15 Seconds"
_name.PICKUP_LIGHTSPEED = "Speed Boost\n+50% Movement Speed\nLasts 10 Seconds"
_name.PICKUP_LIGHTHEALING = "Health Restoration\nRestore 10-20 Health"
_name.PICKUP_COOLDOWN = "Instant Refresh\nResets cooldown of all weapons in inventory"

_name.DEATHMATCH_INFOSIGN = "Info Sign"
_name.DUMMYTARGET = "Target Dummy"
----------------------------------------------------------------------
local function FindKeyFromName(name)
	if name ~= nil and G.type(name) == "string" and name:lower() ~= "none" then
		for i, v in ipairs(G.DEATHMATCH_TEAMS) do
			if v.name:lower() == name:lower() then
				return i
			end
		end
		return 0
	else
		return 0
	end
end

if G.TheNet:GetServerGameMode() == gamemodename then
	local VoteUtil = G.require("voteutil")
	G.require("builtinusercommands")
	G.require("usercommands").GetCommandFromName("regenerate").vote = false
	G.require("usercommands").GetCommandFromName("rollback").vote = false

	G.AddUserCommand("setteam", {
		prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.SETTEAM.NAME, 
		desc = DEATHMATCH_STRINGS.USERCOMMANDS.SETTEAM.DESC, 
		permission = G.COMMAND_PERMISSION.USER,
		slash = true,
		usermenu = false,
		servermenu = false,
		params = {"team"},
		vote = false,
		serverfn = function(params, caller)
			local teamnum = G.tonumber(params.team)
			if G.TheWorld.components.deathmatch_manager.allow_teamswitch_user then
				if teamnum ~= nil and teamnum >= 0 and teamnum <= #G.DEATHMATCH_TEAMS then
					caller.components.teamer:SetTeam(teamnum)
				else
					caller.components.teamer:SetTeam(FindKeyFromName(params.team))
				end
			end
		end,
	})

	G.AddUserCommand("spectate", {
		prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.SPECTATE.NAME, 
		desc = DEATHMATCH_STRINGS.USERCOMMANDS.SPECTATE.DESC, 
		permission = G.COMMAND_PERMISSION.USER,
		slash = true,
		usermenu = false,
		servermenu = false,
		params = {},
		vote = false,
		serverfn = function(params, caller)
			local self = G.TheWorld.components.deathmatch_manager
			self:ToggleSpectator(caller)
		end,
	})
	
	G.AddUserCommand("afk", {
		prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.AFK.NAME, 
		desc = DEATHMATCH_STRINGS.USERCOMMANDS.AFK.DESC, 
		permission = G.COMMAND_PERMISSION.USER,
		slash = true,
		usermenu = false,
		servermenu = false,
		params = {},
		vote = false,
		serverfn = function(params, caller)
			if caller:HasTag("spectator_perma") then 
				caller:RemoveTag("spectator_perma") 
				G.TheNet:Announce(caller:GetDisplayName().." is no longer AFK.", caller.entity, nil, "afk_stop")
			else 
				caller:AddTag("spectator_perma") 
				G.TheNet:Announce(caller:GetDisplayName().." is now AFK.", caller.entity, nil, "afk_start")
			end
		end,
	})

	G.AddUserCommand("setstate", {
		aliases = {"setcycle", "setlook"},
		prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.SETSTATE.NAME, 
		desc = DEATHMATCH_STRINGS.USERCOMMANDS.SETSTATE.DESC, 
		permission = G.COMMAND_PERMISSION.USER,
		slash = true,
		usermenu = false,
		servermenu = false,
		params = {"num"},
		vote = false,
		serverfn = function(params, caller)
			if caller.ChangeCosmeticState and tonumber(params.num) then
				caller:ChangeCosmeticState(math.floor(tonumber(params.num)))
			end
		end,
	})

	G.AddUserCommand("deathmatch", {
		prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.DEATHMATCH.NAME, 
		aliases = {"dm"},
		desc = DEATHMATCH_STRINGS.USERCOMMANDS.DEATHMATCH.DESC, 
		permission = G.COMMAND_PERMISSION.USER,
		slash = true,
		usermenu = false,
		servermenu = false,
		params = {"action"},
		vote = false,
		serverfn = function(params, caller)
			local dm = G.TheWorld.components.deathmatch_manager
			if params.action == "start" then
				if G.TheWorld.net.components.worldvoter:IsVoteActive() then
					G.TheNet:Announce(DEATHMATCH_STRINGS.CHATMESSAGES.STARTMATCH_VOTEACTIVE)
				elseif not (dm.doingreset or dm.matchinprogress or dm.matchstarting) then
					dm:ResetDeathmatch()
				end
			elseif params.action == "stop" or "end" then
				if dm.allow_endmatch_user and dm.matchinprogress then
					dm:Vote("endmatch", caller)
				end
			end
		end,
	})

G.AddUserCommand("despawn", {
    prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.DESPAWN.NAME, 
	aliases = {},
    desc = DEATHMATCH_STRINGS.USERCOMMANDS.DESPAWN.DESC, 
    permission = G.COMMAND_PERMISSION.USER,
    slash = true,
    usermenu = false,
    servermenu = false,
    params = {},
    vote = false,
    serverfn = function(params, caller)
		local dm = G.TheWorld.components.deathmatch_manager --caller:HasTag("spectator") or (not dm.matchstarting and not dm:IsPlayerInMatch(caller)) or not (dm.doingreset or dm.matchinprogress
		if (caller and caller.IsValid and caller:IsValid()) and 
		(caller:HasTag("spectator") or (not dm:isPlayerInMatch(caller)) or (not dm.matchstarting)) then
			G.TheWorld.despawnplayerdata[caller.userid] = caller.SaveForReroll ~= nil and caller:SaveForReroll() or nil
			G.TheWorld:PushEvent("ms_playerdespawnanddelete", caller)
		end
    end,
	localfn = function(params, caller)
		local status = caller.HUD.controls.deathmatch_status
		if status ~= nil then
			if status.data.match_status == 1 then
				G.TheNet:SystemMessage(DEATHMATCH_STRINGS.CHATMESSAGES.DESPAWN_MIDMATCH)
			elseif status.data.match_status == 2 then
				G.TheNet:SystemMessage(DEATHMATCH_STRINGS.CHATMESSAGES.DESPAWN_STARTING)
			end
		end
	end
})

AddUserCommand("setteammode", {
    prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.SETTEAMMODE.NAME, 
    desc = DEATHMATCH_STRINGS.USERCOMMANDS.SETTEAMMODE.DESC, 
    permission = G.COMMAND_PERMISSION.ADMIN,
    confirm = false,
    slash = true,
    usermenu = false,
    servermenu = true,
    params = {"teammode"},
    vote = true,
    votetimeout = 30,
    voteminstartage = 0,
    voteminpasscount = 1,
    votecountvisible = true,
    voteallownotvoted = true,
    voteoptions = {"Free For All", "Red vs. Blue", "2-Player Teams", "Custom"}, 
    votetitlefmt = DEATHMATCH_STRINGS.USERCOMMANDS.SETTEAMMODE.VOTETITLE, 
    votenamefmt = DEATHMATCH_STRINGS.USERCOMMANDS.SETTEAMMODE.VOTENAME, 
    votepassedfmt = "Vote complete!", 
    votecanstartfn = VoteUtil.DefaultCanStartVote,
    voteresultfn = VoteUtil.DefaultMajorityVote,
    serverfn = function(params, caller)
		local dm = G.TheWorld.components.deathmatch_manager
		local mode = G.tonumber(params.teammode)
		if mode ~= nil and type(mode) == "number" and (mode >= 0 and mode <= 3) then
			dm:SetGamemode(math.floor(mode))
			return
		end
		if params.voteselection ~= nil then
			if params.voteselection == 4 then
				dm:SetGamemode(0)
			else
				dm:SetGamemode(params.voteselection)
			end
		end
    end,
})

AddUserCommand("setarena", {
	aliases = {"setmap"},
    prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.SETARENA.NAME, 
    desc = DEATHMATCH_STRINGS.USERCOMMANDS.SETARENA.DESC, 
    permission = G.COMMAND_PERMISSION.ADMIN,
    confirm = false,
    slash = true,
    usermenu = false,
    servermenu = true,
    params = {"arena"},
    vote = true,
    votetimeout = 15,
    voteminstartage = 0,
    voteminpasscount = 1,
    votecountvisible = true,
    voteallownotvoted = true,
    voteoptions = ARENAS.NAMES,
    votetitlefmt = DEATHMATCH_STRINGS.USERCOMMANDS.SETARENA.VOTETITLE, 
    votenamefmt = DEATHMATCH_STRINGS.USERCOMMANDS.SETARENA.VOTENAME, 
    votepassedfmt = "Vote complete!", 
    votecanstartfn = VoteUtil.DefaultCanStartVote,
    voteresultfn = VoteUtil.DefaultMajorityVote,
    serverfn = function(params, caller)
		local arenas = ARENAS.VOTEOPTIONS
		local dm = G.TheWorld.components.deathmatch_manager
		local mode = params.arena
		if mode ~= nil and arenas[mode] ~= nil then
			dm:SetNextArena(arenas[mode])
		end
		if params.voteselection ~= nil then
			dm:SetNextArena(arenas[params.voteselection])
		end
    end,
})

end
-------------------------------------------------------------------------------------------

AddAction("MAKEEXPLOSIVEBALLOON", "Inflate", function(act)
	if act.doer and act.invobject and act.invobject.components.explosiveballoonmaker and
	act.invobject.components.explosiveballoonmaker.enabled:value() then
		if G.TheWorld.ismastersim then
			act.invobject.components.explosiveballoonmaker:MakeBalloon(act.doer, act.doer:GetPosition():Get())
		end
		return true
	end
end)

AddComponentAction("INVENTORY", "explosiveballoonmaker", function(inst, doer, actions)
	if inst.components.explosiveballoonmaker.enabled:value() then
		table.insert(actions, G.ACTIONS.MAKEEXPLOSIVEBALLOON)
	end
end)

AddComponentAction("POINT", "aoespell", function(inst, doer, pos, actions, right) --Hornet: Can't use specials on boats, Lets fix that!
	if right and
		(   inst.components.aoetargeting == nil or inst.components.aoetargeting:IsEnabled()
		) and
		(   inst.components.aoetargeting ~= nil and inst.components.aoetargeting.alwaysvalid or
			(G.TheWorld.Map:IsPassableAtPoint(pos.x, pos.y, pos.z, false, false) and not G.TheWorld.Map:IsGroundTargetBlocked(pos))
		) then
		table.insert(actions, G.ACTIONS.CASTAOE)
	end
end)

local stategraph_postinits = G.require("stategraph_postinits")
for stategraph, states in pairs(stategraph_postinits) do
	for _, state in pairs(states) do
		AddStategraphState(stategraph, state)
	end
end
for k, v in pairs({ "wilson", "wilson_client" }) do
	AddStategraphActionHandler(v, G.ActionHandler(G.ACTIONS.MAKEEXPLOSIVEBALLOON, "makeballoon"))
	AddStategraphPostInit(v, function(self)
		local deststate_castaoe_old = self.actionhandlers[G.ACTIONS.CASTAOE].deststate
		self.actionhandlers[G.ACTIONS.CASTAOE].deststate = function(inst, act)
			if act.invobject ~= nil and act.invobject:HasTag("instantaoe") then
				inst:PerformPreviewBufferedAction()
				if inst.bufferedaction ~= nil then
					inst.bufferedaction:Do()
				--print(inst.bufferedaction)
				end
				return nil
			end
			return act.invobject ~= nil and 
				act.invobject:HasTag("focusattack") and "focusattack" or
				act.invobject:HasTag("combat_jump") and "combat_jump_start" or
				act.invobject:HasTag("shelluse") and "shelluse" or
				deststate_castaoe_old(inst, act)
		end
		--local deststate_revivecorpse_old = self.actionhandlers[G.ACTIONS.REVIVE_CORPSE].deststate
		if v == "wilson" then
			self.actionhandlers[G.ACTIONS.REVIVE_CORPSE].deststate = function(inst, act)
				return "revivecorpse_deathmatch"
			end
		end
		-- temp
		local deststate_makeballoon_old = self.actionhandlers[G.ACTIONS.MAKEBALLOON].deststate
		self.actionhandlers[G.ACTIONS.MAKEBALLOON].deststate = function(inst, act)
			return "doshortaction"
		end
	end)
end

--[[local pikcupact_fn_old = G.ACTIONS.PICKUP.fn
G.ACTIONS.PICKUP.fn = function(act, ...)
	if act.doer and act.doer:HasTag("spectator") then
		return false
	else
		return pikcupact_fn_old(act, ...)
	end
end]]
local spectator_actions = {LOOKAT = true, TALKTO = true, WALKTO = true}
for k, v in pairs(G.ACTIONS) do
	if not spectator_actions[k] then
		local actfn_old = v.fn
		v.fn = function(act, ...)
			if act and act.doer and act.doer:HasTag("spectator") then
				return false
			end
			return actfn_old(act, ...)
		end
	end
end

local lookatfn_old = G.ACTIONS.LOOKAT.fn
G.ACTIONS.LOOKAT.fn = function(act, ...)
	local worked = lookatfn_old(act, ...)
	if worked then
		local targ = act.target or act.invobject
		if targ:HasTag("event_inspect") then
			targ:PushEvent("inspected", act.doer)
		end
	end
	return worked
end

-----------------------------------------------------------------------------

AddModRPCHandler(modname, "deathmatch_currentreticule_change", function(inst, slot)
	if inst == nil or slot == nil then return end
	if inst.components.playercontroller then
		inst.components.playercontroller.reticuleitemslot = slot
	end
end)

AddModRPCHandler(modname, "locationrequest", function(inst, x, z)
	local pos = G.Vector3(x, 0, z)
	inst._spintargetpos = pos
end)

G.TheInput:AddKeyDownHandler(G.KEY_R, function()
	if G.TheFrontEnd and G.TheFrontEnd:GetActiveScreen().name == "HUD" then
		if G.ThePlayer and G.ThePlayer.components.playercontroller then
			if G.ThePlayer.components.playercontroller.reticule == nil then
				G.ThePlayer.components.playercontroller:TryAOETargeting("head")
			else
				G.ThePlayer.components.playercontroller:CancelAOETargeting()
			end
		end
	end
end)

G.TheInput:AddKeyDownHandler(G.KEY_Z, function()
	if G.TheFrontEnd and G.TheFrontEnd:GetActiveScreen().name == "HUD" then
		if G.ThePlayer and G.ThePlayer.components.playercontroller then
			if G.ThePlayer.components.playercontroller.reticule == nil then
				G.ThePlayer.components.playercontroller:TryAOETargeting("body")
			else
				G.ThePlayer.components.playercontroller:CancelAOETargeting()
			end
		end
	end
end)
