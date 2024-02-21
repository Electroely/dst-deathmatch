local assets = {
	Asset("ANIM", "anim/firefighter_placement.zip"),
}
local function OnUpdate(inst)
	if inst.player == nil or not inst.player:IsValid() then
		inst:Remove()
		return
	end
	if inst.player.components.playercontroller.reticule == nil then
		inst:Remove()
		return
	end
	local weapon = inst.player.components.playercontroller.reticule.inst
	if weapon == nil or not weapon:IsValid() or weapon.components.aoetargeting == nil then
		inst:Remove()
		return
	end
	local range = weapon.components.aoetargeting.range
	local scale = math.sqrt(range * 300 / 1900)
	inst.Transform:SetScale(scale, scale, scale)
end
local function SetPlayer(inst, player, range)
	inst.player = player
	if player then
		inst.entity:SetParent(player.entity)
	else
		inst.entity:SetParent(nil)
	end
	local scale = math.sqrt(range * 300 / 1900)
	inst.Transform:SetScale(scale, scale, scale)
end
local function fn()
	local inst = CreateEntity()

	--[[Non-networked entity]]
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst:AddTag("CLASSIFIED")
	inst:AddTag("NOCLICK")

	inst.AnimState:SetBank("firefighter_placement")
	inst.AnimState:SetBuild("firefighter_placement")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetLightOverride(1)
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(1)
	
	inst.SetPlayer = SetPlayer
	
	inst.updatetask = inst:DoPeriodicTask(0, OnUpdate)
	inst.AnimState:SetAddColour(1, 1, 1, 0)
	inst.AnimState:SetMultColour(0.1, 0.1, 0.1, 0.1)
	return inst
end

return Prefab("deathmatch_range_indicator", fn, assets)