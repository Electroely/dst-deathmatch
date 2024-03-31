local Text = require("widgets/text")
local Widget = require("widgets/widget")

local function SecondsToTimer(secs) 
	if secs ~= nil and type(secs) == "number" then 
		local mins = math.floor(secs/60) 
		secs = secs - (mins*60) 
		return string.format("%02d", mins)..":"..string.format("%02d", secs)
	end 
	return "00:00" 
end

local function TimerString(secs)
	local timer = SecondsToTimer(secs)
	return string.format(DEATHMATCH_STRINGS.MATCH_STARTING_HURRY, timer)
end

local Deathmatch_LobbyTimer = Class(Widget, function(self)
	Widget._ctor(self, "Deathmatch_LobbyTimer")

	self.timer = self:AddChild(Text(NEWFONT_OUTLINE, 25))
	self.timer:SetString("A new match starts in "..tostring(SecondsToTimer(TheWorld.net.components.deathmatch_timer:GetTime())).."! Hurry up!")
	
	if TheWorld.net:GetMatchStatus() ~= 2 then
		self:Hide()
	end
	
	self.OnNetStatusDirty = function(wrld)
		if TheWorld.net:GetMatchStatus() == 2 then
			self:Show()
			self:StartUpdating()
		else
			self:Hide()
			self:StopUpdating()
		end
	end
	self.inst:ListenForEvent("deathmatch_matchstatusdirty", self.OnNetStatusDirty, TheWorld.net)
end)

function Deathmatch_LobbyTimer:OnUpdate()
	if self.shown then
		self.timer:SetString("A new match starts in "..tostring(SecondsToTimer(TheWorld.net.components.deathmatch_timer:GetTime())).."! Hurry up!")
	end
end

return Deathmatch_LobbyTimer
