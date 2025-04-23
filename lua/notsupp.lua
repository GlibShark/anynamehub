local function createUnsupportedMessage()
    local scrgui = Instance.new("ScreenGui")
    scrgui.Parent = game:GetService("CoreGui")
    scrgui.IgnoreGuiInset = true

    local messageFrame = Instance.new("Frame")
    messageFrame.Name = "messageFrame"
    messageFrame.Parent = scrgui
    messageFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    messageFrame.BackgroundTransparency = 0.2
    messageFrame.Size = UDim2.new(0, 200, 0, 30) 
    messageFrame.Position = UDim2.new(0.5, -100, 0.9, 0) 
    messageFrame.ZIndex = 50

    local uc = Instance.new("UICorner")
    uc.CornerRadius = UDim.new(0, 8)
    uc.Parent = messageFrame

    local glassEffect = Instance.new("UIGradient")
    glassEffect.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(1, 0.3)
    })
    glassEffect.Rotation = 45
    glassEffect.Parent = messageFrame

    local warningText = Instance.new("TextLabel")
    warningText.Name = "warningText"
    warningText.Parent = messageFrame
    warningText.BackgroundTransparency = 1
    warningText.Size = UDim2.new(1, -10, 1, -10)
    warningText.Position = UDim2.new(0.5, 0, 0.5, 0)
    warningText.AnchorPoint = Vector2.new(0.5, 0.5)
    warningText.ZIndex = 52
    warningText.Font = Enum.Font.SourceSansBold
    warningText.Text = "Game not supported"
    warningText.TextColor3 = Color3.fromRGB(255, 255, 255)
    warningText.TextSize = 18
    warningText.TextScaled = false
    warningText.TextWrapped = false

    local glowEffect = Instance.new("ImageLabel")
    glowEffect.Name = "glowEffect"
    glowEffect.Parent = messageFrame
    glowEffect.BackgroundTransparency = 1
    glowEffect.Size = UDim2.new(1.1, 0, 1.1, 0)
    glowEffect.Position = UDim2.new(0.5, 0, 0.5, 0)
    glowEffect.AnchorPoint = Vector2.new(0.5, 0.5)
    glowEffect.ZIndex = 49
    glowEffect.Image = "rbxassetid://5028857084"
    glowEffect.ImageTransparency = 0.7
    glowEffect.ImageColor3 = Color3.fromRGB(100, 100, 255)

    messageFrame.Position = UDim2.new(0.5, -100, 1, 0)
    game:GetService("TweenService"):Create(messageFrame, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -100, 0.9, 0)}):Play()
    game:GetService("TweenService"):Create(warningText, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {TextTransparency = 0}):Play()

    wait(4)
    game:GetService("TweenService"):Create(messageFrame, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -100, 1, 0)}):Play()
    game:GetService("Debris"):AddItem(messageFrame, 0.5)
end

createUnsupportedMessage()