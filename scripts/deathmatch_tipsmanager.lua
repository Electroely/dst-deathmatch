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


AddPrefabPostInit("player_classified", function(inst)

	inst._deathmatch_tipid = G.net_ushortint(inst.GUID, "deathmatch.tipid", "deathmatch_tipiddirty")
	
	inst:ListenForEvent("deathmatch_tipiddirty", function(inst) --clientside
		if inst._parent then
			inst._parent:PushEvent("deathmatchpopupreceived", TIP_IDS[inst._deathmatch_tipid:value()])
		end
	end)
	
end)

local function PushDeathmatchTip(player, name, force) --todo
	if player.player_classified == nil then return end
	SetDirty(player.player_classified._deathmatch_tipid, GetIdByName(name))
	if not G.TheNet:IsDedicated() and player == G.ThePlayer then
		player.player_classified:PushEvent("deathmatch_tipiddirty")
	end
end

--these'll be defined later
local onItemGet
local onAttacked

AddPlayerPostInit(function(inst) 
	if not G.TheWorld.ismastersim or not G.TheNet:IsDedicated() then
		inst:ListenForEvent("deathmatchpopupreceived", function(inst, data)
			if inst.HUD == nil then return end
			--TODO: manage multiple tips
			if inst.HUD.deathmatch_tip then
				inst.HUD.deathmatch_tip:Kill()
			end
			inst.HUD.deathmatch_tip = inst.HUD:AddChild(DeathmatchTipPopupWidget(data))
			inst.HUD.deathmatch_tip:SetPosition(200,400)
		end)
		
	end
	if not G.TheWorld.ismastersim then return end
	inst:ListenForEvent("pushdeathmatchtip", function(inst, data)
		PushDeathmatchTip(inst, data)
	end)
	
	----------- everything beyond this point should be activation code
	return --keep this here for testing the above code first
	
	--inst:ListenForEvent("itemget", onItemGet)
end)

function onItemGet(inst, data)
	local item = data.item
	if item == nil then return end
	if item.prefab == "lavaarena_firebomb" then
		inst:PushEvent("pushdeathmatchtip", "FIREBOMBEXPLAIN")
	elseif item.prefab == "deathmatch_reviverheart" then
		inst:PushEvent("pushdeathmatchtip", "REVIVERHEARTEXPLAIN")
	end
end
