local assets =
{
	Asset("ANIM", "anim/maxwell_torch.zip"),
}

local prefabs =
{
    "maxwelllight_flame",
}

local function light(inst)
	local amount = 1
    inst.task = inst:DoPeriodicTask(1/20, function()
		inst.components.burnable:SetFXLevel(inst.lightorder[amount])
		amount = amount + 1
		if amount >= 5 then
			inst.task:Cancel()
			inst.task = nil
		end
	end)
end

local function extinguish(inst)
    if inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

    inst.AnimState:SetBank("maxwell_torch")
    inst.AnimState:SetBuild("maxwell_torch")
    inst.AnimState:PlayAnimation("idle",false)
  
    inst:AddTag("structure")
    MakeObstaclePhysics(inst, .1)
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
    -----------------------
    inst:AddComponent("burnable")
    inst.components.burnable:AddBurnFX("maxwelllight_flame", Vector3(0,0,0), "fire_marker")
    inst.components.burnable:SetOnIgniteFn(light)
    ------------------------    
    return inst
end

local function arealight()
    local inst = fn()
	
	if not TheWorld.ismastersim then
		return inst
	end
	
    inst.lightorder = {5,6,7,8,7}
	
    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(14, 16)
    inst.components.playerprox:SetOnPlayerNear(function() if not inst.components.burnable:IsBurning() then inst.components.burnable:Ignite() end end)
    inst.components.playerprox:SetOnPlayerFar(extinguish)

    return inst
end

return Prefab("maxwelllight", arealight, assets, prefabs) 
