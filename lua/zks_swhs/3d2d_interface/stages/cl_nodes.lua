--[[-------------------------------------------------------------------------
  lua\zks_swhs\3d2d_interface\stages\cl_nodes.lua
  CLIENT
  Network Routing stage
---------------------------------------------------------------------------]]

local Stages = ZKsSWHS.UI.Stages
local UI = ZKsSWHS.UI

local STAGE = {}
STAGE.ID = 2
STAGE.Name = "Network Routing"

local NODE_TYPES = {
    ACCESS_POINT = 1,
    ROUTING = 2,
    ENCRYPTED = 3,
    VOLATILE = 4,
    SECURITY_RELAY = 5,
    CORE = 6,
}

local NODE_CONFIG = {
    [NODE_TYPES.ACCESS_POINT] = { color = UI.Colors.Highlight, symbol = "A" },
    [NODE_TYPES.ROUTING] = { color = UI.Colors.Text, symbol = "R" },
    [NODE_TYPES.ENCRYPTED] = { color = Color(255, 0, 0), symbol = "E", detection_onloss = 20, detection_onwin = 0.3 },
    [NODE_TYPES.VOLATILE] = { color = Color(255, 165, 0), symbol = "V" },
    [NODE_TYPES.SECURITY_RELAY] = { color = Color(255, 0, 255), symbol = "S" },
    [NODE_TYPES.CORE] = { color = UI.Colors.Highlight, symbol = "C" },
}

local CAPTURE_TIME = 5 -- seconds



-----------------------------------------------------------------------------
-- Draws a filled circle
-- @param x number The center x coordinate
-- @param y number The center y coordinate
-- @param radius number The radius of the circle
-- @param segments number The number of segments to use to draw the circle
-----------------------------------------------------------------------------
local function DrawFilledCircle(x, y, radius, segments)
    segments = segments or 32
    local poly = {}
    for i = 0, segments do
        local ang = (i / segments) * 2 * math.pi
        table.insert(poly, {
            x = x + math.cos(ang) * radius,
            y = y + math.sin(ang) * radius
        })
    end
    surface.DrawPoly(poly)
end

-----------------------------------------------------------------------------
-- Draws an outlined circle
-- @param x number The center x coordinate
-- @param y number The center y coordinate
-- @param radius number The radius of the circle
-- @param segments number The number of segments to use to draw the circle
-----------------------------------------------------------------------------
local function DrawOutlinedCircle(x, y, radius, segments)
    segments = segments or 32
    local angleStep = (2 * math.pi) / segments
    local lastX = x + radius
    local lastY = y

    for i = 1, segments do
        local angle = i * angleStep
        local newX = x + radius * math.cos(angle)
        local newY = y + radius * math.sin(angle)
        surface.DrawLine(lastX, lastY, newX, newY)
        lastX = newX
        lastY = newY
    end
end


