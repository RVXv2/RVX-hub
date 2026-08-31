local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Intro = {}

local LOGO_ID = "rbxassetid://125616092701976"

-- ===== หน้า Splash โลโก้ (ขึ้นก่อนทุกอย่าง) =====
local function ShowSplash()
    local camera = workspace.CurrentCamera

    local splashGui = Instance.new("ScreenGui")
    splashGui.Name = "RVXSplash"
    splashGui.ResetOnSpawn = false
    splashGui.DisplayOrder = 100
    splashGui.IgnoreGuiInset = true
    splashGui.Parent = playerGui

    -- พื้นหลังโปร่งใสบางๆ เต็มจอเสมอไม่ว่าอุปกรณ์ไหน (ของจริงจะเบลอฉากหลังผ่าน Lighting)
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.Position = UDim2.new(0, 0, 0, 0)
    bg.BackgroundColor3 = Color3.fromRGB(5, 2, 10)
    bg.BackgroundTransparency = 0.55
    bg.BorderSizePixel = 0
    bg.ZIndex = 1
    bg.Parent = splashGui

    -- เอฟเฟกต์เบลอฉากหลังเกมจริง (แทนพื้นดำทึบ)
    local blur = Instance.new("BlurEffect")
    blur.Name = "RVXSplashBlur"
    blur.Size = 0
    blur.Parent = Lighting

    -- คำนวณขนาดโลโก้ตามขนาดจอจริง (Scale ตามด้านที่สั้นกว่า กันโลโก้เบี้ยว/ไม่พอดีจอ)
    local function getLogoSize()
        local vp = camera.ViewportSize
        local base = math.min(vp.X, vp.Y)
        local size = base * 0.35
        return UDim2.new(0, size, 0, size)
    end

    local logoHolder = Instance.new("Frame")
    logoHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    logoHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
    logoHolder.Size = UDim2.new(0, 0, 0, 0)
    logoHolder.BackgroundTransparency = 1
    logoHolder.ZIndex = 2
    logoHolder.Parent = splashGui

    local logo = Instance.new("ImageLabel")
    logo.Size = UDim2.new(1, 0, 1, 0)
    logo.BackgroundTransparency = 1
    logo.Image = LOGO_ID
    logo.ImageTransparency = 0
    logo.ScaleType = Enum.ScaleType.Fit
    logo.ZIndex = 2
    logo.Parent = logoHolder

    -- ปรับขนาดใหม่อัตโนมัติถ้าหมุนจอ/เปลี่ยนขนาดจอระหว่างที่ยังโชว์อยู่
    local resizeConn
    resizeConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        logoHolder.Size = getLogoSize()
    end)

    -- ขยายเข้ามาแบบลื่นๆ ตามขนาดจอจริง
    local targetSize = getLogoSize()
    local growTween = TweenService:Create(logoHolder, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = targetSize,
    })
    local blurTween = TweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = 24,
    })

    growTween:Play()
    blurTween:Play()
    growTween.Completed:Wait()

    -- ค้างไว้ให้เห็นชัดๆ
    task.wait(1.0)

    -- จางหายไปพร้อมกับพื้นหลังและเบลอ
    local fadeLogo = TweenService:Create(logo, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        ImageTransparency = 1,
    })
    local fadeHolder = TweenService:Create(logoHolder, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(targetSize.X.Scale, targetSize.X.Offset * 1.2, targetSize.Y.Scale, targetSize.Y.Offset * 1.2),
    })
    local fadeBg = TweenService:Create(bg, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1,
    })
    local fadeBlur = TweenService:Create(blur, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = 0,
    })

    fadeLogo:Play()
    fadeHolder:Play()
    fadeBg:Play()
    fadeBlur:Play()
    fadeLogo.Completed:Wait()

    resizeConn:Disconnect()
    blur:Destroy()
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
