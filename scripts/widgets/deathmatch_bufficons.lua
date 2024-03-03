local Widget = require("widgets/widget")
local Image = require("widgets/image")

local BUFFSTRINGS = DEATHMATCH_STRINGS.BUFFS
local buffs = {
	buff_pickup_lightdefense = {pos = {-5, 37}, duration = 15},
	buff_pickup_lightdamaging = {pos = {-5, 60}, duration = 10},
	buff_pickup_lightspeed = {pos = {17, 60}, duration = 10},
	buff_deathmatch_damagestack = {pos = {70, 57}, duration = 5},
	buff_healingstaff_ally = {pos = {30, -25}},
	buff_healingstaff_enemy = {pos = {52, -25}},
}

local ATLAS = "images/deathmatch_buff_icons.xml"
local scale = 0.35

local function TimerString(secs) 
	return string.format(BUFFSTRINGS.TIMERSTRING, math.ceil(secs))
end
local function DamageStackString(stacks)
	return string.format(BUFFSTRINGS["buff_deathmatch_damagestack"].DESC, DEATHMATCH_TUNING.SKILLTREE_DAMAGE_BUFF_AMOUNT*stacks*100)
end
local Deathmatch_BuffIcons = Class(Widget, function(self, owner)
	Widget._ctor(self, "Deathmatch_BuffIcons")
	self:SetClickable(true)
	self.owner = owner
	self.bufficons = {}
	self.bufftimers = {}
	self.buffdata = {buff_deathmatch_damagestack = 0}
	for buff, data in pairs(buffs) do
		self.bufficons[buff] = self:AddChild(Image(ATLAS, buff..".tex"))
		self.bufficons[buff]:SetScale(scale, scale, scale)
		self.bufficons[buff]:SetPosition(unpack(data.pos))
		self.bufficons[buff]:Hide()
		if data.duration then
			self.bufftimers[buff] = 0
		end
	end
	owner:ListenForEvent("deathmatch_buff_changed", function(owner, data)
		if data and data.buff and self.bufficons[data.buff] then
			if data.buff == "buff_deathmatch_damagestack" then
				self.buffdata[data.buff] = data.value
				if data.value > 0 then
					self.bufficons[data.buff]:Show()
					if buffs[data.buff].duration then
						self.bufftimers[data.buff] = buffs[data.buff].duration
						self:StartUpdating()
					end
				else
					self.bufficons[data.buff]:Hide()
				end
			else
				if data.value then
					self.bufficons[data.buff]:Show()
					if buffs[data.buff].duration then
						self.bufftimers[data.buff] = buffs[data.buff].duration
						self:StartUpdating()
					end
				else
					self.bufficons[data.buff]:Hide()
				end
			end
			self:UpdateTooltip(data.buff)
		end
	end)
end)

function Deathmatch_BuffIcons:UpdateTooltip(buff)
	local s = BUFFSTRINGS[buff].TITLE
	if buff == "buff_deathmatch_damagestack" then
		s = s .. "\n" .. DamageStackString(self.buffdata[buff])
	else
		s = s .. "\n" .. BUFFSTRINGS[buff].DESC
	end
	if self.bufftimers[buff] then
		s = s .. "\n" .. TimerString(self.bufftimers[buff])
	end
	self.bufficons[buff]:SetTooltip(s)
end

function Deathmatch_BuffIcons:OnUpdate(dt)
	local activetimer = false
	for buff, timer in pairs(self.bufftimers) do
		if timer > 0 then
			self.bufftimers[buff] = math.max(timer-dt, 0)
			self:UpdateTooltip(buff)
			if self.bufftimers[buff] > 0 then
				activetimer = true
			end
		end
	end
	if not activetimer then
		self:StopUpdating()
	end
end

return Deathmatch_BuffIcons