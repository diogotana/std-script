-- STD_Delta.lua — Macro Studio + TP Cravado
-- game: Sorcerer Tower Defense | 17720162456

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")

local lp = Players.LocalPlayer

local G = {
    -- Automação
    AutoCasino = false, AutoReplay = false, AutoLeave = false,
    AutoSkipWave = false, SkipAtWave = 1, AutoSellAtWave = false, SellAtWave = 50,
    AutoAbility = false, AbilityAtWave = 1,
    HideJump = false, FPSBoost = false, AntiAFK = false,
    
    -- Teleportes e Modos
    PosRaid = CFrame.new(24.93, 16.71, 3115.60),
    PosHell = CFrame.new(-442.46, 16.72, 3280.19),
    PosNormal = CFrame.new(-404.70, 16.76, 3239.46),
    PosEasy = CFrame.new(-383.98, 16.80, 3216.45),
    PosCassino = CFrame.new(-362.99, 16.59, 2854.20),
    
    AutoRaid = false, AutoHell = false, AutoNormal = false, AutoEasy = false, AutoCassino = false,
    
    -- Macros
    IsRecording = false, RecordStartTime = 0,
    Macros = {}, SelectedMacro = "", IsPlaying = false
}

local MACRO_FILE = "STD_Macros.json"
local function saveMacros() local s, e = pcall(function() return HttpService:JSONEncode(G.Macros) end) if s then pcall(function() writefile(MACRO_FILE, e) end) end end
local function loadMacros() pcall(function() if isfile(MACRO_FILE) then local d = HttpService:JSONDecode(readfile(MACRO_FILE)) if type(d) == "table" then G.Macros = d end end end) end
loadMacros()

-- ══════════════════════════════════════════════
--  SISTEMA DE TELEPORTE (CORRIGIDO)
-- ══════════════════════════════════════════════
local function tpTo(cframe)
    if not cframe then return end
    local char = lp.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char:PivotTo(cframe)
        char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if G.AutoRaid and G.PosRaid and (hrp.Position - G.PosRaid.Position).Magnitude > 50 then tpTo(G.PosRaid) end
            if G.AutoHell and G.PosHell and (hrp.Position - G.PosHell.Position).Magnitude > 50 then tpTo(G.PosHell) end
            if G.AutoNormal and G.PosNormal and (hrp.Position - G.PosNormal.Position).Magnitude > 50 then tpTo(G.PosNormal) end
            if G.AutoEasy and G.PosEasy and (hrp.Position - G.PosEasy.Position).Magnitude > 50 then tpTo(G.PosEasy) end
            if G.AutoCassino and G.PosCassino and (hrp.Position - G.PosCassino.Position).Magnitude > 50 then tpTo(G.PosCassino) end
        end
    end
end)

-- ══════════════════════════════════════════════
--  SISTEMA DE LOG
-- ══════════════════════════════════════════════
local LogText = nil
local function AddLog(msg)
    local t = os.date("%H:%M:%S")
    local text = "["..t.."] "..msg.."\n"
    if LogText then 
        LogText.Text = LogText.Text .. text 
        local parent = LogText.Parent
        if parent then task.wait() parent.CanvasPosition = Vector2.new(0, parent.AbsoluteCanvasSize.Y) end
    end
    print(msg)
end

-- ══════════════════════════════════════════════
--  PREMIUM UI
-- ══════════════════════════════════════════════
local playerGui = lp:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("STD_Studio") then playerGui:FindFirstChild("STD_Studio"):Destroy() end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name, ScreenGui.ResetOnSpawn, ScreenGui.IgnoreGuiInset, ScreenGui.Parent = "STD_Studio", false, true, playerGui

local Theme = {
    BG = Color3.fromRGB(20, 18, 26), Surface = Color3.fromRGB(28, 26, 36),
    Accent = Color3.fromRGB(120, 80, 200), AccentL = Color3.fromRGB(160, 120, 255),
    Text = Color3.fromRGB(240, 240, 245), Dim = Color3.fromRGB(140, 140, 155),
    Green = Color3.fromRGB(50, 200, 100), Red = Color3.fromRGB(220, 60, 60), Border = Color3.fromRGB(50, 48, 60)
}

