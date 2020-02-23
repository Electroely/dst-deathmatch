local inc = 0
local function atriumkeychanged(inst)
	local self = TheWorld.components.deathmatch_manager
	self.enablepickups = TheWorld.state.atrium_active
end
local fullmoonfn = function(inst)
	inc = inc + 1
	if inc == 2 then
		inst:PushEvent("fakefullmoon", true)
		for k, v in pairs(Ents) do 
			if v.prefab == "pigman" then
				v:DoTaskInTime(math.random(), function() v.components.werebeast:SetWere(30) end)
			end
		end
	elseif inc == 3 then
		inc = 0
		inst:PushEvent("fakefullmoon", false)
		for k, v in pairs(Ents) do 
			if v.prefab == "moonpig" then
				v:DoTaskInTime(math.random(), function() v.components.werebeast:SetNormal() end)
			end
		end
	end
end

local arena_configs = {
	atrium = {
		spawnradius = 20.5,
		--extraitems = { "minerhat" },
		matchstartfn = function()
			local self = TheWorld.components.deathmatch_manager
			if self.atrium_gate == nil then
				for k, v in pairs(Ents) do
					if v.prefab == "atrium_gate" then self.atrium_gate = v end
				end
			end
			if self.atrium_gate.components.trader.enabled then
				self.atrium_gate.components.trader.onaccept(self.atrium_gate)
			end
			self.inst:ListenForEvent("atriumactivechanged", atriumkeychanged)
		end,
		matchendfn = function()
			local self = TheWorld.components.deathmatch_manager
			for k, v in pairs(Ents) do
				if v.prefab == "atrium_key" then
					v:Remove()
				end
			end
			self.inst:RemoveEventCallback("atriumactivechanged", atriumkeychanged)
		end,
	},
	desert = {
		spawnradius = 16
	},
	spring = {
		spawnradius = 16,
		nopickups = true,
	},
	pigvillage = {
		spawnradius = 12,
		nopickups = true,
		matchstartfn = function()
			TheWorld:PushEvent("fakefullmoon", false)
			local self = TheWorld.components.deathmatch_manager
			if self._fullmoontask ~= nil then
				self._fullmoontask:Cancel()
				self._fullmoontask = nil
			end
			if self.glommer == nil or self.glommer.components.health:IsDead() then
				self.glommer = SpawnPrefab("glommer")
				local x, _, z = self.inst.centerpoint:GetPosition():Get()
				self.glommer.Transform:SetPosition(x, 10, z)
			end
			self._fullmoontask = self.inst:DoPeriodicTask(30, fullmoonfn)
		end,
		matchendfn = function()
			local self = TheWorld.components.deathmatch_manager
			if self._fullmoontask ~= nil then
				self._fullmoontask:Cancel()
				self._fullmoontask = nil
			end
			if self.glommer ~= nil and not self.glommer.components.health:IsDead() then
				self.glommer.components.health:Kill()
			end
			inc = -1
			fullmoonfn(self.inst)
		end,
	},
}

local arena_idx = {
	["random"] = 0,
	["atrium"] = 1,
	["desert"] = 2,
	["pigvillage"] = 3,
	["spring"] = 4,
}


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

