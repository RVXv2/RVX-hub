--[[
    RVX-hub: Anime Dice Module (แปลงเป็น WindUI เต็มรูปแบบ — แยกแท็บตามต้นฉบับ 9 แท็บ)

    ดัดแปลงจาก "2K Script — ANIME DICE" (Fluent UI) มาเป็น Tab ใน WindUI ของ Hub หลัก
    โดยคงโครงสร้างแท็บเดิมไว้ครบทั้ง 9 แท็บ: ฟาร์มหลัก, หอคอย, แท่นเงิน, ขายตัว, เกรด,
    อัปเกรด&เต๋า, เว็บฮุก, เคลื่อนที่, ตั้งค่า&ธีม — ไม่ได้รวมเป็นแท็บเดียวเหมือน Fisch

    การเปลี่ยนแปลงจากต้นฉบับที่ควรรู้ (นอกเหนือจากการแปลง UI):
    1. Dropdown แบบ Multi-select 2 จุด (เลือก rarity ที่จะขาย, เลือกหมวดอัปเกรดที่เน้น)
       เปลี่ยนเป็น Toggle แยกทีละอันแทน เพราะไม่ยืนยัน API ของ WindUI Dropdown ว่ารองรับ
       Multi-select แบบเดียวกับ Fluent หรือไม่ — ปลอดภัยกว่า
    2. ฟีเจอร์ "sync widget ให้ตรงกับคอนฟิกที่โหลด" (ตอนกด Load Config) ถูกตัดออก เพราะ
       Fluent มี registry ชื่อ Fluent.Options ที่เก็บ handle ของทุก widget ไว้ให้อัตโนมัติ
       แต่ WindUI ไม่มีกลไกแบบนี้ — ผลคือ: โหลดคอนฟิกแล้ว "ค่าที่ใช้งานจริงถูกต้องครบ"
       แต่ปุ่ม/สไลเดอร์บนหน้าจอจะยังโชว์ค่าเดิมจนกว่าจะปิดเปิดแท็บหรือรีรัน hub ใหม่
    3. ตัดส่วน "บังคับ Font ตัวหนาทับทุก TextLabel" ออก เพราะ hack โครงสร้างภายในของ
       Fluent (Window.Root) โดยเฉพาะ ซึ่งไม่มีใน WindUI

    ต้องโหลดผ่าน universal.lua โดยเพิ่มใน MAP_MODULES:

        [113290951185459] = "https://raw.githubusercontent.com/RVXv2/RVX-hub/main/games/animedice.lua",
        -- 113290951185459 คือ PlaceId ของเกม Anime Dice
--]]

local AnimeDice = {}

function AnimeDice.Init(Window, WindUI)

--[[
    ==============================================================================
    2K SCRIPT — ANIME DICE
    Edition: Pro Progression & Automation Hub
    Discord: https://discord.gg/4Yg72kYT6s
    Theme: 2K Frost Glassmorphism | Cyber Neon 2K Logo Button
    Features:
      - Auto Roll with server debounce synchronization
      - Auto Collect Plot Balance with configurable interval (วินาที)
      - Auto Equip Best Units with configurable interval (วินาที)
      - Auto Level Up Slots with precondition cost checks
      - Auto Buy Upgrades with Multi-Category Focus Dropdown & Priority Purchasing
      - Auto Rebirth with cost validation
      - Auto Buy New Dice
      - Auto Claim Freebies (Daily, Offline, Spins, Group if joined)
      - Movement Hacks (WalkSpeed, JumpPower, InfJump, Noclip)
      - Live Theme Switcher (2K Frost, Aqua, Light, Dark)
      - Built-in Community Discord Link & Copy Button
    ==============================================================================
]]

-- ── 1. STRICT AUTO-CLEANUP ───────────────────────────────────────────────────────
if _G.AnimeDiceCleanup then pcall(_G.AnimeDiceCleanup) end
if _G.AnimeDiceWindow and _G.AnimeDiceWindow.Destroy then pcall(function() _G.AnimeDiceWindow:Destroy() end) end
if _G.AnimeDiceMinGui then pcall(function() _G.AnimeDiceMinGui:Destroy() end) end
_G.AnimeDiceRunning = false

