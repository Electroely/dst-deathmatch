local prefabs = {}
local assets = {}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.Light:SetFalloff(9)
    inst.Light:SetIntensity(.7)
    inst.Light:SetRadius(0.75)
    inst.Light:SetColour(1,1,1)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("atrium_key_light", fn, assets, prefabs)