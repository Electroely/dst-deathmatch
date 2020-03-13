local G = GLOBAL
local require = G.require
local DeathmatchTipPopupWidget = require("widgets/deathmatch_tippopup")

--[[
	clients should only get auto tips once. /dm help should show all tips
	in case they want to read them again.
	we can use a persistent string to save whether a tip has been viewed or
	not.
	
	maybe each tip can get a numerical ID so that comunication about which
	to show or which ones have been viewed can happen through a number netvar
	
	do we want to generate a list of ids automatically or just manually list in?
]]
local function SetDirty(netvar, val)
	netvar:set_local(val)
	netvar:set(val)
end
-- sort alphabetically
local TIP_IDS = {}
for k, v in pairs(G.DEATHMATCH_STRINGS.POPUPS) do
	local pos = 1
	for i, v2 in ipairs(TIP_IDS) do
		if k <= v2 then
			pos = i
			break
		else
			pos = pos + 1
		end
	end
	table.insert(TIP_IDS, pos, k)
end
local function GetIdByName(name)
	for k, v in pairs(TIP_IDS) do
		if v == name then return k end
	end
	G.assert(false, "tried to find a nonregistered tip "..name)
end

local player_userid = { --Hornet: We store the info here on wether or not the player has already gotten that tip

}

AddPrefabPostInit("player_classified", function(inst)

	inst._deathmatch_tipid = G.net_ushortint(inst.GUID, "deathmatch.tipid", "deathmatch_tipiddirty")
	
	inst:ListenForEvent("deathmatch_tipiddirty", function(inst) --clientside
		if inst._parent then
			inst._parent:PushEvent("deathmatchpopupreceived", TIP_IDS[inst._deathmatch_tipid:value()])
		end
	end)
end)

AddPlayerPostInit(function(inst) 
	if not G.TheWorld.ismastersim then
		inst:ListenForEvent("deathmatchpopupreceived", function(inst, data)
			if inst.HUD == nil then return end
			--TODO: manage multiple tipes
			if inst.HUD.deathmatch_tip then
				inst.HUD.deathmatch_tip:Kill()
			end
			inst.HUD.deathmatch_tip = inst.HUD:AddChild(DeathmatchTipPopupWidget(data))
			inst.HUD.deathmatch_tip:MoveTo({x = 1600, y = 300, z = 0}, {x = 1200 , y = 300, z = 0}, 0.7, nil)
		end)
	else
		inst:ListenForEvent("pushdeathmatchtip", function(inst, data)			
			if inst.player_classified == nil then return end
			SetDirty(inst.player_classified._deathmatch_tipid, GetIdByName(data))
		end)
	end
end)
