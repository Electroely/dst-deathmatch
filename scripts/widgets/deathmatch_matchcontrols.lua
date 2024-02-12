local Widget = require("widgets/widget")
local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")

local arenas = require("prefabs/arena_defs")

local UserCommands = require("usercommands")

local MAINBUTTON_SCALE = {0.7,0.7,0.7}
local MAINBUTTON_SCALE_FOCUS = {0.8,0.8,0.8}

local SUBBUTTON_SCALE = {0.4,0.4,0.4}
local SUBBUTTON_SCALE_FOCUS = {0.5,0.5,0.5}

local SUBBUTTON_STARTANGLE = 210*DEGREES
local SUBBUTTON_ENDANGLE = 330*DEGREES
local SUBBUTTON_RADIUS = 80

local BUTTON_ATLAS = "images/matchcontrolsbutton_bg.xml"
local BUTTON_IMAGE = "matchcontrolsbutton_bg.tex"

local FRAME_ATLAS = "images/matchcontrolsbutton_frame.xml"
local FRAME_IMAGE = "matchcontrolsbutton_frame.tex"


--submenus:
--[[
	name: code name
	str: UI name
	validfn: button is greyed out if function is present and returns false
	onclickfn: if present, executes function when clicked. otherwise lists buttons
	buttons: table or function returning a table
		- str: UI name for button
		- onclickfn: function for when the button is clicked
]]

local function GetTeamMode()
	return TheWorld.net.deathmatch_netvars.globalvars.matchmode:value()
end
local function GetMatchStatus()
	return TheWorld.net.deathmatch_netvars.globalvars.matchstatus:value()
end
local modes = {
	"ffa",
	"rvb",
	"2pt"
}
local function GetPlayerTeam()
	return ThePlayer.components.teamer:GetTeam()
end

local submenu_defs = {
	{ name = "team",
		str = DEATHMATCH_STRINGS.TEAMSELECT,
		imgfn = function()
			local w1 = Image("images/teamselect_pole.xml", "teamselect_pole.tex")
			local w2 = Image("images/teamselect_flag.xml", "teamselect_flag.tex")
			local team = GetPlayerTeam()
			if team ~= 0 then
				w2:SetTint(unpack(DEATHMATCH_TEAMS[team].colour))
			end
			w1:AddChild(w2)
			return w1
		end,
		validfn = function() return not (GetTeamMode() == 1) end,
		buttons = function()
			if GetTeamMode() == 2 then
				return {
					{str = DEATHMATCH_TEAMS[1].name,
					imgfn = function() 
						local w1 = Image("images/teamselect_pole.xml", "teamselect_pole.tex")
						local w2 = Image("images/teamselect_flag.xml", "teamselect_flag.tex")
						w2:SetTint(unpack(DEATHMATCH_TEAMS[1].colour))
						w1:AddChild(w2)
						return w1
					end},
					{str = DEATHMATCH_TEAMS[2].name,
					imgfn = function() 
						local w1 = Image("images/teamselect_pole.xml", "teamselect_pole.tex")
						local w2 = Image("images/teamselect_flag.xml", "teamselect_flag.tex")
						w2:SetTint(unpack(DEATHMATCH_TEAMS[2].colour))
						w1:AddChild(w2)
						return w1
					end},
				}
			end
			if GetTeamMode() == 3 then
				return {} --TODO: list players
			end
			end,
	},
	{ name = "teammode",
		str = DEATHMATCH_STRINGS.TEAMMODE,
		imgfn = function()
			local mode = modes[GetTeamMode()]
			return Image("images/modeselect_"..mode..".xml", "modeselect_"..mode..".tex")
		end,
		buttons = {
			{ str = DEATHMATCH_STRINGS.TEAMMODE_FFA,
			imgfn = function() return Image("images/modeselect_ffa.xml", "modeselect_ffa.tex") end },
			{ str = DEATHMATCH_STRINGS.TEAMMODE_RVB,
			imgfn = function() return Image("images/modeselect_rvb.xml", "modeselect_rvb.tex") end },
			{ str = DEATHMATCH_STRINGS.TEAMMODE_2PT,
			imgfn = function() return Image("images/modeselect_2pt.xml", "modeselect_2pt.tex") end },
		}
	},
	{ name = "map",
		str = DEATHMATCH_STRINGS.ARENAS,
		buttons = {
		}
	},
	{ name = "info",
		str = "info",
	}
}

