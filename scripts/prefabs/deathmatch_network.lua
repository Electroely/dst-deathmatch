--[[local MakeWorldNetwork = require("prefabs/world_network")

local assets =
{
    Asset("SCRIPT", "scripts/prefabs/world_network.lua"),
}

local prefabs =
{
}

local function custom_postinit(inst)
	inst:RemoveComponent("clock")
	
	inst._setatriumactive = net_bool(inst.GUID, "deathmatch.atrium_active", "onatriumactivedirty")
	inst:ListenForEvent("onatriumactivedirty", function(inst)
		TheWorld.state.atrium_active = inst._setatriumactive:value()
		TheWorld:PushEvent("atriumactivechanged")
	end)
	inst:ListenForEvent("atriumpowered", function(wrld, data)
		inst._setatriumactive:set_local(false)
		inst._setatriumactive:set(data)
		TheWorld.state.atrium_active = data
	end, TheWorld)
end

return MakeWorldNetwork("deathmatch_network", prefabs, assets, custom_postinit)]]

local function InitDeathmatchData(userid)
	TheWorld.net.deathmatch[userid] = { 
		--kills=G.net_byte(G.TheWorld.net.GUID, "deathmatch."..tostring(userid).."_kills", "deathmatch_killsdirty"),
		kills_local=0,
		--deaths=G.net_byte(G.TheWorld.net.GUID, "deathmatch."..tostring(userid).."_deaths", "deathmatch_deathsdirty"),
		--deaths_local=0,
		--team=G.net_byte(G.TheWorld.net.GUID, "deathmatch."..tostring(userid).."_team", "deathmatch_teamdirty"),
		team_local=0
	}
end
local function UserOnline(clienttable, userid)
	local found = false
	for k, v in pairs(clienttable) do
		if v.userid == userid then
			found = true
		end
	end
	return found
end
local function GetPlayerTable()
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
local function SetDirty(netvar, val)
	netvar:set_local(val)
	netvar:set(val)
end


local function PostInit(inst)
    inst:LongUpdate(0)
    inst.entity:FlushLocalDirtyNetVars()

    for k, v in pairs(inst.components) do
        if v.OnPostInit ~= nil then
            v:OnPostInit()
        end
    end
end

local function OnRemoveEntity(inst)
    if TheWorld ~= nil then
        assert(TheWorld.net == inst)
        TheWorld.net = nil
    end
end

local function DoPostInit(inst)
	
    if not TheWorld.ismastersim then
        if TheWorld.isdeactivated then
            --wow what bad timing!
            return
        end
        --master sim would have already done a proper PostInit in loading
        TheWorld:PostInit()
    end
    if not TheNet:IsDedicated() then
        if ThePlayer == nil then
            TheNet:SendResumeRequestToServer(TheNet:GetUserID())
        end
        PlayerHistory:StartListening()
    end
end

--------------------------------------------------------------------------

local function playerdatafn()
	local net = TheWorld.net
	local inst = CreateEntity()

    inst.entity:SetCanSleep(false)
    inst.persists = false

	inst.entity:AddNetwork()

	inst:AddTag("classified")

	inst.kills = net_ushortint(inst.GUID, "deathmatch.netkills", "deathmatch_killsdirty")
	inst.team = net_byte(inst.GUID, "deathmatch.netteam", "deathmatch_teamdirty")
	inst.userid = net_string(inst.GUID, "deathmatch.netuserid", "deathmatchdatadirty")
	inst.health = net_byte(inst.GUID, "deathmatch.nethealth", "deathmatch_playerhealthdirty")
	inst.isinmatch = net_bool(inst.GUID, "deathmatch.isinmatch", "deathmatch_playerinmatchdirty")

	inst.entity:SetPristine()

	--limit one event per frame
	for k, event in pairs({"deathmatch_killsdirty", "deathmatch_teamdirty", "deathmatchdatadirty", "deathmatch_playerhealthdirty", "deathmatch_playerinmatchdirty"}) do
		inst:ListenForEvent(event, function(inst, data)
			if not net[event.."_task"] then
				net[event.."_task"] = net:DoTaskInTime(0, function(net)
					net:PushEvent(event, data)
					net[event.."_task"] = nil
				end)
			end
		end)
	end

	return inst
end

