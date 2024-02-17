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

-------------------------------------------------------------------------
----------------------- Prefab building functions -----------------------
-------------------------------------------------------------------------

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end

local function MakeBuff(name, onattachedfn, onextendedfn, ondetachedfn, duration)
    local function OnAttached(inst, target)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)

        if onattachedfn ~= nil then
            onattachedfn(inst, target)
        end
    end

    local function OnExtended(inst, target)
        inst.components.timer:StopTimer("buffover")
        inst.components.timer:StartTimer("buffover", duration)

        if onextendedfn ~= nil then
            onextendedfn(inst, target)
        end
    end

    local function OnDetached(inst, target)
        if ondetachedfn ~= nil then
            ondetachedfn(inst, target)
        end

        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()

        if not TheWorld.ismastersim then
            --Not meant for client!
            inst:DoTaskInTime(0, inst.Remove)
            return inst
        end

        inst.entity:AddTransform()

        --[[Non-networked entity]]
        --inst.entity:SetCanSleep(false)
        inst.entity:Hide()
        inst.persists = false

        inst:AddTag("CLASSIFIED")

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff:SetDetachedFn(OnDetached)
        inst.components.debuff:SetExtendedFn(OnExtended)
        inst.components.debuff.keepondespawn = true

        inst:AddComponent("timer")
        inst.components.timer:StartTimer("buffover", duration)
        inst:ListenForEvent("timerdone", OnTimerDone)

        return inst
    end

    return Prefab("buff_"..name, fn)
end

------------------------------------------------------------------------
local buff_prefabs = {}
for name, data in pairs(pickup_data) do
	if data.buff then
		local buff = data.buff
		local function OnAttached(inst, target)
			if buff.damage then
				target.components.combat.externaldamagemultipliers:SetModifier("pickup_"..name, buff.damage)
			end
			if buff.defense then
				target.components.combat.externaldamagetakenmultipliers:SetModifier("pickup_"..name, buff.defense)
			end
			if buff.speed then
				target.components.locomotor:SetExternalSpeedMultiplier(target, "pickup_"..name, buff.speed)
			end
			inst:ListenForEvent("clearpickupbuffs", function() inst.components.debuff:Stop() end, inst)
		end
		local function OnExtended(inst, target)

		end
		local function OnDetached(inst, target)
			if buff.damage then
				target.components.combat.externaldamagemultipliers:RemoveModifier("pickup_"..name)
			end
			if buff.defense then
				target.components.combat.externaldamagetakenmultipliers:RemoveModifier("pickup_"..name)
			end
			if buff.speed then
				target.components.locomotor:RemoveExternalSpeedMultiplier(target, "pickup_"..name)
			end
		end
		table.insert(buff_prefabs, MakeBuff("pickup_"..name, OnAttached, OnExtended, OnDetached, data.buff.duration))
	end
end


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
				doer:AddDebuff("buff_pickup_"..name, "buff_pickup_"..name)
			end
			inst:DoTaskInTime(0, inst.Remove)
			return true
		end)
		local oldpickupfn = inst.components.inventoryitem.OnPickup
		inst.components.inventoryitem.OnPickup = function(self, pickupguy)
			local puff = SpawnPrefab("small_puff")
			puff.Transform:SetPosition(inst:GetPosition():Get())
			return oldpickupfn(self, pickupguy)
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
for k,v in pairs(buff_prefabs) do
	table.insert(res, v)
end

return unpack(res)
