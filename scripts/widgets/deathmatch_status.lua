local function SecondsToTimer(secs) 
	if secs ~= nil and type(secs) == "number" then 
		local mins = math.floor(secs/60) 
		secs = secs - (mins*60) 
		return string.format("%02d", mins)..":"..string.format("%02d", secs)
	end 
	return "00:00" 
end 
local DEATHMATCH_GAMEMODES = { --TODO
	{name=DEATHMATCH_STRINGS.TEAMMODE_FFA},
	{name=DEATHMATCH_STRINGS.TEAMMODE_RVB},
	{name=DEATHMATCH_STRINGS.TEAMMODE_2PT},
	{name=DEATHMATCH_STRINGS.TEAMMODE_CUSTOM}
}
local arena_defs = require("prefabs/arena_defs")

local warnings = {
	{
		fn = function()
			return ThePlayer and ThePlayer:HasTag("afk")
		end,
		str = DEATHMATCH_STRINGS.WARNINGS.AFK_AUTO,
	},
	{
		fn = function()
			local matchstatus = TheWorld.net:GetMatchStatus()
			local in_lobby = matchstatus == DEATHMATCH_MATCHSTATUS.IDLE or matchstatus == DEATHMATCH_MATCHSTATUS.PREPARING
			return in_lobby and ThePlayer and ThePlayer:HasTag("spectator_perma")
		end,
		str = DEATHMATCH_STRINGS.WARNINGS.AFK_MANUAL,
	},
	{
		fn = function()
			return ThePlayer and ThePlayer.teammate_dead
		end,
		str = DEATHMATCH_STRINGS.WARNINGS.REVIVE_TEAMMATE,
	},
	{
		fn = function()
			return ThePlayer and TheSkillTree:GetAvailableSkillPoints(ThePlayer.prefab) > 0
		end,
		str = DEATHMATCH_STRINGS.WARNINGS.SKILLTREE,
	}
}

local MODE_ARENA_SEPARATOR = 0
local SEPARATOR_SPACING = 10
local WARNINGS_OFFSET = -110
local WARNINGS_SPACING = -30
local Text = require("widgets/text")
local Widget = require("widgets/widget")
local strings = DEATHMATCH_STRINGS.STATUS

local Deathmatch_Status = Class(Widget, function(self, owner)

	self.owner = owner
	Widget._ctor(self, "Deathmatch_Status")
	self.data = {
		timer_time = 300,
		timer_current = 0,
		match_status = 0, -- 0=waiting 4 next match, 1=match in progress, 2=doing reset
		match_mode = 1,
		arena = 0, -- 0= random, next numbs are atrium, desert, pigvillage
	}
	
	self.title = self:AddChild(Text(NEWFONT_OUTLINE, 30, strings.TITLE))
	
	self.status = self:AddChild(Text(NEWFONT_OUTLINE, 20))
	self.status:SetPosition(-98, -25)
	self.status.Update = function(status)
		local regionsizeold_x, _ = status:GetRegionSize()
		status:SetString(strings.MATCHSTATUS[self.data.match_status])
		if status:GetRegionSize() ~= nil then
			if regionsizeold_x > 999999 or regionsizeold_x < -99999 then
				regionsizeold_x = 0 
			end
			local x, y, z = status:GetPosition():Get()
			local xoffset, _ = status:GetRegionSize()
			xoffset = (xoffset/2) 
			status:SetPosition((x-regionsizeold_x/2)+xoffset, y, z)
		end
	end
	
	self.mode = self:AddChild(Text(NEWFONT_OUTLINE, 20))
	self.mode:SetPosition(-98, -45)
	--self.mode:SetHAlign(ANCHOR_RIGHT)
	self.mode.Update = function(mode)
		mode:SetString(DEATHMATCH_GAMEMODES[self.data.match_mode].name)
		local regionsize_x, _ = mode:GetRegionSize()
		local pos = mode:GetPosition()
		local xpos = MODE_ARENA_SEPARATOR - regionsize_x/2 - SEPARATOR_SPACING
		mode:SetPosition(xpos, pos.y, pos.z)
	end
	
	self.timer = self:AddChild(Text(NEWFONT_OUTLINE, 40))
	self.timer:SetPosition(0, -75)
	self.timer.inst:DoPeriodicTask(1/2, function()
		self.timer:SetString(tostring(SecondsToTimer(TheWorld.net.components.deathmatch_timer:GetTime())))
	end)
	
	self.timer:SetString(tostring(SecondsToTimer(TheWorld.net.components.deathmatch_timer:GetTime())))
	
	self.arena = self:AddChild(Text(NEWFONT_OUTLINE, 20))
	self.arena:SetPosition(50, -45)
	--self.mode:SetHAlign(ANCHOR_LEFT)
	self.arena.Update = function(arenastr)
		arenastr:SetString(arena_defs.CONFIGS[arena_defs.IDX[self.data.arena]].name)
		local regionsize_x, _ = arenastr:GetRegionSize()
		local pos = arenastr:GetPosition()
		local xpos = MODE_ARENA_SEPARATOR + regionsize_x/2 + SEPARATOR_SPACING
		arenastr:SetPosition(xpos, pos.y, pos.z)
	end

	self.separator = self:AddChild(Text(NEWFONT_OUTLINE, 20, "|"))
	self.separator:SetPosition(MODE_ARENA_SEPARATOR, -45)

	self.warnings = {}
	for k, v in pairs(warnings) do
		local str = self:AddChild(Text(NEWFONT_OUTLINE, 35, v.str, {1,0.2,0.2,1}))
		table.insert(self.warnings, str)
		str:Hide()
	end
end)

function Deathmatch_Status:Refresh()
	if TheWorld.net.deathmatch_netvars and TheWorld.net.deathmatch_netvars.globalvars ~= nil then
		local data = TheWorld.net.deathmatch_netvars.globalvars
		self.data.timer_time = data.timertime:value()
		self.data.match_mode = data.matchmode:value()
		self.data.match_status = data.matchstatus:value()
		self.data.arena = data.arena:value()
	end
	
	self.status:Update()
	self.mode:Update()
	self.arena:Update()

	local hidden_warnings = 0
	for k, v in pairs(warnings) do
		if v.fn() then
			self.warnings[k]:Show()
			self.warnings[k]:SetPosition(0, WARNINGS_OFFSET + WARNINGS_SPACING*(k-hidden_warnings-1))
		else
			self.warnings[k]:Hide()
			hidden_warnings = hidden_warnings + 1
		end
	end
end

return Deathmatch_Status
