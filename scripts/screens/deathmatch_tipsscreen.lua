local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"

local TipsScreen = Class(Screen, function(self, tipredirect)
	Screen._ctor(self, "DeathmatchTipsScreen")
	
	self.root = self:AddChild(TEMPLATES.ScreenRoot("GameOptions"))
	self.black = self.root:AddChild(TEMPLATES.BackgroundTint())
	
	self.bg = self.root:AddChild(TEMPLATES.RectangleWindow(640, 400))
	
end)

return TipsScreen