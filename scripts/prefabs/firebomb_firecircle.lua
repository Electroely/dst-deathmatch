local assets = {
	Asset("ANIM", "anim/fire.zip"),
}

local function fx_fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetBank("fire")
    inst.AnimState:SetBuild("fire")
    inst.AnimState:SetRayTestOnBB(true)
	inst.AnimState:PlayAnimation("level3",true)
	inst.AnimState:SetScale(0.2,0.2,0.2)
	
	inst:AddTag("FX")
	
	inst.persists = false
	
	inst.entity:SetPristine()
	
	return inst
end

local RANGE = 2
local DAMAGE = DEATHMATCH_TUNING.SKILLTREE_FIREBOMB_FIRECIRCLE_DAMAGE_PER_LEVEL
local DURATION = 5
local function DamageNearbyEntities(inst)
	if inst.caster == nil or not inst.caster:IsValid() then
		inst:Remove()
		return
	end
	local x,y,z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x,y,z, RANGE, {"_combat"})
	for k, v in pairs(ents) do
		if v.components.health and inst.caster.components.combat:IsValidTarget(v) then
			v.components.health:DoDelta(-DAMAGE*inst.sparklevel)
		end
	end
end

local function SpawnFX(inst)
	local fx = SpawnPrefab("firebomb_firefx")
	inst:AddChild(fx)
	return fx
end

local RINGS = 4
local SPACING = 1.3

local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddNetwork()
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end

	inst.sparklevel = inst.sparklevel or 1
	
	--spawn fx
	inst.fx = {}
	for i = 1, RINGS do
		if i == 1 then
			local fx = SpawnFX(inst)
			table.insert(inst.fx, fx)
		else
			local dist = (RANGE/RINGS)*(i-1)
			local c = 2*PI*dist
			local num_fx = math.ceil(c/SPACING)
			local start_angle = math.random()*360
			for j = 1, num_fx do
				local angle = start_angle+(360/num_fx)*(j-1)
				local x = math.cos(angle*DEGREES)*dist
				local z = math.sin(angle*DEGREES)*dist
				inst:DoTaskInTime(FRAMES*(i-1), function(inst)
					local fx = SpawnFX(inst)
					fx.Transform:SetPosition(x,0,z)
					table.insert(inst.fx, fx)
				end)
			end
		end
	end
	
	function inst:Kill()
		if inst.damagetask ~= nil then
			inst.damagetask:Cancel()
			inst.damagetask = nil
		end
		for k, v in pairs(inst.fx) do
			v:DoTaskInTime(math.random()*0.5, v.Remove)
		end
		inst:DoTaskInTime(0.5, inst.Remove)
	end
	
	inst.damagetask = inst:DoPeriodicTask(1, DamageNearbyEntities)
	inst.killtask = inst:DoTaskInTime(DURATION+0.1, inst.Kill)
	
	return inst
end

return Prefab("firebomb_firefx", fx_fn, assets), Prefab("firebomb_firecircle", fn)