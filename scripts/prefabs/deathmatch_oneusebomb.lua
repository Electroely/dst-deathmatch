local assets = {}

local prefabs = {"laavarena_firebomb"}

local function onputininventory(inst, data)
	local owner = data.owner
	local items = owner.components.inventory.itemslots
	local ourslot = 0
	for k, v in pairs(items) do if v == inst then ourslot = k break end end
	local oldslot = ourslot
	while ourslot <= 4 or (items[ourslot] ~= nil and not items[ourslot] == inst) do
		ourslot = ourslot + 1
	end
	if oldslot ~= ourslot then
		owner.components.inventory:DropItem(inst)
		owner.components.inventory:GiveItem(inst, ourslot)
	end
end

local fn = function()
	local inst = SpawnPrefab("lavaarena_firebomb")
	
	inst:SetPrefabNameOverride("laavarena_firebomb")
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:RemoveTag("rechargeable")
	local old = inst.components.aoespell.aoe_cast
	inst.components.aoespell:SetAOESpell(function(...)
		old(...)
		inst:Remove()
	end)
	
	inst:ListenForEvent("sparksploded", inst.Remove)
	--inst:ListenForEvent("onpickup", onputininventory)
	
	return inst
end

return Prefab("deathmatch_oneusebomb", fn, assets, prefabs)