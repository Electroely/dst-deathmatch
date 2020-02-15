local function fn()
	local inst = require("prefabs/blowdart_lava2").fn()
	
	inst:RemoveTag("rechargeable")
	inst:SetPrefabNameOverride("blowdart_lava2")
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:RemoveComponent("rechargeable")
	inst.components.inventoryitem:ChangeImageName("blowdart_lava2")
	inst.components.weapon.attackwear = 0
	local onprojectilelaunch_old = inst.components.weapon.LaunchProjectile
	inst.components.weapon.LaunchProjectile = function(...)
		inst.components.aoetargeting:SetEnabled(false)
		inst.components.finiteuses:Use()
		if not inst.readytoremove then
			if onprojectilelaunch_old then
				onprojectilelaunch_old(...)
			end
			if inst.done then
				inst.readytoremove = true
			end
		else
			inst:DoTaskInTime(0, inst.Remove)
		end
	end
	
	inst.done = false
	inst.readytoremove = false
	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(5)
	inst.components.finiteuses:SetUses(5)
	inst.components.finiteuses:SetOnFinished(function() inst.done = true end)
	
	local aoe_cast_old = inst.components.aoespell.aoe_cast
	inst.components.aoespell.aoe_cast = function(...)
		aoe_cast_old(...)
		inst.components.finiteuses:Use(5)
		inst.readytoremove = true
		inst.components.aoetargeting:SetEnabled(false)
	end
	
	return inst
end

return Prefab("blowdart_lava_temp", fn)