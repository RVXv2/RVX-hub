--[[
    RVX-hub: Fisch Module (เอาเฉพาะฟังก์ชัน ไม่มี UI ของตัวเอง)

    ดัดแปลงมาจาก "2K Script — FISCH" — ตัดส่วน Fluent UI (หน้าต่าง/ปุ่มลอย/ธีม) ออกทั้งหมด
    เอาไว้แค่ตัว logic การทำงานจริง (auto fish, auto sell, teleport, movement, anti-afk,
    visuals) แล้วสร้างเป็น Tab ใหม่ชื่อ "Fisch" ผ่าน WindUI ที่ Hub หลักสร้างไว้แล้ว

    ไฟล์นี้ export table ที่มี Init(Window, WindUI) เหมือนโมดูลอื่น (เช่น greedygrowers.lua)
    ต้องโหลดผ่าน universal.lua โดยเพิ่มใน MAP_MODULES:

        [16732694052] = "https://raw.githubusercontent.com/RVXv2/RVX-hub/main/games/fisch.lua",
        -- 16732694052 คือ PlaceId ของเกม Fisch (https://www.roblox.com/games/16732694052/Fisch)
--]]

local Fisch = {}

function Fisch.Init(Window, WindUI)
    -- ===== กันสร้างซ้ำถ้า Init ถูกเรียกซ้ำ (เช่น rerun ทั้ง hub) =====
    if _G.FischCleanup then pcall(_G.FischCleanup) end
    _G.FischRunning = false

    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local Lighting = game:GetService("Lighting")
    local UserInputService = game:GetService("UserInputService")
    local RS = game:GetService("ReplicatedStorage")
    local VIM = game:GetService("VirtualInputManager")

    local thisRunId = HttpService:GenerateGUID(false)
    _G.FischRunId = thisRunId
    _G.FischRunning = true

    local _conns = {}
    _G.FischCleanup = function()
        _G.FischRunning = false
        _G.FischRunId = nil
        for _, c in ipairs(_conns) do pcall(function() c:Disconnect() end) end
        table.clear(_conns)
        local oldP = Workspace:FindFirstChild("2K_WaterWalk")
        if oldP then oldP:Destroy() end
    end

    -- ===== Services, Remotes & Libraries =====
    local LP = Players.LocalPlayer
    local PlayerGui = LP:WaitForChild("PlayerGui")
    local EventsFolder = RS:WaitForChild("events")

    local SellEverythingFunc = EventsFolder:WaitForChild("selleverything")
    local SellSingleFunc = EventsFolder:FindFirstChild("Sell")
    local VirtualUser = game:GetService("VirtualUser")

    local fishLib = nil
    pcall(function()
        fishLib = require(RS.shared.modules.library.fish)
    end)

    -- ===== State (ค่าเริ่มต้นทั้งหมด false ยกเว้น AntiAFK) =====
    local State = {
        AntiAFK          = true,

        FullAutoFish     = false,
        AutoCast         = false,
        CastPower        = 100,
        AutoShake        = false,
        AutoReel         = false,
        AutoEquipRod     = false,

        AutoSell         = false,
        SellInterval     = 30,
        SellAllBypass    = false,
        SelectedRarities = {
            ["Trash"] = true, ["Common"] = true, ["Uncommon"] = true, ["Unusual"] = true,
            ["Rare"] = false, ["Legendary"] = false, ["Mythical"] = false,
            ["Exotic"] = false, ["Secret"] = false,
        },

        WalkSpeed    = 16,
        JumpPower    = 50,
        InfJump      = false,
        Noclip       = false,
        WalkOnWater  = false,

        Fullbright   = false,

        SelectedIsland = "Moosewood (ท่าตกปลา Pier)",

        CastDebounce = false,
        SellDebounce = false,
    }

    -- ===== พิกัดเกาะ =====
    local IslandData = {
        ["Moosewood (ท่าตกปลา Pier)"]        = {pos = Vector3.new(357.46, 133.68, 238.47), look = Vector3.new(-0.959, 0, -0.281)},
        ["Moosewood (หมู่บ้านเริ่มต้น)"]       = {pos = Vector3.new(495, 150, 230)},
        ["Roslit Bay (อ่าวรอสลิต)"]            = {pos = Vector3.new(-1480, 133, 715)},
        ["Sunstone Island (เกาะซันสโตน)"]      = {pos = Vector3.new(-935, 132, -1125)},
        ["Terrapin Island (เกาะเต่า)"]         = {pos = Vector3.new(-170, 145, 1930)},
        ["Snowcap Island (เกาะหิมะ)"]          = {pos = Vector3.new(2620, 145, 2370)},
        ["Mushgrove Swamp (บึงเห็ด)"]          = {pos = Vector3.new(2430, 135, -680)},
        ["Forsaken Shores (ชายหาดร้าง)"]       = {pos = Vector3.new(-2485, 135, 1560)},
        ["Ancient Isle (เกาะโบราณ)"]           = {pos = Vector3.new(5880, 155, 340)},
        ["Statue of Sovereignty (รูปปั้น)"]    = {pos = Vector3.new(28, 135, -840)},
        ["The Depths (ใต้บาดาล)"]              = {pos = Vector3.new(954, -710, 1218)},
        ["Vertigo (เกาะเวอร์ติโก)"]            = {pos = Vector3.new(-118, -488, 1019)},
        ["Desolate Deep (ห้วงลึก)"]            = {pos = Vector3.new(-1655, -235, -2845)},
        ["คนรับซื้อปลา Moosewood (Merchant)"] = {pos = Vector3.new(465, 151, 235)},
        ["ห้องมนตรา (Enchant Room)"]          = {pos = Vector3.new(1316, -401, -44)},
    }

    local function teleportTo(entry)
        pcall(function()
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos = typeof(entry) == "table" and entry.pos or entry
                local look = typeof(entry) == "table" and entry.look
                if look then
                    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0), pos + look)
                else
                    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0))
                end
            end
        end)
    end

    -- ===== ตกปลา & ขายปลา =====
    local function isRodTool(tool)
        if not tool or not tool:IsA("Tool") then return false end
        if tool:FindFirstChild("values") and tool.values:FindFirstChild("casted") then return true end
        if string.find(string.lower(tool.Name), "rod") then return true end
        return false
    end

    local function getRod()
        if LP.Character then
            for _, v in ipairs(LP.Character:GetChildren()) do
                if isRodTool(v) then return v end
            end
        end
        for _, v in ipairs(LP.Backpack:GetChildren()) do
            if isRodTool(v) then return v end
        end
        return nil
    end

    local function getFishRarity(tool)
        if not tool or not tool:IsA("Tool") then return nil end
        if fishLib and fishLib[tool.Name] and fishLib[tool.Name].Rarity then
            return fishLib[tool.Name].Rarity
        end
        local rAttr = tool:GetAttribute("Rarity")
        if rAttr then return tostring(rAttr) end
        local rVal = tool:FindFirstChild("Rarity")
        if rVal and rVal:IsA("StringValue") then return rVal.Value end
        return nil
    end

    local function isRarityAllowedToSell(rarity)
        if not rarity then return false end
        if State.SellAllBypass then return true end
        return State.SelectedRarities[rarity] == true
    end

    local function executeSell()
        if State.SellDebounce then return end
        State.SellDebounce = true

        pcall(function()
            if State.SellAllBypass then
                pcall(function() SellEverythingFunc:InvokeServer() end)
                return
            end

            local char = LP.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then return end

            local currentHeld = char:FindFirstChildOfClass("Tool")
            local itemsToSell = {}

            local function collectFish(container)
                if not container then return end
                for _, t in ipairs(container:GetChildren()) do
                    if t:IsA("Tool") and not isRodTool(t) then
                        local rarity = getFishRarity(t)
                        if rarity and isRarityAllowedToSell(rarity) then
                            table.insert(itemsToSell, t)
                        end
                    end
                end
            end

            collectFish(LP.Backpack)
            collectFish(char)

            if #itemsToSell == 0 then return end

            for _, fishTool in ipairs(itemsToSell) do
                if fishTool.Parent then
                    pcall(function()
                        hum:EquipTool(fishTool)
                        task.wait(0.12)
                        if SellSingleFunc then
                            SellSingleFunc:InvokeServer()
                        end
                        task.wait(0.08)
                    end)
                end
            end

            if currentHeld and currentHeld.Parent and (State.AutoEquipRod or State.FullAutoFish) then
                pcall(function() hum:EquipTool(currentHeld) end)
            else
                local rod = getRod()
                if rod and (State.AutoEquipRod or State.FullAutoFish) and hum then
                    pcall(function() hum:EquipTool(rod) end)
                end
            end
        end)

        State.SellDebounce = false
    end

    -- ===== Hook ReelController (bar-locking สำหรับ auto reel) =====
    pcall(function()
        local rc = require(RS.client.legacyControllers:FindFirstChild("ReelController"))
        if rc and not rc._Hooked2K then
            rc._Hooked2K = true

            local oldIsInBar = rc.IsInBar
            rc.IsInBar = function(self, ...)
                if State.FullAutoFish or State.AutoReel then
                    return true
                end
                return oldIsInBar(self, ...)
            end

            local oldUpdate = rc.Update
            rc.Update = function(self, dt)
                if State.FullAutoFish or State.AutoReel then
                    self.barPosition = self.fishPosition
                end
                local res = oldUpdate(self, dt)
                if State.FullAutoFish or State.AutoReel then
                    self.barPosition = self.fishPosition
                end
                return res
            end
        end
    end)

    local function handleShake()
        local shakeUI = PlayerGui:FindFirstChild("shakeui")
        if not shakeUI then return end

        local safezone = shakeUI:FindFirstChild("safezone")
        if safezone then
            for _, btn in ipairs(safezone:GetChildren()) do
                if (btn:IsA("ImageButton") or btn:IsA("TextButton")) and btn.Visible then
                    pcall(function()
                        if firesignal then
                            firesignal(btn.Activated)
                            firesignal(btn.MouseButton1Click)
                        end
                        if getconnections then
                            for _, c in ipairs(getconnections(btn.Activated)) do pcall(function() c:Fire() end) end
                            for _, c in ipairs(getconnections(btn.MouseButton1Click)) do pcall(function() c:Fire() end) end
                        end
                    end)
                end
            end
        end
    end

    local function handleReel()
        local reelUI = PlayerGui:FindFirstChild("reel")
        if not reelUI then return end

        pcall(function()
            local ReelController = require(RS.client.legacyControllers:FindFirstChild("ReelController"))
            if ReelController and ReelController.ActiveReel then
                local reel = ReelController.ActiveReel
                if reel.fishPosition then
                    reel.barPosition = reel.fishPosition
                end
            end
        end)

        local bar = reelUI:FindFirstChild("bar")
        if bar then
            local fish = bar:FindFirstChild("fish")
            local playerbar = bar:FindFirstChild("playerbar")
            if fish and playerbar then
                playerbar.Position = UDim2.fromScale(fish.Position.X.Scale, playerbar.Position.Y.Scale)
            end
        end
    end

    local function handleCast()
        if State.CastDebounce then return end
        if PlayerGui:FindFirstChild("shakeui") or PlayerGui:FindFirstChild("reel") then return end

        local rod = getRod()
        if not rod then return end

        pcall(function()
            local sp = PlayerGui:FindFirstChild("hud") and PlayerGui.hud:FindFirstChild("safezone") and PlayerGui.hud.safezone:FindFirstChild("starterpack")
            if sp and sp.Visible then sp.Visible = false end
        end)

        if rod.Parent == LP.Backpack and (State.AutoEquipRod or State.FullAutoFish) and LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:EquipTool(rod) end
            task.wait(0.5)
        end

        if rod.Parent ~= LP.Character then return end

        if rod:FindFirstChild("bobber") or (rod:FindFirstChild("values") and rod.values:FindFirstChild("casted") and rod.values.casted.Value == true) then
            return
        end

        State.CastDebounce = true
        task.spawn(function()
            local doneCast = false
            pcall(function()
                local gui = PlayerGui:FindFirstChild("FishButtonMobile")
                local btn = gui and gui:FindFirstChild("Frame") and gui.Frame:FindFirstChild("button")
                if btn then
                    local c_began = getconnections(btn.InputBegan)
                    local c_ended = getconnections(btn.InputEnded)
                    local mockInput = { UserInputType = Enum.UserInputType.MouseButton1, KeyCode = Enum.KeyCode.Unknown }

                    if c_began[1] and c_began[1].Function then
                        task.spawn(c_began[1].Function, mockInput)
                        local holdTime = math.clamp((State.CastPower / 100) * 0.55, 0.25, 0.6)
                        task.wait(holdTime)
                        if c_ended[1] and c_ended[1].Function then
                            task.spawn(c_ended[1].Function, mockInput)
                        end
                        doneCast = true
                    end
                end
            end)

            if not doneCast then
                pcall(function()
                    if mouse1press and mouse1release then
                        mouse1press()
                        task.wait(0.4)
                        mouse1release()
                    elseif VIM and VIM.SendMouseButtonEvent then
                        VIM:SendMouseButtonEvent(150, 500, 0, true, game, 0)
                        task.wait(0.4)
                        VIM:SendMouseButtonEvent(150, 500, 0, false, game, 0)
                    end
                end)
            end

            task.wait(2.2)
            State.CastDebounce = false
        end)
    end

    -- ===== Loop: ตกปลา =====
    task.spawn(function()
        while _G.FischRunning and _G.FischRunId == thisRunId do
            if State.FullAutoFish or State.AutoShake then handleShake() end
            if State.FullAutoFish or State.AutoReel then handleReel() end
            if State.FullAutoFish or State.AutoCast then handleCast() end
            task.wait(0.06)
        end
    end)

    -- ===== Loop: ขายปลา =====
    task.spawn(function()
        while _G.FischRunning and _G.FischRunId == thisRunId do
            if State.AutoSell then executeSell() end
            task.wait(State.SellInterval)
        end
    end)

    -- ===== Anti-AFK =====
    pcall(function()
        if getconnections then
            for _, c in ipairs(getconnections(LP.Idled)) do
                pcall(function() c:Disable() end)
            end
        end
    end)

    local function purgeAfkTags(char)
        if not char then return end
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("BillboardGui") and (desc.Name:lower():find("afk") or desc.Name:lower():find("idle")) then
                pcall(function() desc.Enabled = false end)
            elseif desc:IsA("TextLabel") and (desc.Text:find("%[AFK%]") or desc.Text:find("AFK")) then
                pcall(function() desc.Visible = false end)
            end
        end
    end

    if LP.Character then purgeAfkTags(LP.Character) end
    table.insert(_conns, LP.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        purgeAfkTags(char)
        table.insert(_conns, char.DescendantAdded:Connect(function(desc)
            if desc:IsA("BillboardGui") and (desc.Name:lower():find("afk") or desc.Name:lower():find("idle")) then
                pcall(function() desc.Enabled = false end)
            elseif desc:IsA("TextLabel") and (desc.Text:find("%[AFK%]") or desc.Text:find("AFK")) then
                pcall(function() desc.Visible = false end)
            end
        end))
    end))

    table.insert(_conns, LP.Idled:Connect(function()
        if not State.AntiAFK then return end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end))

    task.spawn(function()
        while _G.FischRunning and _G.FischRunId == thisRunId do
            if State.AntiAFK and LP.Character then
                purgeAfkTags(LP.Character)
            end
            task.wait(5)
        end
    end)

    -- ===== การเคลื่อนที่ & เดินบนน้ำ =====
    local waterPlatform = nil

    table.insert(_conns, RunService.Stepped:Connect(function()
        if not _G.FischRunning or _G.FischRunId ~= thisRunId then return end

        local char = LP.Character
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if State.WalkSpeed and State.WalkSpeed ~= 16 then
                hum.WalkSpeed = State.WalkSpeed
            end
            if State.JumpPower and State.JumpPower ~= 50 then
                hum.JumpPower = State.JumpPower
            end
        end

        if State.Noclip then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end

        if State.WalkOnWater then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if not waterPlatform then
                    waterPlatform = Instance.new("Part")
                    waterPlatform.Name = "2K_WaterWalk"
                    waterPlatform.Size = Vector3.new(24, 1.2, 24)
                    waterPlatform.Anchored = true
                    waterPlatform.CanCollide = true
                    waterPlatform.Transparency = 1
                    waterPlatform.Parent = Workspace
                end
                local p = hrp.Position
                local surfaceY = 127.2
                if p.Y > 120 then
                    waterPlatform.CFrame = CFrame.new(p.X, surfaceY - 0.6, p.Z)
                else
                    waterPlatform.CFrame = CFrame.new(p.X, -9999, p.Z)
                end
            end
        else
            if waterPlatform then
                waterPlatform:Destroy()
                waterPlatform = nil
            end
        end
    end))

    table.insert(_conns, UserInputService.JumpRequest:Connect(function()
        if State.InfJump and LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end))

    table.insert(_conns, RunService.RenderStepped:Connect(function()
        if not _G.FischRunning or _G.FischRunId ~= thisRunId then return end
        if State.Fullbright then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        end
    end))

    local function applyBoostFPS()
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                    v.Enabled = false
                end
            end
        end)
    end

    -- ===========================================================
    -- ===== UI Tab: Fisch (WindUI ของ Hub หลัก ไม่ใช่ Fluent) =====
    -- ===========================================================
    local FischTab = Window:Tab({ Title = "Fisch", Icon = "fish" })

    FischTab:Section({ Title = "ตกปลาอัตโนมัติ", Desc = "หยิบคันเบ็ด เหวี่ยง เขย่า และดึงปลาอัตโนมัติ" })

    FischTab:Toggle({
        Title = "ตกปลาอัตโนมัติ (Full Auto Fish)",
        Desc = "เปิดครบวงจรในปุ่มเดียว: หยิบคัน+เหวี่ยง+เขย่า+ดึง",
        Value = false,
        Callback = function(state)
            State.FullAutoFish = state
            State.AutoEquipRod = state
            State.AutoCast = state
            State.AutoShake = state
            State.AutoReel = state
        end,
    })

    FischTab:Slider({
        Title = "พลังเหวี่ยงเบ็ด (%)",
        Value = { Min = 20, Max = 100, Default = 100 },
        Callback = function(value)
            State.CastPower = value
        end,
    })

    FischTab:Section({ Title = "ขายปลาอัตโนมัติ", Desc = "ขายปลาตามระดับที่เลือกไว้ตามรอบเวลา" })

    FischTab:Toggle({
        Title = "ขายปลาอัตโนมัติ",
        Value = false,
        Callback = function(state)
            State.AutoSell = state
        end,
    })

    FischTab:Toggle({
        Title = "ขายทั้งหมดไม่สนระดับ",
        Desc = "เปิดแล้วจะขายปลาทุกตัวโดยไม่สนใจตัวเลือก rarity ด้านล่าง",
        Value = false,
        Callback = function(state)
            State.SellAllBypass = state
        end,
    })

    FischTab:Slider({
        Title = "ความถี่ขาย (วินาที)",
        Value = { Min = 10, Max = 300, Default = 30 },
        Callback = function(value)
            State.SellInterval = value
        end,
    })

    FischTab:Button({
        Title = "ขายตามเงื่อนไขทันที",
        Icon = "coins",
        Callback = function()
            executeSell()
            pcall(function()
                WindUI:Notify({ Title = "Fisch", Content = "ขายปลาตามเงื่อนไขเรียบร้อยแล้ว", Duration = 2.5 })
            end)
        end,
    })

    FischTab:Section({ Title = "เลือกระดับปลาที่จะขาย", Desc = "ปิดตัวไหนไว้ ปลาระดับนั้นจะไม่ถูกขาย (เก็บไว้ในตัว)" })

    local RARITY_ORDER = { "Trash", "Common", "Uncommon", "Unusual", "Rare", "Legendary", "Mythical", "Exotic", "Secret" }
    for _, rarity in ipairs(RARITY_ORDER) do
        FischTab:Toggle({
            Title = rarity,
            Value = State.SelectedRarities[rarity],
            Callback = function(state)
                State.SelectedRarities[rarity] = state
            end,
        })
    end

    FischTab:Section({ Title = "เทเลพอร์ต", Desc = "วาร์ปไปยังเกาะหรือจุดสำคัญต่างๆ" })

    local islandNames = {}
    for name in pairs(IslandData) do table.insert(islandNames, name) end
    table.sort(islandNames)

    FischTab:Dropdown({
        Title = "เลือกเกาะปลายทาง",
        Values = islandNames,
        Value = State.SelectedIsland,
        Callback = function(selected)
            State.SelectedIsland = selected
        end,
    })

    FischTab:Button({
        Title = "วาร์ปไปยังเกาะที่เลือก",
        Icon = "map-pin",
        Callback = function()
            local entry = IslandData[State.SelectedIsland]
            if entry then
                teleportTo(entry)
                pcall(function()
                    WindUI:Notify({ Title = "Fisch", Content = "วาร์ปไปยัง " .. State.SelectedIsland, Duration = 2.5 })
                end)
            end
        end,
    })

    FischTab:Button({
        Title = "วาร์ปไปคนรับซื้อปลา Moosewood",
        Icon = "store",
        Callback = function()
            teleportTo(IslandData["คนรับซื้อปลา Moosewood (Merchant)"])
        end,
    })

    FischTab:Button({
        Title = "วาร์ปไปห้องมนตรา (Enchant Room)",
        Icon = "sparkles",
        Callback = function()
            teleportTo(IslandData["ห้องมนตรา (Enchant Room)"])
        end,
    })

    FischTab:Section({ Title = "การเคลื่อนที่", Desc = "ปรับความเร็ว กระโดด และการเคลื่อนไหวพิเศษ" })

    FischTab:Slider({
        Title = "ความเร็วเดิน (WalkSpeed)",
        Value = { Min = 16, Max = 120, Default = 16 },
        Callback = function(value)
            State.WalkSpeed = value
        end,
    })

    FischTab:Slider({
        Title = "พลังกระโดด (JumpPower)",
        Value = { Min = 50, Max = 200, Default = 50 },
        Callback = function(value)
            State.JumpPower = value
        end,
    })

    FischTab:Toggle({
        Title = "กระโดดไม่จำกัด (Infinite Jump)",
        Value = false,
        Callback = function(state)
            State.InfJump = state
        end,
    })

    FischTab:Toggle({
        Title = "เดินทะลุกำแพง (Noclip)",
        Value = false,
        Callback = function(state)
            State.Noclip = state
        end,
    })

    FischTab:Toggle({
        Title = "เดินบนผิวน้ำ (Walk on Water)",
        Desc = "สร้างแท่นล่องหนให้เดินข้ามทะเลได้โดยไม่ต้องใช้เรือ",
        Value = false,
        Callback = function(state)
            State.WalkOnWater = state
        end,
    })

    FischTab:Section({ Title = "ป้องกัน & การแสดงผล", Desc = "กันโดนเตะเพราะ AFK และปรับกราฟิก" })

    FischTab:Toggle({
        Title = "ป้องกันถูกเตะ & ซ่อนป้าย AFK",
        Desc = "บล็อกป้าย [AFK] บนหัวตัวละคร และกัน Roblox เตะออกเมื่อปล่อยจอนาน",
        Value = true,
        Callback = function(state)
            State.AntiAFK = state
        end,
    })

    FischTab:Toggle({
        Title = "สว่างชัดทั้งแมพ (Fullbright)",
        Value = false,
        Callback = function(state)
            State.Fullbright = state
        end,
    })

    FischTab:Button({
        Title = "ลดแสงเงา/เอฟเฟกต์ (Boost FPS)",
        Icon = "gauge",
        Callback = function()
            applyBoostFPS()
            pcall(function()
                WindUI:Notify({ Title = "Fisch", Content = "ปิดเอฟเฟกต์ที่ไม่จำเป็นแล้ว", Duration = 2.5 })
            end)
        end,
    })

    print("[Fisch] โหลด Tab เรียบร้อย")
end

return Fisch
