local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_spear_gungnir", "swap_spear_gungnir")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
	DoEquipCooldown(inst)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function PyrePoker(inst, caster, pos)
	caster:PushEvent("combat_lunge", {
		targetpos = pos,
		weapon = inst
	})
	return true
end

local function onlungedfn(inst)
	if inst.components.rechargeable then
		inst.components.rechargeable:Discharge(DEFAULT_COOLDOWN_TIME)
	end
end

local function spear_masterpostinit(inst)
	inst:AddComponent("aoespell")
	inst.components.aoespell:SetSpellFn(PyrePoker)
	
	inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(function(inst) inst.components.aoetargeting:SetEnabled(false) end)
    inst.components.rechargeable:SetOnChargedFn(function(inst) inst.components.aoetargeting:SetEnabled(true) end)
	
	inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DEATHMATCH_TUNING.FORGE_MELEE_DAMAGE)
	inst.components.weapon:SetOnAttack(function(inst, attacker, target) --[[SpawnPrefab("weaponsparks_fx"):SetPosition(attacker, target)]] end)
	
	inst:AddComponent("aoeweapon_lunge")
    inst.components.aoeweapon_lunge:SetDamage(DEATHMATCH_TUNING.FORGE_MELEE_PIKE_DAMAGE)
    inst.components.aoeweapon_lunge:SetSideRange(1)
	inst.components.aoeweapon_lunge:SetStimuli("fire")
    --inst.components.aoeweapon_lunge:SetOnLungedFn(Lightning_OnLunged)
    --inst.components.aoeweapon_lunge:SetOnHitFn(Lightning_OnLungedHit)
    inst.components.aoeweapon_lunge:SetWorkActions()
    inst.components.aoeweapon_lunge:SetTags("_combat")
	inst.components.aoeweapon_lunge:SetTrailFX("spear_gungnir_lungefx", 0.6)
	inst.components.aoeweapon_lunge:SetOnLungedFn(onlungedfn)
	
	inst:AddComponent("inspectable")
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "spear_gungnir"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
end

return {
	master_postinit = spear_masterpostinit
}
