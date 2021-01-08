--i'll move all component postinits to this file... eventually.
local G = GLOBAL
local UpValues = require("deathmatch_upvaluehacker")
local GetUpValue = UpValues.Get
local ReplaceUpValue = UpValues.Replace

AddComponentPostInit("inventory", function(self)
	--make it so that items picked up mid-match can't go into the
	--first 4 slots
	if self.inst:HasTag("player") then
		local GiveItem_old = self.GiveItem
		function self:GiveItem(inst, slot, src_pos, ...)
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
		end
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

AddComponentPostInit("combat", function(self, inst)
	if G.TheNet:GetServerGameMode() == "deathmatch" then
		local engage_old = self.EngageTarget
		self.EngageTarget = function(self, target)
			if not inst:HasTag("player") and target and target:HasTag("player") then
				target.numattackers = target.numattackers + 1
			end
			return engage_old(self, target)
		end
		
		local drop_old = self.DropTarget
		self.DropTarget = function(self, hasnexttarget)
			if not inst:HasTag("player") and self.target and self.target:HasTag("player") then
				self.target.numattackers = self.target.numattackers - 1
			end
			return drop_old(self, hasnexttarget)
		end
		
		local validt_old = self.IsValidTarget
		self.IsValidTarget = function(self, target)
			if target and not inst:HasTag("player") and target:HasTag("player") and target.numattackers >= 2 then
				--print("player has too many attackers")
				return false
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

AddComponentPostInit("playeractionpicker", function(self)
	local GetRightClickActions_Old = self.GetRightClickActions
	self.GetRightClickActions = function(self, position, target)
		local actions = {}
		if self.inst.components.playercontroller and self.inst.components.playercontroller.reticule and
			self.inst.components.playercontroller.reticule.inst and self.inst.components.playercontroller.reticule.reticule then
			local equipitem = self.inst.components.playercontroller.reticule.inst
			if equipitem ~= nil and equipitem:IsValid() then
				actions = self:GetPointActions(position, equipitem, true)

				if equipitem.components.aoetargeting ~= nil then
					return (#actions <= 0 or actions[1].action == G.ACTIONS.CASTAOE) and actions or {}
				end
			end
		elseif self.inst.components.playercontroller.reticuleitemslot ~= nil then
			local equipitem = self.inst.replica.inventory:GetEquippedItem(self.inst.components.playercontroller.reticuleitemslot)
			if equipitem ~= nil and equipitem:IsValid() then
				actions = self:GetPointActions(position, equipitem, true)

				if equipitem.components.aoetargeting ~= nil then
					return (#actions <= 0 or actions[1].action == G.ACTIONS.CASTAOE) and actions or {}
				end
			end
		else
			actions = GetRightClickActions_Old(self, position, target)
		end
		return actions or {}
	end
end)

AddComponentPostInit("playercontroller", function(self) 
	--no need to hold force attack for players
	local ValidateAttackTarget_old = GetUpValue(self.GetAttackTarget, "ValidateAttackTarget")
	ReplaceUpValue(self.GetAttackTarget, "ValidateAttackTarget", function(combat, target, force_attack, x, z, has_weapon, reach, ...)
		if target and target:HasTag("player") then
			force_attack = true
		end
		return ValidateAttackTarget_old(combat, target, force_attack, x, z, has_weapon, reach, ...)
	end)
	-- aoetargeting compability for non-hand slot items
	local HasAOETargeting_Old = self.HasAOETargeting
	self.HasAOETargeting = function(self)
		local test = HasAOETargeting_Old(self)
		if not test then
			local item = self.inst.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.HEAD)
			item = item or self.inst.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.BODY)
			return item ~= nil
				and item.components.aoetargeting ~= nil
				and item.components.aoetargeting:IsEnabled()
				and not (self.inst.replica.rider ~= nil and self.inst.replica.rider:IsRiding())
		end
		return test
	end
	
	local TryAOETargeting_Old = self.TryAOETargeting
	self.TryAOETargeting = function(self, slot)
		if slot == nil then
			TryAOETargeting_Old(self)
			SendModRPCToServer(GetModRPC(modname, "deathmatch_currentreticule_change"), G.EQUIPSLOTS.HANDS)
			self.reticuleitemslot = G.EQUIPSLOTS.HANDS
		else 
			local item = self.inst.replica.inventory:GetEquippedItem(G.EQUIPSLOTS[string.upper(slot)])
			if item ~= nil and
				item.components.aoetargeting ~= nil and
				item.components.aoetargeting:IsEnabled() and
				not (self.inst.replica.rider ~= nil and self.inst.replica.rider:IsRiding()) then
				SendModRPCToServer(GetModRPC(modname, "deathmatch_currentreticule_change"), G.EQUIPSLOTS[string.upper(slot)])
				self.reticuleitemslot = G.EQUIPSLOTS[string.upper(slot)]
				item.components.aoetargeting:StartTargeting()
			end
		end
	end
	
	local RefreshReticule_Old = self.RefreshReticule
	self.RefreshReticule = function(self)
		RefreshReticule_Old(self)
		if self.reticule == nil then
			local item = self.inst.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.HEAD)
			if item and item.components.reticule ~= nil then
				self.reticule = item.components.reticule
			else
				item = self.inst.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.BODY)
				if item and item.components.reticule ~= nil then
					self.reticule = item.components.reticule
				else
					self.reticule = nil
				end
			end
		end
		if self.reticule ~= nil and self.reticule.reticule == nil and (self.reticule.mouseenabled or G.TheInput:ControllerAttached()) then
			self.reticule:CreateReticule()
		end
	end
end)
