local Prediction = {}

function Prediction.GetProjectilePrediction(target, Settings, Ballistics, customOrigin)
    local camera = workspace.CurrentCamera
    local origin = customOrigin or (camera and camera.CFrame.Position) or Vector3.new(0, 0, 0)
    
    local targetPos = target.targetPart.Position
    local targetVelocity = target.velocity or Vector3.new(0, 0, 0)
    
    -- Removed duplicate velocity logic. Targeting.lua already handles stable velocity.
    
    local v = Settings.projectileSpeed or 1000
    local g = Settings.projectileGravity or 196.2
    
    -- Dynamic ballistics if enabled and Ballistics module is provided
    if Settings.ballisticsEnabled and Ballistics then
        local config = Ballistics.GetConfig()
        if config then
            v = config.velocity or v
            -- Ensure gravity is handled correctly (as a positive value for magnitude)
            g = math.abs(config.gravity or g)
        end
    end
    
    -- Sanity check for velocity to prevent division by zero or extreme values
    v = math.max(v, 10)
    
    if not Settings.projectilePredictionEnabled then
        return (targetPos - origin).Unit
    end
    
    local dist = (targetPos - origin).Magnitude
    -- If target is extremely close, skip prediction to prevent jitter/jump
    if dist < 0.5 then
        return (targetPos - origin).Unit
    end
    
    local pFactor = Settings.predictionFactor or 1
    local iterations = Settings.predictionIterations or 10 -- Reduced for performance, 25 was overkill
    local gvec = Vector3.new(0, -g, 0)
    local hitscanThreshold = Settings.hitscanVelocityThreshold or 1500 -- Increased for modern games
    local targetG = workspace.Gravity or 196.2
    
    -- 1. Hitscan mode (High velocity weapons)
    if v >= hitscanThreshold then
        local t = dist / v
        local lead = targetVelocity * t * pFactor
        
        -- Stabilize lead
        local maxLead = dist * 0.5
        if lead.Magnitude > maxLead then
            lead = lead.Unit * maxLead
        end
        
        -- Target movement prediction (Softened to prevent snap)
        local targetFall = Vector3.new(0, 0, 0)
        if target.isFreefalling then
            -- Use a slightly lower gravity for target prediction to be conservative
            targetFall = Vector3.new(0, 0.4 * targetG * (t * t), 0)
        end
        
        local aimPoint = targetPos + lead - targetFall
        return (aimPoint - origin).Unit
    end
    
    -- 2. Projectile mode (Bows, Crossbows, etc.)
    local t = dist / v
    local dir
    
    -- Safety clamp for initial time to prevent extreme offsets
    t = math.min(t, 5) 

    for i = 1, iterations do
        local lead = targetVelocity * t * pFactor
        
        -- Stabilize lead
        local maxLead = dist * 0.8 -- Slightly more lead allowed for projectiles
        if lead.Magnitude > maxLead then
            lead = lead.Unit * maxLead
        end
        
        -- Target movement prediction (Softened)
        local targetFall = Vector3.new(0, 0, 0)
        if target.isFreefalling then
            targetFall = Vector3.new(0, 0.4 * targetG * (t * t), 0)
        end
        
        -- Bullet drop compensation
        local dropComp = g * 0.5 * (t * t)
        
        -- CRITICAL FIX: Limit bullet drop compensation to prevent "320 degrees up" jump
        local maxDropComp = dist * 1.2 
        dropComp = math.min(dropComp, maxDropComp)
        
        local dropVec = Vector3.new(0, dropComp, 0)
        local aimPoint = targetPos + lead - targetFall + dropVec
        
        local toAim = aimPoint - origin
        local newDist = toAim.Magnitude
        
        if newDist < 0.01 then break end
        
        dir = toAim.Unit
        local newT = newDist / v
        
        -- Prevent T from exploding
        newT = math.min(newT, 5)
        
        if math.abs(newT - t) < 0.0005 then
            t = newT
            break
        end
        t = newT
    end
    
    local finalDir = dir or (targetPos - origin).Unit
    
    -- Final sanity check: if the direction is somehow NaN or extreme, return default
    if finalDir.X ~= finalDir.X or math.abs(finalDir.Y) > 0.999 then
        -- This handles the "looking straight up/down" edge cases
        if dist > 0.1 then
            return (targetPos - origin).Unit
        end
    end

    return finalDir
end

return Prediction