local HttpService       = game:GetService("HttpService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local thisRunId         = HttpService:GenerateGUID(false)
_G.AnimeDiceRunId       = thisRunId
_G.AnimeDiceRunning     = true

local _conns = {}
_G.AnimeDiceCleanup = function()
    _G.AnimeDiceRunning = false
    _G.AnimeDiceRunId   = nil
    for _, c in ipairs(_conns) do pcall(function() c:Disconnect() end) end
    table.clear(_conns)
    if _G.AnimeDiceWindow and _G.AnimeDiceWindow.Destroy then
        pcall(function() _G.AnimeDiceWindow:Destroy() end)
        _G.AnimeDiceWindow = nil
    end
    if _G.AnimeDiceMinGui then
        pcall(function() _G.AnimeDiceMinGui:Destroy() end)
        _G.AnimeDiceMinGui = nil
    end
end

-- ── 2. SERVICES & NETWORK REMOTES ────────────────────────────────────────────────
local LP = Players.LocalPlayer
local network = RS:WaitForChild("Network")
local VirtualUser = game:GetService("VirtualUser")

local RollService            = network:WaitForChild("RollService")
local PlotService            = network:WaitForChild("PlotService")
local RebirthService         = network:WaitForChild("RebirthService")
local DiceShopService        = network:WaitForChild("DiceShopService")
local DailyRewardService     = network:WaitForChild("DailyRewardService")
local GroupRewardService     = network:WaitForChild("GroupRewardService")
local OfflineEarningsService = network:WaitForChild("OfflineEarningsService")
local SpinService            = network:WaitForChild("SpinService")
local UpgradeServiceRE       = network:WaitForChild("RE"):WaitForChild("BuyUpgrade")

-- Towers Network Remotes
local TowerNetwork           = network:FindFirstChild("Towers")
local EquipBestTowerTeamRE   = TowerNetwork and TowerNetwork:FindFirstChild("RE") and TowerNetwork.RE:FindFirstChild("EquipBestTowerTeam")
local PlayTowerRF            = TowerNetwork and TowerNetwork:FindFirstChild("RF") and TowerNetwork.RF:FindFirstChild("PlayTower")
local CancelTowerRF          = TowerNetwork and TowerNetwork:FindFirstChild("RF") and TowerNetwork.RF:FindFirstChild("CancelTower")

-- Grade Network Remotes
local GradeNetwork           = network:FindFirstChild("GradeService")
local SetGradeProtectedRE    = GradeNetwork and GradeNetwork:FindFirstChild("RE") and GradeNetwork.RE:FindFirstChild("SetGradeProtected")
local RollGradeRE            = GradeNetwork and GradeNetwork:FindFirstChild("RE") and GradeNetwork.RE:FindFirstChild("Roll")

-- Sell Network Remotes
local SellNetwork            = network:FindFirstChild("SellService")
local SellInventoryRF        = SellNetwork and SellNetwork:FindFirstChild("RF") and SellNetwork.RF:FindFirstChild("SellInventory")
local SellEquippedRF         = SellNetwork and SellNetwork:FindFirstChild("RF") and SellNetwork.RF:FindFirstChild("SellEquipped")
local UpdateAutoSellRE       = SellNetwork and SellNetwork:FindFirstChild("RE") and SellNetwork.RE:FindFirstChild("UpdateAutoSell")

local DataController         = require(RS.Framework.Features.Data.DataController)
local BuffController         = require(RS.Framework.Features.Buffs.BuffController)
local UnitUtil               = require(RS.Framework.Features.Inventory.Kinds.Unit.UnitUtil)
local EntryRegistry          = require(RS.Framework.Features.Inventory.EntryRegistry)
local GradesModule           = require(RS.Framework.Features.Grades.Grades)
local TreeStructure          = require(RS.Framework.Features.Upgrades.TreeStructure)
local RebirthsModule         = require(RS.Framework.Features.Rebirth.Rebirths)
local UpgradesModule         = require(RS.Framework.Features.Upgrades.Upgrades)
local DiceModule             = require(RS.Framework.Features.Rolling.Dice)
local GroupRewardConfig      = require(RS.Framework.Features.Rewards.GroupRewardConfig)
local NumberFormatter        = require(RS.Packages.NumberFormatter)

local httpRequest            = (request or http_request or (syn and syn.request) or (http and http.request))

local TowerController        = nil
pcall(function()
    TowerController = require(RS.Framework.Features.Towers.TowerController)
end)
local UIReferences           = nil
pcall(function()
    UIReferences = require(RS.Framework.Features.UI.UIReferences)
end)
local TowersModule           = nil
pcall(function()
    TowersModule = require(RS.Framework.Features.Towers.Towers)
end)

-- ── 3. UPGRADE CATEGORIES & TOWER MAPPING ────────────────────────────────────────
local UpgradeCategories = {
    ["Luck & Fortune (โชคและดวง)"]      = {"Luck", "Fortune"},
    ["Roll Speed (ความเร็วหมุน)"]       = {"Roll Speed"},
    ["Money (เงินและเหรียญ)"]           = {"Money"},
    ["Unit Storage (ช่องเก็บตัวละคร)"]   = {"Unit Storage"},
    ["Damage (พลังโจมตี)"]              = {"Damage"},
    ["Health (พลังชีวิต)"]              = {"Health"},
    ["Walkspeed (ความเร็วเดิน)"]        = {"Walkspeed"},
    ["Sell (ราคาขาย)"]                  = {"Sell"},
}

local function getCategoryOfKey(key)
    for catName, prefixes in pairs(UpgradeCategories) do
        for _, p in ipairs(prefixes) do
            if key:sub(1, #p) == p then
                return catName
            end
        end
    end
    return "Other"
end

-- Tower display mappings
local TowerDisplayNameMap = {
    ["Dragon Tower (ระดับ ง่าย - 100 ชั้น)"]          = "Dragon Tower",
    ["Cursed Tower (ระดับ ปานกลาง - 100 ชั้น)"]       = "Cursed Tower",
    ["Pirate Tower (ระดับ ยาก - 100 ชั้น)"]           = "Pirate Tower",
    ["Hidden Leaf Tower (ระดับ โหด - 100 ชั้น)"]      = "Hidden Leaf Tower",
    ["Infinity Tower (ระดับ อินฟินิตี้ - ไม่จำกัด)"] = "Infinity Tower",
}

local TowerDisplayOptions = {
    "Dragon Tower (ระดับ ง่าย - 100 ชั้น)",
    "Cursed Tower (ระดับ ปานกลาง - 100 ชั้น)",
    "Pirate Tower (ระดับ ยาก - 100 ชั้น)",
    "Hidden Leaf Tower (ระดับ โหด - 100 ชั้น)",
    "Infinity Tower (ระดับ อินฟินิตี้ - ไม่จำกัด)",
}

-- Grade, Rarity & Rebirth mappings
local GradeOrder = {
    ["D"] = 1,
    ["C"] = 2,
    ["B"] = 3,
    ["A"] = 4,
    ["A+"] = 5,
    ["S"] = 6,
    ["S+"] = 7,
    ["Z"] = 8,
    ["Z+"] = 9,
    ["神"] = 10
}

local RarityOrder = {
    ["Common"] = 1,
    ["Uncommon"] = 2,
    ["Rare"] = 3,
    ["Epic"] = 4,
    ["Legendary"] = 5,
    ["Mythical"] = 6,
    ["Secret I"] = 7,
    ["Secret"] = 7,
    ["Exotic"] = 8,
    ["Celestial"] = 9,
    ["Divine"] = 10,
    ["Exclusive"] = 11
}

local RebirthDisplayOptions = {
    "Rebirth 1",
    "Rebirth 2",
    "Rebirth 3",
    "Rebirth 4",
    "Rebirth 5",
    "Rebirth 6",
    "Rebirth 7",
    "Rebirth 8",
    "Rebirth 9",
    "Rebirth 10",
    "Rebirth 11",
    "Rebirth 12 (MAX)",
    "ไม่จำกัด / สูงสุดตลอดเวลา"
}

-- ── 4. STATE & SETTINGS (เริ่มต้นปิดการทำงานทั้งหมด ทุกระบบเป็น FALSE) ───────────
local State = {
    -- Anti-AFK (100% Safe Client-Side - เปิดใช้งานเป็นมาตรฐาน)
    AntiAFK                  = true,

    -- Auto Farming (ALL FALSE BY DEFAULT)
    AutoRoll                 = false,
    AutoCollect              = false,
    CollectInterval          = 0.5,
    AutoEquipBest            = false,
    EquipInterval            = 3.0,
    AutoLevelSlots           = false,
    TargetUnitLevel          = 30,
    AutoRebirth              = false,
    TargetRebirth            = 12,
    AutoUpgrades             = false,
    OnlySelectedUpgrades     = false,
    SelectedUpgradeCategories = {
        ["Luck & Fortune (โชคและดวง)"] = true,
        ["Roll Speed (ความเร็วหมุน)"] = true,
        ["Money (เงินและเหรียญ)"] = true,
    },
    AutoBuyDice              = false,
    AutoClaim                = false,

    -- Auto Sell Units (ALL FALSE / SAFE BY DEFAULT)
    AutoSellUnits            = false,
    SellInterval             = 5,
    InGameAutoSellThreshold  = 100000000, -- 100m (1 in 100,000,000)
    InGameAutoSellInput      = "100m",
    SellBelowChance          = false,     -- Include 1 in X chance check in inventory sweeping
    SelectedSellRarities     = {
        ["Common (ปกติ)"] = true,
        ["Uncommon (ไม่ธรรมดา)"] = true,
        ["Rare (หายาก)"] = true,
    },
    ProtectPlottedUnits      = true,
    ProtectGradeSPlus        = true,
    ProtectLockedUnits       = true,

    -- Grade System (ALL FALSE BY DEFAULT)
    AutoRerollGrade          = false,
    TargetGradeUnitKey       = "",
    TargetGrade              = "S",
    GradeRollDelay           = 0.35,

    -- Discord Webhook
    WebhookURL               = "",
    WebhookEnabled           = false,
    WebhookNotifyRolls       = true,
    WebhookMinRarity         = "Mythical",
    WebhookNotifyRebirth     = true,
    WebhookNotifyGrade       = true,
    WebhookPeriodicSummary   = false,
    WebhookSummaryInterval   = 15,

    -- Auto Tower (ALL FALSE BY DEFAULT)
    AutoTower                = false,
    SelectedTower            = "Dragon Tower",
    AutoEquipBestTowerTeam   = true,
    HideTowerScreen          = true,

    -- Movement (ALL FALSE BY DEFAULT)
    WalkSpeed                = 16,
    JumpPower                = 50,
    InfJump                  = false,
    Noclip                   = false,
}

-- ── 5. CORE AUTOMATION ENGINE ────────────────────────────────────────────────────

-- 1. Auto Collect Money from all 13 Plot Slots
local function collectAllSlots()
    pcall(function()
        for slot = 1, 13 do
            PlotService.RE.CollectBalance:FireServer(slot)
        end
    end)
end

-- 2. Auto Equip Best Anime Units
local function equipBestUnits()
    pcall(function()
        PlotService.RE.EquipBest:FireServer()
    end)
end

-- 3. Auto Level Up Slots with Precondition Check (กันเงินไม่พอเตือน และคุมเพดานเลเวล)
local function levelUpAllSlots()
    pcall(function()
        local curMoney = DataController.Money()
        if not curMoney or curMoney <= 0 then return end
        local targetLvl = tonumber(State.TargetUnitLevel) or 30
        for slot = 1, 13 do
            local slotData = DataController.Slots[tostring(slot)] and DataController.Slots[tostring(slot)]()
            if slotData and slotData.unitId then
                local unitData = DataController.Inventory[slotData.unitId] and DataController.Inventory[slotData.unitId]()
                if unitData then
                    local currentLvl = (unitData.attributes and unitData.attributes.level) or 1
                    if currentLvl < targetLvl then
                        local price = UnitUtil.GetLevelPrice(unitData.name, unitData.attributes)
                        if price and curMoney >= price then
                            curMoney = curMoney - price
                            PlotService.RE.LevelUpSlot:FireServer(slot)
                        end
                    end
                end
            end
        end
    end)
end

-- Discord Webhook Helper Engine
local function sendDiscordWebhook(title, description, color, fields)
    if not State.WebhookEnabled or not State.WebhookURL or State.WebhookURL == "" or not httpRequest then return end
    task.spawn(function()
        pcall(function()
            local payload = {
                username = "2K Script | Anime Dice",
                avatar_url = "https://cdn.discordapp.com/attachments/1098670557457788938/1175114757186981989/2K_Logo.png",
                embeds = {
                    {
                        title = title,
                        description = description,
                        color = color or 0x00FFE0,
                        fields = fields or {},
                        footer = {
                            text = "2K Script • Anime Dice Automation • " .. os.date("%X")
                        },
                        timestamp = DateTime.now():ToIsoDate()
                    }
                }
            }
            httpRequest({
                Url = State.WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

-- 4. Auto Rebirth with Precondition & Target Limit Check
local function checkAndRebirth()
    pcall(function()
        local curRebirth = DataController.Rebirth()
        local targetRebirth = tonumber(State.TargetRebirth) or 12
        if curRebirth >= targetRebirth then return end

        local curMoney = DataController.Money()
        local nextData = RebirthsModule.GetNext(curRebirth)
        if nextData and nextData.cost and curMoney >= nextData.cost then
            RebirthService.RE.Rebirth:FireServer()
            if State.WebhookEnabled and State.WebhookNotifyRebirth then
                local newLvl = curRebirth + 1
                sendDiscordWebhook(
                    "จุติสำเร็จ! (Rebirth " .. tostring(newLvl) .. ")",
                    "ผู้เล่น **" .. LP.DisplayName .. "** ทำการจุติขั้นถัดไปเรียบร้อยแล้ว",
                    0xFFD700,
                    {
                        {name = "ระดับการจุติใหม่", value = "Rebirth " .. tostring(newLvl), inline = true},
                        {name = "ตัวคูณเงิน", value = "x" .. tostring(nextData.moneyMultiplier or "?"), inline = true},
                        {name = "ตัวคูณดวง", value = "x" .. tostring(nextData.luckMultiplier or "?"), inline = true}
                    }
                )
            end
        end
    end)
end

-- 4.1 Selectable Auto Sell Engine
local function sellSelectedUnits()
    local soldCount = 0
    local earned = 0
    pcall(function()
        if not SellInventoryRF then return end
        local inv = DataController.Inventory and DataController.Inventory()
        if not inv then return end

        local plotted = {}
        for slot = 1, 13 do
            local sData = DataController.Slots[tostring(slot)] and DataController.Slots[tostring(slot)]()
            if sData and sData.unitId then
                plotted[sData.unitId] = true
            end
        end

        local towerTeam = {}
        if DataController.TowerTeam then
            local tt = DataController.TowerTeam()
            if type(tt) == "table" then
                for _, uid in pairs(tt) do
                    if type(uid) == "string" then towerTeam[uid] = true end
                end
            end
        end

        local toSell = {}
        for id, unit in pairs(inv) do
            if type(unit) == "table" and unit.name and unit.attributes then
                local isPlotted = plotted[id] == true
                local isTower = towerTeam[id] == true
                local isLocked = unit.attributes and unit.attributes.locked == true

                local canSell = true
                if State.ProtectPlottedUnits and (isPlotted or isTower) then
                    canSell = false
                end
                if State.ProtectLockedUnits and isLocked then
                    canSell = false
                end
                if State.ProtectGradeSPlus and unit.attributes and unit.attributes.grade then
                    local gOrder = GradeOrder[unit.attributes.grade] or 0
                    if gOrder >= 6 then
                        canSell = false
                    end
                end

                if canSell then
                    local cfg = EntryRegistry.getEntryConfig(unit.name)
                    local rarity = (cfg and cfg.rarity) or "Unknown"
                    local match = false
                    for selName, isSelected in pairs(State.SelectedSellRarities) do
                        if isSelected and (selName == rarity or string.find(selName, rarity, 1, true)) then
                            match = true
                            break
                        end
                    end

                    if match then
                        table.insert(toSell, id)
                        if #toSell >= 50 then
                            break
                        end
                    elseif State.SellBelowChance and cfg and cfg.chance then
                        local ch = cfg.chance()
                        if ch and ch > 0 and ch < (State.InGameAutoSellThreshold or 0) then
                            table.insert(toSell, id)
                            if #toSell >= 50 then
                                break
                            end
                        end
                    end
                end
            end
        end

        if #toSell > 0 then
            local res1, res2 = SellInventoryRF:InvokeServer(toSell)
            earned = res1 or 0
            soldCount = res2 or #toSell
        end
    end)
    return soldCount, earned
end

-- 4.2 Auto Roll Grade Engine
local function rollGradeForSelectedUnit()
    local success = false
    pcall(function()
        if not RollGradeRE or not State.TargetGradeUnitKey or State.TargetGradeUnitKey == "" then return end
        local inv = DataController.Inventory
        if not inv then return end

        local unit = inv[State.TargetGradeUnitKey] and inv[State.TargetGradeUnitKey]()
        if not unit or not unit.attributes then return end

        local curGrade = unit.attributes.grade or "D"
        local curOrder = GradeOrder[curGrade] or 1
        local targetOrder = GradeOrder[State.TargetGrade] or 6

        if curOrder >= targetOrder then
            return -- Already at or above target grade
        end

        local gemData = inv.Gems and inv.Gems()
        if not gemData or (gemData.amount or 0) <= 0 then
            return -- No gems left
        end

        RollGradeRE:FireServer(State.TargetGradeUnitKey, true)
        success = true

        -- Check if rolled new grade and notify
        task.delay(0.2, function()
            pcall(function()
                local updatedUnit = inv[State.TargetGradeUnitKey] and inv[State.TargetGradeUnitKey]()
                if updatedUnit and updatedUnit.attributes and updatedUnit.attributes.grade then
                    local newGrade = updatedUnit.attributes.grade
                    local newOrder = GradeOrder[newGrade] or 1
                    if newOrder >= 6 and State.WebhookEnabled and State.WebhookNotifyGrade then
                        sendDiscordWebhook(
                            "สุ่มได้เกรดระดับสูง! (เกรด " .. newGrade .. ")",
                            "ตัวละคร **" .. updatedUnit.name .. "** ได้รับเกรดระดับสูงจากการสุ่ม",
                            0x9B59B6,
                            {
                                {name = "ตัวละคร", value = updatedUnit.name, inline = true},
                                {name = "เกรดที่ได้", value = newGrade, inline = true},
                                {name = "Gem คงเหลือ", value = tostring(inv.Gems and inv.Gems().amount or 0), inline = true}
                            }
                        )
                    end
                end
            end)
        end)
    end)
    return success
end

-- 5. Auto Buy Upgrades with Dropdown Category Prioritization
local function buyPrioritizedUpgrades()
    pcall(function()
        if not UpgradesModule or not TreeStructure then return end
        local curMoney = DataController.Money()
        if not curMoney or curMoney <= 0 then return end

        local unownedAvailable = {}
        for key, data in pairs(UpgradesModule) do
            local isOwned = DataController.Upgrades[key] and DataController.Upgrades[key]()
            if not isOwned then
                local parent = TreeStructure.GetParent(key)
                local parentUnlocked = (not parent or parent == "Start") or (DataController.Upgrades[parent] and DataController.Upgrades[parent]())
                if parentUnlocked and data.price and curMoney >= data.price then
                    table.insert(unownedAvailable, {
                        key = key,
                        price = data.price,
                        category = getCategoryOfKey(key)
                    })
                end
            end
        end

        if #unownedAvailable == 0 then return end

        local focusedList = {}
        local otherList = {}

        for _, item in ipairs(unownedAvailable) do
            if State.SelectedUpgradeCategories[item.category] then
                table.insert(focusedList, item)
            else
                table.insert(otherList, item)
            end
        end

        table.sort(focusedList, function(a, b) return a.price < b.price end)
        table.sort(otherList, function(a, b) return a.price < b.price end)

        -- ซื้อหมวดที่เลือกก่อนเสมอ
        for _, item in ipairs(focusedList) do
            if curMoney >= item.price then
                curMoney = curMoney - item.price
                UpgradeServiceRE:FireServer(item.key)
                task.wait(0.12)
            end
        end

        -- ถ้าไม่ได้ล็อกซื้อเฉพาะหมวดที่เลือก ให้ซื้อหมวดอื่นที่เหลือด้วย
        if not State.OnlySelectedUpgrades then
            for _, item in ipairs(otherList) do
                if curMoney >= item.price then
                    curMoney = curMoney - item.price
                    UpgradeServiceRE:FireServer(item.key)
                    task.wait(0.12)
                end
            end
        end
    end)
end

-- 6. Auto Buy Affordable Unowned Dice
local function buyAffordableDice()
    pcall(function()
        if not DiceModule then return end
        local allDice = DiceModule.GetAll()
        local curMoney = DataController.Money()
        for name, data in pairs(allDice) do
            local isOwned = DataController.OwnedDice[name] and DataController.OwnedDice[name]()
            if not isOwned and data.price and data.price <= curMoney then
                DiceShopService.RE.BuyDice:FireServer(name)
                task.wait(0.4)
            end
        end
    end)
end

-- 7. Auto Claim Free Rewards (เช็คกลุ่มก่อนเคลม ป้องกันขึ้นแจ้งเตือนซ้ำ)
local function claimAllFreebies()
    pcall(function()
        DailyRewardService.RE.Claim:FireServer()
        OfflineEarningsService.RE.Claim:FireServer()
        SpinService.RE.Use:FireServer()

        -- เคลมของขวัญกลุ่มเฉพาะเมื่อผู้เล่นอยู่ในกลุ่มและยังไม่เคยกดรับเท่านั้น
        if GroupRewardConfig and GroupRewardConfig.GroupId then
            local inGroup = false
            pcall(function()
                inGroup = LP:IsInGroup(GroupRewardConfig.GroupId)
            end)
            if inGroup and DataController.ClaimedGroupReward and not DataController.ClaimedGroupReward() then
                GroupRewardService.RE.Claim:FireServer()
            end
        end
    end)
end

-- 8. Auto Tower Automation Handler
local function handleAutoTower()
    pcall(function()
        if not State.AutoTower then return end

        local screen = UIReferences and UIReferences.Root and UIReferences.Root.Tower and UIReferences.Root.Tower.Screen
        local hidden = screen and screen.Parent and screen.Parent:FindFirstChild("Hidden")
        local inTower = (hidden and hidden.Visible == true) or (screen and screen.Visible == true)

        if inTower then
            -- ซ่อนหน้าจอต่อสู้หอคอยหากเปิดตัวเลือกไว้ เพื่อความลื่นไหลและไม่บังหน้าจอ
            if State.HideTowerScreen and screen and screen.Visible and hidden then
                pcall(function()
                    if firesignal then
                        firesignal(hidden.Activated)
                    end
                end)
            end

            -- ตรวจสอบและกดปุ่ม Auto ภายในเกมเพื่อให้อนิเมชั่นและชั้นถัดไปดำเนินต่อเนื่องทันที
            if screen and screen:FindFirstChild("Buttons") and screen.Buttons:FindFirstChild("Auto") then
                local autoBtn = screen.Buttons.Auto
                local grad = autoBtn:FindFirstChildOfClass("UIGradient")
                local isGreen = grad and tostring(grad.Color):find("0.298")
                if not isGreen and firesignal then
                    pcall(function() firesignal(autoBtn.Activated) end)
                end
            end
        else
            -- ผู้เล่นไม่ได้อยู่ในหอคอย: จัดทีมที่ดีที่สุดและสั่งเริ่มลงหอคอยที่เลือกทันที
            if State.AutoEquipBestTowerTeam and EquipBestTowerTeamRE then
                pcall(function() EquipBestTowerTeamRE:FireServer() end)
                task.wait(0.3)
            end

            local towerTarget = State.SelectedTower or "Dragon Tower"
            local started = false
            if TowerController and TowerController.startTower then
                started = TowerController.startTower(towerTarget)
            end
            if not started and PlayTowerRF then
                PlayTowerRF:InvokeServer(towerTarget)
            end
            task.wait(1.2)

            -- เมื่อเริ่มแล้ว ให้ซ่อนหน้าจอทันทีถ้าเปิดโหมดซ่อน
            if State.HideTowerScreen and screen and screen.Visible and hidden and firesignal then
                pcall(function() firesignal(hidden.Activated) end)
            end
        end
    end)
end

-- ── 5.1 ANTI-AFK & ANTI-KICK DEFENSE ENGINE (TRIPLE-LAYER ZERO-DISCONNECT) ────────

local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

-- เลเยอร์ 1: ทำลายสคริปต์ AFK 19 นาทีของตัวเกม (StarterPlayerScripts.AFK) ทันที
local function neutralizeGameAFK()
    pcall(function()
        local afkScript = LP.PlayerScripts:FindFirstChild("AFK")
        if afkScript then
            afkScript.Disabled = true
            afkScript:Destroy()
        end
    end)
end
neutralizeGameAFK()

table.insert(_conns, LP.PlayerScripts.ChildAdded:Connect(function(child)
    if child.Name == "AFK" and child:IsA("LocalScript") then
        pcall(function()
            child.Disabled = true
            child:Destroy()
        end)
    end
end))

-- เลเยอร์ 2: สกัดกั้นคำสั่ง Teleport เตะผู้เล่นที่เกิดจากสคริปต์ AFK
pcall(function()
    if hookfunction then
        local oldTeleport
        oldTeleport = hookfunction(TeleportService.Teleport, function(self, placeId, player, ...)
            if State.AntiAFK then
                local trace = debug.traceback()
                if string.find(trace, "AFK") or string.find(trace, "scheduleTeleport") then
                    return
                end
            end
            return oldTeleport(self, placeId, player, ...)
        end)
    end
end)

pcall(function()
    if hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if State.AntiAFK and (method == "Teleport" or method == "teleport") and self == TeleportService then
                local trace = debug.traceback()
                if string.find(trace, "AFK") or string.find(trace, "scheduleTeleport") then
                    return
                end
            end
            return oldNamecall(self, ...)
        end)
    end
end)

-- เลเยอร์ 3: บล็อกระบบเตะ 20 นาทีของ Roblox Engine (LP.Idled)
pcall(function()
    if getconnections then
        for _, c in ipairs(getconnections(LP.Idled)) do
            pcall(function() c:Disable() end)
        end
    end
end)

table.insert(_conns, LP.Idled:Connect(function()
    if not State.AntiAFK then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end))

-- เลเยอร์ 4: Virtual Input Heartbeat Loop ทุก 40 วินาที ส่งสัญญาณป้องกันหลุด 100%
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(40)
        if State.AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.zero)
            end)
            pcall(function()
                if VirtualInputManager then
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F15, false, game)
                    task.wait(0.03)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F15, false, game)
                end
            end)
            neutralizeGameAFK()
        end
    end
end)

