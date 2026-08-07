local Core = {}

local API_BASE = "http://de3.bot-hosting.net:20209"  -- << เปลี่ยนเป็นโดเมนจริงของ API คุณ
local API_KEY  = "sgid_08168ec5efd4de42468154fadb9e9a9f38ebff76"        -- << ใส่ key จริงตรงนี้ (อย่าแชร์ไฟล์นี้สาธารณะถ้าใส่ key ตรงๆ)

local function DoRequest(opts)
    local fn = (syn and syn.request) or request or http_request or fluxus_request
    if not fn then
        warn("Executor นี้ไม่รองรับ request แบบใส่ header")
        return nil
    end
    local ok, res = pcall(fn, opts)
    if ok and res and res.Body then
        return res.Body
    end
    return nil
end

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
        local body = DoRequest({
            Url = API_BASE .. "/api/public/songs?banned=false&limit=100",
            Method = "GET",
            Headers = { ["X-API-Key"] = API_KEY },
        })

        if not body then
            WindUI:Notify({ Title = "ผิดพลาด", Content = "โหลดรายชื่อเพลงไม่สำเร็จ", Duration = 3 })
            return
        end

        local ok, decoded = pcall(function()
            return game:GetService("HttpService"):JSONDecode(body)
        end)

        if ok and decoded then
            AllSongs = decoded
            RenderSongs("")
        end
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
