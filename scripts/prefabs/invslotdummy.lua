local assets =
{
}

local prefabs = 
{
}

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	
	inst:AddTag("invslotdummy")
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:SetOnDroppedFn(inst.Remove)
	inst.components.inventoryitem:SetOnActiveItemFn(inst.Remove)
	
	return inst
end

return Prefab("invslotdummy", fn, assets, prefabs)