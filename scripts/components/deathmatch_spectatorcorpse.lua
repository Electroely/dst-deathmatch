local function ReattachToPlayer()
	local oldtarget = TheFocalPoint.entity:GetParent()
	if oldtarget then
		oldtarget:RemoveEventCallback("onremove", ReattachToPlayer)
	end
	if ThePlayer ~= nil then
		TheFocalPoint.entity:SetParent(ThePlayer.entity)
		if ThePlayer.HUD and ThePlayer.HUD.controls.deathmatch_spectatorspinner and ThePlayer.HUD.controls.deathmatch_spectatorspinner.inst:IsValid() then
			ThePlayer.HUD.controls.deathmatch_spectatorspinner.spinner:SetSelected(ThePlayer)
		end
	else
		TheFocalPoint.entity:SetParent(nil)
	end
end

local function AttachToEntity(target)
	local oldtarget = TheFocalPoint.entity:GetParent()
	if oldtarget then
		oldtarget:RemoveEventCallback("onremove", ReattachToPlayer)
	end
	if target ~= nil then
		TheFocalPoint.entity:SetParent(target.entity)
		target:ListenForEvent("onremove", ReattachToPlayer)
	end
end

local function OnIsSpectatingDirty(inst)
    local self = inst.components.deathmatch_spectatorcorpse
    if self._isspectating:value() then
		self.active = true
		if ThePlayer and ThePlayer.HUD.controls.deathmatch_spectatorspinner ~= nil then
			local ctrls = ThePlayer.HUD.controls
			ctrls.deathmatch_spectatorspinner.spinner:SetSelected(ThePlayer)
			ctrls.deathmatch_spectatorspinner:Show()
		end
    else
		ReattachToPlayer()
		self.active = false
		if ThePlayer and ThePlayer.HUD.controls.deathmatch_spectatorspinner ~= nil then
			local ctrls = ThePlayer.HUD.controls
			ctrls.deathmatch_spectatorspinner.spinner:SetSelected(ThePlayer)
			ctrls.deathmatch_spectatorspinner:Hide()
		end
    end
end

local function OnBecameCorpse(inst, data)
    --if data ~= nil and data.corpse then
	local self = inst.components.deathmatch_spectatorcorpse
	self._isspectating:set(true)
	if self.active then
		OnIsSpectatingDirty(inst)
	end
    --end
end

local function OnRezFromCorpse(inst, data)
    --if data ~= nil and data.corpse then
	local self = inst.components.deathmatch_spectatorcorpse
	self._isspectating:set(inst:HasTag("spectator"))
	if self.active then
		OnIsSpectatingDirty(inst)
	end
    --end
end

local function OnPlayerActivated(inst)
    local self = inst.components.deathmatch_spectatorcorpse
    if not self.active then
        self.active = true
        if not TheNet:IsDedicated() then
            inst:ListenForEvent("deathmatch_isspectatingdirty", OnIsSpectatingDirty)
        end
        OnIsSpectatingDirty(inst)
    end
end

local function OnPlayerDeactivated(inst)
    local self = inst.components.deathmatch_spectatorcorpse
    if self.active then
        self.active = false
        if not TheNet:IsDedicated() then
            inst:RemoveEventCallback("deathmatch_isspectatingdirty", OnIsSpectatingDirty)
        end
    end
end

local SpectatorCorpse_Deathmatch = Class(function(self, inst)
    self.inst = inst
    self.active = false

    --Networking
    self._isspectating = net_bool(inst.GUID, "spectatorcorpse_deathmatch._isspectating", "deathmatch_isspectatingdirty")

    if TheWorld.ismastersim then
        inst:ListenForEvent("ms_becameghost", OnBecameCorpse)
        inst:ListenForEvent("ms_respawnedfromghost", OnRezFromCorpse)
        inst:ListenForEvent("ms_becamespectator", OnBecameCorpse)
        inst:ListenForEvent("ms_exitspectator", OnRezFromCorpse)
    end

    inst:ListenForEvent("playeractivated", OnPlayerActivated)
    inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)
end)

function SpectatorCorpse_Deathmatch:SetTarget(target)
	if target then
		AttachToEntity(target)
	end
end

return SpectatorCorpse_Deathmatch -- deathmatch_spectatorcorpse is component's name
