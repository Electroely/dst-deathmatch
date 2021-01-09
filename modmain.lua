local G = GLOBAL
local tonumber = G.tonumber
local debug = G.debug
local gamemodename = "deathmatch" 
G.DEATHMATCH_STRINGS = G.require("deathmatch_strings")
local DEATHMATCH_STRINGS = G.DEATHMATCH_STRINGS
local DEATHMATCH_POPUPS = DEATHMATCH_STRINGS.POPUPS

--mod import extra files
modimport("scripts/deathmatch_teamchat")
modimport("scripts/deathmatch_componentpostinits")
modimport("scripts/deathmatch_prefabpostinits")
modimport("scripts/deathmatch_usercommands")
--modimport("scripts/deathmatch_tipsmanager")

AddPrefabPostInit("player_classified", function(inst)
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
{name="Green", colour={0.25,1,0.25,1}},
{name="Orange", colour={1,0.5,0,1}},
{name="Cyan", colour={0.5,1,1,1}},
{name="Pink", colour={1,0.5,1,1}},
{name="Black", colour={97/255, 80/255, 132/255, 1}},
}

PrefabFiles = {
	"lavaarena", --to load the assets
	--quagmire",
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
	"deathmatch_reviverheart",
	"deathmatch_bugnet",
	"powerflier",
	"powerup_flower",
	"shadowweapons",
}
Assets = {
	Asset("ANIM", "anim/hat_snortoise.zip"),
	Asset("ANIM", "anim/partyhealth_extras.zip"),
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

local function OnKillOther(inst, data)
	G.TheWorld.net:PushEvent("deathmatch_kill", { inst=inst, data=data })
end

local function OnDeath(inst, data)
	--G.TheWorld.net:PushEvent("deathmatch_death", { inst=inst, data=data })
	G.TheWorld:PushEvent("playerdied")
end

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
			inst.teamchoice = 0 --for rvb team preference
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
					ind:Push(inst, data.target, math.floor(data.damage), data.stimuli~=nil)
				end
			end)
			local health = 150
			inst.components.health:SetMaxHealth(health)
			inst.components.combat.hitrange = 2.5
			inst.components.combat.playerdamagepercent = 1
			
			inst:AddComponent("corpsereviver") -- from the forge code
			function inst.components.corpsereviver:GetReviverSpeedMult(target)
				return G.TheWorld.components.deathmatch_manager:GetPlayerRevivalTimeMult(self.inst)
			end
			inst.components.revivablecorpse:SetReviveHealthPercent(1)
			function inst.components.corpsereviver:GetAdditionalReviveHealthPercent()
				local val = G.TheWorld.components.deathmatch_manager:GetPlayerRevivalHealthPct(self.inst)-1
				print(val)
				return G.TheWorld.components.deathmatch_manager:GetPlayerRevivalHealthPct(self.inst)-1
			end
			inst:ListenForEvent("respawnfromcorpse", function(inst, data)
				if data and data.source then
					G.TheWorld.components.deathmatch_manager:OnPlayerRevived(inst, data.source)
				end
			end)
			--remove heart
			inst:ListenForEvent("ms_respawnedfromghost", function(inst, data)
				if data and data.corpse and data.reviver ~= nil and data.reviver:HasTag("player") then
					local item = data.reviver.components.inventory:GetEquippedItem(G.EQUIPSLOTS.HANDS)
					if item and item.prefab == "deathmatch_reviverheart" then
						item:Remove() --Consume Heart
					end
				end
			end)
		end
		---------- character perks
		G.require("player_postinits_deathmatch")(inst, inst.prefab)
		inst.starting_inventory = {}
		---------- debug
		function inst:Respawn()
			self:PushEvent("respawnfromcorpse")
		end
	end
end)

---------------------------------------------------------------------
local Text = G.require("widgets/text")
local Deathmatch_LobbyTimer = G.require("widgets/deathmatch_lobbytimer")
local Deathmatch_InfoPopup = G.require("widgets/deathmatch_infopopup")

AddClassPostConstruct("widgets/controls", function(self, owner)
	if G.TheNet:GetServerGameMode() == "deathmatch" then
		self.deathmatch_playerlist = self.topleft_root:AddChild(G.require("widgets/deathmatch_playerlist")(owner))
		self.deathmatch_playerlist:SetPosition(150, 0-(G.RESOLUTION_Y/2)-25)
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
		
		--self.deathmatch_infopopup = self.bottom_root:AddChild(Deathmatch_InfoPopup(owner))
		--self.deathmatch_infopopup:SetPosition(0, 250)
		--owner.ShowPopup = function()
			--self.deathmatch_infopopup:NewInfo()
		--end
		
		self.clock:Hide()
		
		self.status.stomach:Hide()
		self.status.stomach.Show = function() end
		self.status.brain:Hide()
		self.status.brain.Show = function() end -- im gay
		
		if self.status.inspirationbadge ~= nil then
			self.status.inspirationbadge:Hide()
		end
		
		self.inst:DoTaskInTime(0, function() --Hide Combined Status elements
			if self.seasonclock ~= nil then
				self.seasonclock:Hide()
			end
			
			if self.status.temperature ~= nil then
				self.status.temperature:Hide()
			end
			
			if self.status.tempbadge ~= nil then
				self.status.tempbadge:Hide()
			end
		end)
	end
end)

