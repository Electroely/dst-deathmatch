local Text = require("widgets/text")
local Image = require("widgets/image")
local Widget = require("widgets/widget")
local TeammateHealthBadge = require("widgets/deathmatch_teammatehealthbadge")

local SPACING = 80

local Deathmatch_EnemyList = Class(Widget, function(self, owner)
	Widget._ctor(self, "Deathmatch_EnemyList")
	
	self.widgets = {}
	
	self:RefreshWidgets()
end)

function Deathmatch_EnemyList:GetPlayerTable()
    local ClientObjs = TheNet:GetClientTable()
    if ClientObjs == nil then
        return {}
    elseif TheNet:GetServerIsClientHosted() then
        return ClientObjs
    end

    --remove dedicate host from player list
    for i, v in ipairs(ClientObjs) do
        if v.performance ~= nil then
            table.remove(ClientObjs, i)
            break
        end
    end
    return ClientObjs
end

function Deathmatch_EnemyList:MakeWidgetForPlayer(data)
	local badge = self:AddChild(TeammateHealthBadge(ThePlayer))
	self:SetWidgetToPlayer(badge, data)
	return badge
end

function Deathmatch_EnemyList:SetWidgetToPlayer(badge, data)
	badge:SetPlayer(UserToPlayer(data.userid))
	badge:SetHead(data.prefab, data.colour, data.ishost, data.userflags, data.base_skin)
end

function Deathmatch_EnemyList:RefreshWidgets()
	local players = self:GetPlayerTable()

	for i = 1, math.max(#players, #self.widgets) do
		if self.widgets[i] ~= nil then
			if players[i] ~= nil then
				self:SetWidgetToPlayer(self.widgets[i], players[i])
			else
				self.widgets[i]:Kill()
				self.widgets[i] = nil
			end
		elseif players[i] ~= nil then
			table.insert(self.widgets, self:MakeWidgetForPlayer(players[i]))
		end
	end
	
	--TODO: calculate spacing depending on number of widgets & screen size
	for i, widget in ipairs(self.widgets) do
		widget:SetPosition(-(i-1)*SPACING, 0)
	end
end

return Deathmatch_EnemyList