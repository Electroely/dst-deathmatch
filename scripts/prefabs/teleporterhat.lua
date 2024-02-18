local name = "recharger"
local build = "hat_"..name
local symbol = name.."hat"

local assets =
{
	Asset("ANIM", "anim/"..build..".zip"),
}

local prefabs = 
{
	"lavaarena_portal_player_fx",
}
local function onequip(inst, owner)
	if inst.components.rechargeable and inst.components.rechargeable:GetTimeToCharge() <= EQUIP_COOLDOWN_TIME then
		inst.components.rechargeable:Discharge(EQUIP_COOLDOWN_TIME)
	end
end

local function onunequip(inst, owner)

end

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

local function Teleport(inst, caster, pos)
	if caster ~= nil then
		local fire1 = SpawnPrefab("lavaarena_portal_player_fx")
		local fire2 = SpawnPrefab("lavaarena_portal_player_fx")
		local x, y, z = pos:Get()
		fire1.Transform:SetPosition(caster:GetPosition():Get())
		fire2.Transform:SetPosition(x+0.01,y,z+0.01)
		inst:DoTaskInTime(6 * FRAMES, function(inst)
			caster.Transform:SetPosition(pos:Get())
		end)
		if inst.components.rechargeable then
			inst.components.rechargeable:Discharge(DEFAULT_COOLDOWN_TIME)
		end
	end
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

	inst:AddTag("focusattack")
	
    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetRange(20)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticule"
    inst.components.aoetargeting.reticule.pingprefab = nil
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.validcolour = { 1, 1, 1, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true
	
	inst.name = "Crown of Teleportation"
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:AddComponent("inspectable")
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/teleporterhat.xml"

	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.equipslot = EQUIPSLOTS.HANDS
	
	inst:AddComponent("aoespell")
	inst.components.aoespell:SetSpellFn(Teleport)

	inst:AddComponent("rechargeable")
	inst.components.rechargeable:SetOnDischargedFn(function(inst) inst.components.aoetargeting:SetEnabled(false) end)
	inst.components.rechargeable:SetOnChargedFn(function(inst) inst.components.aoetargeting:SetEnabled(true) end)
	
	return inst
end

local instant_fn = function()
	local inst = fn()
	
	inst:AddTag("instantaoe")
	
	return inst
end

return Prefab("teleporterhat", fn, assets, prefabs), 
	Prefab("teleporterhat_instant", instant_fn, assets, prefabs)