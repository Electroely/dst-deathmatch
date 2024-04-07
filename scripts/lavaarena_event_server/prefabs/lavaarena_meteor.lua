local function OnLand(inst)
	local x, _, z = inst.Transform:GetWorldPosition()
	SpawnPrefab("lavaarena_meteor_splash").Transform:SetPosition(x,0,z)
	local splashbase = SpawnPrefab("lavaarena_meteor_splashbase")
	splashbase.Transform:SetPosition(x,0,z)
	splashbase:ListenForEvent("animover", splashbase.Remove)
	local ents = TheSim:FindEntities(x, 0, z, inst.range)
	for _, ent in pairs(ents) do 
		if ent.components.combat and (TheNet:GetPVPEnabled() or not ent:HasTag("player")) and (ent ~= inst.caster)
			and (inst.caster == nil or (inst.caster.components.combat:IsValidTarget(ent) and not inst.caster.components.combat:IsAlly(ent))) then
			inst:OnHit(ent)
		end
	end
	inst:Remove()
end

local function OnHit(inst, target)
	local targetpos = target:GetPosition()
	local instpos = inst:GetPosition()
	local damage = inst.caster ~= nil and inst.caster.components.combat:CalcDamage(target, inst, inst.caster.components.combat.areahitdamagepercent) or inst.components.weapon.damage
	if inst.caster then
		inst.caster:PushEvent("onareaattackother", { target = target, weapon = inst, stimuli = "fire" })
	end
	target.components.combat:GetAttacked(inst.caster, damage, inst, "fire")
	SpawnPrefab("lavaarena_meteor_splashhit").Transform:SetPosition(targetpos:Get())
end

local function meteor_masterpostinit(inst)
	inst.caster = nil
	inst.range = 4
	inst.Meteor = function(inst, caster, pos, weapon)
		inst.caster = caster
		inst.parent = weapon
		inst.Transform:SetPosition(pos:Get())
	end

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(DEATHMATCH_TUNING.FORGE_MAGE_METEOR_DAMAGE)

	inst:AddTag("projectile")
	
	inst.OnHit = OnHit

	inst:ListenForEvent("animover", OnLand)
end

local function splash_masterpostinit(inst)
	inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/meteor_strike")
	inst:ListenForEvent("animover", inst.Remove)
end

local function splashhit_masterpostinit(inst)
	inst:ListenForEvent("animover", inst.Remove)
end

return {
	meteor_postinit = meteor_masterpostinit,
	splash_postinit = splash_masterpostinit,
	splashhit_postinit = splashhit_masterpostinit
}