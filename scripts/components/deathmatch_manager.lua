local arenas = require("prefabs/arena_defs")

local ARENA_DEFS = arenas.CONFIGS
local arena_configs = ARENA_DEFS
local arena_idx = arenas.IDX_LOOKUP
local random_arena_select = arenas.VALID_ARENAS

local function GetValidPoint(position, start_angle, radius, attempts)
	return FindValidPositionByFan(start_angle, radius, attempts,
            function(offset)
                local x = position.x + offset.x
                local y = position.y + offset.y
                local z = position.z + offset.z
                return TheWorld.Map:IsAboveGroundAtPoint(x, y, z)
			end)
end

local function findcenter()
	local self = TheWorld.components.deathmatch_manager
	for k, v in pairs(Ents) do
		if v.prefab == "arena_centerpoint_"..self.arena then
			return v
		end
	end
	return nil
end

local function getPlayerCount(onlyalive)
	local count = 0
	for k, v in pairs(AllPlayers) do
		if not v:HasTag("spectator") and (not onlyalive or not v.components.health:IsDead()) then
			count = count + 1
		end
	end
	return count
end
local function getPlayers(onlyalive)
	local results = {}
	local spectators = {}
	for k, v in pairs(AllPlayers) do
		if not v:HasTag("spectator") and (not onlyalive or not v.components.health:IsDead()) then
			table.insert(results, v)
		elseif v:HasTag("spectator") then
			table.insert(spectators, v)
		end
	end
	return results, spectators
end

local function TableContains(table, value)
	local found = false
	local idx = nil
	for k, v in pairs(table) do
		if v == value then
			found = true
			idx = k
		end
	end
	return found, idx
end

local function AddTable(target, tabl)
	if tabl ~= nil and type(tabl) == "table" then
		for k, v in pairs(tabl) do
			table.insert(target, v)
		end
	end
end

