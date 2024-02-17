local function OnAttached(inst, target)
	inst.entity:SetParent(target.entity)
	inst.Transform:SetPosition(0, 0, 0) --in case of loading
	inst:ListenForEvent("death", function()
		inst.components.debuff:Stop()
	end, target)
end

local function OnExtended(inst, target)
	inst.components.timer:StopTimer("buffover")
	inst.components.timer:StartTimer("buffover", duration)
end

local function OnDetached(inst, target)

	inst:Remove()
end

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end

local function fn()
	local inst = CreateEntity()

	if not TheWorld.ismastersim then
		--Not meant for client!
		inst:DoTaskInTime(0, inst.Remove)
		return inst
	end

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

	inst:AddComponent("timer")
	inst.components.timer:StartTimer("buffover", duration)
	inst:ListenForEvent("timerdone", OnTimerDone)

	return inst
end