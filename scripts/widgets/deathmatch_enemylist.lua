local Text = require("widgets/text")
local Image = require("widgets/image")
local Widget = require("widgets/widget")
local TeammateHealthBadge = require("widgets/deathmatch_teammatehealthbadge")

local SPACING = 80
local Y_OFFSET = 70

local ALLIES_OFFSET = 520
local ENEMIES_OFFSET = -30

local Deathmatch_EnemyList = Class(Widget, function(self, owner)
	Widget._ctor(self, "Deathmatch_EnemyList")

	self.owner = owner
	
	self.widgets = {}
	self.widgets_allies = {}
	
	self:RefreshWidgets()

	local function refresh()
		self:RefreshWidgets()
	end
	self.inst:ListenForEvent("deathmatchdatadirty", refresh, TheWorld.net)
	self.inst:ListenForEvent("deathmatch_playerhealthdirty", refresh, TheWorld.net)
	self.inst:ListenForEvent("deathmatch_teamdirty", refresh, TheWorld.net)
	self.inst:ListenForEvent("deathmatch_playerinmatchdirty", refresh, TheWorld.net)
	self.inst:ListenForEvent("ms_playerjoined", refresh, TheWorld)
	self.inst:ListenForEvent("ms_playerleft", refresh, TheWorld)
end)

function Deathmatch_EnemyList:GetPlayerTable()
    local ClientObjs = TheNet:GetClientTable()
    if ClientObjs == nil then
        return {}, {}
	end
    --remove dedicate host from player list and add team & hp data
	if TheNet:GetServerIsDedicated() then
		for i, v in ipairs(ClientObjs) do
			if v.performance ~= nil then
				table.remove(ClientObjs, i)
			end
		end
	end
	for k, v in pairs(ClientObjs) do
		v.health = TheWorld.net:GetPlayerHealth(v.userid) or 1
		v.team = TheWorld.net:GetPlayerTeam(v.userid) or 0
	end
	table.sort(ClientObjs, function(a,b)
		if a.team == b.team then
			return a.health > b.health
		end
		if a.team == 0 or b.team == 0 then
			return a.team > b.team
		end
		return a.team < b.team
	end)
	local status = TheWorld.net:GetMatchStatus()
	local is_in_lobby = status == 0 or status == 2
	local allies = {}
	local enemies = {}
	local allyteam = self.owner.components.teamer:GetTeam()
	for i, v in ipairs(ClientObjs) do
		if v.prefab == "" or (v.userid == self.owner.userid) or not (is_in_lobby or TheWorld.net:IsPlayerInMatch(v.userid)) then
			--don't insert
		elseif allyteam ~= 0 and v.team == allyteam then
			table.insert(allies,v)
		else
			table.insert(enemies,v)
		end
	end
    return enemies, allies
end

local function CreateDummyData(character)
	return {
		prefab = character,
		userid = character,
		base_skin = character.."_none",
		userflags = 0,
		name = STRINGS.NAMES[string.upper(character)],
		team = math.random(0,8),
		health = math.random(),
	}
end

local function CreateDummyTable()
	local data = {}
	for k, character in pairs(DST_CHARACTERLIST) do
		table.insert(data, CreateDummyData(character))
	end
	table.sort(data, function(a,b)
		if a.team == b.team then
			return a.health > b.health
		end
		if a.team == 0 or b.team == 0 then
			return a.team > b.team
		end
		return a.team < b.team
	end)
	local allies = {}
	local enemies = {}
	local allyteam = ThePlayer.components.teamer:GetTeam()
	for i, v in ipairs(data) do
		if allyteam ~= 0 and v.team == allyteam then
			table.insert(allies,v)
		else
			table.insert(enemies,v)
		end
	end
	return enemies, allies
end

function Deathmatch_EnemyList:MakeWidgetForPlayer(data)
	local badge = self:AddChild(TeammateHealthBadge(ThePlayer))
	self:SetWidgetToPlayer(badge, data)
	return badge
end

function Deathmatch_EnemyList:SetWidgetToPlayer(badge, data)
	badge:SetPlayer(data)
end

function Deathmatch_EnemyList:RefreshWidgets()
	local players, teammates = self:GetPlayerTable()
	--local players, teammates = CreateDummyTable()
	
	for i = 1, math.max(#players, #self.widgets) do
		if self.widgets[i] ~= nil then
			if players[i] ~= nil then
				self:SetWidgetToPlayer(self.widgets[i], players[i])
			else
				self.widgets[i]:Kill()
				self.widgets[i] = nil
			end
		elseif players[i] ~= nil then
			table.insert(self.widgets, self:MakeWidgetForPlayer(players[i]))
		end
	end

	local teammate_dead = false
	for i = 1, math.max(#teammates, #self.widgets_allies) do
		if self.widgets_allies[i] ~= nil then
			if teammates[i] ~= nil then
				self:SetWidgetToPlayer(self.widgets_allies[i], teammates[i])
			else
				self.widgets_allies[i]:Kill()
				self.widgets_allies[i] = nil
			end
		elseif teammates[i] ~= nil then
			table.insert(self.widgets_allies, self:MakeWidgetForPlayer(teammates[i]))
		end

		if teammates[i] ~= nil and teammates[i].health <= 0 then
			teammate_dead = true
		end
	end
	self.owner.teammate_dead = teammate_dead
	
	--TODO: calculate spacing depending on number of widgets & screen size
	for i, widget in ipairs(self.widgets) do
		if i%2 == 1 then
			widget:SetPosition(ENEMIES_OFFSET-(math.floor(i/2)-1)*SPACING - SPACING*0.5, Y_OFFSET)
		else
			widget:SetPosition(ENEMIES_OFFSET-((i/2)-1)*SPACING, 0)
		end
	end

	for i, widget in ipairs(self.widgets_allies) do
		if i%2 == 1 then
			widget:SetPosition(ALLIES_OFFSET+(math.ceil(i/2)-1)*SPACING, 0)
		else
			widget:SetPosition(ALLIES_OFFSET+((i/2)-1)*SPACING + SPACING*0.5, Y_OFFSET)
		end
	end
end

return Deathmatch_EnemyList