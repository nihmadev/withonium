task.wait(1)
local _modules = {}
local _cache = {}

local old_require = require
local _require
local function require_proxy(p)
    if typeof(p) == 'string' then
        return _require(p)
    end
    return old_require(p)
end
local require = require_proxy

_modules["modules/Aimbot"] = function()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")





local Prediction = require("modules/Aimbot/Prediction")
local Targeting = require("modules/Aimbot/Targeting")
local Input = require("modules/Aimbot/Input")
local Exploits = require("modules/Aimbot/Exploits")
local Hitboxes = require("modules/Aimbot/Hitboxes")
local Hooks = require("modules/Aimbot/Hooks")

local Aimbot = {
    CurrentTarget = nil,
    IsAiming = false,
    TargetPosition = nil,
    FOVCircle = nil,
    SilentTarget = nil,
    LastCacheTick = 0,
    ToggleActive = false,
    LastKeyState = false,
    
    
    FreeCamActive = false,
    FreeCamPos = Vector3.new(0, 0, 0),
    FreeCamRot = Vector2.new(0, 0),
    OriginalCameraType = nil,
    OriginalCameraCFrame = nil,
    
    
    LastPredictedDir = nil,
    PredictionSmoothing = 0.2, 
}


Aimbot.FOVCircle = Drawing.new("Circle")
Aimbot.FOVCircle.Color = Color3.new(1, 1, 1)
Aimbot.FOVCircle.Thickness = 1
Aimbot.FOVCircle.NumSides = 64
Aimbot.FOVCircle.Filled = false
Aimbot.FOVCircle.Transparency = 0.5
Aimbot.FOVCircle.Visible = false


function Aimbot.GetProjectilePrediction(target, Settings, Ballistics, customOrigin)
    return Prediction.GetProjectilePrediction(target, Settings, Ballistics, customOrigin)
end

function Aimbot.IsInputPressed(key)
    return Input.IsInputPressed(key)
end

function Aimbot.GetSilentTarget(Settings, Utils)
    return Aimbot.SilentTarget
end

function Aimbot.FindTarget(Settings, Utils)
    return Targeting.FindTarget(Settings, Utils, Aimbot)
end

function Aimbot.InitHooks(Settings, Utils, Ballistics)
    return Hooks.InitHooks(Aimbot, Settings, Utils, Ballistics)
end

function Aimbot.ApplyNoRecoil(Settings)
    return Exploits.ApplyNoRecoil(Settings)
end

function Aimbot.ApplyFastShoot(Settings)
    return Exploits.ApplyFastShoot(Settings)
end

function Aimbot.ApplyJumpShot(Settings)
    return Exploits.ApplyJumpShot(Settings)
end

function Aimbot.ApplySpider(Settings)
    return Exploits.ApplySpider(Settings)
end

function Aimbot.ApplySpeedHack(Settings)
    return Exploits.ApplySpeedHack(Settings)
end

function Aimbot.ApplyFreeCam(Settings)
    return Exploits.ApplyFreeCam(Aimbot, Settings)
end

function Aimbot.ApplyThirdPerson(Settings)
    return Exploits.ApplyThirdPerson(Settings)
end

function Aimbot.ApplyGodMode(Settings)
    return Exploits.ApplyGodMode(Settings)
end

function Aimbot.ApplyAntiAFK(Settings)
    return Exploits.ApplyAntiAFK(Settings)
end

function Aimbot.ApplyAntiAim(Settings)
    return Exploits.ApplyAntiAim(Settings)
end

function Aimbot.UpdateHitboxes(Settings, Utils, ESP)
    return Hitboxes.UpdateHitboxes(Aimbot, Settings, Utils, ESP)
end

function Aimbot.Update(deltaTime, Settings, Utils, Ballistics, ESP)
    if not Settings then return end
    
    Aimbot.UpdateHitboxes(Settings, Utils, ESP)
    
    
    local currentFrameTarget = Aimbot.FindTarget(Settings, Utils)
    
    
    if Settings.silentAimEnabled then
        Aimbot.SilentTarget = currentFrameTarget
    else
        Aimbot.SilentTarget = nil
    end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local isPressed = false
    if Settings.aimKey then
        isPressed = Aimbot.IsInputPressed(Settings.aimKey)
    end
    
    local shouldAim = false
    
    if Settings.aimbotEnabled then
        local mode = Settings.aimKeyMode or "Hold"
        if mode == "Hold" then
            shouldAim = isPressed
        elseif mode == "Toggle" then
            if isPressed and not Aimbot.LastKeyState then
                Aimbot.ToggleActive = not Aimbot.ToggleActive
            end
            shouldAim = Aimbot.ToggleActive
        elseif mode == "Always" then
            shouldAim = true
        end
    else
        Aimbot.ToggleActive = false
    end
    Aimbot.LastKeyState = isPressed
    
    if shouldAim then
        local target = currentFrameTarget
        if target and target.targetPart then
            Aimbot.CurrentTarget = target
            Aimbot.IsAiming = true
            
            
            
            
            local predictedDir = Aimbot.GetProjectilePrediction(target, Settings, Ballistics)
            Aimbot.TargetPosition = camera.CFrame.Position + (predictedDir * 10)
            
            local currentCFrame = camera.CFrame
            
            local upVector = Vector3.new(0, 1, 0)
            if math.abs(predictedDir:Dot(upVector)) > 0.99 then
                upVector = Vector3.new(0, 0, 1) 
            end
            
            local targetCFrame = CFrame.lookAt(currentCFrame.Position, currentCFrame.Position + predictedDir, upVector)
            
            
            local smoothnessFactor = Settings.smoothness or 0.5
            
            local safeDeltaTime = math.min(deltaTime, 0.1)
            local alpha = math.clamp(safeDeltaTime * (smoothnessFactor * 250), 0, 1)
            
            if smoothnessFactor < 1 then
                camera.CFrame = currentCFrame:Lerp(targetCFrame, alpha)
            else
                camera.CFrame = targetCFrame
            end
        else
            
            Aimbot.CurrentTarget = nil
            Aimbot.IsAiming = false
            Aimbot.TargetPosition = nil
            Aimbot.LastPredictedDir = nil 
        end
    else
        
        Aimbot.CurrentTarget = nil
        Aimbot.IsAiming = false
        Aimbot.TargetPosition = nil
        Aimbot.LastPredictedDir = nil 
    end

    Aimbot.ApplyNoRecoil(Settings)
    Aimbot.ApplyFastShoot(Settings)
    Aimbot.ApplyJumpShot(Settings)
    Aimbot.ApplySpider(Settings)
    Aimbot.ApplySpeedHack(Settings)
    Aimbot.ApplyFreeCam(Settings)
    Aimbot.ApplyThirdPerson(Settings)
    Aimbot.ApplyGodMode(Settings)
    Aimbot.ApplyAntiAFK(Settings)
    
    
    
    Aimbot.ApplyAntiAim(Settings)

    
    if Aimbot.FOVCircle then
        Aimbot.FOVCircle.Visible = Settings.fovCircleEnabled
        Aimbot.FOVCircle.Radius = Settings.fovSize or 90
        Aimbot.FOVCircle.Position = Utils.getScreenCenter()
    end
end

function Aimbot.Remove()
    if Aimbot.FreeCamActive then
        local camera = workspace.CurrentCamera
        if camera then
            camera.CameraType = Aimbot.OriginalCameraType or Enum.CameraType.Custom
        end
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        Aimbot.FreeCamActive = false
        
        
        local character = LocalPlayer.Character
        if character and Exploits.OriginalCollision then
            for part, originalValue in pairs(Exploits.OriginalCollision) do
                if part and part.Parent then
                    part.CanCollide = originalValue
                end
            end
            Exploits.OriginalCollision = nil
        end
    end

    if Aimbot.FOVCircle then
        Aimbot.FOVCircle:Remove()
        Aimbot.FOVCircle = nil
    end
    
    
    if Hitboxes.OriginalProperties then
        for part, props in pairs(Hitboxes.OriginalProperties) do
            if part and part.Parent then
                part.Size = props.Size
                part.Transparency = props.Transparency
                part.CanCollide = props.CanCollide
                local visual = part:FindFirstChild("HitboxVisual")
                if visual then visual:Destroy() end
            end
        end
        Hitboxes.OriginalProperties = {}
    end
    
    
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.AutoRotate = true end
    
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local rootJoint = rootPart:FindFirstChild("RootJoint") or (character:FindFirstChild("LowerTorso") and character.LowerTorso:FindFirstChild("Root"))
        if rootJoint then
            rootJoint.Transform = CFrame.new()
        end
    end
end

return Aimbot

end

_modules["modules/Ballistics"] = function()
local Ballistics = {}


local VELOCITY_NAMES = {"MuzzleVelocity", "Velocity", "Speed", "ProjectileSpeed", "BulletSpeed", "ShootVelocity", "ProjectileVelocity"}
local GRAVITY_NAMES = {"Gravity", "BulletGravity", "Drop", "ProjectileGravity", "BulletDrop", "ProjectileDrop", "Acceleration"}

function Ballistics.GetWeaponFromTool(tool)
    if not tool then return nil end
    
    local stats = {
        velocity = nil,
        gravity = nil
    }
    
    
    for _, name in ipairs(VELOCITY_NAMES) do
        local val = tool:GetAttribute(name)
        if val and type(val) == "number" and val > 0 then
            stats.velocity = val
            break
        end
    end
    
    for _, name in ipairs(GRAVITY_NAMES) do
        local val = tool:GetAttribute(name)
        if val and type(val) == "number" then
            stats.gravity = val
            break
        end
    end
    
    
    if not stats.velocity or not stats.gravity then
        for _, v in ipairs(tool:GetChildren()) do
            if v:IsA("ValueBase") then
                local vName = v.Name
                if not stats.velocity then
                    for _, name in ipairs(VELOCITY_NAMES) do
                        if vName == name then
                            stats.velocity = v.Value
                            break
                        end
                    end
                end
                if not stats.gravity then
                    for _, name in ipairs(GRAVITY_NAMES) do
                        if vName == name then
                            stats.gravity = v.Value
                            break
                        end
                    end
                end
            end
        end
    end
    
    
    if not stats.velocity or not stats.gravity then
        local config = tool:FindFirstChild("Settings") or tool:FindFirstChild("Config") or tool:FindFirstChild("Configuration") or tool:FindFirstChild("GunSettings")
        if config then
            if config:IsA("ModuleScript") then
                local success, moduleData = pcall(require, config)
                if success and type(moduleData) == "table" then
                    if not stats.velocity then
                        for _, name in ipairs(VELOCITY_NAMES) do
                            if moduleData[name] and type(moduleData[name]) == "number" then
                                stats.velocity = moduleData[name]
                                break
                            end
                        end
                    end
                    if not stats.gravity then
                        for _, name in ipairs(GRAVITY_NAMES) do
                            if moduleData[name] and type(moduleData[name]) == "number" then
                                stats.gravity = moduleData[name]
                                break
                            end
                        end
                    end
                end
            else
                for _, v in ipairs(config:GetChildren()) do
                    if v:IsA("ValueBase") then
                        local vName = v.Name
                        if not stats.velocity then
                            for _, name in ipairs(VELOCITY_NAMES) do
                                if vName == name then
                                    stats.velocity = v.Value
                                    break
                                end
                            end
                        end
                        if not stats.gravity then
                            for _, name in ipairs(GRAVITY_NAMES) do
                                if vName == name then
                                    stats.gravity = v.Value
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    
    if not stats.velocity or not stats.gravity then
        local fastCastData = tool:FindFirstChild("FastCastSettings")
        if fastCastData and fastCastData:IsA("ModuleScript") then
            local success, fcSettings = pcall(require, fastCastData)
            if success and type(fcSettings) == "table" then
                stats.velocity = stats.velocity or fcSettings.Velocity or fcSettings.MuzzleVelocity
                stats.gravity = stats.gravity or fcSettings.Gravity or fcSettings.Acceleration
            end
        end
    end

    
    if not stats.velocity or not stats.gravity then
        for _, v in ipairs(tool:GetDescendants()) do
            if v:IsA("ValueBase") then
                local name = v.Name:lower()
                if not stats.velocity and (name:find("velocity") or name:find("muzzle") or (name:find("speed") and not name:find("walk"))) then
                    if type(v.Value) == "number" and v.Value > 1 then
                        stats.velocity = v.Value
                    end
                elseif not stats.gravity and (name:find("gravity") or name:find("drop") or name:find("accel")) then
                    if type(v.Value) == "number" then
                        stats.gravity = v.Value
                    end
                end
            end
            if stats.velocity and stats.gravity then break end
        end
    end

    
    if stats.velocity and type(stats.velocity) == "number" then
        if stats.velocity <= 0 then stats.velocity = nil end
    end
    
    if stats.gravity and type(stats.gravity) == "number" then
        
        stats.gravity = math.abs(stats.gravity)
    end

    return (stats.velocity or stats.gravity) and stats or nil
end

function Ballistics.GetConfig()
    local player = game:GetService("Players").LocalPlayer
    local tool = player and player.Character and player.Character:FindFirstChildWhichIsA("Tool")
    
    
    if tool then
        local dynamicStats = Ballistics.GetWeaponFromTool(tool)
        if dynamicStats then
            return {
                velocity = dynamicStats.velocity or 1000,
                gravity = dynamicStats.gravity or 196.2
            }
        end
    end
    
    
    if tool then
        local name = tool.Name:lower()
        if name:find("bow") then
            return { velocity = 150, gravity = 50 }
        elseif name:find("crossbow") then
            return { velocity = 200, gravity = 40 }
        elseif name:find("sniper") or name:find("bolt") or name:find("awp") or name:find("l9") then
            return { velocity = 1500, gravity = 196.2 }
        end
    end
    
    
    return { velocity = 1000, gravity = 196.2 }
end

return Ballistics

end

_modules["modules/ConfigManager"] = function()
local HttpService = game:GetService("HttpService")

local ConfigManager = {
    Folder = "Withonium/Configs"
}

function ConfigManager.Init()
    local success, err = pcall(function()
        if not isfolder("Withonium") then
            makefolder("Withonium")
        
        end
        if not isfolder(ConfigManager.Folder) then
            makefolder(ConfigManager.Folder)
        end
    end)
    return success
end

function ConfigManager.Serialize(settings)
    local serialized = {}
    for k, v in pairs(settings) do
        if typeof(v) == "Color3" then
            serialized[k] = {Type = "Color3", Value = {v.R, v.G, v.B}}
        elseif typeof(v) == "EnumItem" then
            serialized[k] = {Type = "EnumItem", Enum = tostring(v.EnumType), Value = v.Name}
        elseif type(v) ~= "function" and type(v) ~= "table" then
            serialized[k] = v
        end
    end
    return HttpService:JSONEncode(serialized)
end

function ConfigManager.Deserialize(json, settings)
    local data = HttpService:JSONDecode(json)
    for k, v in pairs(data) do
        if type(v) == "table" and v.Type then
            if v.Type == "Color3" then
                settings[k] = Color3.new(v.Value[1], v.Value[2], v.Value[3])
            elseif v.Type == "EnumItem" then
                local enumType = v.Enum:gsub("Enum.", "")
                pcall(function()
                    settings[k] = Enum[enumType][v.Value]
                end)
            end
        else
            settings[k] = v
        end
    end
end

function ConfigManager.Save(name, settings)
    ConfigManager.Init()
    local success, err = pcall(function()
        local path = ConfigManager.Folder .. "/" .. name .. ".json"
        local json = ConfigManager.Serialize(settings)
        writefile(path, json)
    end)
    return success
end

function ConfigManager.Load(name, settings)
    local success, result = pcall(function()
        local path = ConfigManager.Folder .. "/" .. name .. ".json"
        if isfile(path) then
            local json = readfile(path)
            ConfigManager.Deserialize(json, settings)
            return true
        
        end
        return false
    end)
    return success and result
end

