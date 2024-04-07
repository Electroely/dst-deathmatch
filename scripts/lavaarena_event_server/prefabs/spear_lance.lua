local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_spear_lance", "swap_spear_lance")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
	DoEquipCooldown(inst)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function SkyDive(inst, caster, pos)
	caster:PushEvent("combat_superjump", {
		targetpos = pos,
		weapon = inst
	})
	caster.components.talker:Say("")
	return true
end

local function OnLeaptFn(inst, doer, startingpos, targetpos)
	local fx = SpawnPrefab("superjump_fx")
	local x,y,z = doer.Transform:GetWorldPosition()
	fx.Transform:SetPosition(x,y,z)
	if inst.components.rechargeable then
		inst.components.rechargeable:Discharge(DEFAULT_COOLDOWN_TIME)
	end
end

local function masterpostinit(inst)
	inst:AddComponent("aoespell")
	inst.components.aoespell:SetSpellFn(SkyDive)
	
	inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(function(inst) inst.components.aoetargeting:SetEnabled(false) end)
    inst.components.rechargeable:SetOnChargedFn(function(inst) inst.components.aoetargeting:SetEnabled(true) end)
	
	inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DEATHMATCH_TUNING.FORGE_MELEE_DAMAGE)
	inst.components.weapon.electric_damage_mult = 1
	inst.components.weapon:SetOnAttack(function(inst, attacker, target) --[[SpawnPrefab("weaponsparks_fx"):SetPosition(attacker, target)]] end)

	inst:AddComponent("aoeweapon_leap")
	inst.components.aoeweapon_leap:SetDamage(DEATHMATCH_TUNING.FORGE_MELEE_SPEAR_DAMAGE)
	inst.components.aoeweapon_leap:SetAOERadius(2.05)
	inst.components.aoeweapon_leap:SetOnLeaptFn(OnLeaptFn)
	inst.components.aoeweapon_leap:SetStimuli("electric")
    inst.components.aoeweapon_leap:SetWorkActions()
    inst.components.aoeweapon_leap:SetTags("_combat")
	
	inst:AddComponent("inspectable")
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "spear_lance"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
end

return {
	master_postinit = masterpostinit
}