local W, H = 700, 480
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, W, 0, H) Main.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
Main.BackgroundColor3 = Theme.BG Main.ClipsDescendants = true Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", Main) stroke.Color = Theme.Border stroke.Thickness = 1.5

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 50) TopBar.BackgroundColor3 = Theme.BG TopBar.Parent = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)
local Title = Instance.new("TextLabel")
Title.Text, Title.Size, Title.Position = "SORCERER TOWER DEFENSE", UDim2.new(1, -100, 1, 0), UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency, Title.TextColor3, Title.Font, Title.TextSize = 1, Theme.Text, Enum.Font.GothamBold, 14
Title.TextXAlignment, Title.Parent = Enum.TextXAlignment.Left, TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text, CloseBtn.Size, CloseBtn.Position = "✕", UDim2.new(0, 34, 0, 34), UDim2.new(1, -44, 0.5, -17)
CloseBtn.BackgroundColor3, CloseBtn.TextColor3 = Theme.Red, Theme.Text
CloseBtn.Font, CloseBtn.TextSize, CloseBtn.BorderSizePixel = Enum.Font.GothamBold, 16, 0
CloseBtn.Parent = TopBar Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true dragStart = input.Position startPos = Main.Position end end)
UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = input.Position - dragStart Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

local TabContainer = Instance.new("Frame")
TabContainer.Size, TabContainer.Position = UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 50)
TabContainer.BackgroundColor3, TabContainer.Parent = Theme.BG, Main
local TabList = Instance.new("Frame")
TabList.Size, TabList.Position = UDim2.new(1, -16, 1, -8), UDim2.new(0, 8, 0, 4)
TabList.BackgroundTransparency, TabList.Parent = 1, TabContainer
local TabLayout = Instance.new("UIListLayout", TabList)
TabLayout.FillDirection, TabLayout.Padding, TabLayout.SortOrder = Enum.FillDirection.Horizontal, UDim.new(0, 6), Enum.SortOrder.LayoutOrder
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
local Pages = Instance.new("Frame")
Pages.Size, Pages.Position = UDim2.new(1, 0, 1, -90), UDim2.new(0, 0, 0, 90)
Pages.BackgroundTransparency, Pages.Parent = 1, Main

local function switchTab(activeBtn, activePage)
    for _, v in ipairs(TabList:GetChildren()) do if v:IsA("TextButton") then TweenService:Create(v, TweenInfo.new(0.15), {BackgroundColor3 = Theme.BG, TextColor3 = Theme.Dim}):Play() end end
    for _, v in ipairs(Pages:GetChildren()) do if v:IsA("Frame") then v.Visible = false end end
    TweenService:Create(activeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.Text}):Play()
    activePage.Visible = true
end

local function createTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Size, btn.BackgroundColor3, btn.Text, btn.TextColor3 = UDim2.new(0, 100, 1, 0), Theme.BG, name, Theme.Dim
    btn.Font, btn.TextSize, btn.LayoutOrder, btn.Parent = Enum.Font.GothamBold, 12, order, TabList
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local page = Instance.new("Frame")
    page.Size, page.Position, page.BackgroundTransparency = UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 1
    page.Visible, page.Parent = false, Pages
    btn.MouseButton1Click:Connect(function() switchTab(btn, page) end) return btn, page
end

local function createCheckbox(lbl, order, parent, getF, setF)
    local frame = Instance.new("Frame")
    frame.Size, frame.BackgroundColor3, frame.BorderSizePixel = UDim2.new(1, 0, 0, 40), Theme.Surface, 0
    frame.LayoutOrder, frame.Parent = order, parent
    local str = Instance.new("UIStroke", frame) str.Color = Theme.Border
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local box = Instance.new("Frame")
    box.Size, box.Position = UDim2.new(0, 20, 0, 20), UDim2.new(0, 12, 0.5, -10)
    box.BackgroundColor3, box.Parent = Theme.BG, frame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    local bStroke = Instance.new("UIStroke", box) bStroke.Color = Theme.Accent
    local fill = Instance.new("Frame")
    fill.Size, fill.Position = UDim2.new(1, -4, 1, -4), UDim2.new(0, 2, 0, 2)
    fill.BackgroundColor3, fill.Visible = Theme.Accent, getF()
    fill.Parent = box Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)
    local txt = Instance.new("TextLabel")
    txt.Size, txt.Position, txt.BackgroundTransparency = UDim2.new(1, -40, 1, 0), UDim2.new(0, 42, 0, 0), 1
    txt.Text, txt.TextColor3, txt.Font, txt.TextSize = lbl, Theme.Text, Enum.Font.GothamSemibold, 12
    txt.TextXAlignment, txt.Parent = Enum.TextXAlignment.Left, frame
    local btn = Instance.new("TextButton")
    btn.Size, btn.BackgroundTransparency, btn.Text, btn.ZIndex, btn.Parent = UDim2.new(1,0,1,0), 1, "", 3, frame
    btn.MouseButton1Click:Connect(function() local state = not getF() setF(state) fill.Visible = state AddLog(lbl .. " -> " .. tostring(state)) end)
