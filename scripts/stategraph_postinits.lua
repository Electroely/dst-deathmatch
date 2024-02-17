local TIMEOUT = 2
local function ToggleOffPhysics(inst)
    inst.sg.statemem.isphysicstoggle = true
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
end
local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
end

local function GetState_focusattack(isclient)
	return State
    {
        name = "focusattack",
        tags = { "doing", "busy", "nodangle" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
	        if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
            end
            inst.AnimState:PlayAnimation("channel_pre")
            inst.AnimState:PushAnimation("channel_loop", true)
            if inst.bufferedaction ~= nil then
                inst.sg.statemem.action = inst.bufferedaction
            end
			if isclient then
				inst:PerformPreviewBufferedAction()
			end
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),

			TimeEvent(6 * FRAMES, function(inst)
				inst:PerformBufferedAction()
			end),

			TimeEvent(12 * FRAMES, function(inst)
				inst.sg:GoToState("idle")
			end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
	        if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
        end,
    }
end

local function GetState_shelluse(isclient)
	return State
    {
        name = "shelluse",
        tags = { "doing", "busy", "nodangle" },

        onenter = function(inst, timeout)
			local timeout = timeout or 2
            inst.sg:SetTimeout(timeout)
			inst.sg.statemem.timeout = timeout
            inst.components.locomotor:Stop()
	        if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
            end
            --inst.AnimState:PlayAnimation("hide_idle")
            if inst.bufferedaction ~= nil then
                inst.sg.statemem.action = inst.bufferedaction
            end
			if isclient then
				inst:PerformPreviewBufferedAction()
			else
				inst:PerformBufferedAction()
			end
        end,
        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
	        if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
        end,
    }
end

local combat_jump_start = State{ -- literally copypaste of combat_leap but with modifications
	name = "combat_jump_start",
	tags = { "aoe", "doing", "busy", "nointerrupt", "nomorph" },

	onenter = function(inst)
		inst.components.locomotor:Stop()
		inst.sg:SetTimeout(.2)
		inst.AnimState:PlayAnimation("jump_pre")

		local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		if weapon ~= nil and weapon.components.aoetargeting ~= nil and weapon.components.aoetargeting.targetprefab ~= nil then
			local buffaction = inst:GetBufferedAction()
			if buffaction ~= nil and buffaction.pos ~= nil then
				inst.sg.statemem.targetfx = SpawnPrefab(weapon.components.aoetargeting.targetprefab)
				if inst.sg.statemem.targetfx ~= nil then
					inst.sg.statemem.targetfx.Transform:SetPosition(buffaction.pos:Get())
					inst.sg.statemem.targetfx:ListenForEvent("onremove", OnRemoveCleanupTargetFX, inst)
				end
			end
		end
	end,

	events =
	{
		EventHandler("combat_jump", function(inst, data)
			inst.sg.statemem.leap = true
			inst.sg:GoToState("combat_jump", {
				targetfx = inst.sg.statemem.targetfx,
				data = data,
			})
		end),
	},
	
	ontimeout = function(inst)
		if inst.AnimState:AnimDone() then
			if inst.AnimState:IsCurrentAnimation("jump_pre") then
				inst:PerformBufferedAction()
			else
				inst.sg:GoToState("idle")
			end
		end
	end,

	onexit = function(inst)
		if not inst.sg.statemem.leap and inst.sg.statemem.targetfx ~= nil and inst.sg.statemem.targetfx:IsValid() then
			(inst.sg.statemem.targetfx.KillFX or inst.sg.statemem.targetfx.Remove)(inst.sg.statemem.targetfx)
		end
	end,
}

local combat_jump = State{
	name = "combat_jump",
	tags = { "aoe", "doing", "busy", "nointerrupt", "nopredict", "nomorph" },

	onenter = function(inst, data)
		if data ~= nil then
			inst.sg.statemem.targetfx = data.targetfx
			data = data.data
			if data ~= nil and
				data.targetpos ~= nil and
				data.weapon ~= nil and
				data.weapon.components.aoeweapon_leap ~= nil and
				inst.AnimState:IsCurrentAnimation("jump_pre") then
				ToggleOffPhysics(inst)
				inst.AnimState:PlayAnimation("jumpout")
				inst.AnimState:SetTime(3*FRAMES)
				inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
				inst.sg.statemem.startingpos = inst:GetPosition()
				inst.sg.statemem.weapon = data.weapon
				inst.sg.statemem.targetpos = data.targetpos
				if inst.sg.statemem.startingpos.x ~= data.targetpos.x or inst.sg.statemem.startingpos.z ~= data.targetpos.z then
					inst:ForceFacePoint(data.targetpos:Get())
					inst.Physics:SetMotorVel(math.sqrt(distsq(inst.sg.statemem.startingpos.x, inst.sg.statemem.startingpos.z, data.targetpos.x, data.targetpos.z)) / (14 * FRAMES), 0 ,0)
				end
				return
			end
		end
		--Failed
		inst.sg:GoToState("idle", true)
	end,

	timeline =
	{
		TimeEvent(4 * FRAMES, function(inst)
			if inst.sg.statemem.targetfx ~= nil and inst.sg.statemem.targetfx:IsValid() then
				(inst.sg.statemem.targetfx.KillFX or inst.sg.statemem.targetfx.Remove)(inst.sg.statemem.targetfx)
				inst.sg.statemem.targetfx = nil
			end
		end),
		TimeEvent(14 * FRAMES, function(inst)
			ToggleOnPhysics(inst)
			inst.Physics:Stop()
			inst.Physics:SetMotorVel(0, 0, 0)
			inst.Physics:Teleport(inst.sg.statemem.targetpos.x, 0, inst.sg.statemem.targetpos.z)
			--ShakeAllCameras(CAMERASHAKE.VERTICAL, .7, .015, .8, inst, 20)
			inst.sg:RemoveStateTag("nointerrupt")
			if inst.sg.statemem.weapon:IsValid() then
				inst.sg.statemem.weapon.components.aoeweapon_leap:DoLeap(inst, inst.sg.statemem.startingpos, inst.sg.statemem.targetpos)
			end
		end),
	},

	events =
	{
		EventHandler("animover", function(inst)
			if inst.AnimState:AnimDone() then
				inst.sg:GoToState("idle")
			end
		end),
	},

	onexit = function(inst)
		if inst.sg.statemem.isphysicstoggle then
			ToggleOnPhysics(inst)
			inst.Physics:Stop()
			inst.Physics:SetMotorVel(0, 0, 0)
			local x, y, z = inst.Transform:GetWorldPosition()
			if TheWorld.Map:IsPassableAtPoint(x, 0, z) and not TheWorld.Map:IsGroundTargetBlocked(Vector3(x, 0, z)) then
				inst.Physics:Teleport(x, 0, z)
			else
				inst.Physics:Teleport(inst.sg.statemem.targetpos.x, 0, inst.sg.statemem.targetpos.z)
			end
		end
		if inst.sg.statemem.targetfx ~= nil and inst.sg.statemem.targetfx:IsValid() then
			(inst.sg.statemem.targetfx.KillFX or inst.sg.statemem.targetfx.Remove)(inst.sg.statemem.targetfx)
		end
	end,
}

local combat_jump_start_client = State
{
	name = "combat_jump_start",
	tags = { "doing", "busy", "nointerrupt" },

	onenter = function(inst)
		inst.components.locomotor:Stop()
		inst.AnimState:PlayAnimation("jump_pre",false)

		inst:PerformPreviewBufferedAction()
		inst.sg:SetTimeout(TIMEOUT)
	end,

	onupdate = function(inst)
		if inst:HasTag("doing") then
			if inst.entity:FlattenMovementPrediction() then
				inst.sg:GoToState("idle", "noanim")
			end
		elseif inst.bufferedaction == nil then
			inst.sg:GoToState("idle")
		end
	end,

	ontimeout = function(inst)
		inst:ClearBufferedAction()
		inst.sg:GoToState("idle")
	end,
}

local shellattack_pre = State{
	name = "shellattack_pre", --shell attack
	tags = {"attack", "busy"},
	
	onenter = function(inst, target)
		--inst.AnimState:PlayAnimation("")
		inst.AnimState:SetScale(0,0,0)
		inst.ram_attempt = 0
		inst.components.locomotor:Stop()
		inst.Physics:Stop()
		inst.snortoiseanim = SpawnPrefab("snortoisedummy")
		inst.snortoiseanim.entity:SetParent(inst.entity)
		inst.snortoiseanim.AnimState:PlayAnimation("attack2_pre")
		inst.snortoiseanim.AnimState:SetTime(12*FRAMES)
		inst.sg.statemem.interrupted = true
		if inst.requestmousepos then
			inst.requestmousepos:push()
		end
	end,

	timeline=
	{
		TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/turtillus/hide_pre")
		--inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_mech_med_sharp")
		
		end),
	},

	events=
	{
		EventHandler("animqueueover", function(inst) 
			inst.sg.statemem.interrupted = false
			inst.sg:GoToState("shellattack_loop") 
		end),
	},
	
	onexit = function(inst)
		if inst.sg.statemem.interrupted then
			inst.AnimState:SetScale(1,1,1)
			if inst.snortoiseanim ~= nil then
				inst.snortoiseanim:Remove()
			end
		end
	end

}

