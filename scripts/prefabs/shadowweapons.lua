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
		caster.Transform:SetPosition(pos:Get())
	end
end

local function shadowattackfx_fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
    inst.AnimState:SetBank("lavaarena_fire_fx")
    inst.AnimState:SetBuild("lavaarena_fire_fx")
    inst.AnimState:PlayAnimation("firestaff_ult_projection")
    inst.AnimState:SetMultColour(0, 0, 0, 0.5)
	
	--remove before the anim ends so i can get the specific part of it i need
	inst:DoTaskInTime(0.65, function(inst)
		if inst and inst:IsValid() then
			inst:Remove() --runs on both client and server (which is why im doing checks)
		end
	end)
end

local function SpawnShadowAttack(inst, caster, pos)
	--TODO: replace w/ its own fx prefab
	local fx = SpawnPrefab("lavaarena_meteor_splashbase")
	fx.AnimState:SetMultColour(0,0,0,0.5)
	fx.Transform:SetPosition(pos:Get())
	fx:DoTaskInTime(0.65, fx.Remove) --this should be done on client... separate into a new prefab? it is just an anim
end

local function SpawnShadowMinion(inst, caster, pos)
	local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 2, {"_combat"})
	local target = nil
	for i, v in ipairs(ents) do
		if caster.components.combat:CanTarget(v) then
			target = v
			break
		end
	end
	-- TODO: create new shadow creature prefabs bc they're vastly different from regular shadows
	local shadow = SpawnPrefab(math.random() > 0.3 and "crawlingnightmare" or "nightmarebeak")
	shadow.Transform:SetPosition(pos:Get())
	shadow.components.combat:SetTarget(target)
end

local assets = {
	Asset("ANIM", "anim/lavaarena_fire_fx.zip"),
}
local prefabs = {}

local function common_fn(slot)
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	inst:AddComponent("aoetargeting")
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "nightmarefuel"
	
	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = slot
	
	inst:AddComponent("aoespell")
	
	return inst
end

local function shadow_tp_hat_fn()
	local inst = common_fn(EQUIPSLOTS.HEAD)
	
	inst:AddTag("instantaoe")
	
    inst.components.aoetargeting:SetRange(8)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticule"
    inst.components.aoetargeting.reticule.pingprefab = nil
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.validcolour = { 1, 1, 1, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst.components.aoespell:SetAOESpell(Teleport)
	
	return inst
end

local function shadow_hand_fn()
	local inst = common_fn(EQUIPSLOTS.HANDS)

	inst:AddTag("instantaoe")
	
    inst.components.aoetargeting:SetRange(4)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoe"
    inst.components.aoetargeting.reticule.pingprefab = "reticuleaoeping"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.validcolour = { 0, 0, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { 0.5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst.components.aoespell:SetAOESpell(SpawnShadowAttack)
	
	return inst
end

local function shadow_body_fn()
	local inst = common_fn(EQUIPSLOTS.BODY)

	inst:AddTag("instantaoe")
	
    inst.components.aoetargeting:SetRange(8)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticule"
    inst.components.aoetargeting.reticule.pingprefab = nil
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.validcolour = { 1, 1, 1, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst.components.aoespell:SetAOESpell(SpawnShadowMinion)
	
	return inst
end

return Prefab("shadowplayer_hat", shadow_tp_hat_fn, assets, prefabs),
	Prefab("shadowplayer_hand", shadow_hand_fn, assets, prefabs),
	Prefab("shadowplayer_body", shadow_body_fn, assets, prefabs)	