-- ── 6. ASYNC AUTOMATION THREADS ──────────────────────────────────────────────────

-- Thread 1: Auto Collect Money (กำหนดวินาทีได้)
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        if State.AutoCollect then
            collectAllSlots()
        end
        local delaySec = tonumber(State.CollectInterval) or 0.5
        if delaySec < 0.1 then delaySec = 0.1 end
        task.wait(delaySec)
    end
end)

-- Thread 2: Auto Equip Best Units (กำหนดวินาทีได้)
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        if State.AutoEquipBest then
            equipBestUnits()
        end
        local delaySec = tonumber(State.EquipInterval) or 3.0
        if delaySec < 1.0 then delaySec = 1.0 end
        task.wait(delaySec)
    end
end)

-- Thread 3: Slot Level Ups
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(0.7)
        if State.AutoLevelSlots then
            levelUpAllSlots()
        end
    end
end)

-- Thread 4: Precise Roll Loop (Sync กับ Server Debounce)
task.spawn(function()
    local lastRollTime = 0
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(0.1)
        if State.AutoRoll then
            pcall(function()
                if not DataController.AutoRoll() then
                    RollService.RE.SetAutoRoll:FireServer(true)
                end
            end)

            local duration = 1.9
            pcall(function()
                local d = BuffController.GetBuff("Roll Duration")
                if type(d) == "number" and d > 0 then
                    duration = d
                end
            end)

            if os.clock() - lastRollTime >= (duration + 0.1) then
                lastRollTime = os.clock()
                pcall(function()
                    RollService.RF.RollDice:InvokeServer()
                end)
            end
        else
            pcall(function()
                if DataController.AutoRoll() then
                    RollService.RE.SetAutoRoll:FireServer(false)
                end
            end)
        end
    end
end)

-- Thread 5: Upgrades, Rebirth, Dice & Claims
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(1.5)
        if State.AutoRebirth then
            checkAndRebirth()
        end
        if State.AutoUpgrades then
            buyPrioritizedUpgrades()
        end
        if State.AutoBuyDice then
            buyAffordableDice()
        end
        if State.AutoClaim then
            claimAllFreebies()
        end
    end
end)

-- Thread 6: Auto Tower Loop
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(1.5)
        if State.AutoTower then
            handleAutoTower()
        end
    end
end)

-- Thread 7: Anti-AFK Background Heartbeat (รีเซ็ตเวลา 19 นาทีของเกม และกันหลุด 24/7)
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        if State.AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.zero)
            end)
        end
        task.wait(45)
    end
end)

-- Thread 8: Selectable Auto Sell Units Loop
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        local interval = tonumber(State.SellInterval) or 5
        if interval < 1 then interval = 1 end
        task.wait(interval)
        if State.AutoSellUnits then
            pcall(sellSelectedUnits)
        end
    end
end)

-- Thread 9: Auto Roll Grade Loop
task.spawn(function()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(State.GradeRollDelay or 0.35)
        if State.AutoRerollGrade then
            local ok = rollGradeForSelectedUnit()
            if not ok then
                State.AutoRerollGrade = false
            end
        end
    end
end)

-- Thread 10: Webhook High-Tier Rolls Watcher
task.spawn(function()
    local knownUnits = {}
    pcall(function()
        local inv = DataController.Inventory and DataController.Inventory()
        if inv then
            for id, _ in pairs(inv) do knownUnits[id] = true end
        end
    end)

    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(0.6)
        pcall(function()
            local inv = DataController.Inventory and DataController.Inventory()
            if not inv then return end

            for id, unit in pairs(inv) do
                if not knownUnits[id] and type(unit) == "table" and unit.name and unit.attributes then
                    knownUnits[id] = true

                    local cfg = EntryRegistry.getEntryConfig(unit.name)
                    local rarity = (cfg and cfg.rarity) or "Unknown"
                    local rarityRank = RarityOrder[rarity] or 0
                    local minRank = RarityOrder[State.WebhookMinRarity] or 6

                    if State.WebhookEnabled and State.WebhookNotifyRolls and rarityRank >= minRank then
                        local grade = unit.attributes.grade or "D"
                        local trait = unit.attributes.trait or "None"
                        local mutation = unit.attributes.mutation or "None"
                        sendDiscordWebhook(
                            "สุ่มได้ตัวละครระดับสูง! (" .. rarity .. ")",
                            "ผู้เล่น **" .. LP.DisplayName .. "** ได้รับตัวละครใหม่จากการสุ่ม",
                            0x00FFE0,
                            {
                                {name = "ตัวละคร", value = unit.name, inline = true},
                                {name = "ระดับความหายาก", value = rarity, inline = true},
                                {name = "เกรด", value = grade, inline = true},
                                {name = "คุณสมบัติ (Trait)", value = trait, inline = true},
                                {name = "การกลายพันธุ์", value = mutation, inline = true},
                                {name = "ระดับการจุติ", value = "Rebirth " .. tostring(DataController.Rebirth()), inline = true}
                            }
                        )
                    end
                end
            end
        end)
    end
end)

