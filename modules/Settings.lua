local Settings = {
    -- Aimbot Settings
    aimbotEnabled = false,
    teamCheckEnabled = true,
    visibleCheckEnabled = true,
    noRecoilEnabled = false,
    fastShootEnabled = false,
    jumpShotEnabled = false,
    jumpShotKey = Enum.KeyCode.Unknown,
    jumpShotKeyMode = "Toggle",
    
    fovCircleEnabled = true,
    smoothness = 0.08,
    predictionFactor = 1.0, -- Default to 1.0
    predictionSmoothing = 0.2, -- Smoothing for prediction to avoid jitter
    projectilePredictionEnabled = true,
    projectileSpeed = 1000,
    projectileGravity = 196.2,
    fovSize = 90,
    targetPriority = "Distance", -- "Distance", "Crosshair", "Balanced"
    aimKey = Enum.UserInputType.MouseButton1,
    aimKeyMode = "Hold", -- "Hold", "Toggle", "Always"
    targetPart = "Head", -- "Head", "Torso", "Legs"
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
    
    -- Anti-Aim Settings
    antiAimEnabled = false,
    antiAimMode = "Spin", -- "Spin", "Jitter", "Static"
    antiAimSpeed = 50,
    antiAimKey = Enum.KeyCode.Unknown,
    antiAimKeyMode = "Toggle",
    
    -- Anti-AFK Settings
    antiAfkEnabled = false,
    antiAfkInterval = 15, -- Minutes
    antiAfkLastActionTime = tick(),
    
    -- Ballistics Settings (Not in GUI as requested)
    ballisticsEnabled = true,
    bulletVelocity = 1000, -- Studs per second
    gravity = 196.2, -- Roblox gravity
    predictionFactor = 0.500, -- For movement prediction
    predictionIterations = 20, -- Iterations for ballistics accuracy
    hitscanVelocityThreshold = 800, -- Above this velocity gravity isn't applied to aiming
    espEnabled = true,
    espDrawTeammates = false,
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
    espMaxDistance = 700, --gamemable
    espTextColor = Color3.fromRGB(255, 255, 255),
    espChamsMode = "Default", -- "Default", "Glow", "Metal", "Neon"
    espColor = Color3.fromRGB(255, 255, 255),
    espOutlineColor = Color3.fromRGB(255, 255, 255),
    espSkeletonColor = Color3.fromRGB(255, 255, 255),
    fullBrightEnabled = false,
    noGrassEnabled = false,
    noFogEnabled = false,

    -- GUI Settings
    guiVisible = true,
    watermarkEnabled = true,
    toggleKey = Enum.KeyCode.RightShift,
    logoId = "https://github.com/nihmadev/Withonium/raw/main/icon.png"
}

return Settings
