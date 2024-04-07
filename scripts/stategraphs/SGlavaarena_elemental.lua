require("stategraphs/commonstates")

local HIT_COOLDOWN = 1

local events = {
	CommonHandlers.OnAttack(),
	CommonHandlers.OnDeath(),
	EventHandler("attacked", function(inst)
		local last_hit_time = inst.last_hit_time or 0
        if (not inst.components.health:IsDead()) and (not inst.sg:HasStateTag("nointerrupt")) and (GetTime()-last_hit_time > HIT_COOLDOWN) then
            inst.sg:GoToState("hit")
        end
	end)
}

local states=
{
    State{
        name = "spawn",
        tags = {"busy", "nointerrupt"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("spawn")
            inst.AnimState:PushAnimation("idle", true)
            inst:AddTag("notarget")
            --inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeplant/eye_emerge")
        end,

        events=
        {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle") 
            end),
        },

        onexit = function(inst)
            inst:RemoveTag("notarget")
        end,

    },

    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle", true)
        end,


    },

    State{
        name = "hit",
        tags = {"busy", "hit"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },

    },

    State{
        name = "attack",
        tags = {"attack", "canrotate"},
        onenter = function(inst)
            if inst.components.combat.target then
                inst:ForceFacePoint(inst.components.combat.target.Transform:GetWorldPosition())
            end
            inst.AnimState:PlayAnimation("attack")
        end,

        timeline=
        {
            TimeEvent(5*FRAMES, function(inst) inst.components.combat:DoAttack()
            --inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeplant/eye_bite")
            end),
            TimeEvent(16*FRAMES, function(inst) inst.components.combat:DoAttack()
				--inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeplant/eye_bite")
			end),
        },

        events=
        {
            EventHandler("animqueueover", function(inst)
                if inst.components.combat.target and
                    distsq(inst.components.combat.target:GetPosition(),inst:GetPosition()) <=
                    inst.components.combat:CalcAttackRangeSq(inst.components.combat.target) then

                    inst.sg:GoToState("attack")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            RemovePhysicsColliders(inst)
            --inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeplant/eye_retract")

        end,
    },
}

return StateGraph("lavaarena_elemental", states, events, "idle")