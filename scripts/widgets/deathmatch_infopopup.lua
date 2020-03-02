local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Image = require("widgets/image")

local Deathmatch_InfoPopup = Class(Widget, function(self, owner)
	Widget._ctor(self, "Deathmatch_InfoPopup")
	
	self.owner = owner

	self.root = self:AddChild(Widget("root"))
    self.root:SetPosition(0, 0)

	self.bg = self.root:AddChild(Image("images/frontend_redux.xml", "achievement_backing_selected.tex"))
	
	self.main_title = self.bg:AddChild(Text(BUTTONFONT, 35))
	
	self.text_body = self.bg:AddChild(Text(BUTTONFONT, 35))
end)

return Deathmatch_InfoPopup
