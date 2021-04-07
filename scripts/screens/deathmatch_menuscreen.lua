local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local TEMPLATES = require "widgets/redux/templates"
local DeathmatchMenu = require "widgets/deathmatch_menu"
local MapControls = require "widgets/mapcontrols"

local Deathmatch_MenuScreen = Class(Screen, function(self, owner)
    self.owner = owner
    Screen._ctor(self, "MapScreen") --We're replacing the map

	self.root = self:AddChild(Widget("root"))
	self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetVAnchor(ANCHOR_MIDDLE)
	self.root:SetPosition(0, 0)
	
	self.menu = self.root:AddChild(DeathmatchMenu(owner))
	
	if not TheInput:ControllerAttached() then
		self.bottomright_root = self:AddChild(Widget("br_root"))
		self.bottomright_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
		self.bottomright_root:SetHAnchor(ANCHOR_RIGHT)
		self.bottomright_root:SetVAnchor(ANCHOR_BOTTOM)
		self.bottomright_root:SetMaxPropUpscale(MAX_HUD_SCALE)

		self.bottomright_root = self.bottomright_root:AddChild(Widget("br_scale_root"))
		self.bottomright_root:SetScale(TheFrontEnd:GetHUDScale())
		self.bottomright_root.inst:ListenForEvent("refreshhudsize", function(hud, scale) self.bottomright_root:SetScale(scale) end, owner.HUD.inst)

        self.mapcontrols = self.bottomright_root:AddChild(MapControls())
        self.mapcontrols:SetPosition(-60,70,0)
		self.mapcontrols.minimapBtn:SetTextures("images/quagmire_hud.xml", "map_button.tex")

        self.mapcontrols.pauseBtn:Hide()
        self.mapcontrols.rotleft:Hide()
        self.mapcontrols.rotright:Hide()
    end
end)

return Deathmatch_MenuScreen