-- Thread 11: Webhook Periodic Stats Summary
task.spawn(function()
    local lastSummaryTime = os.clock()
    while _G.AnimeDiceRunning and _G.AnimeDiceRunId == thisRunId do
        task.wait(10)
        if State.WebhookEnabled and State.WebhookPeriodicSummary then
            local intervalSec = (tonumber(State.WebhookSummaryInterval) or 15) * 60
            if os.clock() - lastSummaryTime >= intervalSec then
                lastSummaryTime = os.clock()
                pcall(function()
                    local moneyStr = NumberFormatter.FormatCompact(DataController.Money() or 0)
                    local rebirthLvl = tostring(DataController.Rebirth() or 0)
                    local diceName = tostring(DataController.Dice() or "Default")
                    local invCount = 0
                    local inv = DataController.Inventory and DataController.Inventory()
                    if inv then
                        for _, u in pairs(inv) do
                            if type(u) == "table" and u.name then invCount = invCount + 1 end
                        end
                    end

                    sendDiscordWebhook(
                        "รายงานสถานะผู้เล่นประจำรอบ (Status Summary)",
                        "สรุปสถิติความก้าวหน้าของ **" .. LP.DisplayName .. "** (@" .. LP.Name .. ")",
                        0x4287F5,
                        {
                            {name = "ยอดเงินคงเหลือ", value = "$" .. moneyStr, inline = true},
                            {name = "ระดับการจุติ", value = "Rebirth " .. rebirthLvl, inline = true},
                            {name = "ลูกเต๋าที่ใช้งาน", value = diceName, inline = true},
                            {name = "จำนวนตัวละครในคลัง", value = tostring(invCount) .. " ตัว", inline = true},
                            {name = "หอคอยที่ฟาร์ม", value = State.SelectedTower or "None", inline = true},
                            {name = "ระยะเวลาฟาร์มรอบนี้", value = string.format("%.1f นาที", (os.clock()) / 60), inline = true}
                        }
                    )
                end)
            end
        end
    end
end)

-- ── 7. MOVEMENT ENHANCEMENTS ─────────────────────────────────────────────────────
table.insert(_conns, RunService.Stepped:Connect(function()
    if not _G.AnimeDiceRunning or _G.AnimeDiceRunId ~= thisRunId then return end
    local char = LP.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if hum.WalkSpeed ~= State.WalkSpeed and State.WalkSpeed > 16 then
            hum.WalkSpeed = State.WalkSpeed
        end
        if hum.JumpPower ~= State.JumpPower and State.JumpPower > 50 then
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
end))

table.insert(_conns, UserInputService.JumpRequest:Connect(function()
    if State.InfJump and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))


local Tabs = {
    Main     = Window:Tab({Title = "ฟาร์มหลัก",       Icon = "zap"}),
    Tower    = Window:Tab({Title = "หอคอย",           Icon = "shield"}),
    Plot     = Window:Tab({Title = "แท่นเงิน",        Icon = "home"}),
    AutoSell = Window:Tab({Title = "ขายตัว",          Icon = "trash-2"}),
    Grades   = Window:Tab({Title = "เกรด",            Icon = "award"}),
    Upgrades = Window:Tab({Title = "อัปเกรด & เต๋า",  Icon = "arrow-up-circle"}),
    Webhook  = Window:Tab({Title = "เว็บฮุก",         Icon = "send"}),
    Move     = Window:Tab({Title = "เคลื่อนที่",      Icon = "move"}),
    Settings = Window:Tab({Title = "ตั้งค่า & ธีม",   Icon = "palette"}),
}

-- ── TAB 1: ฟาร์มหลัก (MAIN AUTOMATION) ───────────────────────────────────────────
Tabs.Main:Section({ Title = "สุ่มเต๋า (Rolling)" })

Tabs.Main:Toggle({
    Title       = "สุ่มเต๋าอัตโนมัติ (Auto Roll)",
    Desc = "สุ่มต่อเนื่องตามความเร็วเซิร์ฟเวอร์",
    Value     = false,
    Callback    = function(v)
        State.AutoRoll = v
        WindUI:Notify({Title = "2K Script", Content = v and "เปิด Auto Roll แล้ว" or "ปิด Auto Roll", Duration = 2})
    end
})

Tabs.Main:Section({ Title = "จุติ & รางวัล (Rebirth & Claims)" })

Tabs.Main:Toggle({
    Title       = "จุติอัตโนมัติ (Auto Rebirth)",
    Desc = "เช็คเงินก่อนยิง ไม่แจ้งเตือนสแปม",
    Value     = false,
    Callback    = function(v) State.AutoRebirth = v end
})

local slideRebirthRef = nil

local dropTargetRebirth = Tabs.Main:Dropdown({
    Title       = "เป้าหมายการจุติ (Target Rebirth)",
    Desc = "หยุดจุติเมื่อถึงระดับที่เลือก",
    Values      = RebirthDisplayOptions,
    Value     = "Rebirth 12 (MAX)",
    Callback    = function(val)
        if val == "ไม่จำกัด / สูงสุดตลอดเวลา" then
            State.TargetRebirth = 999
        else
            local num = tonumber(string.match(val or "", "%d+"))
            if num then
                State.TargetRebirth = num
                if slideRebirthRef and slideRebirthRef.SetValue then
                    pcall(function() slideRebirthRef:SetValue(num) end)
                end
            end
        end
    end
})

slideRebirthRef = Tabs.Main:Slider({
    Title       = "เพดานระดับจุติ (1 - 12)",
        Value = { Min = 1, Max = 12, Default = 12 },
    Desc = "ปรับระดับจุติสูงสุดที่ต้องการ",
    Callback    = function(v)
        State.TargetRebirth = v
    end
})

Tabs.Main:Button({
    Title       = "จุติตอนนี้ 1 ครั้ง (Rebirth Now)",
    Desc = "สั่งจุติทันทีเมื่อเงินพอ",
    Callback    = function()
        checkAndRebirth()
        WindUI:Notify({Title = "2K Script", Content = "สั่งตรวจสอบและจุติเรียบร้อย", Duration = 2})
    end
})

Tabs.Main:Toggle({
    Title       = "รับของฟรีทั้งหมด (Auto Claim)",
    Desc = "รับรางวัลประจำวัน สปิน และรางวัลออฟไลน์",
    Value     = false,
    Callback    = function(v) State.AutoClaim = v end
})

Tabs.Main:Section({ Title = "ป้องกันหลุด (Anti-AFK)" })

Tabs.Main:Toggle({
    Title       = "ป้องกันหลุด 24/7 (Anti-AFK)",
    Desc = "กันหลุดและกันเกมเตะเมื่อปล่อยจอทิ้งไว้",
    Value     = true,
    Callback    = function(v) State.AntiAFK = v end
})

-- ── TAB: หอคอย (TOWERS AUTOMATION) ───────────────────────────────────────────────
Tabs.Tower:Section({ Title = "ฟาร์มหอคอย (Auto Tower)" })

Tabs.Tower:Dropdown({
    Title       = "เลือกหอคอย (Select Tower)",
    Desc = "เลือกระดับหอคอยที่ต้องการฟาร์ม",
    Values      = TowerDisplayOptions,
    Value     = 1,
    Callback    = function(v)
        State.SelectedTower = TowerDisplayNameMap[v] or "Dragon Tower"
    end
})

Tabs.Tower:Toggle({
    Title       = "ลงหอคอยอัตโนมัติ (Auto Tower)",
    Desc = "ฟาร์มหอคอยต่อเนื่อง แพ้หรือชนะเริ่มใหม่ทันที",
    Value     = false,
    Callback    = function(v)
        State.AutoTower = v
        WindUI:Notify({
            Title = "2K Script",
            Content = v and ("เริ่ม Auto Tower: " .. State.SelectedTower) or "ปิด Auto Tower แล้ว",
            Duration = 2.5
        })
    end
})

Tabs.Tower:Toggle({
    Title       = "จัดทีมตัวเก่งสุด (Equip Best Team)",
    Desc = "ดึงยูนิตดาเมจและเลือดสูงสุดลงทีมหอคอย",
    Value     = true,
    Callback    = function(v)
        State.AutoEquipBestTowerTeam = v
    end
})

Tabs.Tower:Toggle({
    Title       = "ซ่อนหน้าจอต่อสู้ (Hide Screen)",
    Desc = "ย่อหน้าจอหอคอยเพื่อความลื่นไหล",
    Value     = true,
    Callback    = function(v)
        State.HideTowerScreen = v
    end
})

Tabs.Tower:Section({ Title = "สั่งการหอคอย (Manual Controls)" })

Tabs.Tower:Button({
    Title       = "ลงหอคอยทันที (Play Tower Now)",
    Desc = "เริ่มลงหอคอยรอบปัจจุบัน 1 รอบ",
    Callback    = function()
        pcall(function()
            if State.AutoEquipBestTowerTeam and EquipBestTowerTeamRE then
                EquipBestTowerTeamRE:FireServer()
                task.wait(0.3)
            end
            local towerName = State.SelectedTower or "Dragon Tower"
            if TowerController and TowerController.startTower then
                TowerController.startTower(towerName)
            elseif PlayTowerRF then
                PlayTowerRF:InvokeServer(towerName)
            end
            WindUI:Notify({Title = "2K Script", Content = "เริ่มลง " .. towerName .. " แล้ว", Duration = 2})
        end)
    end
})

Tabs.Tower:Button({
    Title       = "ออกจากหอคอย (Exit Tower)",
    Desc = "ออกจากหอคอยทันที",
    Callback    = function()
        pcall(function()
            if CancelTowerRF then
                CancelTowerRF:InvokeServer()
            end
            WindUI:Notify({Title = "2K Script", Content = "ออกจากหอคอยเรียบร้อย", Duration = 2})
        end)
    end
})

-- ── TAB 2: แท่นรายได้ (PLOT & UNITS) ─────────────────────────────────────────────
Tabs.Plot:Section({ Title = "ดูดเงินแท่น (Collect Balance)" })

Tabs.Plot:Toggle({
    Title       = "ดูดเงินอัตโนมัติ (Auto Collect)",
    Desc = "ดูดเงินจากทุกแท่นตามเวลาที่ตั้งไว้",
    Value     = false,
    Callback    = function(v) State.AutoCollect = v end
})

Tabs.Plot:Slider({
    Title    = "ความถี่ดูดเงิน (วินาที)",
        Value = { Min = 0.1, Max = 5.0, Default = State.CollectInterval },
    Desc = "ปรับระยะเวลารอบการดูดเงิน (แนะนำ 0.3s - 0.5s)",
    Callback = function(v)
        State.CollectInterval = v
    end
})

Tabs.Plot:Button({
    Title       = "ดูดเงินทันที (Collect Now)",
    Desc = "ดูดเงินจากทุกแท่นทันที",
    Callback    = function()
        collectAllSlots()
        WindUI:Notify({Title = "2K Script", Content = "ดูดเงินจากทุกแท่นเรียบร้อย", Duration = 2})
    end
})

Tabs.Plot:Section({ Title = "สวมใส่ตัวละคร (Anime Units)" })

Tabs.Plot:Toggle({
    Title       = "ใส่ตัวเก่งสุดอัตโนมัติ (Auto Equip Best)",
    Desc = "สวมใส่ตัวละครที่ดีที่สุดลงแท่นตลอดเวลา",
    Value     = false,
    Callback    = function(v) State.AutoEquipBest = v end
})

Tabs.Plot:Slider({
    Title    = "ความถี่ใส่ตัว (วินาที)",
        Value = { Min = 1, Max = 30, Default = State.EquipInterval },
    Desc = "ปรับระยะเวลาตรวจสอบและสวมใส่ตัวละคร",
    Callback = function(v)
        State.EquipInterval = v
    end
})

Tabs.Plot:Button({
    Title       = "ใส่ตัวเก่งสุดทันที (Equip Best Now)",
    Callback    = function()
        equipBestUnits()
        WindUI:Notify({Title = "2K Script", Content = "สวมใส่ตัวที่ดีที่สุดเรียบร้อย", Duration = 2})
    end
})

Tabs.Plot:Section({ Title = "อัปเลเวลตัวละคร (Level Up Units)" })

Tabs.Plot:Toggle({
    Title       = "อัปเวลอัตโนมัติ (Auto Level Up)",
    Desc = "คำนวณเงินและอัปเลเวลตัวละครในแท่นเมื่อเงินพอ",
    Value     = false,
    Callback    = function(v) State.AutoLevelSlots = v end
})

local levelPresetOptions = {
    "เลเวล 20",
    "เลเวล 30",
    "เลเวล 40",
    "เลเวล 50",
    "เลเวล 60",
    "เลเวล 70",
    "เลเวล 80",
    "เลเวล 90",
    "เลเวล 100",
    "สูงสุดตามเงิน (MAX)",
}

local slideLevelRef = nil

local dropTargetLvl = Tabs.Plot:Dropdown({
    Title       = "เลเวลเป้าหมาย (Preset Level)",
    Desc = "เลือกเลเวลที่ต้องการอัปเกรดถึง",
    Values      = levelPresetOptions,
    Value     = "เลเวล 30",
    Callback    = function(val)
        if val == "สูงสุดตามเงิน (MAX)" or val == "สูงสุดตามเงิน (MAX / ไม่จำกัด)" then
            State.TargetUnitLevel = 999999
        else
            local num = tonumber(string.match(val or "", "%d+"))
            if num then
                State.TargetUnitLevel = num
                if slideLevelRef and slideLevelRef.SetValue then
                    pcall(function() slideLevelRef:SetValue(num) end)
                end
            end
        end
    end
})

