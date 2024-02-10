local Text = require("widgets/text")
local Image = require("widgets/image")
local Widget = require("widgets/widget")
local TeammateHealthBadge = require("widgets/deathmatch_teammatehealthbadge")

local SPACING = 80
local Y_OFFSET = 70

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

local function CreateDummyData(character)
	return {
		prefab = character,
		userid = character,
		base_skin = character.."_none",
		userflags = 0,
		name = STRINGS.NAMES[character]
	}
end

local function CreateDummyTable()
	local data = {}
	for k, character in pairs(DST_CHARACTERLIST) do
		table.insert(data, CreateDummyData(character))
	end
	return data
end

function Deathmatch_EnemyList:MakeWidgetForPlayer(data)
	local badge = self:AddChild(TeammateHealthBadge(ThePlayer))
	self:SetWidgetToPlayer(badge, data)
	return badge
end

function Deathmatch_EnemyList:SetWidgetToPlayer(badge, data)
	badge:SetPlayer(data.userid)
end

function Deathmatch_EnemyList:RefreshWidgets()
	local players = self:GetPlayerTable()
	--local players = CreateDummyTable()
	
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
		if i%2 == 1 then
			widget:SetPosition(-(math.ceil(i/2)-1)*SPACING, 0)
		else
			widget:SetPosition(-((i/2)-1)*SPACING - SPACING*0.5, Y_OFFSET)
		end
	end
end

return Deathmatch_EnemyList