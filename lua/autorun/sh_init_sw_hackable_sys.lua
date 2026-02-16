---------------------------------------------------------------
--  lua\autorun\sh_init_sw_hackable_entities.lua
---------------------------------------------------------------

ZKsSWHS = ZKsSWHS or {}

ZKsSWHS.VERSION = 1
ZKsSWHS.VERSION_GITHUB = 0
ZKsSWHS.VERSION_TYPE = ".GIT"

function ZKsSWHS:GetVersion()
	return ZKsSWHS.VERSION
end

function ZKsSWHS:CheckUpdates()
	http.Fetch("https://raw.githubusercontent.com/Zak2801/sw-hackable-entities/refs/heads/main/lua/autorun/sh_addon_loader_zksf.lua", function(contents,size) 
		local Entry = string.match( contents, "ZKsSWHS.VERSION%s=%s%d+" )

		if Entry then
			ZKsSWHS.VERSION_GITHUB = tonumber( string.match( Entry , "%d+" ) ) or 0
		else
			ZKsSWHS.VERSION_GITHUB = 0
		end

		if ZKsSWHS.VERSION_GITHUB == 0 then
			print("[HackableEntities] Latest version could not be detected, You have Version: "..ZKsSWHS:GetVersion())
		else
			if  ZKsSWHS:GetVersion() >= ZKsSWHS.VERSION_GITHUB then
				print("[HackableEntities] up to date. Version: "..ZKsSWHS:GetVersion())
			else
				print("[HackableEntities] a newer version is available! Version: "..ZKsSWHS.VERSION_GITHUB..", You have Version: "..ZKsSWHS:GetVersion())

				if ZKsSWHS.VERSION_TYPE == ".GIT" then
					print("[HackableEntities] Get the latest version at https://github.com/Zak2801/sw-hackable-entities")
				else
					print("[HackableEntities] Restart your game/server to get the latest version!")
				end

				if CLIENT then 
					timer.Simple(25, function() 
						chat.AddText( Color( 255, 0, 0 ), "[HackableEntities] a newer version is available!" )
					end)
				end
			end
		end
	end)
end

local function LoadDirectory(path)
	local files, folders = file.Find(path .. "/*", "LUA")

	for _, fileName in ipairs(files) do
		local filePath = path .. "/" .. fileName

		if CLIENT then
			include(filePath)
			print("[SWHS]: Included client file: " .. filePath)
		else
			if fileName:StartWith("cl_") then
				AddCSLuaFile(filePath)
				print("[SWHS]: Included client file: " .. filePath)
			elseif fileName:StartWith("sh_") then
				AddCSLuaFile(filePath)
				include(filePath)
				print("[SWHS]: Included shared file: " .. filePath)
			else
				include(filePath)
				print("[SWHS]: Included server file: " .. filePath)
			end
		end
	end

	return files, folders
end

local function LoadDirectoryRecursive(basePath)
	local _, folders = LoadDirectory(basePath)
	for _, folderName in ipairs(folders) do
		print("[SWHS]: Loading folder: " .. folderName)
		LoadDirectoryRecursive(basePath .. "/" .. folderName)
	end
end

local version = "v0.1"
MsgC( "\n", Color( 255, 255, 255 ), "---------------------------------- \n" )
MsgC( Color( 180, 130, 245 ), "[Zaktak's SW Hacking System]\n" )
MsgC( Color( 255, 255, 255 ), "Loading Files.......\n" )
MsgC( Color( 255, 255, 255 ), "Version........ "..version.."\n" )
MsgC( Color( 255, 255, 255 ), "---------------------------------- \n" )

LoadDirectoryRecursive("zks_swhs")


hook.Add( "InitPostEntity", "!!zks_swhs_checkupdates", function()
	timer.Simple(10, function() ZKsSWHS:CheckUpdates() end)
end )