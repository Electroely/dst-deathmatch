local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_hammer_mjolnir", "swap_hammer_mjolnir")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
	DoEquipCooldown(inst)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function AnvilStrike(inst, caster, pos)
	caster:PushEvent("combat_leap", {
		targetpos = pos,
		weapon = inst
	})
	return true
end

local function OnLeaptFn(inst, doer, startingpos, targetpos)
	local fx = SpawnPrefab("hammer_mjolnir_crackle")
	fx:SetTarget(doer)
	if inst.components.rechargeable then
		inst.components.rechargeable:Discharge(DEFAULT_COOLDOWN_TIME)
	end
end
local function OnLeapHitFn(inst, doer, target)
	local fx = SpawnPrefab("cracklehitfx")
	fx:SetTarget(target)
end

local function hammer_masterpostinit(inst)
	inst:AddComponent("aoespell")
	inst.components.aoespell:SetSpellFn(AnvilStrike)
	
	inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(function(inst) inst.components.aoetargeting:SetEnabled(false) end)
    inst.components.rechargeable:SetOnChargedFn(function(inst) inst.components.aoetargeting:SetEnabled(true) end)
	
	inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DEATHMATCH_TUNING.FORGE_MELEE_DAMAGE)
	inst.components.weapon.electric_damage_mult = 1
	inst.components.weapon:SetOnAttack(function(inst, attacker, target) --[[SpawnPrefab("weaponsparks_fx"):SetPosition(attacker, target)]] end)
	
	inst:AddComponent("aoeweapon_leap")
	inst.components.aoeweapon_leap:SetDamage(DEATHMATCH_TUNING.FORGE_MELEE_HAMMER_DAMAGE)
	inst.components.aoeweapon_leap:SetAOERadius(4.1)
	inst.components.aoeweapon_leap:SetOnLeaptFn(OnLeaptFn)
	inst.components.aoeweapon_leap:SetOnHitFn(OnLeapHitFn)
	inst.components.aoeweapon_leap:SetStimuli("electric")
    inst.components.aoeweapon_leap:SetWorkActions()
    inst.components.aoeweapon_leap:SetTags("_combat")
	
	inst:AddComponent("inspectable")
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "hammer_mjolnir"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
end

local function crackle_masterpostinit(inst)
	inst.persists = false
	inst:ListenForEvent("animover", inst.Remove)
	inst.SetTarget = function(inst, target)
		inst.Transform:SetPosition(target:GetPosition():Get())
		local fx = SpawnPrefab("hammer_mjolnir_cracklebase")
		fx.Transform:SetPosition(target:GetPosition():Get())
		fx:DoTaskInTime(2, fx.Remove)
		inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/hammer")
	end
end

local function cracklehit_masterpostinit(inst)
	inst.persists = false
	
	inst.SetTarget = function(inst, target)
		inst.Transform:SetPosition(target:GetPosition():Get())
		if inst.SoundEmitter then inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/electric") end
		if target:HasTag("largecreature") then inst.AnimState:SetScale(2, 2) end
	end

	inst:ListenForEvent("animover", inst.Remove)
end

return {
	hammer_postinit = hammer_masterpostinit,
	crackle_postinit = crackle_masterpostinit,
	cracklehit_postinit = cracklehit_masterpostinit
}