local Widget = require("widgets/widget")
local Text = require("widgets/text")

local Deathmatch_ChooseYourGear = Class(Widget, function(self, owner)
	
	Widget._ctor(self, "Deathmatch_ChooseYourGear")
	
	self.title = self:AddChild(Text(NEWFONT_OUTLINE, 60, "Equip Your Gear!"))
	self.desc = self:AddChild(Text(NEWFONT_OUTLINE, 25, "You don't get to change it after the match starts."))
	self.desc:SetPosition(0, -40)
end)

return Deathmatch_ChooseYourGear