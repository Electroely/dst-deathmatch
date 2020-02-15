local function stopusingbush(inst, data)
	local hat = inst.components.inventory ~= nil and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
	if hat ~= nil and hat.prefab == "snortoisehat" and data.statename ~= "hide" then
		hat.components.useableitem:StopUsingItem()
	end
end

local function bush_onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_hat", "hat_snortoise", "swap_hat")
	owner.AnimState:Show("HAT")
	owner.AnimState:Show("HAIR_HAT")
	owner.AnimState:Hide("HAIR_NOHAT")
	owner.AnimState:Hide("HAIR")

	if owner:HasTag("player") then
		owner.AnimState:Hide("HEAD")
		owner.AnimState:Show("HEAD_HAT")
	end

	if inst.components.fueled ~= nil then
		inst.components.fueled:StartConsuming()
	end

	inst:ListenForEvent("newstate", stopusingbush, owner)
end

local function bush_onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_hat")

	owner.AnimState:Hide("HAT")
	owner.AnimState:Hide("HAIR_HAT")
	owner.AnimState:Show("HAIR_NOHAT")
	owner.AnimState:Show("HAIR")

	if owner:HasTag("player") then
		owner.AnimState:Show("HEAD")
		owner.AnimState:Hide("HEAD_HAT")
	end

	if inst.components.fueled ~= nil then
		inst.components.fueled:StopConsuming()        
	end

	inst:RemoveEventCallback("newstate", stopusingbush, owner)
end

local function bush_onuse(inst)
	local owner = inst.components.inventoryitem.owner
	if owner then
		owner.sg:GoToState("hide")
		owner.components.combat.externaldamagetakenmultipliers:SetModifier("shell", 0.001)
	end
end

local function onstopuse(inst)
	local owner = inst.components.inventoryitem.owner
	if owner then
		owner.components.combat.externaldamagetakenmultipliers:SetModifier("shell", 1)
	end
end

local assets = {
	Asset("ANIM", "anim/hat_snortoise.zip"),
	Asset("ANIM", "anim/lavaarena_turtillus_basic.zip")
}

local function ReticuleTargetFn()
    local player = ThePlayer
	local pos = Vector3()
	if player ~= nil then
		pos = player:GetPosition()
	end
    return pos
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("hat_snortoise")
	inst.AnimState:SetBuild("hat_snortoise")
	inst.AnimState:PlayAnimation("BUILD_PLAYER")

	inst:AddTag("hat")
	inst:AddTag("shelluse")
	
    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetRange(200)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoesmall"
    inst.components.aoetargeting.reticule.pingprefab = "reticuleaoesmallping"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
	inst.components.aoetargeting.reticule.mousetargetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.validcolour = { 1, 0.75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true
	inst.components.aoetargeting.alwaysvalid = true
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:AddComponent("useableitem")
	inst.components.useableitem:SetOnUseFn(bush_onuse)
	inst.components.useableitem:SetOnStopUseFn(onstopuse)
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "bushhat"

	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
	inst.components.equippable:SetOnEquip(bush_onequip)
	inst.components.equippable:SetOnUnequip(bush_onunequip)
	
	inst:AddComponent("aoespell")
	inst.components.aoespell:SetAOESpell(function(inst, caster, pos) caster.sg:GoToState("shellattack_pre") end)
	
	return inst
end

return Prefab("snortoisehat", fn, assets)
