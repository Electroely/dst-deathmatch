local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Spinner = require("widgets/spinner")
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

local Deathmatch_SpectatorSpinner = Class(Widget, function(self, owner)

	self.owner = owner
	Widget._ctor(self, "Deathmatch_SpectatorSpinner")
	
	self.title = self:AddChild(Text(NEWFONT_OUTLINE, 30, "Currently Spectating:"))
	self.title:SetPosition(0, 40)
	
	self.spinner = self:AddChild(Spinner(GetOptionsList(), 300, 40, false, false, nil, nil, true))
	self.spinner:SetOnChangedFn(function(selected, old)
		if selected ~= nil and ThePlayer.components.deathmatch_spectatorcorpse then
			local sc_dm = ThePlayer.components.deathmatch_spectatorcorpse
			if sc_dm.active then
				sc_dm:SetTarget(selected)
			else
				sc_dm:SetTarget(ThePlayer)
			end
		end
	end)
	
	TheWorld:ListenForEvent("playerexited", function(player)
		if self and self.shown then
			self.spinner:SetOptions(GetOptionsList())
		end
	end)
	
	TheWorld:ListenForEvent("playerentered", function(player)
		if self and self.shown then
			self.spinner:SetOptions(GetOptionsList())
		end
	end)
end)

local Show_old = Deathmatch_SpectatorSpinner.Show
function Deathmatch_SpectatorSpinner:Show(...)
	self.spinner:SetOptions(GetOptionsList())
	Show_old(self, ...)
end

return Deathmatch_SpectatorSpinner
