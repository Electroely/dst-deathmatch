local Widget = require("widgets/widget")
local ImageButton = require("widgets/imagebutton")

local MAINBUTTON_SCALE = {0.7,0.7,0.7}
local MAINBUTTON_SCALE_FOCUS = {0.8,0.8,0.8}

local SUBBUTTON_SCALE = {0.4,0.4,0.4}
local SUBBUTTON_SCALE_FOCUS = {0.5,0.5,0.5}

local SUBBUTTON_STARTANGLE = 210*DEGREES
local SUBBUTTON_ENDANGLE = 330*DEGREES
local SUBBUTTON_RADIUS = 80

local BUTTON_ATLAS = "images/matchcontrolsframe.xml"
local BUTTON_IMAGE = "matchcontrolsframe.tex"

local Deathmatch_MatchControls = Class(Widget, function(self, owner)
	
	Widget._ctor(self, "Deathmatch_MatchControls")
	
	self.submenu = nil
	
	self.mainwidget = nil
	self.subwidgets = {}
	
	self.mainbutton_def = {
		str = DEATHMATCH_STRINGS.STARTMATCH
	}
	self.submenu_defs = {
		{ name = "team",
			str = DEATHMATCH_STRINGS.TEAMSELECT,
			buttons = {
				{ str = "test1" },
				{ str = "test2" },
			}
		},
		{ name = "teammode",
			str = DEATHMATCH_STRINGS.TEAMMODE,
			buttons = {
				{ str = DEATHMATCH_STRINGS.TEAMMODE_FFA },
				{ str = DEATHMATCH_STRINGS.TEAMMODE_RVB },
				{ str = DEATHMATCH_STRINGS.TEAMMODE_2PT },
			}
		},
		{ name = "map",
			str = DEATHMATCH_STRINGS.ARENAS,
			buttons = {
				{ str = DEATHMATCH_STRINGS.ARENA_ATRIUM },
				{ str = DEATHMATCH_STRINGS.ARENA_DESERT },
				{ str = DEATHMATCH_STRINGS.ARENA_PIGVILLAGE },
				{ str = DEATHMATCH_STRINGS.ARENA_RANDOM },
			}
		},
		{ name = "info",
			str = "info",
		}
	}
	
end)

function Deathmatch_MatchControls:BuildWidgets()
	if self.mainwidget then
		self.mainwidget:Kill()
		self.mainwidget = nil
	end
	for k, v in pairs(self.subwidgets) do
		v:Kill()
	end
	self.subwidgets = {}

	self.mainwidget = self:AddChild(ImageButton(BUTTON_ATLAS, BUTTON_IMAGE, nil, nil, nil, nil, MAINBUTTON_SCALE))
	self.mainwidget.focus_scale = MAINBUTTON_SCALE_FOCUS
	self.mainwidget.normal_scale = MAINBUTTON_SCALE
	self.mainwidget:SetHoverText(self.submenu ~= nil and DEATHMATCH_STRINGS.GOBACK or self.mainbutton_def.str)
	--TODO: no local references like this
	self.mainwidget.onclick = function()
		if self.submenu ~= nil then
			self.submenu = nil
			self:BuildWidgets()
		end
	end
	
	for k, v in pairs(self.submenu == nil and self.submenu_defs or self.submenu_defs[self.submenu].buttons) do
		local w = self:AddChild(ImageButton(BUTTON_ATLAS, BUTTON_IMAGE, nil, nil, nil, nil, SUBBUTTON_SCALE))
		w.focus_scale = SUBBUTTON_SCALE_FOCUS
		w.normal_scale = SUBBUTTON_SCALE
		w:SetHoverText(v.str)
		w.onclick = function()
		--TODO: no local references
			if v.buttons and self.submenu == nil then
				self.submenu = k
				self:BuildWidgets()
			end
		end
		table.insert(self.subwidgets, w)
	end
	
	local count = #self.subwidgets
	local startangle = SUBBUTTON_STARTANGLE
	local endangle = SUBBUTTON_ENDANGLE
	local radius = SUBBUTTON_RADIUS
	for i, w in ipairs(self.subwidgets) do
		local i2 = count <= 2 and i or i-1
		local angle = startangle + ((endangle-startangle)/((count <= 2 and count+2 or count)-1)) * i2
		local x = math.cos(angle) * radius
		local y = math.sin(angle) * radius
		w:SetPosition(x,y)
	end
	
end

return Deathmatch_MatchControls