function ConfigManager.List()
    ConfigManager.Init()
    local success, result = pcall(function()
        local files = listfiles(ConfigManager.Folder)
        local configs = {}
        for _, file in ipairs(files) do
            
            local name = file:match("([^/\\]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
        return configs
    end)
    return success and result or {}
end

function ConfigManager.Delete(name)
    local path = ConfigManager.Folder .. "/" .. name .. ".json"
    if isfile(path) then
        delfile(path)
    end
end

return ConfigManager

end

_modules["modules/ESP"] = function()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")


local State = require("modules/ESP/State")
local Skeleton = require("modules/ESP/Skeleton")
local Chams = require("modules/ESP/Chams")
local Labels = require("modules/ESP/Labels")
local Healthbars = require("modules/ESP/Healthbars")

local ESP = {
    Data = State.Data,
    Highlights = State.Highlights,
    Labels = State.Labels,
    Skeletons = State.Skeletons,
    Healthbars = State.Healthbars,
    Container = State.Container,
    PlayersWithDist = {}, 
    PlayerDataPool = {}, 
    LastUpdate = 0
}

function ESP.Create(player)
    State.Create(player)
end

function ESP.Remove(player)
    pcall(function() Chams.Destroy(player) end)
    pcall(function() Labels.Destroy(player) end)
    pcall(function() Skeleton.Destroy(player) end)
    pcall(function() Healthbars.Destroy(player) end)
    if State.Data then
        State.Data[player] = nil
    end
end

function ESP.Update(Settings, deltaTime, Utils)
    local now = tick()
    if now - ESP.LastUpdate < 0.033 then return end 
    ESP.LastUpdate = now

    local Camera = workspace.CurrentCamera
    if not Camera then return end
    
    local activeHighlights = 0
    local maxHighlights = 15 
    
    
    local playersWithDist = ESP.PlayersWithDist
    local pool = ESP.PlayerDataPool
    
    
    for i = 1, #playersWithDist do
        local data = playersWithDist[i]
        data.Player = nil
        data.Character = nil
        data.RootPart = nil
        table.insert(pool, data)
        playersWithDist[i] = nil
    end
    
    local allPlayers = Players:GetPlayers()
    
    
    for player, _ in pairs(State.Data) do
        if not Players:GetPlayerByUserId(player.UserId) then
            ESP.Remove(player)
        end
    end

    for i = 1, #allPlayers do
        local player = allPlayers[i]
        if player == LocalPlayer then continue end
        local character = Utils.getCharacter(player)
        local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Middle"))
        
        local dist = 999999
        if rootPart then
            dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
        end
        
        
        local data = table.remove(pool) or {}
        data.Player = player
        data.Distance = dist
        data.Character = character
        data.RootPart = rootPart
        
        table.insert(playersWithDist, data)
    end
    
    table.sort(playersWithDist, function(a, b)
        return a.Distance < b.Distance
    end)

    local maxDistStuds = Settings.espMaxDistance or 700
    
    for i = 1, #playersWithDist do
        local data = playersWithDist[i]
        local player = data.Player
        local character = data.Character
        local rootPart = data.RootPart
        local distance = data.Distance
        
        if not rootPart or not character then 
            ESP.Remove(player)
            continue 
        end

        local isWithinDistance = distance <= maxDistStuds
        
        if not isWithinDistance then
            Chams.Cleanup(player)
            Labels.Cleanup(player)
            Skeleton.Cleanup(player)
            Healthbars.Cleanup(player)
            continue
        end

        
        if State.Data[player] and State.Data[player].LastCharacter ~= character then
            ESP.Remove(player)
        end
        
        State.Create(player)
        State.Data[player].LastCharacter = character
        
        local humanoid = character:FindFirstChild("Humanoid")
        
        
        if Chams.Update(player, character, humanoid, Settings, activeHighlights, maxHighlights) then
            activeHighlights = activeHighlights + 1
        end

        
        if Settings.espEnabled and Settings.espSkeleton and character and humanoid and humanoid.Health > 0 and character.Parent then
            Skeleton.Draw(player, character, Settings)
        else
            Skeleton.Cleanup(player)
        end

        
        Labels.Update(player, character, rootPart, humanoid, Settings, distance, isWithinDistance)

        
        Healthbars.Update(player, character, rootPart, humanoid, Settings, isWithinDistance)
    end
end

return ESP

end

_modules["modules/GUI"] = function()
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer


local function loadWithTimeout(url: string, timeout: number?): ...any
	if type(url) ~= "string" then return false, "URL must be a string" end
	url = url:gsub("^%s*(.-)%s*$", "%1")
	if not url:find("^http") then return false, "Invalid protocol" end

	timeout = timeout or 15
	local requestCompleted = false
	local success, result = false, nil

	local requestThread = task.spawn(function()
		local fetchSuccess, fetchResult
		
		
		local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request
		if requestFunc then
			fetchSuccess, fetchResult = pcall(function()
				local res = requestFunc({
					Url = url,
					Method = "GET"
				})
				if res and res.StatusCode == 200 then
					return res.Body
				end
				error(res and ("HTTP " .. tostring(res.StatusCode)) or "Unknown error!")
			end)
		else
			
			for i = 1, 3 do
				fetchSuccess, fetchResult = pcall(function()
					return game:HttpGet(url)
				end)
				if fetchSuccess and fetchResult and #fetchResult > 0 then break end
				task.wait(1)
			end
		end

		if not fetchSuccess or not fetchResult or #fetchResult == 0 then
			success, result = false, fetchResult or "Empty response"
			requestCompleted = true
			return
		end

		local execSuccess, execResult = pcall(function()
			local f, err = loadstring(fetchResult)
			if f then return f() end
			error(err)
		end)
		success, result = execSuccess, execResult
		requestCompleted = true
	end)

	task.delay(timeout, function()
		if not requestCompleted then
			task.cancel(requestThread)
			success, result = false, "Request timed out"
			requestCompleted = true
		end
	end)

	while not requestCompleted do task.wait() end
	return success, result
end

local function loadLibrary(): any
	local success, result = loadWithTimeout("https://raw.githubusercontent.com/nihmadev/Withonium/refs/heads/main/WithoniumRTY.lua")
	if success and result then
		return result
	end
	
	error("Failed to load WithoniumRTY: " .. tostring(result))
end

local WithoniumRTY = loadLibrary()

local GUI = {
    Window = nil,
    Tabs = {},
    ConfigManager = nil,
    UnloadCallback = nil,
    ConfigName = "shlepa228",
    CurrentTab = "Aimbot",
    
    
    Watermark = {
        Frame = nil,
        Text = nil,
        Avatar = nil
    },
    KeybindList = {
        Frame = nil,
        Container = nil,
        Items = {}
    },
    FrameCount = 0,
    LastWatermarkUpdate = 0,

    
    Elements = {
        Toggles = {}
    },

    
    ScreenGui = nil
}


local function getKeyName(key)
    if not key then return "None" end
    local str = tostring(key)
    str = str:gsub("Enum.KeyCode.", "")
    str = str:gsub("Enum.UserInputType.", "")
    return str
end


local function setKeybind(Key, Settings, SettingName)
    if not Key then return end
    
    
    local success, result = pcall(function() return Enum.KeyCode[Key] end)
    if success and result then
        Settings[SettingName] = result
        return
    end
    
    
    success, result = pcall(function() return Enum.UserInputType[Key] end)
    if success and result then
        Settings[SettingName] = result
    end
end

function GUI.Init(Settings, Utils, UnloadCallback, ConfigManager)
    GUI.ConfigManager = ConfigManager
    GUI.UnloadCallback = UnloadCallback
    
    
    local gui_parent = nil
    pcall(function()
        if gethui then gui_parent = gethui()
        elseif game:GetService("CoreGui") then gui_parent = game:GetService("CoreGui")
        else gui_parent = LocalPlayer:WaitForChild("PlayerGui") end
    end)

    if gui_parent then
        GUI.ScreenGui = Instance.new("ScreenGui")
        GUI.ScreenGui.Name = "WithoniumExternal"
        GUI.ScreenGui.ResetOnSpawn = false
        GUI.ScreenGui.DisplayOrder = 100
        GUI.ScreenGui.Parent = gui_parent
        GUI.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global 

        
        GUI.Watermark.Frame = Instance.new("Frame")
        GUI.Watermark.Frame.Name = "Watermark"
        GUI.Watermark.Frame.Parent = GUI.ScreenGui
        GUI.Watermark.Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        GUI.Watermark.Frame.Position = UDim2.new(0, 10, 0, 10)
        GUI.Watermark.Frame.Size = UDim2.new(0, 0, 0, 26)
        GUI.Watermark.Frame.AutomaticSize = Enum.AutomaticSize.X
        GUI.Watermark.Frame.Visible = Settings.watermarkEnabled
        
        local WMCorner = Instance.new("UICorner")
        WMCorner.CornerRadius = UDim.new(0, 6)
        WMCorner.Parent = GUI.Watermark.Frame
        
        local WMPadding = Instance.new("UIPadding")
        WMPadding.PaddingLeft = UDim.new(0, 6)
        WMPadding.PaddingRight = UDim.new(0, 8)
        WMPadding.Parent = GUI.Watermark.Frame

        local WMList = Instance.new("UIListLayout")
        WMList.FillDirection = Enum.FillDirection.Horizontal
        WMList.VerticalAlignment = Enum.VerticalAlignment.Center
        WMList.Padding = UDim.new(0, 8)
        WMList.Parent = GUI.Watermark.Frame

        GUI.Watermark.Avatar = Instance.new("ImageLabel")
        GUI.Watermark.Avatar.Name = "Avatar"
        GUI.Watermark.Avatar.BackgroundTransparency = 1
        GUI.Watermark.Avatar.Size = UDim2.new(0, 18, 0, 18)
        GUI.Watermark.Avatar.Parent = GUI.Watermark.Frame
        GUI.Watermark.Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
        
        local AvatarCorner = Instance.new("UICorner")
        AvatarCorner.CornerRadius = UDim.new(1, 0)
        AvatarCorner.Parent = GUI.Watermark.Avatar

        GUI.Watermark.Text = Instance.new("TextLabel")
        GUI.Watermark.Text.Name = "Text"
        GUI.Watermark.Text.BackgroundTransparency = 1
        GUI.Watermark.Text.Font = Enum.Font.GothamMedium
        GUI.Watermark.Text.TextColor3 = Color3.new(1, 1, 1)
        GUI.Watermark.Text.TextSize = 13
        GUI.Watermark.Text.Size = UDim2.new(0, 0, 1, 0)
        GUI.Watermark.Text.AutomaticSize = Enum.AutomaticSize.X
        GUI.Watermark.Text.Text = "Withonium | Initializing..."
        GUI.Watermark.Text.Parent = GUI.Watermark.Frame

        
        GUI.KeybindList.Frame = Instance.new("Frame")
        GUI.KeybindList.Frame.Name = "KeybindList"
        GUI.KeybindList.Frame.Parent = GUI.ScreenGui
        GUI.KeybindList.Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        GUI.KeybindList.Frame.Position = UDim2.new(0, 10, 0, 42)
        GUI.KeybindList.Frame.Size = UDim2.new(0, 220, 0, 0)
        GUI.KeybindList.Frame.AutomaticSize = Enum.AutomaticSize.Y
        GUI.KeybindList.Frame.Visible = Settings.watermarkEnabled
        
        local KBCorner = Instance.new("UICorner")
        KBCorner.CornerRadius = UDim.new(0, 6)
        KBCorner.Parent = GUI.KeybindList.Frame
        
        local KBStroke = Instance.new("UIStroke")
        KBStroke.Color = Color3.fromRGB(45, 45, 45)
        KBStroke.Thickness = 1
        KBStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        KBStroke.Parent = GUI.KeybindList.Frame
        
        local KBList = Instance.new("UIListLayout")
        KBList.Padding = UDim.new(0, 4)
        KBList.Parent = GUI.KeybindList.Frame

        local KBPadding = Instance.new("UIPadding")
        KBPadding.PaddingLeft = UDim.new(0, 8)
        KBPadding.PaddingRight = UDim.new(0, 8)
        KBPadding.PaddingTop = UDim.new(0, 6)
        KBPadding.PaddingBottom = UDim.new(0, 6)
        KBPadding.Parent = GUI.KeybindList.Frame

        local KBHeader = Instance.new("TextLabel")
        KBHeader.Name = "Header"
        KBHeader.BackgroundTransparency = 1
        KBHeader.Size = UDim2.new(1, 0, 0, 24)
        KBHeader.Font = Enum.Font.GothamBold
        KBHeader.Text = "Keybinds"
        KBHeader.TextColor3 = Color3.new(1, 1, 1)
        KBHeader.TextSize = 14
        KBHeader.Parent = GUI.KeybindList.Frame

        GUI.KeybindList.Container = Instance.new("Frame")
        GUI.KeybindList.Container.Name = "Items"
        GUI.KeybindList.Container.BackgroundTransparency = 1
        GUI.KeybindList.Container.Size = UDim2.new(1, 0, 0, 0)
        GUI.KeybindList.Container.AutomaticSize = Enum.AutomaticSize.Y
        GUI.KeybindList.Container.Parent = GUI.KeybindList.Frame
        
        local ItemsLayout = Instance.new("UIListLayout")
        ItemsLayout.Padding = UDim.new(0, 2)
        ItemsLayout.Parent = GUI.KeybindList.Container
    end
    
    GUI.Window = WithoniumRTY:CreateWindow({
        Name = "Withonium",
        LoadingTitle = "Withonium",
        LoadingSubtitle = "by nihmadev",
        Icon = "https://github.com/nihmadev/Withonium/raw/main/icon.png",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "Withonium",
            FileName = GUI.ConfigName
        },
        Discord = {
            Enabled = false,
            Invite = "noinvitelink",
            RememberJoins = true
        },
        KeySystem = false
    })

    
    task.spawn(function()
        while true do
            pcall(function()
                local rayfield = game:GetService("CoreGui"):FindFirstChild("Rayfield") or LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("Rayfield")
                if rayfield then
                    local main = rayfield:FindFirstChild("Main")
                    if main then
                        local topbar = main:FindFirstChild("Topbar")
                        if topbar then
                            for _, v in ipairs(topbar:GetChildren()) do
                                
                                if v:IsA("ImageButton") or v:IsA("Button") then
                                    local name = v.Name:lower()
                                    
                                    if name:find("settings") or name:find("bind") or name:find("help") then
                                        v.Visible = false
                                        v.Transparency = 1
                                        v.Position = UDim2.new(0, -500, 0, 0)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.5)
        end
    end)

    
    local AimbotTab = GUI.Window:CreateTab("Aimbot", 9134785384)
    
    AimbotTab:CreateSection("Silent Aim")
    GUI.Elements.Toggles["aimbotEnabled"] = AimbotTab:CreateToggle({
        Name = "Aimbot Enabled",
        CurrentValue = Settings.aimbotEnabled,
        Flag = "aimbotEnabled",
        Callback = function(Value) Settings.aimbotEnabled = Value end
    })
    GUI.Elements.Toggles["silentAimEnabled"] = AimbotTab:CreateToggle({
        Name = "Silent Aim",
        CurrentValue = Settings.silentAimEnabled,
        Flag = "silentAimEnabled",
        Callback = function(Value) Settings.silentAimEnabled = Value end
    })
    AimbotTab:CreateKeybind({
        Name = "Silent Aim Key",
        CurrentKeybind = getKeyName(Settings.silentAimKey),
        HoldToInteract = (Settings.silentAimKeyMode == "Hold"),
        Flag = "silentAimKey",
        Callback = function(Key) setKeybind(Key, Settings, "silentAimKey") end
    })
    AimbotTab:CreateDropdown({
        Name = "Silent Aim Mode",
        Options = {"Hold", "Toggle", "Always"},
        CurrentOption = {Settings.silentAimKeyMode},
        Flag = "silentAimKeyMode",
        Callback = function(Option) Settings.silentAimKeyMode = Option[1] end
    })

    AimbotTab:CreateSection("Magic Bullets")
    GUI.Elements.Toggles["magicBulletEnabled"] = AimbotTab:CreateToggle({
        Name = "Magic Bullet",
        CurrentValue = Settings.magicBulletEnabled,
        Flag = "magicBulletEnabled",
        Callback = function(Value) Settings.magicBulletEnabled = Value end
    })
    GUI.Elements.Toggles["magicBulletHouseCheck"] = AimbotTab:CreateToggle({
        Name = "Ignore Objects",
        CurrentValue = not Settings.magicBulletHouseCheck,
        Flag = "magicBulletHouseCheck",
        Callback = function(Value) Settings.magicBulletHouseCheck = not Value end
    })
    GUI.Elements.Toggles["visibleCheckEnabled"] = AimbotTab:CreateToggle({
        Name = "Visible Check",
        CurrentValue = Settings.visibleCheckEnabled,
        Flag = "visibleCheckEnabled",
        Callback = function(Value) Settings.visibleCheckEnabled = Value end
    })

    AimbotTab:CreateSection("Combat")
    GUI.Elements.Toggles["fastShootEnabled"] = AimbotTab:CreateToggle({
        Name = "Fast Shoot",
        CurrentValue = Settings.fastShootEnabled,
        Flag = "fastShootEnabled",
        Callback = function(Value) Settings.fastShootEnabled = Value end
    })
    GUI.Elements.Toggles["noRecoilEnabled"] = AimbotTab:CreateToggle({
        Name = "No Recoil",
        CurrentValue = Settings.noRecoilEnabled,
        Flag = "noRecoilEnabled",
        Callback = function(Value) Settings.noRecoilEnabled = Value end
    })
    GUI.Elements.Toggles["jumpShotEnabled"] = AimbotTab:CreateToggle({
        Name = "Jump Shot",
        CurrentValue = Settings.jumpShotEnabled,
        Flag = "jumpShotEnabled",
        Callback = function(Value) Settings.jumpShotEnabled = Value end
    })
    AimbotTab:CreateKeybind({
        Name = "Jump Shot Key",
        CurrentKeybind = getKeyName(Settings.jumpShotKey),
        HoldToInteract = false,
        Flag = "jumpShotKey",
        Callback = function(Key) setKeybind(Key, Settings, "jumpShotKey") end
    })

    AimbotTab:CreateSection("Anti-Aim")
    GUI.Elements.Toggles["antiAimEnabled"] = AimbotTab:CreateToggle({
        Name = "Anti-Aim Enabled",
        CurrentValue = Settings.antiAimEnabled,
        Flag = "antiAimEnabled",
        Callback = function(Value) Settings.antiAimEnabled = Value end
    })
    AimbotTab:CreateKeybind({
        Name = "Anti-Aim Key",
        CurrentKeybind = getKeyName(Settings.antiAimKey),
        HoldToInteract = false,
        Flag = "antiAimKey",
        Callback = function(Key) setKeybind(Key, Settings, "antiAimKey") end
    })
    AimbotTab:CreateDropdown({
        Name = "Anti-Aim Mode",
        Options = {"Spin", "Jitter", "Static"},
        CurrentOption = {Settings.antiAimMode},
        Flag = "antiAimMode",
        Callback = function(Option) Settings.antiAimMode = Option[1] end
    })
    AimbotTab:CreateSlider({
        Name = "Spin Speed",
        Range = {1, 100},
        Increment = 1,
        CurrentValue = Settings.antiAimSpeed,
        Flag = "antiAimSpeed",
        Callback = function(Value) Settings.antiAimSpeed = Value end
    })

    AimbotTab:CreateSection("Prediction")
    GUI.Elements.Toggles["ballisticsEnabled"] = AimbotTab:CreateToggle({
        Name = "Ballistics",
        CurrentValue = Settings.ballisticsEnabled,
        Flag = "ballisticsEnabled",
        Callback = function(Value) Settings.ballisticsEnabled = Value end
    })
    GUI.Elements.Toggles["projectilePredictionEnabled"] = AimbotTab:CreateToggle({
        Name = "Prediction",
        CurrentValue = Settings.projectilePredictionEnabled,
        Flag = "projectilePredictionEnabled",
        Callback = function(Value) Settings.projectilePredictionEnabled = Value end
    })
    AimbotTab:CreateSlider({
        Name = "Prediction Factor",
        Range = {0.1, 2.0},
        Increment = 0.1,
        CurrentValue = Settings.predictionFactor,
        Flag = "predictionFactor",
        Callback = function(Value) Settings.predictionFactor = Value end
    })
    AimbotTab:CreateSlider({
        Name = "Prediction Smooth",
        Range = {0.05, 1.0},
        Increment = 0.05,
        CurrentValue = Settings.predictionSmoothing,
        Flag = "predictionSmoothing",
        Callback = function(Value) Settings.predictionSmoothing = Value end
    })

    AimbotTab:CreateSection("Settings")
    GUI.Elements.Toggles["fovCircleEnabled"] = AimbotTab:CreateToggle({
        Name = "FOV Circle",
        CurrentValue = Settings.fovCircleEnabled,
        Flag = "fovCircleEnabled",
        Callback = function(Value) Settings.fovCircleEnabled = Value end
    })
    AimbotTab:CreateKeybind({
        Name = "Aim Key",
        CurrentKeybind = getKeyName(Settings.aimKey),
        HoldToInteract = (Settings.aimKeyMode == "Hold"),
        Flag = "aimKey",
        Callback = function(Key) setKeybind(Key, Settings, "aimKey") end
    })
    AimbotTab:CreateDropdown({
        Name = "Aim Mode",
        Options = {"Hold", "Toggle", "Always"},
        CurrentOption = {Settings.aimKeyMode},
        Flag = "aimKeyMode",
        Callback = function(Option) Settings.aimKeyMode = Option[1] end
    })
    AimbotTab:CreateSlider({
        Name = "Smoothness",
        Range = {0.01, 1.0},
        Increment = 0.01,
        CurrentValue = Settings.smoothness,
        Flag = "smoothness",
        Callback = function(Value) Settings.smoothness = Value end
    })
    AimbotTab:CreateSlider({
        Name = "FOV Size",
        Range = {10, 800},
        Increment = 1,
        CurrentValue = Settings.fovSize,
        Flag = "fovSize",
        Callback = function(Value) Settings.fovSize = Value end
    })
    AimbotTab:CreateDropdown({
        Name = "Target Priority",
        Options = {"Distance", "Crosshair", "Balanced"},
        CurrentOption = {Settings.targetPriority},
        Flag = "targetPriority",
        Callback = function(Option) Settings.targetPriority = Option[1] end
    })
    AimbotTab:CreateDropdown({
        Name = "Target Part",
        Options = {"Head", "Torso", "Legs"},
        CurrentOption = {Settings.targetPart},
        Flag = "targetPart",
        Callback = function(Option) Settings.targetPart = Option[1] end
    })

    
    local VisualsTab = GUI.Window:CreateTab("Visuals", 9134780101)
    
    VisualsTab:CreateSection("ESP")
    GUI.Elements.Toggles["espEnabled"] = VisualsTab:CreateToggle({
        Name = "ESP Enabled",
        CurrentValue = Settings.espEnabled,
        Flag = "espEnabled",
        Callback = function(Value) Settings.espEnabled = Value end
    })
    VisualsTab:CreateSlider({
        Name = "Max Distance",
        Range = {0, 2000},
        Increment = 10,
        CurrentValue = Settings.espMaxDistance,
        Flag = "espMaxDistance",
        Callback = function(Value) Settings.espMaxDistance = Value end
    })

    VisualsTab:CreateSection("Chams")
    GUI.Elements.Toggles["espHighlights"] = VisualsTab:CreateToggle({
        Name = "Chams",
        CurrentValue = Settings.espHighlights,
        Flag = "espHighlights",
        Callback = function(Value) Settings.espHighlights = Value end
    })
    VisualsTab:CreateDropdown({
        Name = "Chams Mode",
        Options = {"Default", "Glow", "Metal"},
        CurrentOption = {Settings.espChamsMode},
        Flag = "espChamsMode",
        Callback = function(Option) Settings.espChamsMode = Option[1] end
    })
    VisualsTab:CreateColorPicker({
        Name = "Fill Color",
        Color = Settings.espColor,
        Flag = "espColor",
        Callback = function(Value) Settings.espColor = Value end
    })
    VisualsTab:CreateColorPicker({
        Name = "Outline Color",
        Color = Settings.espOutlineColor,
        Flag = "espOutlineColor",
        Callback = function(Value) Settings.espOutlineColor = Value end
    })

    VisualsTab:CreateSection("Overlay")
    GUI.Elements.Toggles["espSkeleton"] = VisualsTab:CreateToggle({
        Name = "Skeleton",
        CurrentValue = Settings.espSkeleton,
        Flag = "espSkeleton",
        Callback = function(Value) Settings.espSkeleton = Value end
    })
    VisualsTab:CreateColorPicker({
        Name = "Skeleton Color",
        Color = Settings.espSkeletonColor,
        Flag = "espSkeletonColor",
        Callback = function(Value) Settings.espSkeletonColor = Value end
    })
    GUI.Elements.Toggles["espNames"] = VisualsTab:CreateToggle({
        Name = "Show Names",
        CurrentValue = Settings.espNames,
        Flag = "espNames",
        Callback = function(Value) Settings.espNames = Value end
    })
    GUI.Elements.Toggles["espDistances"] = VisualsTab:CreateToggle({
        Name = "Show Distance",
        CurrentValue = Settings.espDistances,
        Flag = "espDistances",
        Callback = function(Value) Settings.espDistances = Value end
    })
    GUI.Elements.Toggles["espWeapons"] = VisualsTab:CreateToggle({
        Name = "Show Weapon",
        CurrentValue = Settings.espWeapons,
        Flag = "espWeapons",
        Callback = function(Value) Settings.espWeapons = Value end
    })
    GUI.Elements.Toggles["espIcons"] = VisualsTab:CreateToggle({
        Name = "Show Icons",
        CurrentValue = Settings.espIcons,
        Flag = "espIcons",
        Callback = function(Value) Settings.espIcons = Value end
    })
    GUI.Elements.Toggles["espEnemySlots"] = VisualsTab:CreateToggle({
        Name = "Enemy Slots",
        CurrentValue = Settings.espEnemySlots,
        Flag = "espEnemySlots",
        Callback = function(Value) Settings.espEnemySlots = Value end
    })
    GUI.Elements.Toggles["espHealthBar"] = VisualsTab:CreateToggle({
        Name = "Healthbar",
        CurrentValue = Settings.espHealthBar,
        Flag = "espHealthBar",
        Callback = function(Value) Settings.espHealthBar = Value end
    })
    GUI.Elements.Toggles["espHealthBarText"] = VisualsTab:CreateToggle({
        Name = "Healthbar Text",
        CurrentValue = Settings.espHealthBarText,
        Flag = "espHealthBarText",
        Callback = function(Value) Settings.espHealthBarText = Value end
    })
    VisualsTab:CreateDropdown({
        Name = "Healthbar Pos",
        Options = {"Left", "Right", "Bottom", "Top"},
        CurrentOption = {Settings.espHealthBarPosition},
        Flag = "espHealthBarPosition",
        Callback = function(Option) Settings.espHealthBarPosition = Option[1] end
    })
    VisualsTab:CreateColorPicker({
        Name = "Text Color",
        Color = Settings.espTextColor,
        Flag = "espTextColor",
        Callback = function(Value) Settings.espTextColor = Value end
    })

    VisualsTab:CreateSection("World")
    GUI.Elements.Toggles["fullBrightEnabled"] = VisualsTab:CreateToggle({
        Name = "FullBright",
        CurrentValue = Settings.fullBrightEnabled,
        Flag = "fullBrightEnabled",
        Callback = function(Value) Settings.fullBrightEnabled = Value end
    })
    VisualsTab:CreateKeybind({
        Name = "FullBright Key",
        CurrentKeybind = getKeyName(Settings.FullBrightKey),
        HoldToInteract = false,
        Flag = "FullBrightKey",
        Callback = function(Key) setKeybind(Key, Settings, "FullBrightKey") end
    })

    
    local PlayerTab = GUI.Window:CreateTab("Player", 10747373176)
    
    PlayerTab:CreateSection("Helpers")
    GUI.Elements.Toggles["godModeEnabled"] = PlayerTab:CreateToggle({
        Name = "God Mode",
        CurrentValue = Settings.godModeEnabled,
        Flag = "godModeEnabled",
        Callback = function(Value) Settings.godModeEnabled = Value end
    })
    GUI.Elements.Toggles["spiderEnabled"] = PlayerTab:CreateToggle({
        Name = "Spider",
        CurrentValue = Settings.spiderEnabled,
        Flag = "spiderEnabled",
        Callback = function(Value) Settings.spiderEnabled = Value end
    })
    PlayerTab:CreateKeybind({
        Name = "Spider Key",
        CurrentKeybind = getKeyName(Settings.spiderKey),
        HoldToInteract = false,
        Flag = "spiderKey",
        Callback = function(Key) setKeybind(Key, Settings, "spiderKey") end
    })
    
    GUI.Elements.Toggles["speedHackEnabled"] = PlayerTab:CreateToggle({
        Name = "SpeedHack",
        CurrentValue = Settings.speedHackEnabled,
        Flag = "speedHackEnabled",
        Callback = function(Value) Settings.speedHackEnabled = Value end
    })
    PlayerTab:CreateKeybind({
        Name = "Speed Key",
        CurrentKeybind = getKeyName(Settings.speedHackKey),
        HoldToInteract = false,
        Flag = "speedHackKey",
        Callback = function(Key) setKeybind(Key, Settings, "speedHackKey") end
    })
    PlayerTab:CreateSlider({
        Name = "Speed Multiplier",
        Range = {1, 3},
        Increment = 0.1,
        CurrentValue = Settings.speedMultiplier,
        Flag = "speedMultiplier",
        Callback = function(Value) Settings.speedMultiplier = Value end
    })

    PlayerTab:CreateSection("Visuals")
    GUI.Elements.Toggles["noGrassEnabled"] = PlayerTab:CreateToggle({
        Name = "No Grass",
        CurrentValue = Settings.noGrassEnabled,
        Flag = "noGrassEnabled",
        Callback = function(Value) Settings.noGrassEnabled = Value end
    })
    GUI.Elements.Toggles["noFogEnabled"] = PlayerTab:CreateToggle({
        Name = "No Fog",
        CurrentValue = Settings.noFogEnabled,
        Flag = "noFogEnabled",
        Callback = function(Value) Settings.noFogEnabled = Value end
    })
    GUI.Elements.Toggles["thirdPersonEnabled"] = PlayerTab:CreateToggle({
        Name = "Third Person",
        CurrentValue = Settings.thirdPersonEnabled,
        Flag = "thirdPersonEnabled",
        Callback = function(Value) Settings.thirdPersonEnabled = Value end
    })
    PlayerTab:CreateSlider({
        Name = "TP Distance",
        Range = {5, 25},
        Increment = 1,
        CurrentValue = Settings.thirdPersonDistance,
        Flag = "thirdPersonDistance",
        Callback = function(Value) Settings.thirdPersonDistance = Value end
    })
    GUI.Elements.Toggles["freeCamEnabled"] = PlayerTab:CreateToggle({
        Name = "FreeCam",
        CurrentValue = Settings.freeCamEnabled,
        Flag = "freeCamEnabled",
        Callback = function(Value) Settings.freeCamEnabled = Value end
    })
    PlayerTab:CreateKeybind({
        Name = "FreeCam Key",
        CurrentKeybind = getKeyName(Settings.freeCamKey),
        HoldToInteract = false,
        Flag = "freeCamKey",
        Callback = function(Key) setKeybind(Key, Settings, "freeCamKey") end
    })

    PlayerTab:CreateSection("Hitbox")
    GUI.Elements.Toggles["hitboxExpanderEnabled"] = PlayerTab:CreateToggle({
        Name = "Hitbox Expander",
        CurrentValue = Settings.hitboxExpanderEnabled,
        Flag = "hitboxExpanderEnabled",
        Callback = function(Value) Settings.hitboxExpanderEnabled = Value end
    })
    GUI.Elements.Toggles["hitboxExpanderShow"] = PlayerTab:CreateToggle({
        Name = "Hitbox Visible",
        CurrentValue = Settings.hitboxExpanderShow,
        Flag = "hitboxExpanderShow",
        Callback = function(Value) Settings.hitboxExpanderShow = Value end
    })
    PlayerTab:CreateSlider({
        Name = "Expander Size",
        Range = {1, 30},
        Increment = 1,
        CurrentValue = Settings.hitboxExpanderSize,
        Flag = "hitboxExpanderSize",
        Callback = function(Value) Settings.hitboxExpanderSize = Value end
    })

    PlayerTab:CreateSection("Anti-AFK")
    GUI.Elements.Toggles["antiAfkEnabled"] = PlayerTab:CreateToggle({
        Name = "Anti-AFK Enabled",
        CurrentValue = Settings.antiAfkEnabled,
        Flag = "antiAfkEnabled",
        Callback = function(Value) 
            Settings.antiAfkEnabled = Value 
            if Value then
                Settings.antiAfkLastActionTime = tick()
            end
        end
    })
    PlayerTab:CreateSlider({
        Name = "Interval (Min)",
        Range = {1, 60},
        Increment = 1,
        CurrentValue = Settings.antiAfkInterval,
        Flag = "antiAfkInterval",
        Callback = function(Value) Settings.antiAfkInterval = Value end
    })
    local SettingsTab = GUI.Window:CreateTab("Settings", 7072721682)
    local MainSettings, ConfigsSide = SettingsTab:Split(0.55)
    
    
    local function getConfigsTable()
        if not GUI.ConfigManager then return {} end
        local configs = GUI.ConfigManager.List()
        return type(configs) == "table" and configs or {}
    end

    MainSettings:CreateSection("Config Creation")
    MainSettings:CreateInput({
        Name = "New Config Name",
        PlaceholderText = "shlepa228",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text) GUI.ConfigName = Text end
    })
    
    local function UpdateConfigList()
    end
    MainSettings:CreateButton({
         Name = "Save Current as New Config",
         Callback = function()
             if GUI.ConfigManager then
                 GUI.ConfigManager.Save(GUI.ConfigName, Settings)
                 GUI.UpdateConfigList(ConfigsSide, Settings)
                 GUI.Window:Notify({
                     Title = "Config Saved",
                     Content = "Configuration " .. GUI.ConfigName .. " has been successfully saved.",
                     Duration = 5,
                     Image = 4483362458
                 })
             	end
         end
     })
 
    GUI.UpdateConfigList(ConfigsSide, Settings)

    MainSettings:CreateSection("KeybinsList & Watermark")
    GUI.Elements.Toggles["watermarkEnabled"] = MainSettings:CreateToggle({
        Name = "Watermark",
        CurrentValue = Settings.watermarkEnabled,
        Flag = "watermarkEnabled",
        Callback = function(Value) 
            Settings.watermarkEnabled = Value 
            if GUI.Watermark.Frame then GUI.Watermark.Frame.Visible = Value end
            if GUI.KeybindList.Frame then GUI.KeybindList.Frame.Visible = Value end
        end
    })
    MainSettings:CreateKeybind({
        Name = "Menu Toggle",
        CurrentKeybind = getKeyName(Settings.toggleKey),
        HoldToInteract = false,
        Flag = "toggleKey",
        Callback = function(Key) setKeybind(Key, Settings, "toggleKey") end
    })

    MainSettings:CreateSection("System")
    MainSettings:CreateButton({
        Name = "Unload Script",
        Callback = function()
            if GUI.UnloadCallback then
                GUI.UnloadCallback()
            end
            GUI.Window:Destroy()
        end
    })
