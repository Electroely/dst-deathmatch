--it's much easier to keep everything organized if we put every major feature in its own file
local G = GLOBAL
G.require("emoji_items")

local function GetOwnedEmojiList(userid) --this only works clientside if its the player checking their own list
	local owned_emojis = {}
	for item_type, emoji in pairs(G.EMOJI_ITEMS) do
		if (not emoji.data.requires_validation) or 
		(G.ThePlayer ~= nil and G.ThePlayer.userid == userid and G.TheInventory:CheckOwnership(item_type)) or
		G.TheInventory:CheckClientOwnership(userid, item_type) then
			owned_emojis[emoji.input_name] = emoji.data.utf8_str
		end
	end
	return owned_emojis
end
local function FilterEmojisForUser(userid, message)
	local emojilist = GetOwnedEmojiList(userid)
	for input_string, char in pairs(emojilist) do
		message = string.gsub(message, ":"..input_string..":", char)
	end
	return message
end

local function SetDirty(netvar, val)
	netvar:set_local(val)
	netvar:set(val)
end

AddClassPostConstruct("screens/chatinputscreen", function(self, whisper, team)
	self.team = team == "team" and G.ThePlayer and G.ThePlayer.components.teamer:GetTeam() ~= 0
	local playerteam = G.ThePlayer.components.teamer:GetTeam()
	if self.team then
		self.chat_type:SetString("Team:")
		self.chat_type:SetColour(G.DEATHMATCH_TEAMS[playerteam].colour)
		--self.chat_type:SetColour(100/255, 65/255, 165/255, 1)
	end
	
	local run_old = self.Run
	self.Run = function(...)
		if self.team then
			local chatstring = self.chat_edit:GetString()
			if string.len(chatstring) == 0 or string.sub(chatstring, 0, 1) == "/" then
				return run_old(...)
			end
			G.ThePlayer:PushEvent("sendprivatemessage", chatstring)
		else
			return run_old(...)
		end
	end
end)

local ChatInputScreen = G.require("screens/chatinputscreen")
G.TheInput:AddKeyDownHandler(G.KEY_T, function()
	if G.TheFrontEnd and G.TheFrontEnd:GetActiveScreen().name == "HUD" then
		if G.ThePlayer ~= nil and G.ThePlayer.components.teamer:GetTeam() ~= 0 then
			G.TheFrontEnd:PushScreen(ChatInputScreen(false, "team"))
		end
	end
end)

AddPrefabPostInit("player_classified", function(inst)
	-- would it be a ood idea to make multiple postinits for the same prefab in the same mod
	inst._privatemessage = G.net_string(inst.GUID, "deathmatch.privatemessage", "pmdirty")
	inst._privatemessage_sender = G.net_string(inst.GUID, "deathmatch.privatemessage_sender")
	--inst._privatemessage_team = G.net_byte(inst.GUID, "deathmatch.privatemessage_team")
	
	inst:DoTaskInTime(0, function(inst)
		if inst._parent == nil then inst._parent = inst.entity:GetParent() end
		print("INIT TEAMCHAT LISTENERS", inst, inst._parent)
		inst:ListenForEvent("sendprivatemessage", function(player, data)
			print("SENDPM", player, data)
			SendModRPCToServer(GetModRPC(modname, "deathmatch_privatemessage"), data)
			--the emoji gets sent clientside immediately. might make debugging harder but its less jarring
			data = FilterEmojisForUser(player.userid, data)
			inst._privatemessage_sender:set_local(player.userid)
			inst._privatemessage:set_local(data)
			inst:PushEvent("pmdirty")
		end, inst._parent)
		
		inst:ListenForEvent("pmdirty", function(inst)
			print("PMDIRTY", inst)
			local player = inst._parent
			if player and player.HUD then
				local team = player.components.teamer:GetTeam()
				if team == 0 then return end
				local clientdata = G.TheNet:GetClientTableForUser(inst._privatemessage_sender:value())
				if clientdata == nil then return end
				local profileflair = nil
				for i, v in ipairs(clientdata.vanity) do
					if string.sub(v, 0, 12) == "profileflair" then
						profileflair = v
					end
				end
				player.HUD.controls.networkchatqueue:PushMessage(
					"[T] "..clientdata.name,
					inst._privatemessage:value(),
					G.DEATHMATCH_TEAMS[team].colour,
					false, false,
					profileflair or "default")
			end
		end)
		
		if not G.TheWorld.ismastersim then return end
		
		inst:ListenForEvent("broadcastprivatemessage", function(player, data)
			print("PM BROADCAST", player, data)
			for k, v in pairs(G.AllPlayers) do
				local team = v.components.teamer:GetTeam()
				print("checking player", v, "of team", team)
				if v ~= player and team ~= 0 and team == player.components.teamer:GetTeam() then
					v:PushEvent("receiveprivatemessage", {
						sender = player.userid,
						message = data
					})
				end
			end
		end, inst._parent)
		
		inst:ListenForEvent("receiveprivatemessage", function(player, data)
			print("PM RECIEVED", player, data)
			if data and data.sender and data.message then
				inst._privatemessage_sender:set(data.sender)
				SetDirty(inst._privatemessage, data.message)
			end
		end, inst._parent)
	end)
end)

G.require("networkclientrpc")
AddModRPCHandler(modname, "deathmatch_privatemessage", function(inst, message)
	if not (G.checkstring(message)) then return end
	print("PM RPC RECEIVED", inst, message)
	message = FilterEmojisForUser(inst.userid, message)
	inst:PushEvent("broadcastprivatemessage", message)
end)
