require "behaviours/faceentity"
require "behaviours/standandattack"

local RANGE = 8

local ElementalBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetFaceTargetFn(inst)
	return inst.components.follower:GetLeader()
end
local function KeepFaceTargetFn(inst, target)
    return not target:HasTag("notarget")
end

function ElementalBrain:OnStart()
	local root = PriorityNode(
	{
		WhileNode(function() return self.inst.components.combat.target ~= nil end, "Has Target",
			PriorityNode({
				StandAndAttack(self.inst)
			}, 0.25)
		),
		FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
	}
	)

	self.bt = BT(self.inst, root)
end

return ElementalBrain