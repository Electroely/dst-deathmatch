--i'll move all component postinits to this file... eventually.
local G = GLOBAL
local UpValues = require("deathmatch_upvaluehacker")
local GetUpValue = UpValues.Get
local ReplaceUpValue = UpValues.Replace

local function GetDummySlot(inv)
	local empty = 9
	for slot = 1, inv.maxslots do
		local item = inv.itemslots[slot]
		if item and item.prefab == "invslotdummy" then
			return slot, true
		end
		if item == nil and slot < empty then
			empty = slot
		end
	end
	return empty
end
AddComponentPostInit("inventory", function(self)
	--make it so that items picked up mid-match can't go into the
	--first 4 slots
	if self.inst:HasTag("player") then
		--[[local GiveItem_old = self.GiveItem
		function self:GiveItem(inst, slot, src_pos, ...)
			if inst.itemcountlimit then
				local count = self:GetTotalItemCount(inst.prefab) - (self:IsHolding(inst) and 1 or 0)
				if count >= inst.itemcountlimit then
					self:DropItem(inst, true, true)
					return
				end
			end
			for i = 1, self.maxslots do
				if inst ~= nil and self.itemslots[i] ~= nil and self.itemslots[i].components.stackable ~= nil and inst.components.stackable ~= nil and self.itemslots[i].prefab == inst.prefab and not self.itemslots[i].components.stackable:IsFull() then
					return GiveItem_old(self, inst, slot, src_pos, ...)
				end
			end
			local dm = G.TheWorld.components.deathmatch_manager
			if slot == nil and 
				(inst.prevslot == nil or self.itemslots[inst.prevslot] ~= nil) and
				dm and dm.matchinprogress then
				for i = 5, self.maxslots, 1 do
					if self.itemslots[i] == nil then
						slot = i
						break
					end
				end
			end
			return GiveItem_old(self, inst, slot, src_pos, ...)
		end]]
		local DropItem_old = self.DropItem
		function self:DropItem(item, ...)
			if item and item:HasTag("invslotdummy") then
				local rtn = {DropItem_old(self, item, ...)}
				local equipitem = self:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
				if equipitem ~= nil then
					self:Unequip(GLOBAL.EQUIPSLOTS.HANDS)
					equipitem.components.equippable:ToPocket()
					self.silentfull = true
					self:GiveItem(equipitem)
					self.silentfull = false
				end
				return GLOBAL.unpack(rtn)
			end
			return DropItem_old(self, item, ...)
		end
		local SetActiveItem_old = self.SetActiveItem
		function self:SetActiveItem(item, ...)
			if item and item:HasTag("invslotdummy") then
				local rtn = {SetActiveItem_old(self, item, ...)}
				local equipitem = self:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
				if equipitem ~= nil then
					self:Unequip(GLOBAL.EQUIPSLOTS.HANDS)
					equipitem.components.equippable:ToPocket()
					self.silentfull = true
					self:GiveItem(equipitem)
					self.silentfull = false
				end
				return GLOBAL.unpack(rtn)
			end
			return SetActiveItem_old(self, item, ...)
		end
		local Equip_old = self.Equip
		function self:Equip(inst, ...)
			if inst and inst.itemcountlimit then
				local count = self:GetTotalItemCount(inst.prefab) - (self:IsHolding(inst) and 1 or 0)
				if count >= inst.itemcountlimit then
					self:DropItem(inst, true, true)
					return
				end
			end
			if inst and inst.components.equippable and inst.components.equippable.equipslot == GLOBAL.EQUIPSLOTS.HANDS then
				local oldslot = self:GetItemSlot(inst) or GetDummySlot(self)
				local dummy = GLOBAL.SpawnPrefab("invslotdummy")
				if self.itemslots[oldslot] ~= nil and self.itemslots[oldslot] ~= inst then
					self:DropItem(self.itemslots[oldslot], true, true)
				end
				local rtn = {Equip_old(self, inst, ...)}
				self:GiveItem(dummy, oldslot)
				return GLOBAL.unpack(rtn)
			end
			return Equip_old(self, inst, ...)
		end
		local Unequip_old = self.Unequip
		function self:Unequip(equipslot, ...)
			if equipslot == GLOBAL.EQUIPSLOTS.HANDS then
				local slot, wasdummy = GetDummySlot(self)
				local items = self:GetItemsWithTag("invslotdummy")
				for k, v in pairs(items) do
					v:Remove()
				end
				local item = self:GetEquippedItem(equipslot)
				if wasdummy and item ~= nil then
					item.prevslot = slot
				end
			end
			return Unequip_old(self, equipslot, ...)
		end
	end
	
	function self:GetTotalItemCount(prefab)
		local count = 0
		local containers = {}
		for slot, item in pairs(self.itemslots) do
			if item.prefab == prefab then
				count = count + (item.components.stackable and item.components.stackable:StackSize() or 1)
			end
			if item.components.container then
				table.insert(containers, item)
			end
		end
		for k, v in pairs(G.EQUIPSLOTS) do
			local item = self:GetEquippedItem(v)
			if item ~= nil and item.prefab == prefab then
				count = count + (item.components.stackable and item.components.stackable:StackSize() or 1)
			end
			if item ~= nil and item.components.container then
				table.insert(containers, item)
			end
		end
		local activeitem = self:GetActiveItem()
		if activeitem ~= nil then
			if activeitem.prefab == prefab then
				count = count + (activeitem.components.stackable and activeitem.components.stackable:StackSize() or 1)
			end
			if activeitem.components.container then
				table.insert(containers, activeitem)
			end
		end
		for k, v in pairs(containers) do
			for slot, item in pairs(v.components.container:GetItems()) do
				if item.prefab == prefab then
					count = count + (item.components.stackable and item.components.stackable:StackSize() or 1)
				end
			end
		end
		return count
	end
end)


