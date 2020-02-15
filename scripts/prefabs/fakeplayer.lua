local assets = {}

local prefabs = {
	"wilson"
}

local function fn()
	local inst = CreateEntity()
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	
	inst.Transform:SetFourFaced(inst)
	
	inst.AnimState:SetBank("wilson")
	inst.AnimState:SetBuild("wilson")
	inst.AnimState:PlayAnimation("idle")
	
	inst.AnimState:Hide("ARM_carry")
	inst.AnimState:Hide("HAT")
	inst.AnimState:Hide("HAIR_HAT")
	inst.AnimState:Show("HAIR_NOHAT")
	inst.AnimState:Show("HAIR")
	inst.AnimState:Show("HEAD")
	inst.AnimState:Hide("HEAD_HAT")

	
	function inst:CopySkin(player)
		local function copyskin()
			local headskin = player.components.skinner.skin_name
			if string.sub(headskin, -5) == "_none" then
				headskin = string.sub(headskin, 0, -6)
			end
			SetSkinsOnAnim(inst.AnimState, player.prefab, headskin, player.components.skinner.clothing)
		end
		inst:AddTag("player")
		copyskin()
	end
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:AddComponent("skinner")
	
	return inst
end

return Prefab("fakeplayer", fn, assets, prefabs)