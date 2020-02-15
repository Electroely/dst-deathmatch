local BalloonMaker = Class(function(self, inst)
    self.inst = inst
	self.enabled = net_bool(inst.GUID, "balloonmaker.enabled", "balloonmakerenableddirty")
	self.enabled:set(true)
end)

function BalloonMaker:SetEnabled(bool)
	self.enabled:set(bool)
end

function BalloonMaker:MakeBalloon(doer, x,y,z)
    local balloon = SpawnPrefab("balloon")
    if balloon then
        balloon.Transform:SetPosition(x,y,z)
		balloon.components.combat:SetDefaultDamage(100)
		if balloon.components.teamer ~= nil then
			balloon.components.teamer:SetTeam(doer.components.teamer.team)
			balloon:ListenForEvent("teamchange", function(_, data) balloon.components.teamer:SetTeam(data.team) end, doer)
		end
		local attack_delay = .1 + math.random() * .2
		balloon:ListenForEvent("death", function(inst)
			inst:DoTaskInTime(attack_delay, function(inst)
				inst.components.combat:DoAreaAttack(inst, 4, nil, nil, nil, { "INLIMBO" })
			end)
		end)
		if self.inst.components.rechargeable ~= nil then
			self.inst.components.rechargeable:StartRecharge()
		end
    end
end -- lazy way of making custom balloon

return BalloonMaker