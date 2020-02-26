--it's much easier to keep everything organized if we put every major feature in its own file
local G = GLOBAL

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
			G.ThePlayer:PushEvent("sendprivatemessage", self.chat_edit:GetString())
		else
			run_old(...)
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
		if inst._parent ~= nil then inst._parent = inst.entity:GetParent() end
		inst:ListenForEvent("sendprivatemessage", function(player, data)
			print("SENDPM", player, data)
			SendModRPCToServer(GetModRPC(modname, "deathmatch_privatemessage"), data)
		end, inst._parent)
		
		inst:ListenForEvent("pmdirty", function(inst)
			print("PMDIRTY", inst)
			local player = inst._parent
			if player and player.HUD then
				local team = player.components.teamer:GetTeam()
				if team == 0 then return end
				player.HUD.controls.networkchatqueue:PushMessage(
					"[T] "..inst._privatemessage_sender:value(),
					inst._privatemessage:value(),
					G.DEATHMATCH_TEAMS[team].colour,
					false, false,
					"default") --TODO: what's this argument, exactly
			end
		end)
		
		if not G.TheWorld.ismastersim then return end
		
		inst:ListenForEvent("broadcastprivatemessage", function(player, data)
			print("PM BROADCAST", player, data)
			for k, v in pairs(G.AllPlayers) do
				local team = v.components.teamer:GetTeam()
				if team ~= 0 and team == player.components.teamer:GetTeam() then
					v:PushEvent("receiveprivatemessage", {
						sender = player:GetDisplayName(),
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
	inst:PushEvent("broadcastprivatemessage", message)
end)
