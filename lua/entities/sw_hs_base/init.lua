--[[-------------------------------------------------------------------------
  lua\entities\sw_he_base_entity\init.lua
  SERVER
  Base entity for all hackable devices in the framework
---------------------------------------------------------------------------]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("ZKS.SWHS.StartHack")

-----------------------------------------------------------------------------
-- Called when the entity is initialized on the server
-- @return nil
-----------------------------------------------------------------------------
function ENT:Initialize()
    self:SetModel("models/ace/sw/rh/cgi_console_08.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    self:SetState(0) -- Set initial state to Idle
    self:SetStage(0) -- Set initial stage to Not started
    self:SetDetectionLevel(math.random(0, 5)) -- Set initial detection level
    self:SetSignalStability(math.random(90, 100)) -- Set initial signal stability
end

-----------------------------------------------------------------------------
-- Called when a player uses the entity
-- @param activator Player The player who used the entity
-- @param caller Entity The entity that triggered the use
-- @return nil
-----------------------------------------------------------------------------
function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if not IsValid(self) then return end
    if not IsFirstTimePredicted() then return end

    -- Start hack attempt
    self:StartHack(activator)
end

-----------------------------------------------------------------------------
-- Starts the hacking process
-- @param ply Player The player starting the hack
-- @return nil
-----------------------------------------------------------------------------
function ENT:StartHack(ply)
    if not IsValid(ply) then return end
    if self:GetState() ~= 0 then return end -- Only allow hacking if currently idle
    self:SetState(1) -- Set to hacking state
    self:SetStage(0) -- Set to first stage: Establish Uplink

    hook.Run("ZKS.SWHS.OnHackStarted", self, ply)

    net.Start("ZKS.SWHS.StartHack")
    net.WriteEntity(self)
    net.Send(ply)
end