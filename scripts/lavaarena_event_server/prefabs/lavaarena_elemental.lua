local RANGE = 8

local function Retarget(inst)
	local target = FindEntity(inst, RANGE+4, function(guy)
		return guy ~= inst 
		and (guy.components.health == nil or not guy.components.health:IsDead()) 
		and (not inst.components.combat:IsAlly(guy))
		and (inst.components.teamer == nil or not inst.components.teamer:IsTeamedWith(guy))
		and (inst:GetDistanceSqToPoint(guy.Transform:GetWorldPosition()) < inst.components.combat:CalcAttackRangeSq(guy))
	end, {"_combat"}, nil, {"player","deathmatch_minion"})
	return target
end
local function KeepTarget(inst, target)
	return target ~= nil
		and target.components.combat ~= nil
		and target.components.health ~= nil
		and not target.components.health:IsDead()
		and inst:GetDistanceSqToPoint(target.Transform:GetWorldPosition()) < inst.components.combat:CalcAttackRangeSq(target)
end
local function OnNewTarget(inst, data)
    if data and data.target then
        inst.components.combat:TryAttack()
    end
end
local function OnHit(inst, attacker, damage, spdamage)
	if inst.components.follower and attacker == inst.components.follower:GetLeader() then
		inst.components.health:Kill()
	end
end
local function OnNear(inst)
	inst.components.combat:TryRetarget()
end
local MAX_DAMAGE_PENALTY = DEATHMATCH_TUNING.FORGE_MAGE_SUMMON_DAMAGE_PENALTY
local HITS_DAMAGE_PENALTY = DEATHMATCH_TUNING.FORGE_MAGE_SUMMON_DAMAGE_PENALTY_HITS
local function onhitother(inst, target, damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
	if target and target:HasTag("player") then
		inst.attacks = inst.attacks + 1
		inst.components.combat.externaldamagemultipliers:SetModifier("existencepenalty", 1-(MAX_DAMAGE_PENALTY * (math.clamp(inst.attacks, 1, HITS_DAMAGE_PENALTY)/HITS_DAMAGE_PENALTY)))
	end
	if target and inst.caster then
		local dmgnum = SpawnPrefab("damagenumber")
		if dmgnum.Push ~= nil then
			dmgnum:Push(inst.caster, target, damageresolved or damage, false)
		else
			dmgnum:Remove()
		end
		TheWorld:PushEvent("registerdamagedealt", {player = inst.caster, damage = damageresolved or damage})
	end
end
local function OnSwing(inst, attacker, target)
	local offset = (target:GetPosition() - attacker:GetPosition()):GetNormalized()*1.5
	local particle = SpawnPrefab("fireball_hit_fx")
	particle.Transform:SetPosition((attacker:GetPosition() + offset):Get())
	particle.AnimState:SetScale(0.8,0.8)
end
local function OnProjectileLaunched(inst, attacker, target, proj)
	if proj.components.projectile then
		proj.components.projectile:SetRange(RANGE)
	end
end
local function MakeWeapon(inst)
    if inst.components.inventory ~= nil and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local weapon = CreateEntity()
        --[[Non-networked entity]]
        weapon.entity:AddTransform()
        weapon:AddComponent("weapon")
        weapon.components.weapon:SetDamage(inst.components.combat.defaultdamage)
        weapon.components.weapon:SetRange(RANGE, RANGE+4)
        weapon.components.weapon:SetProjectile("fireball_projectile")
		weapon.components.weapon:SetOnProjectileLaunch(OnSwing)
		weapon.components.weapon:SetOnProjectileLaunched(OnProjectileLaunched)
        weapon:AddComponent("inventoryitem")
        weapon.persists = false
        weapon.components.inventoryitem:SetOnDroppedFn(inst.Remove)
        weapon:AddComponent("equippable")
        weapon:AddTag("nosteal")

        inst.components.inventory:Equip(weapon)
    end
end

local brain = require("brains/lavaarena_elementalbrain")

local function SetCaster(inst, caster)
	inst.caster = caster
	if inst.components.combat and caster and caster.components.combat then
		--inherit damage modifiers at the time of casting
		inst.components.combat.externaldamagemultipliers:SetModifier(caster, caster.components.combat.externaldamagemultipliers:Get()) 
	end
	if caster then
		inst.overridepkname = caster:GetDisplayName().."'s "..inst.name
	end
end

local function master_postinit(inst)
	inst:RemoveTag("NOCLICK")
	inst:RemoveTag("companion")
	inst:AddTag("rocky") --hit sound
	inst:AddTag("ignoreattackerlimit")
	inst:AddTag("deathmatch_minion")

	inst.attacks = 0

	inst:AddComponent("inventory") --for range attacks

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(DEATHMATCH_TUNING.FORGE_MAGE_SUMMON_HEALTH)

	inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(DEATHMATCH_TUNING.FORGE_MAGE_SUMMON_DAMAGE)
    inst.components.combat:SetAttackPeriod(0)
	inst.components.combat:SetRange(0, 0)
    inst.components.combat:SetRetargetFunction(0.25, Retarget)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.NEVER)
	inst.components.combat:SetOnHit(OnHit)
	inst.components.combat.onhitotherfn = onhitother
	MakeWeapon(inst)

	inst:AddComponent("follower")
	inst.components.follower:KeepLeaderOnAttacked()

	inst:AddComponent("playerprox")
	inst.components.playerprox:SetOnPlayerNear(OnNear)
	inst.components.playerprox:SetDist(RANGE, RANGE)
	inst.components.playerprox:Schedule(4*FRAMES)

	inst:AddComponent("colouradder")

	inst:ListenForEvent("newcombattarget", OnNewTarget)

	inst.SetCaster = SetCaster

	inst:SetStateGraph("SGlavaarena_elemental")
	inst:SetBrain(brain)
end

return {master_postinit=master_postinit}