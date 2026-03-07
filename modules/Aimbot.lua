local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Sub-modules
-- We assume these are in the 'Aimbot' folder relative to this script
-- In a real Roblox environment, this would be require(script.Aimbot.Prediction)
-- but for this file-based structure, we'll use paths that make sense for the loader.
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
    
    -- FreeCam State
    FreeCamActive = false,
    FreeCamPos = Vector3.new(0, 0, 0),
    FreeCamRot = Vector2.new(0, 0),
    OriginalCameraType = nil,
    OriginalCameraCFrame = nil,
    
    -- Smooth Prediction Properties
    LastPredictedDir = nil,
    PredictionSmoothing = 0.2, -- Чем меньше, тем плавнее (0.1 - 0.5)
    
    -- Velocity Averaging
    VelocityHistory = {},
    MaxHistorySize = 5,
}

-- Initialize FOV Circle
Aimbot.FOVCircle = Drawing.new("Circle")
Aimbot.FOVCircle.Color = Color3.new(1, 1, 1)
Aimbot.FOVCircle.Thickness = 1
Aimbot.FOVCircle.NumSides = 64
Aimbot.FOVCircle.Filled = false
Aimbot.FOVCircle.Transparency = 0.5
Aimbot.FOVCircle.Visible = false

-- Interface methods delegating to sub-modules
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
    
    -- Cache target for current frame to avoid multiple expensive searches
    local currentFrameTarget = Aimbot.FindTarget(Settings, Utils)
    
    -- Обновляем цель для Silent Aim один раз за кадр, чтобы не лагало в хуках
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
            -- Reset smoothing and history if target changed
            if Aimbot.CurrentTarget and Aimbot.CurrentTarget.player ~= target.player then
                Aimbot.LastPredictedDir = nil
                Aimbot.VelocityHistory = {}
            end
            
            -- Velocity Averaging: Reduces jitter from physics noise
            table.insert(Aimbot.VelocityHistory, target.velocity)
            if #Aimbot.VelocityHistory > (Aimbot.MaxHistorySize or 5) then
                table.remove(Aimbot.VelocityHistory, 1)
            end
            
            local avgVelocity = Vector3.new(0, 0, 0)
            for _, v in ipairs(Aimbot.VelocityHistory) do
                avgVelocity = avgVelocity + v
            end
            avgVelocity = avgVelocity / #Aimbot.VelocityHistory
            
            -- Temporarily override target velocity with averaged one
            local originalVelocity = target.velocity
            target.velocity = avgVelocity
            
            Aimbot.CurrentTarget = target
            Aimbot.IsAiming = true
            
            -- Use a much more stable origin (HumanoidRootPart is better than Head/Camera for prediction)
             local character = LocalPlayer.Character
             local origin = camera.CFrame.Position
             if character and character:FindFirstChild("HumanoidRootPart") then
                 -- Stable origin: RootPart position + standard offset for eyes
                 origin = character.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0)
             end
 
             local predictedDir = Aimbot.GetProjectilePrediction(target, Settings, Ballistics, origin)
            
            -- Restore original velocity just in case
            target.velocity = originalVelocity
            
            -- Smooth Prediction: Prevents jitter when target is moving erratically
            local pSmoothing = Settings.predictionSmoothing or 0.2
            if Aimbot.LastPredictedDir and pSmoothing > 0 then
                predictedDir = Aimbot.LastPredictedDir:Lerp(predictedDir, math.clamp(1 - pSmoothing, 0.01, 1))
            end
            Aimbot.LastPredictedDir = predictedDir
            
            Aimbot.TargetPosition = origin + (predictedDir * 10)
            
            local currentCFrame = camera.CFrame
            -- Safety check for lookAt to prevent "spinning" when looking straight up/down
            local upVector = Vector3.new(0, 1, 0)
            if math.abs(predictedDir:Dot(upVector)) > 0.99 then
                upVector = Vector3.new(0, 0, 1) -- Use forward as up if looking vertically
            end
            
            local targetCFrame = CFrame.lookAt(currentCFrame.Position, currentCFrame.Position + predictedDir, upVector)
            
            -- Improved Smoothness: use an exponential factor for better feel
            local smoothnessFactor = Settings.smoothness or 0.5
            -- Limit deltaTime to prevent huge jumps after lag spikes
            local safeDeltaTime = math.min(deltaTime, 0.1)
            
            -- Adjust alpha to be more responsive but still smooth
            local alpha = math.clamp(safeDeltaTime * (smoothnessFactor * 120), 0, 1)
            
            if smoothnessFactor < 1 then
                camera.CFrame = currentCFrame:Lerp(targetCFrame, alpha)
            else
                camera.CFrame = targetCFrame
            end
        else
            -- Reset state when target is lost
            Aimbot.CurrentTarget = nil
            Aimbot.IsAiming = false
            Aimbot.TargetPosition = nil
            Aimbot.LastPredictedDir = nil
            Aimbot.VelocityHistory = {} -- Clear history
        end
    else
        -- Reset state when aiming stops
        Aimbot.CurrentTarget = nil
        Aimbot.IsAiming = false
        Aimbot.TargetPosition = nil
        Aimbot.LastPredictedDir = nil -- Reset smoothing when not aiming
        Aimbot.VelocityHistory = {}
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
    
    -- Anti-Aim should be applied early or late depending on preference, 
    -- but here we ensure it doesn't break the aimbot by running it after calculations.
    Aimbot.ApplyAntiAim(Settings)

    -- Update FOV Circle
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
        
        -- Restore collision if needed
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
    
    -- Restore hitboxes
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
    
    -- Restore Anti-Aim state
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