end

function GUI.UpdateConfigList(ConfigsSide, Settings)
    if ConfigsSide.Clear then
        ConfigsSide:Clear()
    end
    
    ConfigsSide:CreateSection("Configs")
    
    if GUI.ConfigManager then
        local configs = GUI.ConfigManager.List()
        if type(configs) == "table" then
            for _, name in pairs(configs) do    
                local ConfigButton = ConfigsSide:CreateButton({
                    Name = name,
                    Callback = function()
                        GUI.ConfigName = name
                    end
                })

                
                if ConfigButton and ConfigButton.Element then
                    local ButtonFrame = ConfigButton.Element
                    
                    local Controls = Instance.new("Frame")
                    Controls.Name = "Controls"
                    Controls.Size = UDim2.new(0, 60, 1, -6)
                    Controls.Position = UDim2.new(1, -65, 0, 3)
                    Controls.BackgroundTransparency = 1
                    Controls.Parent = ButtonFrame
                    
                    local Layout = Instance.new("UIListLayout")
                    Layout.FillDirection = Enum.FillDirection.Horizontal
                    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                    Layout.VerticalAlignment = Enum.VerticalAlignment.Center
                    Layout.Padding = UDim.new(0, 4)
                    Layout.Parent = Controls

                    
                    local function createIconButton(icon, color, callback)
                        local btn = Instance.new("ImageButton")
                        btn.Size = UDim2.new(0, 22, 0, 22)
                        btn.BackgroundTransparency = 1
                        btn.Image = "rbxassetid://" .. tostring(icon)
                        btn.ImageColor3 = color
                        btn.ZIndex = 10
                        btn.Parent = Controls
                        btn.MouseButton1Click:Connect(callback)
                        return btn
                    end

                    
                    createIconButton(11311025700, Color3.fromRGB(100, 255, 100), function()
                        GUI.ConfigManager.Load(name, Settings)
                        GUI.UpdateToggles(Settings)
                        GUI.Window:Notify({
                            Title = "Config Loaded",
                            Content = "Configuration " .. name .. " has been successfully loaded.",
                            Duration = 5,
                            Image = 4483362458
                        })
                    end)

                    
                    createIconButton(11311025587, Color3.fromRGB(255, 100, 100), function()
                        GUI.ConfigManager.Delete(name)
                        GUI.UpdateConfigList(ConfigsSide, Settings)
                        GUI.Window:Notify({
                            Title = "Config Deleted",
                            Content = "Configuration " .. name .. " has been deleted.",
                            Duration = 5,
                            Image = 4483362458
                        })
                    end)
                end
            end
        end
    end
