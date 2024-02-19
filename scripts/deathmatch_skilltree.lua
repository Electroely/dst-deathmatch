
local SKILLTREE_DEFS = require("prefabs/skilltree_defs")
local skilltreedata = require("prefabs/deathmatch_skilltree")

local json = GLOBAL.json

GLOBAL.TUNING.SKILL_THRESHOLDS = {
	1,1,1,1,1,1,1,1,
}

local available_skill_points = 6
local SkillTreeData = require("skilltreedata")
SkillTreeData:Save()

function SkillTreeData:Save(force_save, characterprefab)
    --print("[STData] Save")
    if force_save or (self.save_enabled and self.dirty) then
        local str
        if characterprefab == "LOADFIXUP" then
            str = json.encode({activatedskills = self.activatedskills, skillxp = self.skillxp, })
        else
            self.skillxp[characterprefab] = self.skillxp_backup or self.skillxp[characterprefab]
            str = json.encode({activatedskills = self.activatedskills_backup or self.activatedskills, skillxp = self.skillxp, })
        end
        GLOBAL.TheSim:SetPersistentString("skilltree_deathmatch", str, false)
        self.dirty = false
    end
end

function SkillTreeData:Load()
    --print("[STData] Load")
    self.activatedskills = {}
    self.skillxp = {}
    local needs_save = false
    local really_bad_state = false
    GLOBAL.TheSim:GetPersistentString("skilltree_deathmatch", function(load_success, data)
        if load_success and data ~= nil then
            local status, skilltree_data = GLOBAL.pcall(function() return json.decode(data) end)
            if status and skilltree_data then
                if type(skilltree_data.activatedskills) == "table" and type(skilltree_data.skillxp) == "table" then
                    for characterprefab, activatedskills in pairs(skilltree_data.activatedskills) do
                        local skillxp = skilltree_data.skillxp[characterprefab]
                        if skillxp == nil or not self:ValidateCharacterData(characterprefab, activatedskills, skillxp) then
                            --print("[STData] Load clearing skill tree for character due to bad state", characterprefab)
                            skilltree_data.activatedskills[characterprefab] = nil
                            needs_save = true
                        end
                    end
                    self.activatedskills = skilltree_data.activatedskills
                    self.skillxp = skilltree_data.skillxp
                else
                    really_bad_state = true
                    print("Failed to load activated skills or skillxp tables in skilltree!")
                end
            else
                really_bad_state = true
                print("Failed to load the data in skilltree!", status, skilltree_data)
            end
        else
            really_bad_state = true
            print("Failed to load skilltree file itself!")
        end
    end)
    if really_bad_state then
        print("Trying to apply online cache of skilltree data..")
        if self:ApplyOnlineProfileData() then
            print("Was a success, using old stored XP values of:")
            GLOBAL.dumptable(self.skillxp)
            print("Also using old stored skill selection values of:")
            GLOBAL.dumptable(self.activatedskills)
            needs_save = true
        else
            print("Which also failed. This error is unrecoverable. Skill tree will be cleared.")
        end
    end
    if needs_save then
        print("Saving skilltree file as a fixup.")
        self:Save(true, "LOADFIXUP")
    end
end

SkillTreeData.GetMaximumExperiencePoints = function()
	return available_skill_points
end
SkillTreeData.GetSkillXP = function()
	return available_skill_points
end

SkillTreeData:Load()

local data = skilltreedata(SKILLTREE_DEFS.FN)
for k, v in pairs(GLOBAL.DST_CHARACTERLIST) do
	SKILLTREE_DEFS.CreateSkillTreeFor(v, data.SKILLS)
	SKILLTREE_DEFS.SKILLTREE_ORDERS[v] = data.ORDERS
	RegisterSkilltreeBGForCharacter("images/deathmatch_skilltree_bg.xml", v)
	SkillTreeData.activatedskills = {}
	SkillTreeData.skillxp = available_skill_points
end
for skill, v in pairs(data.SKILLS) do
	RegisterSkilltreeIconsAtlas("images/deathmatch_skilltree_icons.xml", skill..".tex")
end

local ValidateCharacterData_old = SkillTreeData.ValidateCharacterData
SkillTreeData.ValidateCharacterData = function(self, characterprefab, activatedskills, skillxp, ...) 
	skillxp = available_skill_points
	return ValidateCharacterData_old(self, characterprefab, activatedskills, skillxp, ...)
end

GLOBAL.RespecSkillsForPlayer = function(player)
    local matchstatus = GLOBAL.TheWorld.net.deathmatch_netvars.globalvars.matchstatus:value()
    if matchstatus == 1 or matchstatus == 2 then
        return
    end
    if player and player.components.skilltreeupdater then
        player.components.skilltreeupdater:SetSkipValidation(true)
        local skills = player.components.skilltreeupdater:GetActivatedSkills()
        if skills then
            for skill, enabled in pairs(skills) do
                if enabled then
                    player.components.skilltreeupdater:DeactivateSkill(skill)
                end
            end
        end
        player.components.skilltreeupdater:SetSkipValidation(false)
    end
end