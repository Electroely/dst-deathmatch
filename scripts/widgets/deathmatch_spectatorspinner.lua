local Widget = require("widgets/widget")
local Text = require("widgets/text")
local TextButton = require("widgets/textbutton")
local Spinner = require("widgets/spinner")
local TEMPLATES = require "widgets/redux/templates"

local UserCommands = require("usercommands")

--options, width, height, textinfo, editable, atlas, textures, lean, textwidth, textheight
local function GetOptionsList()
	local options = {}
	if AllPlayers ~= nil then
		for k, v in pairs(AllPlayers) do
			if v == ThePlayer or not v:HasTag("spectator") then
				local txt = v.name or ""
				local data = v
				table.insert(options, { text=txt, data=data })
			end
		end
	end
	return options
end

local initlisteners = false
local Deathmatch_SpectatorSpinner = Class(Widget, function(self, owner)

	self.owner = owner
	Widget._ctor(self, "Deathmatch_SpectatorSpinner")

	self.bg = self:AddChild(TEMPLATES.RectangleWindow(215, 80))
    local r,g,b = unpack(UICOLOURS.BROWN_DARK)
    self.bg:SetBackgroundTint(r,g,b,0.8)
	self.bg:SetPosition(0, 17)
	
	self.title = self:AddChild(Text(NEWFONT_OUTLINE, 30, "Currently Spectating:"))
	self.title:SetPosition(0, 40)
	
	self.spinner = self:AddChild(Spinner(GetOptionsList(), 300, 40, false, false, nil, nil, true))
	self.spinner:SetOnChangedFn(function(selected, old)
		if selected ~= nil and self.owner.components.deathmatch_spectatorcorpse then
			local sc_dm = self.owner.components.deathmatch_spectatorcorpse
			if sc_dm.active then
				sc_dm:SetTarget(selected)
			else
				sc_dm:SetTarget(ThePlayer)
			end
		end
	end)
	
	--[[
	self.spectatebutton = self:AddChild(TextButton())
	self.spectatebutton:SetPosition(0, 70)
	self.spectatebutton:SetTextSize(40)
	self.spectatebutton:SetText("󰀉")
	self.spectatebutton:SetOnClick(function()
		UserCommands.RunTextUserCommand("spectate", ThePlayer, false)
	end)]]
	
	self.inst:ListenForEvent("playerexited", function(world, player)
		self.spinner:SetOptions(GetOptionsList())
	end, TheWorld)
	
	self.inst:ListenForEvent("playerentered", function(world, player)
		self.spinner:SetOptions(GetOptionsList())
	end, TheWorld)

	self.inst:ListenForEvent("startspectating", function(player)
		self:Show()
		self.spinner:SetSelected(self.owner)
	end, self.owner)
	self.inst:ListenForEvent("stopspectating", function(player)
		self.spinner:SetSelected(self.owner)
		self:Hide()
	end, self.owner)
end)

local Show_old = Deathmatch_SpectatorSpinner.Show
function Deathmatch_SpectatorSpinner:Show(...)
	self.spinner:SetOptions(GetOptionsList())
	Show_old(self, ...)
end

return Deathmatch_SpectatorSpinner
