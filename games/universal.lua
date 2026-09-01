local Core = loadstring(game:HttpGet("https://raw.githubusercontent.com/RVXv2/RVX-hub/main/games/core.lua"))()

local ok, info = pcall(function()
    return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
end)
local mapName = (ok and info and info.Name) or "Universal"

local Window, WindUI = Core.Init(mapName)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ===== แท็บเพลง (ค้นหา/คัดลอกเท่านั้น) =====
local Songs = loadstring(game:HttpGet("https://raw.githubusercontent.com/RVXv2/RVX-hub/main/games/songs.lua"))()
Songs.AddSongsTab(Window, WindUI, false)

-- ===== แท็บดูดไอดีเพลง (ใช้ได้ทุกแมพ) =====
Songs.AddSniffTab(Window, WindUI)

-- ===== แท็บเทเลพอต =====
local TeleportTab = Window:Tab({ Title = "เทเลพอต", Icon = "map-pin" })

TeleportTab:Section({ Title = "วาปหาผู้เล่น", Desc = "เลือกผู้เล่นที่ต้องการเทเลพอตไปหา" })

local function GetPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    return names
end

local SelectedPlayer = nil
local PlayerDropdown

PlayerDropdown = TeleportTab:Dropdown({
    Title = "เลือกผู้เล่น",
    Values = GetPlayerNames(),
    Callback = function(selected)
        SelectedPlayer = selected
    end,
})

local function RefreshPlayerDropdown()
    local names = GetPlayerNames()
    local ok1 = pcall(function()
        PlayerDropdown:Refresh(names)
    end)
    if not ok1 then
        pcall(function()
            PlayerDropdown:SetValues(names)
        end)
    end
end

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    RefreshPlayerDropdown()
end)

Players.PlayerRemoving:Connect(function(p)
    task.wait(0.2)
    RefreshPlayerDropdown()
    if SelectedPlayer == p.Name then
        SelectedPlayer = nil
    end
end)

TeleportTab:Button({
    Title = "รีเฟรชรายชื่อผู้เล่น",
    Icon = "refresh-cw",
    Callback = function()
        RefreshPlayerDropdown()
        WindUI:Notify({ Title = "เทเลพอต", Content = "อัปเดตรายชื่อแล้ว", Duration = 2 })
    end,
})

TeleportTab:Button({
    Title = "เทเลพอตไปหา",
    Icon = "navigation",
    Callback = function()
        if not SelectedPlayer then
            WindUI:Notify({ Title = "ผิดพลาด", Content = "กรุณาเลือกผู้เล่นก่อน", Duration = 3 })
            return
        end

        local target = Players:FindFirstChild(SelectedPlayer)
        local myChar = LocalPlayer.Character

        if target and target.Character and myChar then
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = myChar:FindFirstChild("HumanoidRootPart")

            if targetRoot and myRoot then
                myRoot.CFrame = targetRoot.CFrame + Vector3.new(3, 0, 0)
                WindUI:Notify({ Title = "สำเร็จ", Content = "เทเลพอตไปหา " .. SelectedPlayer, Duration = 3 })
            end
        else
            WindUI:Notify({ Title = "ผิดพลาด", Content = "หาผู้เล่นไม่เจอ (อาจออกจากเกมไปแล้ว)", Duration = 3 })
            RefreshPlayerDropdown()
        end
    end,
})

-- ===== แท็บการป้องกัน =====
local ProtectionTab = Window:Tab({ Title = "การป้องกัน", Icon = "shield" })

-- บันทึก/โหลดค่า toggle ทั้งหมดลงไฟล์แยก เพื่อให้จำค่าได้แม้ออกเข้าเกมใหม่
-- (รันสคริปต์ใหม่) ไม่ต้องมาติ๊กเปิดใหม่ทุกครั้ง
local PROTECTION_CONFIG_FILE = "RVXHub_ProtectionConfig.json"

