local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Image = require("widgets/image")
local TEMPLATES = require("widgets/redux/templates")

local Deathmatch_InfoPopup = Class(Widget, function(self, owner)
	Widget._ctor(self, "Deathmatch_InfoPopup")
	
	self.owner = owner

	self.root = self:AddChild(Widget("root"))
    self.root:SetPosition(0, 0)

	self.bg = self.root:AddChild(TEMPLATES.CurlyWindow(100, 250, nil, nil, nil, nil))
	
	self.icon_bg = self.bg:AddChild(Image("images/ui.xml", "portrait_bg.tex"))
	self.icon_bg:SetScale(0.5, 0.5)
	self.icon_bg:SetPosition(-100, 150)
	
	self.icon = self.bg:AddChild(Image())
	self.icon:SetPosition(-100, 150)
	
	self.main_title = self.bg:AddChild(Text(BUTTONFONT, 50))
	self.main_title:SetPosition(0, 150)
	
	self.text_body = self.bg:AddChild(Text(BUTTONFONT, 30))
end)

function Deathmatch_InfoPopup:NewInfo()
	self.icon:SetTexture("images/inventoryimages.xml", "spear_rose.tex")
	self.main_title:SetString(DEATHMATCH_STRINGS.INFO_POPUPS.JOIN.title)
	self.text_body:SetString(DEATHMATCH_STRINGS.INFO_POPUPS.JOIN.text_body)
end

return Deathmatch_InfoPopup
