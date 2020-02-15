--[[ PLAYERNAME: 
 y offset 20
 size 30
 
-- KILLS
  y offset -20
  size 22]]
  
local Text = require("widgets/text")
local Image = require("widgets/image")
local Widget = require("widgets/widget")
local ScrollableList = require("widgets/scrollablelist")
local TeammateHealthBadge = require("widgets/teammatehealthbadge")

local function listingConstructor(v, i, parent)
	local listing = parent:AddChild(Widget("deathmatch_playerlisting"))
	
	local empty = v == nil or next(v) == nil
	
	listing.userid = not empty and v.userid or nil
	
	-- no bg yet, doing it later
	-- edit, just realized scroll list already has a bg for when i need it
	--local listing.bg = listing:AddChild(Image())
	
	local xpos = 0
	local ypos = 0
	
	listing.healthbadge = listing:AddChild(TeammateHealthBadge(ThePlayer))
	listing.healthbadge.playername:Hide()
	listing.healthbadge.name_banner_center:Hide()
	listing.healthbadge.name_banner_left:Hide()
	listing.healthbadge.name_banner_right:Hide()
	listing.healthbadge.anim:GetAnimState():Hide("stick")
	function listing.healthbadge:CheckForUser(userid)
		if AllPlayers ~= nil then
			local found = false
			for k, v2 in pairs(AllPlayers) do
				if v2.userid == userid and listing.healthbadge.playername:GetRegionSize() ~= nil then
					listing.healthbadge:SetPlayer(v2)
					listing.healthbadge:Show()
					found = true
					break
				end
			end
			if not found then
				listing.healthbadge:Hide()
			end
		end
	end
	if not empty then
		listing.healthbadge:CheckForUser(v.userid)
	else
		listing.healthbadge:Hide()
	end
	
	listing.playername = listing:AddChild(Text(NEWFONT_OUTLINE, 30))
	listing.playername.SetPlayerName = function(self, name)
		if self:GetRegionSize() ~= nil then
			self:SetString(name)
			self:Show()
			local xoffset, y = self:GetRegionSize()
			xoffset = (xoffset/2) + 5
			self:SetPosition(xpos+30+xoffset, ypos+20)
		end
	end
	if empty then
		listing.playername:Hide()
	else
		listing.playername:SetPlayerName(v.name)
	end
	
	listing.deathmatch_kills = listing:AddChild(Text(NEWFONT_OUTLINE, 22))
	function listing.deathmatch_kills.SetKills(self, data)
		if data and data.userid and TheWorld and TheWorld.net and self:GetRegionSize() ~= nil and
		TheWorld.net.deathmatch and TheWorld.net.deathmatch[data.userid] and
		TheWorld.net.deathmatch[data.userid].kills_local then
			self:SetString("Kills: "..tostring(TheWorld.net.deathmatch[data.userid].kills_local))
			self:Show()
			local xoffset, y = self:GetRegionSize()
			xoffset = (xoffset/2) + 5
			self:SetPosition(xpos+30+xoffset, -20)
		end
	end
	if not empty then
		listing.deathmatch_kills:SetKills(v)
	else
		listing.deathmatch_kills:Hide()
	end
	
	listing.team = listing:AddChild(Text(NEWFONT_OUTLINE, 22))
	function listing.team.SetTeamFromData(self, data)
		if data and data.userid and TheWorld and TheWorld.net and self:GetRegionSize() ~= nil and
		TheWorld.net.deathmatch and TheWorld.net.deathmatch[data.userid] and
		TheWorld.net.deathmatch[data.userid].team_local then
			if TheWorld.net.deathmatch[data.userid].team_local == 0 then
				self:SetString("No Team")
				self:SetColour(1,1,1,1)
			elseif math.clamp(TheWorld.net.deathmatch[data.userid].team_local, 1, #DEATHMATCH_TEAMS) == TheWorld.net.deathmatch[data.userid].team_local then
				self:SetString(DEATHMATCH_TEAMS[TheWorld.net.deathmatch[data.userid].team_local].name .. " Team")
				self:SetColour(unpack(DEATHMATCH_TEAMS[TheWorld.net.deathmatch[data.userid].team_local].colour))
			end
			self:Show()
			local xoffset, y = self:GetRegionSize()
			xoffset = (xoffset/2) + 5
			self:SetPosition(xpos+30+xoffset, -2)
		end
	end
	if empty then
		listing.team:Hide()
	else
		listing.team:SetTeamFromData(v)
	end
	
	return listing
end

local function UpdateListing(widget, data, index)
	local empty = data == nil or next(data) == nil
	
	widget.userid = not empty and data.userid or nil
	
	if not empty then
		widget.healthbadge:CheckForUser(data.userid)
	else
		widget.healthbadge:Hide()
	end
	
	if not empty then
		widget.playername:SetPlayerName(data.name)
		widget.deathmatch_kills:SetKills(data)
		widget.team:SetTeamFromData(data)
	else
		widget.playername:Hide()
		widget.deathmatch_kills:Hide()
		widget.team:Hide()
	end
	
end

-------------------------------------------------------------

local Deathmatch_Playerlist = Class(Widget, function(self, owner, nextWidgets)
	self.owner = owner
	Widget._ctor(self, "Deathmatch_Playerlist")

	self.proot = self:AddChild(Widget("ROOT"))
	self.numplayers = 0
	
	self:BuildPlayerList(nil)
	
	owner.dmstatstask = owner:DoPeriodicTask(3, function()
		self:BuildPlayerList(nil)
	end)
end)

function Deathmatch_Playerlist:BuildPlayerList(players)
    if not self.player_list then 
        self.player_list = self.proot:AddChild(Widget("deathmatch_player_list"))
        self.player_list:SetPosition(45,-215,0)
    end
	
	if players == nil then
		players = self:GetPlayerTable()
	end
	self.numplayers = #players
	
	if not self.scroll_list then
	
	
        self.list_root = self.player_list:AddChild(Widget("list_root"))
        self.list_root:SetPosition(90, 5)

        self.row_root = self.player_list:AddChild(Widget("row_root"))
        self.row_root:SetPosition(90, 35)
	
	
		self.player_widgets = {}
		for i = 1, 6 do
			table.insert(self.player_widgets, listingConstructor(players[i] or {}, i, self.row_root))
		end
		--items, listwidth, listheight, itemheight, itempadding, updatefn, widgetstoupdate, widgetXOffset, always_show_static, starting_offset, yInit, bar_width_scale_factor, bar_height_scale_factor, scrollbar_style
		self.scroll_list = self.list_root:AddChild(ScrollableList(players, 200, 350, 60, 7, UpdateListing, self.player_widgets, 7, nil, nil, -15, .8))
        self.scroll_list.bg:Kill() -- no need for focus
		self.scroll_list:LayOutStaticWidgets(-15)
        self.scroll_list:SetPosition(0,0)
	else
	
		self.scroll_list:SetList(players)
	end
end

function Deathmatch_Playerlist:GetPlayerTable()
	local clienttbl = TheNet:GetClientTable()
	if clienttbl == nil then
		return {}
	elseif TheNet:GetServerIsClientHosted() then
		return clienttbl
	end
	
    for i, v in ipairs(clienttbl) do
        if v.performance ~= nil then
            table.remove(clienttbl, i)
            break
        end
    end
    return clienttbl
end

function Deathmatch_Playerlist:Refresh()
	local players = self:GetPlayerTable()
	--[[if #players ~= self.numplayers then
		self:BuildPlayerList(players)
	else
	
		for k, v in ipairs(players) do
			local list_equivalent = self.scroll_list[k]
			if list_equivalent == nil or list_equivalent.userid ~= v.userid then
			self:BuildPlayerList(players)
			end
		end
		
		for k, widget in ipairs(self.player_widgets) do
			for k2, data in ipairs(players) do
				if widget.userid == data.userid then
					UpdateListing(widget, data, k)
				end
			end
		end
	end]]
	self:BuildPlayerList(players)
end

return Deathmatch_Playerlist