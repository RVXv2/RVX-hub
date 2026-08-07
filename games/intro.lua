local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Intro = {}

local MainColor = Color3.fromRGB(160, 80, 255)
local SparkColor = Color3.fromRGB(220, 180, 255)
local UI_SIZE = UDim2.new(0, 480, 0, 280)

local function playSound(id, vol)
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://" .. id
    s.Volume = vol or 0.5
    s.Parent = game:GetService("SoundService")
    s:Play()
    game:GetService("Debris"):AddItem(s, 2)
end

local ClickSound = 6895079853
local HoverSound = 6543311100

local function createSpark(parent)
    local spark = Instance.new("Frame")
    spark.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
    spark.Position = UDim2.new(math.random(), 0, 1, 0)
    spark.BackgroundColor3 = SparkColor
    spark.BorderSizePixel = 0
    spark.ZIndex = 7
    spark.Parent = parent
    Instance.new("UICorner", spark).CornerRadius = UDim.new(1, 0)

    local targetPos = UDim2.new(spark.Position.X.Scale + (math.random(-15, 15) / 100), 0, -0.2, 0)
    local dur = math.random(15, 30) / 10

    TweenService:Create(spark, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = targetPos,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, 0),
    }):Play()

    game:GetService("Debris"):AddItem(spark, dur)
end

function Intro.Show(onNext)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RVXIntro"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local loadingFrame = Instance.new("Frame")
    loadingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    loadingFrame.Size = UDim2.new(0, 160, 0, 160)
    loadingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    loadingFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 35)
    loadingFrame.BorderSizePixel = 0
    loadingFrame.ZIndex = 10
    loadingFrame.ClipsDescendants = true
    loadingFrame.Parent = screenGui
    Instance.new("UICorner", loadingFrame).CornerRadius = UDim.new(0, 25)

    local loadGrad = Instance.new("UIGradient", loadingFrame)
    loadGrad.Color = ColorSequence.new(Color3.fromRGB(80, 20, 140), Color3.fromRGB(160, 80, 240))
    loadGrad.Rotation = 45

    local spinner = Instance.new("ImageLabel")
    spinner.Size = UDim2.new(0, 50, 0, 50)
    spinner.Position = UDim2.new(0.5, -25, 0.5, -35)
    spinner.BackgroundTransparency = 1
    spinner.Image = "rbxassetid://4965945816"
    spinner.ImageColor3 = SparkColor
    spinner.ZIndex = 13
    spinner.Parent = loadingFrame

    local loadingText = Instance.new("TextLabel")
    loadingText.Size = UDim2.new(1, 0, 0, 20)
    loadingText.Position = UDim2.new(0, 0, 0.5, 25)
    loadingText.BackgroundTransparency = 1
    loadingText.Text = "Loading..."
    loadingText.TextColor3 = Color3.fromRGB(220, 200, 255)
    loadingText.Font = Enum.Font.GothamBold
    loadingText.TextSize = 12
    loadingText.ZIndex = 13
    loadingText.Parent = loadingFrame

    local mainFrame = Instance.new("Frame")
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Size = UI_SIZE
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.Visible = false
    mainFrame.ZIndex = 5
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 20)

    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Thickness = 2
    mainStroke.Color = MainColor
    mainStroke.Transparency = 0.4

    local bgGrad = Instance.new("UIGradient", mainFrame)
    bgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 10, 45)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(45, 15, 85)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 35, 170)),
    })
    bgGrad.Rotation = 45

    local avatarFrame = Instance.new("Frame")
    avatarFrame.Size = UDim2.new(0, 90, 0, 90)
    avatarFrame.Position = UDim2.new(0, 25, 0, 55)
    avatarFrame.BackgroundColor3 = Color3.fromRGB(40, 20, 80)
    avatarFrame.BackgroundTransparency = 0.4
    avatarFrame.ZIndex = 8
    avatarFrame.Parent = mainFrame
    Instance.new("UICorner", avatarFrame).CornerRadius = UDim.new(1, 0)

    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size = UDim2.new(1, -6, 1, -6)
    avatarImg.Position = UDim2.new(0, 3, 0, 3)
    avatarImg.BackgroundTransparency = 1
    avatarImg.ZIndex = 9
    avatarImg.Parent = avatarFrame
    Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 300, 0, 30)
    titleLabel.Position = UDim2.new(0, 130, 0, 55)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = player.DisplayName
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 24
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 9
    titleLabel.Parent = mainFrame

    local subLabel = Instance.new("TextLabel")
    subLabel.Size = UDim2.new(0, 300, 0, 20)
    subLabel.Position = UDim2.new(0, 130, 0, 85)
    subLabel.BackgroundTransparency = 1
    subLabel.Text = "Welcome to RVX Hub"
    subLabel.TextColor3 = Color3.fromRGB(180, 150, 255)
    subLabel.Font = Enum.Font.Gotham
    subLabel.TextSize = 14
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.ZIndex = 9
    subLabel.Parent = mainFrame

    local msg3 = Instance.new("TextLabel")
    msg3.Size = UDim2.new(0, 320, 0, 20)
    msg3.Position = UDim2.new(0, 130, 0, 130)
    msg3.BackgroundTransparency = 1
    msg3.Text = "ทุกสคริปต์มีสิทธิ์โดนแบน โปรดใช้อย่างระมัดระวัง"
    msg3.TextColor3 = Color3.fromRGB(180, 150, 255)
    msg3.Font = Enum.Font.Gotham
    msg3.TextSize = 14
    msg3.TextXAlignment = Enum.TextXAlignment.Left
    msg3.ZIndex = 9
    msg3.Parent = mainFrame

    local function makeBtn(text, pos, color, width)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, width or 100, 0, 35)
        btn.Position = pos
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.ZIndex = 10
        btn.BorderSizePixel = 0
        btn.Parent = mainFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        btn.MouseEnter:Connect(function()
            playSound(HoverSound, 0.3)
            TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = color:Lerp(Color3.new(1, 1, 1), 0.2) }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = color }):Play()
        end)
        btn.MouseButton1Down:Connect(function()
            playSound(ClickSound, 0.6)
        end)

        return btn
    end

    local closeBtn = makeBtn("ปิด", UDim2.new(1, -260, 1, -55), Color3.fromRGB(60, 20, 100), 80)
    local nextBtn = makeBtn("เข้าใช้งาน →", UDim2.new(1, -170, 1, -55), MainColor, 150)

    local heartbeatConn
    heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        bgGrad.Rotation = (bgGrad.Rotation + dt * 15) % 360
        spinner.Rotation = (spinner.Rotation + dt * 200) % 360
        if math.random(1, 8) == 1 then
            createSpark(mainFrame)
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        heartbeatConn:Disconnect()
        screenGui:Destroy()
    end)

    nextBtn.MouseButton1Click:Connect(function()
        heartbeatConn:Disconnect()
        screenGui:Destroy()
        if onNext then
            onNext()
        end
    end)

    pcall(function()
        avatarImg.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
    end)

    task.wait(1)
    TweenService:Create(loadingText, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
    TweenService:Create(spinner, TweenInfo.new(0.2), { ImageTransparency = 1 }):Play()
    task.wait(0.2)
    loadingFrame.Visible = false

    mainFrame.Visible = true
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UI_SIZE }):Play()
end

return Intro