end

local function createInputBox(lbl, order, parent, getF, setF)
    local frame = Instance.new("Frame")
    frame.Size, frame.BackgroundColor3, frame.BorderSizePixel = UDim2.new(1, 0, 0, 60), Theme.Surface, 0
    frame.LayoutOrder, frame.Parent = order, parent
    local str = Instance.new("UIStroke", frame) str.Color = Theme.Border
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local txt = Instance.new("TextLabel")
    txt.Size, txt.Position, txt.BackgroundTransparency = UDim2.new(1, -20, 0, 20), UDim2.new(0, 12, 0, 8), 1
    txt.Text, txt.TextColor3, txt.Font, txt.TextSize = lbl, Theme.Dim, Enum.Font.Gotham, 11
    txt.TextXAlignment, txt.Parent = Enum.TextXAlignment.Left, frame
    local input = Instance.new("TextBox")
    input.Size, input.Position, input.BackgroundColor3 = UDim2.new(1, -24, 0, 24), UDim2.new(0, 12, 0, 28), Theme.BG
    input.Text, input.TextColor3, input.Font, input.TextSize = tostring(getF()), Theme.Text, Enum.Font.GothamBold, 13
    input.Parent = frame Instance.new("UICorner", input).CornerRadius = UDim.new(0, 4)
    input.FocusLost:Connect(function() local num = tonumber(input.Text) if num then setF(num) AddLog(lbl .. " alterado para: " .. tostring(num)) else input.Text = tostring(getF()) end end)
end

local function createButton(txt, order, parent, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size, btn.BackgroundColor3 = UDim2.new(1, 0, 0, 36), color
    btn.Text, btn.TextColor3, btn.Font, btn.TextSize = txt, Theme.Text, Enum.Font.GothamBold, 12
    btn.LayoutOrder, btn.Parent = order, parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback) return btn
end

local function createSection(text, order, parent)
    local lbl = Instance.new("TextLabel")
    lbl.Size, lbl.BackgroundTransparency = UDim2.new(1, 0, 0, 24), 1
    lbl.Text, lbl.TextColor3, lbl.Font, lbl.TextSize = string.upper(text), Theme.Text, Enum.Font.GothamBold, 11
    lbl.TextXAlignment, lbl.LayoutOrder, lbl.Parent = Enum.TextXAlignment.Left, order, parent
end

-- ══════════════════════════════════════════════
--  MONTAGEM: ABA MACROS
-- ══════════════════════════════════════════════
local TabMacro, PageMacro = createTab("MACROS", 1)

local leftCol = Instance.new("Frame")
leftCol.Size, leftCol.Position, leftCol.BackgroundTransparency = UDim2.new(0.48, -8, 1, -16), UDim2.new(0, 8, 0, 8), 1
leftCol.Parent = PageMacro
local leftLayout = Instance.new("UIListLayout", leftCol) leftLayout.Padding = UDim.new(0, 8)

local rightCol = Instance.new("Frame")
rightCol.Size, rightCol.Position, rightCol.BackgroundTransparency = UDim2.new(0.52, -8, 1, -16), UDim2.new(0.48, 8, 0, 8), 1
rightCol.Parent = PageMacro
local rightLayout = Instance.new("UIListLayout", rightCol) rightLayout.Padding = UDim.new(0, 8)

createSection("Macro Studio", 1, leftCol)
local nameInput = Instance.new("TextBox")
nameInput.Size, nameInput.BackgroundColor3 = UDim2.new(1, 0, 0, 36), Theme.Surface
nameInput.PlaceholderText, nameInput.Text, nameInput.TextColor3 = "Macro Name...", G.SelectedMacro or "", Theme.Text
nameInput.Font, nameInput.TextSize = Enum.Font.Gotham, 12
nameInput.LayoutOrder, nameInput.Parent = 2, leftCol
local niStroke = Instance.new("UIStroke", nameInput) niStroke.Color = Theme.Border
Instance.new("UICorner", nameInput).CornerRadius = UDim.new(0, 6)

createButton("Create / Save Macro", 3, leftCol, Theme.Surface, function()
    if nameInput.Text ~= "" then
        G.SelectedMacro = nameInput.Text
        if not G.Macros[G.SelectedMacro] then G.Macros[G.SelectedMacro] = {} end
        saveMacros() AddLog("Macro '"..G.SelectedMacro.."' salvo.")
    end
end)

