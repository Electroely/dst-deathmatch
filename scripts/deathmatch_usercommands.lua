local G = GLOBAL
local DEATHMATCH_STRINGS = G.DEATHMATCH_STRINGS
local tonumber = G.tonumber

local function FindKeyFromName(name)
	if name ~= nil and G.type(name) == "string" and name:lower() ~= "none" then
		for i, v in ipairs(G.DEATHMATCH_TEAMS) do
			if v.name:lower() == name:lower() then
				return i
			end
		end
		return 0
	else
		return 0
	end
end

local VoteUtil = G.require("voteutil")
G.require("builtinusercommands")
G.require("usercommands").GetCommandFromName("regenerate").vote = false
G.require("usercommands").GetCommandFromName("rollback").vote = false

AddUserCommand("setteam", {
	aliases = {"team"},
	prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.SETTEAM.NAME, 
	desc = DEATHMATCH_STRINGS.USERCOMMANDS.SETTEAM.DESC, 
	permission = G.COMMAND_PERMISSION.USER,
	slash = true,
	usermenu = false,
	servermenu = false,
	params = {"team"},
	vote = false,
	serverfn = function(params, caller)
		if caller:HasTag("spectator") then return end
		local teamnum = G.tonumber(params.team)
		if G.TheWorld.components.deathmatch_manager.allow_teamswitch_user then --custom teams
			if teamnum ~= nil and teamnum >= 0 and teamnum <= #G.DEATHMATCH_TEAMS then
				caller.components.teamer:SetTeam(teamnum)
			else
				caller.components.teamer:SetTeam(FindKeyFromName(params.team))
			end
		elseif G.TheWorld.components.deathmatch_manager.gamemode == 2 then --rvb
			local team = teamnum or FindKeyFromName(params.team)
			caller.teamchoice = math.clamp(team, 0, 2)
			local dm = G.TheWorld.components.deathmatch_manager
			if not dm.matchstarting and not dm.matchinprogress then
				caller.components.teamer:SetTeam(caller.teamchoice)
			end
		end
	end,
	localfn = function(params, caller)
		if caller:HasTag("spectator") then
			G.Networking_SystemMessage("This command can't be used in spectator mode.")
		end
		local mode = G.TheWorld.net:GetMode()
		local matchstatus = G.TheWorld.net:GetMatchStatus()
		local teamnum = G.tonumber(params.team) 
		teamnum = (teamnum ~= nil and teamnum >= 0 and teamnum <= #G.DEATHMATCH_TEAMS)
				and teamnum or FindKeyFromName(params.team)
		if mode == 4 and (matchstatus == 0 or matchstatus == 2) then -- custom teams
			local teamname = teamnum == 0 and "to be teamless" or G.DEATHMATCH_TEAMS[teamnum].name.." Team"
			G.Networking_SystemMessage("You've chosen "..teamname..".")
		elseif mode == 2 then --rvb
			teamnum = math.clamp(teamnum, 0, 2)
			local teamname = teamnum == 0 and "None" or G.DEATHMATCH_TEAMS[teamnum].name
			G.Networking_SystemMessage("Set team preference to \""..teamname..".\"")
		end
	end,
})

AddUserCommand("spectate", {
	prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.SPECTATE.NAME, 
	desc = DEATHMATCH_STRINGS.USERCOMMANDS.SPECTATE.DESC, 
	permission = G.COMMAND_PERMISSION.USER,
	slash = true,
	usermenu = false,
	servermenu = false,
	params = {},
	vote = false,
	serverfn = function(params, caller)
		if G.TheWorld.net:GetMode() == 1 or not G.TheWorld.net:IsPlayerInMatch(caller.userid) then
			local self = G.TheWorld.components.deathmatch_manager
			self:ToggleSpectator(caller)
		end
	end,
	localfn = function(params, caller)
		if not (G.TheWorld.net:GetMode() == 1 or not G.TheWorld.net:IsPlayerInMatch(caller.userid)) then
			G.Networking_SystemMessage(DEATHMATCH_STRINGS.CANT_DITCH_TEAMMATES_SPECTATE)
		end
	end,
})

AddUserCommand("afk", {
	prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.AFK.NAME, 
	desc = DEATHMATCH_STRINGS.USERCOMMANDS.AFK.DESC, 
	permission = G.COMMAND_PERMISSION.USER,
	slash = true,
	usermenu = false,
	servermenu = false,
	params = {},
	vote = false,
	serverfn = function(params, caller)
		if caller:HasTag("spectator_perma") or caller:HasTag("afk") then 
			caller:DisableAFK()
		else 
			caller:EnableAFK(true)
		end
	end,
})

AddUserCommand("setstate", {
	aliases = {"setcycle", "setlook"},
	prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.SETSTATE.NAME, 
	desc = DEATHMATCH_STRINGS.USERCOMMANDS.SETSTATE.DESC, 
	permission = G.COMMAND_PERMISSION.USER,
	slash = true,
	usermenu = false,
	servermenu = false,
	params = {"num"},
	vote = false,
	serverfn = function(params, caller)
		local num = tonumber(params.num) or 0
		if caller.ChangeCosmeticState then
			if num == 0 then
				num = caller.cosmeticstate + 1
				if num > caller.maxcosmeticstate then
					num = 1
				end
			end
			caller:ChangeCosmeticState(math.floor(num))
		end
	end,
})

AddUserCommand("deathmatch", {
	prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.DEATHMATCH.NAME, 
	aliases = {"dm"},
	desc = DEATHMATCH_STRINGS.USERCOMMANDS.DEATHMATCH.DESC, 
	permission = G.COMMAND_PERMISSION.USER,
	slash = true,
	usermenu = false,
	servermenu = false,
	params = {"action"},
	vote = false,
	serverfn = function(params, caller)
		local dm = G.TheWorld.components.deathmatch_manager
		if params.action == "start" then
			if G.TheWorld.net.components.worldvoter:IsVoteActive() then
				G.TheNet:Announce(DEATHMATCH_STRINGS.CHATMESSAGES.STARTMATCH_VOTEACTIVE)
			elseif not (dm.doingreset or dm.matchinprogress or dm.matchstarting) then
				dm:ResetDeathmatch()
			end
		elseif params.action == "stop" or "end" then
			if dm.allow_endmatch_user and dm.matchinprogress then
				dm:Vote("endmatch", caller)
			end
		end
	end,
})

AddUserCommand("despawn", {
    prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.DESPAWN.NAME, 
	aliases = {},
    desc = DEATHMATCH_STRINGS.USERCOMMANDS.DESPAWN.DESC, 
    permission = G.COMMAND_PERMISSION.USER,
    slash = true,
    usermenu = false,
    servermenu = false,
    params = {},
    vote = false,
    serverfn = function(params, caller)
		local dm = G.TheWorld.components.deathmatch_manager
		if not (caller and caller.IsValid and caller:IsValid()) or dm.doingreset or dm:IsPlayerInMatch(caller) then
			return
		end
		G.TheWorld.despawnplayerdata[caller.userid] = caller.SaveForReroll ~= nil and caller:SaveForReroll() or nil
		G.TheWorld:PushEvent("ms_playerdespawnanddelete", caller)
    end,
	localfn = function(params, caller)
		local status = G.TheWorld.net:GetMatchStatus()
		if status ~= nil then
			if status == 1 then
				G.Networking_SystemMessage(DEATHMATCH_STRINGS.CHATMESSAGES.DESPAWN_MIDMATCH)
			elseif status == 2 then
				G.Networking_SystemMessage(DEATHMATCH_STRINGS.CHATMESSAGES.DESPAWN_STARTING)
			end
		end
	end
})

AddUserCommand("setteammode", {
    prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.SETTEAMMODE.NAME, 
    desc = DEATHMATCH_STRINGS.USERCOMMANDS.SETTEAMMODE.DESC, 
    permission = G.COMMAND_PERMISSION.ADMIN,
    confirm = false,
    slash = true,
    usermenu = false,
    servermenu = true,
    params = {"teammode"},
    vote = false, --no longer a vote option
    votetimeout = 30,
    voteminstartage = 0,
    voteminpasscount = 1,
    votecountvisible = true,
    voteallownotvoted = true,
    voteoptions = {"Free For All", "Red vs. Blue", "2-Player Teams", --[["Custom"]]}, 
    votetitlefmt = DEATHMATCH_STRINGS.USERCOMMANDS.SETTEAMMODE.VOTETITLE, 
    votenamefmt = DEATHMATCH_STRINGS.USERCOMMANDS.SETTEAMMODE.VOTENAME, 
    votepassedfmt = "Vote complete!", 
    votecanstartfn = VoteUtil.DefaultCanStartVote,
    voteresultfn = VoteUtil.DefaultMajorityVote,
    serverfn = function(params, caller)
		local dm = G.TheWorld.components.deathmatch_manager
		local mode = G.tonumber(params.teammode)
		if mode ~= nil and type(mode) == "number" and (mode >= 0 and mode <= 3) then
			dm:SetGamemode(math.floor(mode))
			return
		end
		if params.voteselection ~= nil then
			if params.voteselection == 4 then
				dm:SetGamemode(0)
			else
				dm:SetGamemode(params.voteselection)
			end
		end
    end,
})

AddUserCommand("setarena", {
	aliases = {"setmap"},
    prettyname = DEATHMATCH_STRINGS.USERCOMMANDS.SETARENA.NAME, 
    desc = DEATHMATCH_STRINGS.USERCOMMANDS.SETARENA.DESC, 
    permission = G.COMMAND_PERMISSION.ADMIN,
    confirm = false,
    slash = true,
    usermenu = false,
    servermenu = true,
    params = {"arena"},
    vote = false, --no longer a vote option
    votetimeout = 15,
    voteminstartage = 0,
    voteminpasscount = 1,
    votecountvisible = true,
    voteallownotvoted = true,
    voteoptions = {"The Atrium", "The Badlands", "Pig Village", "Random"}, 
    votetitlefmt = DEATHMATCH_STRINGS.USERCOMMANDS.SETARENA.VOTETITLE, 
    votenamefmt = DEATHMATCH_STRINGS.USERCOMMANDS.SETARENA.VOTENAME, 
    votepassedfmt = "Vote complete!", 
    votecanstartfn = VoteUtil.DefaultCanStartVote,
    voteresultfn = VoteUtil.DefaultMajorityVote,
    serverfn = function(params, caller)
		local arenas = { [1]="atrium", [2]="desert", [3]="pigvillage", [4]="random", atrium="atrium", desert="desert", pigvillage="pigvillage", malbatross = "malbatross", moonisland = "moonisland", stalker = "stalker", random="random" }
		local dm = G.TheWorld.components.deathmatch_manager
		local mode = params.arena
		if mode ~= nil and arenas[mode] ~= nil then
			dm:SetNextArena(arenas[mode])
		end
		if params.voteselection ~= nil then
			dm:SetNextArena(arenas[params.voteselection])
		end
    end,
})