local function LoadProtectionConfig()
    local defaults = {
        AntiSitAll = false,
        AntiSitChair = false,
        AntiSitVehicle = false,
        AntiKnockback = false,
        AntiRagdoll = false,
    }
    if isfile and isfile(PROTECTION_CONFIG_FILE) then
        local ok, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile(PROTECTION_CONFIG_FILE))
        end)
        if ok and data then
            for k, v in pairs(data) do
                defaults[k] = v
            end
        end
    end
    return defaults
end

local function SaveProtectionConfig(cfg)
    if writefile then
        pcall(function()
            writefile(PROTECTION_CONFIG_FILE, game:GetService("HttpService"):JSONEncode(cfg))
        end)
    end
end

local ProtectionConfig = LoadProtectionConfig()

local AntiSitAll = ProtectionConfig.AntiSitAll
local AntiSitChair = ProtectionConfig.AntiSitChair
local AntiSitVehicle = ProtectionConfig.AntiSitVehicle
local AntiKnockback = ProtectionConfig.AntiKnockback
local AntiRagdoll = ProtectionConfig.AntiRagdoll

local function PersistProtectionConfig()
    SaveProtectionConfig({
        AntiSitAll = AntiSitAll,
        AntiSitChair = AntiSitChair,
        AntiSitVehicle = AntiSitVehicle,
        AntiKnockback = AntiKnockback,
        AntiRagdoll = AntiRagdoll,
    })
end

local function GetHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function ApplyRagdollStates()
    local hum = GetHumanoid()
    if not hum then return end
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not AntiRagdoll)
    hum:SetStateEnabled(Enum.HumanoidStateType.Physics, not AntiKnockback)
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not AntiKnockback)
end

local function ApplySitAllState()
    local hum = GetHumanoid()
    if not hum then return end
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, not AntiSitAll)
end

