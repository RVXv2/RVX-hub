local Core = {}

local API_BASE = "http://de3.bot-hosting.net:20209"  -- << เปลี่ยนเป็นโดเมนจริงของคุณ (ไม่มี / ท้าย)
local API_KEY  = "sgid_08168ec5efd4de42468154fadb9e9a9f38ebff76"                  -- << ใส่ key จริงของคุณ

function Core.AddSongsTab(Window, WindUI)
    local SongsTab = Window:Tab({ Title = "เพลง", Icon = "music" })

    SongsTab:Section({ Title = "ค้นหาเพลง", Desc = "ดึงข้อมูลจาก API สาธารณะ" })

    local AllSongs = {}
    local SongButtons = {}
    local ListSection = SongsTab:Section({ Title = "รายการเพลง" })

    local function RenderSongs(filterText)
        for _, btn in ipairs(SongButtons) do
            if btn.Destroy then btn:Destroy() end
        end
        table.clear(SongButtons)

        for _, song in ipairs(AllSongs) do
            local matches = filterText == "" or string.find(string.lower(song.name), string.lower(filterText), 1, true)
            if matches then
                local b = ListSection:Button({
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
                table.insert(SongButtons, b)
            end
        end
    end

    local function LoadSongs()
        WindUI:Notify({ Title = "กำลังโหลด...", Content = "เชื่อมต่อ API", Duration = 2 })

        local fn = (syn and syn.request) or request or http_request or fluxus_request
        if not fn then
            WindUI:Notify({ Title = "ผิดพลาด", Content = "Executor นี้ไม่มีฟังก์ชัน request", Duration = 5 })
            return
        end

        local ok, res = pcall(fn, {
            Url = API_BASE .. "/api/public/songs?banned=false&limit=100",
            Method = "GET",
            Headers = { ["X-API-Key"] = API_KEY },
        })

        if not ok then
            WindUI:Notify({ Title = "Request ผิดพลาด", Content = tostring(res), Duration = 6 })
            return
        end

        if not res or not res.Body then
            WindUI:Notify({ Title = "ไม่มีข้อมูลตอบกลับ", Content = "res เป็น nil หรือไม่มี Body", Duration = 5 })
            return
        end

        WindUI:Notify({ Title = "ได้ข้อมูลแล้ว", Content = "สถานะ: " .. tostring(res.StatusCode), Duration = 4 })

        local decOk, decoded = pcall(function()
            return game:GetService("HttpService"):JSONDecode(res.Body)
        end)

        if not decOk then
            WindUI:Notify({ Title = "แปลง JSON ไม่ได้", Content = tostring(res.Body):sub(1, 100), Duration = 6 })
            return
        end

        AllSongs = decoded
        WindUI:Notify({ Title = "สำเร็จ", Content = "โหลดเพลงได้ " .. #AllSongs .. " เพลง", Duration = 3 })
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

    LoadSongs()
end

return Core
