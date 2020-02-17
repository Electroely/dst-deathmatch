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

local Deathmatch_LobbyTimer = Class(Widget, function(self, owner)
	self.owner = owner
	Widget._ctor(self, "Deathmatch_LobbyTimer")
	
	self.timer = self:AddChild(Text(NEWFONT_OUTLINE, 40))
	self.timer:SetPosition(100, 310, 0)
	self.timer.StartCounting = function(timer)
		if timer.inst.updatetask ~= nil then
			timer.inst.updatetask:Cancel()
			timer.inst.updatetask = nil
		end
		timer.inst.updatetask = timer.inst:DoPeriodicTask(1, function()
			if self.data.timer_current > 0 then
				self.data.timer_current = self.data.timer_current - 1
				self.timer:Update()
			else
				timer:StopCounting()
			end
		end)
	end
	self.timer.StopCounting = function(timer)
		if timer.inst.updatetask ~= nil then
			timer.inst.updatetask:Cancel()
			timer.inst.updatetask = nil
		end
		self.data.timer_current = 0
		self.timer:Update()
	end
	self.timer.Update = function(timer)
		timer:SetString(tostring(SecondsToTimer(self.data.timer_current)))
	end
end)

function Deathmatch_LobbyTimer:Refresh()

end

return Deathmatch_LobbyTimer