local function ScrambleTable(table)
	local newtable = {}
	for i, v in ipairs(table) do
		local function ins(tbl, v)
			local newkey = math.random(1, #table)
			if tbl[newkey] == nil then
				tbl[newkey] = v
			else
				ins(tbl, v)
			end
		end
		ins(newtable, v)
	end
	return(newtable)
end

local function UserOnline(userid)
	local clienttbl = TheNet:GetClientTable()
	if clienttbl == nil then
		return {}
	elseif TheNet:GetServerIsClientHosted() then
		return clienttbl
	end
	
    for i, v in ipairs(clienttbl) do
        if v.performance ~= nil then
            table.remove(clienttbl, i)
            break
        end
    end
	
	local found = false
	for k, v in pairs(clienttbl) do
		if v.userid == userid then
			found = true
		end
	end
	return found
end

local function OnPlayerDeath(inst, data)
	if TheWorld ~= nil and TheWorld.components.deathmatch_manager and TheWorld.components.deathmatch_manager.enabled then
		local self = TheWorld.components.deathmatch_manager
		local liveplayers = self:CountAlivePlayers()
		if liveplayers <= 1 and not self.doingreset and self.matchinprogress then
			TheWorld:PushEvent("wehaveawinner", self:GetWinner())
			self:StopDeathmatch()
		end
	end
end

local function RegisterDamageDealt(inst, data)
	local self = inst.components.deathmatch_manager
	if self.damagedealt[data.player] == nil then self.damagedealt[data.player] = 0 end
	self.damagedealt[data.player] = self.damagedealt[data.player] + data.damage
	--[[local leader = self:GetLeadingPlayer()
	if leader ~= self.leadingplayer then
		self.leadingplayer = leader
		self.inst.net:PushEvent("deathmatch_leadingplayerchange", leader)
	end]] -- doubting if this would be a good idea, dont want the winner to keep running off 
end

local function OnPlayerLeft(inst, player)
	local self = inst.components.deathmatch_manager
	self.damagedealt[player] = nil
	OnPlayerDeath(player)
	local contains, idx = TableContains(self.players_in_match, player)
	if contains then
		table.remove(self.players_in_match, idx)
	end
	local id = player.userid
	inst:DoTaskInTime(FRAMES, function(inst)
		if self.doingreset and UserOnline(id) then
			TheNet:Announce(self.announcestrings.NEARSTARTDESPAWN)
			self:ResetDeathmatch()
		elseif self.doingreset and self.gamemode ~= 0 and self.gamemode <= #self.gamemodes then
			self:GroupTeams(self.gamemodes[self.gamemode].teammode)
		end
	end)
end

local function OnPlayerJoined(inst, player)
	player:PushEvent("respawnfromcorpse",{quick=true})
	player:ApplyLobbyInvincibility(true)
	local self = inst.components.deathmatch_manager
	if self.doingreset then
		TheNet:Announce(self.announcestrings.LATEJOIN)
		--player.components.combat.externaldamagetakenmultipliers:SetModifier("deathmatchinvincibility", 0)
		self:ResetDeathmatch()
	else
		--player.components.combat.externaldamagetakenmultipliers:SetModifier("deathmatchinvincibility", 0)
		--local pos = self.inst.lobbypoint:GetPosition()
		--player.Transform:SetPosition(pos:Get())
		player:DoDeathmatchTeleport(self.inst.lobbypoint:GetPosition())
		if self.matchinprogress or self.matchstarting then
			player:DoTaskInTime(1, function()
				TheNet:SystemMessage(DEATHMATCH_STRINGS.CHATMESSAGES.JOIN_MIDMATCH)
			end)
		end
		self:GiveLobbyInventory(player)
	end
	player:ListenForEvent("updateloadout", function(player)
		if not (self.matchinprogress or self.matchstarting) then
			self:GiveLobbyInventory(player)
		end
	end)
	--[[if #TheNet:GetClientTable() == 2 then
		player:DoTaskInTime(1, function()
			TheNet:SystemMessage(DEATHMATCH_STRINGS.CHATMESSAGES.JOIN_ALONE)
		end)
	elseif not (self.matchinprogress or self.matchstarting) then
		player:DoTaskInTime(1, function()
			TheNet:SystemMessage(DEATHMATCH_STRINGS.CHATMESSAGES.JOIN_LOBBY)
		end)
	end]]
end

local function MakeSpectator(player, bool)
	--player.components.combat.externaldamagetakenmultipliers:SetModifier("deathmatchinvincibility", 0)
	if bool then
		player.AnimState:SetMultColour(0.1,0.1,0.1,0.1)
		player.DynamicShadow:SetSize(0,0)
		player:AddTag("notarget")
		player:AddTag("noclick")
		local phys = player.Physics
		phys:SetCollisionGroup(COLLISION.CHARACTERS)
		phys:ClearCollisionMask()
		phys:CollidesWith(COLLISION.WORLD)
		--player:PushEvent("respawnfromcorpse",{quick=true})
		--phys:SetCapsule(0, 0)
		if player.components.health:IsDead() then
			player:PushEvent("respawnfromcorpse",{instant=true})
			player:DoTaskInTime(2*FRAMES, function(player)
				player.sg.statemem.physicsrestored = true
				phys:SetCollisionGroup(COLLISION.CHARACTERS)
				phys:ClearCollisionMask()
				phys:CollidesWith(COLLISION.WORLD)
			end)
		end
	else
		player.AnimState:SetMultColour(1,1,1,1)
		player.DynamicShadow:SetSize(1.3, .6)
		player:RemoveTag("notarget")
		player:RemoveTag("noclick")
		local phys = player.Physics
		phys:SetCollisionGroup(COLLISION.CHARACTERS)
		phys:ClearCollisionMask()
		phys:CollidesWith(COLLISION.WORLD)
		phys:CollidesWith(COLLISION.OBSTACLES)
		phys:CollidesWith(COLLISION.SMALLOBSTACLES)
		phys:CollidesWith(COLLISION.CHARACTERS)
		phys:CollidesWith(COLLISION.GIANTS)
		if player.components.health:IsDead() then
			player:PushEvent("respawnfromcorpse",{instant=true})
		end
		--phys:SetCapsule(0.5, 1)
	end
	player:ApplyLobbyInvincibility(true)
	player:ClearBufferedAction()
end

local function OnArenaVote(inst)
	local self = inst.components.deathmatch_manager
	if self.allow_arena_vote then
		self:SetVotedArena()
	end
end
local function OnModeVote(inst)
	local self = inst.components.deathmatch_manager
	if self.allow_mode_vote and not (self.matchstarting or self.matchinprogress) then
		self:SetVotedMode()
	end
end

local DEFAULT_LOADOUT = "forge_melee"
local LOADOUTS = {
	forge_melee = {
		health = DEATHMATCH_TUNING.FORGE_MELEE_HEALTH,
		weapons = {
			"spear_gungnir",
			"spear_lance",
			"hammer_mjolnir",
			"lavaarena_heavyblade",
		},
		equip = {
			"lavaarena_armormediumdamager"
		}
	},
	forge_mage = {
		health = DEATHMATCH_TUNING.FORGE_MAGE_HEALTH,
		weapons = {
			"fireballstaff",
			"healingstaff",
			"book_elemental",
			"teleporterhat"
		},
		equip = {
			"lavaarena_armormediumrecharger",
			"lavaarena_rechargerhat",
		}
	}
}

dm = nil -- gotta remove later
local Deathmatch_Manager = Class(function(self, inst)

	self.inst = inst
	self.timer_time = 600
	self.timer_current = 0
	self.revivals = 0
	self.leadingplayer = nil
	
	self.announcestrings = DEATHMATCH_STRINGS.ANNOUNCE
	
	self.pickupprefabs = {
	"pickup_lightdamaging",
	"pickup_lightdefense",
	"pickup_lightspeed",
	"pickup_lighthealing",
	"pickup_cooldown",
	--"blowdart_lava_temp"
	}
	self.perilpickup = "pickup_lighthealing",
	self.gamemode = 0
	self.gamemodes = {
	{name=DEATHMATCH_STRINGS.TEAMMODE_FFA,teammode="ffa"},
	{name=DEATHMATCH_STRINGS.TEAMMODE_RVB,teammode="half"},
	{name=DEATHMATCH_STRINGS.TEAMMODE_2PT,teammode="pairs"},
	}

	self.lobbyitems = {
		"lavaarena_firebomb",
	}
	
	self.enabled = true
	self.arena = "atrium"
	self.upcoming_arena = "atrium"
	self.enablepickups = true
	self.enabledarts = true
	self.allow_teamswitch_user = true
	self.allow_endmatch_user = true
	self.allow_arena_vote = true
	self.allow_mode_vote = true
	self.matchstarting = false
	self.matchinprogress = false
	self.doingreset = false
	self.players_in_match = {}
	self.spawneditems = {}
	self.spawnedgear = {}
	self.spawnedpickups = {}
	self.voters = {}
	self.voters.endmatch = {}
	self.damagedealt = {}
	self.removeallitems = true
	
	
	inst:ListenForEvent("playerdied", OnPlayerDeath)
	inst:ListenForEvent("registerdamagedealt", RegisterDamageDealt)
	inst:ListenForEvent("ms_playerjoined", OnPlayerJoined)
	inst:ListenForEvent("ms_playerleft", OnPlayerLeft)
	inst:ListenForEvent("ms_arenavote", OnArenaVote)
	inst:ListenForEvent("ms_modevote", OnModeVote)
	dm = self -- easier testing ingame
end)

function Deathmatch_Manager:GetLoadoutForPlayer(player)
	for loadout, data in pairs(LOADOUTS) do
		if player:HasTag("loadout_"..loadout) then
			return data
		end
	end
	return LOADOUTS[DEFAULT_LOADOUT]
end

function Deathmatch_Manager:GiveLobbyInventory(player)
	local loadout_data = self:GetLoadoutForPlayer(player)
	local lobbyitems = deepcopy(loadout_data.weapons)
	for k, v in pairs(self.lobbyitems) do
		table.insert(lobbyitems, v)
	end
	local inv = player.components.inventory
	for k, v in pairs(inv.itemslots) do if v.prefab ~= "invslotdummy" then v:Remove() end end
	for k, v in pairs(inv.equipslots) do v:Remove() end
	player.components.health:SetMaxHealth(loadout_data.health)
	for k, v in pairs(lobbyitems) do
		local weap = SpawnPrefab(v)
		weap.forceslot = k
		inv:GiveItem(weap, k)
	end
	for k, v in pairs(loadout_data.equip) do
		local item = SpawnPrefab(v)
		inv:GiveItem(item)
		inv:Equip(item)
		item.components.equippable:SetPreventUnequipping(true)
	end
end

function Deathmatch_Manager:IsPlayerInMatch(player)
	local yes = TableContains(self.players_in_match, player)
	return yes
end

function Deathmatch_Manager:CountAlivePlayers(ignoretagged)
	local count = 0
	local countedteams = {}
	if self.players_in_match ~= nil then
		for k, v in pairs(self.players_in_match) do
			if ignoretagged or (not v:HasTag("ignore_deathmatch"))
				and not v.components.health:IsDead() and not v:HasTag("playerghost") then
				if v.components.teamer and v.components.teamer.team ~= 0 then
					if not TableContains(countedteams, v.components.teamer.team) then
						count = count + 1
						table.insert(countedteams, v.components.teamer.team)
					end
				else
					count = count + 1
				end
			end
		end
	end
	return count
end

function Deathmatch_Manager:GetWinner()
	if self.players_in_match ~= nil then
		for k, v in pairs(self.players_in_match) do
			if not (v.components.health:IsDead() or v:HasTag("playerghost")) then
				return v.components.teamer.team == 0 and v or v.components.teamer.team
			end
		end
	end
	return nil
end

function Deathmatch_Manager:GetLeadingPlayer() -- damage-wise
	local leadingplayer = nil
	local leadingplayerdamage = 0
	if self.players_in_match ~= nil then
		for k, v in pairs(self.players_in_match) do
			if (not v.components.health:IsDead()) and self.damagedealt[v] and self.damagedealt[v] > leadingplayerdamage then
				leadingplayer = v.components.teamer.team == 0 and v or v.components.teamer.team
				leadingplayerdamage = self.damagedealt[v]
			end
		end
	end
	return leadingplayer
end

function Deathmatch_Manager:ReleasePlayers()
	if self.players_in_match ~= nil then
		self.inst.net:PushEvent("deathmatch_matchstatuschange", 3)
		self.doingreset = false
		self.matchstarting = true
		self.inst:DoTaskInTime(7, function() TheNet:Announce(self.announcestrings.MATCHBEGIN) end)
		for k, v in pairs(self.players_in_match) do
			--v.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "deathmatch_speedmult")
			v:DoTaskInTime(7, function(v)
				v.components.locomotor:SetExternalSpeedMultiplier(self.inst, "deathmatch_speedmult", 1)
				--v.components.combat.externaldamagetakenmultipliers:SetModifier("deathmatchinvincibility", 1)
				v:ApplyLobbyInvincibility(false)
				print("Releasing "..v:GetDisplayName().."...")
			end)
		end
		self.inst:DoTaskInTime(7, function() self:BeginMatch() end)
	end
