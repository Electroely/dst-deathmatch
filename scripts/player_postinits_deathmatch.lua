PERKS_ENABLED = false
SHADOW_ENABLED = true
-------------------------------------------
local UpValues = require("deathmatch_upvaluehacker")
local GetUpValue = UpValues.Get
local ReplaceUpValue = UpValues.Replace
-------------------------------------------
local function GhostActionFilter(inst, action)
    return action.ghost_valid
end
local function ConfigurePlayerLocomotor(inst)
    inst.components.locomotor:SetSlowMultiplier(0.6)
    inst.components.locomotor.pathcaps = { player = true, ignorecreep = true } -- 'player' cap not actually used, just useful for testing
    inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED -- 4
    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED -- 6
    inst.components.locomotor.fasteronroad = true
    inst.components.locomotor:SetTriggersCreep(not inst:HasTag("spiderwhisperer"))
end
local function ConfigurePlayerActions(inst)
    if inst.components.playeractionpicker ~= nil then
        inst.components.playeractionpicker:PopActionFilter(GhostActionFilter)
    end
end
local function ShouldKnockout(inst)
    return DefaultKnockoutTest(inst) and not inst.sg:HasStateTag("yawn")
end
local function CommonActualRez(inst)
    inst.player_classified.MapExplorer:EnableUpdate(true)

    if inst.components.revivablecorpse ~= nil then
        inst.components.inventory:Show()
    else
        inst.components.inventory:Open()
        inst.components.age:ResumeAging()
    end

    inst.components.health.canheal = true
    if not GetGameModeProperty("no_hunger") then
        inst.components.hunger:Resume()
    end
    if not GetGameModeProperty("no_temperature") then
        inst.components.temperature:SetTemp() --nil param will resume temp
    end
    inst.components.frostybreather:Enable()

    MakeMediumBurnableCharacter(inst, "torso")
    inst.components.burnable:SetBurnTime(TUNING.PLAYER_BURN_TIME)
    inst.components.burnable.nocharring = true

    MakeLargeFreezableCharacter(inst, "torso")
    inst.components.freezable:SetResistance(4)
    inst.components.freezable:SetDefaultWearOffTime(TUNING.PLAYER_FREEZE_WEAR_OFF_TIME)

    inst:AddComponent("grogginess")
    inst.components.grogginess:SetResistance(3)
    inst.components.grogginess:SetKnockOutTest(ShouldKnockout)

    inst.components.moisture:ForceDry(false)

    inst.components.sheltered:Start()

    inst.components.debuffable:Enable(true)

    --don't ignore sanity any more
    inst.components.sanity.ignore = GetGameModeProperty("no_sanity")

    ConfigurePlayerLocomotor(inst)
    ConfigurePlayerActions(inst)

    if inst.rezsource ~= nil then
        local announcement_string = GetNewRezAnnouncementString(inst, inst.rezsource)
        if announcement_string ~= "" then
            TheNet:AnnounceResurrect(announcement_string, inst.entity)
        end
        inst.rezsource = nil
    end
    inst.remoterezsource = nil
end
local function doRez(inst, data)
	if data == nil then data = {} end
	inst.player_classified:SetGhostMode(false)
	CommonActualRez(inst)
	inst.components.health:SetCurrentHealth(inst.components.health:GetMaxWithPenalty())
    inst.components.health:ForceUpdateHUD(true)
	inst.components.revivablecorpse:SetCorpse(false)
	inst:PushEvent("ms_respawnedfromghost", { corpse = true, reviver = data.source })
	
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.WORLD)
	inst.Physics:CollidesWith(COLLISION.OBSTACLES)
	inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
	inst.Physics:CollidesWith(COLLISION.CHARACTERS)
	inst.Physics:CollidesWith(COLLISION.GIANTS)
	SerializeUserSession(inst)
	inst:ShowActions(true)
	inst:SetCameraDistance()
	if inst.rezhealth ~= nil then
		inst.components.health:SetPercent(inst.rezhealth)
		inst.rezhealth = nil
	end
end
---------------------------------------------------------------
local exts = require("prefabs/player_common_extensions")
local OnRespawnFromPlayerCorpse_old = exts.OnRespawnFromPlayerCorpse
exts.OnRespawnFromPlayerCorpse = function(inst, data)
	if inst:HasTag("corpse") then
		inst.rezhealth = data.health
	end
	if data and data.instant and inst.components.health and inst.components.health:IsDead() then
		doRez(inst, data)
		inst.sg:GoToState("idle")
	elseif data and data.quick and inst.components.health and inst.components.health:IsDead() then
		local delay = data.delay or 0
		inst:DoTaskInTime(delay, function(inst) 
			inst.sg:GoToState("quickrevive_deathmatch") 
			doRez(inst, data)
		end)
	else
		OnRespawnFromPlayerCorpse_old(inst, data)
	end
