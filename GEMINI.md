# Project Design Document: SW Hacking System

This document outlines the architecture, standards, and development workflows for the Star Wars RP Hacking System.

## Overview
The **SW Hacking System** is a modular framework for Garry's Mod designed to provide immersive, 3D2D-based hacking interactions for Star Wars RP servers. It allows players to interact with entities (consoles, doors, etc.) through a multi-stage hacking process involving signal alignment, security bypass, and various minigames.

## Core Architecture

### 1. Hackable Entities (`lua/entities/`)
All hackable objects should inherit from `sw_hs_base`.
- **States:** Managed via `NetworkVar("Int", 0, "State")`.
  - `0`: Idle
  - `1`: Hacking
  - `2`: Hacked
- **Stages:** Managed via `NetworkVar("Int", 1, "Stage")`. Each stage represents a step in the hacking process.

### 2. Networking (`lua/zks_swhs/core/`)
- Uses the `net` library for client-server communication.
- `ZKS.SWHS.StartHack`: Server to Client, initiates the hacking UI.
- `ZKS.SWHS.AbortHack`: Client to Server, resets entity state if the player exits.
- `ZKS.SWHS.UpdateStatus`: Client to Server, updates detection level and signal stability.

### 3. UI System (`lua/zks_swhs/3d2d_interface/`)
- **3D2D Interface:** Rendered directly on the entity using the `imgui` library for interaction.
- **Entry Point:** `ZKsSWHS.UI.EntryPoint(ent)` in `cl_main.lua`.
- **Stages:** Modular stage system defined in `cl_stages.lua`. Each stage has:
  - `ID`: Numeric index matching the entity's Stage NetworkVar.
  - `Init`: Client-side setup when the stage starts.
  - `Draw`: Rendering and logic loop for the stage.

### 4. Minigames (`lua/zks_swhs/minigames/`)
Minigames are self-contained logic units that can be triggered during specific stages. They should provide a `Draw` method and a callback for success/failure.

## Directory Structure
- `lua/autorun/`: Loader script (`sh_init_sw_hackable_sys.lua`).
- `lua/entities/`: Hackable entity definitions.
- `lua/zks_swhs/3d2d_interface/`: Core UI logic and stage definitions.
- `lua/zks_swhs/core/`: Server-side managers and networking.
- `lua/zks_swhs/imgui/`: The `imgui` library for 3D2D interactions.
- `lua/zks_swhs/minigames/`: Client-side minigame implementations.

## Engineering Standards

### File Headers
Every file must start with a header indicating its path, realm, and purpose:
```lua
--[[-------------------------------------------------------------------------
  lua\path\to\file.lua
  REALM (CLIENT/SERVER/SHARED)
  Brief description of the file's goal
---------------------------------------------------------------------------]]
```

### Function Documentation
Functions must be documented using the following format:
```lua
-----------------------------------------------------------------------------
-- <Function's Goal>
-- @param <name> <type> <description>
-- @return <type> <description>
-----------------------------------------------------------------------------
```

### Best Practices
- **Networking:** Avoid sending net messages inside `Think` or `Draw` hooks.
- **Hooks:** Use `hook.Add` instead of overriding `GM:` functions.
- **Optimization:** Cache values (like `LocalPlayer()`) when used in high-frequency hooks like `Draw`.
- **UI:** Mimic the existing holographic blue/cyan aesthetic for new UI elements.

## Adding a New Stage
1. Create a new file in `lua/zks_swhs/3d2d_interface/stages/cl_<name>.lua`.
2. Define a `STAGE` table with `ID`, `Name`, `Init`, and `Draw`.
3. Register it using `ZKsSWHS.UI.Stages:Register(STAGE)`.
4. Update the `sw_hs_base` (or child entity) to increment the stage upon completion.
