local function ReticuleTargetFn()
    --Cast range is 8, leave room for error (6.5 lunge)
    return Vector3(ThePlayer.entity:LocalToWorldSpace(10, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local l = dx * dx + dz * dz
        if l <= 0 then
            return inst.components.reticule.targetpos
        end
        l = 10 / math.sqrt(l)
        return Vector3(x + dx * l, 0, z + dz * l)
    end
end

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

local name = "eyecirclet"
local build = "hat_"..name
local symbol = name.."hat"

local assets =
{
	Asset("ANIM", "anim/"..build..".zip"),
}

local prefabs = 
{
	"deerclops_laserhit",
	"deerclops_laserscorch",
	"deerclops_lasertrail"
}
local function onequip(inst, owner)
	owner.AnimState:OverrideSymbol("swap_hat", build, "swap_hat")
	owner.AnimState:Show("hat")
end

local function onunequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("swap_hat")
	owner.AnimState:Hide("hat")
end

local function OnLaserHit(inst, caster, target)
	SpawnPrefab("deerclops_laserhit"):SetTarget(target)
end

local function ShootLaser(inst, caster, pos)
	inst.components.aoeweapon_lunge:DoLunge(caster, caster:GetPosition(), pos)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank(symbol)
	inst.AnimState:SetBuild(build)
	inst.AnimState:PlayAnimation("anim")

	inst:AddTag("hat")
	inst:AddTag("focusattack")
	
    inst:AddComponent("aoetargeting")
	inst.components.aoetargeting:SetRange(12)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticulelong"
    inst.components.aoetargeting.reticule.pingprefab = "reticulelongping"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
    inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true
	inst.components.aoetargeting.alwaysvalid = true
	
	inst.name = "Laser Headpiece\nPress R while equipped to use"
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:AddComponent("inspectable")
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem:ChangeImageName("lavaarena_eyecirclethat")

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
	
	inst:AddComponent("weapon")
	
	inst:AddComponent("aoeweapon_lunge") -- fid made most of this component and i added things to it, its not in this mod
	inst.components.aoeweapon_lunge:SetDamage(200)
	inst.components.aoeweapon_lunge:SetRange(3)
	inst.components.aoeweapon_lunge:SetStimuli("fire")
	inst.components.aoeweapon_lunge:SetSpeed(2)
	inst.components.aoeweapon_lunge:SetOnHitFn(OnLaserHit)
	inst.components.aoeweapon_lunge.fxnum = 15
	inst.components.aoeweapon_lunge.fx = "deerclops_lasertrail"
	inst.components.aoeweapon_lunge.ignore_firstfx = true
	inst.components.aoeweapon_lunge.fxfn = function(fx, fxnum, fxmaxnum)
		local scorch = SpawnPrefab("deerclops_laserscorch")
		scorch.Transform:SetPosition(fx:GetPosition():Get())
		scorch.Transform:SetScale(fx.Transform:GetScale())
	end
	
	inst:AddComponent("aoespell")
	inst.components.aoespell:SetAOESpell(ShootLaser)
	
	return inst
end

return Prefab("laserhat", fn, assets, prefabs)