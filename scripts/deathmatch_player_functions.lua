--file for functions to make deathmatch_manager.lua cleaner

local function ApplyLobbyInvincibility(inst, enabled)
	if enabled then
		inst.components.combat.externaldamagetakenmultipliers:SetModifier("deathmatchinvincibility", 0)
		inst.components.health:SetAbsorptionAmount(1)
		inst.components.health:SetPercent(1)
	else
		inst.components.combat.externaldamagetakenmultipliers:SetModifier("deathmatchinvincibility", 1)
		inst.components.health:SetAbsorptionAmount(0)
	end
end

local function DoDeathmatchTeleport(inst, pos)
	local oldpos = inst:GetPosition()
	local x, y, z = pos:Get()
	local has_remote_authority = false
	if inst.components.playercontroller then
		has_remote_authority = inst.components.playercontroller.remote_authority
		inst.components.playercontroller.remote_authority = false
	end
	inst.Transform:SetPosition(x,y,z)
	if inst.woby ~= nil and inst.woby:IsValid() then
		inst.woby.Transform:SetPosition(x+1,y,z)
	end
	if oldpos:DistSq(pos) > 3600 then --60*60
		inst:SnapCamera()
	end
	if inst.components.playercontroller then
		inst:DoTaskInTime(1, function(inst)
			inst.components.playercontroller.remote_authority = has_remote_authority
		end)
	end
end

local function UpdateRevivalHealth(inst)
	inst.revivals = inst.revivals or 0
	local pct = TheWorld.components.deathmatch_manager:GetRevivalHealthForPlayer(inst)
	inst.components.revivablecorpse:SetReviveHealthPercent(pct)
end

local function DisableAFK(inst)
	if inst:HasTag("afk") then
		inst:RemoveTag("afk")
		inst:RemoveEventCallback("afk_end", DisableAFK)
	elseif inst:HasTag("spectator_perma") then
		inst:RemoveTag("spectator_perma")
	end
	TheNet:Announce(inst:GetDisplayName().." is no longer AFK.", inst.entity, nil, "afk_stop")
	if inst:HasTag("spectator") and (TheWorld.net:GetMatchStatus() == DEATHMATCH_MATCHSTATUS.IDLE or TheWorld.net:GetMatchStatus() == DEATHMATCH_MATCHSTATUS.STARTING) then
		TheWorld.components.deathmatch_manager:ToggleSpectator(inst)
	end
end
local function EnableAFK(inst, force)
	if inst:HasTag("spectator_perma") or inst:HasTag("afk") then
		return
	end
	if force then
		inst:AddTag("spectator_perma")
	else
		inst:AddTag("afk")
		inst:ListenForEvent("afk_end", DisableAFK)
	end
	TheNet:Announce(inst:GetDisplayName().." is now AFK.", inst.entity, nil, "afk_start")
	if not (inst:HasTag("spectator") or TheWorld.net:IsPlayerInMatch(inst.userid)) then
		TheWorld.components.deathmatch_manager:ToggleSpectator(inst)
	end
end

local function postinit_fn(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst.ApplyLobbyInvincibility = ApplyLobbyInvincibility
	inst.DoDeathmatchTeleport = DoDeathmatchTeleport
	inst.UpdateRevivalHealth = UpdateRevivalHealth
	inst.EnableAFK = EnableAFK
	inst.DisableAFK = DisableAFK
end

return postinit_fn