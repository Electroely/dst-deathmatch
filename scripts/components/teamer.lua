local function OnTeamDirty(inst)
	inst.components.teamer:SetTeam(inst.components.teamer.net_team:value())
	inst.components.teamer.net_team:set_local(inst.components.teamer.team)
end

local Teamer = Class(function(self, inst)

	self.inst = inst
	self.team = 0
	
	self.net_team = net_byte(inst.GUID, "teamer.net_team", "teamdirty")
	
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
	if self.team ~= 0 and target and target.components and target.components.teamer then
		return target.components.teamer.team == self.team
	else
		return false
	end
end

function Teamer:GetTeam()
	return self.team
end

return Teamer
