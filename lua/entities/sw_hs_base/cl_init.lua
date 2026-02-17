--[[-------------------------------------------------------------------------
  lua\entities\sw_hs_base\cl_init.lua
  CLIENT
  Client-side logic for the base hackable entity.
  Handles camera, player input, and 3D2D UI rendering during a hack.
---------------------------------------------------------------------------]]

include("shared.lua")

-- Ensure the main table exists
ZKsSWHS = ZKsSWHS or {}
ZKsSWHS.UI = ZKsSWHS.UI or {}

--===========================================================================--
--      Local Variables
--===========================================================================--

local g_HackingEnt = nil -- The entity currently being hacked.
local g_IsHacking = false -- Is the player currently in the hacking view?
local g_HackStartTime = 0 -- The time when the hack started (used for lerping).
local g_LerpDuration = 1.0 -- How long the camera transition should take in seconds.
local g_StartPos = Vector(0, 0, 0) -- The initial camera position when hacking starts.
local g_StartAngles = Angle(0, 0, 0) -- The initial camera angles when hacking starts.

--===========================================================================--
--      Networking
--===========================================================================--

-----------------------------------------------------------------------------
-- Receives the signal from the server to initiate the hacking sequence.
-- @param len number The length of the net message.
-----------------------------------------------------------------------------
net.Receive("ZKS.SWHS.StartHack", function(len)
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end

    g_HackingEnt = ent
    g_IsHacking = true
    g_HackStartTime = CurTime()
    ZKsSWHS.UI.HackStartTime = g_HackStartTime

    -- Store the initial camera position and angles for the lerp transition.
    local ply = LocalPlayer()
    g_StartPos = ply:EyePos()
    g_StartAngles = ply:EyeAngles()

    print("[ZKS.SWHS] Hack started on entity: " .. tostring(ent))
end)

--===========================================================================--
--      Hooks
--===========================================================================--


-----------------------------------------------------------------------------
-- @name ZKS.SWHS.HackingClose
-- @hook Think
-- @brief Checks for the condition to end the hacking sequence (pressing 'R').
-----------------------------------------------------------------------------
local function EndHack()
    if not g_IsHacking then return end

    if IsValid(g_HackingEnt) then
        print("[ZKS.SWHS] Hack ended on entity: " .. tostring(g_HackingEnt))
    end
    
    g_IsHacking = false
    g_HackingEnt = nil
    ZKsSWHS.UI.HackStartTime = nil
    ZKsSWHS.UI.CurrentStage = -1
end

-----------------------------------------------------------------------------
-- @name ZKS.SWHS.HackingThink
-- @hook Think
-- @brief Monitors for conditions to end the hacking sequence.
-----------------------------------------------------------------------------
hook.Add("Think", "ZKS.SWHS.HackingThink", function()
    if not g_IsHacking then return end

    -- Condition 1: Entity is no longer valid
    if not IsValid(g_HackingEnt) then
        print("[ZKS.SWHS] Hacked entity is no longer valid. Ending hack.")
        EndHack()
        return
    end

    -- Condition 2: Player aborts with 'R' key
    if input.IsKeyDown(KEY_R) then
        print("[ZKS.SWHS] Player aborted hack.")
        -- Tell server we aborted so it can reset the state
        net.Start("ZKS.SWHS.AbortHack")
        net.WriteEntity(g_HackingEnt)
        net.SendToServer()
        EndHack()
        return
    end

    -- Condition 3: Server has changed the state away from 'Hacking'
    if g_HackingEnt:GetState() ~= 1 then
        print("[ZKS.SWHS] Entity state is no longer 'Hacking' (is " .. g_HackingEnt:GetState() .. "). Ending hack.")
        EndHack()
        return
    end
end)


-----------------------------------------------------------------------------
-- Called when the entity is initialized on the client.
-- @return nil
-----------------------------------------------------------------------------
function ENT:Initialize()
    -- Nothing to do here currently.
end

-----------------------------------------------------------------------------
-- Called when the entity is drawn on the client.
-- This function handles drawing the 3D2D user interface.
-- @param flags number Render flags.
-- @return nil
-----------------------------------------------------------------------------
function ENT:DrawTranslucent(flags)
    self:Draw(flags)
    if not g_IsHacking then return end
    if g_HackingEnt ~= self then return end

    ZKsSWHS.UI = ZKsSWHS.UI or {}
    ZKsSWHS.UI.EntryPoint(self)
end

