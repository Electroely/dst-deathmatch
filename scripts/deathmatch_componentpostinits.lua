--i'll move all component postinits to this file... eventually.
local G = GLOBAL

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
