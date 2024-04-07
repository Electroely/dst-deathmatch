local data = {}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_sword_buster", "swap_sword_buster")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
	DoEquipCooldown(inst)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function DoParry(inst, caster, pos)
	caster:PushEvent("combat_parry", {
		direction = caster:GetAngleToPoint(pos),
		duration = 3,
		weapon = inst})
	if inst.components.rechargeable then
		inst.components.rechargeable:Discharge(DEFAULT_COOLDOWN_TIME)
	end
	return true
end

local function OnParry(inst, doer, attacker, damage)

end

data.master_postinit = function(inst)

	--inst.AnimState:SetBuild("wx78")
	--inst.AnimState:SetBank("wilson")
	--inst.AnimState:PlayAnimation("emote_dab_loop", true)
	inst:AddTag("object")
	inst:AddTag("stone")

	inst:AddComponent("inspectable")
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "lavaarena_heavyblade"
	
	inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
	
	inst:AddComponent("aoespell")
	inst.components.aoespell:SetSpellFn(DoParry)
	
	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(50)
	
	inst:AddComponent("parryweapon")
	
	inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(function(inst) inst.components.aoetargeting:SetEnabled(false) end)
    inst.components.rechargeable:SetOnChargedFn(function(inst) inst.components.aoetargeting:SetEnabled(true) end)
end

return data