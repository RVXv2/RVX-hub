--[[
    RVX-hub: Greedy Growers Module (ฉบับปรับสมดุลความเร็ว + เอาปุ่มวาร์ปออก + กันตกสวนอัตโนมัติ)
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

    -- ===== ตั้งค่าความเสถียรและระยะเวลาหน่วง =====
    local LOOP_INTERVAL = 0.1
    local VERIFY_WAIT = 0.15
    local TELEPORT_SETTLE_WAIT = 0.12 -- เพิ่มความเสถียรกันบัคตอนวาร์ป
    local COLLECT_DELAY = 0.12        -- ระยะเวลาหน่วงตอนกดเก็บผลไม้กันติดบัค
    local TELEPORT_APPROACH_MARGIN = 2.0
    local MAX_PLOT_RADIUS = 75         -- รัศมีขอบเขตของสวน (หากออกห่างเกินจะวาร์ปดึงกลับ)
    local MIN_SELL_DELAY = 0.5
    local MAX_SELL_DELAY = 30.0

    _G.AutoTeleportBuy = (_G.AutoTeleportBuy == nil) and true or _G.AutoTeleportBuy
    _G.AutoBuySeed = false
    _G.AutoSellAll = false
    _G.AutoSellInterval = 2.0
    _G.AutoCollectFruit = false

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

    local function getTargetPromptPart(targetObj, prompt)
        if targetObj:IsA("BasePart") then return targetObj end
        if prompt.Parent and prompt.Parent:IsA("BasePart") then return prompt.Parent end
        return targetObj:FindFirstChildWhichIsA("BasePart", true)
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

    -- ===== สแกนหา พล็อตของเรา =====
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

    -- ===== ตรวจสอบว่ายังอยู่ในขอบเขตสวนหรือไม่ =====
    local function checkAndKeepInPlot(plotFolder)
        if not plotFolder then return end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local plotCFrame = plotFolder:GetPivot()
        local distFromPlot = (root.Position - plotCFrame.Position).Magnitude

        -- หากหลุดออกนอกขอบเขตสวน ให้ดึงกลับมาตำแหน่งกลางสวนทันที
        if distFromPlot > MAX_PLOT_RADIUS then
            pcall(function()
                root.CFrame = plotCFrame + Vector3.new(0, 3, 0)
            end)
            task.wait(0.1)
        end
    end

    -- ===== ระบบกรองผลไม้จริงบนต้น =====
    local function isRealTreeFruit(prompt)
        if not prompt or not prompt.Parent then return false end

        local part = prompt.Parent
        local grandParent = part.Parent

        if prompt.ObjectText:find("Collect All") or prompt.ActionText == "Buy" then
            return false
        end

        if part.Name ~= "FruitSpawn" or not grandParent or grandParent.Name ~= "FruitSpawns" then
            return false
        end

        local plotFolder = getMyPlotFolder()
        if plotFolder and plotFolder:IsA("Model") then
            local plotPivot = plotFolder:GetPivot()
            local heightDifference = part.Position.Y - plotPivot.Position.Y
            if heightDifference < 3.5 then
                return false
            end
        end

        return true
    end

    local function scanOnlyRealFruits()
        local plotFolder = getMyPlotFolder()
        if not plotFolder then return {} end

        local candidates = {}
        for _, desc in ipairs(plotFolder:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then
                if isRealTreeFruit(desc) then
                    table.insert(candidates, {
                        object = desc.Parent,
                        prompt = desc,
                        plotName = plotFolder.Name,
                    })
                end
            end
        end
        return candidates
    end

    local function teleportNearTarget(targetObj, prompt)
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local part = getTargetPromptPart(targetObj, prompt)
        if not root or not part then return false, nil end

        local maxDist = prompt.MaxActivationDistance or 5
        local approachDist = math.max(maxDist - TELEPORT_APPROACH_MARGIN, 1)
        local originalCFrame = root.CFrame

        local ok = pcall(function()
            local targetPos = part.Position + Vector3.new(0, 0, approachDist)
            root.CFrame = CFrame.new(targetPos, part.Position)
        end)

        if not ok then return false, nil end

        local function teleportBack()
            pcall(function()
                if root and root.Parent then root.CFrame = originalCFrame end
            end)
        end

        return true, teleportBack
    end

    -- ===========================================================
    -- ===== UI Tab: Greedy Growers =====
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

    GrowersTab:Section({ Title = "เก็บผลไม้อัตโนมัติ", Desc = "วาร์ปเก็บผลไม้ในพล็อตอัตโนมัติ พร้อมระบบป้องกันหลุดนอกสวน" })

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
                        local moved, teleportBackFn = teleportNearTarget(targetSeed.object, targetSeed.prompt)
                        if moved then
                            setStatus("วาปไปซื้อ: " .. targetSeed.seedType)
                            task.wait(TELEPORT_SETTLE_WAIT)
                            
                            pcall(function()
                                fireProximityPrompt(targetSeed.prompt)
                            end)
                            task.wait(VERIFY_WAIT)

                            if teleportBackFn then
                                teleportBackFn()
                            end
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
    -- ===== ลูป Auto Collect Fruit (ปรับไม่ให้ไวเกินจนบัค + กันหลุดสวน) =====
    -- ===========================================================
    task.spawn(function()
        while true do
            if _G.AutoCollectFruit then
                local myPlot = getMyPlotFolder()
                
                -- เช็คเสมอว่าถ้าหลุดสวนให้ดึงกลับเข้ามาที่สวนก่อน
                if myPlot then
                    checkAndKeepInPlot(myPlot)
                end

                local fruits = scanOnlyRealFruits()

                if #fruits > 0 then
                    local character = LocalPlayer.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    local startCFrame = root and root.CFrame

                    for i, target in ipairs(fruits) do
                        if not _G.AutoCollectFruit then break end
                        
                        -- เช็คขอบเขตสวนระหว่างวนเก็บผลไม้
                        checkAndKeepInPlot(myPlot)

                        if target.prompt and target.prompt.Enabled and isRealTreeFruit(target.prompt) then
                            setStatus("กำลังเก็บผลไม้ (" .. i .. "/" .. #fruits .. "): " .. tostring(target.plotName))

                            local targetPart = getTargetPromptPart(target.object, target.prompt)
                            if root and targetPart then
                                local maxDist = target.prompt.MaxActivationDistance or 5
                                local approachDist = math.max(maxDist - TELEPORT_APPROACH_MARGIN, 1)
                                
                                pcall(function()
                                    local targetPos = targetPart.Position + Vector3.new(0, 0, approachDist)
                                    root.CFrame = CFrame.new(targetPos, targetPart.Position)
                                end)
                                
                                -- หน่วงเวลาสั้นๆ หลังวาร์ปกันบัค
                                task.wait(TELEPORT_SETTLE_WAIT)
                            end

                            pcall(function()
                                fireProximityPrompt(target.prompt)
                            end)
                            
                            -- หน่วงเวลาเล็กน้อยหลังกดเก็บ
                            task.wait(COLLECT_DELAY)
                        end
                    end

                    -- เมื่อเก็บผลไม้หมดสวนเรียบร้อยแล้ว ค่อยดึงกลับจุดเดิม
                    if startCFrame and root and root.Parent then
                        pcall(function()
                            root.CFrame = startCFrame
                        end)
                    end

                    setStatus("เก็บผลไม้หมดรอบแล้ว")
                else
                    setStatus("ไม่มีผลไม้สุกในพล็อต")
                end
            end

            task.wait(LOOP_INTERVAL)
        end
    end)

    print("[Greedy Growers] โหลด Tab เรียบร้อย")
end

return GreedyGrowers
