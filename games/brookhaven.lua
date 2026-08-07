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

-- ===== ตั้งค่า (ต้องอยู่ล่างสุดเสมอ) =====
Core.Settings(Window, WindUI)
