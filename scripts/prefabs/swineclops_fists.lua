local assets = {}

local prefabs = {}

local function OnEquip(inst, owner)
	owner.AnimState:OverrideSymbol("hand", "lavaarena_beetlesaur", "hand")
end

local function OnUnEquip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("hand")
end

local function fn()
	local inst = CreateEntity()
    
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
		
	MakeInventoryPhysics(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
		
	inst:AddComponent("inspectable")
		
	inst:AddComponent("inventoryitem")
	
	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(100)
	inst.components.weapon:SetOverrideStimuliFn(function(inst)
		return "kb"
	end)

	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
	inst.components.equippable:SetOnEquip(OnUnEquip)
	inst.components.equippable:SetOnUnequip(OnEquip)

	return inst
end
	
return Prefab("swineclops_fists", fn, assets, prefabs)
