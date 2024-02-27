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

local function moonisland_activatefissure(fissure)
	fissure.level = 5
	fissure:UpdateState(0.5)
end
local function moonisland_deactivatefissure(fissure)
	fissure.level = 1
	fissure:UpdateState(0.5)
end
local function moonisland_changefissure()
	local self = TheWorld.components.deathmatch_manager
	moonisland_deactivatefissure(self.moonisland_fissures[self.current_fissure])
	local new_fissures = {}
	for k, v in pairs(self.moonisland_fissures) do
		if k ~= self.current_fissure then
			table.insert(new_fissures, k)
		end
	end
	self.current_fissure = new_fissures[math.random(#new_fissures)]
	moonisland_activatefissure(self.moonisland_fissures[self.current_fissure])
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
		name = DEATHMATCH_STRINGS.ARENA_ATRIUM,
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
		name = DEATHMATCH_STRINGS.ARENA_DESERT,
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
		name = DEATHMATCH_STRINGS.ARENA_PIGVILLAGE,
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
	
	moonisland = {
		name = DEATHMATCH_STRINGS.ARENA_MOONISLAND,
		--
		spawnradius = 16,
		min_pickup_dist = 0,
		max_pickup_dist = 3.5,
		custom_spawnpoint = function()
			local self = TheWorld.components.deathmatch_manager
			if self.current_fissure then
				return self.moonisland_fissures[self.current_fissure]:GetPosition()
			end
		end,
		matchstartfn = function()
			local self = TheWorld.components.deathmatch_manager
			if self.moonisland_fissures == nil then
				self.moonisland_fissures = {}
				local pos = self.inst.centerpoint:GetPosition()
				self.moonisland_fissures = TheSim:FindEntities(pos.x, pos.y, pos.z, 30, {"deathmatch_fissure"})
			end
			local closestdist = 30*30
			local closest = nil
			for i = 1, #self.moonisland_fissures do
				local fissure = self.moonisland_fissures[i]
				local distsq = self.inst.centerpoint:GetDistanceSqToPoint(fissure.Transform:GetWorldPosition())
				if distsq < closestdist then
					closestdist = distsq
					closest = i
				end
			end
			self.current_fissure = closest
			moonisland_activatefissure(self.moonisland_fissures[self.current_fissure])
		end,
		matchendfn = function()
			local self = TheWorld.components.deathmatch_manager
			moonisland_deactivatefissure(self.moonisland_fissures[self.current_fissure])
		end,
		onpickupspawn = function()
			moonisland_changefissure()
		end,
		--
		CONFIGS = {
			lighting = {200 / 255, 200 / 255, 200 / 255},
			colourcube = "spring_day_cc",
			music = "moonstorm/creatures/boss/alterguardian2/music_epicfight",
			waves = true,
		},
	},
	
	malbatross = {
		name = "The Shoal",
		--
		spawnradius = 16,
		min_pickup_dist = 0,
		max_pickup_dist = 3.5,
		matchstartfn = function()
			local boat = SpawnPrefab("boat")
			boat.Transform:SetPosition(TheWorld.centerpoint.Transform:GetWorldPosition())
			boat.persists = false

			TheWorld:DoTaskInTime(6 + math.random() * 0.75, function()
				local malbatross = SpawnPrefab("malbatross")
				malbatross.Transform:SetPosition(TheWorld.centerpoint.Transform:GetWorldPosition())
				malbatross.sg:GoToState("arrive")
				malbatross.persists = false
			end)
		end,
		matchendfn = function()
			TheWorld:DoTaskInTime(5, function() --TODO, Hornet: we should just make a "delete_prefabs" table for arenas thats used in the manager component
				for k, v in pairs(Ents) do
					if v.prefab == "malbatross_feather" or v.prefab == "boat" or v.prefab == "malbatross" then
						v:Remove()
					end
				end
			end)
		end,
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
	},

	stalker = {
		name = DEATHMATCH_STRINGS.ARENA_STALKER,
		--
		spawnradius = 14,
		--nopowerpickups = true,
		custom_spawnpoint = function()
			local stalker = TheSim:FindFirstEntityWithTag("stalker")
			return stalker and stalker:GetPosition()
		end,
		matchstartfn = function()
			TheWorld.state.isnight = true
			
			local function SpawnStalker(inst)
				local stalker = SpawnPrefab("stalker_forest")
				local x, y, z = inst.Transform:GetWorldPosition()
				local rot = inst.Transform:GetRotation()
				inst:Remove()

				stalker.Transform:SetPosition(x, y, z)
				stalker.Transform:SetRotation(rot)
				stalker.sg:GoToState("resurrect")
				stalker.persists = false
			end
			local fossil = SpawnPrefab("fossil_stalker")
			fossil.Transform:SetPosition(TheWorld.centerpoint.Transform:GetWorldPosition())
			fossil.AnimState:PlayAnimation("1_8")
			fossil:DoTaskInTime(15 + math.random() * 0.75, SpawnStalker)
			fossil.persists = false
		end,
		matchendfn = function()
			TheWorld.state.isnight = false
			for k, v in pairs(Ents) do
				if v.prefab == "stalker_forest" then
					v.components.health:Kill()
				end
			end
			TheWorld:DoTaskInTime(5, function()
				for k, v in pairs(Ents) do
					if v.prefab == "fossil_piece" or v.prefab == "shadowheart" then
						v:Remove()
					end
				end
			end)
		end,
		--
		CONFIGS = {
			lighting = {0, 0, 0},
			colourcube = "night03_cc",
			music = "dontstarve/music/music_epicfight",
		}
	},

	random = {
		name = DEATHMATCH_STRINGS.ARENA_RANDOM,
	}
}

local ARENA_IDX = {
	"atrium",
	"desert",
	"moonisland",
	"stalker",
	"pigvillage",
	"malbatross",
	"grotto",
	
}

ARENA_IDX[0] = "random"

local ARENA_IDX_LOOKUP = {}

for k, v in pairs(ARENA_IDX) do
	ARENA_IDX_LOOKUP[v] = k
end

local VALID_ARENA_LIST = {
	"atrium",
	"desert",
	"moonisland",
	"stalker",
	"pigvillage",
}

local VALID_ARENA_LOOKUP = {}

for k, v in pairs(VALID_ARENA_LIST) do
	VALID_ARENA_LOOKUP[ARENA_IDX_LOOKUP[v]] = true
end

return {
	CONFIGS = ARENA_DEFS,
	IDX = ARENA_IDX,
	IDX_LOOKUP = ARENA_IDX_LOOKUP,
	VALID_ARENAS = VALID_ARENA_LIST,
	VALID_ARENA_LOOKUP = VALID_ARENA_LOOKUP,
}

	--[[when adding new arenas, make sure to update:
	this file
	dm world
	dm manager
	dm status
	vote options
	
	TODO: just make a fucking global table elec please
	]]
