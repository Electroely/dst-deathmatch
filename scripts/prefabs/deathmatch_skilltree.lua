local UI_LEFT, UI_RIGHT = -214, 228
local UI_VERTICAL_MIDDLE = (UI_LEFT + UI_RIGHT) * 0.5
local UI_TOP, UI_BOTTOM = 176, 20
local TILE_SIZE, TILE_HALFSIZE = 34, 16
local SKILLTREESTRINGS = DEATHMATCH_STRINGS.SKILLTREE

local SPELLCASTER_COL = -207
local BRAWLER_COL = -124
local LEFT_ROWS = {
	175,
	142,
	85,
	30
}

local LOADOUT_LOCK_ROWS = {
	175,
}
local LOADOUT_SKILL_OFFSET = -35
local LOADOUT_COLS = {
	103,
	223
}

local IMPROVISER_ROWS = {
	81,
	23
}
local IMPROVISER_COLS = {
	-31,
	35
}
local IMPROVISER_LOCK_POS = {1, 52}

--------------------------------------------------------------------------------------------------
local function onhit_regularattackcheck(data)
	if data == nil then
		return false
	end
	if data.stimuli ~= nil then
		return false
	end
	if data.weapon and data.weapon.components.weapon.projectile ~= nil and data.projectile == nil then
		return false
	end
	return true
end
local function onhit_charge_bomb(inst, data)
	if not onhit_regularattackcheck(data) then
		return
	end
	local items = inst.components.inventory and inst.components.inventory.itemslots or nil
	if items then
		for i = 1, inst.components.inventory.maxslots do
			local item = items[i]
			if item and item.sparklevel ~= nil and item.sparklevel_max ~= nil and item.sparklevel < item.sparklevel_max then
				item:SetSparkLevel(item.sparklevel+1)
				return
			end
		end
	end
end
local function onattacked_explode_bomb(inst, data)
	local items = inst.components.inventory and inst.components.inventory.itemslots or nil
	if items then
		for i = 1, inst.components.inventory.maxslots do
			local item = items[i]
			if item and item.sparklevel ~= nil and item.sparklevel_max ~= nil and item.sparklevel >= item.sparklevel_max and item.DoExplosion then
				item:DoExplosion(inst, inst:GetPosition(), true)
				break
			end
		end
	end
end

local ONHIT_REFRESH_AMOUNT = 1.2
local function onhit_refresh_cooldowns(inst, data)
	if not onhit_regularattackcheck(data) then
		return
	end
	local items = inst.components.inventory and inst.components.inventory.itemslots or nil
	local equips = inst.components.inventory and inst.components.inventory.equipslots or nil
	if items then
		for slot, item in pairs(items) do
			if item and item.components.rechargeable and not item.components.rechargeable:IsCharged() then
				local recharge_amount = ONHIT_REFRESH_AMOUNT/item.components.rechargeable.chargetime
				item.components.rechargeable:SetPercent(math.min(item.components.rechargeable:GetPercent()+recharge_amount,1))
			end
		end
	end
	if equips then
		for slot, item in pairs(equips) do
			if item and item.components.rechargeable and not item.components.rechargeable:IsCharged() then
				local recharge_amount = ONHIT_REFRESH_AMOUNT/item.components.rechargeable.chargetime
				item.components.rechargeable:SetPercent(math.min(item.components.rechargeable:GetPercent()+recharge_amount,1))
			end
		end
	end
end

local function onhit_damagestack(inst, data)
	if not onhit_regularattackcheck(data) then
		return
	end
	inst:DoTaskInTime(0, function(inst)
		inst:AddDebuff("buff_deathmatch_damagestack", "buff_deathmatch_damagestack")
	end)
end
--------------------------------------------------------------------------------------------------

local ORDERS =
{
    { "spellcaster",   { UI_LEFT, UI_TOP } },
	{ "brawler",   { UI_LEFT, UI_TOP } },
	{ "improviser",   { UI_LEFT, UI_TOP } },
	{ "loadout",   { UI_RIGHT, UI_TOP } },
}

local LOADOUTS = {
	"forge_melee",
	"forge_mage",
}

--------------------------------------------------------------------------------------------------