end
DM_FADE = false
function Deathmatch_Manager:StartDeathmatch()
	if self.startdeathmatchtask ~= nil then
		self.startdeathmatchtask:Cancel()
		self.startdeathmatchtask = nil
	end
	self.inst.centerpoint = findcenter()
	TheNet:Announce(self.announcestrings.MATCHINIT)
	self.inst.net:PushEvent("deathmatch_timercurrentchange", 7)
	if getPlayers() ~= nil then
		self.doingreset = true
		for k, v in pairs(self.spawneditems) do
			--[[local pos = v:GetPosition()
			if v.components.inventoryitem.owner == nil then
				SpawnPrefab("small_puff").Transform:SetPosition(pos:Get())
			end]]
			v:Remove()
		end
		if self.removeallitems then
			local to_remove = {}
			local numremove = 0
			for k, v in pairs(Ents) do 
				if (v.prefab == "balloon" or v.components.inventoryitem) and not (v.prefab == "invslotdummy") then
					numremove = numremove + 1
					to_remove[numremove] = v
				end
			end
			for i = 1, numremove do
				to_remove[i]:Remove()
			end
		end
		self.enablepickups = not arena_configs[self.arena].nopickups == true
		local players, spectators = getPlayers()
		for k, v in pairs(players) do 
			local loadout_data = self:GetLoadoutForPlayer(v)
			local items = deepcopy(loadout_data.weapons)
			AddTable(items, arena_configs[self.arena].extraitems)
			AddTable(items, v.deathmatch_startitems)
			v.components.health:SetMaxHealth(loadout_data.health)
			for k2, v2 in pairs(items) do
				local item = SpawnPrefab(v2)
				item.forceslot = k2
				v.components.inventory:GiveItem(item, k2)
				--if k2 == "autoequip" then v.components.inventory:Equip(item) end
				if item.components.rechargeable then item.components.rechargeable:Discharge(DEFAULT_COOLDOWN_TIME) end
				if item.components.inventoryitem then table.insert(self.spawneditems, item) end
			end
			for k2, v2 in pairs(loadout_data.equip) do
				local item = SpawnPrefab(v2)
				v.components.inventory:GiveItem(item)
				v.components.inventory:Equip(item)
				item.components.equippable:SetPreventUnequipping(true)
				
				table.insert(self.spawnedgear, item)
			end
			--[[if arena_configs[self.arena].extraitems ~= nil then
				for k2, v2 in pairs(arena_configs[self.arena].extraitems) do
					local item = SpawnPrefab(v2)
					v.components.inventory:GiveItem(item)
					if item.components.rechargeable then item.components.rechargeable:Discharge(DEFAULT_COOLDOWN_TIME) end
					if item.components.inventoryitem then table.insert(self.spawneditems, item) end
				end
			end]]
			if v:HasTag("playerghost") then
				v:PushEvent("respawnfromghost")
				v:DoTaskInTime(6, function(v) v.components.health:SetPercent(1) end)
			end
			if v.components.revivablecorpse then
				v:PushEvent("respawnfromcorpse", {quick=true, delay = 1})
				v:DoTaskInTime(3, function(v)
					v.components.health:SetPercent(1)
				end)
			end
			if self.inst.centerpoint ~= nil then
				local pos = self.inst.centerpoint:GetPosition()
				if not v.components.health:IsDead() then v.sg:GoToState("idle") end
				v:AddTag("notarget")
				local theta = (k/getPlayerCount()* 2 * PI)
				local radius = arena_configs[self.arena] ~= nil and arena_configs[self.arena].spawnradius or 10
				local offset = GetValidPoint(pos, theta, radius)
				if offset ~= nil then
					offset.x = offset.x + pos.x
					offset.z = offset.z + pos.z
					v:DoDeathmatchTeleport(offset)
					--v.Transform:SetPosition(offset.x, 0, offset.z)
					--v:SnapCamera()
					--if DM_FADE then
					--	v:ScreenFade(false)
					--	v:ScreenFade(true, 1)
					--end
				end
			end
			table.insert(self.players_in_match, v)
			v.components.locomotor:SetExternalSpeedMultiplier(self.inst, "deathmatch_speedmult", 0)
		end
		for k, v in pairs(spectators) do
			--MakeSpectator(v, true)
			--v.Transform:SetPosition(self.inst.centerpoint:GetPosition():Get())
			v:DoDeathmatchTeleport(self.inst.centerpoint:GetPosition())
			--v:SnapCamera()
			--if DM_FADE then
			--	v:ScreenFade(false)
			--	v:ScreenFade(true, 1)
			--end
		end
		if arena_configs[self.arena] and arena_configs[self.arena].matchstartfn then
			arena_configs[self.arena].matchstartfn()
		end
		if self.gamemode ~= 0 and self.gamemode <= #self.gamemodes then
			self:GroupTeams(self.gamemodes[self.gamemode].teammode)
		end
		if self.gamemode == 0 then
			self.allow_teamswitch_user = false
		end
		print("Reset successful! Queuing player release...")
		self:ReleasePlayers()
	end
