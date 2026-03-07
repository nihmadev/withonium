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

    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        -- 1. Instant checkcaller to bypass our own calls
        if checkcaller() then
            return oldNamecall(self, ...)
        end

        -- 2. Fetch method once and avoid further logic if not needed
        local method = getnamecallmethod()
        
        -- 3. Recursion and validity protection
        if insideHook or not self then
            return oldNamecall(self, ...)
        end

        -- 4. JumpShot logic (minimal overhead, specific self check)
        if method == "GetState" and Settings.jumpShotEnabled then
            if self == currentHumanoid and self.Parent then
                return Enum.HumanoidStateType.Landed
            end
        end

        -- 5. Silent Aim Interception (only for workspace calls)
        if (method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhiteList") and self == workspace then
            if Settings.silentAimEnabled and (Aimbot.IsAiming or Settings.aimKeyMode == "Always") then
                local target = Aimbot.SilentTarget
                if target and target.targetPart and target.targetPart.Parent then
                    local args = {...}
                    
                    -- Weapon Check Throttling
                    local now = os.clock()
                    if now - lastWeaponCheck > 0.1 then
                        lastWeaponCheck = now
                        insideHook = true
                        local char = currentCharacter or LocalPlayer.Character
                        local tool = char and char:FindFirstChildOfClass("Tool")
                        isWeaponCache = tool and Ballistics.GetWeaponFromTool(tool) or false
                        insideHook = false
                    end
                    
                    if isWeaponCache then
                        local cam = workspace.CurrentCamera
                        
                        -- Raycast Hook
                        if method == "Raycast" then
                            local origin = args[1]
                            if typeof(origin) == "Vector3" and cam and (origin - cam.CFrame.Position).Magnitude < 50 then
                                local predictedDir = Aimbot.GetProjectilePrediction(target, Settings, Ballistics, origin)
                                local dist = (target.targetPart.Position - origin).Magnitude
                                local direction = predictedDir * (dist * 1.5)
                                
                                if Settings.magicBulletEnabled then
                                    local targetChar = Utils.getCharacter(target.player)
                                    if targetChar then
                                        sharedRaycastParams.FilterDescendantsInstances = {targetChar}
                                        return oldNamecall(self, origin, direction, sharedRaycastParams)
                                    end
                                end
                                
                                return oldNamecall(self, origin, direction, args[3])
                            end
                        
                        -- Legacy Ray Hooks
                        else
                            local ray = args[1]
                            if typeof(ray) == "Ray" and cam and (ray.Origin - cam.CFrame.Position).Magnitude < 50 then
                                local predictedDir = Aimbot.GetProjectilePrediction(target, Settings, Ballistics, ray.Origin)
                                local dist = (target.targetPart.Position - ray.Origin).Magnitude
                                local newRay = Ray.new(ray.Origin, predictedDir * (dist * 1.5))
                                
                                if Settings.magicBulletEnabled then
                                    return target.targetPart, target.targetPart.Position, Vector3.new(0, 1, 0), target.targetPart.Material
                                end
                                
                                return oldNamecall(self, newRay, args[2], args[3], args[4])
                            end
                        end
                    end
                end
            end
        end
        
        return oldNamecall(self, ...)
    end))
end

return Hooks
