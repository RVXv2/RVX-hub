local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Intro = {}

local LOGO_ID = "rbxassetid://125616092701976"

-- ===== หน้า Splash โลโก้ (ขึ้นก่อนทุกอย่าง) =====
local function ShowSplash()
    local splashGui = Instance.new("ScreenGui")
    splashGui.Name = "RVXSplash"
    splashGui.ResetOnSpawn = false
    splashGui.DisplayOrder = 100
    splashGui.Parent = playerGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(5, 2, 10)
    bg.BackgroundTransparency = 0
    bg.BorderSizePixel = 0
    bg.ZIndex = 1
    bg.Parent = splashGui

    local logo = Instance.new("ImageLabel")
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.Position = UDim2.new(0.5, 0, 0.5, 0)
    logo.Size = UDim2.new(0, 0, 0, 0)
    logo.BackgroundTransparency = 1
    logo.Image = LOGO_ID
    logo.ImageTransparency = 0
    logo.ZIndex = 2
    logo.Parent = splashGui

    -- ขยายเข้ามาแบบลื่นๆ
    local growTween = TweenService:Create(logo, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 180, 0, 180),
    })
    growTween:Play()
    growTween.Completed:Wait()

    -- ค้างไว้ให้เห็นชัดๆ
    task.wait(1.0)

    -- จางหายไปพร้อมกับพื้นหลัง
    local fadeLogo = TweenService:Create(logo, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        ImageTransparency = 1,
        Size = UDim2.new(0, 220, 0, 220),
    })
    local fadeBg = TweenService:Create(bg, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1,
    })

    fadeLogo:Play()
    fadeBg:Play()
    fadeLogo.Completed:Wait()

    splashGui:Destroy()
end

function Intro.Show(onNext)
    -- โชว์โลโก้ แล้วเข้าสคริปต์ทันที ไม่ต้องกดปุ่มใดๆ
    ShowSplash()

    if onNext then
        onNext()
    end
end

return Intro
