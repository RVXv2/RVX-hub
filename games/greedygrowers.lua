--[[
    RVX-hub: Greedy Growers Module (ฉบับรวมระบบครบ + Optimize ลดอาการแล็ก)
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
    local VirtualInputManager = game:GetService("VirtualInputManager")
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
    local TELEPORT_SETTLE_WAIT = 0.12
    local COLLECT_DELAY = 0.12
    local TELEPORT_APPROACH_MARGIN = 2.0
    local MAX_PLOT_RADIUS = 75
    local MIN_SELL_DELAY = 0.5
    local MAX_SELL_DELAY = 30.0

    -- ===== ตัวแปรสถานะระบบ (Global States) =====
    _G.AutoTeleportBuy = (_G.AutoTeleportBuy == nil) and true or _G.AutoTeleportBuy
    _G.AutoBuySeed = false
    _G.AutoSellAll = false
    _G.AutoSellInterval = 2.0
    _G.AutoCollectFruit = false
    
    -- ระบบ Auto Plant & Freeze Detector
    _G.AutoPlant = false
    _G.AutoCollectFreeze = false
    _G.TargetMultiplier = 100000
    _G.SelectedSlot = 2

    local lastMultValue = 0
    local sameCount = 0

    local numKeyCodes = {
        Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,
        Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six,
        Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine
    }

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

    -- ===== ฟังก์ชันสลับถือเมล็ดตาม Hotbar =====
    local function forceSwitchToSeed()
        local char = LocalPlayer.Character
        if not char then return end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local backpack = LocalPlayer:FindFirstChild("Backpack")

        if humanoid then
            humanoid:UnequipTools()
            task.wait(0.05)
        end

        if backpack and humanoid then
            local tools = backpack:GetChildren()
            if tools[_G.SelectedSlot] then
                humanoid:EquipTool(tools[_G.SelectedSlot])
                task.wait(0.05)
                if char:FindFirstChildOfClass("Tool") == tools[_G.SelectedSlot] then
                    return
                end
            end
        end

        local key = numKeyCodes[_G.SelectedSlot]
        if key then
            VirtualInputManager:SendKeyEvent(true, key, false, game)
            task.wait(0.03)
            VirtualInputManager:SendKeyEvent(false, key, false, game)
        end
    end

    -- ===== ฟังก์ชันกดปุ๋ยวิเศษกลางจอ =====
    local function clickMagicFertilizer()
        local viewPort = workspace.CurrentCamera.ViewportSize
        local targetX = viewPort.X * 0.70
        local targetY = viewPort.Y * 0.42

        VirtualInputManager:SendMouseButtonEvent(targetX, targetY, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(targetX, targetY, 0, false, game, 0)
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

    -- ===== ตรวจสอบขอบเขตสวน =====
    local function checkAndKeepInPlot(plotFolder)
        if not plotFolder then return end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local plotCFrame = plotFolder:GetPivot()
        local distFromPlot = (root.Position - plotCFrame.Position).Magnitude

        if distFromPlot > MAX_PLOT_RADIUS then
            pcall(function()
                root.CFrame = plotCFrame + Vector3.new(0, 3, 0)
            end)
            task.wait(0.1)
        end
    end

    -- ===== สแกนหาแปลงปลูกที่ว่างเปล่าในพล็อตตัวเอง (Optimize) =====
    local function getOnlyPlantPrompt()
        local myPlot = getMyPlotFolder()
        if not myPlot then return nil end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end

        for _, obj in ipairs(myPlot:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local parentPart = obj.Parent:IsA("BasePart") and obj.Parent or (obj.Parent:IsA("Model") and obj.Parent.PrimaryPart)
                if parentPart and (hrp.Position - parentPart.Position).Magnitude < 18 then
                    local actText = obj.ActionText:lower()
                    local objText = obj.ObjectText:lower()

                    local isHarvestPrompt = actText:find("เก็บ") or objText:find("เก็บ") or 
                                            actText:find("harvest") or actText:find("collect")

                    if (obj.Name == "PlantSeedPrompt" or objText:find("เมล็ด") or actText:find("ปลูก") or actText:find("plant")) 
                       and not isHarvestPrompt then
                        return obj
                    end
                end
            end
        end
        return nil
    end

    -- ===== ระบบตรวจจับตัวคูณหยุดนิ่งเพื่อเก็บ (Optimize ลดแล็ก) =====
    local function checkAndCollectFreeze()
        local myPlot = getMyPlotFolder()
        if not myPlot then return false, 0, false end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false, 0, false end

        for _, gui in ipairs(myPlot:GetDescendants()) do
            if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
                local adornee = gui.Adornee or gui.Parent
                local pos = adornee:IsA("BasePart") and adornee.Position or (adornee:IsA("Model") and adornee.PrimaryPart and adornee.PrimaryPart.Position)

                if pos and (hrp.Position - pos).Magnitude < 18 then
                    local currentMult = 0

                    for _, label in ipairs(gui:GetDescendants()) do
                        if label:IsA("TextLabel") and label.Text:find("x") then
                            local numStr = label.Text:match("([%d%.]+)x") or label.Text:match("x([%d%.]+)")
                            if numStr then 
                                currentMult = tonumber(numStr) or 0 
                            end
                        end
                    end

                    if currentMult > 1 then
                        local isFrozen = false
                        
                        if math.abs(currentMult - lastMultValue) < 0.01 then
                            sameCount = sameCount + 1
                        else
                            sameCount = 0
                        end
                        lastMultValue = currentMult

                        if sameCount >= 2 then
                            isFrozen = true
                        end

                        if currentMult >= _G.TargetMultiplier or isFrozen then
                            local rootModel = gui:FindFirstAncestorOfClass("Model") or adornee
                            if rootModel then
                                for _, prompt in ipairs(rootModel:GetDescendants()) do
                                    if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                                        forceSwitchToSeed()
                                        task.wait(0.05)

                                        if fireProximityPrompt then
                                            fireProximityPrompt(prompt)
                                        else
                                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                            task.wait(0.05)
                                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                        end

                                        sameCount = 0
                                        lastMultValue = 0
                                        return true, currentMult, isFrozen
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return false, 0, false
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

    GrowersTab:Section({ Title = "ระบบปลูกพืชและเก็บเมื่อคูณนิ่ง (Freeze Detector)", Desc = "ปลูก ใส่ปุ๋ย และเก็บอัตโนมัติเมื่อตัวคูณหยุดเพิ่ม" })

    GrowersTab:Toggle({
        Title = "Auto Plant (ปลูก + ใส่ปุ๋ย)",
        Value = _G.AutoPlant,
        Callback = function(state)
            _G.AutoPlant = state
            if not state then setStatus("ปิดการปลูกอัตโนมัติ") end
        end,
    })

    GrowersTab:Toggle({
        Title = "Auto Collect Freeze (เก็บเมื่อคูณนิ่ง)",
        Value = _G.AutoCollectFreeze,
        Callback = function(state)
            _G.AutoCollectFreeze = state
            if not state then setStatus("ปิดการเก็บเมื่อคูณนิ่ง") end
        end,
    })

    GrowersTab:Input({
        Title = "เป้าหมายตัวคูณ ( Target Multiplier )",
        Default = tostring(_G.TargetMultiplier),
        Placeholder = "เช่น 100000",
        Callback = function(text)
            local val = tonumber(text)
            if val then _G.TargetMultiplier = val end
        end,
    })

    GrowersTab:Slider({
        Title = "ช่องใส่เมล็ดพันธุ์ (Hotbar Slot)",
        Value = { Min = 1, Max = 9, Default = _G.SelectedSlot },
        Callback = function(value)
            _G.SelectedSlot = math.floor(value)
        end,
    })

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

    GrowersTab:Section({ Title = "เก็บผลไม้อัตโนมัติ (วาร์ปเก็บ)", Desc = "วาร์ปเก็บผลไม้ทุกต้นในพล็อตอัตโนมัติ" })

    GrowersTab:Toggle({
        Title = "เก็บผลไม้อัตโนมัติ (วาร์ปเก็บ)",
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
    -- ===== ลูป Auto Plant & Freeze Collect Detector (Optimize) =====
    -- ===========================================================
    task.spawn(function()
        while true do
            if _G.AutoCollectFreeze then
                local collected, mult, isFrozen = checkAndCollectFreeze()
                if collected then
                    if isFrozen then
                        setStatus(string.format("❄️ ตัวคูณหยุดเพิ่มที่ x%.2f! กำลังเก็บ...", mult))
                    else
                        setStatus(string.format("💰 เก็บเกี่ยว x%.2f ถึงเป้าหมายแล้ว!", mult))
                    end
                    task.wait(0.4)
                    forceSwitchToSeed()
                end
            end

            if _G.AutoPlant then
                local char = LocalPlayer.Character
                local currentTool = char and char:FindFirstChildOfClass("Tool")
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                local targetTool = backpack and backpack:GetChildren()[_G.SelectedSlot]
                
                if not currentTool or (targetTool and currentTool ~= targetTool) then
                    forceSwitchToSeed()
                end

                local prompt = getOnlyPlantPrompt()
                if prompt then
                    setStatus("🌱 เจอแปลงว่าง! กำลังปลูก...")
                    if fireProximityPrompt then
                        fireProximityPrompt(prompt)
                    else
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    end

                    task.wait(0.2)
                    clickMagicFertilizer()
                    
                    setStatus("ปลูกแล้ว! เตรียมปลูกต่อ...")
                    task.wait(0.4)
                    forceSwitchToSeed()
                end
            end

            task.wait(0.6)
        end
    end)

    -- ===========================================================
    -- ===== ลูป Auto Collect Fruit (แบบวาร์ปดั้งเดิม) =====
    -- ===========================================================
    task.spawn(function()
        while true do
            if _G.AutoCollectFruit then
                local myPlot = getMyPlotFolder()
                
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
                                
                                task.wait(TELEPORT_SETTLE_WAIT)
                            end

                            pcall(function()
                                fireProximityPrompt(target.prompt)
                            end)
                            
                            task.wait(COLLECT_DELAY)
                        end
                    end

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

    print("[Greedy Growers] โหลด Tab และระบบ Freeze Detector (Optimize) เรียบร้อย")
end

return GreedyGrowers
