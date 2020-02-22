local ARENAS = {
	lobby = {
		arena_effects = {
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "day05_cc",
			waves = true,
			music = "dontstarve/music/gramaphone_ragtime",
		},
	},
	atrium = {
		arena_effects = {
			lighting = {0.1,0.1,0.1},
			cctable = { ["true"]=resolvefilepath("images/colour_cubes/ruins_light_cc.tex"), ["false"]=resolvefilepath("images/colour_cubes/ruins_dark_cc.tex") },
			ccphasefn = { blendtime = 2, events = { "atriumactivechanged" },fn = function() return tostring(TheWorld.state.atrium_active) end},
			music = "dontstarve/music/music_epicfight_stalker",
			waves = false,
		},
		--
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
	},
	desert = {
		arena_effects = {
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "summer_day_cc",
			music = "dontstarve_DLC001/music/music_epicfight_summer",
			waves = true,
		},
		--
		spawnradius = 16,
	},
	spring = {
		arena_effects = {
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "spring_day_cc",
			music = "dontstarve_DLC001/music/music_epicfight_spring",
			waves = true,
		}
		--
		spawnradius = 16,
		nopickups = true,
	},
	pigvillage = {
		arena_effects = {
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "day05_cc",
			music = "dontstarve/music/music_pigking_minigame",
			waves = true,
		},
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
	},
	pigvillage_fm = {
		arena_effects = {
			specific = true,
			colourcube = "purple_moon_cc",
			lighting = {84 / 255, 122 / 255, 156 / 255},
		},
	},
	cave = {
		arena_effects = {
			colourcube = "sinkhole_cc",
			lighting = {0.1,0.1,0.1},
			music = "",
			waves = false,
		},
	},
	ocean = {
		arena_effects = {
			colourcube = "day05_cc",
			lighting = {200 / 255, 200 / 255, 200 / 255},
			music = "saltydog/music/malbatross",
			waves = true,
			wave_texture = "images/wave_shadow.tex",
			ocean = true,
		}
		--
		extraitems = { "oar" },
		spawnradius = 20.5,
		nopickups = true,
	},
}

local ARENA_IDX = {
	["random"] = 0,
	["atrium"] = 1,
	["desert"] = 2,
	["pigvillage"] = 3,
	["spring"] = 4,
	["ocean"] = 5,
}

return ARENAS, ARENA_IDX