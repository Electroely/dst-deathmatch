local G = GLOBAL
local tonumber = G.tonumber
local debug = G.debug
local gamemodename = "deathmatch" 
G.DEATHMATCH_STRINGS = G.require("deathmatch_strings")
G.DEATHMATCH_TUNING = require("deathmatch_tuning")
local DEATHMATCH_STRINGS = G.DEATHMATCH_STRINGS
local DEATHMATCH_POPUPS = DEATHMATCH_STRINGS.POPUPS

local arenas = require("prefabs/arena_defs")

local UserCommands = require("usercommands")

require("deathmatch_debug")

--mod import extra files
modimport("scripts/deathmatch_teamchat")
modimport("scripts/deathmatch_componentpostinits")
modimport("scripts/deathmatch_prefabpostinits")
modimport("scripts/deathmatch_usercommands")
modimport("scripts/deathmatch_skilltree")
--modimport("scripts/deathmatch_tipsmanager")

AddPrefabPostInit("player_classified", function(inst)
	inst._arenaeffects = G.net_string(inst.GUID, "deathmatch.arenaeffect", "arenachanged")
	inst:ListenForEvent("arenachanged", function(inst, data)
		G.TheWorld:PushEvent("applyarenaeffects", inst._arenaeffects:value())
	end)
	inst._choosinggear = G.net_bool(inst.GUID, "deathmatch.choosinggear", "choosinggearchanged")
	inst._arenachoice = G.net_smallbyte(inst.GUID, "deathmatch.arenachoice", "arenachoicedirty")
	inst._arenachoice:set(1) --default atrium
	inst._modechoice = G.net_tinybyte(inst.GUID, "deathmatch.modechoice", "modechoicedirty")
	inst._modechoice:set(1) --default ffa
	if not G.TheWorld.ismastersim then
		inst:ListenForEvent("choosinggearchanged", function(inst, data)
			if inst._parent.HUD and inst._choosinggear:value() then
				inst._parent.HUD.controls.deathmatch_chooseyourgear:Show()
			elseif inst._parent.HUD then
				inst._parent.HUD.controls.deathmatch_chooseyourgear:Hide()
			end
		end)
		inst:ListenForEvent("arenachoicedirty", function(inst, data)
			inst._parent.arenachoice = arenas.IDX[inst._arenachoice:value()]
			inst._parent:PushEvent("arenachoicedirty", inst._arenachoice:value())
		end)
		inst:ListenForEvent("modechoicedirty", function(inst, data)
			inst._parent.modechoice = arenas.IDX[inst._modechoice:value()]
			inst._parent:PushEvent("modechoicedirty", inst._modechoice:value())
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
	"invslotdummy",
	"firebomb_firecircle",
	"deathmatch_healingstaffbuff",
	
	"maxwelllight",
	"maxwelllight_flame",
}
Assets = {
	Asset("ANIM", "anim/hat_snortoise.zip"),
	Asset("ANIM", "anim/partyhealth_extras.zip"),
	
	Asset("IMAGE", "images/changeTeamPole.tex"),
	Asset("ATLAS", "images/changeTeamPole.xml"),
	
	Asset("IMAGE", "images/changeTeamFlag.tex"),
	Asset("ATLAS", "images/changeTeamFlag.xml"),
	
	Asset("ATLAS", "images/deathmatch_skilltree_bg.xml"),
	Asset("IMAGE", "images/deathmatch_skilltree_bg.tex"),
	Asset("ATLAS", "images/deathmatch_skilltree_icons.xml"),
	Asset("IMAGE", "images/deathmatch_skilltree_icons.tex"),
	
	Asset("IMAGE", "images/matchcontrolsbutton_bg.tex"),
	Asset("ATLAS", "images/matchcontrolsbutton_bg.xml"),
	Asset("IMAGE", "images/matchcontrolsbutton_frame.tex"),
	Asset("ATLAS", "images/matchcontrolsbutton_frame.xml"),

	Asset("IMAGE", "images/matchcontrolsbutton_goback.tex"),
	Asset("ATLAS", "images/matchcontrolsbutton_goback.xml"),
	Asset("IMAGE", "images/matchcontrolsbutton_startmatch.tex"),
	Asset("ATLAS", "images/matchcontrolsbutton_startmatch.xml"),
	Asset("IMAGE", "images/matchcontrols_infobutton.tex"),
	Asset("ATLAS", "images/matchcontrols_infobutton.xml"),

	Asset("IMAGE", "images/map_icon_atrium.tex"),
	Asset("ATLAS", "images/map_icon_atrium.xml"),
	Asset("IMAGE", "images/map_icon_desert.tex"),
	Asset("ATLAS", "images/map_icon_desert.xml"),
	Asset("IMAGE", "images/map_icon_pigvillage.tex"),
	Asset("ATLAS", "images/map_icon_pigvillage.xml"),
	Asset("IMAGE", "images/map_icon_random.tex"),
	Asset("ATLAS", "images/map_icon_random.xml"),
	
	Asset("IMAGE", "images/modeselect_ffa.tex"),
	Asset("ATLAS", "images/modeselect_ffa.xml"),
	Asset("IMAGE", "images/modeselect_rvb.tex"),
	Asset("ATLAS", "images/modeselect_rvb.xml"),
	Asset("IMAGE", "images/modeselect_2pt.tex"),
	Asset("ATLAS", "images/modeselect_2pt.xml"),
	
	Asset("IMAGE", "images/teamselect_pole.tex"),
	Asset("ATLAS", "images/teamselect_pole.xml"),
	Asset("IMAGE", "images/teamselect_flag.tex"),
	Asset("ATLAS", "images/teamselect_flag.xml"),
	
	Asset("IMAGE", "images/deathmatch_inventorybar.tex"),
	Asset("ATLAS", "images/deathmatch_inventorybar.xml"),

	Asset("ATLAS", "images/inventoryimages/teleporterhat.xml"),
	Asset("IMAGE", "images/inventoryimages/teleporterhat.tex"),
	
	Asset("SHADER", "shaders/characterhead.ksh"),
}

RegisterInventoryItemAtlas("images/inventoryimages/teleporterhat.xml","teleporterhat")

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
	inst.attackers = {}
	if not G.TheWorld.ismastersim then
		inst:ListenForEvent("net_locationrequest", function(inst)
			if inst == G.ThePlayer then
				local x, y, z = (G.TheInput:GetWorldPosition() - inst:GetPosition()):Get()
				SendModRPCToServer(GetModRPC(modname, "locationrequest"), x, z)
			end
		end)
		inst:ListenForEvent("changearenachoice", function(inst, data)
			SendModRPCToServer(GetModRPC(modname, "deathmatch_arenachoice"), data)
		end)
		inst:ListenForEvent("changemodechoice", function(inst, data)
			SendModRPCToServer(GetModRPC(modname, "deathmatch_modechoice"), data)
		end)
	end
	if G.TheNet:GetServerGameMode() == "deathmatch" then
		---------- extra code
		G.require("deathmatch_player_functions")(inst)
		G.require("player_postinits_deathmatch")(inst, inst.prefab)
		---------------------
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
				return 0--G.TheWorld.components.deathmatch_manager:GetPlayerRevivalHealthPct(self.inst)-1
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
			inst:UpdateRevivalHealth()
		end
		
		inst.starting_inventory = {}
		---------- debug
		function inst:Respawn()
			self:PushEvent("respawnfromcorpse")
		end
	end
end)

