local assets =
{
    Asset("ANIM", "anim/sign_home.zip"),
    Asset("ANIM", "anim/ui_board_5x3.zip"),
    Asset("MINIMAP_IMAGE", "sign"),
}

local prefabs =
{
    "collapse_small",
}

local infolists = {
	general = {
		"Welcome to Deathmatch! [...]",
		"Fight to the death with other players in this server. [...]",
		"Use CTRL + F to attack, and the right mouse button to\nuse your weapon's ability. [...]",
		"All characters have 150 HP. No character has perks. [...]",
		"You can vote with other players to change certain things by\npressing the 3 dots button in the TAB player list. [...]",
		"To start a match, type /dm start. [...]",
		"To spectate on the current match (or next if there isn't one), type /spectate. [...]",
		"To change your team in the \"custom teams\" mode, use /setteam color. [...]",
		"We hope you enjoy your stay!"
	}
}

local function fn()
	local inst = require("prefabs/homesign").fn()
	inst.prefab = "deathmatch_infosign"
	inst:RemoveTag("_writeable")
	inst:RemoveTag("writeable")
	
	if not TheWorld.ismastersim then
		return inst
	end
	inst:RemoveComponent("writeable")
	inst.AnimState:Show("WRITING")
	inst.inspectors = {}
	inst.infolist = "general"
	inst:AddTag("event_inspect")
	inst:ListenForEvent("inspected", function(inst, doer)
		if inst.inspectors[doer] == nil or inst.inspectors[doer] >= #infolists[inst.infolist] then
			inst.inspectors[doer] = 1
		else
			inst.inspectors[doer] = inst.inspectors[doer] + 1
		end
	end)
	
	inst.components.inspectable.getspecialdescription = nil
	inst.components.inspectable.descriptionfn = function(inst, doer)
		if inst.inspectors[doer] == nil then
			inst:PushEvent("inspected", doer)
		end
		return infolists[inst.infolist][inst.inspectors[doer]]
	end
	return inst
end

return Prefab("deathmatch_infosign", fn, assets, prefabs)