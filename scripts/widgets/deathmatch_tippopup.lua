local Widget = require("widgets/widget")
local Text = require("widgets/text")
local TEMPLATES = require("widgets/redux/templates")

local function GetDeathmatchPopupString(name)
	local data = DEATHMATCH_STRINGS.POPUPS[name]
	local body = string.gsub(data.BODY, "\n", "")
	body = string.gsub(body, "\t", "")
	return data.TITLE, string.gsub(body, "\n", "")
end

--strings will be pulled from DEATHMATCH_STRINGS.POPUPS[title] if text is nil
local Deathmatch_TipPopup = Class(Widget, function(self, title, text)
	Widget._ctor(self, "Deathmatch_TipPopup")
	
	if text == nil then
		title, text = GetDeathmatchPopupString(title)
	end
	
	self.title = self:AddChild(Text(NEWFONT, 30))
	self.title:SetPosition(-25, 100)
	self.title:SetRegionSize(225, 35)
	
	self.body = self:AddChild(Text(NEWFONT, 25))
	self.body:SetPosition(0, -90)
	self.body:EnableWordWrap(true)
	self.body:SetRegionSize(250, 300)
	self.body:SetHAlign(ANCHOR_LEFT)
	self.body:SetVAlign(ANCHOR_TOP)
	
	self:SetTitle(title)
	self:SetBody(text)
	
	--	TODO
	self.closeButton = self:AddChild(TEMPLATES.IconButton(iconAtlas, iconTexture, "Close", false, false, function() self:Kill() end))
	self.closeButton:SetPosition(200, 100)
end)

function Deathmatch_TipPopup:SetPopupName(name)
	local title, body = GetDeathmatchPopupString(name)
	self:SetTitle(title)
	self:SetBody(body)
end

function Deathmatch_TipPopup:SetTitle(str)
	self.title:SetString(str)
end

function Deathmatch_TipPopup:SetBody(str)
	self.body:SetString(str)
end

return Deathmatch_TipPopup
