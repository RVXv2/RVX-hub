--[[
    RVX-hub: Greedy Growers Module (โมดูลเสริมเฉพาะแมพ)

    ไฟล์นี้ "ไม่ได้" สร้าง Window เอง — มันคาดหวังว่า universal.lua (หรือไฟล์หลัก)
    จะเป็นคนสร้าง Window/WindUI ไว้ก่อนแล้ว (ผ่าน Core.Init) แล้วค่อยโหลดไฟล์นี้มา
    เรียก GreedyGrowers.Init(Window, WindUI) เพื่อเพิ่ม Tab "Greedy Growers" ทับเข้าไป
    เหมือนกับที่ RVXHub_Scripts.lua ถูกโหลดผ่าน Core.Scripts

    ฝั่ง universal.lua ต้องมีโค้ดประมาณนี้ (ดูตัวอย่างเต็มในคำอธิบายที่แชทให้ไว้):

        local MAP_MODULES = {
            [74102906764176] = "https://raw.githubusercontent.com/RVXv2/RVX-hub/main/games/greedygrowers.lua",
        }
        local moduleUrl = MAP_MODULES[game.PlaceId]
        if moduleUrl then
            local ok, Module = pcall(function()
                return loadstring(game:HttpGet(moduleUrl))()
            end)
            if ok and type(Module) == "table" and type(Module.Init) == "function" then
                pcall(function() Module.Init(Window, WindUI) end)
            end
        end

    ด้วยวิธีนี้ ฟีเจอร์ Auto Buy/Sell ในไฟล์นี้จะโผล่ "เฉพาะตอนอยู่ในแมพ Greedy Growers"
    (PlaceId 74102906764176) เท่านั้น แมพอื่นจะไม่ถูกโหลดไฟล์นี้เลยตั้งแต่ต้น
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
    local VERIFY_WAIT = 0.4
    local DISTANCE_SAFETY_MARGIN = 1.0
    local TELEPORT_APPROACH_MARGIN = 2.0
    local TELEPORT_SETTLE_WAIT = 0.1
    local TELEPORT_RETURN_WAIT = 0.15
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

    -- ===== สแกนสายพาน =====
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

    -- ===== สแกนหาผลไม้ที่เก็บได้ทั่วสวน (ทุกพล็อตของเรา) =====
    local function getPlayerPlotsFolder()
        local bigField = workspace:FindFirstChild("BigField")
        return bigField and bigField:FindFirstChild("PlayerPlots")
    end

    local function isOwnedByLocalPlayer(plotFolder)
        -- ชื่อ Attribute เจ้าของพล็อตจริงตามที่เจอจากการสำรวจ: OwnerUserId
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

        return false -- ไม่มี Attribute เจ้าของเลย และไม่ใช่ Model พล็อตที่รู้จัก ถือว่าไม่ใช่ของเรา (ปลอดภัยไว้ก่อน)
    end

    local function scanAllFruitPrompts()
        local plots = getPlayerPlotsFolder()
        if not plots then return {} end

        local candidates = {}
        for _, plotFolder in ipairs(plots:GetChildren()) do
            if isOwnedByLocalPlayer(plotFolder) then
                for _, desc in ipairs(plotFolder:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") then
                        local actionText = tostring(desc.ActionText or ""):lower()
                        local looksLikeCollect = actionText:find("collect", 1, true)
                            or actionText:find("เก็บ", 1, true)
                        if looksLikeCollect and desc.Enabled then
                            table.insert(candidates, {
                                object = desc.Parent,
                                prompt = desc,
                                plotName = plotFolder.Name,
                            })
                        end
                    end
                end
            end
        end
        return candidates
    end

    -- ===== วาปและระยะ =====
    local function getDistanceToPart(part)
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root or not part then return math.huge end
        return (root.Position - part.Position).Magnitude
    end

    local function isWithinRange(targetObj, prompt)
        local part = getTargetPromptPart(targetObj, prompt)
        if not part then return true end
        local maxDist = prompt.MaxActivationDistance or 5
        return getDistanceToPart(part) <= math.max(maxDist - DISTANCE_SAFETY_MARGIN, 0)
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
    -- ===== Tab เฉพาะแมพนี้: "Greedy Growers" =====
    -- ===========================================================
    local GrowersTab = Window:Tab({ Title = "Greedy Growers", Icon = "sprout" })

    -- แสดงสถานะสดๆ (อัปเดตผ่าน :SetDesc())
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

    GrowersTab:Section({ Title = "เก็บผลไม้อัตโนมัติ", Desc = "เก็บผลไม้สุกทุกต้นในพล็อตของเรา" })

    GrowersTab:Toggle({
        Title = "เก็บผลไม้อัตโนมัติ",
        Value = _G.AutoCollectFruit,
        Callback = function(state)
            _G.AutoCollectFruit = state
            if not state then setStatus("ปิดอยู่") end
        end,
    })

    GrowersTab:Toggle({
        Title = "วาปไปเก็บถ้าไกลเกิน",
        Desc = "วาปตัวละครไปยืนใกล้ผลไม้ชั่วคราวแล้ววาปกลับที่เดิม",
        Value = _G.AutoTeleportCollect,
        Callback = function(state)
            _G.AutoTeleportCollect = state
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
                        local inRange = isWithinRange(targetSeed.object, targetSeed.prompt)
                        local teleportBackFn = nil

                        if not inRange then
                            if _G.AutoTeleportBuy then
                                local moved, backFn = teleportNearTarget(targetSeed.object, targetSeed.prompt)
                                if moved then
                                    teleportBackFn = backFn
                                    setStatus("วาปไปซื้อ: " .. targetSeed.seedType)
                                    task.wait(TELEPORT_SETTLE_WAIT)
                                    inRange = true
                                end
                            else
                                setStatus("พบเมล็ดที่เปิดแต่ไกลเกิน: " .. targetSeed.seedType)
                            end
                        end

                        if inRange then
                            setStatus("กำลังซื้อ: " .. targetSeed.seedType)
                            pcall(function()
                                fireProximityPrompt(targetSeed.prompt)
                            end)
                            task.wait(VERIFY_WAIT)
                        end

                        if teleportBackFn then
                            task.wait(TELEPORT_RETURN_WAIT)
                            teleportBackFn()
                        end
                    else
                        setStatus("เงินไม่พอซื้อ: " .. targetSeed.seedType)
                    end
                else
                    setStatus("ไม่พบเมล็ดที่เปิดไว้")
                end
            else
                setStatus("ปิดอยู่")
            end

            task.wait(LOOP_INTERVAL)
        end
    end)

    -- ===========================================================
    -- ===== ลูป Auto Collect Fruit =====
    -- ===========================================================
    task.spawn(function()
        local lastFruitLogKey = nil
        while true do
            if _G.AutoCollectFruit then
                local plots = getPlayerPlotsFolder()
                if not plots then
                    if lastFruitLogKey ~= "NO_PLOTS_FOLDER" then
                        warn("[เก็บผลไม้][DEBUG] หา Workspace.BigField.PlayerPlots ไม่เจอเลย")
                        lastFruitLogKey = "NO_PLOTS_FOLDER"
                    end
                else
                    local fruits = scanAllFruitPrompts()
                    local logKey = "COUNT_" .. tostring(#fruits)

                    if #fruits == 0 then
                        if lastFruitLogKey ~= logKey then
                            print("[เก็บผลไม้][DEBUG] สแกนพล็อตแล้ว แต่ไม่เจอผลไม้ที่พร้อมเก็บตอนนี้ (พล็อตทั้งหมด: " .. #plots:GetChildren() .. ")")
                            lastFruitLogKey = logKey
                        end
                    else
                        lastFruitLogKey = nil -- รีเซ็ต กันพลาดตอนมีผลไม้ใหม่

                        local target = fruits[1]
                        local inRange = isWithinRange(target.object, target.prompt)
                        local teleportBackFn = nil

                        if not inRange then
                            if _G.AutoTeleportCollect then
                                local moved, backFn = teleportNearTarget(target.object, target.prompt)
                                if moved then
                                    teleportBackFn = backFn
                                    setStatus("วาปไปเก็บผลไม้: " .. tostring(target.plotName))
                                    task.wait(TELEPORT_SETTLE_WAIT)
                                    inRange = true
                                end
                            else
                                setStatus("พบผลไม้แต่ไกลเกิน: " .. tostring(target.plotName))
                            end
                        end

                        if inRange then
                            setStatus("กำลังเก็บผลไม้: " .. tostring(target.plotName) .. " (เหลืออีก " .. #fruits .. " ลูก)")
                            pcall(function()
                                fireProximityPrompt(target.prompt)
                            end)
                            task.wait(VERIFY_WAIT)
                        end

                        if teleportBackFn then
                            task.wait(TELEPORT_RETURN_WAIT)
                            teleportBackFn()
                        end
                    end
                end
            else
                setStatus("ปิดอยู่")
            end

            task.wait(LOOP_INTERVAL)
        end
    end)

    print("[Greedy Growers] โหลด Tab เรียบร้อย")
end

return GreedyGrowers