local function HookCharacter(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    ApplyRagdollStates()
    ApplySitAllState()

    hum.Seated:Connect(function(active, seatPart)
        if not active or not seatPart then return end
        if AntiSitAll then
            hum.Sit = false
            return
        end

        local isVehicle = seatPart:IsA("VehicleSeat")
        if isVehicle and AntiSitVehicle then
            hum.Sit = false
        elseif (not isVehicle) and AntiSitChair then
            hum.Sit = false
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(HookCharacter)
if LocalPlayer.Character then
    HookCharacter(LocalPlayer.Character)
end

-- ตรวจจับความเร็วผิดปกติ (แรงกระแทก/ดีดจากของในแมพ) แล้วหักลบทันที
-- และคงสภาพการป้องกัน (Ragdoll/Knockback/นั่ง) ทุกเฟรม แทนที่จะพึ่ง HookCharacter
-- อย่างเดียว (ซึ่งมี delay ทำให้ตายแล้วโดนกระแทกก่อนกันจะกลับมาทำงาน)
-- วิธีนี้การป้องกันจะกลับมาทำงานทันทีไม่ว่าอะไรจะรีเซ็ตสถานะ Humanoid ก็ตาม
local NORMAL_VELOCITY_LIMIT = 90 -- studs/sec สูงกว่านี้ถือว่าผิดปกติ (บิน/หมุนของเราเองไม่โดนกระทบเพราะไม่ผ่าน AssemblyLinearVelocity แบบนี้)
local LastGoodVelocity = Vector3.new(0, 0, 0)

game:GetService("RunService").Heartbeat:Connect(function()
    ApplyRagdollStates()
    ApplySitAllState()

    if not AntiKnockback then return end
    local root = GetRoot()
    if not root then return end

    local vel = root.AssemblyLinearVelocity
    local horizontalSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude

    if horizontalSpeed > NORMAL_VELOCITY_LIMIT then
        root.AssemblyLinearVelocity = Vector3.new(0, math.max(vel.Y, 0), 0)
    end
end)

ProtectionTab:Section({ Title = "การนั่ง", Desc = "ป้องกันไม่ให้ตัวละครนั่งได้" })

ProtectionTab:Toggle({
    Title = "กันนั่งทุกอย่าง",
    Desc = "บล็อกทุกจุดพร้อมกัน (เก้าอี้ + รถ + อื่นๆ)",
    Value = AntiSitAll,
    Callback = function(state)
        AntiSitAll = state
        ApplySitAllState()
        PersistProtectionConfig()
        WindUI:Notify({ Title = "การป้องกัน", Content = "กันนั่งทุกอย่าง: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

ProtectionTab:Toggle({
    Title = "กันนั่งเก้าอี้",
    Desc = "เฉพาะที่นั่งทั่วไป ไม่รวมรถ",
    Value = AntiSitChair,
    Callback = function(state)
        AntiSitChair = state
        PersistProtectionConfig()
        WindUI:Notify({ Title = "การป้องกัน", Content = "กันนั่งเก้าอี้: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

ProtectionTab:Toggle({
    Title = "กันนั่งรถ",
    Desc = "เฉพาะเบาะรถ ไม่รวมเก้าอี้",
    Value = AntiSitVehicle,
    Callback = function(state)
        AntiSitVehicle = state
        PersistProtectionConfig()
        WindUI:Notify({ Title = "การป้องกัน", Content = "กันนั่งรถ: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

ProtectionTab:Section({ Title = "แรงกระแทก", Desc = "ป้องกันการถูกเหวี่ยง/ล้ม (ทั้งสถานะและแรงจริง)" })

ProtectionTab:Toggle({
    Title = "กันโดนดีด",
    Desc = "ป้องกันการถูกดีดจากของในแมพ (หักล้างแรงกระแทกจริง ไม่ใช่แค่บล็อกสถานะ)",
    Value = AntiKnockback,
    Callback = function(state)
        AntiKnockback = state
        ApplyRagdollStates()
        PersistProtectionConfig()
        WindUI:Notify({ Title = "การป้องกัน", Content = "กันโดนดีด: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

ProtectionTab:Toggle({
    Title = "กันล้ม",
    Desc = "ป้องกัน Ragdoll",
    Value = AntiRagdoll,
    Callback = function(state)
        AntiRagdoll = state
        ApplyRagdollStates()
        PersistProtectionConfig()
        WindUI:Notify({ Title = "การป้องกัน", Content = "กันล้ม: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

-- ===== แท็บการเคลื่อนไหว =====
local RunService = game:GetService("RunService")

local MovementTab = Window:Tab({ Title = "การเคลื่อนไหว", Icon = "move" })

MovementTab:Section({ Title = "บิน", Desc = "เปิดโหมดบินอิสระ รองรับมือถือ ความสูงคุมด้วยมุมกล้องเสมอ" })

local FlyEnabled = false
local FlySpeed = 50
local FlyConnection = nil
local FlyBodyVelocity = nil
local FlyBodyGyro = nil

local function StartFly()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    hum.PlatformStand = false

    FlyBodyVelocity = Instance.new("BodyVelocity")
    FlyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    FlyBodyVelocity.Parent = root

    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    FlyBodyGyro.P = 3000
    FlyBodyGyro.CFrame = root.CFrame
    FlyBodyGyro.Parent = root

    FlyConnection = RunService.RenderStepped:Connect(function()
        local camera = workspace.CurrentCamera
        local currentChar = LocalPlayer.Character
        local currentHum = currentChar and currentChar:FindFirstChildOfClass("Humanoid")
        if not camera or not currentHum or not FlyBodyVelocity or not FlyBodyGyro then return end

        local moveDir = currentHum.MoveDirection
        local inputMagnitude = moveDir.Magnitude
        local camCFrame = camera.CFrame

        local horizontal = Vector3.new(0, 0, 0)
        if inputMagnitude > 0.02 then
            horizontal = moveDir.Unit * FlySpeed * inputMagnitude
        end

        -- แนวตั้งแยกออกจากทิศเดินหน้า/ถอยหลังเสมอ ใช้มุมกล้องอย่างเดียว
        -- เพื่อไม่ให้ถอยหลังแล้วความสูงถูกล็อค
        local vertical = camCFrame.LookVector.Y * FlySpeed

        FlyBodyVelocity.Velocity = horizontal + Vector3.new(0, vertical, 0)
        FlyBodyGyro.CFrame = camCFrame
    end)
end

local function StopFly()
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    if FlyBodyVelocity then
        FlyBodyVelocity:Destroy()
        FlyBodyVelocity = nil
    end
    if FlyBodyGyro then
        FlyBodyGyro:Destroy()
        FlyBodyGyro = nil
    end
end

MovementTab:Toggle({
    Title = "เปิดโหมดบิน",
    Desc = "โยกจอยไปทางไหนก็บินไปทางนั้น เงย/ก้มกล้องเพื่อขึ้น-ลง แม้ถอยหลังก็ปรับความสูงได้",
    Value = false,
    Callback = function(state)
        FlyEnabled = state
        if FlyEnabled then
            StartFly()
            WindUI:Notify({ Title = "การเคลื่อนไหว", Content = "เปิดโหมดบินแล้ว", Duration = 2 })
        else
            StopFly()
            WindUI:Notify({ Title = "การเคลื่อนไหว", Content = "ปิดโหมดบินแล้ว", Duration = 2 })
        end
    end,
})

MovementTab:Slider({
    Title = "ความเร็วบิน",
    Desc = "ปรับความเร็วขณะบิน",
    Value = { Min = 10, Max = 200, Default = 50 },
    Callback = function(value)
        FlySpeed = value
    end,
})

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if FlyEnabled then
        StartFly()
    end
end)

-- ===== หมุนตัวละคร (ใช้แรงหมุนจริง คนอื่นเห็นลื่น ไม่กระตุก) =====
MovementTab:Section({ Title = "หมุนตัวละคร", Desc = "หมุนตัวเองอัตโนมัติต่อเนื่อง คนอื่นเห็นหมุนจริงลื่นๆ" })

local SpinEnabled = false
local SpinSpeed = 180
local SpinBAV = nil

local function StartSpin()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if SpinBAV then
        SpinBAV:Destroy()
    end

    SpinBAV = Instance.new("BodyAngularVelocity")
    SpinBAV.MaxTorque = Vector3.new(0, math.huge, 0)
    SpinBAV.P = 10000
    SpinBAV.AngularVelocity = Vector3.new(0, math.rad(SpinSpeed), 0)
    SpinBAV.Parent = root
end

local function StopSpin()
    if SpinBAV then
        SpinBAV:Destroy()
        SpinBAV = nil
    end
end

MovementTab:Toggle({
    Title = "เปิดหมุนตัวละคร",
    Desc = "ตัวละครจะหมุนรอบตัวเองต่อเนื่องอัตโนมัติ ใช้แรงหมุนจริงทำให้คนอื่นเห็นตรงกัน",
    Value = false,
    Callback = function(state)
        SpinEnabled = state
        if SpinEnabled then
            StartSpin()
            WindUI:Notify({ Title = "การเคลื่อนไหว", Content = "เปิดหมุนตัวละครแล้ว", Duration = 2 })
        else
            StopSpin()
            WindUI:Notify({ Title = "การเคลื่อนไหว", Content = "ปิดหมุนตัวละครแล้ว", Duration = 2 })
        end
    end,
})

MovementTab:Slider({
    Title = "ความเร็วหมุน",
    Desc = "หน่วยองศาต่อวินาที (ค่าสูงมากๆ อาจดูสั่น/ไม่ลื่นเพราะข้อจำกัดฟิสิกส์ของเกม ลองปรับดูจุดที่ลื่นสุด)",
    Value = { Min = 30, Max = 10000, Default = 180 },
    Callback = function(value)
        SpinSpeed = value
        if SpinBAV then
            SpinBAV.AngularVelocity = Vector3.new(0, math.rad(SpinSpeed), 0)
        end
    end,
})

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if SpinEnabled then
        StartSpin()
    end
end)

MovementTab:Section({ Title = "ทะลุทุกอย่าง", Desc = "เดิน/บินทะลุกำแพงและวัตถุทุกชนิดในแมพได้" })

local NoclipEnabled = false
local NoclipConnection = nil

local function SetCollide(state)
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = state
        end
    end
end

MovementTab:Toggle({
    Title = "ทะลุทุกอย่าง (Noclip)",
    Desc = "ปิดการชนกับทุกวัตถุในแมพ เดิน/บินทะลุกำแพงได้",
    Value = false,
    Callback = function(state)
        NoclipEnabled = state
        if state then
            if NoclipConnection then NoclipConnection:Disconnect() end
            NoclipConnection = RunService.Stepped:Connect(function()
                SetCollide(false)
            end)
            WindUI:Notify({ Title = "การเคลื่อนไหว", Content = "เปิดทะลุทุกอย่างแล้ว", Duration = 2 })
        else
            if NoclipConnection then
                NoclipConnection:Disconnect()
                NoclipConnection = nil
            end
            SetCollide(true)
            WindUI:Notify({ Title = "การเคลื่อนไหว", Content = "ปิดทะลุทุกอย่างแล้ว", Duration = 2 })
        end
    end,
})

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if NoclipEnabled then
        if NoclipConnection then NoclipConnection:Disconnect() end
        NoclipConnection = RunService.Stepped:Connect(function()
            SetCollide(false)
        end)
    end
end)

MovementTab:Section({ Title = "ล็อคตำแหน่ง", Desc = "ค้างตัวละครอยู่กับที่ แต่ยังเปลี่ยนท่าทาง/เล่นแอนิเมชันได้" })

local PositionLocked = false

local function ApplyPositionLock(state)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    root.Anchored = state
end

MovementTab:Toggle({
    Title = "ล็อคตำแหน่ง",
    Desc = "ตรึงตำแหน่งปัจจุบันไว้ ขยับที่ไม่ได้แต่ยังโพสท่า/เล่นแอนิเมชันได้",
    Value = false,
    Callback = function(state)
        PositionLocked = state
        ApplyPositionLock(state)
        WindUI:Notify({ Title = "การเคลื่อนไหว", Content = "ล็อคตำแหน่ง: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    PositionLocked = false
end)

-- ===== ความเร็ววิ่ง / กระโดด (ล็อคค่าไว้ตลอด ไม่ถูกรีเซ็ต) =====
MovementTab:Section({ Title = "ความเร็ววิ่ง", Desc = "ปรับ WalkSpeed และล็อคค่าไว้ตลอด แม้ถูกรีเซ็ตหรือตายก็คงเดิม" })

local WalkSpeedValue = 16
local WalkSpeedLocked = false

local function ApplyWalkSpeed()
    local hum = GetHumanoid()
    if hum then
        hum.WalkSpeed = WalkSpeedValue
    end
end

MovementTab:Slider({
    Title = "ความเร็ววิ่ง",
    Desc = "ค่าเริ่มต้นของเกมคือ 16 (ล็อคไว้ตลอดอัตโนมัติเมื่อปรับ)",
    Value = { Min = 16, Max = 200, Default = 16 },
    Callback = function(value)
        WalkSpeedValue = value
        WalkSpeedLocked = true
        ApplyWalkSpeed()
    end,
})

MovementTab:Section({ Title = "ความสูงกระโดด", Desc = "ปรับ JumpPower และล็อคค่าไว้ตลอด แม้ถูกรีเซ็ตหรือตายก็คงเดิม" })

local JumpPowerValue = 50
local JumpPowerLocked = false

local function ApplyJumpPower()
    local hum = GetHumanoid()
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = JumpPowerValue
    end
end

MovementTab:Slider({
    Title = "ความสูงกระโดด",
    Desc = "ค่าเริ่มต้นของเกมคือ 50 (ล็อคไว้ตลอดอัตโนมัติเมื่อปรับ)",
    Value = { Min = 50, Max = 300, Default = 50 },
    Callback = function(value)
        JumpPowerValue = value
        JumpPowerLocked = true
        ApplyJumpPower()
    end,
})

RunService.Heartbeat:Connect(function()
    local hum = GetHumanoid()
    if not hum then return end

    if WalkSpeedLocked and math.abs(hum.WalkSpeed - WalkSpeedValue) > 0.01 then
        hum.WalkSpeed = WalkSpeedValue
    end

    if JumpPowerLocked and math.abs(hum.JumpPower - JumpPowerValue) > 0.01 then
        hum.UseJumpPower = true
        hum.JumpPower = JumpPowerValue
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if WalkSpeedLocked then ApplyWalkSpeed() end
    if JumpPowerLocked then ApplyJumpPower() end
end)

if LocalPlayer.Character then
    if WalkSpeedLocked then ApplyWalkSpeed() end
    if JumpPowerLocked then ApplyJumpPower() end
end

-- ===== แท็บ Anti Lag =====
local PerformanceTab = Window:Tab({ Title = "ประสิทธิภาพ", Icon = "gauge" })

PerformanceTab:Section({ Title = "ลดแลค", Desc = "ลบสิ่งของที่ไม่จำเป็นเพื่อเพิ่ม FPS" })

local RemovedItems = {}

PerformanceTab:Button({
    Title = "ลบต้นไม้/พุ่มไม้",
    Icon = "trash-2",
    Callback = function()
        local count = 0
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = string.lower(obj.Name)
                if string.find(n, "tree") or string.find(n, "bush") or string.find(n, "plant") then
                    obj.Transparency = 1
                    obj.CanCollide = false
                    table.insert(RemovedItems, obj)
                    count = count + 1
                end
            end
        end
        WindUI:Notify({ Title = "Anti Lag", Content = "ซ่อนแล้ว " .. count .. " ชิ้น", Duration = 3 })
    end,
})

PerformanceTab:Button({
    Title = "ปิดเงา (Shadows)",
    Icon = "sun",
    Callback = function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        game:GetService("Lighting").GlobalShadows = false
        WindUI:Notify({ Title = "Anti Lag", Content = "ปิดเงาและลดคุณภาพกราฟิกแล้ว", Duration = 3 })
    end,
})

PerformanceTab:Button({
    Title = "ลดระยะมองเห็น (Fog/Distance)",
    Icon = "eye-off",
    Callback = function()
        local Lighting = game:GetService("Lighting")
        Lighting.FogEnd = 300
        workspace.StreamingTargetRadius = 300
        WindUI:Notify({ Title = "Anti Lag", Content = "ลดระยะ Render แล้ว", Duration = 3 })
    end,
})

PerformanceTab:Button({
    Title = "คืนค่าทั้งหมด",
    Icon = "rotate-ccw",
    Callback = function()
        for _, obj in ipairs(RemovedItems) do
            if obj and obj.Parent then
                obj.Transparency = 0
                obj.CanCollide = true
            end
        end
        table.clear(RemovedItems)
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        game:GetService("Lighting").GlobalShadows = true
        game:GetService("Lighting").FogEnd = 100000
        WindUI:Notify({ Title = "Anti Lag", Content = "คืนค่าทุกอย่างแล้ว", Duration = 3 })
    end,
})

-- ===== แท็บสคริปต์ =====
Core.Scripts(Window, WindUI)

-- ===== ตั้งค่า (ต้องอยู่ล่างสุดเสมอ) =====
Core.Settings(Window, WindUI)
