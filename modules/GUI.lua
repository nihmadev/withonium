local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Функция загрузки библиотеки с таймаутом
local function loadWithTimeout(url: string, timeout: number?): ...any
	if type(url) ~= "string" then return false, "URL must be a string" end
	url = url:gsub("^%s*(.-)%s*$", "%1")
	if not url:find("^http") then return false, "Invalid protocol" end

	timeout = timeout or 15
	local requestCompleted = false
	local success, result = false, nil

	local requestThread = task.spawn(function()
		local fetchSuccess, fetchResult
		
		-- Use executor's request if available
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
			-- Fallback to HttpGet with retry
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
    	-- Сначала пробуем локальный файл
	local success, result = pcall(function()
		if isfile("WithoniumRTY.lua") then
			local content = readfile("WithoniumRTY.lua")
			local f, err = loadstring(content)
			if f then return f() end
			error(err)
		end
		error("No local file")
	end)

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
    
    -- Watermark and Keybinds
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

    -- UI Elements for synchronization
    Elements = {
        Toggles = {}
    },

    -- Mock ScreenGui for Main.Unload compatibility
    ScreenGui = nil
}

-- Helper function to safely get name from KeyCode or UserInputType
local function getKeyName(key)
    if not key then return "None" end
    local str = tostring(key)
    str = str:gsub("Enum.KeyCode.", "")
    str = str:gsub("Enum.UserInputType.", "")
    return str
end

-- Helper function to safely set keybind from WithoniumRTY callback
local function setKeybind(Key, Settings, SettingName)
    if not Key then return end
    
    -- First try KeyCode
    local success, result = pcall(function() return Enum.KeyCode[Key] end)
    if success and result then
        Settings[SettingName] = result
        return
    end
    
    -- Then try UserInputType (for MouseButtons)
    success, result = pcall(function() return Enum.UserInputType[Key] end)
    if success and result then
        Settings[SettingName] = result
    end
end

function GUI.Init(Settings, Utils, UnloadCallback, ConfigManager)
    GUI.ConfigManager = ConfigManager
    GUI.UnloadCallback = UnloadCallback
    
    -- Create ScreenGui for Watermark/Keybinds
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
        GUI.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global -- Use Global to avoid sibling issues with ipairs if any

        -- Watermark
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

        -- Keybind List
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

    -- HIDE RAYFIELD SETTINGS BUTTON (EXTREMELY ROBUST)
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
                                -- Hide everything except the title and the close/minimize buttons (which are usually at the far right)
                                if v:IsA("ImageButton") or v:IsA("Button") then
                                    local name = v.Name:lower()
                                    -- Rayfield close/min are usually named "Close" and "Minimize" or similar
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

    -- Aimbot Tab (rbxassetid://9134785384)
    local AimbotTab = GUI.Window:CreateTab("Aimbot", 9134785384)
    
    AimbotTab:CreateSection("Silent Aim")
    GUI.Elements.Toggles["aimbotEnabled"] = AimbotTab:CreateToggle({
        Name = "Aimbot Enabled",
        CurrentValue = Settings.aimbotEnabled,
        Flag = "aimbotEnabled",
        Callback = function(Value) Settings.aimbotEnabled = Value end
    })
    GUI.Elements.Toggles["teamCheckEnabled"] = AimbotTab:CreateToggle({
        Name = "Team Check",
        CurrentValue = Settings.teamCheckEnabled,
        Flag = "teamCheckEnabled",
        Callback = function(Value) Settings.teamCheckEnabled = Value end
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

    -- Visuals Tab (rbxassetid://9134780101)
    local VisualsTab = GUI.Window:CreateTab("Visuals", 9134780101)
    
    VisualsTab:CreateSection("ESP")
    GUI.Elements.Toggles["espEnabled"] = VisualsTab:CreateToggle({
        Name = "ESP Enabled",
        CurrentValue = Settings.espEnabled,
        Flag = "espEnabled",
        Callback = function(Value) Settings.espEnabled = Value end
    })
    GUI.Elements.Toggles["espDrawTeammates"] = VisualsTab:CreateToggle({
        Name = "Draw Teammates",
        CurrentValue = Settings.espDrawTeammates,
        Flag = "espDrawTeammates",
        Callback = function(Value) Settings.espDrawTeammates = Value end
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

    -- Player Tab (rbxassetid://10747373176)
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
    local MainSettings, ConfigsSide = SettingsTab:Split(0.5)

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
    
    ConfigsSide:CreateSection("Config Actions")
    
    -- Add Load and Delete buttons at the top
    ConfigsSide:CreateButton({
        Name = "Load Selected",
        Callback = function()
            if GUI.ConfigName and GUI.ConfigName ~= "" then
                GUI.ConfigManager.Load(GUI.ConfigName, Settings)
                GUI.UpdateToggles(Settings)
                GUI.Window:Notify({
                    Title = "Config Loaded",
                    Content = "Configuration " .. GUI.ConfigName .. " has been successfully loaded.",
                    Duration = 5,
                    Image = 4483362458
                })
            else
                GUI.Window:Notify({
                    Title = "Error",
                    Content = "Please select a config first.",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end
    })
    
    ConfigsSide:CreateButton({
        Name = "Delete Selected",
        Callback = function()
            if GUI.ConfigName and GUI.ConfigName ~= "" then
                local configToDelete = GUI.ConfigName
                GUI.ConfigManager.Delete(configToDelete)
                GUI.ConfigName = ""
                GUI.UpdateConfigList(ConfigsSide, Settings)
                GUI.Window:Notify({
                    Title = "Config Deleted",
                    Content = "Configuration " .. configToDelete .. " has been deleted.",
                    Duration = 5,
                    Image = 4483362458
                })
            else
                GUI.Window:Notify({
                    Title = "Error",
                    Content = "Please select a config first.",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end
    })
    
    ConfigsSide:CreateSection("Available Configs")
    
    if GUI.ConfigManager then
        local configs = GUI.ConfigManager.List()
        if type(configs) == "table" then
            for _, name in pairs(configs) do    
                local ConfigButton = ConfigsSide:CreateButton({
                    Name = (GUI.ConfigName == name and "► " or "") .. name,
                    Callback = function()
                        GUI.ConfigName = name
                        GUI.UpdateConfigList(ConfigsSide, Settings)
                    end
                })
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
            item.StatusLabel.TextColor3 = bind.Active and Color3.fromRGB(220, 220, 220) or Color3.fromRGB(100, 100, 100)
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