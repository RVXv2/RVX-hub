local Core = loadstring(game:HttpGet("https://raw.githubusercontent.com/RVXv2/RVX-hub/main/games/core.lua"))()
local Window, WindUI = Core.Init("Brookhaven-RP")

-- ===== แท็บเพลง =====
local Songs = loadstring(game:HttpGet("https://raw.githubusercontent.com/RVXv2/RVX-hub/main/games/songs.lua"))()
Songs.AddSongsTab(Window, WindUI)

-- ===== แท็บเทเลพอต =====
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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

TeleportTab:Dropdown({
    Title = "เลือกผู้เล่น",
    Values = GetPlayerNames(),
    Callback = function(selected)
        SelectedPlayer = selected
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
            WindUI:Notify({ Title = "ผิดพลาด", Content = "หาผู้เล่นไม่เจอ", Duration = 3 })
        end
    end,
})

-- ===== แท็บการป้องกัน =====
local ProtectionTab = Window:Tab({ Title = "การป้องกัน", Icon = "shield" })

local AntiSitAll = false
local AntiSitChair = false
local AntiSitVehicle = false
local AntiKnockback = false
local AntiRagdoll = false

local function GetHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
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
    task.wait(1)
    local hum = char:FindFirstChildOfClass("Humanoid")
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

ProtectionTab:Section({ Title = "การนั่ง", Desc = "ป้องกันไม่ให้ตัวละครนั่งได้" })

ProtectionTab:Toggle({
    Title = "กันนั่งทุกอย่าง",
    Desc = "บล็อกทุกจุดพร้อมกัน (เก้าอี้ + รถ + อื่นๆ)",
    Value = false,
    Callback = function(state)
        AntiSitAll = state
        ApplySitAllState()
        WindUI:Notify({ Title = "การป้องกัน", Content = "กันนั่งทุกอย่าง: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

ProtectionTab:Toggle({
    Title = "กันนั่งเก้าอี้",
    Desc = "เฉพาะที่นั่งทั่วไป ไม่รวมรถ",
    Value = false,
    Callback = function(state)
        AntiSitChair = state
        WindUI:Notify({ Title = "การป้องกัน", Content = "กันนั่งเก้าอี้: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

ProtectionTab:Toggle({
    Title = "กันนั่งรถ",
    Desc = "เฉพาะเบาะรถ ไม่รวมเก้าอี้",
    Value = false,
    Callback = function(state)
        AntiSitVehicle = state
        WindUI:Notify({ Title = "การป้องกัน", Content = "กันนั่งรถ: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

ProtectionTab:Section({ Title = "แรงกระแทก", Desc = "ป้องกันการถูกเหวี่ยง/ล้ม" })

ProtectionTab:Toggle({
    Title = "กันโดนดีด",
    Desc = "ป้องกันการถูกดีด (Knockback)",
    Value = false,
    Callback = function(state)
        AntiKnockback = state
        ApplyRagdollStates()
        WindUI:Notify({ Title = "การป้องกัน", Content = "กันโดนดีด: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

ProtectionTab:Toggle({
    Title = "กันล้ม",
    Desc = "ป้องกัน Ragdoll",
    Value = false,
    Callback = function(state)
        AntiRagdoll = state
        ApplyRagdollStates()
        WindUI:Notify({ Title = "การป้องกัน", Content = "กันล้ม: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

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
                    count += 1
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

-- ===== ตั้งค่า (ต้องอยู่ล่างสุดเสมอ) =====
Core.Settings(Window, WindUI)