local lobbyitems = {
	"spear_gungnir",
	"spear_lance",
	"hammer_mjolnir",
	"lavaarena_heavyblade",
	"lavaarena_firebomb",
	"lavaarena_armorheavy",
	"lavaarena_armormediumdamager",
	"lavaarena_armormediumrecharger",
	"lavaarena_rechargerhat",
	"lavaarena_lightdamagerhat",
	"teleporterhat_instant",
}
local function GiveLobbyInventory(player)
	local inv = player.components.inventory
	for k, v in pairs(inv.itemslots) do v:Remove() end
	local neededitems = {}
	for k, v in pairs(lobbyitems) do
		neededitems[v] = true
	end
	for k, v in pairs(inv.equipslots) do
		if TableContains(lobbyitems, v.prefab) then
			neededitems[v.prefab] = false
		else
			v:Remove()
		end
	end
	for k, v in pairs(lobbyitems) do
		if neededitems[v] then
			inv:GiveItem(SpawnPrefab(v), k)
			neededitems[v] = false
		end
	end
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
	OnPlayerDeath(inst)
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
	local self = inst.components.deathmatch_manager
	if self.doingreset then
		TheNet:Announce(self.announcestrings.LATEJOIN)
		player.components.combat.externaldamagetakenmultipliers:SetModifier("deathmatchinvincibility", 0)
		self:ResetDeathmatch()
	else
		player.components.combat.externaldamagetakenmultipliers:SetModifier("deathmatchinvincibility", 0)
		local pos = self.inst.lobbypoint:GetPosition()
		player.Transform:SetPosition(pos:Get())
		if self.matchinprogress or self.matchstarting then
			player:DoTaskInTime(1, function()
				TheNet:SystemMessage(DEATHMATCH_STRINGS.CHATMESSAGES.JOIN_MIDMATCH)
			end)
		end
		GiveLobbyInventory(player)
	end
	if #TheNet:GetClientTable() == 2 then
		player:DoTaskInTime(1, function()
			TheNet:SystemMessage(DEATHMATCH_STRINGS.CHATMESSAGES.JOIN_ALONE)
		end)
	end
end

