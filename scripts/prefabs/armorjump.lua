local assets =
{
	Asset("ANIM", "anim/armor_lightspeed.zip"),
}

local prefabs = {
	"reticule",
}

local function ReticuleTargetFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    --Cast range is 8, leave room for error
    --2 is the aoe range
    for r = 5, 0, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function Jump(inst, caster, pos)
	caster:PushEvent("combat_jump", { weapon=inst, targetpos=pos })
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("armor_lightspeed")
	inst.AnimState:SetBuild("armor_lightspeed")
	inst.AnimState:PlayAnimation("anim")
	
    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetRange(10)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticule"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.validcolour = { 1, 0.75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true

	inst:AddTag("grass")
	inst:AddTag("combat_jump")
	inst:AddTag("hide_percentage")

	inst.foleysound = "dontstarve/movement/foley/grassarmour"
	inst.name = "Jump Armor\nPress Z while equipped to use"
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
	local function onequip(inst, owner)
		owner.AnimState:OverrideSymbol("swap_body", "armor_lightspeed", "swap_body")
	end
	
	local function onunequip(inst, owner)
		owner.AnimState:ClearOverrideSymbol("swap_body")
	end
	
	inst:AddComponent("inspectable")
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:ChangeImageName("lavaarena_armorlightspeed")
	
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipslot = EQUIPSLOTS.BODY
	
	--inst:AddComponent("armor")
	--inst.components.armor:InitIndestructible(0.25)
	
	inst:AddComponent("aoeweapon_leap")
	inst.components.aoeweapon_leap:SetRange(0)
	inst.components.aoeweapon_leap.fx = nil
	
	inst:AddComponent("aoespell")
	inst.components.aoespell:SetAOESpell(Jump)

	return inst
end

return Prefab("armorjump", fn, assets)