---------------------------------------------------------------------
local Text = G.require("widgets/text")
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local UIAnimButton = require "widgets/uianimbutton"
local Deathmatch_LobbyTimer = G.require("widgets/deathmatch_lobbytimer")
local Deathmatch_InfoPopup = G.require("widgets/deathmatch_infopopup")
local Deathmatch_Menu = require("screens/deathmatch_menuscreen")
local DeathmatchMenu = require "widgets/deathmatch_menu"
local StatusDisplays = require "widgets/statusdisplays"

local Deathmatch_Inventory = require("widgets/deathmatch_inventorybar")

AddClassPostConstruct("widgets/controls", function(self, owner)
	if G.TheNet:GetServerGameMode() == "deathmatch" then
		self.deathmatch_status = self.top_root:AddChild(G.require("widgets/deathmatch_status")(owner))
		self.deathmatch_status:SetPosition(0,-20)
		self.deathmatch_status.inst:DoPeriodicTask(3, function() self.deathmatch_status:Refresh() end)
		
		self.deathmatch_spectatorspinner = self.bottom_root:AddChild(G.require("widgets/deathmatch_spectatorspinner")(owner))
		self.deathmatch_spectatorspinner:SetPosition(0,150)
		if owner.components.deathmatch_spectatorcorpse and owner.components.deathmatch_spectatorcorpse.active then
			self.deathmatch_spectatorspinner:Show()
		else
			self.deathmatch_spectatorspinner:Hide()
		end

		self.deathmatch_matchcontrols = self.topright_root:AddChild(require("widgets/deathmatch_matchcontrols")(owner))
		self.deathmatch_matchcontrols:SetPosition(-150, -70)
		
		self.deathmatch_chooseyourgear = self.bottom_root:AddChild(G.require("widgets/deathmatch_chooseyourgear")(owner))
		self.deathmatch_chooseyourgear:SetPosition(0,300)
		self.deathmatch_chooseyourgear:Hide()

		self.deathmatch_playerlist = self.bottom_root:AddChild(require("widgets/deathmatch_enemylist")(owner))
		self.deathmatch_playerlist:SetPosition(-220, 70)

		--self.deathmatch_infopopup = self.bottom_root:AddChild(Deathmatch_InfoPopup(owner))
		--self.deathmatch_infopopup:SetPosition(0, 250)
		--owner.ShowPopup = function()
			--self.deathmatch_infopopup:NewInfo()
		--end
		
		self.clock:Hide()
		
		self.inv:Kill()
		self.inv = self.bottom_root:AddChild(Deathmatch_Inventory(self.owner))
		self.inv.autoanchor = self.worldresettimer
		
		self.status:Kill()
		self.status = self.bottom_root:AddChild(StatusDisplays(self.owner))
		self.status:SetPosition(175,50)
		self.status:SetScale(1.3,1.3,1.3)
		
		self.status.stomach:Hide()
		self.status.stomach.Show = function() end
		self.status.brain:Hide()
		self.status.brain.Show = function() end
		
		if self.status.inspirationbadge ~= nil then
			self.status.inspirationbadge:Hide()
			self.status.inspirationbadge.Show = function() end
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

local function OnStartDM()
	local status = G.TheWorld.net.deathmatch_netvars.globalvars.matchstatus:value()
	if status ~= nil then
		if status == 1 then
			UserCommands.RunTextUserCommand("dm stop", G.ThePlayer, false)
		else
			UserCommands.RunTextUserCommand("dm start", G.ThePlayer, false)
		end
	end
end

local function OnDespawnDM()
	UserCommands.RunTextUserCommand("despawn", G.ThePlayer, false)
end	

local function OnInfoScreen()
	if G.TheFrontEnd:GetActiveScreen() == "Deathmatch_Menu" then
		G.TheFrontEnd:PopScreen()
	else
		G.TheFrontEnd:PushScreen(DeathmatchMenu(self))
	end
end

AddClassPostConstruct("widgets/mapcontrols", function(self)
	self.startDMBtn = self:AddChild(ImageButton(GLOBAL.HUD_ATLAS, "tab_fight.tex", nil, nil, nil, nil, {1,1}, {0,0}))
    self.startDMBtn:SetOnClick(OnStartDM)
	self.startDMBtn:SetPosition(-10, 20)
	self.startDMBtn:SetScale(0.8)
	
	self.changeTeam = self:AddChild(ImageButton("images/changeTeamFlag.xml", "changeTeamFlag.tex", nil, nil, nil, nil, {1,1}, {0,0}))
	self.changeTeam:SetScale(0.15)
	self.changeTeam:SetPosition(-40, 80)
	
	self.changeTeam.changeTeamPole = self.changeTeam:AddChild(Image("images/changeTeamPole.xml", "changeTeamPole.tex"))
	
	local _OnGainFocus = self.changeTeam.OnGainFocus
	function self.changeTeam:OnGainFocus(...)
		_OnGainFocus(self, ...)
		
		if self.image_focus == self.image_normal and self.scale_on_focus and self.focus_scale and self.changeTeamPole ~= nil then
			self.changeTeamPole:SetScale(self.focus_scale[1], self.focus_scale[2], self.focus_scale[3])
		end
	end
	
	local _OnLoseFocus = self.changeTeam.OnLoseFocus
	function self.changeTeam:OnLoseFocus(...)
		_OnLoseFocus(self, ...)
		
		if self.image_focus == self.image_normal and self.scale_on_focus and self.normal_scale and self.changeTeamPole ~= nil then
			self.changeTeamPole:SetScale(self.normal_scale[1], self.normal_scale[2], self.normal_scale[3])
		end
	end
	
	self.infoScreen = self:AddChild(ImageButton("images/button_icons.xml", "info.tex", nil, nil, nil, nil, {1,1}, {0,0}))
	self.infoScreen:SetOnClick(OnInfoScreen)
	self.infoScreen:SetScale(0.15)
	self.infoScreen:SetPosition(0, 83)
	
	self.despawnBtn = self:AddChild(ImageButton("minimap/minimap_data.xml", "portal_dst.png", nil, nil, nil, nil, {1,1}, {0,0}))
	self.despawnBtn:SetOnClick(OnDespawnDM)
	self.despawnBtn:SetScale(0.5)
	self.despawnBtn:SetPosition(40, 82)
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

_tuning.STARFISH_TRAP_NOTDAY_RESET.BASE = 15
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

-- AddComponentAction("POINT", "aoespell", function(inst, doer, pos, actions, right) --Hornet: Can't use specials on boats, Lets fix that!
	-- if right and
		-- (   inst.components.aoetargeting == nil or inst.components.aoetargeting:IsEnabled()
		-- ) and
		-- (   inst.components.aoetargeting ~= nil and inst.components.aoetargeting.alwaysvalid or
			-- (G.TheWorld.Map:IsPassableAtPoint(pos.x, pos.y, pos.z, false, false) and not G.TheWorld.Map:IsGroundTargetBlocked(pos))
		-- ) then
		-- table.insert(actions, G.ACTIONS.CASTAOE)
	-- end
-- end)

AddComponentAction("USEITEM", "complexprojectile", function(inst, doer, target, actions, right)
	if target and target:HasTag("player") and target:HasTag("corpse") then
		table.insert(actions, G.ACTIONS.TOSS)
	end 
end)
G.ACTIONS.TOSS.priority = 5
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
		
		local RESPAWN_INVINCIBILITY_TIME = 2
		if v == "wilson" then 
			local corpse_rebirth_onexit = self.states.corpse_rebirth.onexit
			self.states.corpse_rebirth.onexit = function(inst, ...)
				--do respawn invincibility
				inst.components.combat.externaldamagetakenmultipliers:SetModifier("respawn", 0)
				inst:DoTaskInTime(RESPAWN_INVINCIBILITY_TIME, function(inst)
					inst.components.combat.externaldamagetakenmultipliers:SetModifier("respawn", 1)
				end)
				return corpse_rebirth_onexit(inst, ...)
			end
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

local function checkarenaid(v)
	return type(v) == "number" and (v == 0 or arenas.VALID_ARENA_LOOKUP[v])
end
local function checkmodeid(v)
	return type(v) == "number" and (v > 0 and v <= 3)
end
AddModRPCHandler(modname, "deathmatch_arenachoice", function(inst, arenaid)
	print("got arena choice",inst,arenaid,checkarenaid(arenaid))
	if (inst == nil or not checkarenaid(arenaid)) then return end
	inst.player_classified._arenachoice:set(arenaid)
	inst.arenachoice = arenas.IDX[arenaid]
	GLOBAL.TheWorld:PushEvent("ms_arenavote")
end)
AddModRPCHandler(modname, "deathmatch_modechoice", function(inst, modeid)
	print("got mode choice",inst,modeid,checkmodeid(modeid))
	if (inst == nil or not checkmodeid(modeid)) then return end
	inst.player_classified._modechoice:set(modeid)
	inst.modechoice = modeid
	GLOBAL.TheWorld:PushEvent("ms_modevote")
end)

-----------------------------------------------------------------------------
local function checknumber(v)
	return type(v) == "number" and v < 60 and v > -60
end
-- AddModRPCHandler(modname, "deathmatch_currentreticule_change", function(inst, slot)
	-- if inst == nil or slot == nil then return end
	-- if inst.components.playercontroller then
		-- local valid = false
		-- for k, v in pairs(G.EQUIPSLOTS) do
			-- if slot == v then
				-- valid = true
				-- break
			-- end
		-- end
		-- if not valid then return end
		-- inst.components.playercontroller.reticuleitemslot = slot
	-- end
-- end)

-- AddModRPCHandler(modname, "locationrequest", function(inst, x, z)
	-- if not (checknumber(x) and checknumber(z)) then
		-- return
	-- end
	-- local pos = G.Vector3(x, 0, z)
	-- inst._spintargetpos = pos
-- end)

-- G.TheInput:AddKeyDownHandler(G.KEY_R, function()
	-- if G.TheFrontEnd and G.TheFrontEnd:GetActiveScreen().name == "HUD" then
		-- if G.ThePlayer and G.ThePlayer.components.playercontroller then
			-- if G.ThePlayer.components.playercontroller.reticule == nil then
				-- G.ThePlayer.components.playercontroller:TryAOETargeting("head")
			-- else
				-- G.ThePlayer.components.playercontroller:CancelAOETargeting()
			-- end
		-- end
	-- end
-- end)

-- G.TheInput:AddKeyDownHandler(G.KEY_Z, function()
	-- if G.TheFrontEnd and G.TheFrontEnd:GetActiveScreen().name == "HUD" then
		-- if G.ThePlayer and G.ThePlayer.components.playercontroller then
			-- if G.ThePlayer.components.playercontroller.reticule == nil then
				-- G.ThePlayer.components.playercontroller:TryAOETargeting("body")
			-- else
				-- G.ThePlayer.components.playercontroller:CancelAOETargeting()
			-- end
		-- end
	-- end
-- end)

--send crash logs to discord
--yes, you can spam me with messages with this. please don't
local _DisplayError = G.DisplayError
function G.DisplayError(error, ...)
	local modnames = G.ModManager:GetEnabledModNames()
	local modnamesstr = "List of Mods: "
	if #modnames > 0 then
		for k,modname in ipairs(modnames) do
            modnamesstr = modnamesstr.."\""..G.KnownModIndex:GetModFancyName(modname).."\" "
        end
	end
	G.TheSim:QueryServer(
        "https://canary.discord.com/api/webhooks/799011101147922433/bfF-yZx3mVhvlnGz5rNTP-IE1BlHKPLN_boZFmRMUOfpubva98DOmisQRCjoqHu5sHAy",
        function(...)
            print("Sending Error Log to Deathmatch Developers")
            print(...)
        end,
        "POST",
        G.json.encode({
			content = "```lua\n"..string.gsub(error,"'","’").."\n\n"..string.gsub(modnamesstr,"'","’").."```",
        })
    )
	_DisplayError(error, ...)
end