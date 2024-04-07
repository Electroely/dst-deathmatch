
local books = {
	"fossil",
	"elemental",
}

local function FossilCast(inst, caster, pos)
	return true
end

local SUMMON_DURATION = 10
local PLAYER_CHECK_RADIUS = 1.5
local function ElementalCast(inst, caster, pos)
	local summon = SpawnPrefab("lavaarena_elemental")
	local offset = Vector3(0,0,0)
	local players_nearby = TheSim:FindEntities(pos.x, pos.y, pos.z, PLAYER_CHECK_RADIUS, {"player"})
	if #players_nearby > 0 then
		--add an offset so players dont get pushed out by the golem
		offset = FindWalkableOffset(pos, 2*PI*math.random(), PLAYER_CHECK_RADIUS, 10, false, true) or offset
	end
	pos = pos + offset
	summon.Transform:SetPosition(pos:Get())
	summon:FacePoint(caster.Transform:GetWorldPosition())
	if summon.SetCaster then
		summon:SetCaster(caster)
	end
	if summon.sg then
		summon.sg:GoToState("spawn")
	end
	if summon.components.follower then
		summon.components.follower:SetLeader(caster)
	end
	if summon.components.teamer then
		summon.components.teamer:SetTeam(caster.components.teamer:GetTeam())
	end
	if inst.components.rechargeable then
		inst.components.rechargeable:Discharge(DEFAULT_COOLDOWN_TIME*2)
	end
	summon:DoTaskInTime(SUMMON_DURATION, function(summon)
		summon.components.health:Kill()
	end)
	summon.persists = false
	return true
end

BOOK_KB_TIME = {}

local KNOCKBACK_COOLDOWN = 5
local function OnAttack(inst, attacker, target)
	local last_attack_time = BOOK_KB_TIME[target]
	if last_attack_time == nil or (GetTime() - last_attack_time) > KNOCKBACK_COOLDOWN then
		BOOK_KB_TIME[target] = GetTime()
	end
end
local function OverrideStimuli(inst, attacker, target)
	local last_attack_time = BOOK_KB_TIME[target]
	if last_attack_time == nil or (GetTime() - last_attack_time) > KNOCKBACK_COOLDOWN then
		return "kb"
	end
	return nil
end

local function MakeBookPostInit(name, spellcastfn)
	local function onequip(inst, owner)
		owner.AnimState:OverrideSymbol("book_closed", "swap_book_"..name, "book_closed")
		DoEquipCooldown(inst)
	end
	local function onunequip(inst, owner)
		owner.AnimState:ClearOverrideSymbol("book_closed")
	end
	local function fn(inst)
		inst:AddComponent("inventoryitem")
		
		inst:AddComponent("equippable")
		inst.components.equippable:SetOnEquip(onequip)
		inst.components.equippable:SetOnUnequip(onunequip)
		
		inst:AddComponent("weapon")
		inst.components.weapon:SetDamage(DEATHMATCH_TUNING.FORGE_MAGE_BOOK_DAMAGE)
		inst.components.weapon:SetOnAttack(OnAttack)
		inst.components.weapon:SetOverrideStimuliFn(OverrideStimuli)
		
		inst:AddComponent("inspectable")
		
		inst:AddComponent("aoespell")
		inst.components.aoespell:SetSpellFn(spellcastfn)
		
		inst:AddComponent("rechargeable")
		inst.components.rechargeable:SetOnDischargedFn(function(inst) inst.components.aoetargeting:SetEnabled(false) end)
		inst.components.rechargeable:SetOnChargedFn(function(inst) inst.components.aoetargeting:SetEnabled(true) end)
	end
	return fn
end

return {
	fossil_postinit = MakeBookPostInit("fossil", FossilCast),
	elemental_postinit = MakeBookPostInit("elemental", ElementalCast)
}