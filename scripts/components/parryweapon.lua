local ParryWeapon = Class(function(self, inst)
	self.inst = inst
	
	self.absorb = 0.9
	self.blockangle = 150
end)

function ParryWeapon:OnPreParry(user)
end

--[[(weapon and weapon.prefab == "hammer_mjolnir" and stimuli and stimuli == "electric") or ]]

function ParryWeapon:TryParry(user, attacker, damage, weapon, stimuli)
	local sourcepos = weapon and weapon:GetPosition() or (attacker and attacker:GetPosition())
	local angle = user:GetAngleToPoint(sourcepos) - user:GetRotation()
	--print("block attempt: "..angle)
	
	if weapon and weapon.prefab == "spear_gungnir" and stimuli == "fire" then
		return false --pyre poker pierces parry
	end
	
	if (angle > (self.blockangle/2) or angle < -(self.blockangle/2)) then
		return false
	else
		if attacker and attacker.components.combat and not (weapon and weapon:HasTag("projectile")) then
			attacker.components.combat:GetAttacked(user, damage, self.inst, stimuli == "kb" and "kb" or "electric")
		end
		return true
	end
end

return ParryWeapon
