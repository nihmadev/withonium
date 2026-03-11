local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Hitboxes = {
    lastHitboxUpdate = 0,
    OriginalProperties = setmetatable({}, {__mode = "k"}), 
    CleanupIndex = 1,
    Connections = {}
}

function Hitboxes.UpdateHitboxes(Aimbot, Settings, Utils, ESP)
    if not Settings or not ESP then return end
    
    local now = tick()
    
    if now - Hitboxes.lastHitboxUpdate < 0.1 then return end 
    Hitboxes.lastHitboxUpdate = now
    
    local function restorePart(part)
        if not part then return end
        local props = Hitboxes.OriginalProperties[part]
        if props then
            pcall(function()
                if part.Parent then
                    part.Size = props.Size
                    part.Transparency = props.Transparency
                    part.CanCollide = props.CanCollide
                    part.CanTouch = props.CanTouch
                    part.Massless = props.Massless
                    
                    if part:IsA("Part") then
                        part.Shape = props.Shape or Enum.PartType.Block
                    end
                end
            end)
            Hitboxes.OriginalProperties[part] = nil
        end
    end

    if not Settings.hitboxExpanderEnabled then
        if next(Hitboxes.OriginalProperties) then
            for part, _ in pairs(Hitboxes.OriginalProperties) do
                restorePart(part)
            end
        end
        return
    end
    
    local size = Settings.hitboxExpanderSize or 5
    local targetSize = Vector3.new(size, size, size)
    local camPos = workspace.CurrentCamera.CFrame.Position
    
    local allPlayers = Players:GetPlayers()
    for i = 1, #allPlayers do
        local player = allPlayers[i]
        if player == LocalPlayer then continue end
        
        local character = Utils.getCharacter(player)
        
        if not character then continue end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart") 
            or character:FindFirstChild("Torso") 
            or character:FindFirstChild("UpperTorso") 
            or character:FindFirstChild("Middle") 
            or character:FindFirstChild("Center")
        
        if not rootPart then continue end
        
        local distance = (rootPart.Position - camPos).Magnitude
        if distance > 2500 then
            continue 
        end

        local targetParts = {}
        local partSelection = Settings.targetPart or "Head"
        
        if partSelection == "All" then
            targetParts = Utils.getAllBodyParts(character, "Head")
            local torsoParts = Utils.getAllBodyParts(character, "Torso")
            for _, p in ipairs(torsoParts) do table.insert(targetParts, p) end
        else
            targetParts = Utils.getAllBodyParts(character, partSelection)
        end
        
        for j = 1, #targetParts do
            local part = targetParts[j]
            if not part or not part:IsA("BasePart") or part.Name == "HumanoidRootPart" then continue end
            
            if not Hitboxes.OriginalProperties[part] then
                Hitboxes.OriginalProperties[part] = {
                    Size = part.Size,
                    Transparency = part.Transparency,
                    CanCollide = part.CanCollide,
                    CanTouch = part.CanTouch,
                    Massless = part.Massless,
                    Shape = part:IsA("Part") and part.Shape or nil
                }
            end
            
            
            
            if part.CanCollide ~= false then part.CanCollide = false end
            if part.CanTouch ~= true then part.CanTouch = true end
            if part.Massless ~= true then part.Massless = true end
            
            
            pcall(function()
                if part.CanQuery ~= true then part.CanQuery = true end
            end)
            
            if Settings.hitboxExpanderShow then
                if part.Size ~= targetSize then
                    part.Size = targetSize
                end
                
                
                if part.Transparency ~= 0.95 then
                    part.Transparency = 0.95
                end
                
                
                local visual = part:FindFirstChild("HitboxVisual")
                if not visual or not visual:IsA("SelectionBox") then
                    if visual then visual:Destroy() end
                    visual = Instance.new("SelectionBox")
                    visual.Name = "HitboxVisual"
                    visual.LineThickness = 0.015 
                    visual.SurfaceColor3 = Color3.fromRGB(255, 0, 0) 
                    visual.SurfaceTransparency = 0.9 
                    visual.Color3 = Color3.fromRGB(255, 255, 255) 
                    visual.AlwaysOnTop = true
                    visual.Adornee = part
                    visual.Parent = part
                end
            else
                
                
                local orig = Hitboxes.OriginalProperties[part]
                if orig then
                    if part.Size ~= orig.Size then part.Size = orig.Size end
                    if part.Transparency ~= orig.Transparency then part.Transparency = orig.Transparency end
                    if part.CanCollide ~= orig.CanCollide then part.CanCollide = orig.CanCollide end
                end
                
                local visual = part:FindFirstChild("HitboxVisual")
                if visual then visual:Destroy() end
            end
        end
    end
    
    
    local partsInCache = {}
    local k = 0
    for part, _ in pairs(Hitboxes.OriginalProperties) do
        k = k + 1
        partsInCache[k] = part
    end
    
    local cleanupBatchSize = 20 
    local startIndex = Hitboxes.CleanupIndex or 1
    if startIndex > #partsInCache then startIndex = 1 end
    
    for i = startIndex, math.min(startIndex + cleanupBatchSize, #partsInCache) do
        local part = partsInCache[i]
        if part then
            local char = part.Parent
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if not char or not char.Parent or not humanoid or humanoid.Health <= 0 then
                restorePart(part)
            end
        end
    end
    Hitboxes.CleanupIndex = startIndex + cleanupBatchSize
end

return Hitboxes
