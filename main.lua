local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ====== ระบบโปรไฟล์ ======
local ProfileFile = "MyHub_Profile.json"
local DefaultNickname = "Player"

local function LoadProfile()
    if isfile and isfile(ProfileFile) then
        local ok, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile(ProfileFile))
        end)
        if ok and data and data.Nickname then
            return data.Nickname
        end
    end
    return DefaultNickname
end

local function SaveProfile(nickname)
    if writefile then
        local data = { Nickname = nickname }
        writefile(ProfileFile, game:GetService("HttpService"):JSONEncode(data))
    end
end

local CurrentNickname = LoadProfile()
-- =========================

local Window = WindUI:CreateWindow({
    Title = CurrentNickname .. "'s Hub",
    Icon = "rocket",
    Theme = "Emerald",
})

local MainTab = Window:Tab({ Title = "Main", Icon = "home" })
local ProfileTab = Window:Tab({ Title = "Profile", Icon = "user" })

MainTab:Section({ Title = "Interactive Elements", Desc = "Demonstration of new UI components" })

MainTab:Toggle({
    Title = "Autism",
    Value = true,
    Callback = function(state)
        print("Autism:", state)
    end,
})

MainTab:Slider({
    Title = "Brightness Control",
    Value = { Min = 0, Max = 100, Default = 60 },
    Callback = function(value)
        print("Brightness:", value)
    end,
})

MainTab:Slider({
    Title = "Volume Settings",
    Value = { Min = 0, Max = 100, Default = 70 },
    Callback = function(value)
        print("Volume:", value)
    end,
})

ProfileTab:Section({ Title = "โปรไฟล์ของคุณ", Desc = "ตั้งชื่อเล่นที่จะโชว์ใน Hub" })

ProfileTab:Input({
    Title = "ชื่อเล่น",
    Value = CurrentNickname,
    Placeholder = "พิมพ์ชื่อของคุณ",
    Callback = function(text)
        if text ~= "" then
            CurrentNickname = text
            SaveProfile(CurrentNickname)
            WindUI:Notify({
                Title = "บันทึกแล้ว",
                Content = "เปลี่ยนชื่อเป็น " .. text,
                Duration = 3,
            })
        end
    end,
})
