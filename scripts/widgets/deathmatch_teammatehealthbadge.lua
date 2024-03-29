local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"
local Text = require "widgets/text"
local Image = require "widgets/image"
local Widget = require "widgets/widget"

local function UpdateShaderParams(self)
	local pos = self:GetWorldPosition()
	local scale = self:GetScale().x
	self.head_animstate:SetUILightParams(pos.x, pos.y, 24.0, scale)
end
local DEFAULT_ROPE_COLOUR = {140/255, 81/255, 57/255, 1}

local TeammateHealthBadge = Class(Badge, function(self, owner)
    Badge._ctor(self, "lavaarena_partyhealth", owner, nil, nil, nil, nil, true)
	self.anim:GetAnimState():Hide("stick")
	self.anim:GetAnimState():HideSymbol("frame_circle")
    self:SetClickable(false)

    self.arrow = self.underNumber:AddChild(UIAnim())
    self.arrow:GetAnimState():SetBank("sanity_arrow")
    self.arrow:GetAnimState():SetBuild("sanity_arrow")
    self.arrow:GetAnimState():PlayAnimation("neutral")
	self.arrow:GetAnimState():AnimateWhilePaused(false)
	self.arrow:SetScale(0.85)
	
	self.name = self:AddChild(Text(NEWFONT_OUTLINE_SMALL, 20, ""))
	self.name:SetPosition(0, 50)
	self.name:Hide()

	self.frame = self:AddChild(Image("images/teammatehealthbadge_frame.xml", "teammatehealthbadge_frame.tex"))
	self.rope = self:AddChild(Image("images/teammatehealthbadge_rope.xml", "teammatehealthbadge_rope.tex"))
	self.rope:SetTint(unpack(DEFAULT_ROPE_COLOUR))

	self.userid = nil
	self.inst:ListenForEvent("deathmatch_playerhealthdirty", function(src)
		local health = src:GetPlayerHealth(self.userid)
		if health then
			self:SetPercent(health)
		end
	end, TheWorld.net)
	
	self:_SetupHeads()
	self:StartUpdating()
end)

function TeammateHealthBadge:OnUpdate(dt)
	UpdateShaderParams(self)
	local mousepos = TheInput:GetScreenPosition()
	local isnear = mousepos:DistSq(self:GetWorldPosition()) < 900*self:GetScale().x
	if isnear then
		self.name:Show()
		self:MoveToFront()
	else
		self.name:Hide()
	end
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
		local bank, animation, skin_mode, scale, y_offset, x_offset = GetPlayerBadgeData_Override( prefab, false, character_state_1, character_state_2, character_state_3)
		x_offset = x_offset or 0

		self.head_animstate:SetBank(bank)
		self.head_animstate:PlayAnimation(animation, true)
		
		self.head_animstate:SetTime(0)
		self.head_animstate:Pause()
		
		self.head_anim:SetScale(scale*0.7)
		self.head_anim:SetPosition(1+x_offset,y_offset+11, 0)

		local skindata = GetSkinData(base_skin or self.prefabname.."_none")
		local base_build = self.prefabname
		if skindata.skins ~= nil then
			base_build = skindata.skins[skin_mode]
		end
		SetSkinsOnAnim( self.head_animstate, self.prefabname, base_build, {}, nil, skin_mode)
    end
end

local function CreateDummyData(character)
	return {
		prefab = character,
		userid = character,
		base_skin = character.."_none",
		userflags = 0,
		name = STRINGS.NAMES[string.upper(character)],
		team = math.random(1,8),
		health = math.random(),
	}
end


function TeammateHealthBadge:SetPlayer(data)
	--local data = TheNet:GetClientTableForUser(player) or CreateDummyData(player)
	local changed_users = self.userid ~= data.userid
	self.userid = data.userid

	self.arrowdir = 0

	self.name:SetString(data.name)

    self.anim:GetAnimState():HideSymbol("character_wilson")
	self:SetHead(data.prefab, data.colour, data.ishost, data.userflags, data.base_skin)
	
	local health = TheWorld.net:GetPlayerHealth(self.userid)
	self.silent = true
	if health then
		self:SetPercent(health)
	end

	local team = data.team or TheWorld.net:GetPlayerTeam(self.userid) or 0
	if team == 0 then
		self.name:SetColour(1,1,1,1)
		self.rope:SetTint(unpack(DEFAULT_ROPE_COLOUR))
	else
		self.name:SetColour(unpack(DEATHMATCH_TEAMS[team].colour))
		self.rope:SetTint(unpack(DEATHMATCH_TEAMS[team].colour))
	end
	
end

function TeammateHealthBadge:SetPercent(val)
	val = val == 0 and 0 or math.max(val, 0.001)
	local silent = self.silent
	if not silent then
		if self.percent < val then
			if self.arrowdir <= 0 then
				self:PulseGreen()
			end
		elseif self.percent > val then
			if self.arrowdir >= 0 then
				self:PulseRed()
			end
		end
	end
	self.silent = nil

    Badge.SetPercent(self, val)

	if self.percent <= 0 then
		self.head_animstate:SetMultColour(0.5,0.5,0.5,0.5)
	else
		self.head_animstate:SetMultColour(1,1,1,1)
	end
end

return TeammateHealthBadge