createSection("Selected Macro", 4, leftCol)
local selectedDisplay = Instance.new("TextButton")
selectedDisplay.Size, selectedDisplay.BackgroundColor3 = UDim2.new(1, 0, 0, 36), Theme.BG
selectedDisplay.Text, selectedDisplay.TextColor3 = G.SelectedMacro ~= "" and G.SelectedMacro or "None", Theme.Text
selectedDisplay.Font, selectedDisplay.TextSize, selectedDisplay.LayoutOrder = Enum.Font.GothamBold, 13, 5
selectedDisplay.Parent = leftCol
local sdStroke = Instance.new("UIStroke", selectedDisplay) sdStroke.Color = Theme.Border
Instance.new("UICorner", selectedDisplay).CornerRadius = UDim.new(0, 6)

local dropdownFrame = Instance.new("Frame")
dropdownFrame.Size, dropdownFrame.BackgroundColor3 = UDim2.new(1, 0, 0, 0), Theme.Surface
dropdownFrame.Position, dropdownFrame.Visible, dropdownFrame.ClipsDescendants = UDim2.new(0, 0, 0, 36), false, true
dropdownFrame.ZIndex, dropdownFrame.Parent = 10, selectedDisplay
Instance.new("UICorner", dropdownFrame).CornerRadius = UDim.new(0, 6)
local ddLayout = Instance.new("UIListLayout", dropdownFrame)

selectedDisplay.MouseButton1Click:Connect(function()
    if dropdownFrame.Visible then
        TweenService:Create(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)}):Play()
        task.wait(0.2) dropdownFrame.Visible = false
    else
        for _, v in ipairs(dropdownFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        local count = 0
        for name, _ in pairs(G.Macros) do
            count = count + 1
            local opt = Instance.new("TextButton")
            opt.Size, opt.BackgroundTransparency = UDim2.new(1, 0, 0, 30), 1
            opt.Text, opt.TextColor3, opt.Font, opt.TextSize = name, Theme.Text, Enum.Font.Gotham, 12
            opt.Parent = dropdownFrame
            opt.MouseButton1Click:Connect(function()
                G.SelectedMacro = name nameInput.Text = name selectedDisplay.Text = name
                TweenService:Create(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                task.wait(0.2) dropdownFrame.Visible = false
                AddLog("Macro alterado para: "..name)
            end)
        end
        if count > 0 then
            dropdownFrame.Visible = true
            dropdownFrame.Size = UDim2.new(1, 0, 0, 0)
            TweenService:Create(dropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, count * 30)}):Play()
        end
    end
end)

createCheckbox("Record Macro", 6, leftCol, function() return G.IsRecording end, function(v)
    G.IsRecording = v
    if v then
        if G.SelectedMacro == "" then G.SelectedMacro = "Default" end
        G.Macros[G.SelectedMacro] = {}
        G.RecordStartTime = os.clock()
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp or not G.IsRecording then conn:Disconnect() return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local now = os.clock() - G.RecordStartTime
                table.insert(G.Macros[G.SelectedMacro], { Type = "Click", X = input.Position.X, Y = input.Position.Y, Time = now })
            end
        end)
    else saveMacros() end
end)

createCheckbox("Play Macro", 7, leftCol, function() return G.IsPlaying end, function(v)
    G.IsPlaying = v
    if v then
        local macro = G.Macros[G.SelectedMacro]
        if not macro or #macro == 0 then AddLog("Macro empty!"); return end
        task.spawn(function()
            repeat
                local start = os.clock()
                for _, a in ipairs(macro) do
                    if not G.IsPlaying then break end
                    local waitTime = (start + a.Time) - os.clock()
                    if waitTime > 0 then task.wait(waitTime) end
                    if a.Type == "Click" then
                        VirtualInputManager:SendMouseButtonEvent(a.X, a.Y, 0, true, game, 1)
                        task.wait(0.03)
                        VirtualInputManager:SendMouseButtonEvent(a.X, a.Y, 0, false, game, 1)
                    end
                end
                task.wait(0.5)
            until not G.IsPlaying
        end)
    end
end)

createButton("Delete Selected Macro", 8, leftCol, Theme.BG, function()
    if G.SelectedMacro ~= "" and G.Macros[G.SelectedMacro] then
        G.Macros[G.SelectedMacro] = nil saveMacros()
        G.SelectedMacro = "" nameInput.Text = "" selectedDisplay.Text = "None"
        AddLog("Macro deletado.")
    end
end)

createSection("Activity Journal", 1, rightCol)
local journalBox = Instance.new("ScrollingFrame")
journalBox.Size, journalBox.BackgroundColor3 = UDim2.new(1, 0, 0, 240), Color3.fromRGB(10,10,15)
journalBox.BorderSizePixel, journalBox.LayoutOrder = 0, 2
journalBox.ScrollBarThickness, journalBox.ScrollBarImageColor3 = 3, Theme.Accent
journalBox.Parent = rightCol
Instance.new("UICorner", journalBox).CornerRadius = UDim.new(0, 6)

