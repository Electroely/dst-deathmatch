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

local Deathmatch_LobbyTimer = Class(Widget, function(self)
	Widget._ctor(self, "Deathmatch_LobbyTimer")

	self.timer = self:AddChild(Text(NEWFONT_OUTLINE, 40))
	self.timer:SetString(tostring(SecondsToTimer(TheWorld.net.components.deathmatch_timer:GetTime())))
	
	self.timer.inst:DoPeriodicTask(1/2, function()
		if TheWorld.net.deathmatch_netvars.globalvars.matchstatus:value() == 0 then
			self.timer:Show()
			self:OnUpdate()
		else
			self.timer:Hide()
		end
	end)
end)

function Deathmatch_LobbyTimer:OnUpdate()
	self.timer:SetString(tostring(SecondsToTimer(TheWorld.net.components.deathmatch_timer:GetTime())))
end

return Deathmatch_LobbyTimer