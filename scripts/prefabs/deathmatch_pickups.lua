local pickup_data = {
	lighthealing = {
		health = function() return (math.random(50, 100)/100)*20 end,
		colour = { 0.2, 1, 0.2, 1},
		symbol = "health"
	},
	
	lightdamaging = {
		buff = {
			damage = 1.5,
			duration = 10
		},
		colour = {1, 0.2, 0.2, 1},
		symbol = "attack"
	},
	
	lightdefense = {
		buff = {
			defense = 0.5,
			duration = 15
		},
		colour = {0.2, 0.2, 1, 1},
		symbol = "defense"
	},
	
	lightspeed = {
		buff = {
			speed = 1.5,
			duration = 10
		},
		colour = {1, 1, 0.2, 1},
		symbol = "speed"
	},
	
	cooldown = {
		customfn = function(inst, player) 
			if player and player.components.inventory then
				for k, v in pairs(player.components.inventory.itemslots) do
					if v and v.components.rechargeable then
						v.components.rechargeable:SetPercent(1)
					end
				end
				for k, v in pairs(EQUIPSLOTS) do
					local item = player.components.inventory:GetEquippedItem(v)
					if item ~= nil and item.components.rechargeable then
						item.components.rechargeable:SetPercent(1)
					end
				end
			end
		end,
		colour = {0.6, 0, 0.6, 1},
		symbol = "cooldown",
	}
}




local prefabs = {
"small_puff"
}

local assets = {
	Asset("ANIM", "anim/pickup.zip")
}

local function MakePickUp(name)

	local function fn()
		local data = pickup_data[name]

		local inst = CreateEntity()
		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()
		
		MakeInventoryPhysics(inst)
		
		inst.AnimState:SetBuild("pickup")
		inst.AnimState:SetBank("pickup")
		inst.AnimState:PlayAnimation("idle")
		inst.AnimState:OverrideSymbol("symbol_nil", "pickup", "symbol_"..data.symbol)
		inst.AnimState:SetMultColour(unpack(data.colour))
		
		if not TheWorld.ismastersim then
			return inst
		end
		
		inst:AddComponent("inventoryitem")
		inst.components.inventoryitem:SetOnPickupFn(function(inst, doer)
			if data.health ~= nil and doer.components.health then
				if type(data.health) == "number" then
					doer.components.health:DoDelta(data.health)
				elseif type(data.health) == "function" then
					doer.components.health:DoDelta(data.health(doer))
				end
			end
			if data.customfn ~= nil then
				data.customfn(inst, doer)
			end
			if data.buff ~= nil then
				if data.buff.damage and doer.components.combat then
					if doer.deathmatch_pickuptasks[name.."attack"] ~= nil then
						doer.deathmatch_pickuptasks[name.."attack"]:Cancel()
						doer.deathmatch_pickuptasks[name.."attack"] = nil
					end
					doer.components.combat.externaldamagemultipliers:SetModifier("pickup", data.buff.damage, name)
					local function removebuff(doer)
						doer.components.combat.externaldamagemultipliers:RemoveModifier("pickup", name) 
						doer:RemoveEventCallback("clearpickupbuffs", removebuff)
					end
					doer:ListenForEvent("clearpickupbuffs", removebuff)
					doer.deathmatch_pickuptasks[name.."attack"] = doer:DoTaskInTime(data.buff.duration, removebuff)
				end
				if data.buff.defense and doer.components.combat then
					if doer.deathmatch_pickuptasks[name.."defense"] ~= nil then
						doer.deathmatch_pickuptasks[name.."defense"]:Cancel()
						doer.deathmatch_pickuptasks[name.."defense"] = nil
					end
					doer.components.combat.externaldamagetakenmultipliers:SetModifier("pickup", data.buff.defense, name)
					local function removebuff(doer) 
						doer.components.combat.externaldamagetakenmultipliers:RemoveModifier("pickup", name) 
						doer:RemoveEventCallback("clearpickupbuffs", removebuff)
					end
					doer.deathmatch_pickuptasks[name.."defense"] = doer:ListenForEvent("clearpickupbuffs", removebuff)
					doer:DoTaskInTime(data.buff.duration, removebuff)
				end
				if data.buff.speed and doer.components.locomotor then
					if doer.deathmatch_pickuptasks[name.."speed"] ~= nil then
						doer.deathmatch_pickuptasks[name.."speed"]:Cancel()
						doer.deathmatch_pickuptasks[name.."speed"] = nil
					end
					doer.components.locomotor:SetExternalSpeedMultiplier(doer, name, data.buff.speed)
					local function removebuff(doer) 
						doer.components.locomotor:RemoveExternalSpeedMultiplier(doer, name) 
						doer:RemoveEventCallback("clearpickupbuffs", removebuff)
					end
					doer:ListenForEvent("clearpickupbuffs", removebuff)
					doer.deathmatch_pickuptasks[name.."speed"] = doer:DoTaskInTime(data.buff.duration, removebuff)
				end
			end
			inst:DoTaskInTime(0, inst.Remove)
			return true
		end)
		local oldpickupfn = inst.components.inventoryitem.OnPickup
		inst.components.inventoryitem.OnPickup = function(self, pickupguy)
			local puff = SpawnPrefab("small_puff")
			puff.Transform:SetPosition(inst:GetPosition():Get())
			oldpickupfn(self, pickupguy)
		end
		
		inst.Fade = function(inst)
			local r, g, b, o = unpack(data.colour)
			inst.fadetask = inst:DoPeriodicTask(0, function(inst)
				o = o - 0.01
				r = r-(data.colour[1]/100)
				g = g-(data.colour[2]/100)
				b = b-(data.colour[3]/100)
				if o > 0 then
					inst.AnimState:SetMultColour(r, g, b, o)
				else
					inst:Remove()
				end
			end)
		end
		
		return inst
	end
	return Prefab("pickup_"..name, fn, assets, prefabs)
end

local res = {}
for k,v in pairs(pickup_data) do
	table.insert(res, MakePickUp(k))
end

return unpack(res)
