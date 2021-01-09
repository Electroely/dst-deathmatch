local assets =
{
    Asset("ANIM", "anim/bloodpump.zip"),
	Asset("ANIM", "anim/swap_reviverheart.zip"),
	Asset("ANIM", "anim/bloodpump_extra.zip"),
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

local function launchitem(item, angle)
    local speed = 3+math.random()*1
    angle = (angle+math.random()*30-15) * DEGREES
    item.Physics:SetVel(speed * math.cos(angle), 10, -speed * math.sin(angle))
end

local function onholderattacked(player, data)
	if not player._droppedreviverheart then --one heart per attack
		local heart = player.components.inventory:FindItem(function(item)
			return item.prefab == "deathmatch_reviverheart"
		end)
		if heart ~= nil then
			player.components.inventory:DropItem(heart)
			heart.Transform:SetPosition(player.Transform:GetWorldPosition())
			launchitem(heart, 
				data.attacker and player:GetAngleToPoint(data.attacker.Transform:GetWorldPosition()) 
				or math.random()*360)
			player._droppedreviverheart = true
		end
		player:DoTaskInTime(0, function(player) 
			player._droppedreviverheart = nil
		end)
	end
end

local function ondropped(inst)
	if inst._listening then
		inst:RemoveEventCallback("attacked", onholderattacked, inst._owner)
		inst._owner = nil
	end
    if inst.beattask ~= nil then
        inst.beattask:Cancel()
    end
    inst.beattask = inst:DoTaskInTime(0, startbeat)
end

local function onpickup(inst, owner)
	if inst._listening then
		inst:RemoveEventCallback("attacked", onholderattacked, inst._owner)
		inst._owner = nil
	end
	if owner ~= nil then
		inst:ListenForEvent("attacked", onholderattacked, owner)
		inst._owner = owner
		inst._listening = true
	end
    if inst.beattask ~= nil then
        inst.beattask:Cancel()
        inst.beattask = nil
    end
    if inst.beat_fx ~= nil then
        inst.beat_fx:Remove()
        inst.beat_fx = nil
    end
end

local function onthrown(inst)
	inst:AddTag("NOCLICK")
	
	inst.AnimState:PlayAnimation("thrown", true)
	
	inst.Physics:SetMass(1)
	inst.Physics:SetCapsule(0.2, 0.2)
	inst.Physics:SetFriction(0)
	inst.Physics:SetDamping(0)
	inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.GROUND)
	inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	inst.Physics:CollidesWith(COLLISION.ITEMS)
	
	if inst._listening then
		inst:RemoveEventCallback("attacked", onholderattacked, inst._owner)
		inst._owner = nil
	end
end
local REVIVE_RANGE = 2
local function onlanded(inst, thrower)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, 2, {"player"})
	local target = nil
	if thrower then
		for k, v in pairs(ents) do
			if v:HasTag("corpse") and thrower.components.teamer:IsTeamedWith(v) then
				target = v
				break
			end
		end
	end
	if target ~= nil then
		local revivepct = 0.5 / math.pow(2, TheWorld.components.deathmatch_manager.revivals)
		target:PushEvent("respawnfromcorpse", {health=revivepct, user=thrower})
		TheWorld.components.deathmatch_manager:OnPlayerRevived(target, thrower)
		inst:Remove()
	else
		inst:RemoveTag("NOCLICK")
		PlayBeatAnimation(inst)
	end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_reviverheart", "swap_reviverheart")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	
	inst:AddTag("irreplaceable")
	
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
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst:ListenForEvent("unequipped", function(inst, data)
		if data and data.owner and data.owner:HasTag("player") then
			local player = data.owner
			if player.sg.currentstate and player.sg.currentstate.name == "dolongaction" then
				player.sg:GoToState("idle") --cancel revive if heart is unequipped
			end
		end
    end)
    --inst:AddComponent("inspectable")
	
	inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetHorizontalSpeed(15)
    inst.components.complexprojectile:SetGravity(-35)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(.25, 1, 0))
    inst.components.complexprojectile:SetOnLaunch(onthrown)
	inst.components.complexprojectile:SetOnHit(onlanded)

    MakeHauntableLaunch(inst)

    inst.beattask = nil
    ondropped(inst)

    inst.PlayBeatAnimation = PlayBeatAnimation

    return inst
end

return Prefab("deathmatch_reviverheart", fn, assets)