local shellattack_loop = State{
	name = "shellattack_loop",
	tags = {"attack", "busy", "nointerrupt", "spinning", "shell"},
	
	onenter = function(inst, target)
	--DisableAltAttack(inst)
	if inst.requestmousepos then
		inst.requestmousepos:push()
	end
	inst.ram_attempt = inst.ram_attempt + 1
	inst.components.combat.externaldamagetakenmultipliers:SetModifier("shell", 0.01)
	inst.components.combat.multiplier = 0.5
	inst.components.combat:StartAttack()
	inst.components.locomotor:Stop()
	inst.Physics:Stop()
	inst.snortoiseanim.AnimState:PlayAnimation("attack2_loop", true)
	inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/turtillus/attack2_LP", "shell_loop")
	--inst.components.locomotor:WalkForward()
	inst.sg.statemem.initpos = inst:GetPosition()
	inst.sg.statemem.spinstate = "init"
	inst.sg.statemem.spinspeed = 2
	inst.sg.statemem.attacktarget = inst.components.combat.target
	--inst:FacePoint(inst.sg.statemem.attacktarget:GetPosition())
	--[[local pos = TheWorld.components.lavaarenaevent ~= nil and TheWorld.components.lavaarenaevent:GetArenaCenterPoint() or (inst:GetPosition()+Vector3(1,0,0))
	local offset = inst:GetPosition() - pos
	if offset:Length() < 8 then
		offset = offset:GetNormalized()*8
	end]]
	if inst._spintargetpos ~= nil then
		inst.sg.statemem.targetpos = inst:GetPosition() + inst._spintargetpos
	end
	if inst.sg.statemem.targetpos == nil then
		inst.sg.statemem.targetpos = inst:GetPosition()+Vector3(1,0,0)
	end
	inst:FacePoint(inst.sg.statemem.targetpos:Get())
	inst.Transform:SetRotation(inst:GetAngleToPoint(inst.sg.statemem.targetpos:Get()))
	inst.Physics:SetMotorVel(inst.sg.statemem.spinspeed, 0, 0)
	--inst._spintask = inst:DoPeriodicTask(TUNING.SHADOW_BISHOP.ATTACK_TICK/2, DoSwarmAttack)
	inst.sg.statemem.interrupted = true
end,

onupdate = function(inst)
	if inst.sg.statemem.spinstate == "init" then
		if inst.sg.statemem.spinspeed < 8 then
			inst.sg.statemem.spinspeed = inst.sg.statemem.spinspeed * 2
			inst.Transform:SetRotation(inst:GetAngleToPoint(inst.sg.statemem.targetpos:Get()))
		else 
			inst.sg.statemem.spinstate = "full"
		end
		inst.Physics:SetMotorVel(inst.sg.statemem.spinspeed, 0, 0)
	elseif inst.sg.statemem.spinstate == "full" then
		local initoffset = inst.sg.statemem.initpos - inst.sg.statemem.targetpos 
		local currentoffset = inst:GetPosition() - inst.sg.statemem.targetpos 
		-- check if we're past that
		if ((((initoffset.x >= 0) and (currentoffset.x <= 0)) or ((initoffset.x <= 0) and (currentoffset.x >= 0))) and
		(((initoffset.z >= 0) and (currentoffset.z <= 0)) or ((initoffset.z <= 0) and (currentoffset.z >= 0)))) or (inst.sg.statemem.spinspeed > 32) then
			inst.sg.statemem.spinstate = "slowing"
			if inst.requestmousepos then
				inst.requestmousepos:push()
			end
		else
			inst.sg.statemem.spinspeed = inst.sg.statemem.spinspeed * 1.1
			inst.Physics:SetMotorVel(inst.sg.statemem.spinspeed, 0, 0)
		end
	elseif inst.sg.statemem.spinstate == "slowing" then
		if inst.sg.statemem.spinspeed > 8 then
			inst.sg.statemem.spinspeed = inst.sg.statemem.spinspeed / 1.2
		else
			inst.sg.statemem.spinstate = "stopping"
			if inst.requestmousepos then
				inst.requestmousepos:push()
			end
		end
		inst.Physics:SetMotorVel(inst.sg.statemem.spinspeed, 0, 0)
	elseif inst.sg.statemem.spinstate == "stopping" then
		if inst.sg.statemem.spinspeed > 1 then
			inst.sg.statemem.spinspeed = inst.sg.statemem.spinspeed / 2
		else
			if inst.requestmousepos then
				inst.requestmousepos:push()
			end
			inst.sg.statemem.spinspeed = 0
			inst.sg.statemem.spinstate = "done"
		end
		inst.Physics:SetMotorVel(inst.sg.statemem.spinspeed, 0, 0)
	elseif inst.sg.statemem.spinstate == "done" then
		if inst.ram_attempt >= 10 then
			inst.sg.statemem.interrupted = false
			inst.sg:GoToState("shellattack_pst")
			inst.components.combat.externaldamagetakenmultipliers:SetModifier("shell", 1)
			inst.ram_attempt = 0
			--inst:DoTaskInTime(15, EnableAltAttack)
		else
			inst.sg.statemem.interrupted = false
			inst.sg:GoToState("shellattack_loop")
		end
	end
end,

onexit = function(inst)
	inst.SoundEmitter:KillSound("shell_loop")
	if inst._spintask ~= nil then
		inst._spintask:Cancel()
		inst._spintask = nil
	end
	inst.sg.statemem.shell = nil
	inst.sg.statemem.spinstate = nil
	inst.sg.statemem.spinspeed = nil
	inst.sg.statemem.targetpos = nil
	inst.sg.statemem.initpos = nil
	inst.components.combat.externaldamagetakenmultipliers:SetModifier("shell", 1)
	if inst.sg.statemem.attacktarget ~= nil then
		inst.components.combat:SetTarget(inst.sg.statemem.attacktarget)
		inst.sg.statemem.attacktarget = nil
	end
	if inst.sg.statemem.interrupted then
		inst.AnimState:SetScale(1,1,1)
		if inst.snortoiseanim ~= nil then
			inst.snortoiseanim:Remove()
		end
	end
	--inst:SetNormalPhysics()
	inst.components.combat.multiplier = 1		
	--inst.components.locomotor.walkspeed = 0
end,

timeline=
{
		TimeEvent(3*FRAMES, function(inst) inst.sg.statemem.shell = true end),
},

	events=
	{
		EventHandler("attacked", function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/turtillus/shell_impact") end)
	},

}

local shellattack_pst = State{
	name = "shellattack_pst",
	tags = {"busy"},

	onenter = function(inst, cb)
		inst.Physics:Stop()
		inst.AnimState:SetScale(1,1,1)
		if inst.snortoiseanim ~= nil then
			inst.snortoiseanim:Remove()
		end
		inst.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/turtillus/hide_pst")
		inst.sg:GoToState("hide") 
		inst.AnimState:PlayAnimation("hide_idle")
		inst.AnimState:SetTime(14*FRAMES)
	end,

	events=
	{
		EventHandler("animover", function(inst) 
		end),
	},
}

local revivecorpse = State{
        name = "revivecorpse_deathmatch",

        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            inst.sg:GoToState("dolongaction",
                TUNING.REVIVE_CORPSE_ACTION_TIME *
                (inst.components.corpsereviver ~= nil and inst.components.corpsereviver:GetReviverSpeedMult() or 1) *
                (target ~= nil and target.components.revivablecorpse ~= nil and target.components.revivablecorpse:GetReviveSpeedMult() or 1)
            )
        end,
    }
	
local quickrevive = State{
	name = "quickrevive_deathmatch", 
	tags = {"busy"},
	onenter = function(inst)
		if inst.components.playercontroller ~= nil then
			inst.components.playercontroller:RemotePausePrediction()
			inst.components.playercontroller:Enable(false)
		end
		inst.AnimState:PlayAnimation("corpse_revive")
		inst.components.health:SetInvincible(true)
		inst:ShowActions(false)
		inst:SetCameraDistance(14)
	end,
	events = {
		EventHandler("animover", function(inst)
			inst.sg:GoToState("idle")
		end),
	},
	onexit = function(inst)
            inst:ShowActions(true)
            inst:SetCameraDistance()
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
            inst.components.health:SetInvincible(false)

            if not inst.sg.statemem.physicsrestored then
                inst.Physics:ClearCollisionMask()
                inst.Physics:CollidesWith(COLLISION.WORLD)
                inst.Physics:CollidesWith(COLLISION.OBSTACLES)
                inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
                inst.Physics:CollidesWith(COLLISION.CHARACTERS)
                inst.Physics:CollidesWith(COLLISION.GIANTS)
            end

            SerializeUserSession(inst)
	end,
}

local focusattack_quick = State{
	name = "focusattack_quick",
	onenter = function(inst)
		inst.sg:GoToState("focusattack", 0.5)
	end,
}


return {
	wilson = {
		focusattack = GetState_focusattack(false),
		focusattack_quick = focusattack_quick,
		combat_jump_start = combat_jump_start,
		combat_jump = combat_jump,
		shellattack_pre = shellattack_pre,
		shellattack_loop = shellattack_loop,
		shellattack_pst = shellattack_pst,
		shelluse = GetState_shelluse(false),
		revivecorpse_deathmatch = revivecorpse,
		quickrevive_deathmatch = quickrevive,
	},
	wilson_client = {
		focusattack = GetState_focusattack(true),
		focusattack_quick = focusattack_quick,
		shelluse = GetState_shelluse(true),
		combat_jump_start = combat_jump_start_client,
	}
}