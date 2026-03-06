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
    
    -- Shared objects for better performance
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
        -- Instant return for recursion, our own calls, or invalid calls
        if checkcaller() or insideHook or not self then
            return oldNamecall(self, ...)
        end
        
        -- Securely fetch namecall method and self type
        local method = getnamecallmethod()
        local isInstance = typeof(self) == "Instance"
        
        -- NamecallInstance protection: skip if not an instance or method is not a string
        if not isInstance or type(method) ~= "string" then
            return oldNamecall(self, ...)
        end
        
        -- JumpShot logic (minimal overhead, self-validity check)
        if method == "GetState" and Settings.jumpShotEnabled then
            if self == currentHumanoid and self.Parent then
                return Enum.HumanoidStateType.Landed
            end
        end

        -- Main Interception Logic
        if Settings.silentAimEnabled and (Aimbot.IsAiming or Settings.aimKeyMode == "Always") then
            local target = Aimbot.SilentTarget
            if target and target.targetPart and target.targetPart.Parent then
                local args = {...}
                
                -- Weapon Check Throttling (Optimized for faster switching)
                local now = os.clock()
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
                
                -- Only hook if we are holding a weapon
                if isWeaponCache then
                    local cam = workspace.CurrentCamera
                    
                    -- Raycast Hook (Verify self is workspace for extra safety)
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
                    
                    -- Legacy Ray Hooks (Verify self is workspace)
                    elseif (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhiteList") and self == workspace then
                        local ray = args[1]
                        if typeof(ray) == "Ray" and cam and (ray.Origin - cam.CFrame.Position).Magnitude < 50 then
                            local predictedDir = Aimbot.GetProjectilePrediction(target, Settings, Ballistics, ray.Origin)
                            local dist = (target.targetPart.Position - ray.Origin).Magnitude
                            local rayDist = dist * 1.5
                            local newRay = Ray.new(ray.Origin, predictedDir * rayDist)
                            
                            -- Magic Bullet: We still return values, but we ensure self is valid
                            if Settings.magicBulletEnabled then
                                local hitPos = target.targetPart.Position
                                return target.targetPart, hitPos, Vector3.new(0, 1, 0), target.targetPart.Material
                            end
                            
                            return oldNamecall(self, newRay, args[2], args[3], args[4])
                        end
                    end
                end
            end
        end
        
        return oldNamecall(self, ...)
    end)
end

return Hooks
