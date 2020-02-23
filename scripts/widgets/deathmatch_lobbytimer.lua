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

	self.timer = self:AddChild(Text(NEWFONT_OUTLINE, 30))
	self.timer:SetString("A new match starts in "..tostring(SecondsToTimer(TheWorld.net.components.deathmatch_timer:GetTime())).."! Hurry up!")
	
	self.inst:DoPeriodicTask(5*FRAMES, function()
		self:OnUpdate()
	end)
	
	if TheWorld.net.deathmatch_netvars.globalvars.matchstatus:value() ~= 2 then
		self:Hide()
	end
	
	self.OnNetStatusDirty = function(wrld)
		if TheWorld.net.deathmatch_netvars.globalvars.matchstatus:value() == 2 then
			self:Show()
		else
			self:Hide()
		end
	end
	TheWorld.net:ListenForEvent("deathmatch_matchstatusdirty", self.OnNetStatusDirty)
end)

function Deathmatch_LobbyTimer:OnUpdate()
	if self.shown then
		self.timer:SetString("A new match starts in "..tostring(SecondsToTimer(TheWorld.net.components.deathmatch_timer:GetTime())).."! Hurry up!")
	end
end

function Deathmatch_LobbyTimer:Kill(...)
	TheWorld.net:RemoveEventCallback("deathmatch_matchstatusdirty", self.OnNetStatusDirty)
	return Widget.Kill(self, ...)
end

return Deathmatch_LobbyTimer
