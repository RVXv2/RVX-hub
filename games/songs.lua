local Core = {}

local API_BASE = "http://de3.bot-hosting.net:20209"
local API_KEY  = "sgid_31b8690121b792dc6274b58b2df2dcc50ba656af"

function Core.AddSongsTab(Window, WindUI, enablePlayback)
    local SongsTab = Window:Tab({ Title = "เพลง", Icon = "music" })
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer

    -- ===== ระบบเสกลำโพง + เปิดเพลง (เฉพาะ enablePlayback = true) =====
    if enablePlayback then
        SongsTab:Section({ Title = "เครื่องเล่นเพลง", Desc = "หยิบลำโพงและเปิดเพลงด้วย ID" })

        local function IsHoldingBoombox()
            local char = LocalPlayer.Character
            if not char then return false end
            for _, v in pairs(char:GetChildren()) do
                if v:IsA("Tool") and v.Name:lower():find("boom") then
                    return true
                end
            end
            return false
        end

        local function EquipBoombox()
            if IsHoldingBoombox() then return true end
            local ok = pcall(function()
                local Rep = ReplicatedStorage
                local toolRemote = Rep:WaitForChild("RE"):WaitForChild("1Too1l")
                toolRemote:InvokeServer("PickingTools", "Boombox")
            end)
            task.wait(0.5)
            return ok
        end

        local function PlayMusic(id)
            id = tostring(id):gsub("%D", "")
            if id == "" then return false end

            EquipBoombox()

            local ok = pcall(function()
                local Rep = ReplicatedStorage
                local playRemote = Rep:WaitForChild("RE"):WaitForChild("PlayerToolEvent")
                playRemote:FireServer("ToolMusicText", id, nil, true)
            end)

            return ok
        end

        local function StopMusic()
            pcall(function()
                local Rep = ReplicatedStorage
                local playRemote = Rep:WaitForChild("RE"):WaitForChild("PlayerToolEvent")
                playRemote:FireServer("ToolMusicText", "", nil, true)
            end)
        end

        SongsTab:Button({
            Title = "เสกลำโพง",
            Icon = "speaker",
            Callback = function()
                if IsHoldingBoombox() then
                    WindUI:Notify({ Title = "เพลง", Content = "ถือลำโพงอยู่แล้ว", Duration = 2 })
                    return
                end

                local ok = EquipBoombox()
                if ok then
                    WindUI:Notify({ Title = "สำเร็จ", Content = "หยิบลำโพงแล้ว", Duration = 2 })
                else
                    WindUI:Notify({ Title = "ผิดพลาด", Content = "หยิบลำโพงไม่สำเร็จ", Duration = 3 })
                end
            end,
        })

        local currentId = ""

        SongsTab:Input({
            Title = "เปิดเพลงด้วย ID",
            Placeholder = "ใส่ Audio ID เช่น 1234567890",
            Callback = function(text)
                currentId = text:gsub("%D", "")
            end,
        })

        SongsTab:Button({
            Title = "เล่นเพลง",
            Icon = "play",
            Callback = function()
                if currentId == "" then
                    WindUI:Notify({ Title = "ผิดพลาด", Content = "กรุณาใส่ Audio ID ก่อน", Duration = 3 })
                    return
                end

                local ok = PlayMusic(currentId)
                if ok then
                    WindUI:Notify({ Title = "กำลังเล่น", Content = "ID: " .. currentId, Duration = 2 })
                else
                    WindUI:Notify({ Title = "ผิดพลาด", Content = "เล่นเพลงไม่สำเร็จ", Duration = 3 })
                end
            end,
        })

        SongsTab:Button({
            Title = "หยุดเพลง",
            Icon = "square",
            Callback = function()
                StopMusic()
                WindUI:Notify({ Title = "หยุดแล้ว", Content = "หยุดเล่นเพลง", Duration = 2 })
            end,
        })
    end

    -- ===== ค้นหาเพลงจาก API (ใช้ได้ทุกแมพ) =====
    SongsTab:Section({ Title = "ค้นหาเพลง", Desc = "ดึงข้อมูลจาก API สาธารณะ" })

    local AllSongs = {}
    local SongButtons = {}
    local RenderToken = 0

    -- สร้างปุ่มแบบแบ่งเฟรม กันสคริปต์ค้างเวลามีเพลงเยอะ
    local function RenderSongs(filterText)
        RenderToken = RenderToken + 1
        local myToken = RenderToken

        for _, btn in ipairs(SongButtons) do
            pcall(function()
                if btn.Destroy then btn:Destroy() end
            end)
        end
        table.clear(SongButtons)

        task.spawn(function()
            local shown = 0
            local errorCount = 0
            local sinceYield = 0

            for _, song in ipairs(AllSongs) do
                if myToken ~= RenderToken then
                    break
                end

                local matches = filterText == "" or string.find(string.lower(song.name), string.lower(filterText), 1, true)
                if matches then
                    local ok, b = pcall(function()
                        return SongsTab:Button({
                            Title = song.name .. "  |  ID: " .. song.id,
                            Icon = "copy",
                            Callback = function()
                                if setclipboard then
                                    setclipboard(song.id)
                                end
                                WindUI:Notify({
                                    Title = "คัดลอกแล้ว",
                                    Content = song.name .. " (" .. song.id .. ")",
                                    Duration = 2,
                                })
                            end,
                        })
                    end)

                    if ok then
                        table.insert(SongButtons, b)
                        shown = shown + 1
                    else
                        errorCount = errorCount + 1
                    end

                    sinceYield = sinceYield + 1
                    if sinceYield >= 8 then
                        sinceYield = 0
                        task.wait()
                    end
                end
            end

            if myToken == RenderToken then
                if errorCount > 0 then
                    WindUI:Notify({ Title = "มีข้อผิดพลาด", Content = "สร้างปุ่มไม่สำเร็จ " .. errorCount .. " อัน", Duration = 5 })
                end
                WindUI:Notify({ Title = "แสดงผลแล้ว", Content = "โชว์ " .. shown .. " เพลง", Duration = 3 })
            end
        end)
    end

    local function LoadSongs()
        task.spawn(function()
            local fn = (syn and syn.request) or request or http_request or fluxus_request
            if not fn then
                WindUI:Notify({ Title = "ผิดพลาด", Content = "Executor นี้ไม่มีฟังก์ชัน request", Duration = 5 })
                return
            end

            local ok, res = pcall(fn, {
                Url = API_BASE .. "/api/public/songs?banned=false&limit=5000",
                Method = "GET",
                Headers = { ["X-API-Key"] = API_KEY },
            })

            if not ok or not res or not res.Body then
                WindUI:Notify({ Title = "ผิดพลาด", Content = "โหลดข้อมูลไม่สำเร็จ", Duration = 4 })
                return
            end

            local decOk, decoded = pcall(function()
                return game:GetService("HttpService"):JSONDecode(res.Body)
            end)

            if not decOk or not decoded then
                WindUI:Notify({ Title = "แปลง JSON ไม่ได้", Content = tostring(res.Body):sub(1, 100), Duration = 6 })
                return
            end

            AllSongs = decoded
            RenderSongs("")
        end)
    end

    SongsTab:Input({
        Title = "ค้นหาเพลง",
        Placeholder = "พิมพ์ชื่อเพลง...",
        Callback = function(text)
            RenderSongs(text)
        end,
    })

    SongsTab:Button({
        Title = "รีเฟรชรายการ",
        Icon = "refresh-cw",
        Callback = function()
            LoadSongs()
        end,
    })

    SongsTab:Section({ Title = "รายการเพลง" })

    LoadSongs()
