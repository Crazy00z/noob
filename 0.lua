
-- Wait for game to load
if not game:IsLoaded() then game.Loaded:Wait() end

game:GetService("Players").LocalPlayer.Idled:Connect(function()
    local vu = game:GetService("VirtualUser")
    vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)
getgenv().SecureMode = true

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
end)

--------------------------------------------------------------------------------
-- INSTANT PROXIMITY PROMPT
--------------------------------------------------------------------------------

local InstantPromptEnabled = true

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
    if InstantPromptEnabled then
        fireproximityprompt(prompt)
    end
end)

--------------------------------------------------------------------------------
-- SPEED CHANGER
--------------------------------------------------------------------------------

local SpeedEnabled    = false
local SpeedValue      = 50
local SpeedConnection = nil

local function StopSpeed()
    if SpeedConnection then
        SpeedConnection:Disconnect()
        SpeedConnection = nil
    end
end

local function ApplySpeed()
    StopSpeed()
    SpeedConnection = RunService.Heartbeat:Connect(function(dt)
        if not SpeedEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then return end
        if humanoid.MoveDirection.Magnitude == 0 then return end
        local bonus = SpeedValue - 16
        if bonus <= 0 then return end
        rootPart.CFrame = rootPart.CFrame + humanoid.MoveDirection * bonus * dt
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    ApplySpeed()
end)

if LocalPlayer.Character then
    ApplySpeed()
end

--------------------------------------------------------------------------------
-- RAID PLACE CHECK
--------------------------------------------------------------------------------

local IS_RAID_FIGHT = game.PlaceId == 119916675926168

--------------------------------------------------------------------------------
-- KAIZEN SPECIFIC REMOTES & PATHS
--------------------------------------------------------------------------------

local GlobalEvents = ReplicatedStorage:WaitForChild("@rbxts/wcs:source/networking@GlobalEvents")
local RequestSkill = GlobalEvents:WaitForChild("requestSkill")

local MovesetRoot = ReplicatedStorage:WaitForChild("Source"):WaitForChild("Shared"):WaitForChild("Combat"):WaitForChild("Movesets")
local PathCache = {
    Weapons        = MovesetRoot:WaitForChild("Weapons"),
    FightingStyles = MovesetRoot:WaitForChild("FightingStyles"),
    Kaizen         = MovesetRoot:WaitForChild("Anime"):WaitForChild("Kaizen")
}

local SelectedToolName       = "Mantis Edge"
local AutoEquipTool          = true
local IsFarming              = false
local InfiniteStaminaEnabled = false
local InstaKillEnabled       = false
local AutoRaidEnabled        = false

--------------------------------------------------------------------------------
-- STATIC LISTS
--------------------------------------------------------------------------------

local RegularList = {
    "Bandit", "BeetleCurse", "BoxerPuppet", "CaveBat", "CursedFloaterHead",
    "CursedFrog", "CursedPuppet", "CursedTechniqueTrainingDummy", "DeathHowlCurse",
    "Demonhead", "FightingStyleTrainingDummy", "FireFloaterHead", "Flyhead",
    "FrozenCorpse", "Golem_Beach", "Gorex_Beach", "InsomniaCurse", "JHStudent",
    "JJKStudentEvent", "Kroaker_Beach", "LanternFish_Beach", "MushroomCurse",
    "MutatedFlyhead", "RogueSorcererEvent", "SchoolRaid_Roppongi", "SenseiKlops_Beach",
    "Slime", "SmallCaveMole", "StarterTrainingDummy", "ThornmawCurse",
    "TwistedMawCurse", "WailingTitan", "Watcher_Beach", "WeaponTrainingDummy", "ZeninSorcerer", "Dozo",
    "Miyaga", "ElderZeninSorcerer","Bunnox",
}
local BossList = {
    "FrostboundTitan", "IroncladGnasher", "FingerBearer",
    "LizardCurse", "OgreCurse", "CursedFrogKing", "MutatedLizardCurse",
    "BagMan", "BloodBrother", "Cathy", "Kezichu", "Raiken", "ToxicWasteCurse", "CursedWolf", "Kamena",
}
local WorldBossList = {
    "Eso", "Gojo", "Itadori", "Kashimo", "Sukuna", "Uraume",
    "Kraken_Rift", "Grinner_Rift", "Vorath_Rift", "Hakari","Eggion","CarrotShield", "EasterBunny_Rift", "Ryu",
}
table.sort(RegularList)
table.sort(BossList)
table.sort(WorldBossList)

--------------------------------------------------------------------------------
-- NOCLIP
--------------------------------------------------------------------------------

local NoclipEnabled = false

