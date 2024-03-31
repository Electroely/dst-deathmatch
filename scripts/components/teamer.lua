local function OnTeamDirty(inst)
	inst.components.teamer:SetTeam(inst.components.teamer.net_team:value())
	inst.components.teamer.net_team:set_local(inst.components.teamer.team)
end

local Teamer = Class(function(self, inst)

	self.inst = inst
	self.team = 0
	
	self.net_team = net_byte(inst.GUID, "teamer.net_team", "teamdirty")

	if not TheNet:IsDedicated() then
		DEATHMATCH_TEAMERS[inst] = true
	end
	
	inst:ListenForEvent("teamdirty", OnTeamDirty)
end)

function Teamer:SetTeam(teamnum)
	local oldteam = self.team
	if TheWorld.ismastersim then
		self.net_team:set(teamnum)
		if TheWorld.net.deathmatch and TheWorld.net.deathmatch[self.inst.userid] then
			TheWorld.net.deathmatch[self.inst.userid].team_local = teamnum
			TheWorld.net:SetTeam(self.inst.userid, teamnum)
		end
		if oldteam ~= teamnum then
			self.inst:PushEvent("teamchange", { team = teamnum })
		end
	end
	self.team = teamnum
end

function Teamer:IsTeamedWith(target)
	if self.inst == target then
		return true
	elseif self.team ~= 0 and target and target.components and target.components.teamer then
		return target.components.teamer.team == self.team
	else
		local ourleader = self.inst.replica.follower and self.inst.replica.follower:GetLeader()
		if ourleader == target then
			return true
		end
		local theirleader = target.replica and target.replica.follower and target.replica.follower:GetLeader()
		if theirleader == self.inst or (theirleader ~= nil and ourleader == theirleader) then
			return true
		end

		return false
	end
end

function Teamer:GetTeam()
	return self.team
end

return Teamer