local function BuildSkillsData(SkillTreeFns)
	local function NoOtherLoadout(prefabname, current, activatedskills, readonly)
		for k, loadout in pairs(LOADOUTS) do
			if loadout ~= current then
				if SkillTreeFns.CountTags(prefabname, loadout, activatedskills) > 0 then
					return false
				end
			end
		end
		return true
	end
    local skills =
    {
		-- SPELLCASTER
		spellcaster_loadout_lock = {
			desc = SKILLTREESTRINGS.LOADOUT_PICKONE_LOCK,
			pos = {SPELLCASTER_COL, LEFT_ROWS[1]},
			root = true,
			group = "spellcaster",
			tags = {"spellcaster", "lock"},
			lock_open = function(prefabname, activatedskills, readonly)
				if SkillTreeFns.CountTags(prefabname, "loadout", activatedskills) == 1 then
					return true
				end

				return nil
			end,
			connects = {
				"spellcaster_cooldown_1"
			},
		},
		
        spellcaster_cooldown_1 = {
            title = SKILLTREESTRINGS.SPELLCASTER_COOLDOWN_ONE_TITLE,
            desc = string.format(SKILLTREESTRINGS.SPELLCASTER_COOLDOWN_ONE_DESC, DEATHMATCH_TUNING.SKILLTREE_COOLDOWN_1*100),
            pos = {SPELLCASTER_COL, LEFT_ROWS[2]},
            group = "spellcaster",
            tags = {},
            onactivate = function(owner, from_load)
                owner.cooldownmodifiers:SetModifier(owner, DEATHMATCH_TUNING.SKILLTREE_COOLDOWN_1, "spellcaster_cooldown_1")
				owner:PushEvent("cooldownmodifier")
            end,
            ondeactivate = function(owner, from_load)
                owner.cooldownmodifiers:RemoveModifier(owner, "spellcaster_cooldown_1")
				owner:PushEvent("cooldownmodifier")
            end,
			connects = {"spellcaster_cooldown_2"},
        },
		
       spellcaster_cooldown_2 = {
            title = SKILLTREESTRINGS.SPELLCASTER_COOLDOWN_TWO_TITLE,
            desc = string.format(SKILLTREESTRINGS.SPELLCASTER_COOLDOWN_TWO_DESC, DEATHMATCH_TUNING.SKILLTREE_COOLDOWN_2*100),
            pos = {SPELLCASTER_COL, LEFT_ROWS[3]},

            group = "spellcaster",
            tags = {},
            onactivate = function(owner, from_load)
                owner.cooldownmodifiers:SetModifier(owner, DEATHMATCH_TUNING.SKILLTREE_COOLDOWN_2-DEATHMATCH_TUNING.SKILLTREE_COOLDOWN_1, "spellcaster_cooldown_2")
				owner:PushEvent("cooldownmodifier")
            end,
            ondeactivate = function(owner, from_load)
                owner.cooldownmodifiers:RemoveModifier(owner, "spellcaster_cooldown_2")
				owner:PushEvent("cooldownmodifier")
            end,
			connects = {"spellcaster_refresh_on_hit"},
        },
		
       spellcaster_refresh_on_hit = {
            title = SKILLTREESTRINGS.SPELLCASTER_REFRESH_ON_HIT_TITLE,
            desc = SKILLTREESTRINGS.SPELLCASTER_REFRESH_ON_HIT_DESC,
            pos = {SPELLCASTER_COL, LEFT_ROWS[4]},

            group = "spellcaster",
            tags = {},
            onactivate = function(owner, from_load)
                owner:ListenForEvent("onattackother",onhit_refresh_cooldowns)
            end,
            ondeactivate = function(owner, from_load)
                owner:RemoveEventCallback("onattackother",onhit_refresh_cooldowns)
            end,
        },
		
		--BRAWLER
		brawler_loadout_lock = {
			desc = SKILLTREESTRINGS.LOADOUT_PICKONE_LOCK,
			pos = {BRAWLER_COL, LEFT_ROWS[1]},
			root = true,
			group = "brawler",
			tags = {"brawler", "lock"},
			lock_open = function(prefabname, activatedskills, readonly)
				if SkillTreeFns.CountTags(prefabname, "loadout", activatedskills) == 1 then
					return true
				end

				return nil
			end,
			connects = {
				"brawler_damage_1"
			},
		},
		
        brawler_damage_1 = {
            title = SKILLTREESTRINGS.BRAWLER_DAMAGE_ONE_TITLE,
            desc = string.format(SKILLTREESTRINGS.BRAWLER_DAMAGE_ONE_DESC, (DEATHMATCH_TUNING.SKILLTREE_DAMAGE_1-1)*100),
            pos = {BRAWLER_COL, LEFT_ROWS[2]},
            group = "brawler",
            tags = {},
            onactivate = function(owner, from_load)
                owner.components.combat.externaldamagemultipliers:SetModifier(owner, DEATHMATCH_TUNING.SKILLTREE_DAMAGE_1, "brawler_damage_1")
            end,
            ondeactivate = function(owner, from_load)
                owner.components.combat.externaldamagemultipliers:RemoveModifier(owner, "brawler_damage_1")
            end,
			connects = {"brawler_damage_2"},
        },
		
       brawler_damage_2 = {
            title = SKILLTREESTRINGS.BRAWLER_DAMAGE_TWO_TITLE,
            desc = string.format(SKILLTREESTRINGS.BRAWLER_DAMAGE_TWO_DESC, (DEATHMATCH_TUNING.SKILLTREE_DAMAGE_1*DEATHMATCH_TUNING.SKILLTREE_DAMAGE_2 - 1)*100),
            pos = {BRAWLER_COL, LEFT_ROWS[3]},

            group = "brawler",
            tags = {},
            onactivate = function(owner, from_load)
                owner.components.combat.externaldamagemultipliers:SetModifier(owner, DEATHMATCH_TUNING.SKILLTREE_DAMAGE_2, "brawler_damage_2")
            end,
            ondeactivate = function(owner, from_load)
                owner.components.combat.externaldamagemultipliers:RemoveModifier(owner, "brawler_damage_2")
            end,
			connects = {"brawler_buff_on_hit"},
        },
		
       brawler_buff_on_hit = {
            title = SKILLTREESTRINGS.BRAWLER_BUFF_ON_HIT_TITLE,
            desc = string.format(SKILLTREESTRINGS.BRAWLER_BUFF_ON_HIT_DESC, DEATHMATCH_TUNING.SKILLTREE_DAMAGE_BUFF_AMOUNT*100,DEATHMATCH_TUNING.SKILLTREE_DAMAGE_BUFF_STACKS),
            pos = {BRAWLER_COL, LEFT_ROWS[4]},

            group = "brawler",
            tags = {},
            onactivate = function(owner, from_load)
                owner:ListenForEvent("onattackother",onhit_damagestack)
            end,
            ondeactivate = function(owner, from_load)
                owner:RemoveEventCallback("onattackother",onhit_damagestack)
            end,
        },
		--IMPROVISER (bombs)
		improviser_loadout_lock = {
			desc = SKILLTREESTRINGS.LOADOUT_PICKONE_LOCK,
			pos = IMPROVISER_LOCK_POS,
			root = true,
			group = "improviser",
			tags = {"improviser", "lock"},
			lock_open = function(prefabname, activatedskills, readonly)
				if SkillTreeFns.CountTags(prefabname, "loadout", activatedskills) == 1 then
					return true
				end

				return nil
			end,
			connects = {
				"improviser_bouncing_bombs",
				"improviser_homing_bombs",
				"improviser_passive_bombs",
				"improviser_burning_bombs",
			},
		},
		improviser_bouncing_bombs = {
            title = SKILLTREESTRINGS.IMPROVISER_BOUNCING_BOMBS_TITLE,
            desc = SKILLTREESTRINGS.IMPROVISER_BOUNCING_BOMBS_DESC,
            pos = {IMPROVISER_COLS[1], IMPROVISER_ROWS[1]},
            group = "improviser",
            tags = {},
            onactivate = function(owner, from_load)
                owner:AddTag("bouncing_bombs")
            end,
            ondeactivate = function(owner, from_load)
                owner:RemoveTag("bouncing_bombs")
            end,
		},
		improviser_passive_bombs = {
            title = SKILLTREESTRINGS.IMPROVISER_PASSIVE_BOMBS_TITLE,
            desc = SKILLTREESTRINGS.IMPROVISER_PASSIVE_BOMBS_DESC,
            pos = {IMPROVISER_COLS[2], IMPROVISER_ROWS[1]},
            group = "improviser",
            tags = {},
            onactivate = function(owner, from_load)
                owner:ListenForEvent("onattackother", onhit_charge_bomb)
				owner:ListenForEvent("attacked", onattacked_explode_bomb)
            end,
            ondeactivate = function(owner, from_load)
                owner:RemoveEventCallback("onattackother", onhit_charge_bomb)
				owner:RemoveEventCallback("attacked", onattacked_explode_bomb)
            end,
		},
		improviser_homing_bombs = {
            title = SKILLTREESTRINGS.IMPROVISER_HOMING_BOMBS_TITLE,
            desc = SKILLTREESTRINGS.IMPROVISER_HOMING_BOMBS_DESC,
            pos = {IMPROVISER_COLS[1], IMPROVISER_ROWS[2]},
            group = "improviser",
            tags = {},
            onactivate = function(owner, from_load)
                owner:AddTag("homing_bombs")
            end,
            ondeactivate = function(owner, from_load)
                owner:RemoveTag("homing_bombs")
            end,
		},
		improviser_burning_bombs = {
            title = SKILLTREESTRINGS.IMPROVISER_BURNING_BOMBS_TITLE,
            desc = SKILLTREESTRINGS.IMPROVISER_BURNING_BOMBS_DESC,
            pos = {IMPROVISER_COLS[2], IMPROVISER_ROWS[2]},
            group = "improviser",
            tags = {},
            onactivate = function(owner, from_load)
                owner:AddTag("burning_bombs")
            end,
            ondeactivate = function(owner, from_load)
                owner:RemoveTag("burning_bombs")
            end,
		},
		--LOADOUT SELECT
		loadout_forge_melee_lock = {
			desc = SKILLTREESTRINGS.LOADOUT_ONLYONE_LOCK,
			pos = {LOADOUT_COLS[1], LOADOUT_LOCK_ROWS[1]},
			root = true,
			group = "loadout",
			tags = {"loadout", "lock"},
			lock_open = function(prefabname, activatedskills, readonly)
				if NoOtherLoadout(prefabname, "forge_melee", activatedskills, readonly) then
					return true
				end

				return nil
			end,
			connects = {
				"loadout_forge_melee"
			},
		},
       loadout_forge_melee = {
            title = SKILLTREESTRINGS.LOADOUT_FORGE_MELEE_TITLE,
            desc = SKILLTREESTRINGS.LOADOUT_FORGE_MELEE_DESC,
            pos = {LOADOUT_COLS[1], LOADOUT_LOCK_ROWS[1]+LOADOUT_SKILL_OFFSET},
            group = "loadout",
            tags = {"loadout", "forge_melee"},
            onactivate = function(owner, from_load)
                owner:AddTag("loadout_forge_melee")
				owner:PushEvent("updateloadout")
            end,
            ondeactivate = function(owner, from_load)
                owner:RemoveTag("loadout_forge_melee")
				owner:PushEvent("updateloadout")
            end,
        },

		loadout_forge_mage_lock = {
			desc = SKILLTREESTRINGS.LOADOUT_ONLYONE_LOCK,
			pos = {LOADOUT_COLS[2], LOADOUT_LOCK_ROWS[1]},
			root = true,
			group = "loadout",
			tags = {"loadout", "lock"},
			lock_open = function(prefabname, activatedskills, readonly)
				if NoOtherLoadout(prefabname, "forge_mage", activatedskills, readonly) then
					return true
				end

				return nil
			end,
			connects = {
				"loadout_forge_mage"
			},
		},
       loadout_forge_mage = {
            title = SKILLTREESTRINGS.LOADOUT_FORGE_MAGE_TITLE,
            desc = SKILLTREESTRINGS.LOADOUT_FORGE_MAGE_DESC,
            pos = {LOADOUT_COLS[2], LOADOUT_LOCK_ROWS[1]+LOADOUT_SKILL_OFFSET},
            group = "loadout",
            tags = {"loadout", "forge_mage"},
            onactivate = function(owner, from_load)
                owner:AddTag("loadout_forge_mage")
				owner:PushEvent("updateloadout")
            end,
            ondeactivate = function(owner, from_load)
                owner:RemoveTag("loadout_forge_mage")
				owner:PushEvent("updateloadout")
            end,
        },
		
	}
	
	for k, v in pairs(skills) do
		v.icon = k
	end
	
	return {
        SKILLS = skills,
        ORDERS = ORDERS,
    }
end

return BuildSkillsData