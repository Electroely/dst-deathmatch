SHADOW_ENABLED = false
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
		inst.rezhealth = data and data.health
	end
	if data and data.instant and inst:HasTag("corpse") then
		doRez(inst, data)
		inst.sg:GoToState("idle")
	elseif data and data.quick and inst:HasTag("corpse") then
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
--------------------------------------------------------------
local function UpdateMalbatrossFeatherStats(inst)
	local _, feathers = inst.components.inventory:HasItemWithTag("malbatross_feather", 0)
	feathers = math.min(15, feathers)
	if feathers > 0 then
		inst.components.locomotor:SetExternalSpeedMultiplier(inst, "malbatross_speed", 1 + (0.02 * feathers))
		inst.components.combat.externaldamagetakenmultipliers:SetModifier("malbatrossdefense", 1 - feathers * 0.033, "malbatross_defense")
	else
		inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "malbatross_speed")
		inst.components.combat.externaldamagetakenmultipliers:RemoveModifier("malbatrossdefense", "malbatross_defense")
	end
end
---------------------------------------------------------------
local anti_afk_states = {
	combat_lunge_start = true,
	combat_lunge = true,
	combat_superjump_start = true,
	combat_superjump = true,
	combat_leap_start = true,
	combat_leap = true,
	book = true,
	castspell = true,
	parry_pre = true,
	run_start = true,
}
---------------------------------------------------------------
local function fn(inst, prefab)
	
	if not TheWorld.ismastersim then
		return
	end
	
	inst.afkcheck = false
	inst:ListenForEvent("newstate", function(inst, data)
		if data and anti_afk_states[data.statename] then
			inst.afkcheck = false
			if inst:HasTag("afk") then
				inst:PushEvent("afk_end")
			end
		end
	end)
	
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
	
	inst:ListenForEvent("healthdelta", function(inst, data)
		local newhealth = data and data.newpercent
		if inst:HasTag("spectator") then
			newhealth = 0
		end
		if newhealth then
			local datatable = GetNetDMDataTable(inst.userid)
			if datatable then
				datatable.health:set( math.ceil(newhealth*255) )
			end
		end
	end)
	inst.components.health:DoDelta(0) --inits netvars
	
	inst:ListenForEvent("attacked", function(inst, data)
		if data then
			local _, feathers = inst.components.inventory:HasItemWithTag("malbatross_feather", 0)
			if feathers > 0 then
				inst.components.inventory:ConsumeByName("malbatross_feather", 1)
			end
			if data.stimuli and data.stimuli == "kb" then
				inst:DoTaskInTime(0, function()
					local knocker = data.weapon and data.weapon:IsValid() and data.weapon or data.attacker or inst
					inst:PushEvent("knockback", {knocker = knocker or data.attacker or inst, radius = 1, strengthmult = 1})
				end)
			end
		end
	end)
	
	inst:ListenForEvent("itemget", UpdateMalbatrossFeatherStats)
	inst:ListenForEvent("itemlose", UpdateMalbatrossFeatherStats)
	
	local powerups = {
		["damage"] = "pickup_lightdamaging",
		["defense"] = "pickup_lightdefense",
		["speed"] = "pickup_lightspeed",
		["heal"] = "pickup_lighthealing",
		["cooldown"] = "pickup_cooldown",
	}
	
	inst:ListenForEvent("murdered", function(inst, data)
		if data.victim and data.victim.prefab == "powerflier" then
			local powerup = SpawnPrefab(powerups[data.victim.powerup])
			powerup.components.inventoryitem.onpickupfn(powerup, inst)
		end
	end)
	
	inst:ListenForEvent("onattackother", function(inst, data)
		if inst._lightflier_formation ~= nil and inst._lightflier_formation.components.formationleader.buffs and inst._lightflier_formation.components.formationleader.buffs["heal"] then
			inst.components.health:DoDelta(inst._lightflier_formation.components.formationleader.buffs["heal"])
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
		inst.components.inventory:DropEverythingWithTag("deathmatch_pickup")
	end)
	
	inst:ListenForEvent("ms_respawnedfromghost", function(inst)
		--update revival health
		inst:UpdateRevivalHealth()
	end)
	
	inst:AddTag("stronggrip")
	if inst.components.drownable == nil then
		inst:AddComponent("drownable")
	end
	if inst.components.drownable ~= nil then
		inst.components.drownable:SetCustomTuningsFn(function(inst)
			return {
				HEALTH_PENALTY = 0,
				HEALTH = 50,
				HUNGER = 0,
				SANITY = 0,
				WETNESS = 0,  
			}
		end)
		inst.components.drownable.OnFallInOcean = function(self)
			self.src_x, self.src_y, self.src_z = self.inst.Transform:GetWorldPosition()
			self.dest_x, self.dest_y, self.dest_z = TheWorld.components.deathmatch_manager:GetDrowningRespawnPos()
		end
	end
	
end

return fn
