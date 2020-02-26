local assets =
{
    Asset("ANIM", "anim/bloodpump.zip"),
}

local function PlayBeatAnimation(inst)
    inst.AnimState:PlayAnimation("idle")
end

local function beat(inst)
    inst:PlayBeatAnimation()
    inst.SoundEmitter:PlaySound("dontstarve/ghost/bloodpump")
    inst.beattask = inst:DoTaskInTime(.75 + math.random() * .75, beat)
end

local function startbeat(inst)
    if inst.beat_fx ~= nil then
        inst.beat_fx:Remove()
        inst.beat_fx = nil
    end
    if inst.reviver_beat_fx ~= nil then
        inst.beat_fx = SpawnPrefab(inst.reviver_beat_fx)
        inst.beat_fx.entity:SetParent(inst.entity)
        inst.beat_fx.entity:AddFollower()
        inst.beat_fx.Follower:FollowSymbol(inst.GUID, "bloodpump01", -5, -30, 0)
    end
    inst.beattask = inst:DoTaskInTime(.75 + math.random() * .75, beat)
end

local function ondropped(inst)
    if inst.beattask ~= nil then
        inst.beattask:Cancel()
    end
    inst.beattask = inst:DoTaskInTime(0, startbeat)
end

local function onpickup(inst) --TODO player should drop heart if takes enough damage
    if inst.beattask ~= nil then
        inst.beattask:Cancel()
        inst.beattask = nil
    end
    if inst.beat_fx ~= nil then
        inst.beat_fx:Remove()
        inst.beat_fx = nil
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bloodpump")
    inst.AnimState:SetBuild("bloodpump")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(ondropped)
    inst.components.inventoryitem:SetOnPutInInventoryFn(onpickup)
    inst.components.inventoryitem:SetSinks(true)
    inst.components.inventoryitem.imagename = "reviver"
    
    inst:AddComponent("equippable")
    inst:ListenForEvent("unequipped", function(inst, data)
		if data and data.owner and data.owner:HasTag("player") then
			local player = data.owner
			if player.sg.currentstate and player.sg.currentstate.name == "dolongaction" then
				player.sg:GoToState("idle") --cancel revive if heart is unequipped
			end
		end
    end)
    --inst:AddComponent("inspectable")

    MakeHauntableLaunch(inst)

    inst.beattask = nil
    ondropped(inst)

    inst.PlayBeatAnimation = PlayBeatAnimation

    return inst
end

return Prefab("deathmatch_reviverheart", fn, assets)
