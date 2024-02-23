local RANGE = 4
local DEFENSE = DEATHMATCH_TUNING.FORGE_MAGE_HEALBLOOMS_DEFENSE
local ALLIED_ADDCOLOR = {0.1, 0.3, 0.1, 1}
local ENEMY_ADDCOLOR = {0, 0, 0.5, 1}
local function OnAttached(inst, target)
	inst.entity:SetParent(target.entity)
	inst.target = target
	inst.Transform:SetPosition(0, 0, 0) --in case of loading
	inst:ListenForEvent("death", function()
		inst.components.debuff:Stop()
	end, target)
	if inst.allied then
		if target.components.combat then
			target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, DEFENSE)
		end
	else
		if target.components.grogginess then
			target.components.grogginess:SetDecayRate(0)
			target.components.grogginess:AddGrogginess(0.1, 0)
		end
	end
	if target.components.colouradder then
		target.components.colouradder:PushColour(inst, unpack(inst.allied and ALLIED_ADDCOLOR or ENEMY_ADDCOLOR))
	end
end

local function OnExtended(inst, target)

end

local function OnDetached(inst, target)
	if inst.allied then
		if target.components.combat then
			target.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst)
		end
	else
		if target.components.grogginess then
			target.components.grogginess:SetDecayRate(1)
		end
	end
	inst:Remove()
end

local function IsBuffValid(inst)
	local target = inst.target
	local source = inst.source
	if source and source:IsValid() and source:IsNear(target, RANGE) then
		return true
	else
		local newsource = inst:FindNewSource()
		if newsource then
			inst.source = newsource
			return true
		end
	end
	return false
end
local function FindNewSource(inst)
	local target = inst.target
	if target == nil then
		return nil
	end
	local allied = inst.allied
	local x,y,z = target.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x,y,z,RANGE,{"healingstaffcircle"})
	for k, v in pairs(ents) do
		if v:IsAlliedWith(target) == allied then
			return v
		end
	end
	return nil
end
local function OnUpdate(inst)
	if not inst:IsBuffValid() then
		inst.components.debuff:Stop()
	end
end
local function MakeBuff(name, allied)
	local function fn()
		local inst = CreateEntity()

		if not TheWorld.ismastersim then
			--Not meant for client!
			inst:DoTaskInTime(0, inst.Remove)
			return inst
		end

		inst.allied = allied

		inst.entity:AddTransform()

		--[[Non-networked entity]]
		--inst.entity:SetCanSleep(false)
		inst.entity:Hide()
		inst.persists = false

		inst:AddTag("CLASSIFIED")

		inst:AddComponent("debuff")
		inst.components.debuff:SetAttachedFn(OnAttached)
		inst.components.debuff:SetDetachedFn(OnDetached)
		inst.components.debuff:SetExtendedFn(OnExtended)
		inst.components.debuff.keepondespawn = true

		inst.updatetask = inst:DoPeriodicTask(3*FRAMES, OnUpdate)

		inst.FindNewSource = FindNewSource
		inst.IsBuffValid = IsBuffValid

		return inst
	end

	return Prefab("buff_"..name, fn)
end

return MakeBuff("healingstaff_ally", true), MakeBuff("healingstaff_enemy", false)