end

-- ===== แท็บดูดไอดีเพลง (ใช้ได้ทุกแมพ ไม่ผูกกับ Remote เฉพาะเกม) =====
function Core.AddSniffTab(Window, WindUI)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local SniffTab = Window:Tab({ Title = "ดูดไอดีเพลง", Icon = "radio" })

    SniffTab:Section({ Title = "สแกนเพลงในแมพ", Desc = "กดปุ่มรีเฟรชเพื่อสแกนเอง ไม่สแกนอัตโนมัติ" })

    local DetectedSongs = {}
    local SniffButtons = {}

    local function IsValidAudioId(soundId)
        if type(soundId) ~= "string" then return false, nil end
        local id = soundId:match("^rbxassetid://(%d+)$")
        if id then
            return true, id
        end
        return false, nil
    end

    local function ScanPlayingSongs()
        local results = {}
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char and player ~= LocalPlayer then
                local charRoot = char:FindFirstChild("HumanoidRootPart")

                for _, obj in ipairs(char:GetDescendants()) do
                    if obj:IsA("Sound") and obj.IsPlaying then
                        local valid, audioId = IsValidAudioId(obj.SoundId)
                        if valid then
                            local dist = math.huge
                            if myRoot and charRoot then
                                dist = (myRoot.Position - charRoot.Position).Magnitude
                            end
                            table.insert(results, {
                                playerName = player.Name,
                                id = audioId,
                                distance = dist,
                            })
                        end
                    end
                end
            end
        end

        return results
    end

    local function RenderSniffList()
        for _, btn in ipairs(SniffButtons) do
            pcall(function()
                if btn.Destroy then btn:Destroy() end
            end)
        end
        table.clear(SniffButtons)

        DetectedSongs = ScanPlayingSongs()

        if #DetectedSongs == 0 then
            WindUI:Notify({ Title = "ดูดไอดีเพลง", Content = "ไม่พบเพลงที่กำลังเล่นอยู่ในตอนนี้", Duration = 3 })
            return
        end

        table.sort(DetectedSongs, function(a, b)
            return a.distance < b.distance
        end)

        for _, song in ipairs(DetectedSongs) do
            local distText = "ไม่ทราบระยะ"
            if song.distance ~= math.huge then
                distText = string.format("%.0f สตัด", song.distance)
            end

            local ok, btn = pcall(function()
                return SniffTab:Button({
                    Title = song.playerName .. "  |  ID: " .. song.id,
                    Desc = "ระยะห่าง: " .. distText .. " | แตะเพื่อคัดลอก ID",
                    Icon = "copy",
                    Callback = function()
                        if setclipboard then
                            setclipboard(song.id)
                        end
                        WindUI:Notify({
                            Title = "คัดลอกแล้ว",
                            Content = song.playerName .. " (" .. song.id .. ")",
                            Duration = 2,
                        })
                    end,
                })
            end)

            if ok then
                table.insert(SniffButtons, btn)
            end
        end

        WindUI:Notify({ Title = "ดูดไอดีเพลง", Content = "พบ " .. #DetectedSongs .. " เพลงที่กำลังเล่นอยู่", Duration = 3 })
    end

    SniffTab:Button({
        Title = "ดูดคนใกล้ที่สุด",
        Icon = "crosshair",
        Callback = function()
            DetectedSongs = ScanPlayingSongs()

            if #DetectedSongs == 0 then
                WindUI:Notify({ Title = "ผิดพลาด", Content = "ไม่พบเพลงที่กำลังเล่นอยู่ตอนนี้", Duration = 3 })
                return
            end

            table.sort(DetectedSongs, function(a, b)
                return a.distance < b.distance
            end)

            local nearest = DetectedSongs[1]
            if setclipboard then
                setclipboard(nearest.id)
            end
            WindUI:Notify({
                Title = "ดูดสำเร็จ",
                Content = nearest.playerName .. " (" .. nearest.id .. ")",
                Duration = 3,
            })
        end,
    })

    SniffTab:Button({
        Title = "รีเฟรชรายการ",
        Icon = "refresh-cw",
        Callback = function()
            RenderSniffList()
        end,
    })

    SniffTab:Section({ Title = "รายการเพลงที่กำลังเล่น (กดรีเฟรชเพื่อสแกน)" })

    -- ไม่เรียก RenderSniffList() อัตโนมัติแล้ว ต้องกดปุ่มเองเท่านั้น
end

return Core