slideLevelRef = Tabs.Plot:Slider({
    Title       = "เพดานเลเวล (10 - 150)",
        Value = { Min = 10, Max = 150, Default = 30 },
    Desc = "ปรับเพดานเลเวลสูงสุด",
    Callback    = function(v)
        State.TargetUnitLevel = v
    end
})

Tabs.Plot:Button({
    Title       = "อัปเวลทันที 1 รอบ (Level Up Now)",
    Desc = "อัปเลเวลตัวละครในแท่นทันที 1 รอบ",
    Callback    = function()
        levelUpAllSlots()
        WindUI:Notify({
            Title   = "2K Script",
            Content = "สั่งอัปเกรดตัวละครที่ยังไม่ถึงเลเวล " .. tostring(State.TargetUnitLevel) .. " เรียบร้อย",
            Duration = 2.5
        })
    end
})

-- ── TAB: ขายตัวละคร (AUTO SELL UNITS) ───────────────────────────────────────────
Tabs.AutoSell:Section({ Title = "ขายตามโอกาสสุ่มของเกม (1 in X)" })

Tabs.AutoSell:Paragraph({
    Title   = "ระบบขายของเกม (1 in X)",
    Desc = "ขายตัวละครที่สุ่มได้อัตโนมัติบนเซิร์ฟเวอร์ทันทีหากโอกาสสุ่มต่ำกว่า 1 ใน X\n(ตัวละครที่ขายจะไม่เข้ากระเป๋า)"
})

local inGameSellPresets = {
    "1 in 100 (100)",
    "1 in 1,000 (1k)",
    "1 in 10,000 (10k)",
    "1 in 100,000 (100k)",
    "1 in 1,000,000 (1m)",
    "1 in 10,000,000 (10m)",
    "1 in 50,000,000 (50m)",
    "1 in 100,000,000 (100m)",
    "1 in 500,000,000 (500m)",
    "1 in 1,000,000,000 (1b)",
    "1 in 10,000,000,000 (10b)",
    "1 in 100,000,000,000 (100b)",
    "ปิดการทำงาน (Disable / 0)"
}

local inputAutoSellThresholdRef = nil

Tabs.AutoSell:Dropdown({
    Title       = "เลือกโอกาสสุ่ม (Presets)",
    Desc = "เลือกอัตราโอกาสสุ่มที่ต้องการขายอัตโนมัติ",
    Values      = inGameSellPresets,
    Value     = "1 in 100,000,000 (100m)",
    Callback    = function(val)
        if val == "ปิดการทำงาน (Disable / 0)" then
            State.InGameAutoSellThreshold = 0
            State.InGameAutoSellInput = "0"
            if inputAutoSellThresholdRef and inputAutoSellThresholdRef.SetValue then
                pcall(function() inputAutoSellThresholdRef:SetValue("0") end)
            end
            if UpdateAutoSellRE then
                UpdateAutoSellRE:FireServer(0)
            end
            WindUI:Notify({Title = "2K Script", Content = "ปิดระบบขายตามโอกาสสุ่มของเกมแล้ว", Duration = 2.5})
        else
            local compactStr = string.match(val, "%(([%w]+)%)") or "100m"
            local parsedNum = NumberFormatter.ParseCompact(compactStr) or tonumber(compactStr) or 100000000
            State.InGameAutoSellThreshold = parsedNum
            State.InGameAutoSellInput = compactStr
            if inputAutoSellThresholdRef and inputAutoSellThresholdRef.SetValue then
                pcall(function() inputAutoSellThresholdRef:SetValue(compactStr) end)
            end
            if UpdateAutoSellRE then
                UpdateAutoSellRE:FireServer(parsedNum)
            end
            WindUI:Notify({
                Title   = "2K Script",
                Content = "ตั้งค่า Auto Sell 1 in " .. compactStr .. " บนเซิร์ฟเวอร์เรียบร้อย",
                Duration = 2.5
            })
        end
    end
})

inputAutoSellThresholdRef = Tabs.AutoSell:Input({
    Title       = "กำหนดโอกาสสุ่มเอง (Custom)",
    Desc = "กรอกตัวเลข เช่น 100m, 1b, 500k",
    Value     = State.InGameAutoSellInput,
    Placeholder = "เช่น 100m, 1b",
    Numeric     = false,
    Finished    = false,
    Callback    = function(val)
        State.InGameAutoSellInput = string.gsub(val or "", "%s+", "")
    end
})

Tabs.AutoSell:Button({
    Title       = "ตั้งค่าเข้าเกม (Apply to Game)",
    Desc = "ส่งค่าโอกาสสุ่มไปยังเซิร์ฟเวอร์เกมทันที",
    Callback    = function()
        local raw = string.gsub(State.InGameAutoSellInput or "", "%s+", "")
        local parsed = tonumber(raw) or NumberFormatter.ParseCompact(raw)
        if not parsed or parsed < 0 then
            WindUI:Notify({Title = "2K Script", Content = "กรุณาระบุโอกาสสุ่มที่ถูกต้อง เช่น 100m หรือ 1b", Duration = 3})
            return
        end
        State.InGameAutoSellThreshold = parsed
        if UpdateAutoSellRE then
            UpdateAutoSellRE:FireServer(parsed)
        end
        WindUI:Notify({
            Title   = "2K Script",
            Content = "ส่งค่า Auto Sell 1 in " .. NumberFormatter.FormatCompact(parsed) .. " ไปยังเซิร์ฟเวอร์สำเร็จ",
            Duration = 3
        })
    end
})

Tabs.AutoSell:Button({
    Title       = "ปิดระบบขายของเกม (Disable)",
    Desc = "รีเซ็ตค่าเป็น 0 เพื่อปิดขายอัตโนมัติ",
    Callback    = function()
        State.InGameAutoSellThreshold = 0
        State.InGameAutoSellInput = "0"
        if inputAutoSellThresholdRef and inputAutoSellThresholdRef.SetValue then
            pcall(function() inputAutoSellThresholdRef:SetValue("0") end)
        end
        if UpdateAutoSellRE then
            UpdateAutoSellRE:FireServer(0)
        end
        WindUI:Notify({Title = "2K Script", Content = "ปิดระบบ Auto Sell ของเกมเรียบร้อย (ค่าเป็น 0)", Duration = 2.5})
    end
})

Tabs.AutoSell:Toggle({
    Title       = "รวมโอกาสสุ่มในระบบขายคลัง (Check 1 in X)",
    Desc = "ขายตัวในคลังที่มีโอกาสสุ่มต่ำกว่าค่านี้ด้วย",
    Value     = false,
    Callback    = function(v) State.SellBelowChance = v end
})

Tabs.AutoSell:Section({ Title = "ขายตัวในคลัง (Inventory Sell)" })

Tabs.AutoSell:Toggle({
    Title       = "ขายตัวในคลังอัตโนมัติ (Auto Sell)",
    Desc = "สแกนและขายตัวละครตามระดับที่เลือก",
    Value     = false,
    Callback    = function(v)
        State.AutoSellUnits = v
        WindUI:Notify({
            Title   = "2K Script",
            Content = v and "เปิดระบบขายตัวละครอัตโนมัติแล้ว" or "ปิดระบบขายตัวละครแล้ว",
            Duration = 2.5
        })
    end
})

Tabs.AutoSell:Slider({
    Title       = "ความถี่สแกนขาย (วินาที)",
        Value = { Min = 1, Max = 30, Default = State.SellInterval },
    Desc = "ระยะเวลาสแกนและขายตัวละคร",
    Callback    = function(v)
        State.SellInterval = v
    end
})

local sellRarityOptions = {
    "Common (ปกติ)",
    "Uncommon (ไม่ธรรมดา)",
    "Rare (หายาก)",
    "Epic (มหากาพย์)",
    "Legendary (ตำนาน)",
    "Mythical (มายา)"
}

local defaultSellRarities = {
    "Common (ปกติ)",
    "Uncommon (ไม่ธรรมดา)",
    "Rare (หายาก)"
}

-- หมายเหตุ: เดิมเป็น Multi-select Dropdown เดียว เปลี่ยนเป็น Toggle แยกทีละระดับแทน
-- (ปลอดภัยกว่า เพราะไม่ต้องพึ่ง Multi-select API ของ WindUI ที่ยังไม่ยืนยันรูปแบบ)
for _, rarityName in ipairs(sellRarityOptions) do
    local isDefaultOn = false
    for _, defName in ipairs(defaultSellRarities) do
        if defName == rarityName then isDefaultOn = true break end
    end
    Tabs.AutoSell:Toggle({
        Title = rarityName,
        Value = isDefaultOn,
        Callback = function(state)
            State.SelectedSellRarities[rarityName] = state
        end,
    })
end

Tabs.AutoSell:Section({ Title = "ระบบป้องกันขายผิด (Safety Lock)" })

Tabs.AutoSell:Toggle({
    Title       = "ป้องกันตัวบนแท่น & หอคอย (Protect Equipped)",
    Desc = "ไม่ขายตัวละครบนแท่นและทีมหอคอย",
    Value     = true,
    Callback    = function(v) State.ProtectPlottedUnits = v end
})

Tabs.AutoSell:Toggle({
    Title       = "ป้องกันเกรด S+ ขึ้นไป (Protect Grade S+)",
    Desc = "ไม่ขายตัวละครเกรด S, S+, Z, Z+, God",
    Value     = true,
    Callback    = function(v) State.ProtectGradeSPlus = v end
})

Tabs.AutoSell:Toggle({
    Title       = "ป้องกันตัวที่ล็อคไว้ (Protect Locked)",
    Desc = "ไม่ขายตัวละครที่กดล็อคไว้ในกระเป๋า",
    Value     = true,
    Callback    = function(v) State.ProtectLockedUnits = v end
})

Tabs.AutoSell:Section({ Title = "สั่งการขาย (Manual Actions)" })

Tabs.AutoSell:Button({
    Title       = "ขายตามที่เลือกทันที (Sell Now)",
    Desc = "สแกนและขายตัวละครรอบนี้ทันที (สูงสุด 50 ตัว)",
    Callback    = function()
        local count, earned = sellSelectedUnits()
        if count > 0 then
            WindUI:Notify({
                Title   = "2K Script",
                Content = string.format("ขายตัวละครสำเร็จ %d ตัว ได้รับเงิน $%s", count, NumberFormatter.FormatCompact(earned)),
                Duration = 3.5
            })
        else
            WindUI:Notify({
                Title   = "2K Script",
                Content = "ไม่พบตัวละครที่ตรงเงื่อนไขการขาย หรือตัวละครติดระบบป้องกัน",
                Duration = 2.5
            })
        end
    end
})

-- ── TAB: ระบบเกรด (UNIT GRADE SYSTEM) ───────────────────────────────────────────
local function getInventoryUnitOptions()
    local opts = {}
    local map = {}
    pcall(function()
        local inv = DataController.Inventory and DataController.Inventory()
        if not inv then return end
        for id, item in pairs(inv) do
            if type(item) == "table" and item.name then
                local cfg = EntryRegistry.getEntryConfig(item.name)
                if cfg and cfg.kind == "Unit" then
                    local grade = (item.attributes and item.attributes.grade) or "D"
                    local lvl = (item.attributes and item.attributes.level) or 1
                    local label = string.format("%s [Lv.%s | %s] (ID: %s...)", item.name, tostring(lvl), grade, string.sub(id, 1, 8))
                    table.insert(opts, label)
                    map[label] = id
                end
            end
        end
    end)
    if #opts == 0 then
        table.insert(opts, "ไม่พบตัวละครในคลัง")
    end
    return opts, map
end

local unitLabels, unitIdMap = getInventoryUnitOptions()
if unitLabels[1] and unitIdMap[unitLabels[1]] then
    State.TargetGradeUnitKey = unitIdMap[unitLabels[1]]
end

Tabs.Grades:Section({ Title = "รีเกรดอัตโนมัติ (Auto Reroll)" })

Tabs.Grades:Paragraph({
    Title   = "คำแนะนำระบบเกรด",
    Desc = "ใช้ 1 Gem ต่อการสุ่ม 1 ครั้ง ระบบจะหยุดเมื่อได้เกรดเป้าหมายหรือ Gem หมด"
})

