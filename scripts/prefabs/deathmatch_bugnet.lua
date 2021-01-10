local assets =
{
    Asset("ANIM", "anim/bugnet.zip"),
    Asset("ANIM", "anim/swap_bugnet.zip"),
    Asset("ANIM", "anim/floating_items.zip"),
}

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_bugnet", inst.GUID, "swap_bugnet")
    else
        owner.AnimState:OverrideSymbol("swap_object", "swap_bugnet", "swap_bugnet")
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bugnet")
    inst.AnimState:SetBuild("swap_bugnet")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("tool")
    inst:AddTag("weapon")
	inst:AddTag("deathmatch_pickup")

    local swap_data = {sym_build = "swap_bugnet"}
    MakeInventoryFloatable(inst, "med", 0.09, {0.9, 0.4, 0.9}, true, -14.5, swap_data)
	
	inst:SetPrefabNameOverride("bugnet")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "bugnet"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.BUGNET_DAMAGE)
    inst.components.weapon.attackwear = 3

    -----
    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.NET)
    -------

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(1)
    inst.components.finiteuses:SetUses(1)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst.components.finiteuses:SetConsumption(ACTIONS.NET, 1)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("deathmatch_bugnet", fn, assets)