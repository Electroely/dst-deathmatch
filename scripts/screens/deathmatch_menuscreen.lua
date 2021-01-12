local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local TEMPLATES = require "widgets/redux/templates"
local DeathmatchMenu = require "widgets/deathmatch_menu"

local Deathmatch_MenuScreen = Class(Screen, function(self, owner)
    self.owner = owner
    Screen._ctor(self, "MapScreen") --We're replacing the map

	self.root = self:AddChild(Widget("root"))
	self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetVAnchor(ANCHOR_MIDDLE)
	self.root:SetPosition(0, 0)
	
	self.menu = root:AddChild(DeathmatchMenu(owner))
end)

return Deathmatch_MenuScreen