local dropSelectUnitRef = nil

dropSelectUnitRef = Tabs.Grades:Dropdown({
    Title       = "เลือกตัวละคร (Select Unit)",
    Desc = "เลือกตัวละครจากคลังที่ต้องการรีเกรด",
    Values      = unitLabels,
    Value     = unitLabels[1] or "",
    Callback    = function(val)
        local uId = unitIdMap[val]
        if uId then
            State.TargetGradeUnitKey = uId
        end
    end
})

Tabs.Grades:Button({
    Title       = "รีเฟรชรายชื่อตัว (Refresh Units)",
    Desc = "อัปเดตรายชื่อและเกรดล่าสุดในคลัง",
    Callback    = function()
        local newOpts, newMap = getInventoryUnitOptions()
        unitLabels = newOpts
        unitIdMap = newMap
        if dropSelectUnitRef and dropSelectUnitRef.SetValues then
            dropSelectUnitRef:SetValues(newOpts)
        end
        WindUI:Notify({Title = "2K Script", Content = "อัปเดตรายชื่อตัวละครเรียบร้อย", Duration = 2})
    end
})

local gradeTargetOptions = {
    "A",
    "A+",
    "S",
    "S+",
    "Z",
    "Z+",
    "神 (God)"
}

Tabs.Grades:Dropdown({
    Title       = "เกรดเป้าหมาย (Target Grade)",
    Desc = "สุ่มจนกระทั่งได้เกรดนี้ขึ้นไป",
    Values      = gradeTargetOptions,
    Value     = "S",
    Callback    = function(v)
        local cleanGrade = string.match(v, "^[^%s]+") or v
        State.TargetGrade = cleanGrade
    end
})

Tabs.Grades:Slider({
    Title       = "ความเร็วรีเกรด (วินาที)",
        Value = { Min = 0.15, Max = 1.0, Default = State.GradeRollDelay },
    Desc = "แนะนำ 0.25s - 0.40s ป้องกันเซิร์ฟเวอร์หน่วง",
    Callback    = function(v)
        State.GradeRollDelay = v
    end
})

Tabs.Grades:Toggle({
    Title       = "เปิดรีเกรดอัตโนมัติ (Auto Reroll)",
    Desc = "รีเกรดตัวละครต่อเนื่องจนถึงเกรดเป้าหมาย",
    Value     = false,
    Callback    = function(v)
        State.AutoRerollGrade = v
        WindUI:Notify({
            Title   = "2K Script",
            Content = v and "เริ่ม Auto Reroll Grade แล้ว" or "ปิด Auto Reroll Grade",
            Duration = 2
        })
    end
})

Tabs.Grades:Section({ Title = "สั่งการรีเกรด (Manual Reroll)" })

Tabs.Grades:Button({
    Title       = "รีเกรด 1 ครั้ง (Reroll 1x)",
    Desc = "สุ่มเกรดตัวละครที่เลือกทันที 1 ครั้ง (ใช้ 1 Gem)",
    Callback    = function()
        if not State.TargetGradeUnitKey or State.TargetGradeUnitKey == "" then
            WindUI:Notify({Title = "2K Script", Content = "กรุณาเลือกตัวละครที่ต้องการรีเกรดก่อน", Duration = 2.5})
            return
        end
        local ok = rollGradeForSelectedUnit()
        if ok then
            WindUI:Notify({Title = "2K Script", Content = "สั่งรีเกรดตัวละคร 1 ครั้งเรียบร้อย", Duration = 2})
        else
            WindUI:Notify({Title = "2K Script", Content = "ไม่สามารถรีเกรดได้ (อาจไม่มี Gem หรือตัวละครถึงเกรดแล้ว)", Duration = 2.5})
        end
    end
})

Tabs.Grades:Section({ Title = "ระบบล็อคเกรดเซิร์ฟเวอร์ (Server Lock)" })

local serverProtectList = {"S", "S+", "Z", "Z+", "神"}
for _, g in ipairs(serverProtectList) do
    Tabs.Grades:Toggle("TogServerProt_" .. g, {
        Title       = "ล็อคเกรด " .. g .. " (Lock " .. g .. ")",
        Desc = "ป้องกันเกรด " .. g .. " บนเซิร์ฟเวอร์",
        Value     = true,
        Callback    = function(val)
            pcall(function()
                if SetGradeProtectedRE then
                    SetGradeProtectedRE:FireServer(g, val)
                end
            end)
        end
    })
end

-- ── TAB 3: อัปเกรด & ลูกเต๋า (UPGRADES & DICE) ──────────────────────────────────
Tabs.Upgrades:Section({ Title = "อัปเกรดความสามารถ (Upgrades)" })

Tabs.Upgrades:Toggle({
    Title       = "ซื้ออัปเกรดอัตโนมัติ (Auto Upgrades)",
    Desc = "ซื้ออัปเกรดตามหมวดที่เลือกเมื่อเงินพอ",
    Value     = false,
    Callback    = function(v) State.AutoUpgrades = v end
})

local upgradeOptions = {
    "Luck & Fortune (โชคและดวง)",
    "Roll Speed (ความเร็วหมุน)",
    "Money (เงินและเหรียญ)",
    "Unit Storage (ช่องเก็บตัวละคร)",
    "Damage (พลังโจมตี)",
    "Health (พลังชีวิต)",
    "Walkspeed (ความเร็วเดิน)",
    "Sell (ราคาขาย)"
}

local defaultSelections = {
    "Luck & Fortune (โชคและดวง)",
    "Roll Speed (ความเร็วหมุน)",
    "Money (เงินและเหรียญ)"
}

-- หมายเหตุ: เดิมเป็น Multi-select Dropdown เดียว เปลี่ยนเป็น Toggle แยกทีละหมวดแทน
-- (ปลอดภัยกว่า เพราะไม่ต้องพึ่ง Multi-select API ของ WindUI ที่ยังไม่ยืนยันรูปแบบ)
for _, categoryName in ipairs(upgradeOptions) do
    local isDefaultOn = false
    for _, defName in ipairs(defaultSelections) do
        if defName == categoryName then isDefaultOn = true break end
    end
    Tabs.Upgrades:Toggle({
        Title = categoryName,
        Value = isDefaultOn,
        Callback = function(state)
            State.SelectedUpgradeCategories[categoryName] = state
        end,
    })
end

Tabs.Upgrades:Toggle({
    Title       = "ซื้อเฉพาะหมวดที่เลือก (Only Selected)",
    Desc = "ไม่ซื้อหมวดอื่นแม้เงินจะเหลือ",
    Value     = false,
    Callback    = function(v) State.OnlySelectedUpgrades = v end
})

Tabs.Upgrades:Button({
    Title       = "ซื้ออัปเกรดทันที (Buy Upgrades Now)",
    Callback    = function()
        buyPrioritizedUpgrades()
        WindUI:Notify({Title = "2K Script", Content = "ซื้ออัปเกรดตามหมวดที่เลือกเรียบร้อย", Duration = 2})
    end
})

Tabs.Upgrades:Section({ Title = "ร้านค้าลูกเต๋า (Dice Shop)" })

Tabs.Upgrades:Toggle({
    Title       = "ซื้อเต๋าใหม่เมื่อเงินพอ (Auto Buy Dice)",
    Desc = "ซื้อลูกเต๋าที่ยังไม่มีเมื่อเงินพอ",
    Value     = false,
    Callback    = function(v) State.AutoBuyDice = v end
})

Tabs.Upgrades:Button({
    Title       = "ซื้อเต๋าทันที (Buy Available Dice)",
    Callback    = function()
        buyAffordableDice()
        WindUI:Notify({Title = "2K Script", Content = "ซื้อลูกเต๋าที่เงินพอเรียบร้อย", Duration = 2})
    end
})

-- ── TAB: เว็บฮุก (DISCORD WEBHOOK INTEGRATION) ──────────────────────────────────
Tabs.Webhook:Section({ Title = "ตั้งค่า Discord Webhook" })

Tabs.Webhook:Paragraph({
    Title   = "ระบบแจ้งเตือน Discord",
    Desc = "ใส่ Webhook URL จาก Discord เพื่อรับการแจ้งเตือนแบบเรียลไทม์ เช่น สุ่มได้ตัวเทพ หรือสรุปสถิติ"
})

local inputWebhookRef = nil

inputWebhookRef = Tabs.Webhook:Input({
    Title       = "Discord Webhook URL",
    Desc = "วางลิงก์ Webhook จาก Discord ที่นี่",
    Value     = State.WebhookURL,
    Placeholder = "https://discord.com/api/webhooks/...",
    Numeric     = false,
    Finished    = false,
    Callback    = function(val)
        State.WebhookURL = string.gsub(val or "", "%s+", "")
    end
})

Tabs.Webhook:Button({
    Title       = "บันทึก Webhook (Confirm URL)",
    Desc = "บันทึกและตรวจเช็ค URL ทันที (เหมาะสำหรับมือถือ)",
    Callback    = function()
        local currentVal = (inputWebhookRef and inputWebhookRef.Value) or State.WebhookURL
        local clean = string.gsub(currentVal or "", "%s+", "")
        if clean == "" then
            WindUI:Notify({Title = "2K Script", Content = "กรุณากรอกหรือวาง Webhook URL ก่อนกดยืนยัน", Duration = 3})
            return
        end
        State.WebhookURL = clean
        if clean:find("discord.com/api/webhooks") or clean:find("discordapp.com/api/webhooks") then
            WindUI:Notify({
                Title   = "2K Script",
                Content = "บันทึกและยืนยัน Webhook URL สำเร็จ พร้อมใช้งานแล้ว",
                Duration = 3.5
            })
        else
            WindUI:Notify({
                Title   = "2K Script",
                Content = "บันทึกแล้ว (คำเตือน: รูปแบบ URL ไม่ตรงกับมาตรฐาน Discord)",
                Duration = 4
            })
        end
    end
})

Tabs.Webhook:Button({
    Title       = "วางจากคลิปบอร์ด (Paste Clipboard)",
    Desc = "ดึง URL จากคลิปบอร์ดมาใส่ทันที",
    Callback    = function()
        local pasteFn = getclipboard or (Clipboard and Clipboard.get)
        if pasteFn then
            local ok, clip = pcall(pasteFn)
            if ok and clip and type(clip) == "string" and #clip > 0 then
                local clean = string.gsub(clip, "%s+", "")
                State.WebhookURL = clean
                if inputWebhookRef and inputWebhookRef.SetValue then
                    pcall(function() inputWebhookRef:SetValue(clean) end)
                end
                WindUI:Notify({
                    Title   = "2K Script",
                    Content = "วาง Webhook URL จากคลิปบอร์ดเรียบร้อยแล้ว!",
                    Duration = 3
                })
                return
            end
        end
        WindUI:Notify({
            Title   = "2K Script",
            Content = "ไม่สามารถดึงข้อมูลจากคลิปบอร์ดได้ กรุณากดวางลงในช่องโดยตรง",
            Duration = 3
        })
    end
})

Tabs.Webhook:Toggle({
    Title       = "เปิดใช้งาน Webhook (Enable)",
    Desc = "ส่งการแจ้งเตือนไปยัง Discord",
    Value     = false,
    Callback    = function(v)
        State.WebhookEnabled = v
        WindUI:Notify({
            Title   = "2K Script",
            Content = v and "เปิดใช้งาน Discord Webhook แล้ว" or "ปิดการแจ้งเตือน Webhook แล้ว",
            Duration = 2.5
        })
    end
})

Tabs.Webhook:Button({
    Title       = "ทดสอบส่งข้อความ (Test Webhook)",
    Desc = "ส่งข้อความทดสอบไปยัง Discord",
    Callback    = function()
        if not State.WebhookURL or State.WebhookURL == "" then
            WindUI:Notify({Title = "2K Script", Content = "กรุณากรอก Webhook URL ก่อนกดทดสอบ", Duration = 2.5})
            return
        end
        local ok = sendDiscordWebhook(
            "ทดสอบการเชื่อมต่อ Webhook สำเร็จ!",
            "ระบบแจ้งเตือนของ **2K Script - Anime Dice** เชื่อมต่อกับ Discord ของคุณเรียบร้อยแล้ว",
            0x00FF88,
            {
                {name = "ผู้เล่น", value = LP.DisplayName .. " (@" .. LP.Name .. ")", inline = true},
                {name = "สถานะ", value = "พร้อมใช้งาน 100%", inline = true},
                {name = "เวลา", value = os.date("%H:%M:%S - %d/%m/%Y"), inline = true}
            }
        )
        WindUI:Notify({
            Title   = "2K Script",
            Content = ok and "ส่งข้อความทดสอบไปยัง Discord เรียบร้อยแล้ว!" or "ไม่สามารถส่ง Webhook ได้ (ตรวจสอบ URL หรือระบบเครือข่าย)",
            Duration = 3.5
        })
    end
})