local function fn()
    local inst = CreateEntity()

    assert(TheWorld ~= nil and TheWorld.net == nil)
    TheWorld.net = inst

    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddNetwork()
	--inst.entity:AddShardClient()
    inst:AddTag("CLASSIFIED")
	
	--inst:AddComponent("shardstate") 

    inst.entity:SetPristine()
	
    inst:AddComponent("autosaver")
	inst:AddComponent("worldvoter")
	inst:AddComponent("seasons")
	inst:AddComponent("worldreset")
    inst:AddComponent("worldtemperature")
	inst:AddComponent("deathmatch_timer")

    inst.PostInit = PostInit
    inst.OnRemoveEntity = OnRemoveEntity
	

    inst:DoTaskInTime(0, DoPostInit)
	
	inst._setatriumactive = net_bool(inst.GUID, "deathmatch.atrium_active", "onatriumactivedirty")
	inst:ListenForEvent("onatriumactivedirty", function(inst)
		TheWorld.state.atrium_active = inst._setatriumactive:value()
		TheWorld:PushEvent("atriumactivechanged")
	end)
	inst:ListenForEvent("atriumpowered", function(wrld, data)
		inst._setatriumactive:set_local(false)
		inst._setatriumactive:set(data)
		TheWorld.state.atrium_active = data
	end, TheWorld)

	inst.deathmatch = {}
	inst.deathmatch_netvars = {}
	local clienttbl = TheNet:GetClientTable() or {}
	for k, v in pairs(clienttbl) do
		if inst.deathmatch[v.userid] == nil then
			InitDeathmatchData(v.userid)
		end
	end
	for i = 1, TheNet:GetServerMaxPlayers() do
		inst.deathmatch_netvars[i] = SpawnPrefab("deathmatch_network_playerdata")
	end
	inst.deathmatch_netvars.globalvars = {
		timertime = net_ushortint(inst.GUID, "deathmatch_timertime", "deathmatch_timertimedirty"),
		timercurrent = net_ushortint(inst.GUID, "deathmatch_timercurrent", "deathmatch_timercurrentdirty"),
		matchmode = net_byte(inst.GUID, "deathmatch_matchmode", "deathmatch_matchmodedirty"),
		matchstatus = net_tinybyte(inst.GUID, "deathmatch_matchstatus", "deathmatch_matchstatusdirty"),
		leadingplayer = net_string(inst.GUID, "deathmatch_leadingplayer", "deathmatch_leadingplayerdirty"),
		arena = net_tinybyte(inst.GUID, "deathmatch_arena", "deathmatch_arenadirty"),
	}
	--------------
	function inst.FillNextEmptyDataSlot(inst,userid)
		if TheWorld.ismastersim then
			for _, v in ipairs(inst.deathmatch_netvars) do
				local clienttable = GetPlayerTable() or {}
				if clienttable and v.userid and v.userid:value() == "" or not UserOnline(clienttable, v.userid:value()) then
					v.userid:set(userid)
					return v
				end
			end
		end
	end
	function inst.GetPlayerHealth(inst,userid)
		local datatable = GetNetDMDataTable(userid)
		if datatable == nil then
			return 1
		end
		return datatable.health:value()/255
	end
	function inst.IsPlayerInMatch(inst, userid)
		local datatable = GetNetDMDataTable(userid)
		if datatable == nil then
			return false
		end
		return datatable.isinmatch:value()
	end
	function inst.GetMode(inst)
		return inst.deathmatch_netvars.globalvars.matchmode:value()
	end
	function inst.GetMatchStatus(inst)
		return inst.deathmatch_netvars.globalvars.matchstatus:value()
	end
	function inst.GetArena(inst)
		return inst.deathmatch_netvars.globalvars.arena:value()
	end
	function inst.AddKill(inst,userid)
		local datatable = GetNetDMDataTable(userid)
		if inst.deathmatch[userid] == nil then
			InitDeathmatchData(userid)
		end
			inst.deathmatch[userid].kills_local = inst.deathmatch[userid].kills_local + 1
		if datatable == nil then
			inst:FillNextEmptyDataSlot(userid)
			datatable = GetNetDMDataTable(userid)
		end
		if datatable ~= nil then
			datatable.kills:set(inst.deathmatch[userid].kills_local)
		end
	end
	function inst.SetTeam(inst, userid, team)
		local datatable = GetNetDMDataTable(userid)
		if datatable == nil then
			inst:FillNextEmptyDataSlot(userid)
			datatable = GetNetDMDataTable(userid)
		end
		if datatable ~= nil then
			datatable.team:set(team)
		end
		if inst.deathmatch[userid] == nil then
			InitDeathmatchData(userid)
		end
		inst.deathmatch[userid].team_local = team
	end
	function inst.GetPlayerTeam(inst,userid)
		local datatable = GetNetDMDataTable(userid)
		if datatable == nil then
			return 0
		end
		return datatable.team:value()
	end
	inst:ListenForEvent("deathmatch_kill", function(inst, data)
		if data ~= nil then
			if data.inst.userid and data.inst.userid ~= "" and inst.deathmatch[data.inst.userid] == nil then
				InitDeathmatchData(data.inst.userid)
			end
			if data.inst.userid and data.data.victim.userid and data.inst.userid ~= "" and data.data.victim.userid ~= "" then
				--local dmdata = inst.deathmatch[data.inst.userid]
				--dmdata.kills_local = dmdata.kills_local + 1
				inst:AddKill(data.inst.userid)
				--dmdata.kills:set(dmdata.kills_local)
			end	
		end
	end)
	
	--[[inst:ListenForEvent("deathmatch_death", function(inst, data)
		if data ~= nil then
			if data.inst.userid and data.inst.userid ~= "" and inst.deathmatch[data.inst.userid] == nil then
				InitDeathmatchData(data.inst.userid)
			end
			if data.inst.userid and data.data.afflicter and data.data.afflicter.userid and data.inst.userid ~= "" and data.data.afflicter.userid ~= ""  then
				local dmdata = inst.deathmatch[data.inst.userid]
				dmdata.deaths_local = dmdata.deaths_local + 1
				dmdata.deaths:set(dmdata.deaths_local)
			end	
		end
	end)]]
	--if not inst.ismastersim then
		inst:ListenForEvent("deathmatchdatadirty", function()
			local clienttbl = TheNet:GetClientTable() or {}
			for k, v in pairs(clienttbl) do
				if inst.deathmatch[v.userid] == nil then
					InitDeathmatchData(v.userid)
				end
			end
			if TheWorld.ismastersim then
				for k, v in pairs(inst.deathmatch) do
					if UserOnline(clienttbl, k) then
						local datatable = GetNetDMDataTable(k)
						if datatable == nil then
							inst:FillNextEmptyDataSlot(k)
							datatable = GetNetDMDataTable(k)
						end
						if datatable ~= nil then
							--SetDirty(datatable.userid, k)
							--SetDirty(datatable.kills, v.kills_local)
							datatable.kills:set(v.kills_local)
							--v.deaths:set(v.deaths_local)
							--SetDirty(datatable.team, v.team_local)
							datatable.team:set(v.team_local)
						end
					end
				end
			else
				for k, v in pairs(inst.deathmatch) do
					local datatable = GetNetDMDataTable(k)
					if datatable == nil then
						inst:FillNextEmptyDataSlot(k)
						datatable = GetNetDMDataTable(k)
					end
					if datatable ~= nil then
						v.kills_local = datatable.kills:value()
						--v.deaths_local = v.deaths:value()
						v.team_local = datatable.team:value()
						-- make all values dirty
						datatable.kills:set_local(v.kills_local)
						--v.deaths:set_local(v.deaths_local)
						datatable.team:set_local(v.team_local)
					end
				end
			end
		end)
	--end
	
	inst:ListenForEvent("deathmatch_timercurrentchange", function(inst, val)
		SetDirty(inst.deathmatch_netvars.globalvars.timercurrent, val)
	end)
	inst:ListenForEvent("deathmatch_timertimechange", function(inst, val)
		SetDirty(inst.deathmatch_netvars.globalvars.timertime, val)
	end)
	inst:ListenForEvent("deathmatch_matchstatuschange", function(inst, val)
		SetDirty(inst.deathmatch_netvars.globalvars.matchstatus, val)
	end)
	inst:ListenForEvent("deathmatch_matchmodechange", function(inst, val)
		SetDirty(inst.deathmatch_netvars.globalvars.matchmode, val)
	end)
	inst:ListenForEvent("deathmatch_arenachange", function(inst, val)
		SetDirty(inst.deathmatch_netvars.globalvars.arena, val)
	end)
	inst:ListenForEvent("deathmatch_timercurrentdirty", function(inst)
		inst.components.deathmatch_timer.timer_current = inst.deathmatch_netvars.globalvars.timercurrent:value()
	end)
	local function refreshdmstatuswidget()
		if ThePlayer and ThePlayer.HUD then
			ThePlayer.HUD.controls.deathmatch_status:Refresh()
		end
	end
	inst:ListenForEvent("deathmatch_timertimedirty", refreshdmstatuswidget)
	inst:ListenForEvent("deathmatch_matchmodedirty", refreshdmstatuswidget)
	inst:ListenForEvent("deathmatch_matchstatusdirty", refreshdmstatuswidget)
	inst:ListenForEvent("deathmatch_arenadirty", refreshdmstatuswidget)
	inst:DoPeriodicTask(3, function() inst:PushEvent("deathmatchdatadirty") end)
	inst:ListenForEvent("deathmatch_killsdirty", function(inst) inst:PushEvent("deathmatchdatadirty") end)
	--inst:ListenForEvent("deathmatch_deathsdirty", function(inst) inst:PushEvent("deathmatchdatadirty") end)
	inst:ListenForEvent("deathmatch_teamdirty", function(inst) inst:PushEvent("deathmatchdatadirty") end)
	
    return inst
end

return Prefab("deathmatch_network", fn), Prefab("deathmatch_network_playerdata", playerdatafn)

