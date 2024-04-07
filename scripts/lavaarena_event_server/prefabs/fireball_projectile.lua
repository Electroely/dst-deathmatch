local function OnMiss(inst, attacker, target)
	if inst.missremovetask ~= nil then
		inst.missremovetask:Cancel()
		inst.missremovetask = nil
	end
	if inst.misstimeouttask ~= nil then
		inst.misstimeouttask:Cancel()
		inst.misstimeouttask = nil
	end
	inst.missremovetask = inst:DoPeriodicTask(0, function(inst)
		local startpos = inst.components.projectile.start
		local range = inst.components.projectile.range or 4
		local currentpos = inst:GetPosition()
		if distsq(startpos, currentpos) > range*range then
			--local particle = SpawnPrefab("fireball_hit_fx")
			--particle.Transform:SetPosition(currentpos:Get())
			inst:Remove()
		end
	end)
	inst.misstimeouttask = inst:DoTaskInTime(2, inst.Remove)
end

local function common_masterpostinit(inst, speed, hitfx)
	inst.persists = false
	inst.OnEntitySleep = inst.Remove
	
	inst:AddComponent("projectile")
	inst.components.projectile:SetSpeed(speed)
	inst.components.projectile:SetHoming(true)
	inst.components.projectile:SetHitDist(1)
	inst.components.projectile.onhit = function(inst, owner, target)
		SpawnPrefab(hitfx).Transform:SetPosition(inst.Transform:GetWorldPosition())
		inst:Remove()
	end
	inst.components.projectile:SetOnMissFn(OnMiss)
end

local function common_hit_masterpostinit(inst)
	inst:ListenForEvent("animover", inst.Remove)
end

return {
	projectile_postinit = common_masterpostinit,
	fireballhit_postinit = common_hit_masterpostinit,
	blossomhit_postinit = common_hit_masterpostinit,
	gooballhit_postinit = common_hit_masterpostinit,
}