Tabs.Webhook:Section({ Title = "เลือกการแจ้งเตือน (Event Alerts)" })

Tabs.Webhook:Toggle({
    Title       = "เตือนเมื่อสุ่มได้ตัวระดับสูง (High Rolls)",
    Desc = "ส่งข้อมูลตัวละคร เกรด Trait เข้า Discord",
    Value     = true,
    Callback    = function(v) State.WebhookNotifyRolls = v end
})

local webhookRarityOptions = {
    "Epic",
    "Legendary",
    "Mythical",
    "Secret",
    "Exotic",
    "Celestial",
    "Divine"
}

Tabs.Webhook:Dropdown({
    Title       = "ระดับขั้นต่ำที่แจ้งเตือน (Min Rarity)",
    Desc = "เพดานระดับความหายากขั้นต่ำ",
    Values      = webhookRarityOptions,
    Value     = "Mythical",
    Callback    = function(v) State.WebhookMinRarity = v end
})

Tabs.Webhook:Toggle({
    Title       = "เตือนเมื่อจุติสำเร็จ (Rebirth Alert)",
    Desc = "ส่งรายงานระดับจุติใหม่และโบนัสที่ได้",
    Value     = true,
    Callback    = function(v) State.WebhookNotifyRebirth = v end
})

Tabs.Webhook:Toggle({
    Title       = "เตือนเมื่อได้เกรดระดับสูง (High Grade)",
    Desc = "ส่งรายงานเมื่อได้เกรด S, S+, Z, Z+, God",
    Value     = true,
    Callback    = function(v) State.WebhookNotifyGrade = v end
})

Tabs.Webhook:Section({ Title = "สรุปสถิติตามเวลา (Periodic Summary)" })

Tabs.Webhook:Toggle({
    Title       = "ส่งสรุปสถิติอัตโนมัติ (Auto Summary)",
    Desc = "ส่งสรุปยอดเงิน จุติ และตัวละครตามเวลา",
    Value     = false,
    Callback    = function(v) State.WebhookPeriodicSummary = v end
})

Tabs.Webhook:Slider({
    Title       = "ความถี่ส่งรายงาน (นาที)",
        Value = { Min = 5, Max = 60, Default = State.WebhookSummaryInterval },
    Desc = "ระยะเวลาส่งสรุปสถิติ (5 - 60 นาที)",
    Callback    = function(v) State.WebhookSummaryInterval = v end
})

Tabs.Webhook:Button({
    Title       = "ส่งสรุปสถิติตอนนี้ (Send Summary Now)",
    Desc = "ส่งรายงานสถิติปัจจุบันเข้า Discord ทันที",
    Callback    = function()
        if not State.WebhookURL or State.WebhookURL == "" then
            WindUI:Notify({Title = "2K Script", Content = "กรุณากรอก Webhook URL ก่อนสั่งส่งรายงาน", Duration = 2.5})
            return
        end
        pcall(function()
            local moneyStr = NumberFormatter.FormatCompact(DataController.Money() or 0)
            local rebirthLvl = tostring(DataController.Rebirth() or 0)
            local diceName = tostring(DataController.Dice() or "Value")
            local invCount = 0
            local inv = DataController.Inventory and DataController.Inventory()
            if inv then
                for _, u in pairs(inv) do
                    if type(u) == "table" and u.name then invCount = invCount + 1 end
                end
            end

            local ok = sendDiscordWebhook(
                "รายงานสถานะผู้เล่นประจำรอบ (Status Summary)",
                "สรุปสถิติความก้าวหน้าของ **" .. LP.DisplayName .. "** (@" .. LP.Name .. ")",
                0x4287F5,
                {
                    {name = "ยอดเงินคงเหลือ", value = "$" .. moneyStr, inline = true},
                    {name = "ระดับการจุติ", value = "Rebirth " .. rebirthLvl, inline = true},
                    {name = "ลูกเต๋าที่ใช้งาน", value = diceName, inline = true},
                    {name = "จำนวนตัวละครในคลัง", value = tostring(invCount) .. " ตัว", inline = true},
                    {name = "หอคอยที่ฟาร์ม", value = State.SelectedTower or "None", inline = true},
                    {name = "ระยะเวลาฟาร์มรอบนี้", value = string.format("%.1f นาที", (os.clock()) / 60), inline = true}
                }
            )
            WindUI:Notify({
                Title   = "2K Script",
                Content = ok and "ส่งรายงานสรุปสถิติเข้า Discord เรียบร้อยแล้ว" or "ไม่สามารถส่งได้ (ตรวจสอบ Webhook URL)",
                Duration = 3
            })
        end)
    end
})

-- ── TAB 4: การเคลื่อนที่ (MOVEMENT HACKS) ─────────────────────────────────────────
Tabs.Move:Section({ Title = "ปรับแต่งการเคลื่อนที่ (Movement)" })

Tabs.Move:Slider({
    Title    = "ความเร็วเดิน (WalkSpeed)",
        Value = { Min = 16, Max = 200, Default = 16 },
    Callback = function(v)
        State.WalkSpeed = v
        if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
            LP.Character.Humanoid.WalkSpeed = v
        end
    end
})

Tabs.Move:Slider({
    Title    = "แรงกระโดด (JumpPower)",
        Value = { Min = 50, Max = 250, Default = 50 },
    Callback = function(v)
        State.JumpPower = v
        if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
            LP.Character.Humanoid.JumpPower = v
        end
    end
})

Tabs.Move:Toggle({
    Title       = "กระโดดไม่จำกัด (Infinite Jump)",
    Desc = "กระโดดซ้ำกลางอากาศได้ตลอดเวลา",
    Value     = false,
    Callback    = function(v) State.InfJump = v end
})

Tabs.Move:Toggle({
    Title       = "เดินทะลุกำแพง (Noclip)",
    Desc = "เดินทะลุกำแพงและสิ่งกีดขวาง",
    Value     = false,
    Callback    = function(v) State.Noclip = v end
})

-- ── TAB 5: ตั้งค่า & คอมมูนิตี้ (SETTINGS & COMMUNITY) ───────────────────────────
Tabs.Settings:Section({ Title = "คอมมูนิตี้ (Community & Support)" })

Tabs.Settings:Paragraph({
    Title = "2K Script Official Discord",
    Desc = "เข้าร่วมดิสคอร์ดเพื่อรับอัปเดตสคริปต์ แจ้งปัญหา และพูดคุยกับสมาชิก\nDiscord: https://discord.gg/4Yg72kYT6s"
})

Tabs.Settings:Button({
    Title       = "คัดลอกลิงก์ Discord (Copy Discord Invite)",
    Desc = "กดเพื่อคัดลอกลิงก์ดิสคอร์ดลง Clipboard ทันที",
    Callback    = function()
        local copyFn = setclipboard or toclipboard or (Clipboard and Clipboard.set)
        if copyFn then
            pcall(copyFn, "https://discord.gg/4Yg72kYT6s")
            WindUI:Notify({
                Title = "2K Script",
                Content = "คัดลอกลิงก์ Discord ลง Clipboard เรียบร้อยแล้ว!",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "2K Script",
                Content = "discord.gg/4Yg72kYT6s",
                Duration = 4
            })
        end
    end
})

-- ── CONFIG MANAGEMENT ENGINE ──────────────────────────────────────────────────
local ConfigFolder = "2K_Scripts/AnimeDice"
local AutoloadFile = ConfigFolder .. "/autoload.txt"

local function ensureConfigFolder()
    pcall(function()
        if makefolder and isfolder then
            if not isfolder("2K_Scripts") then
                makefolder("2K_Scripts")
            end
            if not isfolder(ConfigFolder) then
                makefolder(ConfigFolder)
            end
        end
    end)
end

local function listConfigs()
    ensureConfigFolder()
    local list = {}
    pcall(function()
        if listfiles then
            local files = listfiles(ConfigFolder)
            for _, path in ipairs(files) do
                local filename = string.match(path, "([^/\\]+)%.json$")
                if filename and filename ~= "" then
                    table.insert(list, filename)
                end
            end
        end
    end)
    table.sort(list)
    if #list == 0 then
        table.insert(list, "ไม่มีคอนฟิก (ว่าง)")
    end
    return list
end

local function getAutoloadConfigName()
    ensureConfigFolder()
    local autoName = nil
    pcall(function()
        if isfile and isfile(AutoloadFile) and readfile then
            local content = readfile(AutoloadFile)
            if content and #content > 0 then
                autoName = string.gsub(content, "%s+", "")
            end
        end
    end)
    return autoName
end

local function saveConfigFile(configName)
    ensureConfigFolder()
    if not configName or configName == "" or configName == "ไม่มีคอนฟิก (ว่าง)" then
        return false, "ชื่อคอนฟิกไม่ถูกต้อง"
    end
    local safeName = string.gsub(configName, "[^%w_%-]", "")
    if #safeName == 0 then
        return false, "ชื่อคอนฟิกต้องมีตัวอักษรหรือตัวเลข"
    end

    local dataToSave = {
        Version = "1.0",
        Timestamp = os.time(),
        State = State
    }

    local success, encoded = pcall(function()
        return HttpService:JSONEncode(dataToSave)
    end)
    if not success or not encoded then
        return false, "แปลงข้อมูล JSON ไม่สำเร็จ"
    end

    local filePath = ConfigFolder .. "/" .. safeName .. ".json"
    local writeOk = pcall(function()
        writefile(filePath, encoded)
    end)
    if not writeOk then
        return false, "เขียนไฟล์คอนฟิกลงเครื่องไม่สำเร็จ"
    end
    return true, safeName
end

local function loadConfigFile(configName)
    ensureConfigFolder()
    if not configName or configName == "" or configName == "ไม่มีคอนฟิก (ว่าง)" then
        return false, "กรุณาเลือกคอนฟิกที่ต้องการโหลด"
    end
    local safeName = string.gsub(configName, "[^%w_%-]", "")
    local filePath = ConfigFolder .. "/" .. safeName .. ".json"
    if not isfile(filePath) then
        return false, "ไม่พบไฟล์คอนฟิก: " .. safeName
    end

    local content
    local readOk = pcall(function()
        content = readfile(filePath)
    end)
    if not readOk or not content or #content == 0 then
        return false, "อ่านไฟล์คอนฟิกไม่สำเร็จ"
    end

    local decodeOk, decoded = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not decodeOk or type(decoded) ~= "table" then
        return false, "โครงสร้างไฟล์คอนฟิกเสียหาย"
    end

    local loadedState = decoded.State or decoded
    if type(loadedState) ~= "table" then
        return false, "ไม่พบข้อมูล State ในคอนฟิก"
    end

    -- อัปเดต State ปัจจุบัน
    for k, v in pairs(loadedState) do
        if State[k] ~= nil then
            State[k] = v
        end
    end

    -- หมายเหตุ: เวอร์ชัน WindUI นี้ไม่มี registry แบบ Fluent.Options ให้ sync widget
    -- อัตโนมัติแบบเดิม ค่า State ด้านบนถูกอัปเดตถูกต้องแล้ว (ระบบทำงานตามค่าที่โหลดจริง)
    -- แต่ปุ่ม/สไลเดอร์บนหน้าจอจะยังโชว์ค่าเดิมจนกว่าจะปิดเปิดแท็บใหม่ หรือรีรัน hub

    return true, safeName
end

local function deleteConfigFile(configName)
    ensureConfigFolder()
    if not configName or configName == "" or configName == "ไม่มีคอนฟิก (ว่าง)" then
        return false, "กรุณาเลือกคอนฟิกที่ต้องการลบ"
    end
    local safeName = string.gsub(configName, "[^%w_%-]", "")
    local filePath = ConfigFolder .. "/" .. safeName .. ".json"
    if not isfile(filePath) then
        return false, "ไม่พบไฟล์คอนฟิกที่จะลบ"
    end
    local ok = pcall(function()
        delfile(filePath)
    end)
    if not ok then
        return false, "ลบไฟล์คอนฟิกไม่สำเร็จ"
    end
    if getAutoloadConfigName() == safeName then
        pcall(function() delfile(AutoloadFile) end)
    end
    return true, safeName
