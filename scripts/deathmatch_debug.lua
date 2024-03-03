require("reload")
local DeathmatchMenu = require "widgets/deathmatch_menu"

buffs = nil
function CreateBuffIcons()
	if buffs ~= nil then
		buffs:Kill()
	end
	DoReload()
	buffs = ThePlayer.HUD.controls.status:AddChild(require("widgets/deathmatch_bufficons")(ThePlayer))
	--buffs:SetPosition(-220, 70)
end