AddComponentPostInit("healthsyncer", function(self, inst)
	local oldGetpct = self.GetPercent
	self.GetPercent = function(self)
		if self.inst:HasTag("playerghost") or self.inst:HasTag("spectator") then
			return 0
		else
			return oldGetpct(self)
		end
	end
end)

local MAX_ATTACKERS = 1
AddComponentPostInit("combat", function(self, inst)
	if G.TheNet:GetServerGameMode() == "deathmatch" then
		local engage_old = self.EngageTarget
		self.EngageTarget = function(self, target)
			if not self.inst:HasTag("ignoreattackerlimit") and not self.inst:HasTag("player") and target and target:HasTag("player") and target.attackers then
				target.attackers[self.inst] = true
			end
			return engage_old(self, target)
		end
		
		local drop_old = self.DropTarget
		self.DropTarget = function(self, hasnexttarget)
			if not self.inst:HasTag("ignoreattackerlimit") and not self.inst:HasTag("player") and self.target and self.target:HasTag("player") and self.target.attackers then
				self.target.attackers[self.inst] = nil
			end
			return drop_old(self, hasnexttarget)
		end
		
		local validt_old = self.IsValidTarget
		self.IsValidTarget = function(self, target)
			if not self.inst:HasTag("ignoreattackerlimit") and target ~= nil and not self.inst:HasTag("player") and target:HasTag("player") and target.attackers and not target.attackers[self.inst] then
				local numattackers = 0
				for attacker, v in pairs(target.attackers) do
					if v and attacker:IsValid() then
						numattackers = numattackers + 1
						if numattackers > MAX_ATTACKERS then
							return false
						end
					else
						target.attackers[attacker] = nil
					end
				end
			end
			return validt_old(self, target)
		end
	end
end)

AddClassPostConstruct("components/combat_replica", function(self, inst)
	if G.TheNet:GetServerGameMode() == "deathmatch" then
		local IsValidTarget_Old = self.IsValidTarget
		self.IsValidTarget = function(self, target)
			if target ~= nil and target.components and 
				((target.components.teamer and target.components.teamer:IsTeamedWith(self.inst))
				or (target:HasTag("spectator") or self.inst:HasTag("spectator"))) then
					return false
			else
				return IsValidTarget_Old(self, target)
			end
		end
		
		local IsAlly_Old = self.IsAlly
		self.IsAlly = function(self, guy)
			if guy and guy.components and
			guy.components.teamer and guy.components.teamer:IsTeamedWith(self.inst) then
				return true
			else
				return IsAlly_Old(self, guy)
			end
		end
		
		local CanBeAttacked_Old = self.CanBeAttacked
		self.CanBeAttacked = function(self, attacker)
			if attacker and (attacker.components and attacker.components.teamer and
			attacker.components.teamer:IsTeamedWith(self.inst) or
			self.inst:HasTag("spectator") or attacker:HasTag("spectator")) then
				return false
			else
				return CanBeAttacked_Old(self, attacker)
			end
		end
	end
end)

