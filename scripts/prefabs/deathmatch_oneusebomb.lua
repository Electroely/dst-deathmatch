local assets = {}

local prefabs = {
	"laavarena_firebomb"
}

local function onputininventory(inst, data)
	data.owner:PushEvent("pushdeathmatchtip", "FIREBOMBEXPLAIN")
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
	inst:ListenForEvent("onpickup", onputininventory)
	
	return inst
end

return Prefab("deathmatch_oneusebomb", fn, assets, prefabs)