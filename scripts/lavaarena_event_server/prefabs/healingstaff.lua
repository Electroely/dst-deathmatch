local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_healingstaff", "swap_healingstaff")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
	DoEquipCooldown(inst)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local DURATION = 20
local function LifeBlossom(inst, caster, pos)
	local spell = SpawnPrefab("lavaarena_healblooms")
	spell.Transform:SetPosition(pos:Get())
	spell:SetCaster(caster)
	spell:DoTaskInTime(DURATION, spell.Kill)
	spell.persists = false
	if inst.components.rechargeable then
		inst.components.rechargeable:Discharge(DEFAULT_COOLDOWN_TIME*2)
	end
	return true
end

local function OnSwing(inst, attacker, target)
	inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/heal_staff")
	local offset = (target:GetPosition() - attacker:GetPosition()):GetNormalized()*1.2
	local particle = SpawnPrefab("blossom_hit_fx")
	particle.Transform:SetPosition((attacker:GetPosition() + offset):Get())
	particle.AnimState:SetScale(0.8,0.8)
end
local function OnProjectileLaunched(inst, attacker, target, proj)
	if proj.components.projectile then
		proj.components.projectile:SetRange(4)
	end
end

local function staff_masterpostinit(inst)
    inst:AddComponent("aoespell")
	inst.components.aoespell:SetSpellFn(LifeBlossom)
	
	inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(function(inst) inst.components.aoetargeting:SetEnabled(false) end)
    inst.components.rechargeable:SetOnChargedFn(function(inst) inst.components.aoetargeting:SetEnabled(true) end)
	
	inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DEATHMATCH_TUNING.FORGE_MAGE_DAMAGE)
    inst.components.weapon:SetRange(2, 4)
    inst.components.weapon:SetProjectile("blossom_projectile")
	inst.components.weapon:SetOnProjectileLaunch(OnSwing)
	inst.components.weapon:SetOnProjectileLaunched(OnProjectileLaunched)
	
	inst:AddComponent("inspectable")
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "healingstaff"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
end

local function castfx_masterpostinit(inst)
	inst:ListenForEvent("animover", inst.Remove)
end

return {
	healingstaff_postinit = staff_masterpostinit,
	castfx_postinit = castfx_masterpostinit
}