-- AddComponentPostInit("playeractionpicker", function(self)
	-- local GetRightClickActions_Old = self.GetRightClickActions
	-- self.GetRightClickActions = function(self, position, target)
		-- local actions = {}
		-- if self.inst.components.playercontroller and self.inst.components.playercontroller.reticule and
			-- self.inst.components.playercontroller.reticule.inst and self.inst.components.playercontroller.reticule.reticule then
			-- local equipitem = self.inst.components.playercontroller.reticule.inst
			-- if equipitem ~= nil and equipitem:IsValid() then
				-- actions = self:GetPointActions(position, equipitem, true)

				-- if equipitem.components.aoetargeting ~= nil then
					-- return (#actions <= 0 or actions[1].action == G.ACTIONS.CASTAOE) and actions or {}
				-- end
			-- end
		-- elseif self.inst.components.playercontroller.reticuleitemslot ~= nil then
			-- local equipitem = self.inst.replica.inventory:GetEquippedItem(self.inst.components.playercontroller.reticuleitemslot)
			-- if equipitem ~= nil and equipitem:IsValid() then
				-- actions = self:GetPointActions(position, equipitem, true)

				-- if equipitem.components.aoetargeting ~= nil then
					-- return (#actions <= 0 or actions[1].action == G.ACTIONS.CASTAOE) and actions or {}
				-- end
			-- end
		-- else
			-- actions = GetRightClickActions_Old(self, position, target)
		-- end
		-- return actions or {}
	-- end
-- end)

local priority_prefabs = {
	pickup_lighthealing = true,
}
AddComponentPostInit("playercontroller", function(self) 
	--adjusted spacebar priority for deathlatch
	local GetActionButtonAction_old = self.GetActionButtonAction
	function self:GetActionButtonAction(force_target, ...)
		if force_target == nil then
			local x,y,z = self.inst.Transform:GetWorldPosition()
			local ents = G.TheSim:FindEntities(x,y,z,8, nil, {"INLIMBO","NOCLICK"}, {"_inventoryitem","corpse", "stalkerbloom"})
			local backup_target = nil
			for k, v in pairs(ents) do
				if priority_prefabs[v.prefab] and self.inst:IsNear(v, 1) then
					force_target = v
				end
				if backup_target == nil and ((v:HasTag("_inventoryitem") and v.replica.inventoryitem:CanBePickedUp() and not v:HasTag("catchable"))
					or (v:HasTag("corpse") and self.inst.components.teamer:IsTeamedWith(v))) 
					or (v:HasTag("stalkerbloom") and v:HasTag("pickable")) then
					backup_target = v
					break
				end
			end
			if force_target == nil then
				force_target = backup_target
			end
		end
		print("doing spacebar with ",force_target)
		return GetActionButtonAction_old(self, force_target, ...)
	end
	
	--no need to hold force attack for players
	local ValidateAttackTarget_old = GetUpValue(self.GetAttackTarget, "ValidateAttackTarget")
	ReplaceUpValue(self.GetAttackTarget, "ValidateAttackTarget", function(combat, target, force_attack, x, z, has_weapon, reach, ...)
		if target and target:HasTag("player") then
			force_attack = true
		end
		return ValidateAttackTarget_old(combat, target, force_attack, x, z, has_weapon, reach, ...)
	end)
	-- aoetargeting compability for non-hand slot items
	-- local HasAOETargeting_Old = self.HasAOETargeting
	-- self.HasAOETargeting = function(self)
		-- local test = HasAOETargeting_Old(self)
		-- if not test then
			-- local item = self.inst.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.HEAD)
			-- item = item or self.inst.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.BODY)
			-- return item ~= nil
				-- and item.components.aoetargeting ~= nil
				-- and item.components.aoetargeting:IsEnabled()
				-- and not (self.inst.replica.rider ~= nil and self.inst.replica.rider:IsRiding())
		-- end
		-- return test
	-- end
	
	-- local TryAOETargeting_Old = self.TryAOETargeting
	-- self.TryAOETargeting = function(self, slot)
		-- if slot == nil then
			-- TryAOETargeting_Old(self)
			-- SendModRPCToServer(GetModRPC(modname, "deathmatch_currentreticule_change"), G.EQUIPSLOTS.HANDS)
			-- self.reticuleitemslot = G.EQUIPSLOTS.HANDS
		-- else 
			-- local item = self.inst.replica.inventory:GetEquippedItem(G.EQUIPSLOTS[string.upper(slot)])
			-- if item ~= nil and
				-- item.components.aoetargeting ~= nil and
				-- item.components.aoetargeting:IsEnabled() and
				-- not (self.inst.replica.rider ~= nil and self.inst.replica.rider:IsRiding()) then
				-- SendModRPCToServer(GetModRPC(modname, "deathmatch_currentreticule_change"), G.EQUIPSLOTS[string.upper(slot)])
				-- self.reticuleitemslot = G.EQUIPSLOTS[string.upper(slot)]
				-- item.components.aoetargeting:StartTargeting()
			-- end
		-- end
	-- end
	
	-- local RefreshReticule_Old = self.RefreshReticule
	-- self.RefreshReticule = function(self)
		-- RefreshReticule_Old(self)
		-- if self.reticule == nil then
			-- local item = self.inst.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.HEAD)
			-- if item and item.components.reticule ~= nil then
				-- self.reticule = item.components.reticule
			-- else
				-- item = self.inst.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.BODY)
				-- if item and item.components.reticule ~= nil then
					-- self.reticule = item.components.reticule
				-- else
					-- self.reticule = nil
				-- end
			-- end
		-- end
		-- if self.reticule ~= nil and self.reticule.reticule == nil and (self.reticule.mouseenabled or G.TheInput:ControllerAttached()) then
			-- self.reticule:CreateReticule()
		-- end
	-- end
end)
