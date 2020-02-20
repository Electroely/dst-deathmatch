local Deathmatch_Timer = Class(function(self, inst)
	self.inst = inst
	self.timer_current = 0
	
	inst:DoPeriodicTask(1, function()
		if self.timer_current > 0 then
			self.timer_current = self.timer_current - 1
		end
	end)
end)

function Deathmatch_Timer:SetTime(time)
	self.timer_current = time
end

function Deathmatch_Timer:GetTime()
	return self.timer_current
end

return Deathmatch_Timer
