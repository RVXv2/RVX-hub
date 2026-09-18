local ScriptsModule = {}

-- ==============================================================
-- รายชื่อสคริปต์ (แก้/เพิ่ม/ลบได้ตรงนี้เท่านั้น)
-- Name = ชื่อปุ่มที่โชว์
-- Desc = คำอธิบายสั้นๆ ใต้ชื่อปุ่ม (จะไม่ใส่ก็ได้ ให้เป็น nil หรือ "")
-- Url  = ลิงก์ raw ของสคริปต์ที่จะโหลดด้วย HttpGet แล้วรันด้วย loadstring
--
-- เพิ่มสคริปต์ใหม่: copy 1 บล็อกด้านล่าง แล้วแก้ Name / Desc / Url
-- ==============================================================
local SCRIPT_LIST = {
    {
        Name = "ตัวอย่างสคริปต์ 1",
        Desc = "คำอธิบายสั้นๆ ของสคริปต์นี้",
        Url = "https://raw.githubusercontent.com/USERNAME/REPO/main/script1.lua",
    },
    {
        Name = "ตัวอย่างสคริปต์ 2",
        Desc = "คำอธิบายสั้นๆ ของสคริปต์นี้",
        Url = "https://raw.githubusercontent.com/USERNAME/REPO/main/script2.lua",
    },
    -- {
    --     Name = "ชื่อสคริปต์ใหม่",
    --     Desc = "คำอธิบาย",
    --     Url  = "https://raw.githubusercontent.com/USERNAME/REPO/main/scriptX.lua",
    -- },
}

-- T = ตารางข้อความภาษาปัจจุบัน (ส่งมาจาก Core เพื่อให้ label ใช้ภาษาเดียวกันทั้ง Hub)
-- ใส่ default ไว้เผื่อ T ไม่มีคีย์ที่ต้องใช้ (กันปุ่มว่าง/error)
function ScriptsModule.Init(Window, WindUI, T)
    T = T or {}

    local ScriptsTab = Window:Tab({
        Title = T.scripts or "Scripts",
        Icon = "terminal",
    })

    ScriptsTab:Section({
        Title = T.scriptsSection or "สคริปต์ภายนอก",
        Desc = T.scriptsSectionDesc or "กดปุ่มเพื่อรันสคริปต์แต่ละตัว",
    })

    if #SCRIPT_LIST == 0 then
        ScriptsTab:Paragraph({
            Title = T.scriptsEmptyTitle or "ยังไม่มีสคริปต์",
            Desc = T.scriptsEmptyDesc or "เพิ่มรายการได้ในไฟล์ RVXHub_Scripts.lua",
        })
        return
    end

    for _, item in ipairs(SCRIPT_LIST) do
        ScriptsTab:Button({
            Title = item.Name or "Unnamed Script",
            Desc = item.Desc,
            Icon = "play",
            Callback = function()
                local ok, err = pcall(function()
                    local chunk = game:HttpGet(item.Url)
                    local fn, loadErr = loadstring(chunk)
                    if not fn then
                        error(loadErr or "loadstring failed")
                    end
                    fn()
                end)

                if ok then
                    WindUI:Notify({
                        Title = item.Name,
                        Content = T.scriptRan or "รันสคริปต์แล้ว",
                        Duration = 3,
                    })
                else
                    warn("[RVX Hub] Script '" .. tostring(item.Name) .. "' error: " .. tostring(err))
                    WindUI:Notify({
                        Title = item.Name,
                        Content = (T.scriptError or "รันไม่สำเร็จ: ") .. tostring(err),
                        Duration = 5,
                    })
                end
            end,
        })
    end
end

return ScriptsModule
