local hatextradata = {
	feathercrown={speedmult=1.2, headbase_hat=false},
	lightdamager={damagemult=1.1, headbase_hat=true},
	recharger={rechargemult=0.1, headbase_hat=false},
	healingflower={healrecievemult=1.25, headbase_hat=false},
	tiaraflowerpetals={healgivenmult=1.2, headbase_hat=false},
	strongdamager={damagemult=1.15, headbase_hat=true},
	crowndamager={damagemult=1.15, speedmult=1.1, rechargemult=0.1, headbase_hat=true},
	healinggarland={regen={persec=2, maxregenpercent=0.8},rechargemult=0.1,speedmult=1.1},
	eyecirclet={damagemult=1.25, rechargemult=0.1,speedmult=1.1}
}

local function UpdateDamageMults(inst, owner, isequipping)
	local bodyitem = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
	local headmult = inst.components.equippable.damagemult or 1
	local bodymult = 1
	if bodyitem ~= nil then
		bodymult = bodyitem.components.equippable.damagemult or 1
	end
	
	local totalmult = 1 + (headmult-1) + (bodymult-1)
	
	if not	isequipping then
		totalmult = 1 + (bodymult-1)
	end
	
	owner.components.combat.externaldamagemultipliers:SetModifier(owner, totalmult, "armors")
end

local function healtask(inst)
	local owner = inst.components.inventoryitem.owner
	if owner ~= nil and owner.components.health then
		if owner.components.health:GetPercent() < inst.regen.maxregenpercent and
		not owner.components.health:IsDead() and not owner:HasTag("playerghost") then
			owner.components.health:DoDelta(inst.regen.persec/10, true)
			if not inst:HasTag("regen") then
				inst:AddTag("regen")
			end
		else
			if inst:HasTag("regen") then
				inst:RemoveTag("regen")
			end
		end
	end
end

local function MasterPostInit(inst, name, build, symbol)
	if hatextradata[name] ~= nil then
		local function onequip(inst, owner)
			owner.AnimState:OverrideSymbol("swap_hat", build, "swap_hat")
			owner.AnimState:Show("HAT")
			if hatextradata[name].headbase_hat then
				owner.AnimState:Show("HAIR_HAT")
				owner.AnimState:Hide("HAIR_NOHAT")
				owner.AnimState:Hide("HAIR")
				if owner:HasTag("player") then
					owner.AnimState:Hide("HEAD")
					owner.AnimState:Show("HEAD_HAT")
				end
			end
			if inst.regen and inst.regentask == nil then
				inst.regentask = inst:DoPeriodicTask(1/10, healtask)
			end
			UpdateDamageMults(inst, owner, true)
		end
		
		local function onunequip(inst, owner)
			owner.AnimState:ClearOverrideSymbol("swap_hat")
			owner.AnimState:Hide("HAT")
			if hatextradata[name].headbase_hat then
				owner.AnimState:Hide("HAIR_HAT")
				owner.AnimState:Show("HAIR_NOHAT")
				owner.AnimState:Show("HAIR")
				if owner:HasTag("player") then
					owner.AnimState:Show("HEAD")
					owner.AnimState:Hide("HEAD_HAT")
				end
			end
			if inst.regentask ~= nil then
				inst.regentask:Cancel()
				inst.regentask = nil
			end
			UpdateDamageMults(inst, owner, false)
		end
		
		if hatextradata[name].regen ~= nil then
			inst.regen = hatextradata[name].regen
		end

		inst:AddComponent("inspectable")
		
		inst:AddComponent("inventoryitem")

		inst:AddComponent("equippable")
		inst.components.equippable:SetOnEquip(onequip)
		inst.components.equippable:SetOnUnequip(onunequip)
		inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
		inst.components.equippable.walkspeedmult = hatextradata[name].speedmult
		inst.components.equippable.cooldownmultiplier = hatextradata[name].rechargemult
		inst.components.equippable.damagemult = hatextradata[name].damagemult
		inst.components.equippable.healgivenmult = hatextradata[name].healgivenmult
		inst.components.equippable.healrecievemult = hatextradata[name].healrecievemult
	end
end

return {
	master_postinit = MasterPostInit
}
