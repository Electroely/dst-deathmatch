local inc = 0

local function atriumkeychanged(inst)
	local self = TheWorld.components.deathmatch_manager
	self.enablepickups = TheWorld.state.atrium_active
end

local fullmoonfn = function(inst)
	inc = inc + 1
	if inc == 2 then
		inst:PushEvent("fakefullmoon", true)
		for k, v in pairs(Ents) do 
			if v.prefab == "pigman" then
				v:DoTaskInTime(math.random(), function() v.components.werebeast:SetWere(30) end)
			end
		end
	elseif inc == 3 then
		inc = 0
		inst:PushEvent("fakefullmoon", false)
		for k, v in pairs(Ents) do 
			if v.prefab == "moonpig" then
				v:DoTaskInTime(math.random(), function() v.components.werebeast:SetNormal() end)
			end
		end
	end
end

local ARENAS = {
	CONFIGS = {
		lobby = {
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "day05_cc",
			waves = true,
			music = "dontstarve/music/gramaphone_ragtime",
		},
		atrium = {
			--
			lighting = {0.1,0.1,0.1},
			cctable = { ["true"]=resolvefilepath("images/colour_cubes/ruins_light_cc.tex"), ["false"]=resolvefilepath("images/colour_cubes/ruins_dark_cc.tex") },
			ccphasefn = { blendtime = 2, events = { "atriumactivechanged" },fn = function() return tostring(TheWorld.state.atrium_active) end},
			music = "dontstarve/music/music_epicfight_stalker",
			waves = false,
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
			--
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "summer_day_cc",
			music = "dontstarve_DLC001/music/music_epicfight_summer",
			waves = true,
			--
			spawnradius = 16,
		},
		spring = {
			--
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "spring_day_cc",
			music = "dontstarve_DLC001/music/music_epicfight_spring",
			waves = true,
			--
			spawnradius = 16,
			nopickups = true,
		},
		pigvillage = {
			--
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "day05_cc",
			music = "dontstarve/music/music_pigking_minigame",
			waves = true,
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
			specific = true,
			colourcube = "purple_moon_cc",
			lighting = {84 / 255, 122 / 255, 156 / 255},
		},
		cave = {
			colourcube = "sinkhole_cc",
			lighting = {0.1,0.1,0.1},
			music = "",
			waves = false,
		},
		ocean = {
			--
			colourcube = "day05_cc",
			lighting = {200 / 255, 200 / 255, 200 / 255},
			music = "saltydog/music/malbatross",
			waves = true,
			wave_texture = "images/wave_shadow.tex",
			ocean = true,
			--
			extraitems = { "oar" },
			spawnradius = 20.5,
			nopickups = true,
			
			matchendfn = function()
				
			end,
		},
	},

	IDX = {
		["random"] = 0,
		["atrium"] = 1,
		["desert"] = 2,
		["pigvillage"] = 3,
		["spring"] = 4,
		["ocean"] = 5,
	},

	NAMES = {
		"Random",
		"Atrium",
		"Desert",
		"Pig Village",
		"Spring Island",
		"Ocean",
	},

	VOTEOPTIONS = { 
		[1] = "atrium", 
		[2] = "desert", 
		[3] = "pigvillage",
		[4] = "ocean",
		[5] = "random",
		--
		atrium = "atrium",
		desert = "desert",
		pigvillage = "pigvillage",
		spring = "spring",
		ocean = "ocean",
		random = "random",
	},
}

return ARENAS