end

function GUI.ToggleVisible(Settings)
    pcall(function()
        if GUI.Window.Toggle then
            GUI.Window:Toggle()
        end
    end)
end
function GUI.UpdateToggles(Settings)
    pcall(function()
        for flag, toggle in pairs(GUI.Elements.Toggles) do
            if toggle and toggle.Set then
                local value = Settings[flag]
                if flag == "magicBulletHouseCheck" then
                    value = not value
                end
                toggle:Set(value)
            end
        end
    end)
end

function GUI.UpdateWatermark(Settings)
    if not GUI.Watermark.Frame or not GUI.Watermark.Text then return end
    
    GUI.Watermark.Frame.Visible = Settings.watermarkEnabled
    if not Settings.watermarkEnabled then return end
    
    GUI.FrameCount = (GUI.FrameCount or 0) + 1
    local now = tick()
    if now - GUI.LastWatermarkUpdate < 1 then return end
    
    local deltaTime = now - GUI.LastWatermarkUpdate
    local fps = math.floor(GUI.FrameCount / deltaTime)
    GUI.LastWatermarkUpdate = now
    GUI.FrameCount = 0
    
    local ping = 0
    local playerName = LocalPlayer.DisplayName or LocalPlayer.Name
    
    pcall(function()
        local stats = game:GetService("Stats")
        if stats:FindFirstChild("Network") and stats.Network:FindFirstChild("ServerStatsItem") then
            ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
        end
    end)
    
    GUI.Watermark.Text.Text = string.format("Withonium | %s | %dms | %dfps", playerName, ping, fps)
end

function GUI.UpdateKeybindList(Settings)
    if not GUI.KeybindList.Frame or not GUI.KeybindList.Container then return end
    
    local container = GUI.KeybindList.Container
    local itemIndex = 0
    
    local function getOrCreateItem(name)
        itemIndex = itemIndex + 1
        local item = GUI.KeybindList.Items[itemIndex]
        
        if not item then
            item = {}
            item.Frame = Instance.new("Frame")
            item.Frame.BackgroundTransparency = 1
            item.Frame.Size = UDim2.new(1, 0, 0, 20)
            item.Frame.Parent = container
            
            item.NameLabel = Instance.new("TextLabel")
            item.NameLabel.BackgroundTransparency = 1
            item.NameLabel.Size = UDim2.new(0.4, 0, 1, 0)
            item.NameLabel.Font = Enum.Font.Gotham
            item.NameLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            item.NameLabel.TextSize = 13
            item.NameLabel.TextXAlignment = Enum.TextXAlignment.Left
            item.NameLabel.Parent = item.Frame
            
            item.StatusLabel = Instance.new("TextLabel")
            item.StatusLabel.BackgroundTransparency = 1
            item.StatusLabel.Position = UDim2.new(1, 0, 0, 0)
            item.StatusLabel.AnchorPoint = Vector2.new(1, 0)
            item.StatusLabel.Size = UDim2.new(0.6, 0, 1, 0)
            item.StatusLabel.Font = Enum.Font.GothamMedium
            item.StatusLabel.TextSize = 12
            item.StatusLabel.TextXAlignment = Enum.TextXAlignment.Right
            item.StatusLabel.Parent = item.Frame
            
            GUI.KeybindList.Items[itemIndex] = item
        end
        
        item.Frame.Visible = true
        return item
    end
    
    local hasItems = false
    local keybindList = {
        {Name = "Aimbot", Key = Settings.aimKey, Active = Settings.aimbotEnabled},
        {Name = "Silent Aim", Key = Settings.silentAimKey, Active = Settings.silentAimEnabled},
        {Name = "Spider", Key = Settings.spiderKey, Active = Settings.spiderEnabled},
        {Name = "Speed", Key = Settings.speedHackKey, Active = Settings.speedHackEnabled},
        {Name = "Jump Shot", Key = Settings.jumpShotKey, Active = Settings.jumpShotEnabled},
        {Name = "FreeCam", Key = Settings.freeCamKey, Active = Settings.freeCamEnabled},
        {Name = "Anti-Aim", Key = Settings.antiAimKey, Active = Settings.antiAimEnabled},
        {Name = "FullBright", Key = Settings.FullBrightKey, Active = Settings.fullBrightEnabled}
    }

    for _, bind in ipairs(keybindList) do
        if bind.Key and bind.Key ~= Enum.KeyCode.Unknown then
            local item = getOrCreateItem(bind.Name)
            item.NameLabel.Text = bind.Name
            item.StatusLabel.Text = string.format("[%s] [%s]", getKeyName(bind.Key), bind.Active and "Active" or "Disabled")
            item.StatusLabel.TextColor3 = bind.Active and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
            hasItems = true
        end
    end
    
    for i = itemIndex + 1, #GUI.KeybindList.Items do
        GUI.KeybindList.Items[i].Frame.Visible = false
    end
    
    GUI.KeybindList.Frame.Visible = Settings.watermarkEnabled and hasItems
end

function GUI.SwitchTab(tabName, Settings) end

return GUI
end

_modules["modules/Settings"] = function()
local Settings = {
    
    aimbotEnabled = false,
    visibleCheckEnabled = true,
    noRecoilEnabled = false,
    fastShootEnabled = false,
    jumpShotEnabled = false,
    jumpShotKey = Enum.KeyCode.Unknown,
    jumpShotKeyMode = "Toggle",
    
    fovCircleEnabled = true,
    smoothness = 0.08,
    predictionFactor = 1.0, 
    predictionSmoothing = 0.2, 
    projectilePredictionEnabled = true,
    projectileSpeed = 1000,
    projectileGravity = 196.2,
    fovSize = 90,
    targetPriority = "Distance", 
    aimKey = Enum.UserInputType.MouseButton1,
    aimKeyMode = "Hold", 
    targetPart = "Head", 
    silentAimKey = Enum.KeyCode.Unknown,
    silentAimKeyMode = "Toggle",

    magicBulletEnabled = false,
    magicBulletHouseCheck = true,
    
    spiderEnabled = false,
    spiderKey = Enum.KeyCode.Unknown,
    spiderKeyMode = "Toggle",

    speedHackEnabled = false,
    speedHackKey = Enum.KeyCode.Unknown,
    speedHackKeyMode = "Toggle",
    
    thirdPersonEnabled = false,
    thirdPersonDistance = 10,
    
    freeCamEnabled = false,
    freeCamKey = Enum.KeyCode.Unknown,
    freeCamKeyMode = "Toggle",

    FullBrightKey = Enum.KeyCode.Unknown,
    FullBrightKeyMode = "Toggle",
    speedMultiplier = 1,
    godModeEnabled = false,
    hitboxExpanderEnabled = false,
    hitboxExpanderSize = 5,
    hitboxExpanderShow = false,
    
    
    antiAimEnabled = false,
    antiAimMode = "Spin", 
    antiAimSpeed = 50,
    antiAimKey = Enum.KeyCode.Unknown,
    antiAimKeyMode = "Toggle",
    
    
    antiAfkEnabled = false,
    antiAfkInterval = 15, 
    antiAfkLastActionTime = tick(),
    
    
    ballisticsEnabled = true,
    bulletVelocity = 1000, 
    gravity = 196.2, 
    predictionFactor = 0.500, 
    predictionIterations = 20, 
    hitscanVelocityThreshold = 800, 
    espEnabled = true,
    espHighlights = false,
    espSkeleton = false,
    espNames = true,
    espDistances = true,
    espWeapons = true,
    espIcons = true,
    espEnemySlots = false,
    espHealthBar = false,
    espHealthBarText = true,
    espHealthBarPosition = "Left",
    espHealthBarAutoScale = true,
    espHealthBarBaseSize = 50,
    espHealthBarBaseWidth = 4,
    espHealthBarBaseDistance = 25,
    espHealthBarMinScale = 0.4,
    espHealthBarMaxScale = 1.0,
    espMaxDistance = 700, 
    espTextColor = Color3.fromRGB(255, 255, 255),
    espChamsMode = "Default", 
    espColor = Color3.fromRGB(255, 255, 255),
    espOutlineColor = Color3.fromRGB(255, 255, 255),
    espSkeletonColor = Color3.fromRGB(255, 255, 255),
    fullBrightEnabled = false,
    noGrassEnabled = false,
    noFogEnabled = false,

    
    guiVisible = true,
    watermarkEnabled = true,
    toggleKey = Enum.KeyCode.RightShift,
    logoId = "https://github.com/nihmadev/Withonium/raw/main/icon.png"
}

return Settings

end

_modules["modules/Utils"] = function()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Utils = {
    SharedRaycastParams = RaycastParams.new(),
    SharedFilterTable = {},
    BodyPartsCache = {}
}


Utils.SharedRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
Utils.SharedRaycastParams.IgnoreWater = true

function Utils.getCharacter(player)
    if not player then return nil end
    
    
    if player.Character then return player.Character end
    
    
    
    if game.PlaceId == 13253735473 or game.PlaceId == 8130299583 then
        local renv = getrenv and getrenv()
        if renv and renv._G then
            
            if renv._G.Character and renv._G.Character.character then
                if player == Players.LocalPlayer then
                    return renv._G.Character.character
                end
            end
        end
        
        
        local ignorePlayers = workspace:FindFirstChild("Ignore") and workspace.Ignore:FindFirstChild("Players")
        if ignorePlayers then
            local char = ignorePlayers:FindFirstChild(player.Name)
            if char and char:IsA("Model") then return char end
        end
    end
    
    return nil
end

function Utils.getScreenCenter()
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize / 2 or Vector2.new(0, 0)
end

function Utils.getBodyPart(character, partName)
    if not character then return nil end
    
    if partName == "Head" then
        return character:FindFirstChild("Head")
    elseif partName == "Torso" then
        
        
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Middle")
    elseif partName == "Legs" then
        return character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg") or character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg")
    end
    return character:FindFirstChild("Head")
end

function Utils.getAllBodyParts(character, partName)
    
    local parts = Utils.BodyPartsCache
    for k in pairs(parts) do parts[k] = nil end
    
    if not character then return parts end
    
    if partName == "Head" then
        local p = character:FindFirstChild("Head")
        if p then table.insert(parts, p) end
    elseif partName == "Torso" then
        local p1 = character:FindFirstChild("UpperTorso")
        local p2 = character:FindFirstChild("LowerTorso")
        local p3 = character:FindFirstChild("Torso")
        if p1 then table.insert(parts, p1) end
        if p2 then table.insert(parts, p2) end
        if p3 then table.insert(parts, p3) end
    elseif partName == "Legs" then
        for _, n in ipairs({"Left Leg", "Right Leg", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg"}) do
            local p = character:FindFirstChild(n)
            if p then table.insert(parts, p) end
        end
    end
    return parts
end

function Utils.isPartVisible(part, character)
    if not part or not character then return false end
    
    local camera = workspace.CurrentCamera
    if not camera then return false end
    
    local origin = camera.CFrame.Position
    local destination = part.Position
    local direction = (destination - origin)
    
    if direction.Magnitude < 0.1 then return true end
    
    
    local params = Utils.SharedRaycastParams
    local filter = Utils.SharedFilterTable
    
    
    for k in pairs(filter) do filter[k] = nil end
    
    
    if typeof(character) == "Instance" then
        table.insert(filter, character)
    end
    
    local localChar = Utils.getCharacter(LocalPlayer)
    if localChar then
        table.insert(filter, localChar)
    end
    
    if LocalPlayer.Character and LocalPlayer.Character ~= localChar then
        table.insert(filter, LocalPlayer.Character)
    end
    
    
    table.insert(filter, camera)
    local ignore = workspace:FindFirstChild("Ignore")
    if ignore then table.insert(filter, ignore) end
    
    params.FilterDescendantsInstances = filter
    
    
    local currentOrigin = origin + (direction.Unit * 0.1)
    local currentDirection = (destination - currentOrigin)
    
    for i = 1, 3 do 
        local result = workspace:Raycast(currentOrigin, currentDirection, params)
        if not result then return true end
        
        local hit = result.Instance
        local canPierce = false
        
        
        if hit.Transparency > 0.7 or not hit.CanCollide then
            canPierce = true
        else
            
            local name = hit.Name:lower()
            if name:find("grass") or name:find("leaf") or name:find("cloud") or name:find("effect") or name:find("particle") then
                canPierce = true
            end
        end
        
        if canPierce then
            table.insert(filter, hit)
            params.FilterDescendantsInstances = filter
            currentOrigin = result.Position + (direction.Unit * 0.01)
            currentDirection = (destination - currentOrigin)
            if currentDirection.Magnitude < 0.05 then return true end
        else
            return false
        end
    end
    
    return false
end

function Utils.isHouse(part)
    if not part or not part:IsA("BasePart") then return false end
    if not part.CanCollide then return false end
    
    local name = part.Name:lower()
    local parent = part.Parent
    local parentName = parent and parent.Name:lower() or ""
    
    
    if name:find("wall") or name:find("roof") or name:find("door") or 
       name:find("house") or name:find("building") or name:find("struct") or 
       parentName:find("house") or parentName:find("building") or parentName:find("struct") then
        return true
    end
    
    
    if parent and (parent:IsA("Folder") or parent:IsA("Model")) then
        if parentName:find("build") or parentName:find("house") or parentName:find("base") then
            return true
        end
    end
    
    return false
end

function Utils.MakeDraggable(topbarobject, object)
    local Dragging = nil
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    local function Update(input)
        local Delta = input.Position - DragStart
        local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
        object.Position = pos
    end

    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            Update(input)
        end
    end)
end

return Utils

end

_modules["modules/Visuals"] = function()
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

local Visuals = {
    Connections = {},
    NormalSettings = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient
    },
    FullBrightSettings = {
        Brightness = 1,
        ClockTime = 12,
        FogEnd = 786543,
        GlobalShadows = false,
        Ambient = Color3.fromRGB(178, 178, 178)
    },
    Enabled = false,
    NoFogEnabled = false,
    NoGrassEnabled = false,
    OriginalDecoration = false,
    HasDecorationProperty = false,
    OriginalAtmosphere = {
        Density = 0.3,
        Offset = 0.2,
        Glare = 0,
        Haze = 0,
        Visible = true
    }
}

