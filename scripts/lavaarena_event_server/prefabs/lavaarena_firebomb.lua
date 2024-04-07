local data = {}

local function tryequipsparks(inst, owner)
	local ignoreequipcheck = owner ~= nil
	owner = owner or inst.components.inventoryitem.owner
	if owner and (ignoreequipcheck or owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) == inst) then
		if inst.sparkfx and inst.sparkfx.Follower then
			inst.sparkfx:Show()
			inst.sparkfx.Follower:FollowSymbol(owner.GUID, "swap_object", 40, 20, 0)
		end
	end
end
local function tryunequipsparks(inst)
	if inst.sparkfx then inst.sparkfx:Hide() end
end

local function ondropped(inst)
	if inst.sparkfx and inst.sparkfx.Follower then
		inst.sparkfx:Show()
		inst.sparkfx.Follower:FollowSymbol(inst.GUID, "firebomb01", 40, -80, 0)
	end
end
local function onpickup(inst)
	if inst.sparkfx then
		inst.sparkfx:Hide()
	end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_lavaarena_firebomb", "swap_lavaarena_firebomb")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
	tryequipsparks(inst, owner)
	if inst.components.rechargeable and inst.components.rechargeable:GetTimeToCharge() <= EQUIP_COOLDOWN_TIME then
		inst.components.rechargeable:Discharge(EQUIP_COOLDOWN_TIME)
	end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
	tryunequipsparks(inst)
end

local BOUNCE_DAMAGE_PENALTY = 1/2
local function DoExplosion(inst, caster, pos, should_kb)
	local x,y,z = pos:Get()
	SpawnPrefab("lavaarena_firebomb_explosion").Transform:SetPosition(x,y,z)
	local stimuli = should_kb and "kb" or "fire"
    local ents = TheSim:FindEntities(x, y, z, 2.5, nil, {"companion"})
	for _,ent in ipairs(ents) do
        if caster ~= nil and caster:IsValid() and ent ~= caster and caster.components.combat:IsValidTarget(ent) and ent.components.health and (TheNet:GetPVPEnabled() or not ent:HasTag("player")) then
			local damagemult = math.pow(BOUNCE_DAMAGE_PENALTY, inst.prev_targets and inst.prev_targets[ent] or 0)
            caster:PushEvent("onareaattackother", { target = ent, weapon = inst, stimuli = stimuli })
            ent.components.combat:GetAttacked(caster, caster.components.combat:CalcDamage(ent, inst, caster.components.combat.areahitdamagepercent)*damagemult, inst, stimuli)
			if inst.prev_targets then
				inst.prev_targets[ent] = (inst.prev_targets[ent] or 0)+1
			end
        end
    end
	if caster:HasTag("burning_bombs") then
		local bounces = inst.bounces or 0
		inst.firecircle = SpawnPrefab("firebomb_firecircle")
		inst.firecircle:SetCaster(caster)
		inst.firecircle.sparklevel = inst.sparklevel+1 - (bounces-1)
		inst.firecircle.Transform:SetPosition(x,y,z)
	end
	inst:PushEvent("sparksploded")
end

local function DoTheFireBomb(inst, caster, pos)
	local projectile = SpawnPrefab("lavaarena_firebomb_projectile")
	projectile.Transform:SetPosition(caster.Transform:GetWorldPosition())
	projectile.components.complexprojectile:SetLaunchOffset(Vector3(0.5, 1.25, 0))
	projectile.sparklevel = inst.sparklevel
	if caster:HasTag("bouncing_bombs") then
		projectile.should_bounce = true
	end
	projectile.should_home = caster:HasTag("homing_bombs")
	projectile.should_make_firecircle = caster:HasTag("burning_bombs")
	projectile:Throw(pos, caster)
	inst:SetSparkLevel(0)
	if inst.components.rechargeable then
		inst.components.rechargeable:Discharge(DEFAULT_COOLDOWN_TIME)
	end
	return true
end

