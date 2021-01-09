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
		name = "Atrium",
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
		--
		CONFIGS = {
			fadeheight = 5,
			lighting = {0.3,0.3,0.3},
			cctable = { ["true"]=resolvefilepath("images/colour_cubes/ruins_light_cc.tex"), ["false"]=resolvefilepath("images/colour_cubes/ruins_dark_cc.tex") },
			ccphasefn = { blendtime = 2, events = { "atriumactivechanged" },fn = function() return tostring(TheWorld.state.atrium_active) end},
			music = "dontstarve/music/music_epicfight_stalker", 
			waves = false,
		},
	},
	
	desert = {
		name = "Desert",
		--
		spawnradius = 16,
		--
		CONFIGS = {
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "summer_day_cc",
			music = "dontstarve_DLC001/music/music_epicfight_summer",
			waves = true,
		},
	},
	
	pigvillage = {
		name = "Pig Village",
		--
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
	
	spring = {
		name = "Spring Island",
		--
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
	
	malbatross = {
		name = "The Shoal",
		--
		spawnradius = 16,
		min_pickup_dist = 0,
		max_pickup_dist = 3.5,
		--
		CONFIGS = {
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "day05_cc",
			waves = true,
			music = "saltydog/music/malbatross",
			has_ocean = true,
			oceancolor = {TUNING.OCEAN_SHADER.OCEAN_FLOOR_COLOR[1] / 255, TUNING.OCEAN_SHADER.OCEAN_FLOOR_COLOR[2] / 255, TUNING.OCEAN_SHADER.OCEAN_FLOOR_COLOR[3] / 255, TUNING.OCEAN_SHADER.OCEAN_FLOOR_COLOR[4] / 255}
		},
	},
	
	grotto = {
		name = "Lunar Grotto",
		--
		spawnradius = 20,
		min_pickup_dist = 5,
		max_pickup_dist = 10,
		overridepickups = {
			"deathmatch_bugnet",
		},
		--
		CONFIGS = {
			fadeheight = 5,
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "caves_default", --lunacy_regular_cc
			waves = false,
			music = "dontstarve/music/music_danger_cave",
		}
	}
}

local ARENA_IDX = {
	["random"] = 0,
	["atrium"] = 1,
	["desert"] = 2,
	["pigvillage"] = 3,
	["spring"] = 4,
}

return ARENA_DEFS

	--[[when adding new arenas, make sure to update:
	this file
	dm world
	dm manager
	dm status
	vote options
	
	TODO: just make a fucking global table elec please
	]]
