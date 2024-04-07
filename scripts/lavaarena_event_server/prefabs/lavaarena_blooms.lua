local function IsAlliedWith(inst, target)
	local caster = inst.caster
	if caster and ((caster == target) or (caster.components.teamer and caster.components.teamer:IsTeamedWith(target) or (target.components.follower and target.components.follower:GetLeader() == caster))) then
		return true
	end
	return false
end
local function OnUpdate(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, inst.range, nil, nil, {"player", "deathmatch_minion"})
	for k, v in pairs(ents) do
		if inst:IsAlliedWith(v) then
			v:AddDebuff("buff_healingstaff_ally", "buff_healingstaff_ally")
		else
			v:AddDebuff("buff_healingstaff_enemy", "buff_healingstaff_enemy")
		end
	end
end
local function Kill(inst)
	if inst.bufftask then
		inst.bufftask:Cancel()
		inst.bufftask = nil
	end
	for k, v in pairs(inst.blooms) do
		v:Kill(true)
	end
	inst:Remove()
end
local function SetCaster(inst, caster)
	inst.caster = caster
	inst:ListenForEvent("onremove", function() inst:Kill() end, caster)
	inst:ListenForEvent("death", function() inst:Kill() end, caster)
end

local function bloom_masterpostinit(inst)
	inst.persists = false
	
	inst.AnimState:PlayAnimation("in_"..inst.variation)
	inst.AnimState:PushAnimation("idle_"..inst.variation)
		
	function inst:Kill(withdelay)
		local delay = withdelay and math.random() or 0
		inst:DoTaskInTime(delay, function(inst)
			inst.AnimState:PushAnimation("out_"..inst.variation, false)
			inst:ListenForEvent("animover", inst.Remove)
		end)
	end
	
	function inst:SetBuffed(isbuffed)
		if isbuffed then
			inst.AnimState:Show("buffed_hide_layer")
		else
			inst.AnimState:Hide("buffed_hide_layer")
		end
	end
end

local function healblooms_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --[[Non-networked entity]]

	inst:AddTag("healingstaffcircle")
	
	inst.caster = nil
	inst.range = 4
	inst.blooms = {}
	inst.bufftask = inst:DoPeriodicTask(3*FRAMES, OnUpdate)
	
	inst.IsAlliedWith = IsAlliedWith
	inst.Kill = Kill
	inst.SetCaster = SetCaster
	
	function inst:SpawnBlooms()
		local bloomprefab = "lavaarena_bloom"
		for i = 1,15 do
			local pt = inst:GetPosition()
			if i == 1 then
				inst:DoTaskInTime(math.random(), function()
				local bloom = SpawnPrefab(bloomprefab)
				bloom.Transform:SetPosition(pt:Get())
				table.insert(inst.blooms, bloom)
				end)
			elseif i >= 2 and i < 7 then
				local theta = (i-1)/5 * 2 * PI
				local radius = inst.range/2
				local offset = FindWalkableOffset(pt, theta, radius, 2, false, true)
				if offset ~= nil then
					offset.x = offset.x + pt.x
					offset.z = offset.z + pt.z
					inst:DoTaskInTime(math.random(), function()
					local bloom = SpawnPrefab(bloomprefab)
					bloom.Transform:SetPosition(offset.x, 0, offset.z)
					table.insert(inst.blooms, bloom)
					end)
				end
			elseif i >= 7 then
				local theta = (i-5)/9 * 2 * PI
				local radius = inst.range
				local offset = FindWalkableOffset(pt, theta, radius, 2, false, true)
				if offset ~= nil then
					offset.x = offset.x + pt.x
					offset.z = offset.z + pt.z
					inst:DoTaskInTime(math.random(), function()
					local bloom = SpawnPrefab(bloomprefab)
					bloom.Transform:SetPosition(offset.x, 0, offset.z)
					table.insert(inst.blooms, bloom)
					end)
				end
			end
		end
	end
	inst:DoTaskInTime(0, inst.SpawnBlooms)
    return inst
end
----------------------------------------------------
local function sleepdebuff_fn()
	local inst = CreateEntity()
	inst:DoTaskInTime(0, inst.Remove)
	return inst
end
----------------------------------------------------
local function healbuff_masterpostinit(inst)
	inst:DoTaskInTime(0, inst.Remove)
	return inst
end
----------------------------------------------------

return {
	bloom_postinit = bloom_masterpostinit,
	createhealblooms = healblooms_fn,
	createsleepdebuff = sleepdebuff_fn,
	healbuff_postinit = healbuff_masterpostinit
}