end

function Deathmatch_Manager:StopDeathmatch()
	self.matchinprogress = false
	TheNet:Announce(self.announcestrings.MATCHOVER)
	if self.timertask ~= nil then
		self.timertask:Cancel()
		self.timertask = nil
	end
	self.timer_current = 0
	self.inst.net:PushEvent("deathmatch_timercurrentchange", 0)
	self.inst.net:PushEvent("deathmatch_matchstatuschange", 0)
	if self.allow_arena_vote then
		self:SetVotedArena()
	end
	self.inst.net:PushEvent("deathmatch_arenachange", arena_idx[self.upcoming_arena])
	if self.pickuptask ~= nil then
		self.pickuptask:Cancel()
		self.pickuptask = nil
	end
	if arena_configs[self.arena] and arena_configs[self.arena].matchendfn ~= nil then
		arena_configs[self.arena].matchendfn()
	end
	for k, v in pairs(self.spawnedpickups) do
		if v and v:IsValid() then
			local poof = SpawnPrefab("small_puff")
			poof.Transform:SetPosition(v:GetPosition():Get())
			v:Remove()
		end
	end
	self.spawnedpickups = {}
	if self.gamemode == 0 then
		self.allow_teamswitch_user = true
	end
	for k, v in pairs(AllPlayers) do
		v:DoTaskInTime(5, function(v)
			v:PushEvent("respawnfromcorpse",{quick=true, delay = 1})
			if not v.components.health:IsDead() then v.sg:GoToState("idle") end
			if v:HasTag("spectator") and not v:HasTag("spectator_perma") then
				self:ToggleSpectator(v)
			elseif v:HasTag("spectator_perma") then
				self:ToggleSpectator(v)
			end
			local pos = self.inst.lobbypoint:GetPosition()
			local theta = (k/#AllPlayers * 2 * PI)
			local radius = 7
			local offset = GetValidPoint(pos, theta, radius)
			if offset ~= nil then
				offset.x = offset.x + pos.x
				offset.z = offset.z + pos.z
				--v.Transform:SetPosition(offset.x, 0, offset.z)
				--v:SnapCamera()
				--if DM_FADE then
				--	v:ScreenFade(false)
				--	v:ScreenFade(true, 1)
				--end
				v:DoDeathmatchTeleport(offset)
				self:GiveLobbyInventory(v)
			end
			if self.allow_mode_vote then
				self:SetVotedMode()
			end
			--v.components.combat.externaldamagetakenmultipliers:SetModifier("deathmatchinvincibility", 0)
			v:ApplyLobbyInvincibility(true)
			if self.gamemode == 2 then
				v.components.teamer:SetTeam(v.teamchoice)
			else
				v.components.teamer:SetTeam(0)
			end
		end)
	end
	self.players_in_match = {}
end


function Deathmatch_Manager:ResetDeathmatch()
	if self.upcoming_arena == "random" then
		self.arena = GetRandomItem(random_arena_select)
	else
		self.arena = self.upcoming_arena
	end
	TheNet:Announce(self.announcestrings.MATCHRESET)
	self.voters.endmatch = {}
	self.damagedealt = {}
	self.revivals = 0
	self.matchinprogress = false
	if self.pickuptask ~= nil then
		self.pickuptask:Cancel()
		self.pickuptask = nil
	end
	if self.startdeathmatchtask ~= nil then
		self.startdeathmatchtask:Cancel()
		self.startdeathmatchtask = nil
	end
	self.startdeathmatchtask = self.inst:DoTaskInTime(10, function()
		self:StartDeathmatch()
	end)
	self.inst.net:PushEvent("deathmatch_matchstatuschange", 2)
	self.inst.net:PushEvent("deathmatch_timercurrentchange", 10)
	self.inst.net:PushEvent("deathmatch_arenachange", arena_idx[self.arena])
	self.doingreset = true
end

local PICKUP_RADIUS = DEATHMATCH_TUNING.PICKUP_RADIUS
function Deathmatch_Manager:GetPickUpItemList(custompos)
	local result = {}
	
	local count = getPlayerCount(true)
	local pos = custompos or self.inst.centerpoint:GetPosition()
	local nearbyplayers = 0
	local highesthealth = 0
	local lowhealthplayers = {}
	for k, v in pairs(self.players_in_match) do
		if v and v:IsValid() and not v.components.health:IsDead() then
			local playerhealth = v.components.health.currenthealth
			if playerhealth > highesthealth then
				highesthealth = playerhealth
			end
			if v:GetDistanceSqToPoint(pos) <= PICKUP_RADIUS*PICKUP_RADIUS then
				nearbyplayers = nearbyplayers + 1
				if playerhealth < DEATHMATCH_TUNING.EQUALIZER_MAX_HEALTH then
					table.insert(lowhealthplayers, v)
				end
			end
		end
	end
	local perilplayers = {}
	for k,player in pairs(lowhealthplayers) do
		local playerhealth = player.components.health.currenthealth
		local healthdiff = highesthealth-playerhealth
		if healthdiff >= DEATHMATCH_TUNING.EQUALIZER_HEALTH_DIFF then
			table.insert(perilplayers, player)
		end
	end
	if self.enabledarts and (nearbyplayers > 0 and nearbyplayers <= count/2) then
		table.insert(result, "deathmatch_oneusebomb")
	end
	if not arena_configs[self.arena].nopowerpickups then
		for i = 1, math.floor(count/2) do
			table.insert(result, GetRandomItem(arena_configs[self.arena].overridepickups or self.pickupprefabs))
		end
	end
	if self.gamemode ~= 1 then
		local heartcount = 0
		for k, v in pairs(self.spawnedpickups) do
			if v:IsValid() and v.prefab == "deathmatch_reviverheart" then
				heartcount = heartcount + 1
			end
		end
		local heartchance = 1 / (self.revivals+2)
		if heartcount < 3 and math.random()<heartchance then
			table.insert(result, "deathmatch_reviverheart")
		end
	end
	return result, perilplayers
end

function Deathmatch_Manager:DoPickUpSpawn()
	if not self.enablepickups then return end
	local custompos = (arena_configs[self.arena].custom_spawnpoint ~= nil and arena_configs[self.arena].custom_spawnpoint())
	local items_to_spawn, players_in_peril = self:GetPickUpItemList(custompos)
	for i, v in ipairs(items_to_spawn) do
		local pos = custompos or self.inst.centerpoint:GetPosition()
		local offset = nil
		local min_dist = arena_configs[self.arena].min_pickup_dist or 1
		local max_dist = arena_configs[self.arena].max_pickup_dist or 6
		local dist = min_dist + math.random()*(max_dist-min_dist)
		offset = FindValidPositionByFan(math.random()*2*PI, dist, 10,
			function(offset)
				return TheWorld.Map:IsPassableAtPoint((pos+offset):Get())
		end)
		if offset ~= nil then
			local item = SpawnPrefab(v)
			local fx = SpawnPrefab("small_puff")
			item.Transform:SetPosition((pos+offset):Get())
			fx.Transform:SetPosition((pos+offset):Get())
			table.insert(self.spawnedpickups, item)
			if item.Fade ~= nil then
				item:DoTaskInTime(15, item.Fade)
			end
		end
	end
	for k, v in pairs(players_in_peril) do
		local pos = v:GetPosition()
		local offset = FindValidPositionByFan(math.random()*2*PI, 1, 10,
		function(offset)
			return TheWorld.Map:IsPassableAtPoint((pos+offset):Get())
		end)
		if offset ~= nil then
			local item = SpawnPrefab(self.perilpickup)
			local fx = SpawnPrefab("small_puff")
			item.Transform:SetPosition((pos+offset):Get())
			fx.Transform:SetPosition((pos+offset):Get())
			table.insert(self.spawnedpickups, item)
			if item.Fade ~= nil then
				item:DoTaskInTime(15, item.Fade)
			end
		end
	end
end

function Deathmatch_Manager:GetDrowningRespawnPos()
	local center = (self.inst.centerpoint and self.matchinprogress) and self.inst.centerpoint:GetPosition() or self.inst.lobbypoint:GetPosition()
	local dist = arena_configs[self.arena].spawnradius or 12
	local offset = FindValidPositionByFan(math.random()*2*PI, dist, 10,
		function(offset)
			return TheWorld.Map:IsPassableAtPoint((center+offset):Get())
	end) or Vector3(0,0,0)
	return (center+offset):Get()
end

local function SpawnPickUp(inst) --gosh this code is AWFUL
	local self = inst.components.deathmatch_manager
	if self.enablepickups then
		local count = getPlayerCount(true)
		local pos = inst.centerpoint:GetPosition()
		local nearbyplayers = 0
		for k, v in pairs(self.players_in_match) do
			if v and v:IsValid() and not v.components.health:IsDead() and v:GetDistanceSqToPoint(pos) <= 8*8 then
				nearbyplayers = nearbyplayers + 1
			end
		end
		if self.enabledarts and nearbyplayers ~= 0 and nearbyplayers <= getPlayerCount(true)/2 then
			local pickup = SpawnPrefab("deathmatch_oneusebomb")
			local poof = SpawnPrefab("small_puff")
			local pos = inst.centerpoint:GetPosition()
			pos.x = pos.x + (math.random(-300, 300)/100)
			pos.z = pos.z + (math.random(-300, 300)/100)
			if math.random() > 0.5 then
				pos.x = pos.x + 1.5
			else
				pos.x = pos.x - 1.5
			end
			if math.random() > 0.5 then
				pos.z = pos.z + 1.5
			else
				pos.z = pos.z - 1.5
			end
			pickup.Transform:SetPosition(pos:Get())
			poof.Transform:SetPosition(pos:Get())
			table.insert(self.spawnedpickups, pickup)
		end
		for i = 1, math.floor(count/2) do
			local pos = inst.centerpoint:GetPosition()
			local pickup = SpawnPrefab(GetRandomItem(self.pickupprefabs))
			local poof = SpawnPrefab("small_puff")
			pos.x = pos.x + (math.random(-300, 300)/100)
			pos.z = pos.z + (math.random(-300, 300)/100)
			pickup.Transform:SetPosition(pos:Get())
			poof.Transform:SetPosition(pos:Get())
			table.insert(self.spawnedpickups, pickup)
			if pickup.Fade ~= nil then
				pickup:DoTaskInTime(15, pickup.Fade)
			end
		end
	end
end

function Deathmatch_Manager:SetNextArena(arena)
	self.upcoming_arena = (arena == "random" or arena_configs[arena] ~= nil) and arena or "random"
	if not (self.matchinprogress or self.doingreset or self.matchstarting) then
		self.inst.net:PushEvent("deathmatch_arenachange", arena_idx[self.upcoming_arena])
	end
end

function Deathmatch_Manager:SetVotedArena()
	local players = getPlayers(true)
	local votes = {}
	local highest = 0
	for k, v in pairs(players) do
		local choice = v.arenachoice or "atrium"
		if votes[choice] == nil then
			votes[choice] = 1
		else
			votes[choice] = votes[choice] + 1
		end
		if votes[choice] > highest then
			highest = votes[choice]
		end
	end
	local winners = {}
	for arena, n in pairs(votes) do
		if n == highest then
			table.insert(winners, arena)
		end
	end
	if #winners == 1 then
		print(winners[1])
		self:SetNextArena(winners[1])
	end
end

function Deathmatch_Manager:SetVotedMode()
	local players = getPlayers(true)
	local votes = {}
	local highest = 0
	for k, v in pairs(players) do
		local choice = v.modechoice or 1
		if votes[choice] == nil then
			votes[choice] = 1
		else
			votes[choice] = votes[choice] + 1
		end
		if votes[choice] > highest then
			highest = votes[choice]
		end
	end
	local winners = {}
	for mode, n in pairs(votes) do
		if n == highest then
			table.insert(winners, mode)
		end
	end
	if #winners == 1 then
		local winner = winners[1]
		if winner ~= self.gamemode then
			self:SetGamemode(winners[1])
		end
	end
end

function Deathmatch_Manager:BeginMatch()
	self.matchstarting = false
	if self.timertask ~= nil then
		self.timertask:Cancel()
		self.timertask = nil
	end
	self.timer_current = self.timer_time
	self.inst.net:PushEvent("deathmatch_timercurrentchange", self.timer_time)
	self.timertask = self.inst:DoPeriodicTask(1, function()
		if self.timer_current <= 0 then
			self.inst:PushEvent("wehaveawinner", self:GetLeadingPlayer())
			self:StopDeathmatch()
		else
			self.timer_current = self.timer_current - 1
		end
	end)
	self.inst.net:PushEvent("deathmatch_matchstatuschange", 1)
	self.inst.centerpoint = findcenter()
	self.matchinprogress = true
	self.doingreset = false
	if self.pickuptask ~= nil then
		self.pickuptask:Cancel()
		self.pickuptask = nil
	end
	self.pickuptask = self.inst:DoPeriodicTask(10, function() self:DoPickUpSpawn() end)
	for k, v in pairs(self.players_in_match) do
		v:RemoveTag("notarget")
		v.revivals = 0
		v:UpdateRevivalHealth()
	end
	for k, v in pairs(self.spawnedgear) do
		if not v.components.equippable:IsEquipped() then
			v:Remove()
		end
	end
end

function Deathmatch_Manager:Vote(reason, player)
	if reason == "endmatch" then
		if not TableContains(self.voters.endmatch, player.userid) then
			table.insert(self.voters.endmatch, player.userid)
			local numplayers = getPlayerCount()
			local numvotes = #self.voters.endmatch
			if numvotes > numplayers/2 then
				self.voters.endmatch = {}
				self:StopDeathmatch()
			else
				TheNet:Announce(player:GetDisplayName() .. " voted to end this deathmatch.")
			end
		end
	end
end

--todo: for team preference:
--half mode would use a table where reds are on top and blues on bottom
--pairs would group the pre-determined pairs first and everyone else after
--maybe make team grouping only happen when match starts rather than when /dm start is ran?
-- lua does have a sort table function, use that for half
-- (team selection would be part of teamer component or independent variable?
local function sortByRedVBlue(a, b) --true if a comes before b
	return (a.teamchoice == 2 and b.teamchoice ~= 2) or (b.teamchoice == 1 and a.teamchoice ~= 1)
end

local function getFirstTeamWithoutPair() --for 2pt paring
	local players = getPlayers()
	local teamcounts = {}
	for i = 1, #DEATHMATCH_TEAMS do
		teamcounts[i] = 0
	end
	for k, v in pairs(players) do
		local team = v.components.teamer:GetTeam()
		if team ~= 0 then
			teamcounts[team] = teamcounts[team] + 1
		end
	end
	for i, v in ipairs(teamcounts) do
		if v < 2 then
			return i
		end
	end
	--this really shouldn't ever happen in 2pt mode
	return 0
end

function Deathmatch_Manager:GroupTeams(mode)
	local players = ScrambleTable(getPlayers())
	local numplayers = #players
	if mode == "half" then
		if numplayers >= 2 then
			table.sort(players, sortByRedVBlue)
		end
		for i, v in ipairs(players) do
			if i > numplayers/2 then
				v.components.teamer:SetTeam(1)
			else
				v.components.teamer:SetTeam(2)
			end
		end
	elseif mode == "pairs" then
		local teamlessplayers = {}
		for k, v in pairs(players) do
			if v.components.teamer:GetTeam() == 0 then
				table.insert(teamlessplayers, v)
			end
		end
		for i, v in ipairs(teamlessplayers) do
			v.components.teamer:SetTeam(getFirstTeamWithoutPair())
		end
	elseif mode == "ffa" then
		for i, v in ipairs(players) do
			v.components.teamer:SetTeam(0)
		end
	end
end

function Deathmatch_Manager:SetGamemode(mode, onload)
	self.gamemode = mode
	if mode ~= 0 then
		self.allow_teamswitch_user = false
		if not onload then
			if mode == 2 then
				TheNet:Announce(string.format(DEATHMATCH_STRINGS.ANNOUNCE.SETTEAMMODE_RVB, self.gamemodes[mode].name))
			else
				TheNet:Announce(string.format(DEATHMATCH_STRINGS.ANNOUNCE.SETTEAMMODE, self.gamemodes[mode].name))
			end
		end
		self.inst.net:PushEvent("deathmatch_matchmodechange", mode)
	else
		self.allow_teamswitch_user = true
		if not onload then
			TheNet:Announce(DEATHMATCH_STRINGS.ANNOUNCE.SETTEAMMODE_CUSTOM)
		end
		self.inst.net:PushEvent("deathmatch_matchmodechange", 4)
	end
	if self.matchstaring or self.matchinprogress then return end
	for k, v in pairs(getPlayers()) do
		if self.gamemode == 2 then
			v.components.teamer:SetTeam(v.teamchoice)
		else
			v.components.teamer:SetTeam(0)
		end
	end
end

function Deathmatch_Manager:DisbandPairTeam(player)
	local team = player.components.teamer:GetTeam()
	if team == 0 then return end
	for k, v in pairs(getPlayers()) do
		if v ~= player and v.components.teamer:GetTeam() == team then
			v.components.teamer:SetTeam(0)
			if v.pairrequest == player then
				v.pairrequest = nil
			end
			break
		end
	end
	player.components.teamer:SetTeam(0)
	player.pairrequest = nil
end

function Deathmatch_Manager:RequestPairing(doer, target)
	doer.pairrequest = target
	if target.pairrequest == doer then
		self:PresetPair(doer, target)
	end
end

function Deathmatch_Manager:PresetPair(p1, p2)
	self:DisbandPairTeam(p1)
	self:DisbandPairTeam(p2)
	local usedteams = {}
	for i = 1, #DEATHMATCH_TEAMS do
		usedteams[i] = false
	end
	for k, v in pairs(getPlayers()) do
		local team = v.components.teamer:GetTeam()
		if team ~= 0 then
			usedteams[team] = true
		end
	end
	local team = 0
	for i, v in ipairs(usedteams) do
		if not v then
			team = i
			break
		end
	end
	p1.components.teamer:SetTeam(team)
	p2.components.teamer:SetTeam(team)
end

function Deathmatch_Manager:ToggleSpectator(player)
	if player == nil or not player:IsValid() then return end
	local isspectator = player:HasTag("spectator")
	if isspectator then
		player:RemoveTag("spectator")
		MakeSpectator(player, false)
		if self.matchstarting or self.matchinprogress then
			--player.Transform:SetPosition(self.inst.lobbypoint:GetPosition():Get())
			player:DoDeathmatchTeleport(self.inst.lobbypoint:GetPosition())
		end
		self:GiveLobbyInventory(player)
		player:PushEvent("ms_exitspectator")
	else
		player:AddTag("spectator")
		if not player.components.health:IsDead() then
			player.sg:GoToState("idle")
		end
		MakeSpectator(player, true)
		if player.components.inventory.activeitem then
			player.components.inventory:DropItem(player.components.inventory.activeitem)
		end
		for k, v in pairs(player.components.inventory.itemslots) do
			v:Remove()
		end
		for k, v in pairs(player.components.inventory.equipslots) do
			v:Remove()
		end
		if self.matchstarting or self.matchinprogress then
			--player.Transform:SetPosition(self.inst.centerpoint:GetPosition():Get())
			player:DoDeathmatchTeleport(self.inst.centerpoint:GetPosition())
		end
		if not self.doingreset and not self.matchstarting then
			player.components.teamer:SetTeam(0)
		end
		local ingame, idx = TableContains(self.players_in_match, player)
		if ingame then 
			table.remove(self.players_in_match, idx) 
		end
		OnPlayerDeath(self.inst, player)
		player:PushEvent("ms_becamespectator")
	end
	--this is to update the player health badge
	player.components.health:DoDelta(0)
	if (self.doingreset or self.matchstarting) and self.gamemode ~= 0 then
		self:GroupTeams(self.gamemodes[self.gamemode].teammode)
	end
end

function Deathmatch_Manager:OnPlayerRevived(player, source)
	self.revivals = self.revivals + 1
	if player ~= nil then
		player.revivals = (player.revivals or 0) + 1
	end
end

function Deathmatch_Manager:GetRevivalHealthForPlayer(player)
	return math.max(0.5 - (player.revivals or 0)*0.1, 0.25)
end

function Deathmatch_Manager:GetPlayerRevivalTimeMult(reviver)
	if reviver and reviver:HasTag("player") then
		local item = reviver.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		if item and item.prefab == "deathmatch_reviverheart" then
			return 0.5
		end
	end
	return 2
end

function Deathmatch_Manager:GetPlayerRevivalHealthPct(reviver)
	if reviver and reviver:HasTag("player") then
		local item = reviver.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		if item and item.prefab == "deathmatch_reviverheart" then
			return 0.5 / math.pow(2, self.revivals-1)
		end
	end
	return 0.25
end

return Deathmatch_Manager
