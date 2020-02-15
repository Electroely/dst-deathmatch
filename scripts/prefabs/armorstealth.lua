local assets =
{
	Asset("ANIM", "anim/armor_lightspeed.zip"),
}
local prefabs = {
	"small_puff",
	"reticuleaoesmall",
	"reticuleaoesmallping",
}
local function OnUpdateInvisibility(inst, owner)
	local r, g, b, a = owner.AnimState:GetMultColour()
	if a > 0.1 then
		inst.stealtharmorinvisible = false
		r = r - 0.05
		g = g - 0.05
		b = b - 0.05
		a = a - 0.05
		owner.AnimState:SetMultColour(r, g, b, a)
	end
	if not owner.stealtharmorinvisible and a <= 0.1 then
		owner.stealtharmorinvisible = true
	end
end

local function applystealth(inst)
	local owner = inst.components.inventoryitem.owner
	if owner ~= nil then
		OnUpdateInvisibility(inst, owner)
	end
end

local function ActivateStealth(inst, caster, pos)
	if inst.stealtharmortask ~= nil then
		inst.stealtharmortask:Cancel()
		inst.stealtharmortask = nil
	end
	if inst.stealtharmortaskiller ~= nil then
		inst.stealtharmortaskiller:Cancel()
		inst.stealtharmortaskiller = nil
	end
	inst.stealtharmortask = inst:DoPeriodicTask(1/10, applystealth)
	caster.AnimState:SetMultColour(0.1,0.1,0.1,0.1)
	local puff = SpawnPrefab("small_puff")
	puff.Transform:SetPosition(caster:GetPosition():Get())
	puff.Transform:SetScale(1.5,1.5,1.5)
	inst.stealtharmortaskiller = inst:DoTaskInTime(12, function(inst)
		if inst.stealtharmortask ~= nil then
			inst.stealtharmortask:Cancel()
			inst.stealtharmortask = nil
		end
		local owner = inst.components.inventoryitem.owner
		if owner ~= nil then
			owner.AnimState:SetMultColour(1,1,1,1)
			local puff = SpawnPrefab("small_puff")
			puff.Transform:SetPosition(owner:GetPosition():Get())
			puff.Transform:SetScale(1.5,1.5,1.5)
		end
		if inst.components.finiteuses then
			inst.components.finiteuses:Use()
		end
		inst.stealtharmortaskiller = nil
	end)
end

local function OnAttacked(inst, data)
	inst.AnimState:SetMultColour(1,1,1,1)
end

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

	inst.AnimState:SetBank("armor_lightspeed")
	inst.AnimState:SetBuild("armor_lightspeed")
	inst.AnimState:PlayAnimation("anim")
	
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

	inst:AddTag("grass")
	inst:AddTag("focusattack")
	inst:AddTag("hide_percentage")

	inst.foleysound = "dontstarve/movement/foley/grassarmour"
	inst.name = "Stealth Armor\n25% Damage Reduction\nPress Z to use"
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
	local function onequip(inst, owner)
		owner.AnimState:OverrideSymbol("swap_body", "armor_lightspeed", "swap_body")
		owner:ListenForEvent("attacked", OnAttacked)
	end
	
	local function onunequip(inst, owner)
		owner.AnimState:ClearOverrideSymbol("swap_body")
		owner:RemoveEventCallback("attacked", OnAttacked)
		owner.AnimState:SetMultColour(1,1,1,1)
		if inst.stealtharmortask ~= nil then
			inst.stealtharmortask:Cancel()
			inst.stealtharmortask = nil
		end
		if inst.stealtharmortaskiller ~= nil then
			inst.stealtharmortaskiller:Cancel()
			inst.stealtharmortaskiller = nil
			local puff = SpawnPrefab("small_puff")
			puff.Transform:SetPosition(owner:GetPosition():Get())
			puff.Transform:SetScale(1.5,1.5,1.5)
		end
	end
	
	inst:AddComponent("inspectable")
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:ChangeImageName("lavaarena_armorlightspeed")
	
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipslot = EQUIPSLOTS.BODY
	inst.components.equippable.cooldownmultiplier = 0.5
	
	inst:AddComponent("armor")
	inst.components.armor:InitIndestructible(0.25)
	
	--inst:AddComponent("finiteuses")
	--inst.components.finiteuses:SetMaxUses(1)
	--inst.components.finiteuses:SetUses(1)
	--inst.components.finiteuses:SetOnFinished(inst.Remove)
	
	inst:AddComponent("aoespell")
	inst.components.aoespell:SetAOESpell(ActivateStealth)

	return inst
end

return Prefab("armorstealth", fn, assets)