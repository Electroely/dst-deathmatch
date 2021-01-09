local assets =
{
    Asset("ANIM", "anim/bulb_plant_single.zip"),
    Asset("ANIM", "anim/bulb_plant_springy.zip"),
    Asset("SOUND", "sound/common.fsb"),
    Asset("MINIMAP_IMAGE", "bulb_plant"),
}

local prefabs =
{
    "powerflier",
}

local powerups = {
	"cooldown",
	"damage",
	"defense",
	"heal",
	"speed",
}

local LIGHT_MIN_TIME = 4
local LIGHT_MAX_TIME = 8

local MAX_CHILDREN = 1

local FIND_LIGHTFLIER_DISTANCE = 16

local RECALL_FREQUENCY = 8

local function SpawnLightflierFromStalk(inst)
    local lightflier = SpawnPrefab("powerflier")
    inst.components.childspawner:TakeOwnership(lightflier)

	lightflier:SetPowerup(inst.powerup)
    lightflier.Transform:SetPosition(inst:GetPosition():Get())
    lightflier:PushEvent("startled")
    
    inst.components.childspawner.childreninside = math.max(inst.components.childspawner.childreninside - 1, 0)
end

local function CancelCallForLightflierTask(inst)
    if inst._call_for_lightflier_task ~= nil then
        inst._call_for_lightflier_task:Cancel()
        inst._call_for_lightflier_task = nil
    end
end

local function makefullfn(inst)
    CancelCallForLightflierTask(inst)

    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
end

local function CallForLightflier(inst)
    if inst.components.pickable:CanBePicked() or inst.components.childspawner.numchildrenoutside < TUNING.LIGHTFLIER_FLOWER.TARGET_NUM_CHILDREN_OUTSIDE then
        CancelCallForLightflierTask(inst)
        return
    end

    if inst._lightflier_returning_home ~= nil and inst._lightflier_returning_home:IsValid() and not inst._lightflier_returning_home.components.formationfollower.active then
        return
    end

    for k, v in pairs(inst.components.childspawner.childrenoutside) do
        if not v.components.formationfollower.active then
            inst._lightflier_returning_home = v
            return
        end
    end

    inst._lightflier_returning_home = nil
end

local function StartCallForLightflierTask(inst)
    CancelCallForLightflierTask(inst)
    inst._call_for_lightflier_task = inst:DoPeriodicTask(RECALL_FREQUENCY, CallForLightflier, TUNING.LIGHTFLIER_FLOWER.RECALL_DELAY + math.random() * TUNING.LIGHTFLIER_FLOWER.RECALL_DELAY_VARIANCE)
end

local function onregenfn(inst)
	inst.powerup = GetRandomItem(powerups)
	
	inst.AnimState:OverrideSymbol("bulb", "powerflier_bulbs", inst.powerup.."bulb")
	
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", true)
end

local function onpickedfn(inst, picker, loot)
    SpawnLightflierFromStalk(inst)

    if picker ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/pickup_lightbulb")
    end
    inst.AnimState:PlayAnimation("picking")

    if inst.components.pickable:IsBarren() then
        inst.AnimState:PushAnimation("idle_dead")
    else
        inst.AnimState:PushAnimation("picked")
    end
    
    inst.components.pickable:Pause() -- Do not re-grow until the population is lower than max
    StartCallForLightflierTask(inst)
end

local function makeemptyfn(inst)
    inst.components.timer:StopTimer("turnoff")
    inst.components.timer:StopTimer("recharge")

    inst.AnimState:PlayAnimation("picked")
end

local function OnChildKilled(inst, child)
    -- Also called when fly is caught
    inst.components.pickable:Resume()
end

local function OnGoHome(inst, child)
    if not inst.components.pickable:CanBePicked() then
        inst.components.pickable:Regen()
    end
end

local function OnLoadPostPass(inst, ents, data)
    if not inst.components.pickable:CanBePicked()
        and inst.components.childspawner.numchildrenoutside >= TUNING.LIGHTFLIER_FLOWER.TARGET_NUM_CHILDREN_OUTSIDE then

        StartCallForLightflierTask(inst)
    end
end

local function commonfn(bank, build)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("plant")
    inst:AddTag("lightflier_home")

    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(0)
    inst.Light:SetRadius(0)
    inst.Light:SetColour(237/255, 237/255, 209/255)
    inst.Light:Enable(true)
    inst.Light:EnableClientModulation(true)

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle", true)

    inst.MiniMapEntity:SetIcon("bulb_plant.png")

    --inst:SetPrefabNameOverride("flower_cave")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.powerup = GetRandomItem(powerups)
	
	inst.AnimState:OverrideSymbol("bulb", "powerflier_bulbs", inst.powerup.."bulb")

    local color = 0.75 + math.random() * 0.25
    inst.AnimState:SetMultColour(color, color, color, 1)
	
	inst:AddComponent("inspectable")

    inst:AddComponent("timer")

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
    inst.components.pickable.onregenfn = onregenfn
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makeemptyfn = makeemptyfn
    inst.components.pickable.makefullfn = makefullfn
	
	---------------------
    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)
    ---------------------

    inst:AddComponent("lootdropper")

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "lightflier"
    inst.components.childspawner:SetMaxChildren(MAX_CHILDREN)
    inst.components.childspawner:SetOnChildKilledFn(OnChildKilled)
    inst.components.childspawner:SetGoHomeFn(OnGoHome)

    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

local plantnames = { "_single", "_springy" }

local lightparams_single =
{
    falloff = .5,
    intensity = .8,
    radius = 3,
}

local function single()
    local inst = commonfn("bulb_plant_single", "bulb_plant_single")
	
	inst.Light:SetRadius(lightparams_single.radius)
	inst.Light:SetIntensity(lightparams_single.intensity)
	inst.Light:SetFalloff(lightparams_single.falloff)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.plantname = plantnames[math.random(1, #plantnames)]
    inst.AnimState:SetBank("bulb_plant"..inst.plantname)
    inst.AnimState:SetBuild("bulb_plant"..inst.plantname)
    
    inst.components.pickable:SetUp(nil, 15)

    return inst
end

return Prefab("powerup_flower", single, assets, prefabs)
