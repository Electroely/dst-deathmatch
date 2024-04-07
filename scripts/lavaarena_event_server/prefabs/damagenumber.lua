local function SetDirty(netvar, val)
	netvar:set_local(val)
	netvar:set(val)
end

local function master_postinit(inst)
	inst.Push = function(inst, attacker, target, damage, islarge)
		inst.entity:SetParent(attacker.entity)
		SetDirty(inst.target, target)
		SetDirty(inst.damage, damage)
		SetDirty(inst.large, islarge)
		inst:DoTaskInTime(1, inst.Remove)
		if not TheNet:IsDedicated() and attacker == ThePlayer then
			inst.PushDamageNumber(attacker, target, math.floor(damage), islarge)
		end
	end
end

return {
	master_postinit = master_postinit
}