end
local DoActualRezFromCorpse_old = GetUpValue(OnRespawnFromPlayerCorpse_old, "DoActualRezFromCorpse")
ReplaceUpValue(OnRespawnFromPlayerCorpse_old, "DoActualRezFromCorpse", function(inst, source)
	DoActualRezFromCorpse_old(inst, source)
	if inst.rezhealth ~= nil then
		inst.components.health:SetPercent(inst.rezhealth)
		inst.rezhealth = nil
	end
end)
---------------------------------------------------------------
local function fn(inst, prefab)
	
	if not TheWorld.ismastersim then
		return
	end
	
	inst.revive = function(inst)
		inst.sg:GoToState("idle")
		doRez(inst)
	end
	
	function inst:RespawnFromShadow()
		local p = inst:GetPosition()
		SpawnPrefab("shadow_despawn").Transform:SetPosition(p.x, p.y, p.z) 
		SpawnPrefab("statue_transition_2").Transform:SetPosition(p.x, p.y, p.z) 
		inst.AnimState:SetMultColour(1,1,1,1)
		inst.Transform:SetPosition(inst.fake_body.Transform:GetWorldPosition())
		inst.sg:GoToState("quickrevive_deathmatch")
		inst:RemoveTag("playershadow")
		inst.fake_body:Remove()
	end
	
	inst:ListenForEvent("attacked", function(inst, data)
		if data and data.stimuli and data.stimuli == "kb" then
			inst:DoTaskInTime(0, function()
				local knocker = data.weapon and data.weapon:IsValid() and data.weapon or data.attacker or inst
				inst:PushEvent("knockback", {knocker = knocker or data.attacker or inst, radius = 1, strengthmult = 1})
			end)
		end
	end)
	
	inst:ListenForEvent("death", function(inst) 
		if inst.enable_shadow  and SHADOW_ENABLED then
			inst:DoTaskInTime(2.5, function() 
				inst.fake_body = SpawnPrefab("fakeplayer") 
				inst.fake_body.AnimState:PlayAnimation("death2_idle") 
				inst.fake_body:CopySkin(inst) 
				inst.fake_body.Transform:SetPosition(inst:GetPosition():Get()) 
				inst.fake_body.Transform:SetRotation(inst.Transform:GetRotation()) 
				local p = inst:GetPosition() inst.AnimState:SetMultColour(0,0,0,0.5) SpawnPrefab("shadow_despawn").Transform:SetPosition(p.x, p.y, p.z) SpawnPrefab("statue_transition_2").Transform:SetPosition(p.x, p.y, p.z) 
				inst:PushEvent("respawnfromcorpse", {quick = true}) 
				inst:AddTag("playershadow")
			end) 
		end
	end)
	--------------------------------------------------------------------------------------
	if not PERKS_ENABLED then return end
	if prefab == "willow" and TheWorld.ismastersim then
		inst.components.health.fire_damage_scale = 0
		local function OnAttack(inst, data)
			if math.random() > 0.8 then
				local fire = SpawnPrefab("houndfire")
				fire.Transform:SetPosition(inst:GetPosition():Get())
				fire.Physics:SetVel(math.random(-7,7), 0, math.random(-7,7))
			end
		end
		inst:ListenForEvent("onattackother", OnAttack)
		inst:ListenForEvent("onmissother", OnAttack)
	end
	----------------------------------------------------------------------------------------
	if prefab == "wendy" and TheWorld.ismastersim then
		inst.abi = nil
		local function KillAbi(abi)
			abi.components.health:Kill()
		end
		local function SpawnAbi(inst, target)
			local abi = SpawnPrefab("abigail")
			inst.abi = abi
			abi:AddTag("notarget")
			inst.components.leader:AddFollower(abi)
			abi.Transform:SetPosition(inst:GetPosition():Get())
			abi.components.combat:SetTarget(target)
			abi.components.combat.externaldamagetakenmultipliers:SetModifier("abi", 0)
			abi.components.combat:SetPlayerStunlock(PLAYERSTUNLOCK.NEVER)
			abi.components.teamer:SetTeam(inst.components.teamer.team)
			abi:ListenForEvent("teamchange", function(abi, data) abi.components.teamer:SetTeam(data.team) end, inst)
			abi.killtask = abi:DoTaskInTime(3, KillAbi)
			abi:ListenForEvent("onremove", function()
				inst.abi = nil
			end)
		end
		local function RefreshAbi(inst, target)
			if inst.abi ~= nil and not inst.abi.components.health:IsDead() then
				if inst.abi.killtask ~= nil then
					inst.abi.killtask:Cancel()
					inst.abi.killtask = nil
				end
				inst.abi.killtask = inst.abi:DoTaskInTime(3, KillAbi)
				inst.abi.components.combat:SetTarget(target)
			end
		end
		local function OnAttackOrMiss(inst, data)
			if inst.abi == nil and data.target ~= nil then
				SpawnAbi(inst, data.target)
			elseif data.target ~= nil then
				RefreshAbi(inst, data.target)
			end
		end
		local function OnAttacked(inst, data)
			if inst.abi == nil and data.attacker ~= nil then
				SpawnAbi(inst, data.attacker)
			elseif data.attacker ~= nil then
				RefreshAbi(inst, data.attacker)
			end
		end
		inst:ListenForEvent("onattackother", OnAttackOrMiss)
		inst:ListenForEvent("onmissother", OnAttackOrMiss)
		inst:ListenForEvent("attacked", OnAttacked)
	end
	---------------------------------------------------------------------------
	if prefab == "wx78" then
		inst.components.inventory.IsInsulated = function() return true end -- immune to stun
		local hitcountdown = 4
		local function OnAttack(inst, data)
			hitcountdown = hitcountdown - 1
			if hitcountdown == 0 then
				if data.target ~= nil and data.target:HasTag("player") then
					data.target.sg:GoToState("electrocute")
				end
				hitcountdown = 4
			end
		end
		inst:ListenForEvent("onattackother", OnAttack)
	end
	---------------------------------------------------------------------------- 
	
end

return fn