AddClassPostConstruct("screens/redux/lobbyscreen", function(self)
	self.deathmatch_timer = self.panel_root:AddChild(Deathmatch_LobbyTimer())
	self.deathmatch_timer:SetPosition(-160, 340)
end)
local CHARACTERS_EXTRAS = {
	warly = true,
	walter = true,
	wormwood = true,
	wortox = true,
	wurt = true,
}
AddClassPostConstruct("widgets/teammatehealthbadge", function(self)
	local SetPlayer_old = self.SetPlayer
	self.SetPlayer = function(self, player, ...)
		local rtn = {SetPlayer_old(self, player, ...)}
		if player and CHARACTERS_EXTRAS[player.prefab] then
			self.anim:GetAnimState():OverrideSymbol("character_wilson", "partyhealth_extras", "character_"..player.prefab)
		end
		return G.unpack(rtn)
	end
end)
---------------------------------------------------------------------
local _name = GLOBAL.STRINGS.NAMES

_name.PICKUP_LIGHTDAMAGING = "Damage Boost\n+50% Damage Dealt\nLasts 10 Seconds"
_name.PICKUP_LIGHTDEFENSE = "Defense Boost\n-50% Damage Taken\nLasts 15 Seconds"
_name.PICKUP_LIGHTSPEED = "Speed Boost\n+50% Movement Speed\nLasts 10 Seconds"
_name.PICKUP_LIGHTHEALING = "Health Restoration\nRestore 10-20 Health"
_name.PICKUP_COOLDOWN = "Instant Refresh\nResets cooldown of all weapons in inventory"

_name.POWERFLIER = "Powerbug"
_name.POWERUP_FLOWER = "Power Flower"

_name.DEATHMATCH_INFOSIGN = "Info Sign"
_name.DUMMYTARGET = "Target Dummy"
_name.DEATHMATCH_REVIVERHEART = "Telltale Heart"

local _tuning = GLOBAL.TUNING
_tuning.REVIVE_CORPSE_ACTION_TIME = 2 --in deathmatch, revivals start out fast but get slower
----------------------------------------------------------------------

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

local PairAction = AddAction("DEATHMATCH_PAIRWITH", "Team up with", function(act)
	if act.doer and act.target then
		if act.doer:HasTag("spectator") or act.target:HasTag("spectator") then return false end
		if act.doer.components.teamer:IsTeamedWith(act.target) then
			G.TheWorld.components.deathmatch_manager:DisbandPairTeam(act.doer)
			return true
		end
		G.TheWorld.components.deathmatch_manager:RequestPairing(act.doer, act.target)
		return true
	end
end)
PairAction.instant = true
PairAction.rmb = true
PairAction.strfn = function(act)
	if act.doer and act.target and act.doer.components.teamer:IsTeamedWith(act.target) then
		return "DISBAND"
	end
	return "GENERIC"
end
G.STRINGS.ACTIONS.DEATHMATCH_PAIRWITH = DEATHMATCH_STRINGS.PAIRWITH_ACTION

AddComponentAction("SCENE", "teamer", function(inst, doer, actions, right)
	--if right then
		if inst:HasTag("spectator") or doer:HasTag("spectator") or inst == doer then return end
		local mode = G.TheWorld.net.deathmatch_netvars.globalvars.matchmode:value() --3: 2pt
		local matchstatus = G.TheWorld.net.deathmatch_netvars.globalvars.matchstatus:value()
		if mode == 3 and (matchstatus == 0 or matchstatus == 2) then
			table.insert(actions, G.ACTIONS.DEATHMATCH_PAIRWITH)
		end
	--end
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
local function checknumber(v)
	return type(v) == "number"
end
AddModRPCHandler(modname, "deathmatch_currentreticule_change", function(inst, slot)
	if inst == nil or slot == nil then return end
	if inst.components.playercontroller then
		local valid = false
		for k, v in pairs(G.EQUIPSLOTS) do
			if slot == v then
				valid = true
				break
			end
		end
		if not valid then return end
		inst.components.playercontroller.reticuleitemslot = slot
	end
end)

AddModRPCHandler(modname, "locationrequest", function(inst, x, z)
	if not (checknumber(x) and checknumber(z)) then
		return
	end
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