data.firebomb_postinit = function(inst)

	--inst.AnimState:SetBuild("wilson")
	--inst.AnimState:SetBank("wilson")
	--inst.AnimState:PlayAnimation("emote_dab_loop", true)
	inst:RemoveTag("rechargeable")

	inst.sparklevel = 0
	inst.sparklevel_max = 3
	function inst:CreateSparks()
		inst.sparkfx = SpawnPrefab("lavaarena_firebomb_sparks")
		inst.sparkfx.persists = false
		inst.sparkfx.entity:AddFollower()
	end
	function inst:SetSparkLevel(lvl)
		inst.sparklevel = lvl
		if lvl >= inst.sparklevel_max then
			inst.components.weapon:SetDamage(DEATHMATCH_TUNING.FIREBOMB_MELEE_EXPLOSION_DAMAGE)
		else
			inst.components.weapon:SetDamage(DEATHMATCH_TUNING.FIREBOMB_MELEE_DAMAGE)
		end
		if inst.sparkfx ~= nil then
			if lvl > 0 then
				inst.sparkfx:SetSparkLevel(lvl)
			else
				inst.sparkfx:Remove()
				inst.sparkfx = nil
			end
		elseif lvl > 0 then
			inst:CreateSparks()
			inst.sparkfx:SetSparkLevel(lvl)
			--tryequipsparks(inst)
		end
		if inst.sparkfx then
			if (inst.components.equippable == nil or inst.components.equippable:IsEquipped()) then
				tryequipsparks(inst, inst.components.inventoryitem and inst.components.inventoryitem.owner)
			else
				tryunequipsparks(inst)
			end
		end
	end
	
	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(DEATHMATCH_TUNING.FIREBOMB_MELEE_DAMAGE)
	inst.components.weapon:SetOnAttack(function(inst, attacker, target)
		if inst.sparklevel >= 3 then
			if target ~= nil and target:IsValid() then
				local fx = SpawnPrefab("lavaarena_firebomb_proc_fx")
				fx.Transform:SetPosition(target.Transform:GetWorldPosition())
				if attacker:HasTag("burning_bombs") then
					local firecircle = SpawnPrefab("firebomb_firecircle")
					firecircle:SetCaster(attacker)
					firecircle.sparklevel = inst.sparklevel+2
					firecircle.Transform:SetPosition(target.Transform:GetWorldPosition())
				end
			end
			inst:SetSparkLevel(0)
			inst:PushEvent("sparksploded")
		else
			inst:SetSparkLevel(inst.sparklevel+1)
		end
	end)
	inst.components.weapon:SetOverrideStimuliFn(function(inst)
		if inst.sparklevel >= 3 then
			return "kb"
		end
		return nil
	end)
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "lavaarena_firebomb"
	
	inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
	
	inst:AddComponent("aoespell")
	inst.components.aoespell:SetSpellFn(DoTheFireBomb)
	
	inst.DoExplosion = DoExplosion

	inst:ListenForEvent("onremove", function(inst)
		if inst.sparkfx then
			inst.sparkfx:Remove()
		end
	end)
	inst:ListenForEvent("ondropped", ondropped)
	inst:ListenForEvent("onpickup", onpickup)
end

local HOMING_SEARCH_RANGE = 12
local function FindHomingTarget(pos, attacker)
	local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, HOMING_SEARCH_RANGE, {"_combat"})
	local closest = nil
	for i, v in ipairs(ents) do
		if v ~= attacker and attacker.components.combat:IsValidTarget(v) and v.components.health and (TheNet:GetPVPEnabled() or not v:HasTag("player")) then
			if v:HasTag("player") then
				return v --prioritize players
			elseif closest == nil then
				closest = v
			end
		end
	end
	return closest
end