LogText = Instance.new("TextLabel")
LogText.Size, LogText.BackgroundTransparency = UDim2.new(1, -10, 0, 0), 1
LogText.Position, LogText.TextColor3 = UDim2.new(0, 5, 0, 5), Theme.AccentL
LogText.Font, LogText.TextSize, LogText.TextXAlignment, LogText.TextYAlignment = Enum.Font.Code, 10, Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
LogText.Text = "[STD] Hub iniciado.\n"
LogText.Parent = journalBox
LogText.AutomaticSize = Enum.AutomaticSize.Y

-- ══════════════════════════════════════════════
--  MONTAGEM: ABA OTHERS (Automação)
-- ══════════════════════════════════════════════
local TabOthers, PageOthers = createTab("OTHERS", 2)
local leftOther = Instance.new("Frame")
leftOther.Size, leftOther.Position, leftOther.BackgroundTransparency = UDim2.new(0.5, -8, 1, -16), UDim2.new(0, 8, 0, 8), 1
leftOther.Parent = PageOthers
local loLayout = Instance.new("UIListLayout", leftOther) loLayout.Padding = UDim.new(0, 8)
local rightOther = Instance.new("Frame")
rightOther.Size, rightOther.Position, rightOther.BackgroundTransparency = UDim2.new(0.5, -8, 1, -16), UDim2.new(0.5, 8, 0, 8), 1
rightOther.Parent = PageOthers
local roLayout = Instance.new("UIListLayout", rightOther) roLayout.Padding = UDim.new(0, 8)

createSection("Auto Casino & Raid", 1, leftOther)
createCheckbox("Auto Casino", 2, leftOther, function() return G.AutoCasino end, function(v) G.AutoCasino = v end)
createCheckbox("Auto Raid", 3, leftOther, function() return G.AutoRaid end, function(v) G.AutoRaid = v end)
createCheckbox("Auto Hell Mode", 4, leftOther, function() return G.AutoHell end, function(v) G.AutoHell = v end)
createCheckbox("Auto Normal Mode", 5, leftOther, function() return G.AutoNormal end, function(v) G.AutoNormal = v end)
createCheckbox("Auto Easy Mode", 6, leftOther, function() return G.AutoEasy end, function(v) G.AutoEasy = v end)

createSection("Result Automation", 7, leftOther)
createCheckbox("Auto Replay", 8, leftOther, function() return G.AutoReplay end, function(v) G.AutoReplay = v end)
createCheckbox("Auto Leave", 9, leftOther, function() return G.AutoLeave end, function(v) G.AutoLeave = v end)

createSection("Visual & Mobile", 10, leftOther)
createCheckbox("Hide Jump Button", 11, leftOther, function() return G.HideJump end, function(v) 
    G.HideJump = v 
    if v then pcall(function() lp.PlayerGui.TouchGui.TouchJumpButton.Visible = false end) else pcall(function() lp.PlayerGui.TouchGui.TouchJumpButton.Visible = true end) end
end)
createCheckbox("Enable Anti-AFK", 12, leftOther, function() return G.AntiAFK end, function(v) 
    G.AntiAFK = v
    if v then
        task.spawn(function() while G.AntiAFK do game:GetService("VirtualUser"):CaptureController() game:GetService("VirtualUser"):ClickButton2(Vector2.new()) task.wait(60) end end)
    end
end)

createSection("Wave Automation", 1, rightOther)
createInputBox("Start Skipping At Wave", 2, rightOther, function() return G.SkipAtWave end, function(v) G.SkipAtWave = v end)
createCheckbox("Auto Skip Wave", 3, rightOther, function() return G.AutoSkipWave end, function(v) G.AutoSkipWave = v end)
createInputBox("Sell All Units At Wave", 4, rightOther, function() return G.SellAtWave end, function(v) G.SellAtWave = v end)
createCheckbox("Auto Sell at Wave", 5, rightOther, function() return G.AutoSellAtWave end, function(v) G.AutoSellAtWave = v end)

createSection("Ability Automation", 6, rightOther)
createCheckbox("Auto Ability", 7, rightOther, function() return G.AutoAbility end, function(v) G.AutoAbility = v end)
createInputBox("Auto Ability Start Wave", 8, rightOther, function() return G.AbilityAtWave end, function(v) G.AbilityAtWave = v end)

switchTab(TabMacro, PageMacro)
AddLog("UI Macro Studio carregada com coordenadas atualizadas.")
