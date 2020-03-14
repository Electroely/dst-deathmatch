local assets = {}

local prefabs = {}

local function OnEquip(inst, owner)
	owner.AnimState:OverrideSymbol("hand", "lavaarena_beetletaur", "hand")
end

local function OnUnEquip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("hand")
end

local function ReticuleTargetFn()
    local player = ThePlayer
    local ground = TheWorld.Map
    local pos = Vector3()
    for r = 7, 0, -.25 do
        pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
        if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
            return pos
        end
    end
    return pos
end

local function AnvilStrike(inst, caster, pos)
	caster:PushEvent("combat_leap", {
		targetpos = pos,
		weapon = inst
	})
end

local function fn()
	local inst = CreateEntity()
    
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
		
	MakeInventoryPhysics(inst)
	
	inst:AddTag("weapon")
    inst:AddTag("aoeweapon_leap")
    inst:AddTag("rechargeable")
	
	inst:AddComponent("aoetargeting")
    inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoe"
    inst.components.aoetargeting.reticule.pingprefab = "reticuleaoeping"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
		
	inst:AddComponent("inspectable")
		
	inst:AddComponent("inventoryitem")
	
	inst:AddComponent("aoespell")
	inst.components.aoespell:SetAOESpell(AnvilStrike)
	
	inst:AddComponent("rechargeable")
	
	inst:AddComponent("aoeweapon_leap")
	inst.components.aoeweapon_leap:SetDamage(100)
	inst.components.aoeweapon_leap:SetRange(4.1)
	inst.components.aoeweapon_leap:SetStimuli("electric")
	
	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(100)
	inst.components.weapon:SetOverrideStimuliFn(function(inst)
		return "kb"
	end)

	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
	inst.components.equippable:SetOnEquip(OnEquip)
	inst.components.equippable:SetOnUnequip(OnUnEquip)

	return inst
end
	
return Prefab("swineclops_fists", fn, assets, prefabs)
