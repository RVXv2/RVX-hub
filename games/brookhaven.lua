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

ProtectionTab:Section({ Title = "ป้องกันตัวละคร", Desc = "เลือกเปิดได้อิสระทีละอัน" })

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

ProtectionTab:Toggle({
    Title = "กันนั่งทุกอย่าง (บล็อกทุกจุดพร้อมกัน)",
    Value = false,
    Callback = function(state)
        AntiSitAll = state
        ApplySitAllState()
        WindUI:Notify({ Title = "การป้องกัน", Content = "กันนั่งทุกอย่าง: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

ProtectionTab:Toggle({
    Title = "กันนั่งเก้าอี้",
    Value = false,
    Callback = function(state)
        AntiSitChair = state
        WindUI:Notify({ Title = "การป้องกัน", Content = "กันนั่งเก้าอี้: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

ProtectionTab:Toggle({
    Title = "กันนั่งรถ",
    Value = false,
    Callback = function(state)
        AntiSitVehicle = state
        WindUI:Notify({ Title = "การป้องกัน", Content = "กันนั่งรถ: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

ProtectionTab:Toggle({
    Title = "กันโดนดีด (Knockback)",
    Value = false,
    Callback = function(state)
        AntiKnockback = state
        ApplyRagdollStates()
        WindUI:Notify({ Title = "การป้องกัน", Content = "กันโดนดีด: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

ProtectionTab:Toggle({
    Title = "กันล้ม (Ragdoll)",
    Value = false,
    Callback = function(state)
        AntiRagdoll = state
        ApplyRagdollStates()
        WindUI:Notify({ Title = "การป้องกัน", Content = "กันล้ม: " .. (state and "เปิด" or "ปิด"), Duration = 2 })
    end,
})

-- ===== ตั้งค่า (ต้องอยู่ล่างสุดเสมอ) =====
Core.Settings(Window, WindUI)