function Visuals.Init(Settings)
    
    if Terrain then
        local success, val = pcall(function() return Terrain.Decoration end)
        if success then
            Visuals.HasDecorationProperty = true
            Visuals.OriginalDecoration = val
        end
    end

    
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        Visuals.OriginalAtmosphere = {
            Density = atmosphere.Density,
            Offset = atmosphere.Offset,
            Glare = atmosphere.Glare,
            Haze = atmosphere.Haze,
            Visible = true
        }
    end

    
    Visuals.NormalSettings = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient
    }

    
    local function setupWatcher(property, targetValue)
        local connection = Lighting:GetPropertyChangedSignal(property):Connect(function()
            if Visuals.Enabled then
                if Lighting[property] ~= targetValue then
                    Lighting[property] = targetValue
                end
            elseif Visuals.NoFogEnabled and (property == "FogEnd" or property == "FogStart") then
                if Lighting[property] ~= 1000000 then
                    Lighting[property] = 1000000
                end
            else
                
                Visuals.NormalSettings[property] = Lighting[property]
            end
        end)
        table.insert(Visuals.Connections, connection)
    end

    setupWatcher("Brightness", Visuals.FullBrightSettings.Brightness)
    setupWatcher("ClockTime", Visuals.FullBrightSettings.ClockTime)
    setupWatcher("FogEnd", 1000000)
    setupWatcher("FogStart", 1000000)
    setupWatcher("GlobalShadows", Visuals.FullBrightSettings.GlobalShadows)
    setupWatcher("Ambient", Visuals.FullBrightSettings.Ambient)

    
    task.spawn(function()
        while task.wait(1) do
            if not Visuals.Connections or #Visuals.Connections == 0 then break end 
            local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmosphere and Visuals.NoFogEnabled then
                if atmosphere.Density ~= 0 then atmosphere.Density = 0 end
                if atmosphere.Haze ~= 0 then atmosphere.Haze = 0 end
            end
        end
    end)

    
    if Terrain and Visuals.HasDecorationProperty then
        local connection = Terrain:GetPropertyChangedSignal("Decoration"):Connect(function()
            if Visuals.NoGrassEnabled then
                if Terrain.Decoration ~= false then
                    Terrain.Decoration = false
                end
            else
                Visuals.OriginalDecoration = Terrain.Decoration
            end
        end)
        table.insert(Visuals.Connections, connection)
    end
end

function Visuals.Update(Settings)
    
    if Settings.fullBrightEnabled ~= Visuals.Enabled then
        Visuals.Enabled = Settings.fullBrightEnabled
        
        if Visuals.Enabled then
            
            Lighting.Brightness = Visuals.FullBrightSettings.Brightness
            Lighting.ClockTime = Visuals.FullBrightSettings.ClockTime
            Lighting.FogEnd = Visuals.FullBrightSettings.FogEnd
            Lighting.FogStart = 0
            Lighting.GlobalShadows = Visuals.FullBrightSettings.GlobalShadows
            Lighting.Ambient = Visuals.FullBrightSettings.Ambient
        else
            
            Lighting.Brightness = Visuals.NormalSettings.Brightness
            Lighting.ClockTime = Visuals.NormalSettings.ClockTime
            Lighting.GlobalShadows = Visuals.NormalSettings.GlobalShadows
            Lighting.Ambient = Visuals.NormalSettings.Ambient
            
            if Settings.noFogEnabled then
                Lighting.FogEnd = 1000000
                Lighting.FogStart = 0
            else
                Lighting.FogEnd = Visuals.NormalSettings.FogEnd
            end
        end
    end

    
    if Settings.noFogEnabled ~= Visuals.NoFogEnabled then
        Visuals.NoFogEnabled = Settings.noFogEnabled
        
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if Visuals.NoFogEnabled then
            Lighting.FogEnd = 1000000
            Lighting.FogStart = 1000000
            if atmosphere then
                atmosphere.Density = 0
                atmosphere.Haze = 0
                atmosphere.Glare = 0
            end
        else
            Lighting.FogEnd = Visuals.NormalSettings.FogEnd
            Lighting.FogStart = 0
            if atmosphere and Visuals.OriginalAtmosphere then
                atmosphere.Density = Visuals.OriginalAtmosphere.Density
                atmosphere.Haze = Visuals.OriginalAtmosphere.Haze
                atmosphere.Glare = Visuals.OriginalAtmosphere.Glare
            end
        end
    end

    
    if Settings.noGrassEnabled ~= Visuals.NoGrassEnabled then
        Visuals.NoGrassEnabled = Settings.noGrassEnabled
        
        if Visuals.HasDecorationProperty then
            Terrain.Decoration = not Visuals.NoGrassEnabled
        end
        
        
        task.spawn(function()
            pcall(function()
                local grassNames = {"Grass", "TallGrass", "Shrub", "Bush"}
                local targetTransparency = Visuals.NoGrassEnabled and 1 or 0
                
                
                local allDescendants = workspace:GetDescendants()
                for i = 1, #allDescendants do
                    local v = allDescendants[i]
                    if v:IsA("BasePart") then
                        local name = v.Name:lower()
                        local isGrass = false
                        for j = 1, #grassNames do
                            if name:find(grassNames[j]:lower()) then
                                isGrass = true
                                break
                            end
                        end
                        
                        
                        if not isGrass then
                            local parent = v.Parent
                            if parent and parent:IsA("Model") then
                                local pName = parent.Name:lower()
                                for j = 1, #grassNames do
                                    if pName:find(grassNames[j]:lower()) then
                                        isGrass = true
                                        break
                                    end
                                end
                            end
                        end
                        
                        if isGrass then
                            v.Transparency = targetTransparency
                        end
                    end
                end
            end)
        end)
    end
end

function Visuals.Unload()
    for _, conn in ipairs(Visuals.Connections) do
        conn:Disconnect()
    end
    Visuals.Connections = {}
    
    
    Lighting.Brightness = Visuals.NormalSettings.Brightness
    Lighting.ClockTime = Visuals.NormalSettings.ClockTime
    Lighting.FogEnd = Visuals.NormalSettings.FogEnd
    Lighting.GlobalShadows = Visuals.NormalSettings.GlobalShadows
    Lighting.Ambient = Visuals.NormalSettings.Ambient

    
    if Terrain and Visuals.HasDecorationProperty then
        Terrain.Decoration = Visuals.OriginalDecoration
    end
end

return Visuals

end

_modules["modules/Aimbot/Exploits"] = function()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

local Exploits = {
    LastRecoilUpdate = 0,
    LastFastShootUpdate = 0,
    LastGodUpdate = 0,
    LastFreeCamUpdate = 0,
    LastTool = nil,
    LastRecoilTool = nil,
    OriginalFireRates = {}
}

function Exploits.ApplyFastShoot(Settings)
    local character = LocalPlayer.Character
    if not character then return end

    local tool = character:FindFirstChildOfClass("Tool")
    
    if not Settings.fastShootEnabled then 
        
        if next(Exploits.OriginalFireRates) ~= nil then
            for obj, originalValue in pairs(Exploits.OriginalFireRates) do
                if typeof(obj) == "Instance" and obj.Parent then
                    if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                        obj.Value = originalValue
                    end
                elseif type(obj) == "string" and obj:find("Attr_") then
                    
                    
                end
            end
            
            
            if tool then
                for name, originalValue in pairs(Exploits.OriginalFireRates) do
                    if type(name) == "string" and name:find("Attr_") then
                        local attrName = name:sub(6)
                        tool:SetAttribute(attrName, originalValue)
                    end
                end
            end
            Exploits.OriginalFireRates = {}
            Exploits.LastTool = nil
        end
        return 
    end
    
    if not tool then return end

    
    if Exploits.LastTool == tool then return end
    Exploits.LastTool = tool

    
    local rateKeywords = {"firerate", "rpm", "speed", "shotspersecond"}
    local delayKeywords = {"delay", "cooldown", "interval", "waittime", "recovery"}

    
    local attributes = tool:GetAttributes()
    for name, val in pairs(attributes) do
        if typeof(val) == "number" then
            local lowerName = name:lower()
            local isRate = false
            for _, kw in ipairs(rateKeywords) do
                if lowerName:find(kw) then isRate = true break end
            end
            
            local isDelay = false
            for _, kw in ipairs(delayKeywords) do
                if lowerName:find(kw) then isDelay = true break end
            end

            if isRate or isDelay then
                local attrKey = "Attr_" .. name
                if not Exploits.OriginalFireRates[attrKey] then
                    Exploits.OriginalFireRates[attrKey] = val
                    
                    if isRate then
                        tool:SetAttribute(name, val * (Settings.fastShootMultiplier or 2))
                    else
                        tool:SetAttribute(name, val / (Settings.fastShootMultiplier or 2))
                    end
                end
            end
        end
    end

    
    local function checkValues(container)
        for _, v in ipairs(container:GetChildren()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                local name = v.Name:lower()
                local isRate = false
                for _, kw in ipairs(rateKeywords) do
                    if name:find(kw) then isRate = true break end
                end
                
                local isDelay = false
                for _, kw in ipairs(delayKeywords) do
                    if name:find(kw) then isDelay = true break end
                end

                if isRate or isDelay then
                    if not Exploits.OriginalFireRates[v] then
                        Exploits.OriginalFireRates[v] = v.Value
                        
                        if isRate then
                            v.Value = v.Value * (Settings.fastShootMultiplier or 2)
                        else
                            v.Value = v.Value / (Settings.fastShootMultiplier or 2)
                        end
                    end
                end
            elseif v.Name == "Settings" or v.Name == "Config" or v.Name == "GunSettings" then
                checkValues(v)
            end
        end
    end
    checkValues(tool)
end

function Exploits.ApplyNoRecoil(Settings)
    if not Settings.noRecoilEnabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end

    
    
    
    
    if Exploits.LastRecoilTool == tool then return end
    Exploits.LastRecoilTool = tool
    
    
    local attributes = tool:GetAttributes()
    for name, _ in pairs(attributes) do
        local lowerName = name:lower()
        if lowerName:find("recoil") or lowerName:find("shake") or lowerName:find("sway") or lowerName:find("spread") then
            local val = tool:GetAttribute(name)
            if typeof(val) == "number" then
                tool:SetAttribute(name, 0)
            elseif typeof(val) == "Vector3" then
                tool:SetAttribute(name, Vector3.new(0, 0, 0))
            elseif typeof(val) == "Vector2" then
                tool:SetAttribute(name, Vector2.new(0, 0))
            end
        end
    end

    
    
    local function checkValues(container)
        for _, v in ipairs(container:GetChildren()) do
            if v:IsA("NumberValue") or v:IsA("Vector3Value") or v:IsA("Vector2Value") or v:IsA("IntValue") then
                local name = v.Name:lower()
                if name:find("recoil") or name:find("shake") or name:find("sway") or name:find("spread") then
                    if v:IsA("Vector3Value") then
                        v.Value = Vector3.new(0, 0, 0)
                    elseif v:IsA("Vector2Value") then
                        v.Value = Vector2.new(0, 0)
                    else
                        v.Value = 0
                    end
                end
            elseif v.Name == "Settings" or v.Name == "Config" or v.Name == "GunSettings" then
                checkValues(v)
            end
        end
    end
    checkValues(tool)

    
    local camera = workspace.CurrentCamera
    if camera then
        for _, v in ipairs(camera:GetChildren()) do
            if v.Name:lower():find("shake") or v.Name:lower():find("recoil") then
                if v:IsA("NumberValue") or v:IsA("Vector3Value") then
                    if v:IsA("Vector3Value") then
                        v.Value = Vector3.new(0, 0, 0)
                    else
                        v.Value = 0
                    end
                end
            end
        end
    end
end

function Exploits.ApplyJumpShot(Settings)
    if not Settings.jumpShotEnabled then return end
    
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
            humanoid:ChangeState(Enum.HumanoidStateType.Landed)
        end
    end
end

function Exploits.ApplySpider(Settings)
    if not Settings.spiderEnabled then return end
    
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if rootPart and humanoid and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {character}
        
        local camera = workspace.CurrentCamera
        local lookVector = camera and camera.CFrame.LookVector or rootPart.CFrame.LookVector
        local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
        
        local directions = {
            flatLook
        }
        
        local nearWall = false
        for _, dir in ipairs(directions) do
            local rayResult = workspace:Raycast(rootPart.Position, dir * 1.8, params)
            if rayResult then
                nearWall = true
                break
            end
        end
        
        if nearWall then
            rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 35, rootPart.Velocity.Z)
        end
    end
end

function Exploits.ApplySpeedHack(Settings)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if humanoid then
        if Settings.speedHackEnabled and Settings.speedMultiplier and Settings.speedMultiplier > 1 then
            humanoid.WalkSpeed = 16 * Settings.speedMultiplier
        elseif not Settings.speedHackEnabled and humanoid.WalkSpeed > 16 then
            humanoid.WalkSpeed = 16
        end
    end
end