-----------------------------------------------------------------------------
-- Generates the node network for the minigame.
-- @param self table The entity.
-- @param difficulty number A number representing the difficulty.
-- @return table A table of nodes.
-----------------------------------------------------------------------------
local function GenerateNodes(self, difficulty)
    local nodes = {}
    local nodeId = 1
    local rings = {}

    local function AddNode(x, y, nodeType, ring, angle)
        nodes[nodeId] = {
            id = nodeId,
            x = x,
            y = y,
            type = nodeType,
            connections = {},
            state = 'locked', -- locked, unlocked, capturing, captured, in_minigame, cooldown
            capture_start = 0,
            cooldown_end = 0,
            ring = ring,
            angle = angle,
        }
        nodeId = nodeId + 1
        return nodes[nodeId - 1]
    end

    -- Ring 0: Core node
    local coreNode = AddNode(0, 0, NODE_TYPES.CORE, 0, 0)
    rings[0] = { coreNode }

    local numRings = 1 + math.floor(difficulty / 3)
    local nodesPerRing = 2 + difficulty

    -- Create nodes in rings
    for r = 1, numRings do
        rings[r] = {}
        local ringRadius = r / numRings
        for i = 0, nodesPerRing - 1 do
            local angle = (i / nodesPerRing) * 2 * math.pi + math.Rand(-0.1, 0.1)
            local x = math.cos(angle) * ringRadius
            local y = math.sin(angle) * ringRadius
            
            local nodeType = NODE_TYPES.ROUTING -- 10%
            local rand = math.random()
            if rand > 0.7 then nodeType = NODE_TYPES.SECURITY_RELAY -- 30%
            elseif rand > 0.3 then nodeType = NODE_TYPES.ENCRYPTED -- 40%
            elseif rand > 0.1 then nodeType = NODE_TYPES.VOLATILE -- 20%
            end

            local newNode = AddNode(x, y, nodeType, r, angle)
            table.insert(rings[r], newNode)
        end
    end

    -- Connect nodes
    for r = 1, numRings do
        local currentRing = rings[r]
        local ringNodeCount = #currentRing

        -- Connect nodes to their neighbors in the same ring
        if ringNodeCount > 1 then
            for i = 1, ringNodeCount do
                local nodeA = currentRing[i]
                local nodeB = currentRing[(i % ringNodeCount) + 1] -- Wraps around to connect last to first
                table.insert(nodeA.connections, nodeB.id)
                table.insert(nodeB.connections, nodeA.id)
            end
        end
        
        -- Connect each node to 1-2 closest nodes in the previous ring
        for _, node in ipairs(currentRing) do
            table.sort(rings[r-1], function(a, b) return math.abs(a.angle - node.angle) < math.abs(b.angle - node.angle) end)
            
            local numToConnect = math.random(1,2)
            for i = 1, math.min(#rings[r-1], numToConnect) do
                local prevNode = rings[r-1][i]
                table.insert(node.connections, prevNode.id)
                table.insert(prevNode.connections, node.id)
            end
        end
    end


    -- Choose an access point on the outermost ring
    local accessPoint = table.Random(rings[numRings])
    accessPoint.type = NODE_TYPES.ACCESS_POINT
    accessPoint.state = 'captured'
    
    -- Unlock nodes connected to access point
    for _, connId in ipairs(accessPoint.connections) do
        if nodes[connId] then
            nodes[connId].state = 'unlocked'
        end
    end

    return nodes
end


-----------------------------------------------------------------------------
-- Initializes the Network Routing stage
-- @param self table The entity
-----------------------------------------------------------------------------
STAGE.Init = function(self)
    self.Nodes = GenerateNodes(self, 5) -- Using a default difficulty of 5
    self.LastInputTime = 0
end

local MINIGAME_COOLDOWN = 5 -- seconds

-----------------------------------------------------------------------------
-- Placeholder Minigames
-- @param node table The node the minigame is being played on.
-- @param callback function The function to call with the result (true for win, false for loss).
-----------------------------------------------------------------------------
local MINIGAMES = {
    [NODE_TYPES.ENCRYPTED] = { "cipher" },
    [NODE_TYPES.SECURITY_RELAY] = { "cipher" },
}

STAGE.Draw = function(self, w, h)
    if not self.Nodes then return end
    if self.ActiveMinigame then
        if self.CurrentMinigame and self.CurrentMinigame.Draw then
            self.CurrentMinigame:Draw(self, w, h)
        end
        return
    end

    local centerX, centerY = w / 2, h / 2
    local radius = (math.min(w, h) / 2 - 50)
    local nodes = self.Nodes

    -- Draw connections first
    for _, node in pairs(nodes) do
        for _, connId in ipairs(node.connections) do
            local otherNode = nodes[connId]

            -- Draw each line only once
            if otherNode and node.id < connId then
                local node_state = node.state
                local other_state = otherNode.state

                local startX = centerX + node.x * radius
                local startY = centerY + node.y * radius
                local endX = centerX + otherNode.x * radius
                local endY = centerY + otherNode.y * radius

                local should_draw = false
                -- Traveled path: between two captured/capturing nodes
                if (node_state == 'captured' or node_state == 'capturing') and (other_state == 'captured' or other_state == 'capturing') then
                    surface.SetDrawColor(0, 255, 0, 200) -- Green for traveled
                    should_draw = true
                -- Reachable path: from a captured node to an unlocked one
                elseif (node_state == 'captured' and other_state == 'unlocked') or (node_state == 'unlocked' and other_state == 'captured') then
                    surface.SetDrawColor(UI.Colors.Highlight) -- Highlight for reachable
                    should_draw = true
                end

                if should_draw then
                    surface.DrawLine(startX, startY, endX, endY)
                end
            end
        end
    end

    -- Draw nodes and handle input
    for id, node in pairs(nodes) do
        local nodeX = centerX + node.x * radius
        local nodeY = centerY + node.y * radius
        local nodeRadius = 15
        local symbolFont = "DermaDefaultBold"
        local config = NODE_CONFIG[node.type]
        if node.type == NODE_TYPES.ACCESS_POINT then
            nodeRadius = 20
            symbolFont = "DermaLarge"
        elseif node.type == NODE_TYPES.CORE then
            nodeRadius = 25
            symbolFont = "DermaLarge"
        end
        -- Base fill
        surface.SetDrawColor(10, 10, 10, 200)
        DrawFilledCircle(nodeX, nodeY, nodeRadius)
        
        -- State border and symbol color
        local symbolColor = color_white
        if node.state == 'captured' then
            surface.SetDrawColor(0, 255, 0, 255)
        elseif node.state == 'capturing' or node.state == 'in_minigame' then
            surface.SetDrawColor(UI.Colors.Highlight)
        elseif node.state == 'unlocked' then
            local pulse = 0.5 + (math.sin(CurTime() * 5) * 0.5)
            surface.SetDrawColor(UI.Colors.Highlight.r, UI.Colors.Highlight.g, UI.Colors.Highlight.b, 150 + 105 * pulse)
        elseif node.state == 'cooldown' then
            surface.SetDrawColor(255, 0, 0, 150)
            if CurTime() > node.cooldown_end then node.state = 'unlocked' end
        else -- locked
            if node.type == NODE_TYPES.CORE then
                surface.SetDrawColor(UI.Colors.Highlight.r, UI.Colors.Highlight.g, UI.Colors.Highlight.b, 100)
                symbolColor = Color(255, 255, 255, 150)
            else
                surface.SetDrawColor(80, 80, 80, 100)
                symbolColor = Color(120, 120, 120)
            end
        end
        DrawOutlinedCircle(nodeX, nodeY, nodeRadius, 32)

        -- Inner symbol
        if node.state ~= 'locked' or node.type == NODE_TYPES.CORE then
            draw.SimpleText(config.symbol, symbolFont, nodeX, nodeY, symbolColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Progress bar for capturing
        if node.state == 'capturing' then
            local progress = (CurTime() - node.capture_start) / CAPTURE_TIME
            if progress >= 1 then
                node.state = 'captured'
                for _, connId in ipairs(node.connections) do
                    if nodes[connId] and nodes[connId].state == 'locked' then
                        nodes[connId].state = 'unlocked'
                    end
                end
            else
                local progRadius = Lerp(progress, 0, nodeRadius)
                surface.SetDrawColor(0, 255, 0, 255)
                DrawOutlinedCircle(nodeX, nodeY, progRadius, 16)
            end
        end

        -- Handle input for unlocked nodes
        if node.state ~= 'locked' and node.state ~= 'captured' and self.LastInputTime < CurTime() then
            local is_hovered = imgui.IsHovering(nodeX - nodeRadius, nodeY - nodeRadius, nodeRadius * 2, nodeRadius * 2)
            if node.state == 'unlocked' then
                -- Handle interaction based on node type, this is for non-minigame nodes
                if node.type == NODE_TYPES.ROUTING or node.type == NODE_TYPES.VOLATILE or node.type == NODE_TYPES.CORE then
                    if imgui.xButton(nodeX - nodeRadius, nodeY - nodeRadius, nodeRadius * 2, nodeRadius * 2, 0) then
                        if node.type == NODE_TYPES.CORE then
                            node.state = 'captured'
                            STAGE.Completed(self)
                        elseif node.type == NODE_TYPES.VOLATILE then
                            self:SetSignalStability(self:GetSignalStability() * math.Rand(0.7, 0.9)) -- Volatile makes signal worse on capture
                            node.state = 'capturing'
                            node.capture_start = CurTime()
                        else
                            node.state = 'capturing'
                            node.capture_start = CurTime()
                        end
                        self.LastInputTime = CurTime() + 0.5
                    end
                -- Minigame nodes interaction
                elseif MINIGAMES[node.type] then
                    if is_hovered and input.IsKeyDown(KEY_E) then
                        local minigameName = table.Random(MINIGAMES[node.type])
                        local minigame = ZKsSWHS.Minigames.Registered[minigameName]

                        if minigame then
                            node.state = 'in_minigame'
                            self.LastInputTime = CurTime() + 1
                            self.ActiveMinigame = true
                            self.CurrentMinigame = minigame

                            minigame:Start(node, function(success)
                                self.ActiveMinigame = false
                                self.CurrentMinigame = nil
                                if success then
                                    if NODE_CONFIG[node.type] and NODE_CONFIG[node.type].detection_onwin then
                                        self:SetDetectionLevel(self:GetDetectionLevel() * NODE_CONFIG[node.type].detection_onwin)
                                    end
                                    node.state = 'captured'
                                    for _, connId in ipairs(node.connections) do
                                        if nodes[connId] and nodes[connId].state == 'locked' then
                                            nodes[connId].state = 'unlocked'
                                        end
                                    end
                                else
                                    if NODE_CONFIG[node.type] and NODE_CONFIG[node.type].detection_onloss then
                                        self:SetDetectionLevel(self:GetDetectionLevel() + NODE_CONFIG[node.type].detection_onloss)
                                    end
                                    node.state = 'cooldown'
                                    node.cooldown_end = CurTime() + MINIGAME_COOLDOWN
                                end
                            end)
                        else
                            print("[SWHS] Minigame not found: " .. minigameName)
                        end
                    end
                end
            end

            -- Draw interaction prompt
            if is_hovered then
                local prompt = ""
                local can_interact = node.state == 'unlocked'
                if can_interact then
                    if node.type == NODE_TYPES.ROUTING or node.type == NODE_TYPES.VOLATILE then
                        ZKsSWHS.UI.InfoPanelText = "This node is a " .. (node.type == NODE_TYPES.ROUTING and "routing node" or "volatile node") .. ". Interact to capture it and unlock connected nodes."
                        prompt = "[LMB] Capture"
                    elseif MINIGAMES[node.type] then
                        prompt = "[E] " .. (node.type == NODE_TYPES.ENCRYPTED and "Decrypt" or "Bypass")
                        ZKsSWHS.UI.InfoPanelText = "This node is " .. (node.type == NODE_TYPES.ENCRYPTED and "encrypted" or "protected by a security relay") .. ". Interact to attempt to " .. (node.type == NODE_TYPES.ENCRYPTED and "decrypt it" or "bypass the security relay") .. "."
                    elseif node.type == NODE_TYPES.CORE then
                        prompt = "[LMB] Capture Core"
                        ZKsSWHS.UI.InfoPanelText = "This is the core node. Capture it to complete the breach."
                    end
                end
                if prompt ~= "" then
                    draw.SimpleText(prompt, "DermaDefault", nodeX, nodeY - 30, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
        end
    end
end

-----------------------------------------------------------------------------
-- Checks if the stage is completed
-- @param self table The entity
-- @return boolean Whether the stage is completed
-----------------------------------------------------------------------------
STAGE.Completed = function(self)
    if not self.Nodes then return false end
    for _, node in pairs(self.Nodes) do
        if node.type == NODE_TYPES.CORE and node.state == 'captured' then
            self:SetStage(self:GetStage() + 1)
            return true
        end
    end
    return false
end

local succ, err = pcall(function()
    Stages:Register(STAGE)
end)
if not succ then print(err) end
