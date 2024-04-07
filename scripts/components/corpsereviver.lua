

local CorpseReviver = Class(function(self, inst)
	self.inst = inst
	
	self.speedmult = 1
	self.extrarevivehealth = 0
end)

function CorpseReviver:GetReviverSpeedMult(target)
	return self.speedmult
end

function CorpseReviver:GetAdditionalReviveHealthPercent()
	return self.extrarevivehealth
end

return CorpseReviver
