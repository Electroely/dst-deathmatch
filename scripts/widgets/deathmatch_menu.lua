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

local TIP_SORT_ORDER = 
{
	"WELCOME",
	"TEAMS_ENABLED",
	"TEAMMODE_HALF",
	"TEAMMODE_PAIRS",
	"CASTAOEEXPLAIN",
	"FIREBOMBEXPLAIN",
	"REVIVERHEARTEXPLAIN",
	"PICKUPEXPLAIN",
	"DESPAWNEXPLAIN",
	"SIZETEST",
}

local function GetDeathmatchPopupString(name)
	local data = DEATHMATCH_STRINGS.POPUPS[name]
	local body = string.gsub(data.BODY, "\n", "")
	body = string.gsub(body, "\t", "")
	body = string.gsub(body, "*NEWLINE", "\n")
	return data.TITLE, body
end

local Deathmatch_Menu = Class(Screen, function(self)
    Screen._ctor(self, "Deathmatch_Menu")
	
	local black = self:AddChild(ImageButton("images/global.xml", "square.tex"))
    black.image:SetVRegPoint(ANCHOR_MIDDLE)
    black.image:SetHRegPoint(ANCHOR_MIDDLE)
    black.image:SetVAnchor(ANCHOR_MIDDLE)
    black.image:SetHAnchor(ANCHOR_MIDDLE)
    black.image:SetScaleMode(SCALEMODE_FILLSCREEN)
    black.image:SetTint(0,0,0,.5)
    black:SetOnClick(function() TheFrontEnd:PopScreen() end)
    black:SetHelpTextMessage("")
	
	self.root = self:AddChild(TEMPLATES.ScreenRoot())
	self.root:MoveToFront()

    self.detail_panel_frame = self.root:AddChild(TEMPLATES.RectangleWindow(500, 500))
    local r,g,b = unpack(UICOLOURS.BROWN_DARK)
    self.detail_panel_frame:SetBackgroundTint(r,g,b,0.6)
    self.detail_panel_frame.top:Hide()
    
	self.tip_list = self.root:AddChild(self:BuildTipsMenu())
	self.tip_list:SetPosition(-170, 0)

	self.title = self.root:AddChild(Text(UIFONT, 30))
	self.title:SetPosition(110, 150)
	self.title:SetRegionSize(225, 35)
	
	self.body = self.root:AddChild(Text(UIFONT, 25))
	self.body:SetPosition(110, -40)
	self.body:EnableWordWrap(true)
	self.body:SetRegionSize(250, 300)
	self.body:SetHAlign(ANCHOR_LEFT)
	self.body:SetVAlign(ANCHOR_TOP)
	
	local tip_grid_data = {}

	for i, v in ipairs(TIP_SORT_ORDER) do
		local tip = DEATHMATCH_STRINGS.POPUPS[v]
		if tip then
			table.insert(tip_grid_data, {title = tip.TITLE, tip = v.BODY, popup = v})
		end
	end
	
	self.tip_list:SetItemsData(tip_grid_data)
	
	local title, text = GetDeathmatchPopupString("WELCOME")
	self:SetTitle(title)
	self:SetBody(text)
end)

function Deathmatch_Menu:SetTitle(str)
	self.title:SetString(str)
end

function Deathmatch_Menu:SetBody(str)
	self.body:SetString(str)
end

function Deathmatch_Menu:BuildTipsMenu()
    local base_size = 128
    local cell_size = 73
    local row_w = cell_size
    local row_h = cell_size;
    local reward_width = 80
    local row_spacing = 5
	
	local font = HEADERFONT
	local title_font_size = 14

    local function ScrollWidgetsCtor(context, index)
        local w = Widget("tip-cell-"..index)
		----------------
		w.cell_root = w:AddChild(ImageButton("images/frontend_redux.xml", "listitem_thick_selected.tex", "listitem_thick_selected.tex"))
		w.cell_root:SetFocusScale((1 + .05)/1.5, (1 + .05)/1.5)
		w.cell_root:SetNormalScale(1/1.5, 1/1.5)
		
		w.tip_title = w.cell_root:AddChild(Text(font, title_font_size))
		
		w.focus_forward = w.cell_root

        w.cell_root.ongainfocusfn = function()  end
		
		return w
    end

    local function ScrollWidgetApply(context, widget, data, index)
		widget.data = data
		--print(data)
		if data ~= nil then
			widget.cell_root:Show()
			widget:Enable()
			
			widget.tip_title:SetString(data.title)
			
			widget.cell_root:SetOnClick(function() --Hornet: we dont have access to data variable in the ctor function sooo yeah....
				local title, text = GetDeathmatchPopupString(data.popup)
				self:SetTitle(title)
				self:SetBody(text)
			end)
		else
			widget:Disable()
			widget.cell_root:Hide()
		end
    end

    local grid = TEMPLATES.ScrollingGrid(
        {},
        {
            context = {},
            widget_width  = 300,
            widget_height = 80,
            num_visible_rows = 6,
            num_columns      = 1,
            item_ctor_fn = ScrollWidgetsCtor,
            apply_fn     = ScrollWidgetApply,
            scrollbar_offset = -30,
            scrollbar_height_offset = 0,
        })

    grid.up_button:SetPosition(0, 230)
    grid.down_button:SetPosition(0, -230)

	grid.scroll_bar_line:SetScale(.4)

    return grid
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