end

local function setAutoloadConfig(configName)
    ensureConfigFolder()
    if not configName or configName == "" or configName == "ไม่มีคอนฟิก (ว่าง)" then
        pcall(function() if isfile(AutoloadFile) then delfile(AutoloadFile) end end)
        return false, "ล้างค่า AutoLoad เรียบร้อย"
    end
    local safeName = string.gsub(configName, "[^%w_%-]", "")
    local filePath = ConfigFolder .. "/" .. safeName .. ".json"
    if not isfile(filePath) then
        return false, "ไม่พบไฟล์คอนฟิก " .. safeName
    end
    local ok = pcall(function()
        writefile(AutoloadFile, safeName)
    end)
    if not ok then
        return false, "บันทึก AutoLoad ไม่สำเร็จ"
    end
    return true, safeName
end

Tabs.Settings:Section({ Title = "โปรไฟล์ & คอนฟิก (Config)" })

Tabs.Settings:Paragraph({
    Title   = "ระบบจัดการคอนฟิก",
    Desc = "บันทึกการตั้งค่าลงเครื่อง (โฟลเดอร์ 2K_Scripts/AnimeDice) และตั้งโหลดอัตโนมัติได้"
})

local selectedConfigName = ""
local newConfigInputName = "Default"
local configListValues = listConfigs()
local dropConfigListRef = nil
local paraAutoloadRef = nil

local function updateAutoloadStatusText()
    local autoName = getAutoloadConfigName()
    if autoName and autoName ~= "" then
        return "คอนฟิกที่โหลดอัตโนมัติปัจจุบัน: " .. autoName
    else
        return "คอนฟิกที่โหลดอัตโนมัติปัจจุบัน: ไม่ได้ตั้งค่า (ปิด)"
    end
end

paraAutoloadRef = Tabs.Settings:Paragraph({
    Title   = "สถานะ Auto-Load ปัจจุบัน",
    Desc = updateAutoloadStatusText()
})

local inputConfigNameRef = Tabs.Settings:Input({
    Title       = "ชื่อคอนฟิกใหม่ (Config Name)",
    Desc = "ตั้งชื่อคอนฟิก เช่น Farm_Main, Tower_Push",
    Value     = "Value",
    Placeholder = "เช่น Value, Farm_Plot, Night_AFK",
    Numeric     = false,
    Finished    = false,
    Callback    = function(val)
        newConfigInputName = string.gsub(val or "", "%s+", "")
    end
})

Tabs.Settings:Button({
    Title       = "สร้างคอนฟิกใหม่ (Create Config)",
    Desc = "สร้างและบันทึกการตั้งค่าปัจจุบันลงไฟล์",
    Callback    = function()
        local nameToSave = newConfigInputName
        if not nameToSave or nameToSave == "" then
            nameToSave = (inputConfigNameRef and inputConfigNameRef.Value) or "Value"
        end
        local ok, msg = saveConfigFile(nameToSave)
        if ok then
            configListValues = listConfigs()
            selectedConfigName = msg
            if dropConfigListRef and dropConfigListRef.SetValues then
                dropConfigListRef:SetValues(configListValues)
                dropConfigListRef:SetValue(msg)
            end
            WindUI:Notify({
                Title   = "2K Script",
                Content = "สร้างและบันทึกคอนฟิก [" .. msg .. "] สำเร็จแล้ว!",
                Duration = 3.5
            })
        else
            WindUI:Notify({
                Title   = "2K Script",
                Content = "เกิดข้อผิดพลาด: " .. tostring(msg),
                Duration = 3.5
            })
        end
    end
})

dropConfigListRef = Tabs.Settings:Dropdown({
    Title       = "เลือกคอนฟิก (Select Config)",
    Desc = "เลือกคอนฟิกที่มีอยู่ในเครื่องเพื่อโหลดหรือลบ",
    Values      = configListValues,
    Value     = configListValues[1] or "ไม่มีคอนฟิก (ว่าง)",
    Callback    = function(val)
        selectedConfigName = val
    end
})

if configListValues[1] and configListValues[1] ~= "ไม่มีคอนฟิก (ว่าง)" then
    selectedConfigName = configListValues[1]
end

Tabs.Settings:Button({
    Title       = "โหลดคอนฟิก (Load Config)",
    Desc = "โหลดการตั้งค่าจากคอนฟิกมาใช้งานทันที",
    Callback    = function()
        if not selectedConfigName or selectedConfigName == "" or selectedConfigName == "ไม่มีคอนฟิก (ว่าง)" then
            WindUI:Notify({Title = "2K Script", Content = "กรุณาเลือกคอนฟิกจากรายการก่อนกดโหลด", Duration = 3})
            return
        end
        local ok, msg = loadConfigFile(selectedConfigName)
        if ok then
            WindUI:Notify({
                Title   = "2K Script",
                Content = "โหลดคอนฟิก [" .. msg .. "] สำเร็จแล้ว การตั้งค่ามีผลทันที!",
                Duration = 3.5
            })
        else
            WindUI:Notify({
                Title   = "2K Script",
                Content = "โหลดคอนฟิกล้มเหลว: " .. tostring(msg),
                Duration = 3.5
            })
        end
    end
})

Tabs.Settings:Button({
    Title       = "บันทึกทับคอนฟิก (Save Config)",
    Desc = "บันทึกค่าปัจจุบันทับคอนฟิกที่เลือก",
    Callback    = function()
        if not selectedConfigName or selectedConfigName == "" or selectedConfigName == "ไม่มีคอนฟิก (ว่าง)" then
            WindUI:Notify({Title = "2K Script", Content = "กรุณาเลือกคอนฟิกที่ต้องการบันทึกทับ", Duration = 3})
            return
        end
        local ok, msg = saveConfigFile(selectedConfigName)
        if ok then
            WindUI:Notify({
                Title   = "2K Script",
                Content = "บันทึกทับคอนฟิก [" .. msg .. "] เรียบร้อยแล้ว!",
                Duration = 3.5
            })
        else
            WindUI:Notify({
                Title   = "2K Script",
                Content = "บันทึกคอนฟิกล้มเหลว: " .. tostring(msg),
                Duration = 3.5
            })
        end
    end
})

Tabs.Settings:Button({
    Title       = "รีเฟรชรายชื่อ (Refresh List)",
    Desc = "อัปเดตรายชื่อคอนฟิกในดรอปดาวน์",
    Callback    = function()
        configListValues = listConfigs()
        if dropConfigListRef and dropConfigListRef.SetValues then
            dropConfigListRef:SetValues(configListValues)
            if configListValues[1] then
                dropConfigListRef:SetValue(configListValues[1])
                selectedConfigName = configListValues[1]
            end
        end
        if paraAutoloadRef and paraAutoloadRef.SetDesc then
            pcall(function() paraAutoloadRef:SetDesc(updateAutoloadStatusText()) end)
        end
        WindUI:Notify({Title = "2K Script", Content = "รีเฟรชรายชื่อคอนฟิกเรียบร้อย", Duration = 2})
    end
})

Tabs.Settings:Button({
    Title       = "ตั้งเป็นโหลดอัตโนมัติ (Set Auto-Load)",
    Desc = "โหลดคอนฟิกนี้ทันทีทุกครั้งที่เปิดสคริปต์",
    Callback    = function()
        if not selectedConfigName or selectedConfigName == "" or selectedConfigName == "ไม่มีคอนฟิก (ว่าง)" then
            WindUI:Notify({Title = "2K Script", Content = "กรุณาเลือกคอนฟิกที่ต้องการตั้งเป็น Auto-Load ก่อน", Duration = 3})
            return
        end
        local ok, msg = setAutoloadConfig(selectedConfigName)
        if ok then
            if paraAutoloadRef and paraAutoloadRef.SetDesc then
                pcall(function() paraAutoloadRef:SetDesc(updateAutoloadStatusText()) end)
            end
            WindUI:Notify({
                Title   = "2K Script",
                Content = "ตั้งค่า [" .. msg .. "] เป็น Auto-Load เรียบร้อยแล้ว!",
                Duration = 3.5
            })
        else
            WindUI:Notify({
                Title   = "2K Script",
                Content = "เกิดข้อผิดพลาด: " .. tostring(msg),
                Duration = 3
            })
        end
    end
})

Tabs.Settings:Button({
    Title       = "ยกเลิกโหลดอัตโนมัติ (Clear Auto-Load)",
    Desc = "ยกเลิกการโหลดคอนฟิกอัตโนมัติ",
    Callback    = function()
        setAutoloadConfig(nil)
        if paraAutoloadRef and paraAutoloadRef.SetDesc then
            pcall(function() paraAutoloadRef:SetDesc(updateAutoloadStatusText()) end)
        end
        WindUI:Notify({Title = "2K Script", Content = "ยกเลิก Auto-Load เรียบร้อยแล้ว", Duration = 2.5})
    end
})

Tabs.Settings:Button({
    Title       = "ลบคอนฟิก (Delete Config)",
    Desc = "ลบไฟล์คอนฟิกออกจากเครื่องถาวร",
    Callback    = function()
        if not selectedConfigName or selectedConfigName == "" or selectedConfigName == "ไม่มีคอนฟิก (ว่าง)" then
            WindUI:Notify({Title = "2K Script", Content = "กรุณาเลือกคอนฟิกที่ต้องการลบก่อน", Duration = 3})
            return
        end
        local targetToDelete = selectedConfigName
        local ok, msg = deleteConfigFile(targetToDelete)
        if ok then
            configListValues = listConfigs()
            selectedConfigName = configListValues[1] or ""
            if dropConfigListRef and dropConfigListRef.SetValues then
                dropConfigListRef:SetValues(configListValues)
                dropConfigListRef:SetValue(configListValues[1] or "")
            end
            if paraAutoloadRef and paraAutoloadRef.SetDesc then
                pcall(function() paraAutoloadRef:SetDesc(updateAutoloadStatusText()) end)
            end
            WindUI:Notify({
                Title   = "2K Script",
                Content = "ลบคอนฟิก [" .. msg .. "] เรียบร้อยแล้ว",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title   = "2K Script",
                Content = "ลบคอนฟิกล้มเหลว: " .. tostring(msg),
                Duration = 3
            })
        end
    end
})

Tabs.Settings:Section({ Title = "ปรับแต่งธีม (Theme Settings)" })

Tabs.Settings:Dropdown({
    Title       = "เปลี่ยนสีธีมหน้าต่าง",
    Values      = {"2K_Frost", "Aqua", "Light", "Dark"},
    Value     = "2K_Frost",
    Callback    = function(themeName)
        pcall(function()
            WindUI:SetTheme(themeName)
        end)
    end
})

Tabs.Settings:Button({
    Title       = "ปิดสคริปต์ (Unload Script)",
    Desc = "หยุดระบบทั้งหมดและปิด UI ทันที",
    Callback    = function()
        if _G.AnimeDiceCleanup then
            _G.AnimeDiceCleanup()
        end
    end
})

pcall(function()
    if Window.SelectTab then
        Window:SelectTab(1)
    end
end)

-- หมายเหตุ: ตัดส่วน "บังคับ Font ตัวหนาทับทุก TextLabel" ออก เพราะเป็นการ hack
-- โครงสร้างภายในของ Fluent (Window.Root) โดยเฉพาะ ซึ่งไม่มีใน WindUI — WindUI
-- มีธีม/ฟอนต์ของตัวเองอยู่แล้วจากหน้าต่าง Hub หลัก ไม่จำเป็นต้องบังคับทับซ้ำ

WindUI:Notify({
    Title   = "2K Script",
    Content = "Anime Dice | discord.gg/4Yg72kYT6s",
    Duration = 5
})

-- Auto-Load Config at Boot
task.spawn(function()
    task.wait(1.5)
    pcall(function()
        local autoConfig = getAutoloadConfigName()
        if autoConfig and autoConfig ~= "" and autoConfig ~= "ไม่มีคอนฟิก (ว่าง)" then
            local ok, name = loadConfigFile(autoConfig)
            if ok then
                WindUI:Notify({
                    Title   = "2K Script",
                    Content = "โหลดคอนฟิกอัตโนมัติสำเร็จ: " .. tostring(name),
                    Duration = 4
                })
            end
        end
    end)
end)


end

return AnimeDice
