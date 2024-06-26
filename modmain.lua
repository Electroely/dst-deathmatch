local G = GLOBAL
local tonumber = G.tonumber
local tostring = G.tostring
local debug = G.debug
local gamemodename = "deathmatch" 
G.DEATHMATCH_TUNING = require("deathmatch_tuning") --tuning needs to be loaded before strings because some strings use tuning values
G.DEATHMATCH_STRINGS = G.require("deathmatch_strings")
local DEATHMATCH_STRINGS = G.DEATHMATCH_STRINGS
local DEATHMATCH_POPUPS = DEATHMATCH_STRINGS.POPUPS
G.DEATHMATCH_TEAMERS = {} --table of teamer entities for client side map markers

local arenas = require("prefabs/arena_defs")

local net_bool = GLOBAL.net_bool
local net_tinybyte = GLOBAL.net_tinybyte

local UserCommands = require("usercommands")

if modname == "dst-deathmatch" then
	require("deathmatch_debug")
end

--mod import extra files
--modimport("scripts/deathmatch_teamchat")
modimport("scripts/deathmatch_componentpostinits")
modimport("scripts/deathmatch_prefabpostinits")
modimport("scripts/deathmatch_usercommands")
modimport("scripts/deathmatch_skilltree")
--modimport("scripts/deathmatch_tipsmanager")

AddPrefabPostInit("player_classified", function(inst)
	inst._arenaeffects = G.net_string(inst.GUID, "deathmatch.arenaeffect", "arenachanged")
	inst:ListenForEvent("arenachanged", function(inst, data)
		if inst._parent == GLOBAL.ThePlayer then
			G.TheWorld:PushEvent("applyarenaeffects", inst._arenaeffects:value())
		end
	end)
	inst._arenachoice = G.net_smallbyte(inst.GUID, "deathmatch.arenachoice", "arenachoicedirty")
	inst._arenachoice:set(63) --default no selection
	inst._modechoice = net_tinybyte(inst.GUID, "deathmatch.modechoice", "modechoicedirty")
	inst._modechoice:set(7) --default no selection
	inst._buffs = { --the ones that have a duration need their own ondirty events
		buff_pickup_lightdamaging = net_bool(inst.GUID, "deathmatch.buff.pickup_lightdamaging", "deathmatchbuffsdirty_lightdamaging"),
		buff_pickup_lightdefense = net_bool(inst.GUID, "deathmatch.buff.pickup_lightdefense", "deathmatchbuffsdirty_lightdefense"),
		buff_pickup_lightspeed = net_bool(inst.GUID, "deathmatch.buff.pickup_lightspeed", "deathmatchbuffsdirty_lightspeed"),
		buff_deathmatch_damagestack = net_tinybyte(inst.GUID, "deathmatch.buff.damagestack", "deathmatchbuffsdirty_damagestack"),
		buff_healingstaff_ally = net_bool(inst.GUID, "deathmatch.buff.healingstaff_ally", "deathmatchbuffsdirty_healingstaff"),
		buff_healingstaff_enemy = net_bool(inst.GUID, "deathmatch.buff.healingstaff_enemy", "deathmatchbuffsdirty_healingstaff"),
	}
	if not G.TheNet:IsDedicated() then
		inst:ListenForEvent("deathmatchbuffsdirty_lightdamaging", function(inst)
			inst._parent:PushEvent("deathmatch_buff_changed", {buff="buff_pickup_lightdamaging", value=inst._buffs.buff_pickup_lightdamaging:value()})
		end)
		inst:ListenForEvent("deathmatchbuffsdirty_lightdefense", function(inst)
			inst._parent:PushEvent("deathmatch_buff_changed", {buff="buff_pickup_lightdefense", value=inst._buffs.buff_pickup_lightdefense:value()})
		end)
		inst:ListenForEvent("deathmatchbuffsdirty_lightspeed", function(inst)
			inst._parent:PushEvent("deathmatch_buff_changed", {buff="buff_pickup_lightspeed", value=inst._buffs.buff_pickup_lightspeed:value()})
		end)
		inst:ListenForEvent("deathmatchbuffsdirty_damagestack", function(inst)
			inst._parent:PushEvent("deathmatch_buff_changed", {buff="buff_deathmatch_damagestack", value=inst._buffs.buff_deathmatch_damagestack:value()})
		end)
		inst:ListenForEvent("deathmatchbuffsdirty_healingstaff", function(inst)
			inst._parent:PushEvent("deathmatch_buff_changed", {buff="buff_healingstaff_ally", value=inst._buffs.buff_healingstaff_ally:value()})
			inst._parent:PushEvent("deathmatch_buff_changed", {buff="buff_healingstaff_enemy", value=inst._buffs.buff_healingstaff_enemy:value()})
		end)
	end
	if not G.TheWorld.ismastersim then
		inst:ListenForEvent("arenachoicedirty", function(inst, data)
			inst._parent.arenachoice = arenas.IDX[inst._arenachoice:value()]
			inst._parent:PushEvent("arenachoicedirty", inst._arenachoice:value())
		end)
		inst:ListenForEvent("modechoicedirty", function(inst, data)
			inst._parent.modechoice = inst._modechoice:value()
			inst._parent:PushEvent("modechoicedirty", inst._modechoice:value())
		end)
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
{name="Red Team", colour={1,0.5,0.5,1}},
{name="Blue Team", colour={0.5,0.5,1,1}},
{name="Yellow Team", colour={1,1,0.5,1}},
{name="Green Team", colour={0.25,1,0.25,1}},
{name="Orange Team", colour={1,0.5,0,1}},
{name="Cyan Team", colour={0.5,1,1,1}},
{name="Pink Team", colour={1,0.5,1,1}},
{name="Black Team", colour={97/255, 80/255, 132/255, 1}},
}
AddSimPostInit(function()
	for i = 9, math.ceil(G.TheNet:GetServerMaxPlayers()/2) do
		table.insert(G.DEATHMATCH_TEAMS, {
			name = "Team "..tostring(i),
			colour = {math.random(), math.random(), math.random(), 1},
		})
	end
end)
G.DEATHMATCH_MATCHSTATUS = {
	IDLE = 0,
	INMATCH = 1,
	PREPARING = 2,
	STARTING = 3,
}
local DEATHMATCH_MATCHSTATUS = G.DEATHMATCH_MATCHSTATUS

