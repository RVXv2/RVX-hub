--[[
    RVX-hub: Greedy Growers Module (ฉบับแก้ไข: สแกนเฉพาะผลไม้บนต้น + วาปลอยกลางอากาศเก็บทีละลูก)
--]]

local GreedyGrowers = {}

function GreedyGrowers.Init(Window, WindUI)
    local fireProximityPrompt = fireproximityprompt or (getgenv and getgenv().fireproximityprompt)
    if not fireProximityPrompt then
        warn("[Greedy Growers] executor นี้ไม่มีฟังก์ชัน fireproximityprompt — ปิดฟีเจอร์ auto buy/sell ของแมพนี้")
        return
    end

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer

    -- ===== ค้นหา Remote สำหรับขายของ =====
    local sellAllRemote = nil
    pcall(function()
        sellAllRemote = ReplicatedStorage.Packages._Index["sleitnick_knit@1.6.0"].knit.Services.SellStandService.RF.SellAll
    end)

    if not sellAllRemote then
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc:IsA("RemoteFunction") and desc.Name == "SellAll" then
                sellAllRemote = desc
                break
            end
        end
    end

    -- ===== ตั้งค่าความเสถียร =====
    local LOOP_INTERVAL = 0.15
    local VERIFY_WAIT = 0.3
    local MIN_SELL_DELAY = 0.5
    local MAX_SELL_DELAY = 30.0

    _G.AutoTeleportBuy = (_G.AutoTeleportBuy == nil) and true or _G.AutoTeleportBuy
    _G.AutoBuySeed = false
    _G.AutoSellAll = false
    _G.AutoSellInterval = 2.0
    _G.AutoCollectFruit = false
    _G.AutoTeleportCollect = (_G.AutoTeleportCollect == nil) and true or _G.AutoTeleportCollect

    -- ===== ตารางราคาเมล็ด =====
    local SEED_PRICES = {
        Oak         = 0,
        Pine        = 25,
        Apple       = 200,
        Peach       = 350,
        Fig         = 500,
        Orange      = 10000,
        Lemon       = 15000,
        Avocado     = 20000,
        Cherry      = 2500000,
        Mango       = 5000000,
        Coconut     = 10000000,
        Banana      = 3000000000,
        Starfruit   = 4500000000,
        DragonFruit = 7000000000,
        Glowing     = 500000000000,
        Blooming    = 750000000000,
        Magic       = 500000000000000,
        Pizza       = 850000000000000,
        Diamond     = 1000000000000000000,
        Void        = 1750000000000000000,
    }

    -- ===== รายชื่อ Rarity =====
    local RARITY_LIST = {"COMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC", "CELESTIAL", "SECRET", "DIVINE"}
    local RARITY_THAI = {
        COMMON    = "ธรรมดา",
        RARE      = "หายาก",
        EPIC      = "เอพิค",
        LEGENDARY = "ตำนาน",
        MYTHIC    = "มายา / มิติก",
        CELESTIAL = "สวรรค์",
        SECRET    = "ลับ",
        DIVINE    = "เทพ",
    }

    _G.AllowedRarities = _G.AllowedRarities or {}
    for _, r in ipairs(RARITY_LIST) do
        if _G.AllowedRarities[r] == nil then
            _G.AllowedRarities[r] = true
        end
    end

    -- ===== แปลงค่าเงิน =====
    local SUFFIX_MAP = {
        K = 1e3, M = 1e6, B = 1e9, T = 1e12,
        Qa = 1e15, Qi = 1e18, Sx = 1e21, Sp = 1e24,
        Oc = 1e27, No = 1e30, De = 1e33,
    }

    local function parseMoney(text)
        if type(text) ~= "string" then return 0 end
        local cleaned = text:gsub("%$", ""):gsub(",", ""):gsub("%s", "")
        local numPart, suffix = cleaned:match("^([%d%.]+)(%a*)$")
        if not numPart then return 0 end
        local num = tonumber(numPart) or 0
        if suffix == "" then return num end
        local mult = SUFFIX_MAP[suffix]
        return mult and (num * mult) or num
    end

    local function getCurrentCash()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        local cashStat = leaderstats and leaderstats:FindFirstChild("Cash")
        return cashStat and parseMoney(tostring(cashStat.Value)) or 0
    end

    local function triggerSellAll()
        if sellAllRemote then
            pcall(function()
                sellAllRemote:InvokeServer()
            end)
        end
    end

    -- ===== สแกนสายพานซื้อเมล็ด =====
    local function getConveyorFolder()
        local bigField = workspace:FindFirstChild("BigField")
        return bigField and bigField:FindFirstChild("ConveyorSeeds")
    end

    local function scanAllAvailableSeeds()
        local conveyor = getConveyorFolder()
        if not conveyor then return {} end

        local candidates = {}
        for _, child in ipairs(conveyor:GetChildren()) do
            local seedType = child:GetAttribute("SeedType")
            local rarity = child:GetAttribute("Rarity")
            local prompt = child:FindFirstChildWhichIsA("ProximityPrompt", true)

            if seedType and rarity and prompt then
                local uRarity = tostring(rarity):upper()
                table.insert(candidates, {
                    object = child,
                    seedType = tostring(seedType),
                    rarity = uRarity,
                    prompt = prompt,
                    price = SEED_PRICES[seedType] or 0
                })
            end
        end
        return candidates
    end

    -- ===== สแกนพล็อตของเรา =====
    local function getPlayerPlotsFolder()
        local bigField = workspace:FindFirstChild("BigField")
        return bigField and bigField:FindFirstChild("PlayerPlots")
    end

    local function isOwnedByLocalPlayer(plotFolder)
        local ownerId = plotFolder:GetAttribute("OwnerUserId")
            or plotFolder:GetAttribute("OwnerId")
            or plotFolder:GetAttribute("UserId")
        if ownerId ~= nil then
            return tostring(ownerId) == tostring(LocalPlayer.UserId)
        end

        local ownerName = plotFolder:GetAttribute("Owner")
            or plotFolder:GetAttribute("OwnerName")
            or plotFolder:GetAttribute("PlayerName")
        if ownerName ~= nil then
            return tostring(ownerName) == LocalPlayer.Name or tostring(ownerName) == LocalPlayer.DisplayName
        end

        return false
    end

    local function getMyPlotFolder()
        local plots = getPlayerPlotsFolder()
        if not plots then return nil end
        for _, plotFolder in ipairs(plots:GetChildren()) do
            if isOwnedByLocalPlayer(plotFolder) then
                return plotFolder
            end
        end
        return nil
    end

    -- ===== [ปรับปรุงใหม่] ระบบสแกนเฉพาะผลไม้บนต้นไม้ เจาะจง ProximityPrompt ที่เป็นผลไม้แท้เท่านั้น =====
    local function scanOnlyRealFruits()
        local plotFolder = getMyPlotFolder()
        if not plotFolder then return {} end

        local fruitList = {}
        
        -- ไล่เช็กทุก ProximityPrompt ในพล็อตของเรา
        for _, desc in ipairs(plotFolder:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                local parentPart = desc.Parent
                local actionText = tostring(desc.ActionText):lower()
                local objectText = tostring(desc.ObjectText):lower()
                local parentName = parentPart and parentPart.Name or ""

                -- บล็อกคำสำคัญของป้าย Robux / แต่งสวน / ซื้อของ / คราฟต์
                local isForbidden = actionText:find("customize") or actionText:find("ปรับแต่ง")
                    or actionText:find("buy") or actionText:find("ซื้อ")
                    or objectText:find("robux") or objectText:find("ทั้งหมด")
                    or parentName:find("Crafting") or parentName:find("Bench")
                    or parentName:find("CollectAll") or parentName:find("Sign")

                -- เงื่อนไข: ต้องไม่ใช่ป้ายต้องห้าม และ parent ต้องมีชื่อเกี่ยวกับ Fruit หรือกดเก็บได้
                if not isForbidden then
                    -- เช็กว่าป้ายอยู่บนต้นไม้ หรือ อยู่ตรงส่วนที่เป็น Fruit
                    local isFruitPart = parentName == "FruitSpawn" 
                        or parentName:find("Fruit") 
                        or parentName:find("Harvest")
                        or (desc.ObjectText and desc.ObjectText ~= "")

                    if isFruitPart then
                        table.insert(fruitList, {
                            part = parentPart,
                            prompt = desc
                        })
                    end
                end
            end
        end
        return fruitList
    end

    -- ===========================================================
    -- ===== Tab เฉพาะแมพนี้: "Greedy Growers" =====
    -- ===========================================================
    local GrowersTab = Window:Tab({ Title = "Greedy Growers", Icon = "sprout" })

    local statusParagraph = GrowersTab:Paragraph({
        Title = "สถานะ",
        Desc = "รอเริ่มทำงาน...",
    })

    local function setStatus(text)
        pcall(function()
            statusParagraph:SetDesc(text)
        end)
    end

    GrowersTab:Section({ Title = "ซื้อเมล็ดอัตโนมัติ", Desc = "สแกนสายพานแล้วซื้อเฉพาะ rarity ที่เปิดไว้" })

    GrowersTab:Toggle({
        Title = "ซื้ออัตโนมัติ",
        Value = _G.AutoBuySeed,
        Callback = function(state)
            _G.AutoBuySeed = state
            if not state then setStatus("ปิดอยู่") end
        end,
    })

    GrowersTab:Toggle({
        Title = "วาปไปซื้อถ้าไกลเกิน",
        Desc = "วาปตัวละครไปยืนใกล้เมล็ดชั่วคราวแล้ววาปกลับที่เดิม",
        Value = _G.AutoTeleportBuy,
        Callback = function(state)
            _G.AutoTeleportBuy = state
        end,
    })

    GrowersTab:Section({ Title = "ขายของอัตโนมัติ", Desc = "ขายของในตัวทั้งหมดตามรอบเวลาที่ตั้ง" })

    GrowersTab:Toggle({
        Title = "ขายของในตัวทั้งหมด",
        Value = _G.AutoSellAll,
        Callback = function(state)
            _G.AutoSellAll = state
        end,
    })

    GrowersTab:Slider({
        Title = "ความถี่ขาย (วินาที)",
        Value = { Min = MIN_SELL_DELAY, Max = MAX_SELL_DELAY, Default = _G.AutoSellInterval },
        Callback = function(value)
            _G.AutoSellInterval = value
        end,
    })

    GrowersTab:Section({ Title = "เก็บผลไม้อัตโนมัติ", Desc = "วาปเจาะจงลอยไปกดเก็บทีละลูกบนต้นไม้" })

    GrowersTab:Toggle({
        Title = "เก็บผลไม้อัตโนมัติ",
        Value = _G.AutoCollectFruit,
        Callback = function(state)
            _G.AutoCollectFruit = state
            if not state then setStatus("ปิดอยู่") end
        end,
    })

    GrowersTab:Section({ Title = "เลือก Rarity ที่จะซื้อ", Desc = "ปิดตัวไหนไว้ สคริปต์จะข้ามเมล็ด rarity นั้นไปเฉยๆ" })

    for _, r in ipairs(RARITY_LIST) do
        GrowersTab:Toggle({
            Title = r .. " / " .. (RARITY_THAI[r] or r),
            Value = _G.AllowedRarities[r],
            Callback = function(state)
                _G.AllowedRarities[r] = state
            end,
        })
    end

    -- ===========================================================
    -- ===== ลูป Auto Sell =====
    -- ===========================================================
    task.spawn(function()
        local lastSellTime = 0
        while true do
            local currentTime = tick()
            local interval = tonumber(_G.AutoSellInterval) or 2.0

            if _G.AutoSellAll then
                if (currentTime - lastSellTime) >= interval then
                    triggerSellAll()
                    lastSellTime = currentTime
                end
            else
                lastSellTime = currentTime
            end

            task.wait(0.1)
        end
    end)

    -- ===========================================================
    -- ===== ลูป Auto Buy =====
    -- ===========================================================
    task.spawn(function()
        while true do
            if _G.AutoBuySeed then
                local seeds = scanAllAvailableSeeds()
                local targetSeed = nil

                for _, item in ipairs(seeds) do
                    if _G.AllowedRarities[item.rarity] == true then
                        targetSeed = item
                        break
                    end
                end

                if targetSeed then
                    local cash = getCurrentCash()
                    if cash >= targetSeed.price then
                        local character = LocalPlayer.Character
                        local root = character and character:FindFirstChild("HumanoidRootPart")
                        if root and targetSeed.object then
                            local origCFrame = root.CFrame
                            root.CFrame = targetSeed.object:GetPivot() + Vector3.new(0, 2, 0)
                            setStatus("กำลังซื้อ: " .. targetSeed.seedType)
                            task.wait(0.1)
                            pcall(function()
                                fireProximityPrompt(targetSeed.prompt)
                            end)
                            task.wait(VERIFY_WAIT)
                            root.CFrame = origCFrame
                        end
                    else
                        setStatus("เงินไม่พอซื้อ: " .. targetSeed.seedType)
                    end
                else
                    setStatus("ไม่พบเมล็ดที่เปิดไว้")
                end
            end
            task.wait(LOOP_INTERVAL)
        end
    end)

    -- ===========================================================
    -- ===== ลูป Auto Collect Fruit (วาปตรงเข้าหาผลไม้บนต้นทีละลูก) =====
    -- ===========================================================
    task.spawn(function()
        while true do
            if _G.AutoCollectFruit then
                local fruitItems = scanOnlyRealFruits()

                if #fruitItems > 0 then
                    local character = LocalPlayer.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")

                    if root then
                        local initialPos = root.CFrame

                        for i, item in ipairs(fruitItems) do
                            if not _G.AutoCollectFruit then break end

                            local prompt = item.prompt
                            local part = item.part

                            if prompt and prompt.Enabled and part and part.Parent then
                                setStatus("กำลังเก็บผลไม้ลูกที่ (" .. i .. "/" .. #fruitItems .. ")")

                                -- วาปไปจ่อลอยอยู่เหนือผลไม้นั้น 1.5 บล็อก
                                root.CFrame = part.CFrame + Vector3.new(0, 1.5, 0)
                                task.wait(0.1)

                                -- กดปุ่มเก็บ
                                pcall(function()
                                    fireProximityPrompt(prompt)
                                end)
                                task.wait(0.15)
                            end
                        end

                        -- พากลับมายืนจุดเดิมก่อนหน้า
                        if root and root.Parent then
                            root.CFrame = initialPos
                        end
                        setStatus("เก็บผลไม้รอบนี้เสร็จแล้ว")
                    end
                else
                    setStatus("ไม่มีผลไม้สุกในพล็อต")
                end
            end

            task.wait(1.5)
        end
    end)

    print("[Greedy Growers] โหลด Tab เรียบร้อย")
end

return GreedyGrowers