function Exploits.ApplyFreeCam(Aimbot, Settings)
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    if Settings.freeCamEnabled then
        if not Aimbot.FreeCamActive then
            Aimbot.FreeCamActive = true
            Aimbot.OriginalCameraType = camera.CameraType
            Aimbot.OriginalCameraCFrame = camera.CFrame
            Aimbot.FreeCamPos = camera.CFrame.Position
            
            local x, y, z = camera.CFrame:ToEulerAnglesYXZ()
            Aimbot.FreeCamRot = Vector2.new(math.deg(x), math.deg(y))
            
            camera.CameraType = Enum.CameraType.Scriptable
            
            
            local character = LocalPlayer.Character
            if character then
                Exploits.OriginalCollision = {}
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        Exploits.OriginalCollision[part] = part.CanCollide
                        part.CanCollide = false
                    end
                end
            	end
        end
        
        local baseSpeed = 0.5
        local moveSpeed = baseSpeed * (Settings.speedMultiplier or 1)
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveSpeed = moveSpeed * 3
        end
        
        local moveVector = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + Vector3.new(0, 0, -1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector + Vector3.new(0, 0, 1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector + Vector3.new(-1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + Vector3.new(1, 0, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveVector = moveVector + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector = moveVector + Vector3.new(0, -1, 0) end
        
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local delta = UserInputService:GetMouseDelta()
            local sensitivity = 0.5
            Aimbot.FreeCamRot = Aimbot.FreeCamRot + Vector2.new(-delta.Y * sensitivity, -delta.X * sensitivity)
            Aimbot.FreeCamRot = Vector2.new(math.clamp(Aimbot.FreeCamRot.X, -89, 89), Aimbot.FreeCamRot.Y)
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        else
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
        
        local rotation = CFrame.Angles(0, math.rad(Aimbot.FreeCamRot.Y), 0) * CFrame.Angles(math.rad(Aimbot.FreeCamRot.X), 0, 0)
        Aimbot.FreeCamPos = Aimbot.FreeCamPos + (rotation * moveVector) * moveSpeed
        
        camera.CFrame = CFrame.new(Aimbot.FreeCamPos) * rotation
        
        
        if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCurrentPosition and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
        end
    else
        if Aimbot.FreeCamActive then
            Aimbot.FreeCamActive = false
            camera.CameraType = Aimbot.OriginalCameraType or Enum.CameraType.Custom
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            
            
            local character = LocalPlayer.Character
            if character and Exploits.OriginalCollision then
                for part, originalValue in pairs(Exploits.OriginalCollision) do
                    if part and part.Parent then
                        part.CanCollide = originalValue
                    end
                end
                Exploits.OriginalCollision = nil
            end
        end
    end
end

function Exploits.ApplyThirdPerson(Settings)
    if Settings.thirdPersonEnabled then
        local distance = Settings.thirdPersonDistance or 10
        LocalPlayer.CameraMaxZoomDistance = distance
        LocalPlayer.CameraMinZoomDistance = distance
        
        
        if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
            pcall(function() LocalPlayer.CameraMode = Enum.CameraMode.Classic end)
        end
    else
        
        if LocalPlayer.CameraMaxZoomDistance == (Settings.thirdPersonDistance or 10) then
            LocalPlayer.CameraMaxZoomDistance = 128
            LocalPlayer.CameraMinZoomDistance = 0.5
        end
    end
end

function Exploits.ApplyGodMode(Settings)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if not character or not humanoid then return end

    if Settings.godModeEnabled then
        if humanoid:GetStateEnabled(Enum.HumanoidStateType.Dead) then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        end
        
        
        local now = tick()
        if now - Exploits.LastGodUpdate >= 2 then
            Exploits.LastGodUpdate = now
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("TouchTransmitter") and not part:FindFirstAncestorWhichIsA("Tool") then
                    part:Destroy()
                end
            end
        end

        if humanoid.Health > 0 and humanoid.Health < 20 then
            humanoid.Health = 100
        end
    else
        if not humanoid:GetStateEnabled(Enum.HumanoidStateType.Dead) then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        end
    end
end

function Exploits.ApplyAntiAFK(Settings)
    if not Settings.antiAfkEnabled then return end
    
    local now = tick()
    if now - Settings.antiAfkLastActionTime >= (Settings.antiAfkInterval * 60) then
        Settings.antiAfkLastActionTime = now
        
        task.spawn(function()
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            
            
            local oldSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = math.max(oldSpeed, 24) 
            
            
            humanoid:Move(Vector3.new(0, 0, -1), true)
            task.wait(6)
            humanoid:Move(Vector3.new(0, 0, 0), true)
            
            task.wait(6)
            
            
            humanoid:Move(Vector3.new(0, 0, 1), true)
            task.wait(6)
            humanoid:Move(Vector3.new(0, 0, 0), true)
            
            
            humanoid.WalkSpeed = oldSpeed
            
            task.wait(6)
            
            
            humanoid.Jump = true
            task.wait(0.2)
            humanoid.Jump = false
            
            
            task.wait(0.5)
            humanoid.Jump = true
            task.wait(0.2)
            humanoid.Jump = false
        end)
    end
end

function Exploits.ApplyAntiAim(Settings)
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if not Settings.antiAimEnabled then 
        if humanoid then humanoid.AutoRotate = true end
        
        
        if rootPart then
            local rootJoint = rootPart:FindFirstChild("RootJoint") or (character:FindFirstChild("LowerTorso") and character.LowerTorso:FindFirstChild("Root"))
            if rootJoint then
                rootJoint.Transform = CFrame.new()
            end
        end
        return 
    end
    
    if not rootPart or not humanoid then return end
    
    
    if humanoid.AutoRotate then humanoid.AutoRotate = false end
    
    local speed = Settings.antiAimSpeed or 50
    local mode = Settings.antiAimMode or "Spin"
    
    
    local aaAngle = 0
    if mode == "Spin" then
        
        aaAngle = math.rad((tick() * (speed * 10)) % 360)
    elseif mode == "Jitter" then
        
        aaAngle = math.rad((tick() * 1000 % 200 < 100) and 90 or -90)
    elseif mode == "Static" then
        
        aaAngle = math.rad(180)
    end

    
    
    local camera = workspace.CurrentCamera
    local lookVector = camera.CFrame.LookVector
    local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
    
    
    local targetRotation = CFrame.new(Vector3.new(), flatLook) * CFrame.Angles(0, aaAngle, 0)
    rootPart.CFrame = CFrame.new(rootPart.Position) * targetRotation.Rotation

    
    
    local rootJoint = rootPart:FindFirstChild("RootJoint") or (character:FindFirstChild("LowerTorso") and character.LowerTorso:FindFirstChild("Root"))
    
    if rootJoint then
        
        
        rootJoint.Transform = CFrame.Angles(0, -aaAngle, 0)
    end
end
 
return Exploits

end

_modules["modules/Aimbot/Hitboxes"] = function()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Hitboxes = {
    lastHitboxUpdate = 0,
    OriginalProperties = {} 
}

function Hitboxes.UpdateHitboxes(Aimbot, Settings, Utils, ESP)
    if not Settings or not ESP then return end
    
    local now = tick()
    if now - Hitboxes.lastHitboxUpdate < 0.2 then return end
    Hitboxes.lastHitboxUpdate = now
    
    local function restorePart(part)
        if not part then return end
        local props = Hitboxes.OriginalProperties[part]
        if props then
            part.Size = props.Size
            part.Transparency = props.Transparency
            part.CanCollide = props.CanCollide
            local visual = part:FindFirstChild("HitboxVisual")
            if visual then visual:Destroy() end
            Hitboxes.OriginalProperties[part] = nil
        end
    end

    if not Settings.hitboxExpanderEnabled then
        for part, _ in pairs(Hitboxes.OriginalProperties) do
            restorePart(part)
        end
        return
    end
    
    local size = Settings.hitboxExpanderSize or 5
    local targetSize = Vector3.new(size, size, size)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Middle") or character:FindFirstChild("Torso")
            
            if not rootPart or (rootPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude > 300 then
                continue 
            end

            local parts = Utils.getAllBodyParts(character, Settings.targetPart)
            
            for _, part in ipairs(parts) do
                if part.Name == "HumanoidRootPart" then continue end
                
                if not Hitboxes.OriginalProperties[part] then
                    Hitboxes.OriginalProperties[part] = {
                        Size = part.Size,
                        Transparency = part.Transparency,
                        CanCollide = part.CanCollide
                    }
                end
                
                if part.Size ~= targetSize then
                    part.Size = targetSize
                    part.CanCollide = false 
                end

                if Settings.hitboxExpanderShow then
                    local selection = part:FindFirstChild("HitboxVisual")
                    if not selection then
                        selection = Instance.new("SelectionBox")
                        selection.Name = "HitboxVisual"
                        selection.LineThickness = 0.05
                        selection.Adornee = part
                        selection.Color3 = Color3.fromRGB(255, 0, 0)
                        selection.Transparency = 0.5
                        selection.Parent = part
                    end
                    selection.Visible = true
                    part.Transparency = 0.8
                else
                    local selection = part:FindFirstChild("HitboxVisual")
                    if selection then selection.Visible = false end
                    part.Transparency = Hitboxes.OriginalProperties[part].Transparency
                end
            end
        end
    end
    
    
    for part, props in pairs(Hitboxes.OriginalProperties) do
        local char = part and part.Parent
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        
        if not part or not char or not char.Parent or not humanoid or humanoid.Health <= 0 then
            
            pcall(function()
                if part and part.Parent then
                    part.Size = props.Size
                    part.Transparency = props.Transparency
                    part.CanCollide = props.CanCollide
                    local visual = part:FindFirstChild("HitboxVisual")
                    if visual then visual:Destroy() end
                end
            end)
            Hitboxes.OriginalProperties[part] = nil
        end
    end
end

return Hitboxes

end

_modules["modules/Aimbot/Hooks"] = function()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Hooks = {
    IsInitialized = false
}

function Hooks.InitHooks(Aimbot, Settings, Utils, Ballistics)
    if Hooks.IsInitialized then return end
    Hooks.IsInitialized = true
    
    local oldNamecall
    local insideHook = false
    
    
    local currentCharacter = nil
    local currentHumanoid = nil
    local currentTool = nil
    local isWeaponCache = false
    local lastWeaponCheck = 0
    local sharedRaycastParams = RaycastParams.new()
    sharedRaycastParams.FilterType = Enum.RaycastFilterType.Include
    sharedRaycastParams.IgnoreWater = true
    
    LocalPlayer.CharacterAdded:Connect(function(char)
        currentCharacter = char
        currentHumanoid = char:WaitForChild("Humanoid", 5)
    end)
    currentCharacter = LocalPlayer.Character
    currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")

    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        
        if checkcaller() or insideHook then return oldNamecall(self, ...) end
        
        local method = getnamecallmethod()
        local args = {...}
        
        
        if method == "GetState" and Settings.jumpShotEnabled then
            if self == currentHumanoid then
                return Enum.HumanoidStateType.Landed
            end
        end

        
        
        
        if Settings.silentAimEnabled and (Aimbot.IsAiming or Settings.aimKeyMode == "Always") then
            local target = Aimbot.SilentTarget
            if target and target.targetPart then
                
                local now = tick()
                if now - lastWeaponCheck > 0.1 then
                    lastWeaponCheck = now
                    insideHook = true
                    local char = currentCharacter or LocalPlayer.Character
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    if tool then
                        isWeaponCache = Ballistics.GetWeaponFromTool(tool)
                    else
                        isWeaponCache = false
                    end
                    insideHook = false
                end
                
                
                if isWeaponCache then
                    local cam = workspace.CurrentCamera
                    
                    
                    if method == "Raycast" and self == workspace then
                        local origin = args[1]
                        
                        
                        if typeof(origin) == "Vector3" and cam and (origin - cam.CFrame.Position).Magnitude < 50 then
                            
                            local predictedDir = Aimbot.GetProjectilePrediction(target, Settings, Ballistics, origin)
                            
                            
                            
                            local dist = (target.targetPart.Position - origin).Magnitude
                            local rayDist = dist * 1.5 
                            local direction = predictedDir * rayDist
                            
                            
                            if Settings.magicBulletEnabled then
                                
                                local targetChar = Utils.getCharacter(target.player)
                                if targetChar then
                                    
                                    sharedRaycastParams.FilterDescendantsInstances = {targetChar}
                                    return oldNamecall(self, origin, direction, sharedRaycastParams)
                                end
                            end
                            
                            return oldNamecall(self, origin, direction, args[3])
                        end
                    
                    
                    elseif (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhiteList") and self == workspace then
                        local ray = args[1]
                        
                        if typeof(ray) == "Ray" and cam and (ray.Origin - cam.CFrame.Position).Magnitude < 50 then
                            
                            local predictedDir = Aimbot.GetProjectilePrediction(target, Settings, Ballistics, ray.Origin)
                            local dist = (target.targetPart.Position - ray.Origin).Magnitude
                            local rayDist = dist * 1.5 
                            local newRay = Ray.new(ray.Origin, predictedDir * rayDist)
                            
                            
                            local hitPos = target.targetPart.Position
                            
                            
                            if Settings.magicBulletEnabled then
                                return target.targetPart, hitPos, Vector3.new(0, 1, 0), target.targetPart.Material
                            end
                            
                            if method == "FindPartOnRay" then
                                return oldNamecall(self, newRay, args[2], args[3], args[4])
                            elseif method == "FindPartOnRayWithIgnoreList" then
                                return oldNamecall(self, newRay, args[2], args[3], args[4])
                            elseif method == "FindPartOnRayWithWhiteList" then
                                return oldNamecall(self, newRay, args[2], args[3], args[4])
                            end
                        end
                    end
                end
            end
        end
        
        return oldNamecall(self, ...)
    end)
end

return Hooks

end

_modules["modules/Aimbot/Input"] = function()
local UserInputService = game:GetService("UserInputService")
local Input = {}

function Input.IsInputPressed(key)
    if not key then return false end
    if key.EnumType == Enum.KeyCode then
        return UserInputService:IsKeyDown(key)
    elseif key.EnumType == Enum.UserInputType then
        if key.Name:match("MouseButton") then
            return UserInputService:IsMouseButtonPressed(key)
        end
    end
    return false
end

return Input

end

_modules["modules/Aimbot/Prediction"] = function()
local Prediction = {}

function Prediction.GetProjectilePrediction(target, Settings, Ballistics, customOrigin)
    local camera = workspace.CurrentCamera
    local origin = customOrigin or (camera and camera.CFrame.Position) or Vector3.new(0, 0, 0)
    
    local targetPos = target.targetPart.Position
    local targetVelocity = target.velocity or Vector3.new(0, 0, 0)
    
    
    if target.player and target.player.Character then
        local humanoid = target.player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local moveDir = humanoid.MoveDirection
            if moveDir.Magnitude > 0.1 then
                
                
                
                local walkSpeed = humanoid.WalkSpeed or 16
                targetVelocity = Vector3.new(moveDir.X * walkSpeed, targetVelocity.Y, moveDir.Z * walkSpeed)
            end
        end
    end
    
    local v = Settings.projectileSpeed or 1000
    local g = Settings.projectileGravity or 196.2
    
    
    if Settings.ballisticsEnabled and Ballistics then
        local config = Ballistics.GetConfig()
        if config then
            v = config.velocity or v
            
            g = math.abs(config.gravity or g)
        end
    end
    
    
    v = math.max(v, 10)
    
    if not Settings.projectilePredictionEnabled then
        return (targetPos - origin).Unit
    end
    
    local dist = (targetPos - origin).Magnitude
    
    if dist < 0.5 then
        return (targetPos - origin).Unit
    end
    
    local pFactor = Settings.predictionFactor or 1
    local iterations = Settings.predictionIterations or 10 
    local gvec = Vector3.new(0, -g, 0)
    local hitscanThreshold = Settings.hitscanVelocityThreshold or 1500 
    local targetG = workspace.Gravity or 196.2
    
    
    if v >= hitscanThreshold then
        local t = dist / v
        local lead = targetVelocity * t * pFactor
        
        
        local maxLead = dist * 0.5
        if lead.Magnitude > maxLead then
            lead = lead.Unit * maxLead
        end
        
        local targetFall = Vector3.new(0, 0, 0)
        if target.isFreefalling then
            targetFall = Vector3.new(0, 0.5 * targetG * (t * t), 0)
        end
        
        local aimPoint = targetPos + lead - targetFall
        return (aimPoint - origin).Unit
    end
    
    
    local t = dist / v
    local dir
    
    
    t = math.min(t, 5) 

    for i = 1, iterations do
        local lead = targetVelocity * t * pFactor
        
        
        local maxLead = dist * 0.5
        if lead.Magnitude > maxLead then
            lead = lead.Unit * maxLead
        end
        
        
        local targetFall = Vector3.new(0, 0, 0)
        if target.isFreefalling then
            targetFall = Vector3.new(0, 0.5 * targetG * (t * t), 0)
        end
        
        
        local dropComp = g * 0.5 * (t * t)
        
        
        
        local maxDropComp = dist * 1.5 
        dropComp = math.min(dropComp, maxDropComp)
        
        local dropVec = Vector3.new(0, dropComp, 0)
        local aimPoint = targetPos + lead - targetFall + dropVec
        
        local toAim = aimPoint - origin
        local newDist = toAim.Magnitude
        
        if newDist < 0.01 then break end
        
        dir = toAim.Unit
        local newT = newDist / v
        
        
        newT = math.min(newT, 5)
        
        if math.abs(newT - t) < 0.0005 then
            t = newT
            break
        end
        t = newT
    end
    
    local finalDir = dir or (targetPos - origin).Unit
    
    
    if finalDir.X ~= finalDir.X or math.abs(finalDir.Y) > 0.999 then
        
        if dist > 0.1 then
            return (targetPos - origin).Unit
        end
    end

    return finalDir
end

return Prediction

end

_modules["modules/Aimbot/Targeting"] = function()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Targeting = {
    SharedRaycastParams = RaycastParams.new(),
    SharedFilter = {}
}


Targeting.SharedRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
Targeting.SharedRaycastParams.IgnoreWater = true

function Targeting.FindTarget(Settings, Utils, Aimbot)
    local bestTarget = nil
    local bestScore = math.huge
    local camera = workspace.CurrentCamera
    local screenCenter = Utils.getScreenCenter()
    
    local allPlayers = Players:GetPlayers()
    for i = 1, #allPlayers do
        local player = allPlayers[i]
        local character = Utils.getCharacter(player)
        if player ~= LocalPlayer and character then
            local humanoid = character:FindFirstChild("Humanoid")
            local targetObj = Utils.getBodyPart(character, Settings.targetPart)
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            if humanoid and humanoid.Health > 0 and rootPart then
                
                if not targetObj then targetObj = character:FindFirstChild("Head") end
                
                local isVisible = false
                local bestPart = targetObj
                
                if Settings.visibleCheckEnabled then
                    isVisible = Utils.isPartVisible(targetObj, character)
                    
                    if not isVisible and Settings.targetPart ~= "Torso" then
                        
                        local torso = Utils.getBodyPart(character, "Torso")
                        if torso and Utils.isPartVisible(torso, character) then
                            isVisible = true
                            bestPart = torso
                        end
                    end
                    
                    if not isVisible then
                        
                        local size = targetObj.Size * 0.4
                        local points = {
                            targetObj.Position + Vector3.new(size.X, size.Y, size.Z),
                            targetObj.Position + Vector3.new(-size.X, size.Y, size.Z),
                            targetObj.Position + Vector3.new(size.X, -size.Y, size.Z),
                            targetObj.Position + Vector3.new(size.X, size.Y, -size.Z)
                        }
                        
                        for _, p in ipairs(points) do
                            local tempPart = {Position = p}
                            if Utils.isPartVisible(tempPart, character) then
                                isVisible = true
                                break
                            end
                        end
                    end
                    
                    
                    if not isVisible and Settings.magicBulletEnabled then
                        if Settings.magicBulletHouseCheck then
                            
                            local cam = workspace.CurrentCamera
                            if cam then
                                local camPos = cam.CFrame.Position
                                local direction = (targetObj.Position - camPos)
                                local params = Targeting.SharedRaycastParams
                                
                                
                                local filter = Targeting.SharedFilter
                                for k in pairs(filter) do filter[k] = nil end
                                
                                table.insert(filter, character)
                                
                                local localChar = Utils.getCharacter(LocalPlayer)
                                if localChar then table.insert(filter, localChar) end
                                if LocalPlayer.Character and LocalPlayer.Character ~= localChar then
                                    table.insert(filter, LocalPlayer.Character)
                                end
                                table.insert(filter, cam)
                                
                                params.FilterDescendantsInstances = filter
                                
                                local rayResult = workspace:Raycast(camPos, direction, params)
                                
                                if not rayResult or not Utils.isHouse(rayResult.Instance) then
                                    isVisible = true
                                end
                            end
                        else
                            
                            isVisible = true
                        end
                    end
                else
                    isVisible = true
                end

                if isVisible then
                    local pos, onScreen = camera:WorldToViewportPoint(bestPart.Position)
                    
                    
                    
                    local baseFov = Settings.fovSize or 90
                    local currentFov = baseFov
                    
                    if Aimbot and Aimbot.CurrentTarget and Aimbot.CurrentTarget.player == player then
                        currentFov = currentFov * 1.5 
                    end
                    
                    if onScreen then
                        local screenDistance = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                        local worldDistance = (bestPart.Position - camera.CFrame.Position).Magnitude
                        
                        
                        local maxDistStuds = Settings.espMaxDistance or 700
                        if worldDistance <= maxDistStuds and screenDistance < currentFov then
                            local score = 0
                            local priority = Settings.targetPriority or "Distance"
                            
                            if priority == "Distance" then
                                score = worldDistance
                            elseif priority == "Crosshair" then
                                score = screenDistance
                            elseif priority == "Balanced" then
                                score = worldDistance * (1 + (screenDistance / (Settings.fovSize or 90)))
                            end

                            if score < bestScore then
                                bestScore = score
                                local humanoidState = humanoid:GetState()
                                local isFalling = (humanoidState == Enum.HumanoidStateType.Freefall or humanoidState == Enum.HumanoidStateType.Jumping)
                                
                                
                                if isFalling and math.abs(rootPart.Velocity.Y) < 1.5 then
                                    isFalling = false
                                end
                                
                                
                                local targetVel = rootPart.Velocity
                                if humanoid.MoveDirection.Magnitude > 0 then
                                    local moveDir = humanoid.MoveDirection
                                    local speed = humanoid.WalkSpeed
                                    
                                    targetVel = Vector3.new(moveDir.X * speed, targetVel.Y, moveDir.Z * speed)
                                end

                                bestTarget = {
                                    player = player,
                                    targetPart = bestPart,
                                    rootPart = rootPart,
                                    velocity = targetVel,
                                    lastPosition = bestPart.Position,
                                    distance = screenDistance,
                                    worldDistance = worldDistance,
                                    isFreefalling = isFalling,
                                    isVisible = isVisible 
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    
    return bestTarget
end

return Targeting

end

_modules["modules/ESP/Chams"] = function()
local State = require("modules/ESP/State")

local Chams = {}

function Chams.Update(player, character, humanoid, Settings, activeHighlights, maxHighlights)
    if Settings.espEnabled and Settings.espHighlights and character.Parent and humanoid and humanoid.Health > 0 and activeHighlights < maxHighlights then
        if not State.Highlights[player] or not State.Highlights[player].Parent then
            local highlight = Instance.new("Highlight")
            highlight.Name = player.Name
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = State.GetContainer()
            State.Highlights[player] = highlight
            
            
            for _, v in ipairs(character:GetChildren()) do
                if v:IsA("Accessory") then
                    local handle = v:FindFirstChild("Handle")
                    if handle then
                        handle.LocalTransparencyModifier = 0.5
                    end
                end
            end
        end
        
        local h = State.Highlights[player]
        h.Enabled = true
        h.Adornee = character
        
        
        if Settings.espChamsMode == "Glow" then
            h.FillTransparency = 0.5
            h.OutlineTransparency = 0
            h.FillColor = Settings.espColor
            h.OutlineColor = Settings.espColor
        elseif Settings.espChamsMode == "Metal" then
            h.FillTransparency = 0.2
            h.OutlineTransparency = 0.5
            h.FillColor = Settings.espColor:lerp(Color3.fromRGB(150, 150, 150), 0.5)
            h.OutlineColor = Settings.espOutlineColor
        else
            h.FillTransparency = 0.5
            h.OutlineTransparency = 0
            h.FillColor = Settings.espColor
            h.OutlineColor = Settings.espOutlineColor or Color3.new(1, 1, 1)
        end
        return true 
    else
        if State.Highlights[player] then
            State.Highlights[player].Enabled = false
        end
        return false
    end
end

function Chams.Cleanup(player)
    if State.Highlights[player] then
        State.Highlights[player].Enabled = false
    end
end

function Chams.Destroy(player)
    if State.Highlights[player] then
        State.Highlights[player]:Destroy()
        State.Highlights[player] = nil
    end
end

return Chams

end

_modules["modules/ESP/Healthbars"] = function()
local State = require("modules/ESP/State")

local Healthbars = {}

function Healthbars.Update(player, character, rootPart, humanoid, Settings, isWithinDistance)
    if Settings.espEnabled and isWithinDistance and Settings.espHealthBar and character and rootPart and humanoid and humanoid.Health > 0 and character.Parent then
        if not State.Healthbars[player] or not State.Healthbars[player].Parent then
            local bbg = Instance.new("BillboardGui")
            bbg.Name = "ESP_Healthbar"
            bbg.AlwaysOnTop = true
            bbg.LightInfluence = 0
            bbg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            bbg.Parent = State.GetContainer()
            
            local bg = Instance.new("Frame")
            bg.Name = "Background"
            bg.BackgroundColor3 = Color3.new(0, 0, 0)
            bg.BackgroundTransparency = 0.5
            bg.BorderSizePixel = 0
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.Parent = bbg
            
            local fill = Instance.new("Frame")
            fill.Name = "Fill"
            fill.BorderSizePixel = 0
            fill.ZIndex = 2
            fill.Parent = bg
            
            local text = Instance.new("TextLabel")
            text.Name = "HealthText"
            text.BackgroundTransparency = 1
            text.Font = Enum.Font.GothamBold
            text.TextColor3 = Color3.new(1, 1, 1)
            text.TextStrokeTransparency = 0
            text.TextSize = 10
            text.ZIndex = 3
            text.Parent = bg
            
            State.Healthbars[player] = bbg
        end
        
        local bbg = State.Healthbars[player]
        bbg.Enabled = true
        bbg.Adornee = rootPart
        
        local bg = bbg:FindFirstChild("Background")
        local fill = bg and bg:FindFirstChild("Fill")
        local text = bg and bg:FindFirstChild("HealthText")
        
        if bg and fill and text then
            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local position = Settings.espHealthBarPosition or "Left"
            
            local autoScale = (Settings.espHealthBarAutoScale == nil) and true or Settings.espHealthBarAutoScale
            local cam = workspace.CurrentCamera
            local distance = (cam and rootPart) and (cam.CFrame.Position - rootPart.Position).Magnitude or 1
            local baseDistance = Settings.espHealthBarBaseDistance or 25
            local minScale = Settings.espHealthBarMinScale or 0.4
            local maxScale = Settings.espHealthBarMaxScale or 1.0
            local fovFactor = cam and (70 / cam.FieldOfView) or 1
            local scale = 1
            if autoScale then
                scale = math.clamp((baseDistance / math.max(distance, 1)) * fovFactor, minScale, maxScale)
            end
            
            local baseLength = Settings.espHealthBarBaseSize or 50
            local baseThickness = Settings.espHealthBarBaseWidth or 4
            local lengthPx = math.max(1, math.floor(baseLength * scale + 0.5))
            local thicknessPx = math.max(1, math.floor(baseThickness * scale + 0.5))
            
            
            local color = Color3.fromHSV(healthPercent * 0.3, 1, 1)
            fill.BackgroundColor3 = color
            
            
            if Settings.espHealthBarText then
                text.Visible = true
                text.Text = math.floor(humanoid.Health)
            else
                text.Visible = false
            end
            
            
            if position == "Left" then
                bbg.Size = UDim2.new(0, thicknessPx, 0, lengthPx)
                bbg.StudsOffset = Vector3.new(-2.5, 0, 0)
                fill.Size = UDim2.new(1, 0, healthPercent, 0)
                fill.Position = UDim2.new(0, 0, 1 - healthPercent, 0)
                text.Size = UDim2.new(1, 0, 0, 10)
                text.Position = UDim2.new(0, 0, 0, -12)
            elseif position == "Right" then
                bbg.Size = UDim2.new(0, thicknessPx, 0, lengthPx)
                bbg.StudsOffset = Vector3.new(2.5, 0, 0)
                fill.Size = UDim2.new(1, 0, healthPercent, 0)
                fill.Position = UDim2.new(0, 0, 1 - healthPercent, 0)
                text.Size = UDim2.new(1, 0, 0, 10)
                text.Position = UDim2.new(0, 0, 0, -12)
            elseif position == "Bottom" then
                bbg.Size = UDim2.new(0, lengthPx, 0, thicknessPx)
                bbg.StudsOffset = Vector3.new(0, -3.5, 0)
                fill.Size = UDim2.new(healthPercent, 0, 1, 0)
                fill.Position = UDim2.new(0, 0, 0, 0)
                text.Size = UDim2.new(0, 20, 1, 0)
                text.Position = UDim2.new(1, 2, 0, 0)
                text.TextXAlignment = Enum.TextXAlignment.Left
            elseif position == "Top" then
                bbg.Size = UDim2.new(0, lengthPx, 0, thicknessPx)
                bbg.StudsOffset = Vector3.new(0, 3.5, 0)
                fill.Size = UDim2.new(healthPercent, 0, 1, 0)
                fill.Position = UDim2.new(0, 0, 0, 0)
                text.Size = UDim2.new(0, 20, 1, 0)
                text.Position = UDim2.new(1, 2, 0, 0)
                text.TextXAlignment = Enum.TextXAlignment.Left
            end
        end
    else
        if State.Healthbars[player] then
            State.Healthbars[player].Enabled = false
        end
    end
end

function Healthbars.Cleanup(player)
    if State.Healthbars[player] then
        State.Healthbars[player].Enabled = false
    end
end

function Healthbars.Destroy(player)
    if State.Healthbars[player] then
        State.Healthbars[player]:Destroy()
        State.Healthbars[player] = nil
    end
end

return Healthbars

end

_modules["modules/ESP/Labels"] = function()
local State = require("modules/ESP/State")

local Labels = {}

function Labels.Update(player, character, rootPart, humanoid, Settings, distance, isWithinDistance)
    if Settings.espEnabled and isWithinDistance and (Settings.espNames or Settings.espDistances or Settings.espWeapons) and character and rootPart and humanoid and humanoid.Health > 0 and character.Parent then
        if not State.Labels[player] or not State.Labels[player].Parent then
            local bbg = Instance.new("BillboardGui")
            bbg.Name = "ESP_Label"
            bbg.AlwaysOnTop = true
            bbg.LightInfluence = 0
            bbg.Size = UDim2.new(0, 250, 0, 150)
            bbg.StudsOffset = Vector3.new(0, 3, 0)
            bbg.Parent = State.GetContainer()
            
            local container = Instance.new("Frame")
            container.Name = "Container"
            container.BackgroundTransparency = 1
            container.Size = UDim2.new(1, 0, 1, 0)
            container.Parent = bbg
            
            local layout = Instance.new("UIListLayout")
            layout.Parent = container
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 2)
            
            local enemySlotsFrame = Instance.new("Frame")
            enemySlotsFrame.Name = "EnemySlotsFrame"
            enemySlotsFrame.BackgroundTransparency = 1
            enemySlotsFrame.Size = UDim2.new(1, 0, 0, 45)
            enemySlotsFrame.LayoutOrder = 0
            enemySlotsFrame.Parent = container

            local uiScale = Instance.new("UIScale")
            uiScale.Name = "UIScale"
            uiScale.Parent = enemySlotsFrame

            local slotsLayout = Instance.new("UIListLayout")
            slotsLayout.Parent = enemySlotsFrame
            slotsLayout.FillDirection = Enum.FillDirection.Horizontal
            slotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            slotsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
            slotsLayout.Padding = UDim.new(0, 4)

            for i = 1, 6 do
                local slot = Instance.new("Frame")
                slot.Name = "Slot" .. i
                slot.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                slot.BackgroundTransparency = 0.5
                slot.BorderSizePixel = 1
                slot.Size = UDim2.new(0, 32, 0, 32)
                slot.Parent = enemySlotsFrame

                local icon = Instance.new("ImageLabel")
                icon.Name = "Icon"
                icon.BackgroundTransparency = 1
                icon.Size = UDim2.new(1, -4, 1, -4)
                icon.Position = UDim2.new(0, 2, 0, 2)
                icon.ScaleType = Enum.ScaleType.Fit
                icon.ZIndex = 3
                icon.Parent = slot

                local name = Instance.new("TextLabel")
                name.Name = "Name"
                name.BackgroundTransparency = 1
                name.Position = UDim2.new(0.5, 0, 1, 2)
                name.AnchorPoint = Vector2.new(0.5, 0)
                name.Size = UDim2.new(1, 10, 0, 10)
                name.Font = Enum.Font.Gotham
                name.TextColor3 = Color3.new(1, 1, 1)
                name.TextSize = 8
                name.TextStrokeTransparency = 0
                name.ZIndex = 3
                name.Parent = slot
            end
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "NameLabel"
            nameLabel.BackgroundTransparency = 1
            nameLabel.Size = UDim2.new(1, 0, 0, 20)
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextColor3 = Settings.espTextColor
            nameLabel.TextSize = 14
            nameLabel.TextStrokeTransparency = 0
            nameLabel.LayoutOrder = 1
            nameLabel.ZIndex = 2
            nameLabel.Parent = container
            
            local distLabel = Instance.new("TextLabel")
            distLabel.Name = "DistLabel"
            distLabel.BackgroundTransparency = 1
            distLabel.Size = UDim2.new(1, 0, 0, 15)
            distLabel.Font = Enum.Font.Gotham
            distLabel.TextColor3 = Settings.espTextColor
            distLabel.TextSize = 12
            distLabel.TextStrokeTransparency = 0
            distLabel.LayoutOrder = 2
            distLabel.ZIndex = 2
            distLabel.Parent = container

            local weaponFrame = Instance.new("Frame")
            weaponFrame.Name = "WeaponFrame"
            weaponFrame.BackgroundTransparency = 1
            weaponFrame.Size = UDim2.new(1, 0, 0, 22)
            weaponFrame.LayoutOrder = 3
            weaponFrame.Parent = container
            
            local weaponLayout = Instance.new("UIListLayout")
            weaponLayout.Parent = weaponFrame
            weaponLayout.FillDirection = Enum.FillDirection.Horizontal
            weaponLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            weaponLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            weaponLayout.Padding = UDim.new(0, 6)

            local weaponIcon = Instance.new("ImageLabel")
            weaponIcon.Name = "WeaponIcon"
            weaponIcon.BackgroundTransparency = 1
            weaponIcon.Size = UDim2.new(0, 18, 0, 18)
            weaponIcon.ZIndex = 2
            weaponIcon.ScaleType = Enum.ScaleType.Fit
            weaponIcon.Parent = weaponFrame

            local weaponLabel = Instance.new("TextLabel")
            weaponLabel.Name = "WeaponLabel"
            weaponLabel.BackgroundTransparency = 1
            weaponLabel.Size = UDim2.new(0, 0, 1, 0)
            weaponLabel.AutomaticSize = Enum.AutomaticSize.X
            weaponLabel.Font = Enum.Font.GothamMedium
            weaponLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            weaponLabel.TextSize = 12
            weaponLabel.TextStrokeTransparency = 0
            weaponLabel.ZIndex = 2
            weaponLabel.Parent = weaponFrame
            
            State.Labels[player] = bbg
        end
        
        local bbg = State.Labels[player]
        bbg.Enabled = true
        bbg.Adornee = rootPart
        
        local container = bbg:FindFirstChild("Container")
        if container then
            local enemySlotsFrame = container:FindFirstChild("EnemySlotsFrame")
            if enemySlotsFrame then
                local uiScale = enemySlotsFrame:FindFirstChild("UIScale")
                if uiScale then
                    local baseDist = 60
                    local scale = math.clamp(baseDist / math.max(distance, 1), 0.5, 1.2)
                    uiScale.Scale = scale
                end
            end

            local nameLabel = container:FindFirstChild("NameLabel")
            local distLabel = container:FindFirstChild("DistLabel")
            local weaponFrame = container:FindFirstChild("WeaponFrame")
            
            if Settings.espNames and nameLabel then
                nameLabel.Visible = true
                nameLabel.Text = player.DisplayName or player.Name
                nameLabel.TextColor3 = Settings.espTextColor
            elseif nameLabel then
                nameLabel.Visible = false
            end
            
            if Settings.espDistances and distLabel then
                distLabel.Visible = true
                distLabel.Text = string.format("[%d studs]", math.floor(distance))
                distLabel.TextColor3 = Settings.espTextColor
            elseif distLabel then
                distLabel.Visible = false
            end

            if Settings.espWeapons and weaponFrame then
                local weaponLabel = weaponFrame:FindFirstChild("WeaponLabel")
                local weaponIcon = weaponFrame:FindFirstChild("WeaponIcon")
                local tool = character:FindFirstChildWhichIsA("Tool")
                
                weaponFrame.Visible = true
                if weaponLabel then
                    weaponLabel.Text = tool and tool.Name or "None"
                end
                
                if weaponIcon then
                    if Settings.espIcons and tool and tool.TextureId ~= "" then
                        weaponIcon.Visible = true
                        weaponIcon.Image = tool.TextureId
                    else
                        weaponIcon.Visible = false
                    end
                end
            elseif weaponFrame then
                weaponFrame.Visible = false
            end

            if Settings.espEnemySlots and enemySlotsFrame then
                enemySlotsFrame.Visible = true
                local items = {}
                
                
                
                local lastItemUpdate = bbg:GetAttribute("LastItemUpdate") or 0
                local now = tick()
                
                if now - lastItemUpdate > 1 then
                    bbg:SetAttribute("LastItemUpdate", now)
                    
                    
                    local equipped = character:FindFirstChildWhichIsA("Tool")
                    if equipped then
                        table.insert(items, equipped)
                    end
                    
                    
                    local backpack = player:FindFirstChild("Backpack")
                    if backpack then
                        local backpackChildren = backpack:GetChildren()
                        for j = 1, #backpackChildren do
                            local item = backpackChildren[j]
                            if item:IsA("Tool") and #items < 6 then
                                table.insert(items, item)
                            end
                        end
                    end
                    
                    for i = 1, 6 do
                        local slot = enemySlotsFrame:FindFirstChild("Slot" .. i)
                        if slot then
                            local item = items[i]
                            local icon = slot:FindFirstChild("Icon")
                            local name = slot:FindFirstChild("Name")
                            
                            if item then
                                slot.Visible = true
                                if icon then
                                    if item.TextureId ~= "" then
                                        icon.Visible = true
                                        icon.Image = item.TextureId
                                    else
                                        icon.Visible = false
                                    end
                                end
                                if name then
                                    name.Text = item.Name
                                end
                            else
                                slot.Visible = false
                            end
                        end
                    end
                end
            elseif enemySlotsFrame then
                enemySlotsFrame.Visible = false
            end
        end
    else
        if State.Labels[player] then
            State.Labels[player].Enabled = false
        end
    end
end

function Labels.Cleanup(player)
    if State.Labels[player] then
        State.Labels[player].Enabled = false
    end
end

function Labels.Destroy(player)
    if State.Labels[player] then
        State.Labels[player]:Destroy()
        State.Labels[player] = nil
    end
end

return Labels

end

_modules["modules/ESP/Skeleton"] = function()
local State = require("modules/ESP/State")

local Skeleton = {}

local R15_BONES = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

local R6_BONES = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

function Skeleton.Draw(player, character, Settings)
    if not State.Skeletons[player] then
        State.Skeletons[player] = {}
    end

    local skeleton = State.Skeletons[player]
    local isR15 = character:FindFirstChild("UpperTorso") ~= nil
    local bones = isR15 and R15_BONES or R6_BONES

    
    if #skeleton > #bones then
        for i = #bones + 1, #skeleton do
            skeleton[i]:Destroy()
            skeleton[i] = nil
        end
    end

    for i, bonePair in ipairs(bones) do
        local part1 = character:FindFirstChild(bonePair[1])
        local part2 = character:FindFirstChild(bonePair[2])

        if part1 and part2 then
            if not skeleton[i] then
                local line = Instance.new("LineHandleAdornment")
                line.Name = "BoneLine_" .. i
                line.Length = 0
                line.Thickness = 2
                line.ZIndex = 10
                line.AlwaysOnTop = true
                line.Transparency = 0
                line.Parent = State.GetContainer()
                skeleton[i] = line
            end

            local line = skeleton[i]
            local p1 = part1.Position
            local p2 = part2.Position
            local dist = (p1 - p2).Magnitude

            line.Visible = true
            line.Color3 = Settings.espSkeletonColor
            line.Transparency = 0
            line.Adornee = part1
            line.CFrame = CFrame.lookAt(Vector3.new(0, 0, 0), part1.CFrame:PointToObjectSpace(p2))
            line.Length = dist
        else
            if skeleton[i] then
                skeleton[i].Visible = false
            end
        end
    end
end

function Skeleton.Cleanup(player)
    if State.Skeletons[player] then
        for _, line in pairs(State.Skeletons[player]) do
            line.Visible = false
        end
    end
end

function Skeleton.Destroy(player)
    if State.Skeletons[player] then
        for _, line in pairs(State.Skeletons[player]) do
            line:Destroy()
        end
        State.Skeletons[player] = nil
    end
end

return Skeleton

end

_modules["modules/ESP/State"] = function()
local CoreGui = game:GetService("CoreGui")

local State = {
    Data = {},
    Highlights = {},
    Labels = {},
    Skeletons = {},
    Healthbars = {},
    Container = nil
}

function State.GetContainer()
    if not State.Container or not State.Container.Parent then
        local success, folder = pcall(function()
            local f = Instance.new("Folder")
            f.Name = "WithoniumESP"
            f.Parent = (gethui and gethui()) or CoreGui
            return f
        end)
        if success then
            State.Container = folder
        end
    end
    return State.Container
end

function State.Create(player)
    if not State.Data[player] then
        State.Data[player] = {
            LastCharacter = nil
        }
    end
end

return State

end

_require = function(p)
    if _cache[p] then return _cache[p] end
    if _modules[p] then
        local s, r = pcall(_modules[p])
        if s then
            _cache[p] = r
            return r
        else
            error('Err: ' .. tostring(r))
        end
    end
    error('Not found: ' .. tostring(p))
end

local Modules = {
    ["Settings"] = _require("modules/Settings"),
    ["Utils"] = _require("modules/Utils"),
    ["ESP"] = _require("modules/ESP"),
    ["Aimbot"] = _require("modules/Aimbot"),
    ["GUI"] = _require("modules/GUI"),
    ["Visuals"] = _require("modules/Visuals"),
    ["Ballistics"] = _require("modules/Ballistics"),
    ["ConfigManager"] = _require("modules/ConfigManager")
}

local Main = (function()
local function log(msg)
    pcall(function()
        warn("[LOG] " .. tostring(msg))
        if rconsoleprint then rconsoleprint("[LOG] " .. tostring(msg) .. "\n") end
    end)
end

log("Initializing core engine...")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

local Main = {
    Connections = {},
    Modules = {}
}

function Main.Init(Modules)
    log("Loading resources...")
    Main.Modules = Modules
    local Settings = Modules.Settings
    local Utils = Modules.Utils
    local ESP = Modules.ESP
    local Aimbot = Modules.Aimbot
    local GUI = Modules.GUI
    local ConfigManager = Modules.ConfigManager
    local Ballistics = Modules.Ballistics
    local Visuals = Modules.Visuals

    -- Async initialization to prevent hanging
    task.spawn(function()
        -- Initialize ConfigManager
        if ConfigManager then
            pcall(function()
                ConfigManager.Init()
                ConfigManager.Load("autoload", Settings)
            end)
        end

        -- Initialize Visuals
        if Visuals then
            pcall(function() Visuals.Init(Settings) end)
        end

        -- Initialize GUI
        log("Setting up view...")
        local success_gui, err_gui = pcall(function()
            GUI.Init(Settings, Utils, function()
                Main.Unload()
            end, ConfigManager)
        end)
        if not success_gui then
            log("View error: " .. tostring(err_gui))
        else
            log("GUI initialized successfully")
        end

        log("Finalizing engine...")
    end)

    -- Set initial cursor state
    UserInputService.MouseIconEnabled = Settings.guiVisible



    -- Function Keybind Handling
    local function handleKeybind(input, isBegan)
        local keyCode = input.KeyCode
        local inputType = input.UserInputType
        
        -- Ignore input if typing in a TextBox
        if UserInputService:GetFocusedTextBox() then return end
        
        local keybinds = {
            {Key = Settings.silentAimKey, Mode = Settings.silentAimKeyMode, Setting = "silentAimEnabled", Name = "Silent Aim"},
            {Key = Settings.spiderKey, Mode = Settings.spiderKeyMode, Setting = "spiderEnabled", Name = "Spider"},
            {Key = Settings.speedHackKey, Mode = Settings.speedHackKeyMode, Setting = "speedHackEnabled", Name = "Speed"},
            {Key = Settings.freeCamKey, Mode = Settings.freeCamKeyMode, Setting = "freeCamEnabled", Name = "FreeCam"},
            {Key = Settings.jumpShotKey, Mode = Settings.jumpShotKeyMode, Setting = "jumpShotEnabled", Name = "Jump Shot"},
            {Key = Settings.FullBrightKey, Mode = Settings.FullBrightKeyMode, Setting = "fullBrightEnabled", Name = "FullBright"},
            {Key = Settings.antiAimKey, Mode = Settings.antiAimKeyMode, Setting = "antiAimEnabled", Name = "Anti-Aim"}
        }
        
        local updated = false
        for _, bind in ipairs(keybinds) do
            if bind.Key ~= Enum.KeyCode.Unknown and (keyCode == bind.Key or inputType == bind.Key) then
                if bind.Mode == "Toggle" then
                    if isBegan then
                        Settings[bind.Setting] = not Settings[bind.Setting]
                        updated = true
                        log("Toggled " .. bind.Name .. ": " .. tostring(Settings[bind.Setting]))
                    end
                elseif bind.Mode == "Hold" then
                    if Settings[bind.Setting] ~= isBegan then
                        Settings[bind.Setting] = isBegan
                        updated = true
                        log(bind.Name .. " (Hold): " .. tostring(isBegan))
                    end
                elseif bind.Mode == "Always" then
                    if not Settings[bind.Setting] then
                        Settings[bind.Setting] = true
                        updated = true
                        log(bind.Name .. " set to Always Active")
                    end
                end
            end
        end
        
        -- Refresh GUI if state changed and it's visible
        if updated and Settings.guiVisible and GUI then
            if GUI.UpdateToggles then
                GUI.UpdateToggles(Settings)
            end
        end
    end

    -- Toggle GUI Visibility
    table.insert(Main.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and (input.KeyCode == Settings.toggleKey or input.UserInputType == Settings.toggleKey) then
            if GUI and GUI.ToggleVisible then
                GUI.ToggleVisible(Settings)
            else
                Settings.guiVisible = not Settings.guiVisible
            end
            
            pcall(function()
                if Settings.guiVisible then
                    UserInputService.MouseIconEnabled = true
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                else
                    UserInputService.MouseIconEnabled = false
                    -- Restore mouse behavior for FPS games
                    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                end
            end)
        end
        -- We handle processed ourselves for function keybinds (except for toggleKey)
        handleKeybind(input, true)
    end))

    table.insert(Main.Connections, UserInputService.InputEnded:Connect(function(input, processed)
        handleKeybind(input, false)
    end))

    -- Main Loop
    local lastGuiUpdate = 0
    local lastVisualsUpdate = 0
    local lastErrorTime = 0
    
    RunService:BindToRenderStep("WithoniumUpdate", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
        -- Aimbot must run every frame for smoothness
        local success_aim, err_aim = pcall(function()
            Aimbot.Update(deltaTime, Settings, Utils, Ballistics, ESP)
        end)
        if not success_aim then 
            if tick() - lastErrorTime > 5 then
                lastErrorTime = tick()
                log("Aimbot update error: " .. tostring(err_aim)) 
            end
        end

        -- ESP can run at slightly lower frequency (e.g. 30-60 FPS)
        -- Throttling is handled inside ESP.Update itself now
        local success_esp, err_esp = pcall(function()
            ESP.Update(Settings, deltaTime, Utils)
        end)
        if not success_esp then 
            if tick() - lastErrorTime > 5 then
                lastErrorTime = tick()
                log("ESP update error: " .. tostring(err_esp)) 
            end
        end
        
        local now = tick()
        
        -- Visuals (FullBright etc) don't need to check every frame
        if now - lastVisualsUpdate > 0.5 then
            lastVisualsUpdate = now
            if Visuals then
                pcall(function() Visuals.Update(Settings) end)
            end
        end
        
        -- Watermark update must be called every frame to count FPS correctly
        if GUI and GUI.UpdateWatermark then
            pcall(function() GUI.UpdateWatermark(Settings) end)
        end
        
        -- Other GUI elements update (Keybinds) - very slow if done every frame
        if now - lastGuiUpdate > 0.1 then
            lastGuiUpdate = now
            if GUI then
                pcall(function()
                    if GUI.UpdateKeybindList then
                        GUI.UpdateKeybindList(Settings)
                    end
                end)
            end
        end
    end)

    -- Initialize Hooks LAST to ensure everything else is ready
    task.spawn(function()
        task.wait(1) -- Extra safety delay
        log("Activating hooks...")
        pcall(function()
            Aimbot.InitHooks(Settings, Utils, Ballistics)
        end)
    end)

    -- Cleanup on player removing
    table.insert(Main.Connections, Players.PlayerRemoving:Connect(function(player)
        ESP.Remove(player)
    end))
end

function Main.Unload()
    local Settings = Main.Modules.Settings
    local ConfigManager = Main.Modules.ConfigManager

    -- Auto-save settings
    if ConfigManager and Settings then
        ConfigManager.Save("autoload", Settings)
    end

    RunService:UnbindFromRenderStep("WithoniumUpdate")
    for _, conn in ipairs(Main.Connections) do
        if conn then conn:Disconnect() end
    end
    
    if Main.Modules.GUI and Main.Modules.GUI.ScreenGui then
        Main.Modules.GUI.ScreenGui:Destroy()
    end

    if Main.Modules.ESP then
        pcall(function()
            if Main.Modules.ESP.Data then
                for player, _ in pairs(Main.Modules.ESP.Data) do
                    pcall(function() Main.Modules.ESP.Remove(player) end)
                end
            end
            if Main.Modules.ESP.Container then
                Main.Modules.ESP.Container:Destroy()
            end
        end)
    end

    if Main.Modules.Aimbot then
        Main.Modules.Aimbot.Remove()
    end

    if Main.Modules.Visuals then
        Main.Modules.Visuals.Unload()
    end

    -- Restore mouse
    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

return Main

end)()

if Main and Main.Init then
    pcall(function() Main.Init(Modules) end)
end