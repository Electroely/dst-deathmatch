local assets = {}

local prefabs = {
	"boat",
}

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
	
	inst:AddTag("boatspawner")
	
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("deathmatch_start", function()
		SpawnPrefab("boat").Transform:SetPosition(inst.Transform:GetWorldPosition())
	end, TheWorld)
	
	inst:DoTaskInTime(0, function()
		table.insert(TheWorld.components.deathmatch_manager.ocean_spawnpoints, inst)
	end)

    return inst
end

return Prefab("boatspawner", fn, assets, prefabs)