-- Services
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Camera = game.Workspace.CurrentCamera
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Variables
local isLocked = false  -- Kamera kilit durumu
local lockedTarget = nil  -- Kilitlenen oyuncu
local isCheckBoxEnabled = false  -- Checkbox işaretli mi?
local guiVisible = true -- GUI Açık mı?

-- GUI Oluşturma
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 150)
Frame.Position = UDim2.new(0.1, 0, 0.1, 0)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(128, 0, 128)
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 100, 0, 30)
Title.Position = UDim2.new(0, 10, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "Camlock"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 20
Title.Font = Enum.Font.SourceSansBold
Title.Parent = Frame

local CheckBox = Instance.new("TextButton")
CheckBox.Size = UDim2.new(0, 30, 0, 30)
CheckBox.Position = UDim2.new(0, 120, 0, 10)
CheckBox.BackgroundColor3 = Color3.fromRGB(80, 0, 80)
CheckBox.TextColor3 = Color3.fromRGB(255, 255, 255)
CheckBox.Text = "☐"
CheckBox.TextSize = 24
CheckBox.Font = Enum.Font.SourceSansBold
CheckBox.Parent = Frame

local Credit = Instance.new("TextLabel")
Credit.Size = UDim2.new(0, 100, 0, 20)
Credit.Position = UDim2.new(0, 10, 0, 120)
Credit.BackgroundTransparency = 1
Credit.Text = "acne"
Credit.TextColor3 = Color3.fromRGB(100, 100, 100)
Credit.TextSize = 14
Credit.Font = Enum.Font.SourceSansItalic
Credit.Parent = Frame

-- En Yakın Oyuncuyu Bulan Fonksiyon
local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mouse = LocalPlayer:GetMouse()
    local mousePosition = Vector2.new(mouse.X, mouse.Y)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character
            local screenPoint, onScreen = Camera:WorldToViewportPoint(character.HumanoidRootPart.Position)

            if onScreen then
                local screenPosition = Vector2.new(screenPoint.X, screenPoint.Y)
                local distance = (mousePosition - screenPosition).Magnitude
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

-- Glow Efekti Ekleme Fonksiyonu
local function ApplyGlowEffect(character, enabled)
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            local highlight = part:FindFirstChild("Highlight")
            if enabled then
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "Highlight"
                    highlight.FillColor = Color3.fromRGB(128, 0, 128) -- Mor iç kısım
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- Beyaz dış hat
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.Parent = part
                end
            else
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end

-- Kamera Güncelleme (Ölüm Kontrolü Eklenmiş)
local smoothness = 0.2 -- Kamera hareketinin yumuşaklığı
local shakeIntensity = 0.02 -- Titreşim şiddeti

RunService.RenderStepped:Connect(function()
    if isLocked and lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("HumanoidRootPart") then
        local humanoid = lockedTarget.Character:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then -- Karakterin canı 0'dan büyükse devam et
            local targetPosition = lockedTarget.Character.HumanoidRootPart.Position
            local currentCFrame = Camera.CFrame
            local desiredCFrame = CFrame.new(currentCFrame.Position, targetPosition)
            
            -- Rastgele titreşim ekleme
            local shakeOffset = Vector3.new(
                (math.random() - 0.5) * shakeIntensity,
                (math.random() - 0.5) * shakeIntensity,
                (math.random() - 0.5) * shakeIntensity
            )
            
            -- Yumuşak geçiş
            Camera.CFrame = currentCFrame:Lerp(desiredCFrame, smoothness) + shakeOffset
        else
            -- Karakter öldüyse camlock'u devre dışı bırak
            isLocked = false
            lockedTarget = nil
            ApplyGlowEffect(lockedTarget.Character, false)
        end
    end
end)

-- Kamera Kilitleme / Açma İşlevi
local function ToggleCameraLock()
    if not isCheckBoxEnabled then return end -- Eğer tik işaretlenmemişse çalıştırma
    
    if isLocked then
        isLocked = false
        if lockedTarget and lockedTarget.Character then
            ApplyGlowEffect(lockedTarget.Character, false)
        end
        lockedTarget = nil
    else
        local targetPlayer = GetClosestPlayer()
        if targetPlayer then
            isLocked = true
            lockedTarget = targetPlayer
            ApplyGlowEffect(targetPlayer.Character, true)
        end
    end
end

-- CheckBox Butonuna İşlev Ekle
CheckBox.MouseButton1Click:Connect(function()
    isCheckBoxEnabled = not isCheckBoxEnabled
    CheckBox.Text = isCheckBoxEnabled and "☑" or "☐"
    if not isCheckBoxEnabled then
        isLocked = false  -- Eğer tik kaldırıldıysa, camlock sıfırlansın
        if lockedTarget and lockedTarget.Character then
            ApplyGlowEffect(lockedTarget.Character, false)
        end
        lockedTarget = nil
    end
end)

-- "G" Tuşuna Basılınca Kamera Kilitleme (Eğer tik işaretliyse çalışır)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.G and isCheckBoxEnabled then
        ToggleCameraLock()
    end
    if input.KeyCode == Enum.KeyCode.Home then
        guiVisible = not guiVisible
        Frame.Visible = guiVisible
    end
end)