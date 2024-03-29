require("reload")

arrows = nil
function CreateAllyArrows()
	if arrows ~= nil then
		arrows:Kill()
	end
	DoReload()
	arrows = ThePlayer.HUD:AddChild(require("widgets/deathmatch_allyindicator")(ThePlayer))
end
