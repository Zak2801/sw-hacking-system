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
local ourMat = Material( "phoenix_storms/wire/pcb_green" )

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

    -- Store the initial camera position and angles for the lerp transition.
    local ply = LocalPlayer()
    g_StartPos = ply:EyePos()
    g_StartAngles = ply:EyeAngles()

    -- Restore player movement by removing the hook.
    hook.Remove("CreateMove", "ZKS.SWHS.FreezePlayer")

    print("[ZKS.SWHS] Hack started on entity: " .. tostring(ent))

    -----------------------------------------------------------------------------
    -- @name ZKS.SWHS.FreezePlayer
    -- @hook CreateMove
    -- @brief Prevents the player from moving or using items while hacking.
    -----------------------------------------------------------------------------
    hook.Add("CreateMove", "ZKS.SWHS.FreezePlayer", function(cmd)
        if not g_IsHacking then return end

        -- Block movement and actions.
        cmd:ClearMovement()
        cmd:RemoveKey(IN_ATTACK)
        cmd:RemoveKey(IN_ATTACK2)
    end)
end)

--===========================================================================--
--      Hooks
--===========================================================================--

-----------------------------------------------------------------------------
-- @name ZKS.SWHS.HackingView
-- @hook CalcView
-- @brief Overrides the player's camera to create the hacking view.
--        Lerps the camera from its original position to a target position
--        above the hacked entity.
-- @param ply Player The local player.
-- @param pos Vector The original view position.
-- @param angles Angle The original view angles.
-- @param fov number The original field of view.
-- @return table A view table to override the camera.
-----------------------------------------------------------------------------
hook.Add("CalcView", "ZKS.SWHS.HackingView", function(ply, pos, angles, fov)
    if not g_IsHacking or not IsValid(g_HackingEnt) then return end

    local frac = (CurTime() - g_HackStartTime) / g_LerpDuration
    frac = math.Clamp(frac, 0, 1)

    -- Define the camera's destination
    local targetPos = g_HackingEnt:GetPos() + Vector(0, 0, 110) + g_HackingEnt:GetForward() * 70
    local targetAngles = ply:EyeAngles()

    -- Interpolate camera position and angles
    local view = {}
    view.origin = LerpVector(frac, g_StartPos, targetPos)
    view.angles = LerpAngle(frac, g_StartAngles, targetAngles)
    view.fov = fov

    return view
end)

-----------------------------------------------------------------------------
-- @name ZKS.SWHS.HideViewModel
-- @hook PreDrawViewModel
-- @brief Prevents the player's viewmodel from being drawn while hacking.
-----------------------------------------------------------------------------
hook.Add("PreDrawViewModel", "ZKS.SWHS.HideViewModel", function(vm, weapon, ply)
    if g_IsHacking then
        return true -- returning true prevents the viewmodel from drawing
    end
end)

-----------------------------------------------------------------------------
-- @name ZKS.SWHS.HideHands
-- @hook PreDrawPlayerHands
-- @brief Prevents the player's hands from being drawn while hacking.
-----------------------------------------------------------------------------
hook.Add("PreDrawPlayerHands", "ZKS.SWHS.HideHands", function(hands, vm, ply)
    if g_IsHacking then
        return true
    end
end)


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

    -- Restore player movement by removing the hook.
    hook.Remove("CreateMove", "ZKS.SWHS.FreezePlayer")

    -- Reset the player's view angles when exiting the hack.
    local ply = LocalPlayer()
    if IsValid(ply) and g_StartAngles then
        ply:SetEyeAngles(g_StartAngles)
    end
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
    ZKsSWHS.UI = ZKsSWHS.UI or {}
    ZKsSWHS.UI.EntryPoint(self)
end