local HOMING_ACCEL_RANGE = 1
local HOMING_STRENGTH = 10
local MAX_HOMING_VEL = 5
local MIN_HOMING_VEL = 1
local function OnHomingUpdate(inst)
	local target = inst.homing_target
	local speedsq = inst.components.complexprojectile.velocity.x*inst.components.complexprojectile.velocity.x + inst.components.complexprojectile.velocity.z*inst.components.complexprojectile.velocity.z
	if (target == nil or not target:IsValid()) or (inst:IsNear(target, HOMING_ACCEL_RANGE) and speedsq < MIN_HOMING_VEL*MIN_HOMING_VEL) then return end
	local angle = inst:GetAngleToPoint(target.Transform:GetWorldPosition())-inst:GetRotation()
	local z_accel = math.sin(angle*DEGREES)
	local x_accel = math.cos(angle*DEGREES)
	local currenttime = GetTime()
	local dt = currenttime - (inst.last_homing_update_time or currenttime)
	local new_x = inst.components.complexprojectile.velocity.x+(x_accel*dt)*HOMING_STRENGTH
	local new_z = inst.components.complexprojectile.velocity.z-(z_accel*dt)*HOMING_STRENGTH
	local newspeedsq = new_x*new_x + new_z*new_z
	if (newspeedsq > speedsq) and (newspeedsq > MAX_HOMING_VEL*MAX_HOMING_VEL) then
		local newspeed = math.sqrt(newspeedsq)
		local speed = math.sqrt(speedsq)
		new_x = (new_x)/newspeed * speed
		new_z = (new_z)/newspeed * speed
	end
	inst.components.complexprojectile.velocity.x = new_x
	inst.components.complexprojectile.velocity.z = new_z

	inst.last_homing_update_time = currenttime
end

local function OnProjectileHit(inst)
	DoExplosion(inst, inst.thrower, inst:GetPosition())
	if inst.should_bounce and inst.bounces < inst.sparklevel+1 then
		inst.components.complexprojectile:SetHorizontalSpeed(15)
		inst.components.complexprojectile:SetGravity(-25)
		inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 1, 0))
		inst.components.complexprojectile.usehigharc = true
		inst.bounces = inst.bounces + 1
		inst:Throw(inst:GetPosition(), inst.thrower, false)
	else
		inst:Remove()
	end
end

data.projectile_postinit = function(inst)
	inst.persists = false

	inst.bounces = 0
	inst.prev_targets = {}

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(DEATHMATCH_TUNING.FIREBOMB_THROW_EXPLOSION_DAMAGE)
	
	inst:AddComponent("locomotor")

	inst:AddComponent("complexprojectile")
	inst.components.complexprojectile:SetHorizontalSpeed(18) --default 15
	inst.components.complexprojectile:SetGravity(-50) --default -25
	inst.components.complexprojectile:SetLaunchOffset(Vector3(0, 2.5, 0))
	inst.components.complexprojectile:SetOnHit(OnProjectileHit)
	
	--inst.components.complexprojectile.usehigharc = false
	
	function inst:Throw(pos, attacker, should_turn)
		if not attacker:IsValid() then
			inst:Remove()
			return
		end
		if inst.bounces <= 0 and not inst.should_home and inst:GetDistanceSqToPoint(pos:Get()) <= 5*5 then
			inst.components.complexprojectile.usehigharc = false
		end
		if should_turn == nil or should_turn then
			inst.direction:set(attacker:GetRotation())
		end
		if inst.should_home then
			inst.components.complexprojectile:SetHorizontalSpeed(15)
			inst.components.complexprojectile:SetGravity(-25)
			inst.homing_target = FindHomingTarget(pos, attacker)
			if inst.homing_task == nil then
				inst.homing_task = inst:DoPeriodicTask(0, OnHomingUpdate)
			end
		end
		inst.thrower = attacker
		inst.components.complexprojectile:Launch(pos, attacker)
	end
end

data.explosion_postinit = function(inst)
	inst:ListenForEvent("animover", inst.Remove)
	inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_explo")
end

data.procfx_postinit = function(inst)
	inst:ListenForEvent("animover", inst.Remove)
	inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_explo")
end

return data
