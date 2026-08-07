local Core = {}

local API_BASE = "http://de3.bot-hosting.net:20209"
local API_KEY  = "sgid_08168ec5efd4de42468154fadb9e9a9f38ebff76"

function Core.AddSongsTab(Window, WindUI)
    local SongsTab = Window:Tab({ Title = "เพลง", Icon = "music" })
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer

    -- ===== ระบบเสกลำโพง + เปิดเพลง =====
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

    -- ===== ค้นหาเพลงจาก API =====
    SongsTab:Section({ Title = "ค้นหาเพลง", Desc = "ดึงข้อมูลจาก API สาธารณะ" })

    local AllSongs = {}
    local SongButtons = {}

    local function RenderSongs(filterText)
        for _, btn in ipairs(SongButtons) do
            pcall(function()
                if btn.Destroy then btn:Destroy() end
            end)
        end
        table.clear(SongButtons)

        local shown = 0
        local errorCount = 0

        for _, song in ipairs(AllSongs) do
            local matches = filterText == "" or string.find(string.lower(song.name), string.lower(filterText), 1, true)
            if matches then
                -- ปุ่มเล่น
                local playOk, playBtn = pcall(function()
                    return SongsTab:Button({
                        Title = "▶ " .. song.name .. "  |  ID: " .. song.id,
                        Icon = "play",
                        Callback = function()
                            local ok = PlayMusic(song.id)
                            if ok then
                                WindUI:Notify({ Title = "กำลังเล่น", Content = song.name, Duration = 2 })
                            else
                                WindUI:Notify({ Title = "ผิดพลาด", Content = "เล่นเพลงไม่สำเร็จ", Duration = 3 })
                            end
                        end,
                    })
                end)

                -- ปุ่มคัดลอก ID
                local copyOk, copyBtn = pcall(function()
                    return SongsTab:Button({
                        Title = "คัดลอก ID",
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

                if playOk then
                    table.insert(SongButtons, playBtn)
                    shown += 1
                else
                    errorCount += 1
                end

                if copyOk then
                    table.insert(SongButtons, copyBtn)
                end
            end
        end

        if errorCount > 0 then
            WindUI:Notify({ Title = "มีข้อผิดพลาด", Content = "สร้างปุ่มไม่สำเร็จ " .. errorCount .. " อัน", Duration = 5 })
        end
        WindUI:Notify({ Title = "แสดงผลแล้ว", Content = "โชว์ " .. shown .. " เพลง", Duration = 3 })
    end

    local function LoadSongs()
        local fn = (syn and syn.request) or request or http_request or fluxus_request
        if not fn then
            WindUI:Notify({ Title = "ผิดพลาด", Content = "Executor นี้ไม่มีฟังก์ชัน request", Duration = 5 })
            return
        end

        local ok, res = pcall(fn, {
            Url = API_BASE .. "/api/public/songs?banned=false&limit=1000",
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

return Core
