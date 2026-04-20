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
    self.CurrentHacker = ply

    hook.Run("ZKS.SWHS.OnHackStarted", self, ply)

    net.Start("ZKS.SWHS.StartHack")
    net.WriteEntity(self)
    net.Send(ply)
end

-----------------------------------------------------------------------------
-- Resets the entity state
-----------------------------------------------------------------------------
function ENT:ResetHack()
    self:SetState(0)
    self:SetStage(0)
    self:SetDetectionLevel(math.random(0, 5))
    self:SetSignalStability(math.random(90, 100))
    self.CurrentHacker = nil
end

-----------------------------------------------------------------------------
-- Think hook for handling consequences
-----------------------------------------------------------------------------
function ENT:Think()
    if self:GetState() ~= 1 then return end
    if not IsValid(self.CurrentHacker) then 
        self:ResetHack()
        return 
    end

    local detection = self:GetDetectionLevel()
    local signal = self:GetSignalStability()

    -- 1. Signal Stability Reset (< 10%)
    if signal < 10 then
        self:ResetHack()
        -- You might want to play a sound or net message here for "CRITICAL FAILURE"
        return
    end

    -- 2. Detection Consequences (NPC Targeting)
    if detection > 50 then
        local searchDist = (detection / 100) * 2000 -- Scaling distance: 1000 to 2000 units
        local entities = ents.FindInSphere(self:GetPos(), searchDist)

        for _, npc in ipairs(entities) do
            if npc:IsNPC() and npc:GetClass() ~= "npc_bullseye" then -- Basic check for NPCs
                local rel = npc:Disposition(self.CurrentHacker)
                if rel == D_HT or rel == D_FR then -- Only hostile/frightened NPCs
                    npc:SetEnemy(self.CurrentHacker)
                    npc:UpdateEnemyMemory(self.CurrentHacker, self.CurrentHacker:GetPos())

                    -- Some NPCs need a schedule to move
                    if npc.SetSchedule then
                        npc:SetSchedule(SCHED_CHASE_ENEMY)
                    end
                end
            end
        end
    end

    self:NextThink(CurTime() + 1) -- Run once a second
    return true
end