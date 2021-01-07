local function lobby_postinit(inst)
	inst.onfar = nil
	if TheWorld.ismastersim then
		TheWorld.lobbypoint = inst
	end
end

local function pigvillage_postinit(inst)
	TheWorld:ListenForEvent("fakefullmoon", function(wrld, shouldpush)
		if shouldpush then
			inst.presetname = "pigvillage_fm"
		else
			inst.presetname = "pigvillage"
		end
		for k, v in pairs(inst.players_inside) do
			inst:onnear(k)
		end
	end)
end

---------------------------------------------------

local ARENA_DEFS = {
	lobby = {
		postinit = lobby_postinit,
		--
		CONFIGS = {
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "day05_cc",
			waves = true,
			music = "dontstarve/music/gramaphone_ragtime",
		},
	},
	
	atrium = {
		spawnradius = 20.5,
		matchstartfn = function()
			local self = TheWorld.components.deathmatch_manager
			if self.atrium_gate == nil then
				for k, v in pairs(Ents) do
					if v.prefab == "atrium_gate" then self.atrium_gate = v end
				end
			end
			if self.atrium_gate.components.trader.enabled then
				self.atrium_gate.components.trader.onaccept(self.atrium_gate)
			end
			self.inst:ListenForEvent("atriumactivechanged", atriumkeychanged)
		end,
		matchendfn = function()
			local self = TheWorld.components.deathmatch_manager
			for k, v in pairs(Ents) do
				if v.prefab == "atrium_key" then
					v:Remove()
				end
			end
			self.inst:RemoveEventCallback("atriumactivechanged", atriumkeychanged)
		end,
		--
		CONFIGS = {
			lighting = {0.1,0.1,0.1},
			cctable = { ["true"]=resolvefilepath("images/colour_cubes/ruins_light_cc.tex"), ["false"]=resolvefilepath("images/colour_cubes/ruins_dark_cc.tex") },
			ccphasefn = { blendtime = 2, events = { "atriumactivechanged" },fn = function() return tostring(TheWorld.state.atrium_active) end},
			music = "dontstarve/music/music_epicfight_stalker", 
			waves = false,
		},
	},
	
	desert = {
		spawnradius = 16,
		--
		CONFIGS = {
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "summer_day_cc",
			music = "dontstarve_DLC001/music/music_epicfight_summer",
			waves = true,
		},
	},
	
	spring = {
		spawnradius = 16,
		nopickups = true,
		--
		CONFIGS = {
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "spring_day_cc",
			music = "dontstarve_DLC001/music/music_epicfight_spring",
			waves = true,
		},
	},
	
	cave = {
		CONFIGS = {
			colourcube = "sinkhole_cc",
			lighting = {0.1,0.1,0.1},
			music = "",
			waves = false,
		},
	},
	
	pigvillage = {
		postinit = pigvillage_postinit,
		--
		spawnradius = 12,
		nopickups = true,
		matchstartfn = function()
			TheWorld:PushEvent("fakefullmoon", false)
			local self = TheWorld.components.deathmatch_manager
			if self._fullmoontask ~= nil then
				self._fullmoontask:Cancel()
				self._fullmoontask = nil
			end
			if self.glommer == nil or self.glommer.components.health:IsDead() then
				self.glommer = SpawnPrefab("glommer")
				local x, _, z = self.inst.centerpoint:GetPosition():Get()
				self.glommer.Transform:SetPosition(x, 10, z)
			end
			self._fullmoontask = self.inst:DoPeriodicTask(30, fullmoonfn)
		end,
		matchendfn = function()
			local self = TheWorld.components.deathmatch_manager
			if self._fullmoontask ~= nil then
				self._fullmoontask:Cancel()
				self._fullmoontask = nil
			end
			if self.glommer ~= nil and not self.glommer.components.health:IsDead() then
				self.glommer.components.health:Kill()
			end
			inc = -1
			fullmoonfn(self.inst)
		end,
		CONFIGS = {
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "day05_cc",
			music = "dontstarve/music/music_pigking_minigame",
			waves = true,
		}
	},
}

local ARENA_IDX = {
	["random"] = 0,
}

--[[
for k, v in pairs(ARENA_DEFS) do
	table.insert(ARENA_IDX, [v] = #ARENA_IDX + 1)
end
]]

return ARENA_DEFS

	--[[when adding new arenas, make sure to update:
	this file
	dm world
	dm manager
	dm status
	vote options
	
	TODO: just make a fucking global table elec please
	]]