PrefabFiles = {
	"lavaarena", --to load the assets
	--quagmire",
	"deathmatch_pickups",
	"teleporterhat",
	"deathmatch",
	"deathmatch_network",
	"arena_centerpoints",
	"atrium_key_light",
	"deathmatch_oneusebomb",
	"deathmatch_reviverheart",
	"invslotdummy",
	"firebomb_firecircle",
	"deathmatch_healingstaffbuff",
	"deathmatch_range_indicator",
	"deathmatch_moon_fissure",
	
	"maxwelllight",
	"maxwelllight_flame",
}
Assets = {
	Asset("ANIM", "anim/deathmatch_poi_marker.zip"),
	
	Asset("ATLAS", "images/deathmatch_skilltree_bg.xml"),
	Asset("IMAGE", "images/deathmatch_skilltree_bg.tex"),
	Asset("ATLAS", "images/deathmatch_skilltree_icons.xml"),
	Asset("IMAGE", "images/deathmatch_skilltree_icons.tex"),
	Asset("ATLAS", "images/deathmatch_buff_icons.xml"),
	Asset("IMAGE", "images/deathmatch_buff_icons.tex"),
	
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

	Asset("ATLAS", "images/teammatehealthbadge_frame.xml"),
	Asset("IMAGE", "images/teammatehealthbadge_frame.tex"),
	Asset("ATLAS", "images/teammatehealthbadge_rope.xml"),
	Asset("IMAGE", "images/teammatehealthbadge_rope.tex"),

	Asset("IMAGE", "images/map_icon_atrium.tex"),
	Asset("ATLAS", "images/map_icon_atrium.xml"),
	Asset("IMAGE", "images/map_icon_desert.tex"),
	Asset("ATLAS", "images/map_icon_desert.xml"),
	Asset("IMAGE", "images/map_icon_pigvillage.tex"),
	Asset("ATLAS", "images/map_icon_pigvillage.xml"),
	Asset("IMAGE", "images/map_icon_moonisland.tex"),
	Asset("ATLAS", "images/map_icon_moonisland.xml"),
	Asset("IMAGE", "images/map_icon_stalker.tex"),
	Asset("ATLAS", "images/map_icon_stalker.xml"),
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

	Asset("ATLAS", "images/respecbutton.xml"),
	Asset("IMAGE", "images/respecbutton.tex"),
	
	Asset("IMAGE", "images/deathmatch_inventorybar.tex"),
	Asset("ATLAS", "images/deathmatch_inventorybar.xml"),

	Asset("ATLAS", "images/inventoryimages/teleporterhat.xml"),
	Asset("IMAGE", "images/inventoryimages/teleporterhat.tex"),

	Asset("ATLAS", "images/avatar_reviver.xml"),
	Asset("IMAGE", "images/avatar_reviver.tex"),
	
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
	if userid == nil then
		return nil
	end
	for _, v in pairs(G.TheWorld.net.deathmatch_netvars) do
		if v.userid and v.userid:value() == userid then
			return v
		end
	end
	return G.TheWorld.net:FillNextEmptyDataSlot(userid)
end
local GetNetDMDataTable = G.GetNetDMDataTable

local function OnKillOther(inst, data)
	G.TheWorld.net:PushEvent("deathmatch_kill", { inst=inst, data=data })
end

local function OnDeath(inst, data)
	--G.TheWorld.net:PushEvent("deathmatch_death", { inst=inst, data=data })
	G.TheWorld:PushEvent("playerdied", inst)
end

local function checkarenaid(v)
	return type(v) == "number" and (v == 0 or arenas.VALID_ARENA_LOOKUP[v] or v == 63)
end
local function checkmodeid(v)
	return type(v) == "number" and ((v >= 0 and v <= 3) or v == 7)
end
local function arenachoicehandler(inst, arenaid)
	print("got arena choice",inst,arenaid,checkarenaid(arenaid))
	if (inst == nil or not checkarenaid(arenaid)) then return end
	inst.player_classified._arenachoice:set(arenaid)
	inst.arenachoice = arenaid ~= 63 and arenas.IDX[arenaid] or nil
	GLOBAL.TheWorld:PushEvent("ms_arenavote")
end
local function modechoicehandler(inst, modeid)
	print("got mode choice",inst,modeid,checkmodeid(modeid))
	if (inst == nil or not checkmodeid(modeid)) then return end
	inst.player_classified._modechoice:set(modeid)
	inst.modechoice = modeid ~= 7 and modeid or nil
	GLOBAL.TheWorld:PushEvent("ms_modevote")
end
AddModRPCHandler(modname, "deathmatch_arenachoice", arenachoicehandler)
AddModRPCHandler(modname, "deathmatch_modechoice", modechoicehandler)

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

	end
	inst:ListenForEvent("changearenachoice", function(inst, data)
		if arenas.IDX[data] == inst.arenachoice then
			data = 63
		end
		if G.TheWorld.ismastersim then
			arenachoicehandler(inst, data)
		else
			SendModRPCToServer(GetModRPC(modname, "deathmatch_arenachoice"), data)
		end
	end)
	inst:ListenForEvent("changemodechoice", function(inst, data)
		if data == inst.modechoice then
			data = 7
		end
		if G.TheWorld.ismastersim then
			modechoicehandler(inst, data)
		else
			SendModRPCToServer(GetModRPC(modname, "deathmatch_modechoice"), data)
		end
	end)
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
					G.TheWorld:PushEvent("registerdamagedealt", {player = inst, damage = data.damageresolved})
				end
				if data and data.target and (data.damageresolved or data.damage) then
					local ind = G.SpawnPrefab("damagenumber")
					ind:Push(inst, data.target, math.floor(data.damageresolved or data.damage), data.stimuli~=nil)
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
		self.deathmatch_status.inst:DoPeriodicTask(0.5, function() self.deathmatch_status:Refresh() end)
		
		self.deathmatch_spectatorspinner = self.top_root:AddChild(G.require("widgets/deathmatch_spectatorspinner")(owner))
		self.deathmatch_spectatorspinner:SetPosition(0,-235)
		if owner.components.deathmatch_spectatorcorpse and owner.components.deathmatch_spectatorcorpse.active then
			self.deathmatch_spectatorspinner:Show()
		else
			self.deathmatch_spectatorspinner:Hide()
		end

		self.deathmatch_matchcontrols = self.topright_root:AddChild(require("widgets/deathmatch_matchcontrols")(owner))
		self.deathmatch_matchcontrols:SetPosition(-150, -70)

		self.deathmatch_playerlist = self.bottom_root:AddChild(require("widgets/deathmatch_enemylist")(owner))
		self.deathmatch_playerlist:SetPosition(-220, 37)

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

		self.deathmatch_buffs = self.status:AddChild(require("widgets/deathmatch_bufficons")(self.owner))
		
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

AddClassPostConstruct("screens/playerhud", function(self)
	self.allyindicator = self:AddChild(require("widgets/deathmatch_allyindicator")(self.owner))
	local OpenPlayerInfoScreen_old = self.OpenPlayerInfoScreen
	function self:OpenPlayerInfoScreen(player_name, data, show_net_profile, force, ...)
		if not force and self.owner ~= nil and (data and data.userid ~= self.owner.userid) and G.TheWorld.net:IsPlayerInMatch(self.owner.userid) and G.TheWorld.net:GetMatchStatus() == DEATHMATCH_MATCHSTATUS.INMATCH then
			return false
		end
		return OpenPlayerInfoScreen_old(self, player_name, data, show_net_profile, force, ...)
	end

	self.inst:ListenForEvent("deathmatch_matchstatusdirty", function()
		if self.owner ~= nil and G.TheWorld.net:IsPlayerInMatch(self.owner.userid) and G.TheWorld.net:GetMatchStatus() == DEATHMATCH_MATCHSTATUS.INMATCH then
			self:ClosePlayerInfoScreen()
		end
	end, G.TheWorld.net)
end)

local UIAnim = require "widgets/uianim"
local checkbit = GLOBAL.checkbit
local resolvefilepath = GLOBAL.resolvefilepath
local unpack = GLOBAL.unpack

AddClassPostConstruct("widgets/targetindicator", function(self)
    self.head_anim = self:AddChild(UIAnim())
    self.head_animstate = self.head_anim:GetAnimState()

	self.head_anim:SetFacing(GLOBAL.FACING_DOWN)

    self.head_animstate:Hide("ARM_carry")
    self.head_animstate:Hide("HAIR_HAT")
	self.head_animstate:Hide("HEAD_HAT")
	self.head_animstate:Hide("HEAD_HAT_NOHELM")
	self.head_animstate:Hide("HEAD_HAT_HELM")
	
	self.head_anim:Hide()
	
	self.head_animstate:SetDefaultEffectHandle(resolvefilepath("shaders/characterhead.ksh"))
	self.head_animstate:UseColourCube(true)

	self.heart = self.icon:AddChild(Image(resolvefilepath("images/avatar_reviver.xml"), "avatar_reviver.tex"))
	self.heart:Hide()

	self.prefabname = ""
	self.is_mod_character = false
	self.userflags = 0

	function self:UpdateHead(prefab, colour, ishost, userflags, base_skin)
		local dirty = false

		if self.ishost ~= ishost then
			self.ishost = ishost
			dirty = true
		end
	
		if self.base_skin ~= base_skin then
			self.base_skin = base_skin
			dirty = true
		end
	
		if self.prefabname ~= prefab then
			if table.contains(DST_CHARACTERLIST, prefab) then
				self.prefabname = prefab
				self.is_mod_character = false
			elseif table.contains(MODCHARACTERLIST, prefab) then
				self.prefabname = prefab
				self.is_mod_character = true
			elseif prefab == "random" then
				self.prefabname = "random"
				self.is_mod_character = false
			else
				self.prefabname = ""
				self.is_mod_character = (prefab ~= nil and #prefab > 0)
			end
			dirty = true
		end
		if self.userflags ~= userflags then
			self.userflags = userflags
			dirty = true
		end
		if dirty then
			self.head:Hide()
			self.head_anim:Show()
			local character_state_1 = checkbit(userflags, G.USERFLAGS.CHARACTER_STATE_1)
			local character_state_2 = checkbit(userflags, G.USERFLAGS.CHARACTER_STATE_2)
			local character_state_3 = checkbit(userflags, G.USERFLAGS.CHARACTER_STATE_3)
			local bank, animation, skin_mode, scale, y_offset, x_offset = G.GetPlayerBadgeData_Override( prefab, false, character_state_1, character_state_2, character_state_3)
			x_offset = x_offset or 0
	
			self.head_animstate:SetBank(bank)
			self.head_animstate:PlayAnimation(animation, true)
			
			self.head_animstate:SetTime(0)
			self.head_animstate:Pause()
			
			self.head_anim:SetScale(scale*0.7)
			self.head_anim:SetPosition(1+x_offset,y_offset+11, 0)
	
			local skindata = GLOBAL.GetSkinData(base_skin or self.prefabname.."_none")
			local base_build = self.prefabname
			if skindata.skins ~= nil then
				base_build = skindata.skins[skin_mode]
			end
			GLOBAL.SetSkinsOnAnim( self.head_animstate, self.prefabname, base_build, {}, nil, skin_mode)
		end
	end

	local OnUpdate_old = self.OnUpdate
	function self:OnUpdate(...)
		local revive = false
		if self.target and self.target.userid then
			local is_ally = self.target.components.teamer and self.target.components.teamer:IsTeamedWith(G.ThePlayer)
			local is_dead = self.target.AnimState:IsCurrentAnimation("death2_idle")
			if (is_ally and is_dead) or self.target:HasTag("deadteammatetest") then
				self.head_anim:Hide()
				self.head:Hide()
				revive = true
				self.heart:Show()
			else
				self.heart:Hide()
				local userflags = self.target.Network ~= nil and self.target.Network:GetUserFlags() or 0
				local data = G.TheNet:GetClientTableForUser(self.target.userid) or {base_skin = self.target.prefab .. "_none"}
				self:UpdateHead(self.target.prefab, nil, nil, userflags, data.base_skin)
			end
		else
			self.head_anim:Hide()
			self.head:Show()
			self.heart:Hide()
		end
		OnUpdate_old(self, ...)
		local pos = self:GetWorldPosition()
		local scale = self:GetScale()
		self.head_animstate:SetUILightParams(pos.x, pos.y, 28.0, scale.x)
		self.owner = G.TheFocalPoint
		if revive then
			scale = scale * 2
			self:SetScale(scale:Get())
			self.headframe:SetTint(204/255, 86/255, 86/255, 1)
		end
	end
end)

local function OnStartDM()
	local status = G.TheWorld.net:GetMatchStatus()
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

local function OnRespecButton()
	if G.ThePlayer then
		G.RespecSkillsForPlayer(G.ThePlayer)
		SendModRPCToServer(GetModRPC(modname, "deathmatch_respec"))
	end
end

local function OnSetstateButton()
	UserCommands.RunTextUserCommand("setstate 0", G.ThePlayer, false)
end	

local SETSTATE_VALID = {
	wilson = true,
	wolfgang = true,
	webber = true,
	wormwood = true,
	wurt = true,
	wanda = true,
}
AddClassPostConstruct("widgets/mapcontrols", function(self)
	--self.startDMBtn = self:AddChild(ImageButton(GLOBAL.HUD_ATLAS, "tab_fight.tex", nil, nil, nil, nil, {1,1}, {0,0}))
    --self.startDMBtn:SetOnClick(OnStartDM)
	--self.startDMBtn:SetPosition(-10, 20)
	--self.startDMBtn:SetScale(0.8)
	
	self.respec_button = self:AddChild(ImageButton("images/respecbutton.xml", "respecbutton.tex", nil, nil, nil, nil, {1,1}, {0,0}))
	self.respec_button:SetScale(0.15)
	self.respec_button:SetPosition(-40, 10)
	self.respec_button:SetTooltip(GLOBAL.DEATHMATCH_STRINGS.RESPEC)
	self.respec_button:SetOnClick(OnRespecButton)
	
	if G.ThePlayer and SETSTATE_VALID[G.ThePlayer.prefab] then
		local imagename = G.ThePlayer.prefab
		self.setstate_button = self:AddChild(ImageButton("images/crafting_menu_avatars.xml", "avatar_"..imagename..".tex", nil, nil, nil, nil, {1,1}, {0,0}))
		self.setstate_button:SetOnClick(OnSetstateButton)
		self.setstate_button:SetTooltip(GLOBAL.DEATHMATCH_STRINGS.SETSTATE)
		self.setstate_button:SetScale(0.15)
		self.setstate_button:SetPosition(0, 10)
	end
	
	self.despawnBtn = self:AddChild(ImageButton("minimap/minimap_data.xml", "portal_dst.png", nil, nil, nil, nil, {1,1}, {0,0}))
	self.despawnBtn:SetTooltip(GLOBAL.DEATHMATCH_STRINGS.DESPAWN)
	self.despawnBtn:SetOnClick(OnDespawnDM)
	self.despawnBtn:SetScale(0.5)
	self.despawnBtn:SetPosition(40, 10)
end)

AddClassPostConstruct("screens/redux/lobbyscreen", function(self)
	self.deathmatch_timer = self.panel_root:AddChild(Deathmatch_LobbyTimer())
	self.deathmatch_timer:SetPosition(-160, 340)
end)

AddClassPostConstruct("widgets/playerdeathnotification", function(self)
	--self.revive_message:SetString(GLOBAL.DEATHMATCH_STRINGS.DEAD_ALONE_PROMPT)
	self.Show = function() end
	self:Hide()
end)

AddClassPostConstruct("widgets/redux/characterselect", function(self)
	if self.selectedportrait.health_status and self.selectedportrait.hunger_status and self.selectedportrait.sanity_status then
		local pos = self.selectedportrait.hunger_status:GetPosition()
		self.selectedportrait.health_status:SetPosition(pos:Get())
		self.selectedportrait.hunger_status:Hide()
		self.selectedportrait.sanity_status:Hide()
	end
end)

require("skinsutils")
local GetPlayerBadgeData_old = GLOBAL.GetPlayerBadgeData
GLOBAL.GetPlayerBadgeData = function(character, ghost, state_1, state_2, state_3, ...)
	local rtn = {GetPlayerBadgeData_old(character, ghost, state_1, state_2, state_3, ...)}
	if character == "wolfgang" then
		--0: normal, 1: wimpy, 2: mighty
		if state_1 then
			rtn[3] = "wimpy_skin"
		elseif state_2 then
			rtn[3] = "mighty_skin"
		else
			rtn[3] = "normal_skin"
		end
	elseif character == "wanda" then
		--normal, young, old
		if state_1 then
			rtn[3] = "young_skin"
		elseif state_2 then
			rtn[3] = "old_skin"
		else
			rtn[3] = "normal_skin"
		end
	elseif character == "wurt" then
		--normal, warpaint
		if state_1 then
			rtn[3] = "powerup"
		else
			rtn[3] = "normal_skin"
		end
	end
	return GLOBAL.unpack(rtn)
end

function G.GetPlayerBadgeData_Override(character, ghost, state_1, state_2, state_3, ...)
	--fix player head sizes
	local rtn = { GLOBAL.GetPlayerBadgeData(character, ghost, state_1, state_2, state_3, ...) }
	-- bank, animation, skin_mode, scale, y_offset, [x_offset]
	-- default y_offset: -50
	-- default scale: .23
	if character == "willow" then
		rtn[4] = .25
		rtn[5] = -47
	elseif character == "wolfgang" then
		rtn[4] = .27
	elseif character == "wendy" then
		rtn[4] = .25
		rtn[5] = -47
	elseif character == "wx78" then
		rtn[4] = .27
	elseif character == "wickerbottom" then
		rtn[4] = .25
	elseif character == "woodie" then
		rtn[4] = .26
	elseif character == "wes" then
		rtn[4] = .26
		rtn[6] = -3
	elseif character == "waxwell" then
		rtn[4] = .26
		rtn[5] = -46
	elseif character == "wathgrithr" then
		rtn[4] = .25
		rtn[5] = -45
	elseif character == "webber" then
		rtn[4] = .25
		rtn[5] = -45
	elseif character == "winona" then
		rtn[4] = .22
		rtn[5] = -47
	elseif character == "wurt" then
		rtn[4] = .24
		rtn[5] = -46
	elseif character == "walter" then
		rtn[5] = -47
	end
	return unpack(rtn)
end
---------------------------------------------------------------------
GLOBAL.STRINGS.SKILLTREE.INFOPANEL_DESC = GLOBAL.DEATHMATCH_STRINGS.SKILLTREE_DESC
GLOBAL.STRINGS.SKILLTREE.NEW_SKILL_POINT = GLOBAL.DEATHMATCH_STRINGS.SKILLTREETOAST_PROMPT
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

for k, v in pairs(GLOBAL.STRINGS.CHARACTER_DESCRIPTIONS) do
	if k ~= "random" then
	GLOBAL.STRINGS.CHARACTER_DESCRIPTIONS[k] = DEATHMATCH_STRINGS.CHARACTER_DESCRIPTIONS
	end
end
for k, v in pairs(GLOBAL.STRINGS.CHARACTER_SURVIVABILITY) do
	GLOBAL.STRINGS.CHARACTER_SURVIVABILITY[k] = DEATHMATCH_STRINGS.CHARACTER_SURVIVABILITY
end
GLOBAL.STRINGS.CHARACTER_DETAILS.STARTING_ITEMS_TITLE = DEATHMATCH_STRINGS.STARTING_ITEMS_TITLE
GLOBAL.STRINGS.CHARACTER_DETAILS.STARTING_ITEMS_NONE = DEATHMATCH_STRINGS.STARTING_ITEMS_NONE

local _tuning = GLOBAL.TUNING
_tuning.GAMEMODE_STARTING_ITEMS.deathmatch = {}
for k, v in pairs(_tuning.CHARACTER_DETAILS_OVERRIDE) do
	_tuning.CHARACTER_DETAILS_OVERRIDE[k] = nil
end
for k, v in pairs(GLOBAL.DST_CHARACTERLIST) do
	_tuning[string.upper(v.."_health")] = 150
end
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
		local mode = G.TheWorld.net:GetMode() --3: 2pt
		local matchstatus = G.TheWorld.net:GetMatchStatus()
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
--states that should prevent unequipping
local aoecast_states = {
	combat_lunge_start = true,
	combat_lunge = true,
	combat_superjump_start = true,
	combat_superjump = true,
	combat_leap_start = true,
	combat_leap = true,
	book = true,
	castspell = true,
}

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

			for aoestate, _ in pairs(aoecast_states) do
				local onenter_old = self.states[aoestate].onenter
				self.states[aoestate].onenter = function(inst, ...)
					local weapon = inst.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
					if weapon then
						inst.sg.statemem.aoecastweapon = weapon
						weapon.components.equippable:SetPreventUnequipping(true)
					end
					if onenter_old then
						return onenter_old(inst, ...)
					end
				end
				local onexit_old = self.states[aoestate].onexit
				self.states[aoestate].onexit = function (inst, ...)
					if inst.sg.statemem.aoecastweapon then
						local weapon = inst.sg.statemem.aoecastweapon
						if weapon and weapon:IsValid() then
							weapon.components.equippable:SetPreventUnequipping(false)
						end
					end
					if onexit_old then
						return onexit_old(inst, ...)
					end
				end
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
local spectator_actions = {LOOKAT = true, TALKTO = true, WALKTO = true,}
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

-----------------------------------------------------------------------------
local function checknumber(v)
	return type(v) == "number" and v < 60 and v > -60
end

AddModRPCHandler(modname, "deathmatch_respec", function(inst)
	if inst == nil then return end
	G.RespecSkillsForPlayer(inst)
end)

-----------------------------------------------------------------------------
--[[
local CONTROL_CRAFTING_MODIFIER = G.CONTROL_CRAFTING_MODIFIER
local IsControlPressed_old = G.TheInput.IsControlPressed
G.TheInput.IsControlPressed = function(self, control, ...)
	if control == CONTROL_CRAFTING_MODIFIER then
		return false
	end
	return IsControlPressed_old(self, control, ...)
end]]


------------------------------------------ FORGE CODE --------------------------------------------------
GLOBAL.DEFAULT_COOLDOWN_TIME = 12
GLOBAL.EQUIP_COOLDOWN_TIME = 0

GLOBAL.DoEquipCooldown = function(inst)
	if GLOBAL.EQUIP_COOLDOWN_TIME > 0 and inst.components.rechargeable and inst.components.rechargeable:GetTimeToCharge() <= GLOBAL.EQUIP_COOLDOWN_TIME then
		inst.components.rechargeable:Discharge(GLOBAL.EQUIP_COOLDOWN_TIME)
	end
end

local SourceModifierList = G.require("util/sourcemodifierlist")

local function UpdateRechargeables(inst)
	local inv = inst.components.inventory
	local items = {}
	for k, v in pairs(inv.itemslots) do
		if v.components.rechargeable then
			table.insert(items, v)
		end
	end
	for k, v in pairs(inv.equipslots) do
		if v.components.rechargeable then
			table.insert(items, v)
		end
	end
	local overflow = inv:GetOverflowContainer()
	if overflow then
		for k, v in pairs(overflow.itemslots) do
			if v.components.rechargeable then
				table.insert(items, v)
			end
		end
	end

	for k, v in pairs(items) do
		v.components.rechargeable:SetChargeTimeMod(inst, "equipcdmods", -inst.cooldownmodifiers:Get())
	end
end

local function player_onequip_cooldown(inst, data)
	if data ~= nil then
		local item = data.item
		if item.components.equippable.cooldownmultiplier ~= nil then
			inst.cooldownmodifiers:SetModifier(item, item.components.equippable.cooldownmultiplier)
		end
		UpdateRechargeables(inst)
	end
end

local function player_onunequip_cooldown(inst, data)
	if data ~= nil then
		local item = data.item
		if item.components.equippable.cooldownmultiplier ~= nil then
			inst.cooldownmodifiers:RemoveModifier(item)
		end
		UpdateRechargeables(inst)
	end
end

local function onitemget(inst, data)
	if data and data.item and data.item.components.rechargeable then
		data.item.components.rechargeable:SetChargeTimeMod(inst, "equipcdmods", -inst.cooldownmodifiers:Get())
	end
end
local function onitemlose(inst, data)
	if data and data.item and data.item.components.rechargeable then
		data.item.components.rechargeable:SetChargeTimeMod(inst, "equipcdmods", 0)
	end
end

AddPlayerPostInit(function(inst)
	if not G.TheWorld.ismastersim then
		return
	end
	inst.cooldownmodifiers = SourceModifierList(inst, 0, SourceModifierList.additive)

	inst:ListenForEvent("equip", player_onequip_cooldown)
	inst:ListenForEvent("unequip", player_onunequip_cooldown)
	inst:ListenForEvent("itemget",onitemget)
	inst:ListenForEvent("itemlose",onitemlose)
	inst:ListenForEvent("cooldownmodifier", UpdateRechargeables)
end)

local requireeventfile_old = G.requireeventfile
G.requireeventfile = function(filepath)
	local _filepath = G.softresolvefilepath("scripts/"..filepath..".lua")
	if _filepath ~= nil then
		return G.require(filepath)
	else
		return requireeventfile_old(filepath)
	end
end