local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"

local TeammateHealthBadge = Class(Badge, function(self, owner)
    Badge._ctor(self, "lavaarena_partyhealth", owner, nil, nil, nil, nil, true)
	self.anim:GetAnimState():Hide("stick")
    self:SetClickable(false)

    self.arrow = self.underNumber:AddChild(UIAnim())
    self.arrow:GetAnimState():SetBank("sanity_arrow")
    self.arrow:GetAnimState():SetBuild("sanity_arrow")
    self.arrow:GetAnimState():PlayAnimation("neutral")
	self.arrow:GetAnimState():AnimateWhilePaused(false)
	self.arrow:SetScale(0.85)

	self._onclienthealthdirty = function(src, data) self:SetPercent(data.percent) end
	self._onclienthealthstatusdirty = function() self:RefreshStatus() end
	
	self:_SetupHeads()
end)

local function SetPlayerName(self, player)

	local name = (player.name ~= nil and #player.name > 0) and player.name or STRINGS.UI.SERVERADMINSCREEN.UNKNOWN_USER_NAME

end

local function UpdateShaderParams(self)
	local pos = self:GetWorldPosition()
	local scale = self:GetScale().x
	self.head_animstate:SetUILightParams(pos.x, pos.y, 24.0, scale)
end

function TeammateHealthBadge:_SetupHeads()

    self.head_anim = self:AddChild(UIAnim())
    self.head_animstate = self.head_anim:GetAnimState()

	self.head_anim:SetFacing(FACING_DOWN)

    self.head_animstate:Hide("ARM_carry")
    self.head_animstate:Hide("HAIR_HAT")
	self.head_animstate:Hide("HEAD_HAT")
	self.head_animstate:Hide("HEAD_HAT_NOHELM")
	self.head_animstate:Hide("HEAD_HAT_HELM")
	
	self.head_anim:Hide()
	
	self.head_animstate:SetDefaultEffectHandle(resolvefilepath("shaders/characterhead.ksh"))
	self.head_animstate:UseColourCube(true)
	self.OnUpdate = UpdateShaderParams
	self:StartUpdating()
end

function TeammateHealthBadge:SetHead(prefab, colour, ishost, userflags, base_skin)
    local dirty = false

    if self.ishost ~= ishost then
        self.ishost = ishost
        dirty = true
    end

    if self.base_skin ~= base_skin then
        self.base_skin = base_skin
        dirty = true
    end

    if self.prefabname ~= prefab then
        if table.contains(DST_CHARACTERLIST, prefab) then
            self.prefabname = prefab
            self.is_mod_character = false
        elseif table.contains(MODCHARACTERLIST, prefab) then
            self.prefabname = prefab
            self.is_mod_character = true
        elseif prefab == "random" then
            self.prefabname = "random"
            self.is_mod_character = false
        else
            self.prefabname = ""
            self.is_mod_character = (prefab ~= nil and #prefab > 0)
        end
        dirty = true
    end
    if self.userflags ~= userflags then
        self.userflags = userflags
        dirty = true
    end
    if dirty then

		self.head_anim:Show()
		local character_state_1 = checkbit(userflags, USERFLAGS.CHARACTER_STATE_1)
		local character_state_2 = checkbit(userflags, USERFLAGS.CHARACTER_STATE_2)
		local character_state_3 = checkbit(userflags, USERFLAGS.CHARACTER_STATE_3)
		local bank, animation, skin_mode, scale, y_offset = GetPlayerBadgeData( prefab, false, character_state_1, character_state_2, character_state_3)

		self.head_animstate:SetBank(bank)
		self.head_animstate:PlayAnimation(animation, true)
		
		self.head_animstate:SetTime(0)
		self.head_animstate:Pause()
		
		self.head_anim:SetScale(scale*0.7)
		self.head_anim:SetPosition(1,y_offset+11, 0)

		local skindata = GetSkinData(base_skin or self.prefabname.."_none")
		local base_build = self.prefabname
		if skindata.skins ~= nil then
			base_build = skindata.skins[skin_mode]
		end
		SetSkinsOnAnim( self.head_animstate, self.prefabname, base_build, {}, nil, skin_mode)
    end
end

function TeammateHealthBadge:SetPlayer(player)
	if self.player ~= nil and self.player ~= player then
		self.inst:RemoveEventCallback("clienthealthdirty", self._onclienthealthdirty, self.player)
		self.inst:RemoveEventCallback("clienthealthstatusdirty", self._onclienthealthstatusdirty, self.player)
	end

	self.player = player
	self.userid = player.userid
    self.inst:ListenForEvent("clienthealthdirty", self._onclienthealthdirty, player)
	self.inst:ListenForEvent("clienthealthstatusdirty", self._onclienthealthstatusdirty, player)

	self.arrowdir = 0

    SetPlayerName(self, player)

    self.anim:GetAnimState():HideSymbol("character_wilson")

	if player.components.healthsyncer ~= nil then
		self.percent = player.components.healthsyncer:GetPercent()
	    self:SetPercent(self.percent)
	end
	
end

function TeammateHealthBadge:SetPercent(val)
	val = val == 0 and 0 or math.max(val, 0.001)

    if self.percent < val then
		if self.arrowdir <= 0 then
		    self:PulseGreen()
		end
	elseif self.percent > val then
		if self.arrowdir >= 0 then
		    self:PulseRed()
		end
	end

    Badge.SetPercent(self, val)

	self:RefreshStatus()
end

function TeammateHealthBadge:RefreshStatus()
    local arrowdir = self.player.components.healthsyncer ~= nil and self.player.components.healthsyncer:GetOverTime() or 0

    if self.arrowdir ~= arrowdir then
        self.arrowdir = arrowdir

        self.arrow:GetAnimState():PlayAnimation((arrowdir > 1 and "arrow_loop_increase_most") or
													(arrowdir < 0 and "arrow_loop_decrease_most") or
													"neutral", true)
    end

	local warning = (arrowdir > 1 and {0,1,0,1}) or
					((arrowdir < 0 or (self.percent <= .33 and self.percent > 0)) and {1,0,0,1}) or
					nil

	if warning ~= nil then
		self:StartWarning(unpack(warning))
	else
		self:StopWarning()
	end

end

return TeammateHealthBadge
