require("reload")
list = nil
function CreatePlayerList()
	if list ~= nil then
		list:Kill()
	end
	DoReload()
	list = ThePlayer.HUD.controls.bottom_root:AddChild(require("widgets/deathmatch_enemylist")(ThePlayer))
	list:SetPosition(-220, 70)
end

menu = nil
function CreateMenu()
	if menu ~= nil then
		menu:Kill()
	end
	DoReload()
	menu = ThePlayer.HUD.controls.topright_root:AddChild(require("widgets/deathmatch_matchcontrols")(ThePlayer))
	menu:SetPosition(-220, -70)
end