local arenalist = {}
for k, v in pairs(arenas.VALID_ARENAS) do 
	table.insert(arenalist, v)
end
table.insert(arenalist, "random")

for k, v in pairs(arenalist) do
	local buttondata = {
		str = DEATHMATCH_STRINGS["ARENA_"..string.upper(v)],
		onclickfn = function()
			if ThePlayer then
				ThePlayer:PushEvent("changearenachoice", arenas.IDX_LOOKUP[v])
			end
		end,
		imgfn = function(button)
			return Image("images/map_icon_"..v..".xml", "map_icon_"..v..".tex")
		end
	}
	table.insert(submenu_defs[3].buttons, buttondata)
end

local Deathmatch_MatchControls = Class(Widget, function(self, owner)
	
	Widget._ctor(self, "Deathmatch_MatchControls")
	
	self.submenu = nil
	
	self.mainwidget = nil
	self.subwidgets = {}
	
	self.mainbutton_def = {
		onclickfn = function()
			local status = GetMatchStatus()
			if status == 1 then
				UserCommands.RunTextUserCommand("dm stop", ThePlayer, false)
			else
				UserCommands.RunTextUserCommand("dm start", ThePlayer, false)
			end
		end
	}

	self:BuildWidgets()
	
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
	self.mainwidget.imagedisabledcolour = {0.2, 0.2, 0.2, 1}
	self.mainwidget.frame = self.mainwidget.image:AddChild(Image(FRAME_ATLAS, FRAME_IMAGE))
	self.mainwidget:SetHoverText(self.submenu ~= nil and DEATHMATCH_STRINGS.GOBACK or (GetMatchStatus() == 1 and DEATHMATCH_STRINGS.STOPMATCH or DEATHMATCH_STRINGS.STARTMATCH))
	if self.submenu == nil and self.mainbutton_def.validfn and not self.mainbutton_def.validfn() then
		self.mainwidget:Disable()
	end
	--TODO: no local references like this
	self.mainwidget.onclick = function()
		if self.submenu ~= nil then
			self.submenu = nil
			self:BuildWidgets()
		elseif (self.mainbutton_def.validfn == nil or self.mainbutton_def.validfn()) and self.mainbutton_def.onclickfn then
			self.mainbutton_def.onclickfn()
		end
	end
	
	local buttons = self.submenu == nil and submenu_defs or submenu_defs[self.submenu].buttons
	if type(buttons) == "function" then
		buttons = buttons()
	end
	
	for k, v in pairs(buttons) do
		local w = self:AddChild(ImageButton(BUTTON_ATLAS, BUTTON_IMAGE, nil, nil, nil, nil, SUBBUTTON_SCALE))
		w.focus_scale = SUBBUTTON_SCALE_FOCUS
		w.normal_scale = SUBBUTTON_SCALE
		w.imagedisabledcolour = {0.2, 0.2, 0.2, 1}
		w:SetHoverText(v.str)
		w.onclick = function()
		--TODO: no local references
			if v.buttons and self.submenu == nil then
				self.submenu = k
				self:BuildWidgets()
			end
		end
		if v.imgfn then
			w.extraimage = w.image:AddChild(v.imgfn(w))
		end
		w.frame = w.image:AddChild(Image(FRAME_ATLAS, FRAME_IMAGE))
		if v.validfn and not v.validfn() then
			w:Disable()
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