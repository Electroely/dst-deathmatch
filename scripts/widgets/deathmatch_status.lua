local function SecondsToTimer(secs) 
	if secs ~= nil and type(secs) == "number" then 
		local mins = math.floor(secs/60) 
		secs = secs - (mins*60) 
		return string.format("%02d", mins)..":"..string.format("%02d", secs)
	end 
	return "00:00" 
end 
local DEATHMATCH_GAMEMODES = {
	{name="Free For All"},
	{name="Red vs. Blue"},
	{name="2-Player Teams"},
	{name="Custom Teams"}
}

local ARENAS = {
	"Random",
	"Atrium",
	"Desert",
	"Pig Village",
	"Spring Island",
	"The Shoal", --malbatross
	"Lunar Grotto",
}

local Text = require("widgets/text")
local Widget = require("widgets/widget")

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
	
	self.title = self:AddChild(Text(NEWFONT_OUTLINE, 30, "Deathmatch Status:"))
	
	self.status = self:AddChild(Text(NEWFONT_OUTLINE, 20))
	self.status:SetPosition(-98, -25)
	self.status.Update = function(status)
		local regionsizeold_x, _ = status:GetRegionSize()
		if self.data.match_status == 0 then
			status:SetString("Waiting for next match...")
		elseif self.data.match_status == 1 then
			status:SetString("Match in progress!")
		elseif self.data.match_status == 2 then
			status:SetString("Preparing next match...")
		elseif self.data.match_status == 3 then
			status:SetString("Starting next match...")
		end
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
	self.mode.Update = function(mode)
		local regionsizeold_x, _ = mode:GetRegionSize()
		self.mode:SetString(DEATHMATCH_GAMEMODES[self.data.match_mode].name)
		if mode:GetRegionSize() ~= nil then
			if regionsizeold_x > 999999 or regionsizeold_x < -99999 then
				regionsizeold_x = 0 
			end
			local x, y, z = mode:GetPosition():Get()
			local xoffset, _ = mode:GetRegionSize()
			xoffset = (xoffset/2) 
			mode:SetPosition((x-regionsizeold_x/2)+xoffset, y, z)
		end
	end
	
	self.timer = self:AddChild(Text(NEWFONT_OUTLINE, 40))
	self.timer:SetPosition(0, -75)
	self.timer.inst:DoPeriodicTask(1/2, function()
		self.timer:SetString(tostring(SecondsToTimer(TheWorld.net.components.deathmatch_timer:GetTime())))
	end)
	
	self.timer:SetString(tostring(SecondsToTimer(TheWorld.net.components.deathmatch_timer:GetTime())))
	
	self.arena = self:AddChild(Text(NEWFONT_OUTLINE, 20))
	self.arena:SetPosition(50, -45)
	self.arena.Update = function(arenastr)
		arenastr:SetString("|  " .. ARENAS[self.data.arena+1])
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
end

return Deathmatch_Status
