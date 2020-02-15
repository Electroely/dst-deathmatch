local function fxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --inst.entity:AddPhysics()
    inst.entity:AddNetwork()

    --[[inst.Physics:SetMass(1)
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:SetSphere(.2)]]

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("turtillus")
    inst.AnimState:SetBuild("lavaarena_turtillus_basic")
    inst.AnimState:PlayAnimation("hide_idle")
	inst.AnimState:SetScale(0.7,0.7,0.7)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    --inst.SetMotion = SetMotionFX
	
	inst:ListenForEvent("animover", function(inst, data)
		local parent = inst.entity:GetParent()
		if parent ~= nil then
			parent:PushEvent("animover", data)
		end
	end)
	inst:ListenForEvent("animqueueover", function(inst, data)
		local parent = inst.entity:GetParent()
		if parent ~= nil then
			parent:PushEvent("animqueueover", data)
		end
	end)
    return inst
end

return Prefab("snortoisedummy", fxfn)