local function MakeSpectator(player, bool)
	player.components.combat.externaldamagetakenmultipliers:SetModifier("deathmatchinvincibility", 0)
	player:ClearBufferedAction()
	if bool then
		player.AnimState:SetMultColour(0.1,0.1,0.1,0.1)
		player.DynamicShadow:SetSize(0,0)
		player:AddTag("notarget")
		player:AddTag("noclick")
		local phys = player.Physics
		phys:SetCollisionGroup(COLLISION.CHARACTERS)
		phys:ClearCollisionMask()
		phys:CollidesWith(COLLISION.WORLD)
		player:PushEvent("respawnfromcorpse",{quick=true})
		--phys:SetCapsule(0, 0)
		if player.components.health:IsDead() then
			player:PushEvent("respawnfromcorpse",{quick=true})
			player:DoTaskInTime(90*FRAMES, function(player)
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
			player:PushEvent("respawnfromcorpse",{quick=true})
		end
		--phys:SetCapsule(0.5, 1)
	end
end



dm = nil -- gotta remove later
local Deathmatch_Manager = Class(function(self, inst)

	self.inst = inst
	self.timer_time = 600
	self.timer_current = 0
	self.leadingplayer = nil
	
	self.announcestrings = DEATHMATCH_STRINGS.ANNOUNCE
	
	self.itemstable = {
	"spear_gungnir",
	"spear_lance",
	"hammer_mjolnir",
	"lavaarena_heavyblade",
	}
	self.choicegear = {
	"lavaarena_armormediumdamager",
	"lavaarena_armormediumrecharger",
	"lavaarena_armorheavy",
	"lavaarena_lightdamagerhat",
	"lavaarena_rechargerhat",
	}
	self.pickupprefabs = {
	"pickup_lightdamaging",
	"pickup_lightdefense",
	"pickup_lightspeed",
	"pickup_lighthealing",
	"pickup_cooldown",
	--"blowdart_lava_temp"
	}
	self.gamemode = 0
	self.gamemodes = {
	{name="Free For All",teammode="ffa"},
	{name="Red vs. Blue",teammode="half"},
	{name="2-Player Teams",teammode="pairs"},
	}
	
	self.enabled = true
	self.arena = "atrium"
	self.upcoming_arena = "atrium"
	self.enablepickups = true
	self.enabledarts = true
	self.allow_teamswitch_user = true
	self.allow_endmatch_user = true
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
	dm = self -- easier testing ingame
end)


function Deathmatch_Manager:AddItem(prefab)
	table.insert(self.itemstable, prefab)
end

function Deathmatch_Manager:RemoveItem(prefab)
	for k, v in pairs(self.itemstable) do
		if v == prefab then
			table.remove(self.itemstable, k)
			break
		end
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
			if self.damagedealt[v] and self.damagedealt[v] > leadingplayerdamage then
				leadingplayer = v
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
				v.components.combat.externaldamagetakenmultipliers:SetModifier("deathmatchinvincibility", 1)
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
			for k, v in pairs(Ents) do 
				if v.prefab == "balloon" or v.components.inventoryitem then
					v:Remove()
				end
			end
		end
		self.enablepickups = not arena_configs[self.arena].nopickups == true
		local players, spectators = getPlayers()
		for k, v in pairs(players) do 
			local items = deepcopy(self.itemstable)
			AddTable(items, arena_configs[self.arena].extraitems)
			AddTable(items, v.deathmatch_startitems)
			for k2, v2 in pairs(items) do
				local item = SpawnPrefab(v2)
				v.components.inventory:GiveItem(item)
				--if k2 == "autoequip" then v.components.inventory:Equip(item) end
				if item.components.rechargeable then item.components.rechargeable:StartRecharge() end
				if item.components.inventoryitem then table.insert(self.spawneditems, item) end
			end
			for k2, v2 in pairs(self.choicegear) do
				local item = SpawnPrefab(v2)
				v.components.inventory:GiveItem(item)
				local slot = item.components.equippable.equipslot
				if v.components.inventory:GetEquippedItem(slot) == nil then
					v.components.inventory:Equip(item)
				end
				
				table.insert(self.spawnedgear, item)
			end
			--[[if arena_configs[self.arena].extraitems ~= nil then
				for k2, v2 in pairs(arena_configs[self.arena].extraitems) do
					local item = SpawnPrefab(v2)
					v.components.inventory:GiveItem(item)
					if item.components.rechargeable then item.components.rechargeable:StartRecharge() end
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
				self.inst:PushEvent("startchoosinggear")
				local theta = (k/getPlayerCount()* 2 * PI)
				local radius = arena_configs[self.arena] ~= nil and arena_configs[self.arena].spawnradius or 10
				local offset = GetValidPoint(pos, theta, radius)
				if offset ~= nil then
					offset.x = offset.x + pos.x
					offset.z = offset.z + pos.z
					v.Transform:SetPosition(offset.x, 0, offset.z)
					v:SnapCamera()
					if DM_FADE then
						v:ScreenFade(false)
						v:ScreenFade(true, 1)
					end
				end
			end
			table.insert(self.players_in_match, v)
			v.components.locomotor:SetExternalSpeedMultiplier(self.inst, "deathmatch_speedmult", 0)
		end
		for k, v in pairs(spectators) do
			--MakeSpectator(v, true)
			v.Transform:SetPosition(self.inst.centerpoint:GetPosition():Get())
			v:SnapCamera()
			if DM_FADE then
				v:ScreenFade(false)
				v:ScreenFade(true, 1)
			end
		end
		if arena_configs[self.arena] and arena_configs[self.arena].matchstartfn then
			arena_configs[self.arena].matchstartfn()
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
	if self.gamemode == 0 then
		self.allow_teamswitch_user = true
	end
	for k, v in pairs(AllPlayers) do
		v:DoTaskInTime(5, function(v)
			v:PushEvent("respawnfromcorpse",{quick=true, delay = 1})
			if not v.components.health:IsDead() then v.sg:GoToState("idle") end
			if v:HasTag("spectator") and not v:HasTag("spectator_perma") then
				self:ToggleSpectator(v)
			end
			local pos = self.inst.lobbypoint:GetPosition()
			local theta = (k/#AllPlayers * 2 * PI)
			local radius = 7
			local offset = GetValidPoint(pos, theta, radius)
			if offset ~= nil then
				offset.x = offset.x + pos.x
				offset.z = offset.z + pos.z
				v.Transform:SetPosition(offset.x, 0, offset.z)
				v:SnapCamera()
				if DM_FADE then
					v:ScreenFade(false)
					v:ScreenFade(true, 1)
				end
				GiveLobbyInventory(v)
			end
			v:DoTaskInTime(5, function(v)
			v.components.combat.externaldamagetakenmultipliers:SetModifier("deathmatchinvincibility", 0)
			end)
		end)
	end
	self.players_in_match = {}
end


function Deathmatch_Manager:ResetDeathmatch()
	if self.upcoming_arena == "random" then
		self.arena = GetRandomItem({"atrium", "desert", "pigvillage"})
	else
		self.arena = self.upcoming_arena
	end
	TheNet:Announce(self.announcestrings.MATCHRESET)
	self.voters.endmatch = {}
	self.damagedealt = {}
	self.matchinprogress = false
	if self.pickuptask ~= nil then
		self.pickuptask:Cancel()
		self.pickuptask = nil
	end
	if self.gamemode ~= 0 and self.gamemode <= #self.gamemodes then
		self:GroupTeams(self.gamemodes[self.gamemode].teammode)
	end
	if self.gamemode == 0 then
		self.allow_teamswitch_user = false
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

local function SpawnPickUp(inst)
	local self = inst.components.deathmatch_manager
	if self.enablepickups then
		local count = getPlayerCount(true)
		local pos = inst.centerpoint:GetPosition()
		local nearbyplayers = 0
		for k, v in pairs(self.players_in_match) do
			if v and v:IsValid() and not v.components.health:IsDead() and v:GetDistanceSqToPoint(pos) <= 25 then
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
			self:StopDeathmatch()
			self.inst:PushEvent("wehaveawinner", self:GetLeadingPlayer())
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
	self.pickuptask = self.inst:DoPeriodicTask(10, SpawnPickUp)
	for k, v in pairs(self.players_in_match) do
		v:RemoveTag("notarget")
		self.inst:PushEvent("donechoosinggear")
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

function Deathmatch_Manager:GroupTeams(mode)
	local players = ScrambleTable(getPlayers())
	local numplayers = #players
	if mode == "half" then
		for i, v in ipairs(players) do
			if i > numplayers/2 then
				v.components.teamer:SetTeam(1)
			else
				v.components.teamer:SetTeam(2)
			end
		end
	elseif mode == "pairs" then
		for i, v in ipairs(players) do
			v.components.teamer:SetTeam(math.ceil(i/2))
		end
	elseif mode == "ffa" then
		for i, v in ipairs(players) do
			v.components.teamer:SetTeam(0)
		end
	end
end

function Deathmatch_Manager:SetGamemode(mode)
	self.gamemode = mode
	if mode ~= 0 then
		self.allow_teamswitch_user = false
		TheNet:Announce(string.format(DEATHMATCH_STRINGS.ANNOUNCE.SETTEAMMODE, self.gamemodes[mode].name))
		self.inst.net:PushEvent("deathmatch_matchmodechange", mode)
	else
		self.allow_teamswitch_user = true
		TheNet:Announce(DEATHMATCH_STRINGS.ANNOUNCE.SETTEAMMODE_CUSTOM)
		self.inst.net:PushEvent("deathmatch_matchmodechange", 4)
	end
end

function Deathmatch_Manager:ToggleSpectator(player)
	if player == nil or not player:IsValid() then return end
	local isspectator = player:HasTag("spectator")
	if isspectator then
		player:RemoveTag("spectator")
		MakeSpectator(player, false)
		if self.matchstarting or self.matchinprogress then
			player.Transform:SetPosition(self.inst.lobbypoint:GetPosition():Get())
		end
		GiveLobbyInventory(player)
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
			player.Transform:SetPosition(self.inst.centerpoint:GetPosition():Get())
		end
		if not self.doingreset and not self.matchstarting then
			player.components.teamer:SetTeam(0)
		end
		local ingame, idx = TableContains(self.players_in_match, player)
		if ingame then 
			table.remove(self.players_in_match, idx) 
		end
		OnPlayerDeath(self.inst, player)
	end
	if (self.doingreset or self.matchstarting) and self.gamemode ~= 0 then
		self:GroupTeams(self.gamemodes[self.gamemode].teammode)
	end
end

return Deathmatch_Manager
