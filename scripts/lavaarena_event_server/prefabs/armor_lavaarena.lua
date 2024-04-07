local armorextradata = {
	lavaarena_armorlight = {defense = 0.5, rechargemult = 0.05},
	lavaarena_armorlightspeed = {defense = 0.6, speedmult = 1.1},
	lavaarena_armormedium = {defense = 0.75},
	lavaarena_armormediumdamager = {defense = 0.75, damagemult = 1.1},
	lavaarena_armormediumrecharger = {defense = 0.75, rechargemult = 0.1},
	lavaarena_armorheavy = {defense = 0.85},
	lavaarena_armorextraheavy = {defense = 0.9, speedmult = 0.85},
	lavaarena_armor_hpextraheavy = {},
	lavaarena_armor_hppetmastery = {},
	lavaarena_armor_hprecharger = {},
	lavaarena_armor_hpdamager = {}
}

local function UpdateDamageMults(inst, owner, isequipping)
	local headitem = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
	local bodymult = inst.components.equippable.damagemult or 1
	local headmult = 1
	if headitem ~= nil then
		headmult = headitem.components.equippable.damagemult or 1
	end
	
	local totalmult = 1 + (bodymult-1) + (headmult-1)
	
	if not	isequipping then
		totalmult = 1 + (headmult-1)
	end
	
	owner.components.combat.externaldamagemultipliers:SetModifier(owner, totalmult, "armors")
end

local function MasterPostInit(inst, name, build)

	local function onequip(inst, owner)
		owner.AnimState:OverrideSymbol("swap_body", build, "swap_body")
		UpdateDamageMults(inst, owner, true)
	end
	
	local function onunequip(inst, owner)
		owner.AnimState:ClearOverrideSymbol("swap_body")
		UpdateDamageMults(inst, owner, false)
	end
	
	inst:AddComponent("inspectable")
	
	inst:AddComponent("inventoryitem")
	
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipslot = EQUIPSLOTS.BODY
	inst.components.equippable.walkspeedmult = armorextradata[name].speedmult
	inst.components.equippable.cooldownmultiplier = armorextradata[name].rechargemult
	inst.components.equippable.damagemult = armorextradata[name].damagemult
	
	inst:AddComponent("armor")
	inst.components.armor:InitIndestructible(armorextradata[name].defense)
	
	return inst
end

return {
	master_postinit = MasterPostInit
}