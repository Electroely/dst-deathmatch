local assets =
{
    Asset("ANIM", "anim/balloons_empty.zip"),
    Asset("SOUND", "sound/pengull.fsb"),
}

local prefabs =
{
    "balloon"
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("balloons_empty")
    inst.AnimState:SetBuild("balloons_empty")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon("balloons_empty.png")
	
    inst:AddComponent("explosiveballoonmaker")
	
	-- added tag rechargeable (from rechargeable component) to pristine state for optimization
	-- also itemtile stuff lol
	inst:AddTag("rechargeable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:ChangeImageName("balloons_empty")

    inst:AddComponent("inspectable")
	
	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetRechargeTime(6)
	inst.components.rechargeable:SetRechargeStartFn(function(inst)
		inst.components.explosiveballoonmaker:SetEnabled(false)
	end)
	inst.components.rechargeable:SetRechargeDoneFn(function(inst)
		inst.components.explosiveballoonmaker:SetEnabled(true)
	end)

    return inst
end

return Prefab("explosiveballoons_empty", fn, assets, prefabs)
