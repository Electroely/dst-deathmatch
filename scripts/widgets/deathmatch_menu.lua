local HeaderTabs = require "widgets/redux/headertabs"
local PopupDialogScreen = require "screens/redux/popupdialog"
local Screen = require "widgets/screen"
local ServerSettingsTab = require "widgets/redux/serversettingstab"
local SnapshotTab = require "widgets/redux/snapshottab"
local Subscreener = require "screens/redux/subscreener"
local TEMPLATES = require "widgets/redux/templates"
local TextListPopup = require "screens/redux/textlistpopup"
local Widget = require "widgets/widget"
local Text = require "widgets/text"

local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"

local Deathmatch_Menu = Class(Screen, function(self)
    Screen._ctor(self, "Deathmatch_Menu")

    self.root = self:AddChild(TEMPLATES.ScreenRoot())

    self.detail_panel_frame = self.root:AddChild(TEMPLATES.RectangleWindow(500, 1000))
    local r,g,b = unpack(UICOLOURS.BROWN_DARK)
    self.detail_panel_frame:SetBackgroundTint(r,g,b,0.6)
    self.detail_panel_frame.top:Hide()
    
	self.tip_list = self.root:AddChild(self:BuildTipsMenu())
	self.tip_list:SetPosition(-110, 0)
	
	local tip_grid_data = {}

	for k, v in pairs(DEATHMATCH_STRINGS.POPUPS) do
		table.insert(tip_grid_data, {title = v.TITLE, body = v.BODY})
	end
	
	self.tip_list:SetItemsData(tip_grid_data)
end)

function Deathmatch_Menu:BuildTipsMenu()
    local base_size = 128
    local cell_size = 73
    local row_w = cell_size
    local row_h = cell_size;
    local reward_width = 80
    local row_spacing = 5
	
	local font = HEADERFONT
	local title_font_size = 16

    local function ScrollWidgetsCtor(context, index)
        local w = Widget("tip-cell-".. index)
        print("Test Test")
		----------------
		w.cell_root = w:AddChild(ImageButton("images/frontend_redux.xml", "achievement_backing_selected.tex", "achievement_backing_selected.tex"))
		w.cell_root:SetFocusScale(0.3 + .005, 1 + .05)
		w.cell_root:SetNormalScale(1, 1)
		
		w.tip_title = w.cell_root:AddChild(Text(font, title_font_size))
		
		w.focus_forward = w.cell_root

        w.cell_root.ongainfocusfn = function()  end

		w.cell_root:SetOnClick(function()
	
		end)
		
		return w

    end

    local function ScrollWidgetApply(context, widget, data, index)
		widget.data = data
		--print(data)
		if data ~= nil then
			widget.cell_root:Show()
			widget:Enable()
			
			print("Test")
			
			widget.tip_title:SetString(data.title)
		else
			widget:Disable()
			widget.cell_root:Hide()
		end
    end

    local grid = TEMPLATES.ScrollingGrid(
        {},
        {
            context = {},
            widget_width  = 500,
            widget_height = 100,
            num_visible_rows = 6,
            num_columns      = 1,
            item_ctor_fn = ScrollWidgetsCtor,
            apply_fn     = ScrollWidgetApply,
            scrollbar_offset = -80,
            scrollbar_height_offset = 0,
        })

	grid.up_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    grid.up_button:SetScale(0.5)

	grid.down_button:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_arrow_hover.tex")
    grid.down_button:SetScale(-0.5)

	grid.scroll_bar_line:SetTexture("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_bar.tex")
	grid.scroll_bar_line:SetScale(.8)

	grid.position_marker:SetTextures("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_handle.tex")
	grid.position_marker.image:SetTexture("images/quagmire_recipebook.xml", "quagmire_recipe_scroll_handle.tex")
    grid.position_marker:SetScale(.6)

    return grid
end

function Deathmatch_Menu:GetContentHeight()
    return dialog_size_y
end

function Deathmatch_Menu:OnBecomeActive()
    Deathmatch_Menu._base.OnBecomeActive(self)
    self:Enable()
    if self.last_focus then self.last_focus:SetFocus() end
end

function Deathmatch_Menu:OnBecomeInactive()
    Deathmatch_Menu._base.OnBecomeInactive(self)
end

function Deathmatch_Menu:OnDestroy()
    self._base.OnDestroy(self)
end

return Deathmatch_Menu