RunService.Stepped:Connect(function()
    if NoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

local function SetNoclip(enabled)
    NoclipEnabled = enabled
    if not enabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- PHYSICS LOCK
--------------------------------------------------------------------------------

local ActiveBV = nil
local ActiveBG = nil

local function GetCharacter()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
        if char.Humanoid.Health > 0 then return char end
    end
    return nil
end

local function LockPosition(targetCFrame)
    local char = GetCharacter()
    if not char or not char.PrimaryPart then return end
    local root = char.PrimaryPart

    if not ActiveBV or ActiveBV.Parent ~= root then
        if ActiveBV then ActiveBV:Destroy() end
        ActiveBV          = Instance.new("BodyVelocity")
        ActiveBV.Name     = "CrazyHub_Hold"
        ActiveBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        ActiveBV.Velocity = Vector3.zero
        ActiveBV.Parent   = root
    end

    if not ActiveBG or ActiveBG.Parent ~= root then
        if ActiveBG then ActiveBG:Destroy() end
        ActiveBG           = Instance.new("BodyGyro")
        ActiveBG.Name      = "CrazyHub_Look"
        ActiveBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        ActiveBG.P         = 30000
        ActiveBG.D         = 100
        ActiveBG.Parent    = root
    end

    root.CFrame       = targetCFrame
    root.Velocity     = Vector3.zero
    ActiveBG.CFrame   = targetCFrame
    ActiveBV.Velocity = Vector3.zero
end

local function UnlockPosition()
    if ActiveBV then ActiveBV:Destroy() ActiveBV = nil end
    if ActiveBG then ActiveBG:Destroy() ActiveBG = nil end
end

--------------------------------------------------------------------------------
-- TOOL HELPERS
--------------------------------------------------------------------------------

local function GetToolType(toolName)
    if toolName == "Divergent Fist" or toolName == "Divergent Fists"
        or toolName == "Fists" or toolName == "Black Flash" or toolName == "Combat" then
        return "FightingStyle"
    end
    if PathCache.FightingStyles:FindFirstChild(toolName) then return "FightingStyle" end
    if PathCache.Weapons:FindFirstChild(toolName)        then return "Weapon" end
    if PathCache.Kaizen:FindFirstChild(toolName)         then return "Kaizen" end
    return "Weapon"
end

local function GetToolFullPath(toolName)
    if toolName == "Divergent Fists" or toolName == "Divergent Fist" then return "Movesets/FightingStyles/Fists" end
    if toolName == "Fists"                                             then return "Movesets/FightingStyles/Fists" end
    if PathCache.FightingStyles:FindFirstChild(toolName) then return "Movesets/FightingStyles/" .. toolName end
    if PathCache.Weapons:FindFirstChild(toolName)        then return "Movesets/Weapons/"         .. toolName end
    if PathCache.Kaizen:FindFirstChild(toolName)         then return "Movesets/Anime/Kaizen/"    .. toolName end
    return "Movesets/Weapons/" .. toolName
end

--------------------------------------------------------------------------------
-- SYNC REMOTE (cached)
--------------------------------------------------------------------------------

local CachedSyncRemote = nil
local function GetCachedSyncRemote()
    if CachedSyncRemote and CachedSyncRemote.Parent then return CachedSyncRemote end
    local ok, result = pcall(function()
        local current = ReplicatedStorage
        for _, name in ipairs({"Source","Shared","Packages","Nodeware","Utilities","RE//Nodeware/PacketsSync"}) do
            current = current:WaitForChild(name, 3)
            if not current then return nil end
        end
        return current
    end)
    if ok and result then CachedSyncRemote = result end
    return CachedSyncRemote
end

task.spawn(function()
    task.wait(1)
    GetCachedSyncRemote()
end)

--------------------------------------------------------------------------------
-- INFINITE STAMINA HOOK
--------------------------------------------------------------------------------

local StaminaRemote = GetCachedSyncRemote()
local Metatable     = getrawmetatable(game)
local OldNamecall   = Metatable.__namecall
setreadonly(Metatable, false)

Metatable.__namecall = newcclosure(function(Self, ...)
    local Args   = {...}
    local Method = getnamecallmethod()
    if InfiniteStaminaEnabled and Method == "FireServer" and Self == StaminaRemote then
        local BufferData = Args[1]
        if typeof(BufferData) == "buffer" and buffer.len(BufferData) >= 1 then
            local h = buffer.readu8(BufferData, 0)
            if h == 0x22 or h == 0x23 then return nil end
        end
    end
    return OldNamecall(Self, ...)
end)

setreadonly(Metatable, true)

--------------------------------------------------------------------------------
-- QUEST REMOTES
--------------------------------------------------------------------------------

local QUEST_SUFFIX = "8\000\003\000SFX\003\000set\001\002\000\000\000\000\000\000\240?8\000\005\000Music\003\000set\001\002\000\000\000\000\000\000\240?8\000\002\000UI\003\000set\001\002\000\000\000\000\000\000\240?"

local function AcceptQuest(npcName)
    local remote = GetCachedSyncRemote()
    if not remote then return end
    local nameLen = #npcName
    local lenLo   = nameLen % 256
    local lenHi   = math.floor(nameLen / 256)
    local bufStr  = string.char(0x3E, 0x00, lenLo, lenHi) .. npcName .. string.char(0x01, 0x00)
    pcall(function() remote:FireServer(buffer.fromstring(bufStr .. QUEST_SUFFIX)) end)
end

local function AbandonQuest()
    local remote = GetCachedSyncRemote()
    if not remote then return end
    pcall(function() remote:FireServer(buffer.fromstring("\064\000\000\000")) end)
end

--------------------------------------------------------------------------------
-- LEVEL & QUEST UI READERS
--------------------------------------------------------------------------------

local function GetLevel()
    local ok, text = pcall(function()
        return LocalPlayer.PlayerGui.HUD.HUDContainer.Level.Container.Progress.Top.ShadowLabel.Text
    end)
    if ok and type(text) == "string" then
        local n = text:gsub("<[^>]+>", ""):match("(%d+)%s*$")
        return n and tonumber(n) or 0
    end
    return 0
end

local function HasActiveQuest()
    local ok, result = pcall(function()
        local lower = LocalPlayer.PlayerGui.HUD.HUDContainer.Top.Top.Lower
        local obj   = LocalPlayer.PlayerGui.HUD.HUDContainer.Top.Top.Objective
        return lower.Visible and obj.Visible
    end)
    return ok and result == true
end

local function GetQuestObjective()
    local ok, text = pcall(function()
        return LocalPlayer.PlayerGui.HUD.HUDContainer.Top.Top.Objective.DisplayLabel.Text
    end)
    return (ok and type(text) == "string") and text or ""
end

local function GetQuestProgress()
    local ok, text = pcall(function()
        return LocalPlayer.PlayerGui.HUD.HUDContainer.Top.Top.Lower.Quest.Progress.DisplayLabel.Text
    end)
    return (ok and type(text) == "string") and text or "0/0"
end

local function IsQuestComplete()
    local cur, max = GetQuestProgress():match("(%d+)/(%d+)")
    if cur and max then return tonumber(cur) >= tonumber(max) end
    return false
end

local function QuestHasMobObjective()
    local progress = GetQuestProgress()
    if not progress or progress == "0/0" then return false end
    local cur, max = progress:match("(%d+)/(%d+)")
    if cur and max then return tonumber(max) > 0 end
    return false
end

--------------------------------------------------------------------------------
-- QUEST TABLE
--------------------------------------------------------------------------------

local KAIZEN_QUESTS = {
    { npcName="Principle Yaga",           displayName="Principal Yaga",    minLvl=1,   targets={"CursedPuppet"},                    npcCFrame=CFrame.new(2132,106,-1727)  },
    { npcName="Megumi",                   displayName="Megumi",            minLvl=8,   targets={"Raiken","CursedPuppet"},           npcCFrame=CFrame.new(2367,106,-1766)  },
    { npcName="Hitoshi",                  displayName="Hitoshi",           minLvl=18,  targets={"Flyhead","FireFloaterHead"},       npcCFrame=CFrame.new(2385,68,-285)    },
    { npcName="Murata",                   displayName="Murata",            minLvl=23,  targets={"BagMan"},                         npcCFrame=CFrame.new(2834,68,-276)    },
    { npcName="Mika",                     displayName="Mika",              minLvl=28,  targets={"CursedFloaterHead"},               npcCFrame=CFrame.new(1838,59,-527)    },
    { npcName="Rin",                      displayName="Rin",               minLvl=30,  targets={"CursedFrog"},                     npcCFrame=CFrame.new(1117,59,-920)    },
    { npcName="Hisashi",                  displayName="Hisashi",           minLvl=33,  targets={"GrasshopperCurse"},               npcCFrame=CFrame.new(934,114,-550)    },
    { npcName="Akira",                    displayName="Akira",             minLvl=34,  targets={"MushroomHeadCurse","MushroomCurse"}, npcCFrame=CFrame.new(673,141,-1446) },
    { npcName="Osamu",                    displayName="Osamu",             minLvl=45,  targets={"BeetleCurse","LizardCurse"},      npcCFrame=CFrame.new(1245,173,-2092)  },
    { npcName="Taro",                     displayName="Taro",              minLvl=55,  targets={"Demonhead","OgreCurse"},          npcCFrame=CFrame.new(501,136,-2549)   },
    { npcName="Rei",                      displayName="Sorcerer Rei",      minLvl=70,  targets={"FrozenCorpse"},                   npcCFrame=CFrame.new(-133,331,-1755)  },
    { npcName="Kaori",                    displayName="Kaori",             minLvl=78,  targets={"DeathHowlCurse"},                 npcCFrame=CFrame.new(-755,314,-1723)  },
    { npcName="Itsuki",                   displayName="Scout Itsuki",      minLvl=85,  targets={"FrostboundTitan"},                npcCFrame=CFrame.new(-248,444,-1499)  },
    { npcName="Rikumo",                   displayName="Rikumo",            minLvl=90,  targets={"CaveBat","CaveMole"},             npcCFrame=CFrame.new(3329,51,-1099)   },
    { npcName="Tetsuya",                  displayName="Tetsuya",           minLvl=91,  targets={"Slime"},                         npcCFrame=CFrame.new(3824,-12,-1517)  },
    { npcName="Hotaru",                   displayName="Hotaru",            minLvl=99,  targets={"ToxicWasteCurse"},                npcCFrame=CFrame.new(5150,-32,-1530)  },
    { npcName="Curse Analyst Yuna",       displayName="Analyst Yuna",      minLvl=110, targets={"CaveBat"},                       npcCFrame=CFrame.new(4233,-0.5,-744)  },
    { npcName="Jin",                      displayName="Jin",               minLvl=115, targets={"FingerBearer"},                   npcCFrame=CFrame.new(3870,42,435)     },
    { npcName="Scared Civilian - Shibuya",displayName="Scared Civilian",   minLvl=125, targets={"ThornmawCurse"},                  npcCFrame=CFrame.new(1370,164,971)    },
    { npcName="Yuta - Shibuya",           displayName="Yuta",              minLvl=140, targets={"TwistedMawCurse","GrinCurse"},   npcCFrame=CFrame.new(677,177,2083)    },
    { npcName="Nanami - Shibuya",         displayName="Nanami",            minLvl=170, targets={"WailingTitan","IroncladGnasher"},npcCFrame=CFrame.new(953,178,3002)    },
    { npcName="Yukimiya",                 displayName="Yukimiya",          minLvl=250, targets={"Watcher_Beach"},                  npcCFrame=CFrame.new(422,178,3213)    },
    { npcName="Kamfuji",                  displayName="Kamfuji",           minLvl=265, targets={"Golem_Beach"},                    npcCFrame=CFrame.new(77,177,3020)     },
    { npcName="Sutoshi",                  displayName="Sutoshi",           minLvl=280, targets={"SenseiKlops_Beach"},              npcCFrame=CFrame.new(-67,178,3231)    },
    { npcName="Aizetsu",                  displayName="Aizetsu",           minLvl=295, targets={"Kroaker_Beach"},                  npcCFrame=CFrame.new(-1142,121,3493)  },
    { npcName="Thanos",                   displayName="Thanos",            minLvl=310, targets={"Gorex_Beach"},                    npcCFrame=CFrame.new(-1440,113,4460)  },
    { npcName="Minato",                   displayName="Minato",            minLvl=325, targets={"LanternFish_Beach"},              npcCFrame=CFrame.new(-1748,109,4214)  },
    { npcName="Dozo",                     displayName="Dozo",              minLvl=355, targets={"Dozo"},                           npcCFrame=CFrame.new(4123.28, 157.49, 3024.37) },
    { npcName="Miyaga",                   displayName="Miyaga",            minLvl=370, targets={"Miyaga"},                         npcCFrame=CFrame.new(3128.56, 192.71, 3304.45) },
    { npcName="CursedWolf",               displayName="CursedWolf",        minLvl=385, targets={"CursedWolf"},                     npcCFrame=CFrame.new(3477.74, 66.85,  4705.75) },
    { npcName="ElderZeninSorcerer",       displayName="ElderZeninSorcerer",minLvl=400, targets={"ElderZeninSorcerer"},             npcCFrame=CFrame.new(4637.28, 218.27, 4014.76) },
    { npcName="Kamena",                   displayName="Kamena",            minLvl=415, targets={"Kamena"},                         npcCFrame=CFrame.new(5725.52, 312.14, 4429.03) },
}

local function GetQuestForLevel(level)
    local best = KAIZEN_QUESTS[1]
    for _, q in ipairs(KAIZEN_QUESTS) do
        if level >= q.minLvl then best = q end
    end
    return best
end

--------------------------------------------------------------------------------
-- HELPER: IS CIVILIAN
--------------------------------------------------------------------------------

local function IsCivilian(model)
    if not model then return false end
    local attr = model:GetAttribute("EnemyName")
    if attr then
        local s = tostring(attr)
        if s:sub(1,3) == "Civ" or s:find("Civilian") then return true end
    end
    if model.Name:sub(1,3) == "Civ" or model.Name:find("Civilian") then return true end
    return false
end

--------------------------------------------------------------------------------
-- TARGET FINDER (SPECIFIC)
--------------------------------------------------------------------------------

local function FindEnemyTarget(targetNames)
    local char = GetCharacter()
    if not char then return nil end
    local myPos = char.HumanoidRootPart.Position
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return nil end

    local function searchFolder(folder, targetName)
        local closest, closestDist = nil, math.huge
        local targetLower = targetName:lower()
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Model") then
                local hum = child:FindFirstChildWhichIsA("Humanoid", true)
                local isAlive = hum and hum.Health > 0
                local isInstaKilled = InstaKillEnabled and hum and hum.Health <= 0
                if isAlive or isInstaKilled then
                    local attr = child:GetAttribute("EnemyName")
                    if not attr then continue end
                    local nameToCheck = tostring(attr):lower()
                    if nameToCheck == targetLower then
                        local hrp = child:FindFirstChild("HumanoidRootPart")
                        local pos = hrp and hrp.Position or child:GetPivot().Position
                        if pos then
                            local dist = (myPos - pos).Magnitude
                            if dist < closestDist then
                                closest = child
                                closestDist = dist
                            end
                        end
                    end
                end
            end
        end
        return closest
    end

    if targetNames then
        for _, targetName in ipairs(targetNames) do
            local found = searchFolder(enemiesFolder, targetName)
            if not found and enemiesFolder:FindFirstChild("Bosses") then
                found = searchFolder(enemiesFolder.Bosses, targetName)
            end
            if found then return found end
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- PRIORITY TARGET FINDER (WorldBoss > Boss > Mob)
--------------------------------------------------------------------------------

local SelectedEnemyNames     = {}
local SelectedBossNames      = {}
local SelectedWorldBossNames = {}

local function FindPriorityTarget()
    if #SelectedWorldBossNames > 0 then
        local t = FindEnemyTarget(SelectedWorldBossNames)
        if t then return t end
    end
    if #SelectedBossNames > 0 then
        local t = FindEnemyTarget(SelectedBossNames)
        if t then return t end
    end
    if #SelectedEnemyNames > 0 then
        local t = FindEnemyTarget(SelectedEnemyNames)
        if t then return t end
    end
    return nil
end

local function IsTargetValid(target)
    if not target or not target.Parent then return false end
    local hum = target:FindFirstChildWhichIsA("Humanoid", true)
    if not hum then return false end
    return hum.Health > 0
end

--------------------------------------------------------------------------------
-- TARGET FINDER (ANY / RAID)
--------------------------------------------------------------------------------

local function FindAnyEnemy(filterKeyword)
    local char = GetCharacter()
    if not char then return nil end
    local myPos = char.HumanoidRootPart.Position
    local closest, closestDist = nil, math.huge
    local filterLower = filterKeyword and filterKeyword:lower() or nil

    local function tryModel(child)
        if not child:IsA("Model") then return end
        local hum = child:FindFirstChild("Humanoid")
        if not hum then return end
        if not InstaKillEnabled and hum.Health <= 0 then return end
        if IsCivilian(child) then return end
        if filterLower then
            local rawName = child:GetAttribute("EnemyName")
            if not rawName or not tostring(rawName):lower():find(filterLower, 1, true) then return end
        end
        local hrp = child:FindFirstChild("HumanoidRootPart")
        local pos = hrp and hrp.Position or child:GetPivot().Position
        if not pos then return end
        local dist = (myPos - pos).Magnitude
        if dist < closestDist then closest = child closestDist = dist end
    end

    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if enemiesFolder then
        for _, child in ipairs(enemiesFolder:GetChildren()) do tryModel(child) end
        local bossFolder = enemiesFolder:FindFirstChild("Bosses")
        if bossFolder then
            for _, child in ipairs(bossFolder:GetChildren()) do tryModel(child) end
        end
    end
    return closest
end

local function GetEnemyCFrame(enemy)
    local hrp = enemy:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.CFrame end
    return enemy:GetPivot()
end

local function ComputeGoalCFrame(targetCF, mode, dist)
    local tp = targetCF.Position
    local goalPos
    if mode == "Behind" then
        goalPos = tp - (targetCF.LookVector * dist)
        goalPos = Vector3.new(goalPos.X, tp.Y, goalPos.Z)
    elseif mode == "Under" then
        goalPos = Vector3.new(tp.X, tp.Y - dist, tp.Z)
    else
        goalPos = Vector3.new(tp.X, tp.Y + dist, tp.Z)
    end
    return CFrame.new(goalPos, tp)
end

--------------------------------------------------------------------------------
-- SHARED FARM STATE
--------------------------------------------------------------------------------

local FarmTarget   = nil
local FarmLocked   = false
local FarmLockedCF = nil

local function FarmTick(farmPosition, farmDistance)
    farmPosition = farmPosition or "Above"
    farmDistance = farmDistance or 5
    if not FarmTarget or not FarmTarget.Parent then
        FarmTarget=nil FarmLocked=false FarmLockedCF=nil
        IsFarming=false UnlockPosition() return
    end
    local hum = FarmTarget:FindFirstChildWhichIsA("Humanoid", true)
    if not InstaKillEnabled and hum and hum.Health <= 0 then
        FarmTarget=nil FarmLocked=false FarmLockedCF=nil
        IsFarming=false UnlockPosition() return
    end
    local char = GetCharacter()
    if not char then return end
    local goalCF = ComputeGoalCFrame(GetEnemyCFrame(FarmTarget), farmPosition, farmDistance)
    if farmPosition == "Under" then SetNoclip(true) else SetNoclip(false) end
    local char = GetCharacter()
    if char then
        local myPos = char.HumanoidRootPart.Position
        local targetPos = GetEnemyCFrame(FarmTarget).Position
        if (myPos - targetPos).Magnitude > 100 then
            char.HumanoidRootPart.CFrame = goalCF
        end
    end
    LockPosition(goalCF)
    FarmLocked=true FarmLockedCF=goalCF
    IsFarming = true
end

--------------------------------------------------------------------------------
-- AUTO STATS LOGIC
--------------------------------------------------------------------------------

local STATS_SUFFIX = "8\000\003\000SFX\003\000set\001\002\000\000\000\000\000\000\240?8\000\005\000Music\003\000set\001\002\000\000\000\000\000\000\240?8\000\002\000UI\003\000set\001\002\000\000\000\000\000\000\240?"

local function GetStatBuffer(statName)
    local len = #statName
    return ":\000\001\000\000\000" .. string.char(len) .. "\000" .. statName .. STATS_SUFFIX
end

local AutoStats = {
    Melee = false, Defense = false, Stamina = false,
    Weapon = false, CursedEnergy = false
}

task.spawn(function()
    while true do
        task.wait(0.5)
        local remote = GetCachedSyncRemote()
        if remote then
            for stat, enabled in pairs(AutoStats) do
                if enabled then
                    pcall(function() remote:FireServer(buffer.fromstring(GetStatBuffer(stat))) end)
                    task.wait(0.1)
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- ATTACK LOOPS
--------------------------------------------------------------------------------

local RaidSelectedToolName = "Mantis Edge"

local function GetActiveTool()
    if AutoRaidEnabled then return RaidSelectedToolName end
    return SelectedToolName
end

task.spawn(function()
    while true do
        task.wait(0.05)
        if IsFarming and InstaKillEnabled then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        else
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end
    end
end)

local function IsScriptUIOpen()
    local ok, result = pcall(function()
        return Library.Toggled -- Obsidian library stores visibility state here
    end)
    return ok and result == true
end

task.spawn(function()
    while true do
        task.wait(0.3)
        if IsFarming and not IsScriptUIOpen() then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
    end
end)

--------------------------------------------------------------------------------
-- INSTA KILL LOGIC
--------------------------------------------------------------------------------
local IMMUNE_BOSSES = {
    ["IroncladGnasher"]   = true,
    ["Kraken_Rift"]       = true,
    ["LanternFish_Beach"] = true,
}

task.spawn(function()
    while true do
        task.wait(0.1)
        if not InstaKillEnabled then continue end
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then continue end

        local function checkKill(mob)
            if not mob:IsA("Model") then return end
            local hum = mob:FindFirstChild("Humanoid")
            if not hum or hum.Health <= 0 then return end
            if IsCivilian(mob) then return end
            local mobName = tostring(mob:GetAttribute("EnemyName") or mob.Name)
            if IMMUNE_BOSSES[mobName] then return end
            if AutoRaidEnabled then
                hum.Health = 0
            else
                if hum.Health <= hum.MaxHealth * 0.84 then
                    hum.Health = 0
                end
            end
        end

        for _, mob in pairs(enemies:GetChildren()) do checkKill(mob) end
        local bosses = enemies:FindFirstChild("Bosses")
        if bosses then
            for _, boss in pairs(bosses:GetChildren()) do checkKill(boss) end
        end
    end
end)

--------------------------------------------------------------------------------
-- GET PLAYER TOOLS
--------------------------------------------------------------------------------
local function GetPlayerTools()
    local tools, seen = {}, {}
    local function addTools(parent)
        for _, item in ipairs(parent:GetChildren()) do
            if item:IsA("Tool") and not seen[item.Name] then
                table.insert(tools, item.Name)
                seen[item.Name] = true
            end
        end
    end
    if LocalPlayer:FindFirstChild("Backpack") then addTools(LocalPlayer.Backpack) end
    if Character then addTools(Character) end
    if not seen["Divergent Fist"] and not seen["Divergent Fists"] then
        table.insert(tools, "Divergent Fist")
    end
    table.sort(tools)
    return tools
end
--------------------------------------------------------------------------------
-- AUTO COLLECT EGGS
--------------------------------------------------------------------------------
local AutoEggEnabled = false
local EggStatusLabel = nil
local BANNED_EGG_POSITIONS = {
    Vector3.new(1444.18127, 33.8299942, -139.110275),
    Vector3.new(1444.18, 16.6, -139.11),
    Vector3.new(1437.98865, 28.6299763, -200.949295),
    Vector3.new(1442.38867, 24.60882, -262.049316),
    Vector3.new(2569.55835, 298.405579, 4091.39697),
    Vector3.new(5190.22021, 605.707886, 3339.21045),
    Vector3.new(2883.64941, -52.2587357, -997.356323),
    Vector3.new(2916.3418, -66.3587341, -993.156311),
    Vector3.new(2947.3418, -64.8390274, -939.717407),
    Vector3.new(2898.14941, -46.8587341, -947.817383),
    Vector3.new(3499.07275, 272.46814, 5205.4917),
    Vector3.new(1437.98865, 5.59076881, -200.949295),
    Vector3.new(1444.18127, 16.6035595, -139.110275),
    Vector3.new(1442.38867, 24.60882, -262.049316),
    Vector3.new(5190.22021, 605.707886, 3339.21045),
    Vector3.new(2898.14941, -57.8947639, -947.817383),
    Vector3.new(2947.3418, -64.8390274, -939.717407),
    Vector3.new(2883.64941, -54.8596764, -997.356323),
    Vector3.new(2916.3418, -66.3587341, -993.156311),
    Vector3.new(3353.12207, 272.46814, 5266.81982),
    Vector3.new(2569.55835, 298.405579, 4091.39697),
}

local BAN_RADIUS = 50 

local function IsBannedEggPosition(pos)
    for _, banned in ipairs(BANNED_EGG_POSITIONS) do
        if (pos - banned).Magnitude < BAN_RADIUS then
            return true
        end
    end
    return false
end
local function AutoEggLoop()
    local function setStatus(txt)
        if EggStatusLabel then pcall(function() EggStatusLabel:SetText("Status: "..txt) end) end
    end
    while AutoEggEnabled do
        local char = GetCharacter()
        if not char then
            setStatus("Waiting for character...")
            task.wait(1)
            continue
        end
        local mapFolder = workspace:FindFirstChild("Map")
        if not mapFolder then
            setStatus("Map folder not found!")
            task.wait(2)
            continue
        end
        local found = 0
        for _, model in ipairs(mapFolder:GetChildren()) do
            if not AutoEggEnabled then break end
            if not model:IsA("Model") then continue end
            local pivot = model:GetPivot()
            if IsBannedEggPosition(pivot.Position) then
                setStatus("Skipping banned egg...")
                continue
            end
            char = GetCharacter()
            if not char then break end
            char.HumanoidRootPart.CFrame = pivot + Vector3.new(0, 3, 0)
            task.wait(0.35)
            local eggMesh = nil
            local meshPart = model:FindFirstChildWhichIsA("MeshPart")
            if meshPart and meshPart:FindFirstChild("egg") then
                eggMesh = meshPart
            end
            if not eggMesh then
                for _, desc in ipairs(model:GetDescendants()) do
                    if desc.Name == "egg" then
                        eggMesh = desc
                        break
                    end
                end
            end
            if eggMesh then
                local eggPos = eggMesh:IsA("BasePart") and eggMesh.Position or eggMesh:GetPivot().Position
                if IsBannedEggPosition(eggPos) then
                    setStatus("Skipping banned egg...")
                    continue
                end
                found = found + 1
                setStatus("Collecting egg " .. found .. "...")
                char = GetCharacter()
                if char then
                             char.HumanoidRootPart.CFrame = eggMesh.CFrame + Vector3.new(0, 2, 0)
                                task.wait(0.5)
                                local prompt = nil
                                for _, desc in ipairs(model:GetDescendants()) do
                                    if desc:IsA("ProximityPrompt") then
                                        prompt = desc
                                        break
                                    end
                                end
                                if prompt then
                                    char.HumanoidRootPart.CFrame = eggMesh.CFrame + Vector3.new(0, 2, 0)
                                    task.wait(0.2)
                                    for _ = 1, 3 do
                                        pcall(function() fireproximityprompt(prompt) end)
                                        task.wait(0.2)
                                    end
                                    task.wait(0.3)
                                else
                                    char.HumanoidRootPart.CFrame = eggMesh.CFrame + Vector3.new(0, 2, 0)
                                    task.wait(0.2)
                                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                    task.wait(0.6)
                                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                    task.wait(0.3)
                                end
                            end 
                        end 
                    end

                        setStatus("Cycle done — " .. found .. " eggs found. Restarting...")
                        task.wait(2)
                    end -- closes while AutoEggEnabled

                    setStatus("Idle")
                end -- closes AutoEggLoop

--------------------------------------------------------------------------------
-- UI SETUP — OBSIDIAN
--------------------------------------------------------------------------------

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local Library    = loadstring(game:HttpGet(repo .. "Library.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()

local Window = Library:CreateWindow({
    Title  = "CrazyHub",
    Footer = "Game | KAIZEN",
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    Farming    = Window:AddTab("Farming",     "sword"),
    Raid       = Window:AddTab("Auto Raid",   "shield"),
    Misc       = Window:AddTab("Misc",        "box"),
    UISettings = Window:AddTab("UI Settings", "settings"),
}

-- Left / Right groupboxes
local AutoLevelGroup    = Tabs.Farming:AddLeftGroupbox("Auto Level")
local FarmGroup         = Tabs.Farming:AddLeftGroupbox("Auto Farm Settings")
local WeaponGroup       = Tabs.Farming:AddRightGroupbox("Weapon Selection")
local MobsGroup         = Tabs.Farming:AddRightGroupbox("Mob Selection")

local AutoJoinRaidGroup = Tabs.Raid:AddLeftGroupbox("Auto Join Raid")

local StatsGroup   = Tabs.Misc:AddLeftGroupbox("Auto Stats")
local EggGroup     = Tabs.Misc:AddLeftGroupbox("Auto Collect Eggs")
local ChestGroup   = Tabs.Misc:AddLeftGroupbox("Chest Collection")
local StaminaGroup = Tabs.Misc:AddLeftGroupbox("Stamina")
local SpeedGroup   = Tabs.Misc:AddLeftGroupbox("Speed")
local ServerGroup  = Tabs.Misc:AddRightGroupbox("Server")
local CreditsGroup = Tabs.Misc:AddRightGroupbox("Credits")

--------------------------------------------------------------------------------
-- VARIABLES
--------------------------------------------------------------------------------

local Farming              = false
local AutoCollectBossChest = true

local AutoJoinEnabled     = false
local AutoStartEnabled    = false
local AutoReplayEnabled   = false
local ReplayRemote        = nil
local AutoJoinStatusLabel = nil
local SelectedRaidName    = "Zenin Massacre"
local SelectedDiffName    = "Easy"
local _AutoJoinLoopFn     = nil
local _AutoStartLoopFn    = nil
local Distance            = 5
local FarmPosition        = "Above"

local ToolList = GetPlayerTools()

--------------------------------------------------------------------------------
-- AUTO LEVEL STATE
--------------------------------------------------------------------------------

local AutoLevelEnabled = false
local AL_CurrentQuest  = nil
local AL_ForceRefresh  = false
local AL_StatusLabel   = nil
local AL_LevelLabel    = nil
local AL_QuestLabel    = nil

--------------------------------------------------------------------------------
-- AUTO LEVEL LOOP
--------------------------------------------------------------------------------

local function AutoLevelLoop()
    AL_CurrentQuest=nil AL_ForceRefresh=true
    FarmTarget=nil FarmLocked=false FarmLockedCF=nil
    UnlockPosition()

    local function setStatus(txt)
        if AL_StatusLabel then pcall(function() AL_StatusLabel:SetText("Status: "..tostring(txt)) end) end
    end
    local function setQuestInfo(txt)
        if AL_QuestLabel then pcall(function() AL_QuestLabel:SetText(tostring(txt)) end) end
    end
    local function setLevel(lvl)
        if AL_LevelLabel then pcall(function() AL_LevelLabel:SetText("Level: "..tostring(lvl)) end) end
    end

    while AutoLevelEnabled do
        task.wait(0.1)
        if not AutoLevelEnabled then break end

        local char = GetCharacter()
        if not char then
            IsFarming=false FarmTarget=nil FarmLocked=false
            UnlockPosition()
            setStatus("Waiting for character...")
            task.wait(0.5)
            continue
        end

        local level = GetLevel()
        local quest = GetQuestForLevel(level)
        setLevel(level)

        local needAccept = AL_ForceRefresh or (AL_CurrentQuest ~= quest) or (not HasActiveQuest())

        if needAccept then
            IsFarming=false FarmTarget=nil FarmLocked=false FarmLockedCF=nil
            AL_ForceRefresh=false
            UnlockPosition()

            if HasActiveQuest() then
                setStatus("Abandoning current quest...")
                AbandonQuest()
                task.wait(0.8)
                if not AutoLevelEnabled then break end
            end

            setStatus("Going to NPC: "..tostring(quest.displayName).."...")
            char = GetCharacter()
            if char then char.HumanoidRootPart.CFrame = quest.npcCFrame + Vector3.new(0, 3, 0) end
            task.wait(0.8)
            if not AutoLevelEnabled then break end

            AcceptQuest(quest.npcName)
            task.wait(0.8)
            if not AutoLevelEnabled then break end

            local ws = tick()
            repeat task.wait(0.15) until HasActiveQuest() or tick()-ws > 5 or not AutoLevelEnabled
            if not AutoLevelEnabled then break end

            if HasActiveQuest() then
                AL_CurrentQuest = quest
                setStatus("Quest accepted: "..tostring(quest.displayName))
            else
                AcceptQuest(quest.npcName)
                task.wait(1)
                if HasActiveQuest() then
                    AL_CurrentQuest = quest
                    setStatus("Quest accepted: "..tostring(quest.displayName))
                else
                    setStatus("Accept failed, retrying...")
                    AL_CurrentQuest = nil
                    task.wait(2)
                    continue
                end
            end
        end

        if HasActiveQuest() and IsQuestComplete() then
            IsFarming=false FarmTarget=nil FarmLocked=false FarmLockedCF=nil
            UnlockPosition()
            setStatus("Quest complete! Re-doing...")
            task.wait(0.5)
            AbandonQuest()
            task.wait(0.6)
            if not AutoLevelEnabled then break end

            local newLevel = GetLevel()
            local newQuest = GetQuestForLevel(newLevel)
            char = GetCharacter()
            if char then
                char.HumanoidRootPart.CFrame = newQuest.npcCFrame + Vector3.new(0, 3, 0)
                task.wait(0.8)
                if not AutoLevelEnabled then break end
                AcceptQuest(newQuest.npcName)
                task.wait(0.8)
                if not AutoLevelEnabled then break end
                local ws2 = tick()
                repeat task.wait(0.15) until HasActiveQuest() or tick()-ws2 > 5 or not AutoLevelEnabled
                AL_CurrentQuest = newQuest
                AL_ForceRefresh = false
            end
            continue
        end

        local targetsToFarm
        if HasActiveQuest() then
            setQuestInfo("Quest: "..GetQuestObjective().." ["..GetQuestProgress().."]")
            if QuestHasMobObjective() then
                targetsToFarm = quest.targets
            else
                targetsToFarm = quest.fallbackTargets or quest.targets
                setStatus("Non-kill step — farming fallback mobs for "..quest.displayName)
            end
        else
            setQuestInfo("No active quest")
            targetsToFarm = quest.targets
        end

        local target = FindEnemyTarget(targetsToFarm)
        if target then
            if target ~= FarmTarget then
                FarmTarget=target FarmLocked=false FarmLockedCF=nil
            end
            IsFarming = true
            setStatus("Farming: "..tostring(target:GetAttribute("EnemyName") or "Mob"))
        else
            if FarmTarget ~= nil then
                FarmTarget=nil FarmLocked=false FarmLockedCF=nil
                UnlockPosition()
            end
            IsFarming = false
            setStatus("Waiting for spawn... | LV."..tostring(level))
        end
    end

    IsFarming=false FarmTarget=nil FarmLocked=false FarmLockedCF=nil
    AL_CurrentQuest=nil
    UnlockPosition() SetNoclip(false)
    if AL_StatusLabel then pcall(function() AL_StatusLabel:SetText("Status: Idle") end) end
    if AL_QuestLabel  then pcall(function() AL_QuestLabel:SetText("No active quest") end) end
end

--------------------------------------------------------------------------------
-- UI CONSTRUCTION — AUTO LEVEL
--------------------------------------------------------------------------------

AL_StatusLabel = AutoLevelGroup:AddLabel("Status: Idle")
AL_LevelLabel  = AutoLevelGroup:AddLabel("Level: --")
AL_QuestLabel  = AutoLevelGroup:AddLabel("Quest: --")

AutoLevelGroup:AddToggle("AutoLevelToggle", {
    Text    = "Auto Level",
    Default = false,
    Callback = function(v)
        AutoLevelEnabled = v
        if v then
            Farming=false IsFarming=false AutoRaidEnabled=false
            FarmTarget=nil FarmLocked=false FarmLockedCF=nil
            AL_CurrentQuest=nil AL_ForceRefresh=true
            task.spawn(AutoLevelLoop)
        else
            IsFarming=false FarmTarget=nil FarmLocked=false FarmLockedCF=nil
            UnlockPosition() SetNoclip(false)
        end
    end,
})

--------------------------------------------------------------------------------
-- UI CONSTRUCTION — FARM GROUP
--------------------------------------------------------------------------------

FarmGroup:AddToggle("AutoFarmToggle", {
    Text    = "Auto Farm",
    Default = false,
    Callback = function(v)
        Farming = v
        if v then
            AutoLevelEnabled=false AutoRaidEnabled=false IsFarming=true
            FarmTarget=nil FarmLocked=false FarmLockedCF=nil
        else
            IsFarming=false FarmTarget=nil FarmLocked=false FarmLockedCF=nil
            UnlockPosition() SetNoclip(false)
            if GetToolType(SelectedToolName) ~= "FightingStyle" then
                local fp = GetToolFullPath(SelectedToolName)
                local bs = string.char(#fp,0,0,0)..fp.."\000\000\000\000\000"
                pcall(function() RequestSkill:FireServer(unpack({{ buffer=buffer.fromstring(bs), blobs={} }})) end)
            end
        end
    end,
})

FarmGroup:AddToggle("InstaKillToggleFarm", {
    Text    = "Insta Kill (Waits 16% on Farm, Instant on Raid)",
    Default = false,
    Callback = function(v) InstaKillEnabled = v end,
})

FarmGroup:AddToggle("AutoChestToggle", {
    Text    = "Auto Collect Chests",
    Default = false,
    Callback = function(v) AutoCollectBossChest = v end,
})

FarmGroup:AddSlider("DistanceSlider", {
    Text    = "Distance",
    Default = 5,
    Min     = 0,
    Max     = 20,
    Rounding = 0,
    Callback = function(v) Distance=v FarmLocked=false FarmLockedCF=nil end,
})

FarmGroup:AddDropdown("PosDropdown", {
    Text       = "Position Method",
    Values     = {"Above", "Behind", "Under"},
    Default    = 1,
    Searchable = true,
    Callback   = function(v)
        FarmPosition = v FarmLocked=false FarmLockedCF=nil
        if FarmPosition ~= "Under" then SetNoclip(false) end
    end,
})

--------------------------------------------------------------------------------
-- UI CONSTRUCTION — WEAPON GROUP
--------------------------------------------------------------------------------

WeaponGroup:AddToggle("AutoEquipToggle", {
    Text    = "Auto Equip Selected",
    Default = false,
    Callback = function(v) AutoEquipTool = v end,
})

local WeaponDropdown = WeaponGroup:AddDropdown("WeaponDropdown", {
    Text       = "Your Weapons",
    Values     = #ToolList > 0 and ToolList or {"Mantis Edge"},
    Default    = 1,
    Searchable = true,
    Callback   = function(v)
        SelectedToolName = v
        if AutoEquipTool and Character then
            local t = LocalPlayer.Backpack:FindFirstChild(SelectedToolName)
            if t then Character.Humanoid:EquipTool(t) end
        end
    end,
})

WeaponGroup:AddButton({
    Text = "Refresh Weapons",
    Func = function()
        ToolList = GetPlayerTools()
        WeaponDropdown:SetValues(#ToolList > 0 and ToolList or {"Mantis Edge"})
        Library:Notify({ Title = "Refreshed", Description = "Found "..#ToolList.." weapons.", Time = 2 })
    end,
})

--------------------------------------------------------------------------------
-- UI CONSTRUCTION — MOB SELECTION
--------------------------------------------------------------------------------

MobsGroup:AddDropdown("EnemyDropdown", {
    Text       = "Normal Enemies",
    Values     = RegularList,
    Multi      = true,
    Searchable = true,
    Callback = function(v)
        SelectedEnemyNames = {}
        for name, selected in pairs(v) do
            if selected then table.insert(SelectedEnemyNames, name) end
        end
        FarmTarget=nil FarmLocked=false FarmLockedCF=nil
    end,
})

MobsGroup:AddDropdown("BossDropdown", {
    Text       = "Bosses",
    Values     = BossList,
    Multi      = true,
    Searchable = true,
    Callback = function(v)
        SelectedBossNames = {}
        for name, selected in pairs(v) do
            if selected then table.insert(SelectedBossNames, name) end
        end
        FarmTarget=nil FarmLocked=false FarmLockedCF=nil
    end,
})

MobsGroup:AddDropdown("WorldBossDropdown", {
    Text       = "World Bosses",
    Values     = WorldBossList,
    Multi      = true,
    Searchable = true,
    Callback = function(v)
        SelectedWorldBossNames = {}
        for name, selected in pairs(v) do
            if selected then table.insert(SelectedWorldBossNames, name) end
        end
        FarmTarget=nil FarmLocked=false FarmLockedCF=nil
    end,
})

--------------------------------------------------------------------------------
-- UI CONSTRUCTION — AUTO JOIN RAID
--------------------------------------------------------------------------------

AutoJoinStatusLabel = AutoJoinRaidGroup:AddLabel("Status: Idle")

AutoJoinRaidGroup:AddDropdown("RaidNameDropdown", {
    Text       = "Select Raid",
    Values     = {"Zenin Massacre", "Death Painting Raid", "Maharagoa Raid", "Yuta Raid", "Toji Raid"},
    Default    = 1,
    Searchable = true,
    Callback   = function(v) SelectedRaidName = v end,
})

AutoJoinRaidGroup:AddDropdown("RaidDiffDropdown", {
    Text       = "Select Difficulty",
    Values     = {"Easy", "Normal", "Hard", "Extreme", "Nightmare"},
    Default    = 1,
    Searchable = true,
    Callback   = function(v) SelectedDiffName = v end,
})

AutoJoinRaidGroup:AddToggle("AutoJoinToggle", {
    Text    = "Auto Join Raid",
    Default = false,
    Callback = function(v)
        AutoJoinEnabled = v
        if v then
            if _AutoJoinLoopFn then
                task.spawn(_AutoJoinLoopFn)
                Library:Notify({ Title = "Auto Join", Description = "Scanning for empty zones...", Time = 2 })
            else
                AutoJoinEnabled = false
                Library:Notify({ Title = "Wrong Place", Description = "Go to the Raid Lobby first!", Time = 3 })
            end
        end
    end,
})

AutoJoinRaidGroup:AddToggle("AutoReplayToggle", {
    Text    = "Auto Replay Raid",
    Default = false,
    Callback = function(v)
        AutoReplayEnabled = v
        if v then
            Library:Notify({ Title = "Auto Replay", Description = "Will replay when rewards screen appears.", Time = 2 })
        end
    end,
})

--------------------------------------------------------------------------------
-- UI CONSTRUCTION — MISC
--------------------------------------------------------------------------------

StatsGroup:AddToggle("StatMelee",  { Text = "Auto Melee",        Default = false, Callback = function(v) AutoStats.Melee=v end })
StatsGroup:AddToggle("StatDef",    { Text = "Auto Defense",       Default = false, Callback = function(v) AutoStats.Defense=v end })
StatsGroup:AddToggle("StatStam",   { Text = "Auto Stamina",       Default = false, Callback = function(v) AutoStats.Stamina=v end })
StatsGroup:AddToggle("StatWep",    { Text = "Auto Weapon",        Default = false, Callback = function(v) AutoStats.Weapon=v end })
StatsGroup:AddToggle("StatCE",     { Text = "Auto Cursed Energy", Default = false, Callback = function(v) AutoStats.CursedEnergy=v end })

-- EGG GROUP
EggStatusLabel = EggGroup:AddLabel("Status: Idle")

EggGroup:AddToggle("AutoEggToggle", {
    Text    = "Auto Collect Eggs",
    Default = false,
    Callback = function(v)
        AutoEggEnabled = v
        if v then
            task.spawn(AutoEggLoop)
            Library:Notify({ Title = "Auto Eggs", Description = "Egg collection started!", Time = 2 })
        end
    end,
})

EggGroup:AddToggle("InstantPromptToggle", {
    Text    = "Instant Proximity Prompt",
    Default = true,
    Callback = function(v)
        InstantPromptEnabled = v
        Library:Notify({
            Title = "Instant Prompt",
            Description = v and "Enabled" or "Disabled",
            Time = 2
        })
    end,
})

--------------------------------------------------------------------------------
-- EASTER SHOP
--------------------------------------------------------------------------------

local EasterTab       = Window:AddTab("Easter Shop", "shopping-cart")
local ShopBuyGroup    = EasterTab:AddLeftGroupbox("Auto Buy")
local ShopStockGroup  = EasterTab:AddRightGroupbox("Stock Viewer")

local PURCHASE_SUFFIX = "8\000\003\000SFX\003\000set\001\002\000\000\000\000\000\000\240?8\000\005\000Music\003\000set\001\002\000\000\000\000\000\000\240?8\000\002\000UI\003\000set\001\002\000\000\000\000\000\000\240?"

local GLOBAL_ITEMS = {
    "bunnox_companion_accessory",
    "ears_of_light_accessory",
    "easter_bow_weapon",
    "easter_hammer_weapon",
    "eggcelent_crown_accessory",
    "eggcelent_necklace_accessory",
    "luminous_aegis_accessory",
    "luminous_bracers_accessory",
    "luminous_helmet_accessory",
    "radiant_aegis_accessory",
    "radiant_bracers_accessory",
    "radiant_halo_accessory",
    "radiant_helmet_accessory",
    "radiant_wings_accessory",
    "spirit_hare_mask_accessory",
    "world_boss_totem_artifact_global",
}

local LOCAL_ITEMS = {
    "crimson_yolk_elixir_booster",
    "egg_burst_potion_booster",
    "golden_yolk_elixir_booster",
    "spring_vitality_elixir_booster",
    "world_boss_totem_artifact_local",
}

local function BuildPurchasePacket(itemName)
    local len = #itemName
    local lenLo = len % 256
    local lenHi = math.floor(len / 256)
    return "G\000\001" .. string.char(lenLo, lenHi) .. itemName .. "\f\000PurchaseItem" .. PURCHASE_SUFFIX
end

local function BuyItem(itemName)
    local remote = GetCachedSyncRemote()
    if not remote then return false end
    pcall(function()
        remote:FireServer(buffer.fromstring(BuildPurchasePacket(itemName)))
    end)
end

local function OpenEasterShop()
    pcall(function()
        local canvasGroup = LocalPlayer.PlayerGui.Easter2026.CanvasGroup
        canvasGroup.Visible = true
        task.wait(0.1)
        canvasGroup.Main.Visible = true
    end)
end

local function CloseEasterShop()
    pcall(function()
        local canvasGroup = LocalPlayer.PlayerGui.Easter2026.CanvasGroup
        canvasGroup.Main.Visible = false
        canvasGroup.Visible = false
    end)
end

local function GetStockInfo(itemPath)
    local ok, result = pcall(function()
        local name  = itemPath.ItemLabel  and itemPath.ItemLabel.Text  or "?"
        local price = itemPath.PriceLabel and itemPath.PriceLabel.Text or "?"
        local stock = itemPath.StockLabel and itemPath.StockLabel.Text or "?"
        return name, price, stock
    end)
    if ok then return result end
    return "?", "?", "?"
end

local function GetTimerText(header)
    local ok, text = pcall(function() return header.ShadowLabel.Text end)
    return (ok and text) or "?"
end

-- State
local SelectedBuyItems  = {}
local AutoBuyEnabled    = false
local BuyAmount         = 1
local BuyDelay          = 0.5
local ShopStatusLabel   = nil
local StockLabels       = {}

-- Status label
ShopStatusLabel = ShopBuyGroup:AddLabel("Status: Idle")

-- Item selection dropdowns
ShopBuyGroup:AddDropdown("GlobalItemsDrop", {
    Text      = "Global Stock Items",
    Values    = GLOBAL_ITEMS,
    Multi     = true,
    Searchable = true,
    AllowNull = true,
    Callback  = function(val)
        -- clear global selections then re-add
        for _, v in ipairs(GLOBAL_ITEMS) do
            SelectedBuyItems[v] = nil
        end
        if type(val) == "table" then
            for name, selected in pairs(val) do
                if selected then SelectedBuyItems[name] = true end
            end
        end
    end,
})

ShopBuyGroup:AddDropdown("LocalItemsDrop", {
    Text      = "Local Stock Items",
    Values    = LOCAL_ITEMS,
    Multi     = true,
    Searchable = true,
    AllowNull = true,
    Callback  = function(val)
        for _, v in ipairs(LOCAL_ITEMS) do
            SelectedBuyItems[v] = nil
        end
        if type(val) == "table" then
            for name, selected in pairs(val) do
                if selected then SelectedBuyItems[name] = true end
            end
        end
    end,
})

ShopBuyGroup:AddSlider("BuyAmountSlider", {
    Text     = "Buy Amount (per item)",
    Default  = 1,
    Min      = 1,
    Max      = 50,
    Rounding = 0,
    Callback = function(v) BuyAmount = v end,
})

ShopBuyGroup:AddSlider("BuyDelaySlider", {
    Text     = "Delay Between Purchases (s)",
    Default  = 0.5,
    Min      = 0.1,
    Max      = 3,
    Rounding = 1,
    Callback = function(v) BuyDelay = v end,
})

-- Manual buy button
ShopBuyGroup:AddButton({
    Text = "Buy Selected Now",
    Func = function()
        task.spawn(function()
            local items = {}
            for name, _ in pairs(SelectedBuyItems) do
                table.insert(items, name)
            end
            if #items == 0 then
                Library:Notify({ Title = "Easter Shop", Description = "No items selected!", Time = 2 })
                return
            end
            pcall(function() ShopStatusLabel:SetText("Status: Buying...") end)
            for _, itemName in ipairs(items) do
                for i = 1, BuyAmount do
                    BuyItem(itemName)
                    pcall(function()
                        ShopStatusLabel:SetText("Buying: " .. itemName .. " (" .. i .. "/" .. BuyAmount .. ")")
                    end)
                    task.wait(BuyDelay)
                end
            end
            pcall(function() ShopStatusLabel:SetText("Status: Done!") end)
            Library:Notify({ Title = "Easter Shop", Description = "Purchase complete!", Time = 2 })
        end)
    end,
})

-- Auto buy toggle (loops until stock runs out or toggled off)
ShopBuyGroup:AddToggle("AutoBuyToggle", {
    Text    = "Auto Buy",
    Default = false,
    Callback = function(v)
        AutoBuyEnabled = v
        if v then
            task.spawn(function()
                while AutoBuyEnabled do
                    local items = {}
                    for name, _ in pairs(SelectedBuyItems) do
                        table.insert(items, name)
                    end
                    if #items == 0 then
                        pcall(function() ShopStatusLabel:SetText("Status: No items selected!") end)
                        task.wait(1)
                        continue
                    end
                    for _, itemName in ipairs(items) do
                        if not AutoBuyEnabled then break end
                        for i = 1, BuyAmount do
                            if not AutoBuyEnabled then break end
                            BuyItem(itemName)
                            pcall(function()
                                ShopStatusLabel:SetText("Auto Buying: " .. itemName .. " (" .. i .. "/" .. BuyAmount .. ")")
                            end)
                            task.wait(BuyDelay)
                        end
                    end
                    task.wait(1)
                end
                pcall(function() ShopStatusLabel:SetText("Status: Idle") end)
            end)
        else
            pcall(function() ShopStatusLabel:SetText("Status: Idle") end)
        end
    end,
})

-- ── STOCK VIEWER ──────────────────────────────────────────────────────────────

local GlobalTimerLabel = ShopStockGroup:AddLabel("Global Reset: ?")
local LocalTimerLabel  = ShopStockGroup:AddLabel("Local Reset: ?")
ShopStockGroup:AddLabel("─── Global Stock ───")

local globalStockLabels = {}
for _, item in ipairs(GLOBAL_ITEMS) do
    globalStockLabels[item] = ShopStockGroup:AddLabel(item .. " | ...")
end

ShopStockGroup:AddLabel("─── Local Stock ───")
local localStockLabels = {}
for _, item in ipairs(LOCAL_ITEMS) do
    localStockLabels[item] = ShopStockGroup:AddLabel(item .. " | ...")
end

ShopStockGroup:AddButton({
    Text = "Refresh Stock",
    Func = function()
        task.spawn(function()
            OpenEasterShop()
            task.wait(0.3)

            pcall(function()
                local base = LocalPlayer.PlayerGui.Easter2026.CanvasGroup.Main.Body.Content

                -- timers
                local gt = GetTimerText(base.Global.Header)
                local lt = GetTimerText(base.Local.Header)
                GlobalTimerLabel:SetText("Global Reset: " .. gt)
                LocalTimerLabel:SetText("Local Reset: " .. lt)

                -- global items
                for _, item in ipairs(GLOBAL_ITEMS) do
                    local ok, price, stock = pcall(function()
                        local el = base.Global.Items[item]
                        return el.PriceLabel.Text, el.StockLabel.Text
                    end)
                    if ok then
                        globalStockLabels[item]:SetText(item .. " | " .. price .. " | Stock: " .. stock)
                    else
                        globalStockLabels[item]:SetText(item .. " | N/A")
                    end
                end

                -- local items
                for _, item in ipairs(LOCAL_ITEMS) do
                    local ok, price, stock = pcall(function()
                        local el = base.Local.Items[item]
                        return el.PriceLabel.Text, el.StockLabel.Text
                    end)
                    if ok then
                        localStockLabels[item]:SetText(item .. " | " .. price .. " | Stock: " .. stock)
                    else
                        localStockLabels[item]:SetText(item .. " | N/A")
                    end
                end
            end)

            CloseEasterShop()
        end)
    end,
})

-- Auto countdown timer updater
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local base = LocalPlayer.PlayerGui.Easter2026.CanvasGroup.Main.Body.Content
            local gt = GetTimerText(base.Global.Header)
            local lt = GetTimerText(base.Local.Header)
            GlobalTimerLabel:SetText("Global Reset: " .. gt)
            LocalTimerLabel:SetText("Local Reset: " .. lt)
        end)
    end
end)

-- CHEST GROUP
ChestGroup:AddButton({
    Text = "Teleport to Chests (Manual)",
    Func = function()
        task.spawn(function()
            local ef = Workspace:FindFirstChild("Effects") if not ef then return end
            local char = GetCharacter() if not char then return end
            local hrp = char.HumanoidRootPart
            for _, v in pairs(ef:GetDescendants()) do
                if v.Name:find("Chest") then
                    if v:IsA("BasePart") then
                        hrp.CFrame = v.CFrame + Vector3.new(0,3,0) task.wait(1)
                    elseif v:IsA("Model") and v:FindFirstChildWhichIsA("BasePart") then
                        hrp.CFrame = v:FindFirstChildWhichIsA("BasePart").CFrame + Vector3.new(0,3,0) task.wait(1)
                    end
                end
            end
        end)
    end,
})

StaminaGroup:AddToggle("InfStamina", {
    Text    = "Infinite Stamina (Dash/Jump)",
    Default = false,
    Callback = function(v)
        InfiniteStaminaEnabled = v
        StaminaRemote = GetCachedSyncRemote()
    end,
})

SpeedGroup:AddToggle("SpeedToggle", {
    Text    = "Speed Changer",
    Default = false,
    Callback = function(v)
        SpeedEnabled = v
        if v then
            ApplySpeed()
            Library:Notify({ Title = "Speed", Description = "Speed enabled ("..SpeedValue.." studs/s)", Time = 2 })
        else
            SpeedEnabled = false
            Library:Notify({ Title = "Speed", Description = "Speed disabled.", Time = 2 })
        end
    end,
})

SpeedGroup:AddSlider("SpeedSlider", {
    Text     = "Speed Value",
    Default  = 50,
    Min      = 16,
    Max      = 300,
    Rounding = 0,
    Callback = function(v) SpeedValue = v end,
})

ServerGroup:AddButton({
    Text = "Rejoin Server",
    Func = function()
        Library:Notify({ Title = "Rejoining...", Time = 2 })
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

CreditsGroup:AddButton({
    Text = "Copy Discord Link",
    Func = function()
        setclipboard("https://discord.gg/Mf6tXaRgUa")
        Library:Notify({ Title = "Discord", Description = "Invite copied!", Time = 3 })
    end,
})

CreditsGroup:AddButton({
    Text = "Unload Script",
    Func = function()
        pcall(function()
            IsFarming = false
            AutoLevelEnabled = false
            AutoRaidEnabled = false
            AutoEggEnabled = false
            Farming = false
            UnlockPosition()
            SetNoclip(false)
            if SpeedConnection then SpeedConnection:Disconnect() SpeedConnection = nil end
        end)
        Library:Unload()
    end,
})

local MenuGroup = Tabs.UISettings:AddLeftGroupbox("Menu")
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI    = true,
    Text    = "Menu keybind",
})
Library.ToggleKeybind = Library.Options.MenuKeybind

local AutoCloseUI = false

MenuGroup:AddToggle("AutoCloseUIToggle", {
    Text    = "Auto Close UI on Execute",
    Default = false,
    Callback = function(v) AutoCloseUI = v end,
})

-- Auto close UI once on load if toggled
task.spawn(function()
    task.wait(2) -- wait for UI to fully load
    if AutoCloseUI or (Library.Options.AutoCloseUIToggle and Library.Options.AutoCloseUIToggle.Value) then
        Library:SetOpen(false)
    end
end)
--------------------------------------------------------------------------------
-- MAIN RENDERSTEPPED
--------------------------------------------------------------------------------

RunService.RenderStepped:Connect(function()
    local char = GetCharacter()
    if not char then return end

    if (Farming or AutoLevelEnabled or AutoRaidEnabled) and AutoEquipTool then
        local activeTool = GetActiveTool()
        if activeTool then
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if bp then
                local tool = bp:FindFirstChild(activeTool)
                if tool then char.Humanoid:EquipTool(tool) end
            end
        end
    end

    if Farming then
        local hasAny = #SelectedEnemyNames > 0 or #SelectedBossNames > 0 or #SelectedWorldBossNames > 0
        if not hasAny then
            IsFarming = false
            return
        end

        if AutoCollectBossChest then
            local ef = Workspace:FindFirstChild("Effects")
            if ef then
                local chest = ef:FindFirstChild("TestChest")
                if not chest then
                    for _, c in ipairs(ef:GetChildren()) do
                        if c.Name:match("^TestChest") then chest=c break end
                    end
                end
                if chest then
                    IsFarming=false FarmTarget=nil FarmLocked=false FarmLockedCF=nil
                    UnlockPosition()
                    if chest:IsA("BasePart") then
                        char.HumanoidRootPart.CFrame = chest.CFrame + Vector3.new(0,3,0)
                    elseif chest:IsA("Model") then
                        char.HumanoidRootPart.CFrame = chest:GetPivot() + Vector3.new(0,3,0)
                    end
                    return
                end
            end
        end

        if FarmTarget and not IsTargetValid(FarmTarget) then
            FarmTarget=nil FarmLocked=false FarmLockedCF=nil
            UnlockPosition()
        end

        if not FarmTarget then
            FarmTarget = FindPriorityTarget()
            FarmLocked = false
            FarmLockedCF = nil
            if not FarmTarget then
                IsFarming = false
                UnlockPosition()
                return
            end
        end

        IsFarming = true
    end

    if (Farming or AutoLevelEnabled) and FarmTarget then
        FarmTick(FarmPosition, Distance)
    elseif not Farming and not AutoLevelEnabled and not AutoRaidEnabled then
        UnlockPosition() SetNoclip(false)
    end
end)

--------------------------------------------------------------------------------
-- BACKGROUND LEVEL UPDATER
--------------------------------------------------------------------------------

task.spawn(function()
    while true do
        task.wait(1)
        if not AutoLevelEnabled then
            pcall(function()
                if AL_LevelLabel then AL_LevelLabel:SetText("Level: "..tostring(GetLevel())) end
            end)
        end
    end
end)

--------------------------------------------------------------------------------
-- CHARACTER RESPAWN
--------------------------------------------------------------------------------

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character=newChar FarmTarget=nil FarmLocked=false FarmLockedCF=nil
    ActiveBV=nil ActiveBG=nil SetNoclip(false)
    if AutoLevelEnabled then AL_CurrentQuest=nil AL_ForceRefresh=true end
    task.wait(1)
    ApplySpeed()
end)

--------------------------------------------------------------------------------
-- RAID FIGHT LOGIC
--------------------------------------------------------------------------------

if IS_RAID_FIGHT then

    local RaidAutoEquip    = true
    local RaidDistance     = 5
    local RaidFarmPosition = "Above"
    local RaidStatusLabel  = nil
    local RaidObjectiveLabel = nil
    local RaidProgressLabel  = nil

    local function GetRaidObjective()
        local ok, text = pcall(function()
            return LocalPlayer.PlayerGui.HUD.HUDContainer.Top.Top.Objective.DisplayLabel.Text
        end)
        if ok and type(text) == "string" then
            return text:gsub("<[^>]+>", ""):match("^%s*(.-)%s*$") or text
        end
        return "No Objective"
    end

    local function GetRaidProgress()
        local ok, text = pcall(function()
            return LocalPlayer.PlayerGui.HUD.HUDContainer.Top.Top.Lower.Quest.Progress.DisplayLabel.Text
        end)
        return (ok and type(text) == "string") and text or ""
    end

       local function HandleRaidSpecifics()
        local obj = GetRaidObjective()
        if not obj then return end
        local char = GetCharacter()
        if not char or not char.PrimaryPart then return end
        local root = char.PrimaryPart

        if string.find(obj, "Explore the Zenin Household") then
            root.CFrame = CFrame.new(3, 997, 3540)
        elseif string.find(obj, "Defeat the Zenin Sorcerers") then
            if (root.Position - Vector3.new(1, 1043, 2415)).Magnitude > 10 then
                root.CFrame = CFrame.new(1, 1043, 2415)
            end
        elseif string.find(obj, "Defeat Maki") then
            if (root.Position - Vector3.new(589, 997, 3933)).Magnitude > 10 then
                root.CFrame = CFrame.new(589, 997, 3933)
            end
        elseif string.find(obj, "Defeat Kezichu") then
            if (root.Position - Vector3.new(-4016, 2068, 85)).Magnitude > 10 then
                root.CFrame = CFrame.new(-4016, 2068, 85)
            end
        elseif string.find(obj, "Defeat Megumi") then
            if (root.Position - Vector3.new(276, 926, -5068)).Magnitude > 10 then
                root.CFrame = CFrame.new(276, 926, -5068)
            end
        elseif string.find(obj, "Defeat Yuta") then
            if (root.Position - Vector3.new(4808, 88, 376)).Magnitude > 10 then
                root.CFrame = CFrame.new(4808, 88, 376)
            end
        elseif string.find(obj, "Eliminate all Time Vessel Associates") then
            -- Enemies spawn instantly, no teleport needed — just farm
        elseif string.find(obj, "Enraged Toji") then
            if (root.Position - Vector3.new(13449, 88, 1914)).Magnitude > 10 then
                root.CFrame = CFrame.new(13449, 88, 1914)
            end
        elseif string.find(obj, "Pursue Toji into the forest clearing") then
            if (root.Position - Vector3.new(13449, 88, 1914)).Magnitude > 10 then
                root.CFrame = CFrame.new(13449, 88, 1914)
            end
        elseif string.find(obj, "Defeat Toji") then
            if (root.Position - Vector3.new(13433, 88, 906)).Magnitude > 10 then
                root.CFrame = CFrame.new(13433, 88, 906)
            end
        end
    end

    local function RaidFarmTick()
        if not FarmTarget or not FarmTarget.Parent then
            FarmTarget=nil FarmLocked=false FarmLockedCF=nil
            IsFarming=false UnlockPosition() return
        end
        local hum = FarmTarget:FindFirstChild("Humanoid")
        if not InstaKillEnabled and hum and hum.Health <= 0 then
            FarmTarget=nil FarmLocked=false FarmLockedCF=nil
            IsFarming=false UnlockPosition() return
        end
        local char = GetCharacter()
        if not char then return end
        local goalCF = ComputeGoalCFrame(GetEnemyCFrame(FarmTarget), RaidFarmPosition, RaidDistance)
        if RaidFarmPosition == "Under" then SetNoclip(true) else SetNoclip(false) end
        LockPosition(goalCF)
        FarmLocked=true FarmLockedCF=goalCF
        IsFarming = true
    end

    task.spawn(function()
        while true do
            task.wait(1)
            if not AutoRaidEnabled then continue end
            if FarmTarget and FarmTarget.Parent then continue end
            local enemy = FindAnyEnemy(nil)
            if enemy then
                FarmTarget = enemy
                FarmLocked = false FarmLockedCF = nil
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if not AutoRaidEnabled then return end
        local char = GetCharacter()
        if not char then return end

        if RaidAutoEquip and RaidSelectedToolName then
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if bp then
                local tool = bp:FindFirstChild(RaidSelectedToolName)
                if tool then char.Humanoid:EquipTool(tool) end
            end
        end

        -- ALWAYS handle teleports first, regardless of enemies
        HandleRaidSpecifics()

        if FarmTarget and FarmTarget.Parent then
            local hum = FarmTarget:FindFirstChild("Humanoid")
            if not InstaKillEnabled and hum and hum.Health <= 0 then
                FarmTarget=nil FarmLocked=false FarmLockedCF=nil
            end
        end

        if not FarmTarget or not FarmTarget.Parent then
            FarmTarget=FindAnyEnemy(nil) FarmLocked=false FarmLockedCF=nil
        end

        if FarmTarget then
            RaidFarmTick()
            IsFarming = true
            if RaidStatusLabel then
                pcall(function()
                    RaidStatusLabel:SetText("Farming: "..tostring(FarmTarget:GetAttribute("EnemyName") or "Enemy"))
                end)
            end
        else
            IsFarming = false
            UnlockPosition()
            if RaidStatusLabel then
                pcall(function() RaidStatusLabel:SetText("Waiting for boss...") end)
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.5)
            if AutoRaidEnabled then
                local obj  = GetRaidObjective()
                local prog = GetRaidProgress()
                if RaidObjectiveLabel then pcall(function() RaidObjectiveLabel:SetText("Obj: "..obj) end) end
                if RaidProgressLabel and prog ~= "" then pcall(function() RaidProgressLabel:SetText("Progress: "..prog) end) end
            end
        end
    end)

    local RaidFarmGroup   = Tabs.Raid:AddLeftGroupbox("Raid Auto Farm")
    local RaidInfoGroup   = Tabs.Raid:AddLeftGroupbox("Raid Info")
    local RaidWeaponGroup = Tabs.Raid:AddRightGroupbox("Weapon")
    local RaidSetGroup    = Tabs.Raid:AddRightGroupbox("Farm Settings")

    RaidStatusLabel    = RaidInfoGroup:AddLabel("Status: Idle")
    RaidObjectiveLabel = RaidInfoGroup:AddLabel("Obj: --")
    RaidProgressLabel  = RaidInfoGroup:AddLabel("Progress: --")

    RaidFarmGroup:AddToggle("RaidFarmToggle", {
        Text    = "Auto Raid Farm",
        Default = false,
        Callback = function(v)
            AutoRaidEnabled = v
            if v then
                Farming=false AutoLevelEnabled=false IsFarming=false
                FarmTarget=nil FarmLocked=false FarmLockedCF=nil
                Library:Notify({ Title = "Auto Raid", Description = "Raid farming started!", Time = 2 })
            else
                IsFarming=false FarmTarget=nil FarmLocked=false FarmLockedCF=nil
                UnlockPosition() SetNoclip(false)
                if RaidStatusLabel then pcall(function() RaidStatusLabel:SetText("Status: Idle") end) end
            end
        end,
    })

    RaidFarmGroup:AddToggle("InstaKillToggleRaid", {
        Text    = "Insta Kill (Instant in Raid)",
        Default = false,
        Callback = function(v) InstaKillEnabled = v end,
    })

    RaidWeaponGroup:AddToggle("RaidAutoEquipToggle", {
        Text    = "Auto Equip Selected",
        Default = true,
        Callback = function(v) RaidAutoEquip = v end,
    })

    local RaidToolList = GetPlayerTools()
    RaidSelectedToolName = RaidToolList[1] or "Mantis Edge"

    local RaidWeaponDropdown = RaidWeaponGroup:AddDropdown("RaidWeaponDropdown", {
        Text       = "Weapon",
        Values     = #RaidToolList > 0 and RaidToolList or {"Mantis Edge"},
        Default    = 1,
        Searchable = true,
        Callback   = function(v)
            RaidSelectedToolName = v
            if RaidAutoEquip and Character then
                local t = LocalPlayer.Backpack:FindFirstChild(RaidSelectedToolName)
                if t then Character.Humanoid:EquipTool(t) end
            end
        end,
    })

    RaidWeaponGroup:AddButton({
        Text = "Refresh Weapons",
        Func = function()
            RaidToolList = GetPlayerTools()
            RaidWeaponDropdown:SetValues(#RaidToolList > 0 and RaidToolList or {"Mantis Edge"})
            Library:Notify({ Title = "Refreshed", Description = "Found "..#RaidToolList.." weapons.", Time = 2 })
        end,
    })

    RaidSetGroup:AddSlider("RaidDistSlider", {
        Text     = "Distance",
        Default  = 5,
        Min      = 0,
        Max      = 20,
        Rounding = 0,
        Callback = function(v) RaidDistance=v FarmLocked=false FarmLockedCF=nil end,
    })

    RaidSetGroup:AddDropdown("RaidPosDropdown", {
        Text       = "Position Method",
        Values     = {"Above", "Behind", "Under"},
        Default    = 1,
        Searchable = true,
        Callback   = function(v)
            RaidFarmPosition = v FarmLocked=false FarmLockedCF=nil
            if RaidFarmPosition ~= "Under" then SetNoclip(false) end
        end,
    })

end -- END IS_RAID_FIGHT

--------------------------------------------------------------------------------
-- RAID LOBBY
--------------------------------------------------------------------------------

if game.PlaceId == 116332986653377 then

    local PACKET_SUFFIX = ">\000\005\000Music\003\000set\001\002\000\000\000\000\000\000\240?>\000\002\000UI\003\000set\001\002\000\000\000\000\000\000\240?>\000\003\000SFX\003\000set\001\002\000\000\000\000\000\000\240?"

    local function U16(n)
        return string.char(n % 256, math.floor(n / 256))
    end

local RAID_IDS = {
    ["Sugisawa Incident"]   = "SchoolRaid",
    ["Death Painting Raid"] = "Choso",
    ["Zenin Massacre"]      = "Zenin",
    ["Maharagoa Raid"]      = "MahoragaRaid",
    ["Yuta Raid"]           = "YutaRaid",
    ["Toji Raid"]           = "TojiRaid",
}

    local function BuildRaidPacket(raidName, difficulty, actionType)
        local raidId = RAID_IDS[raidName]
        if not raidId then return nil end
        local p = "6\000"
        p = p .. U16(#difficulty) .. difficulty
        p = p .. "\001\000"
        p = p .. U16(#raidId) .. raidId
        p = p .. U16(#actionType) .. actionType .. "\000"
        p = p .. PACKET_SUFFIX
        return p
    end

    local function FireRaidRemote(bufStr)
        local SR = GetCachedSyncRemote()
        if not SR then return end
        pcall(function() SR:FireServer(buffer.fromstring(bufStr)) end)
    end

    local function FindEmptyZone()
        local ok, raidZones = pcall(function() return Workspace.StreamExclusions.RaidZones end)
        if not ok or not raidZones then return nil, nil end
        local empty = {}
        for _, zone in ipairs(raidZones:GetChildren()) do
            local isOk, isEmpty = pcall(function()
                local body = zone.GUI.SurfaceGui.RaidLobby.PlayerList.Body
                for _, child in ipairs(body:GetChildren()) do
                    if child.Name == "PlayerTemplate" then return false end
                end
                return true
            end)
            if isOk and isEmpty then
                local zonePart = zone:FindFirstChild("Zone") and zone.Zone:FindFirstChild("ZonePart")
                if zonePart then table.insert(empty, { zone=zone, zonePart=zonePart }) end
            end
        end
        if #empty == 0 then return nil, nil end
        local pick = empty[math.random(1, #empty)]
        return pick.zone, pick.zonePart
    end

    local function IsRaidBodyVisible()
        local ok, vis = pcall(function() return LocalPlayer.PlayerGui.Raid.Container.Body.Visible end)
        return ok and vis == true
    end

    local function SetStatus(txt)
        if AutoJoinStatusLabel then
            pcall(function() AutoJoinStatusLabel:SetText("Status: "..txt) end)
        end
    end

    local function AutoJoinLoop()
        while AutoJoinEnabled do
            task.wait(0.5)
            if not AutoJoinEnabled then break end

            local char = GetCharacter()
            if not char then
                SetStatus("Waiting for character...")
                task.wait(1)
                continue
            end

            local confirmPacket = BuildRaidPacket(SelectedRaidName, SelectedDiffName, "Confirm")
            local startPacket   = BuildRaidPacket(SelectedRaidName, SelectedDiffName, "Start")
            local updatePacket  = BuildRaidPacket(SelectedRaidName, SelectedDiffName, "Update")

            if not confirmPacket or not startPacket then
                SetStatus("Invalid Raid/Diff selection!")
                task.wait(2)
                continue
            end

            SetStatus("Scanning for empty zone...")
            local _, zonePart = FindEmptyZone()
            if not zonePart then
                SetStatus("No empty zones, retrying in 3s...")
                task.wait(3)
                continue
            end

            SetStatus("Teleporting to zone...")
            local teleportAttempts = 0
            repeat
                char = GetCharacter()
                if not char then break end
                char.HumanoidRootPart.CFrame = zonePart.CFrame + Vector3.new(0, 4, 0)
                task.wait(0.8)
                teleportAttempts += 1
            until IsRaidBodyVisible() or teleportAttempts >= 5 or not AutoJoinEnabled

            if not AutoJoinEnabled then break end

            if not IsRaidBodyVisible() then
                SetStatus("UI never appeared, retrying...")
                task.wait(2)
                continue
            end

            if updatePacket then
                SetStatus("Setting difficulty: " .. SelectedDiffName)
                FireRaidRemote(updatePacket)
                task.wait(0.6)
                if not AutoJoinEnabled then break end
            end

            SetStatus("Confirming: " .. SelectedRaidName .. " [" .. SelectedDiffName .. "]")
            FireRaidRemote(confirmPacket)
            task.wait(0.6)
            if not AutoJoinEnabled then break end

            SetStatus("Starting: " .. SelectedRaidName .. " [" .. SelectedDiffName .. "]")
            FireRaidRemote(startPacket)
            task.wait(0.3)
            FireRaidRemote(startPacket)
            task.wait(1)

            local waitedForLoad = 0
            repeat
                task.wait(0.5)
                waitedForLoad += 0.5
                SetStatus("Waiting for raid to start... (" .. waitedForLoad .. "s)")
            until not AutoJoinEnabled or waitedForLoad >= 10

            if AutoJoinEnabled then
                SetStatus("Start may have failed, retrying...")
                task.wait(2)
            end
        end

        SetStatus("Idle")
    end

    _AutoJoinLoopFn  = AutoJoinLoop
    _AutoStartLoopFn = nil

end

local function FireReplay()
    local SR = GetCachedSyncRemote()
    if not SR then return end
    pcall(function()
        SR:FireServer(buffer.fromstring("\b\000\006\000Replay:\000\005\000Music\003\000set\001\002\000\000\000\000\000\000\240?:\000\002\000UI\003\000set\001\002\000\000\000\000\000\000\240?:\000\003\000SFX\003\000set\001\002\000\000\000\000\000\000\240?"))
    end)
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if not AutoReplayEnabled then continue end
        local ok, visible = pcall(function()
            return LocalPlayer.PlayerGui.RaidRewards.CanvasGroup.Visible
        end)
        if ok and visible then
            task.wait(1)
            FireReplay()
            task.wait(2)
        end
    end
end)

--------------------------------------------------------------------------------
-- MAIN GAME — Teleport to Raid Lobby
--------------------------------------------------------------------------------

if game.PlaceId == 17662297954 then

    local TeleportStatusLabel = AutoJoinRaidGroup:AddLabel("Status: Idle")
    local AutoTpRaidEnabled = false

    AutoJoinRaidGroup:AddToggle("AutoTpRaidToggle", {
        Text    = "Auto Join Raid (Teleport to Lobby)",
        Default = false,
        Callback = function(v)
            AutoTpRaidEnabled = v
            if v then
                pcall(function() TeleportStatusLabel:SetText("Status: Teleporting to Raid Lobby...") end)
                Library:Notify({ Title = "Auto Join Raid", Description = "Teleporting to Raid Lobby...", Time = 3 })
                task.spawn(function()
                    task.wait(1)
                    local success, err = pcall(function()
                        TeleportService:Teleport(116332986653377, LocalPlayer)
                    end)
                    if not success then
                        AutoTpRaidEnabled = false
                        pcall(function() TeleportStatusLabel:SetText("Status: Teleport Failed — "..tostring(err)) end)
                        Library:Notify({ Title = "Teleport Failed", Description = tostring(err), Time = 4 })
                    end
                end)
            else
                pcall(function() TeleportStatusLabel:SetText("Status: Idle") end)
            end
        end,
    })

end

--------------------------------------------------------------------------------
-- SAVE / THEME MANAGER + FINAL SETUP
--------------------------------------------------------------------------------

Library:OnUnload(function()
    pcall(function()
        IsFarming = false
        AutoLevelEnabled = false
        AutoRaidEnabled = false
        AutoEggEnabled = false
        Farming = false
        UnlockPosition()
        SetNoclip(false)
        if SpeedConnection then SpeedConnection:Disconnect() SpeedConnection = nil end
    end)
end)

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("CrazyHub/Kaizen")
SaveManager:BuildConfigSection(Tabs.UISettings)
ThemeManager:ApplyToTab(Tabs.UISettings)

SaveManager:LoadAutoloadConfig()
ThemeManager:LoadDefault()
task.spawn(function()
    task.wait(1.5)
    if Library.Options.AutoCloseUIToggle and Library.Options.AutoCloseUIToggle.Value then
        Library:SetOpen(false)
    end
end)

setclipboard("https://discord.gg/Mf6tXaRgUa")
