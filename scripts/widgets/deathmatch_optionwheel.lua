local Widget = require("widgets/widget")
local ImageButton = require("widgets/imagebutton")

local RADIUS = 30

local function CreateWheelOption(widget)
	local self = ImageButton("images/optionwheelcircle.xml", "optionwheelcircle.tex")
	self:AddChild(widget)
	widget:SetClickable(false)
	
	return self
end

local Deathmatch_OptionWheel = Class(Widget, function(self, data)
	
	Widget._ctor(self, "Deathmatch_OptionWheel")
	
	self.optionwidgets = {}
	
	if data then
		self:BuildWheel(data)
	end
end)

function Deathmatch_OptionWheel:BuildWheel(data)
	--data: {name, widget, clickfn}
	for k, v in pairs(self.optionwidgets) do
		v:Kill()
	end
	self.optionwidgets = {}
	
	local num_options = #data
	for i, v in ipairs(data) do
		local optionbutton = CreateWheelOption(data.widget)
		optionbutton:SetOnClick(data.clickfn)
		optionbutton:SetHoverText(data.name)
		local angle = ((i/num_options) * (2*math.pi)) + 0.5*math.pi
		optionbutton:SetPosition(math.cos(angle)*RADIUS, math.sin(angle)*RADIUS)
		table.insert(optionwidgets, optionbutton)
	end
end


return Deathmatch_OptionWheel
