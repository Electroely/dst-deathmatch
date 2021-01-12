--file for functions to make deathmatch_manager.lua cleaner

local function ApplyLobbyInvincibility(inst, enabled)
	if enabled then
		inst.components.combat.externaldamagetakenmultipliers:SetModifier("deathmatchinvincibility", 0)
		inst.components.health:SetPercent(1)
	else
		inst.components.combat.externaldamagetakenmultipliers:SetModifier("deathmatchinvincibility", 1)
	end
end

local function DoDeathmatchTeleport(inst, pos)
	local oldpos = inst:GetPosition()
	local x, y, z = pos:Get()
	inst.Transform:SetPosition(x,y,z)
	if inst.woby ~= nil and inst.woby:IsValid() then
		inst.woby.Transform:SetPosition(x+1,y,z)
	end
	if oldpos:DistSq(pos) > 3600 then --60*60
		inst:SnapCamera()
	end
end

local function postinit_fn(inst)
	inst.ApplyLobbyInvincibility = ApplyLobbyInvincibility
	inst.DoDeathmatchTeleport = DoDeathmatchTeleport
end

return postinit_fn