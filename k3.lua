local ReplicatedStorage, Workspace, RunService, Players =
    game:GetService("ReplicatedStorage"), game:GetService("Workspace"),
    game:GetService("RunService"),        game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/habibrodriguez7-art/newGui/refs/heads/main/10.lua"))()

_G.EventResolver = (function()
    local self = {
        _isInitialized = false,
        _remoteEvents   = {},
        _remoteFunctions = {},
        _netFolder      = nil,
    }

    local function isHashString(name)
        return #name >= 32 and name:match("^[0-9a-f]+$") ~= nil
    end
    local function stripPrefix(name)
        return name:match("^[A-Z]+/(.+)$") or name
    end

    local function findNetFolder()
        if self._netFolder and self._netFolder.Parent then
            return self._netFolder
        end
        local success, netFolder = pcall(function()
            return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
        end)
        if success and netFolder then
            self._netFolder = netFolder
            return netFolder
        end

        local packagesFolder = ReplicatedStorage:FindFirstChild("Packages")
        local indexFolder    = packagesFolder and packagesFolder:FindFirstChild("_Index")
        if not indexFolder then return nil end

        for _, child in ipairs(indexFolder:GetChildren()) do
            if child.Name:lower():find("net") then
                local found = child:FindFirstChild("net") or child:FindFirstChild("Net")
                if found then
                    self._netFolder = found
                    return found
                end
            end
        end
    end

    local function scanNetFolder(netFolder)
        local children = netFolder:GetChildren()
        local index = 1

        while index <= #children do
            local current = children[index]
            local next    = children[index + 1]
            local currentName = stripPrefix(current.Name)

            if next then
                local nextName = stripPrefix(next.Name)
                if current.ClassName == next.ClassName
                    and not isHashString(currentName)
                    and isHashString(nextName)
                then
                    if current:IsA("RemoteFunction") then
                        self._remoteFunctions[currentName] = next
                    elseif current:IsA("RemoteEvent") or current:IsA("UnreliableRemoteEvent") then
                        self._remoteEvents[currentName] = next
                    end
                    index += 2
                    continue
                end
            end

            if not isHashString(currentName) then
                if current:IsA("RemoteFunction") and not self._remoteFunctions[currentName] then
                    self._remoteFunctions[currentName] = current
                elseif (current:IsA("RemoteEvent") or current:IsA("UnreliableRemoteEvent"))
                    and not self._remoteEvents[currentName]
                then
                    self._remoteEvents[currentName] = current
                end
            end

            index += 1
        end
    end

    function self:Init()
        if self._isInitialized then return true end

        local netFolder = findNetFolder()
        if not netFolder then
            warn("[EventResolver] Folder Net tidak ditemukan!")
            return false
        end

        self._remoteEvents    = {}
        self._remoteFunctions = {}
        scanNetFolder(netFolder)

        self._isInitialized = true
        _G.ResolvedNetEvents = {
            RemoteEvents    = self._remoteEvents,
            RemoteFunctions = self._remoteFunctions,
        }
        return true
    end

    function self:GetRemoteFunction(name)
        if not self._isInitialized then self:Init() end
        if not self._remoteFunctions[name] then
            local netFolder = findNetFolder()
            if netFolder then scanNetFolder(netFolder) end
        end
        return self._remoteFunctions[name]
    end

    function self:GetRemoteEvent(name)
        if not self._isInitialized then self:Init() end
        if not self._remoteEvents[name] then
            local netFolder = findNetFolder()
            if netFolder then scanNetFolder(netFolder) end
        end
        return self._remoteEvents[name]
    end

    function self:Reset()
        self._isInitialized  = false
        self._netFolder       = nil
        self._remoteEvents    = {}
        self._remoteFunctions = {}
    end

    function self:IsReady()     return self._isInitialized end
    function self:GetNetFolder() return findNetFolder() end

    self:Init()
    return self
end)()

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(3)
    _G.EventResolver:Reset()
    task.spawn(function()
        _G.EventResolver:Init()
    end)
end)

local NetEvents = setmetatable({}, {
    __index = function(_, key)
        local remoteMap = {
            RF_ChargeFishingRod        = function() return _G.EventResolver:GetRemoteFunction("ChargeFishingRod") end,
            RF_RequestMinigame         = function() return _G.EventResolver:GetRemoteFunction("RequestFishingMinigameStarted") end,
            RF_CancelFishingInputs     = function() return _G.EventResolver:GetRemoteFunction("CancelFishingInputs") end,
            RF_UpdateAutoFishingState  = function() return _G.EventResolver:GetRemoteFunction("UpdateAutoFishingState") end,
            RF_InitiateTrade           = function() return _G.EventResolver:GetRemoteFunction("InitiateTrade") end,
            RF_AwaitTradeResponse      = function() return _G.EventResolver:GetRemoteFunction("AwaitTradeResponse") end,
            RF_ConsumePotion           = function() return _G.EventResolver:GetRemoteFunction("ConsumePotion") end,
            RF_PurchaseCharm           = function() return _G.EventResolver:GetRemoteFunction("PurchaseCharm") end,
            RF_SellItem                = function() return _G.EventResolver:GetRemoteFunction("SellItem") end,
            RF_SellAllItems            = function() return _G.EventResolver:GetRemoteFunction("SellAllItems") end,
            RE_FishingCompleted        = function() return _G.EventResolver:GetRemoteEvent("CatchFishCompleted") end,
            RE_UpdateChargeState       = function() return _G.EventResolver:GetRemoteEvent("UpdateChargeState") end,
            RE_MinigameChanged         = function() return _G.EventResolver:GetRemoteEvent("FishingMinigameChanged") end,
            RF_MinigameChange          = function() return _G.EventResolver:GetRemoteEvent("FishingMinigameChanged") end,
            RE_FishCaught              = function() return _G.EventResolver:GetRemoteEvent("FishCaught") end,
            RE_FishingStopped          = function() return _G.EventResolver:GetRemoteEvent("FishingStopped") end,
            RE_FavoriteItem            = function() return _G.EventResolver:GetRemoteEvent("FavoriteItem") end,
            RE_EquipItem               = function() return _G.EventResolver:GetRemoteEvent("EquipItem") end,
            RF_EquipToolFromHotbar     = function() return _G.EventResolver:GetRemoteEvent("EquipToolFromHotbar") end,
            RE_ActivateEnchantingAltar = function() return _G.EventResolver:GetRemoteEvent("ActivateEnchantingAltar") end,
            RE_ActivateSecondEnchantingAltar = function() return _G.EventResolver:GetRemoteEvent("ActivateSecondEnchantingAltar") end,
            RE_RollEnchant             = function() return _G.EventResolver:GetRemoteEvent("RollEnchant") end,
            RE_BaitSpawned             = function() return _G.EventResolver:GetRemoteEvent("BaitSpawned") end,
            RE_BaitDestroyed           = function() return _G.EventResolver:GetRemoteEvent("BaitDestroyed") end,
            RE_ObtainedNewFishNotification = function() return _G.EventResolver:GetRemoteEvent("ObtainedNewFishNotification") end,
            RF_PurchaseFishingRod      = function() return _G.EventResolver:GetRemoteFunction("PurchaseFishingRod") end,
            RF_PurchaseBait            = function() return _G.EventResolver:GetRemoteFunction("PurchaseBait") end,
            RE_PlaceLeverItem          = function() return _G.EventResolver:GetRemoteEvent("PlaceLeverItem") end,
            RE_PlacePressurePlateItem  = function() return _G.EventResolver:GetRemoteEvent("PlacePressureItem") end,
            RE_EquipBait               = function() return _G.EventResolver:GetRemoteEvent("EquipBait") end,
            netFolder     = function() return _G.EventResolver:GetNetFolder() end,
            IsInitialized = function() return _G.EventResolver:IsReady() end,
        }
        return remoteMap[key] and remoteMap[key]() or nil
    end,

    __newindex = function(table, key, value)
        if key ~= "IsInitialized" then rawset(table, key, value) end
    end,
})

local function safeFire(fn) pcall(fn) end

local cachedAreas, cachedTiers, cachedItems, cachedReplionData, fishingController

local function getAreas()
    if not cachedAreas then
        pcall(function() cachedAreas = require(ReplicatedStorage.Areas) end)
    end
    return cachedAreas
end

local function getTiers()
    if not cachedTiers then
        pcall(function() cachedTiers = require(ReplicatedStorage.Tiers) end)
    end
    return cachedTiers
end

local function getItems()
    if not cachedItems then
        pcall(function() cachedItems = require(ReplicatedStorage.Items) end)
    end
    return cachedItems
end

local function getReplionData()
    if not cachedReplionData then
        pcall(function()
            cachedReplionData = require(ReplicatedStorage.Packages.Replion).Client:GetReplion("Data")
        end)
    end
    return cachedReplionData
end

local UltraBlatantRemoteEvents, UltraBlatantRemoteFunctions = {}, {}
local lastRodTier, isSpoofing, isVisualFiring = 2, false, false
local goldCounter, rainbowCounter, bagCounter, isCounterLocked, isOurOwnSet = 0, 0, 0, false, false

_G._lynxVisualUUIDs = {}

local ALLOWED_ROD_IDS = { [559] = true, [257] = true }

local TIER_COLOR_SEQUENCES = {
    [1] = ColorSequence.new(Color3.fromRGB(255, 250, 246)),
    [2] = ColorSequence.new(Color3.fromRGB(195, 255, 85)),
    [3] = ColorSequence.new(Color3.fromRGB(85, 162, 255)),
    [4] = ColorSequence.new(Color3.fromRGB(178, 114, 247)),
    [5] = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 184, 42)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 184, 42)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 232, 142)),
    }),
    [6] = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 24, 24)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(102, 0,  0)),
    }),
    [7] = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(23,  255, 151)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(11,  149, 255)),
    }),
}

task.spawn(function()
    UltraBlatantRemoteEvents.BaitCast        = _G.EventResolver:GetRemoteEvent("BaitCastVisual")
    UltraBlatantRemoteEvents.PlayFishingFX   = _G.EventResolver:GetRemoteEvent("PlayFishingEffect")
    UltraBlatantRemoteEvents.BaitSpawned     = _G.EventResolver:GetRemoteEvent("BaitSpawned")
    UltraBlatantRemoteEvents.TextEffect      = _G.EventResolver:GetRemoteEvent("ReplicateTextEffect")
    UltraBlatantRemoteEvents.FishCaught      = _G.EventResolver:GetRemoteEvent("FishCaught")
    UltraBlatantRemoteEvents.FishCaughtVisual = _G.EventResolver:GetRemoteEvent("FishCaughtVisual")
    UltraBlatantRemoteEvents.NewFishNotif    = _G.EventResolver:GetRemoteEvent("ObtainedNewFishNotification")
    UltraBlatantRemoteEvents.FishCompleted   = _G.EventResolver:GetRemoteEvent("CatchFishCompleted")

    UltraBlatantRemoteFunctions.ChargeRod    = _G.EventResolver:GetRemoteFunction("ChargeFishingRod")
    UltraBlatantRemoteFunctions.StartMinigame = _G.EventResolver:GetRemoteFunction("RequestFishingMinigameStarted")
    UltraBlatantRemoteFunctions.CancelInputs = _G.EventResolver:GetRemoteFunction("CancelFishingInputs")

    if UltraBlatantRemoteEvents.PlayFishingFX then
        UltraBlatantRemoteEvents.PlayFishingFX.OnClientEvent:Connect(function(player, _, tierValue)
            if player == LocalPlayer
                and not isSpoofing
                and type(tierValue) == "number"
                and tierValue > 0
            then
                lastRodTier = tierValue
            end
        end)
    end
end)

local function incrementCounters(amount)
    while isCounterLocked do task.wait() end
    isCounterLocked = true
    amount = amount or 1

    goldCounter    = goldCounter + amount
    rainbowCounter = rainbowCounter + amount
    bagCounter     = bagCounter + amount

    if goldCounter    > 10 then goldCounter    = 1 end
    if rainbowCounter > 40 then rainbowCounter = 1 end

    local replionData = getReplionData()
    if replionData then
        isOurOwnSet = true
        pcall(function() replionData:_set("Modifiers.Golden",             goldCounter) end)
        pcall(function() replionData:_set("Modifiers.Rainbow",            rainbowCounter) end)
        pcall(function() replionData:_set("InventoryNotifications.Fish",  bagCounter) end)
        isOurOwnSet = false
    end

    isCounterLocked = false
end

local function getTierFromChance(chance)
    local tiers = getTiers()
    if not tiers then return 1 end

    local bestTier = 1
    for _, tierData in pairs(tiers) do
        if type(tierData) == "table"
            and tierData.Rarity
            and tierData.Tier
            and chance <= tierData.Rarity
            and tierData.Tier > bestTier
            and tierData.Tier <= 7
        then
            bestTier = tierData.Tier
        end
    end
    return bestTier
end

local function getFishIdByName(fishName)
    local items = getItems()
    if not items then return 0 end

    for _, itemData in pairs(items) do
        if itemData.Data
            and itemData.Data.Name == fishName
            and itemData.Data.Type == "Fish"
        then
            return itemData.Data.Id or 0
        end
    end
    return 0
end

local function getTierColorByFishName(fishName)
    local items = getItems()
    if not items then return TIER_COLOR_SEQUENCES[1] end

    for _, itemData in pairs(items) do
        if itemData.Data
            and itemData.Data.Name == fishName
            and itemData.Data.Type == "Fish"
        then
            return TIER_COLOR_SEQUENCES[itemData.Data.Tier or 1] or TIER_COLOR_SEQUENCES[1]
        end
    end
    return TIER_COLOR_SEQUENCES[1]
end

local function getEquippedRodTier()
    local replionData = getReplionData()
    if not replionData then return lastRodTier end

    local equippedUUID = replionData:Get("EquippedId")
    if not equippedUUID or equippedUUID == "" then return lastRodTier end

    local fishingRods = replionData:Get("Inventory.Fishing Rods") or {}
    for _, rod in ipairs(fishingRods) do
        if rod.UUID == equippedUUID then
            local allItems = getItems() or {}
            for _, itemData in pairs(allItems) do
                if itemData.Data
                    and tostring(itemData.Data.Id) == tostring(rod.Id)
                    and itemData.Data.Type == "Fishing Rods"
                then
                    return itemData.Data.Tier or lastRodTier
                end
            end
        end
    end
    return lastRodTier
end

local function isEquippedRodAllowed()
    local replionData = getReplionData()
    if not replionData then return false end

    local equippedUUID = replionData:Get("EquippedId")
    if not equippedUUID or equippedUUID == "" then return false end

    local fishingRods = replionData:Get("Inventory.Fishing Rods") or {}
    for _, rod in ipairs(fishingRods) do
        if rod.UUID == equippedUUID then
            return ALLOWED_ROD_IDS[rod.Id] == true
        end
    end
    return false
end

local function getPlayerLocation()
    local success, locationValue = pcall(function() return LocalPlayer.LocationName end)
    if success and locationValue and tostring(locationValue) ~= "" then
        return tostring(locationValue)
    end

    local character = LocalPlayer.Character
    if character then
        local attr = character:GetAttribute("LocationName")
        if attr and tostring(attr) ~= "" then return tostring(attr) end
    end

    local playerAttr = LocalPlayer:GetAttribute("LocationName")
    if playerAttr and tostring(playerAttr) ~= "" then return tostring(playerAttr) end
end

local function calculateCastPosition()
    local character = LocalPlayer.Character
    if not character then
        return Vector3.zero, Vector3.new(0, 6, 0)
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return Vector3.zero, Vector3.new(0, 6, 0)
    end

    local forwardDirection = rootPart.CFrame.LookVector
    local castTarget = rootPart.Position + forwardDirection * 10

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { character }

    local rayResult = Workspace:Raycast(
        castTarget + Vector3.new(0, 50, 0),
        Vector3.new(0, -150, 0),
        rayParams
    )

    local castPosition  = rayResult and (rayResult.Position + Vector3.new(0, 0.1, 0))
                          or (castTarget + Vector3.new(0, -5, 0))
    local originPosition = rootPart.Position + forwardDirection * 5 + Vector3.new(0, 6.5, 0)

    return castPosition, originPosition
end

local function getFishListByTiers(tierList)
    local items = getItems()
    local areas = getAreas()
    if not items or not areas then return {} end

    local locationName = getPlayerLocation()
    local currentArea  = (locationName and areas[locationName]) or areas["Fisherman Island"]
    if not currentArea or not currentArea.Items then return {} end

    local result = {}
    for _, fishName in ipairs(currentArea.Items) do
        for _, itemData in pairs(items) do
            if itemData.Data
                and itemData.Data.Name == fishName
                and itemData.Data.Type == "Fish"
            then
                local fishTier = (itemData.Probability and itemData.Probability.Chance
                    and getTierFromChance(itemData.Probability.Chance))
                    or itemData.Data.Tier or 1

                for _, targetTier in ipairs(tierList) do
                    if fishTier == targetTier then
                        table.insert(result, { Name = fishName, Id = itemData.Data.Id or 0 })
                        break
                    end
                end
                break
            end
        end
    end
    return result
end

local function generateUUID()
    return ("xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"):gsub("[xy]", function(char)
        return string.format("%x",
            char == "x" and math.random(0, 15) or math.random(8, 11)
        )
    end)
end

local function getEquippedRodName()
    local success, value = pcall(function() return LocalPlayer.FishingRod end)
    return (success and value and tostring(value) ~= "" and tostring(value)) or ""
end

local function getEquippedRodSkin()
    local success, value = pcall(function() return LocalPlayer.FishingRodSkin end)
    return (success and value and tostring(value) ~= "" and tostring(value)) or ""
end

local function spoofFishCaughtVisual(fish)
    if isSpoofing then return end
    isSpoofing = true

    local uuid      = generateUUID()
    _G._lynxVisualUUIDs[uuid] = true

    local fishId    = fish.Id
    local fishName  = fish.Name
    local weight    = math.random(100, 2500) / 700

    local castPosition, originPosition = calculateCastPosition()
    local headPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
               or LocalPlayer.Character

    pcall(function()
        firesignal(UltraBlatantRemoteEvents.BaitCast.OnClientEvent,
            LocalPlayer,
            {
                CastPosition     = castPosition,
                Power            = 0.86895783044309,
                RodName          = getEquippedRodName(),
                CosmeticTemplateId = -1,
                EquippedToolModel  = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChild("!!!EQUIPPED_TOOL!!!") or nil,
                ConnectingJoint  = 0,
                NoFishingZone    = false,
                BaitIdentifier   = 3,
                Origin           = originPosition,
                CustomModel      = false,
            }
        )
    end)

    pcall(function()
        firesignal(UltraBlatantRemoteEvents.PlayFishingFX.OnClientEvent, LocalPlayer, headPart, getEquippedRodTier())
    end)
    pcall(function()
        firesignal(UltraBlatantRemoteEvents.BaitSpawned.OnClientEvent,
            LocalPlayer,
            getEquippedRodSkin(),
            Vector3.new(castPosition.X, castPosition.Y + 0.1, castPosition.Z)
        )
    end)

    isSpoofing = false
    task.wait(0.05)

    pcall(function()
        firesignal(UltraBlatantRemoteEvents.TextEffect.OnClientEvent,
            {
                Channel  = "All",
                TextData = {
                    AttachTo   = headPart,
                    Text       = "!",
                    TextColor  = getTierColorByFishName(fishName),
                    EffectType = "Exclaim",
                },
                Duration  = 0.5,
                Container = headPart,
            }
        )
    end)

    pcall(function()
        local replionData = getReplionData()
        if not replionData then return end

        local inventory = replionData:Get("Inventory.Items") or {}
        local newInventory = {}
        for _, item in ipairs(inventory) do
            table.insert(newInventory, item)
        end

        local newItem = {
            Id        = fishId,
            Favorited = false,
            UUID      = uuid,
            Metadata  = { Weight = weight },
        }
        table.insert(newInventory, newItem)
        replionData:_set("Inventory.Items", newInventory)
    end)

    isVisualFiring = true
    pcall(function()
        firesignal(UltraBlatantRemoteEvents.NewFishNotif.OnClientEvent,
            fishId,
            { Weight = weight },
            {
                CustomDuration = 5,
                InventoryItem  = { Id = fishId, Favorited = false, UUID = uuid, Metadata = { Weight = weight } },
                ItemType       = "Fish",
                _newlyIndexed  = false,
                Type           = "Item",
                ItemId         = fishId,
            },
            false
        )
    end)

    incrementCounters(1)
    isVisualFiring = false

    isSpoofing = true
    pcall(function()
        firesignal(UltraBlatantRemoteEvents.FishCaught.OnClientEvent, fishName, { Weight = weight }, 0, 0)
    end)
    task.wait(0.1)
    isSpoofing = false

    pcall(function()
        firesignal(UltraBlatantRemoteEvents.FishCaughtVisual.OnClientEvent,
            LocalPlayer, castPosition, fishName, { Weight = weight }
        )
    end)
end

task.spawn(function()
    task.wait(2)

    local replionData = getReplionData()
    if not replionData then return end

    local modifiers = replionData:Get("Modifiers")
    if modifiers then
        goldCounter    = modifiers.Golden  or 0
        rainbowCounter = modifiers.Rainbow or 0
    end

    local inventoryNotifications = replionData:Get("InventoryNotifications")
    if inventoryNotifications then
        bagCounter = inventoryNotifications.Fish or 0
    end

    replionData:OnChange("InventoryNotifications.Fish", function(newValue)
        if newValue == 0 then bagCounter = 0 end
    end)
    local originalSet = replionData._set
    replionData._set = function(selfArg, path, value)
        if isOurOwnSet then
            return originalSet(selfArg, path, value)
        end

        if path == "Modifiers.Golden"            then return originalSet(selfArg, path, goldCounter) end
        if path == "Modifiers.Rainbow"           then return originalSet(selfArg, path, rainbowCounter) end
        if path == "InventoryNotifications.Fish" then return originalSet(selfArg, path, bagCounter) end

        return originalSet(selfArg, path, value)
    end

    local waitTime = 0
    while not UltraBlatantRemoteEvents.NewFishNotif and waitTime < 10 do
        task.wait(0.5)
        waitTime += 0.5
    end

    if UltraBlatantRemoteEvents.NewFishNotif then
        UltraBlatantRemoteEvents.NewFishNotif.OnClientEvent:Connect(function()
            if not isVisualFiring then
                incrementCounters(1)
            end
        end)
    end
end)

local MainWindow = Library:Window({
    Title         = "Lynx",
    Footer        = "Fish It",
    Color         = Color3.fromRGB(100, 200, 255),
    ["Tab Width"] = 130,
    Version       = 1,
    Image         = "107726435417936",
})

local FishingTab = MainWindow:AddTab({ Name = "Main", Icon = "home" })

do
    local _sup = {
        AnimConn   = nil, AnimEnabled = false,

        RodThread  = nil, RodEnabled  = false,
        RodSupported = false,
        RodReplion   = nil, RodStats = nil, RodItems = nil,

        LockConn   = nil, LockEnabled = false, LockedCFrame = nil,

        NotifConn  = nil,

        VFXDisabled     = false,
        VFXController   = nil,
        VFXOrigHandle   = nil, VFXOrigAtPoint = nil, VFXOrigInstance = nil,
        VFXSupported    = false,

        CutsceneCtrl    = nil, CutsceneOrigPlay = nil, CutsceneDisabled = false,

        WaterEnabled    = false, WaterPlatform = nil,
        WaterAlign      = nil,   WaterConn     = nil, WaterSurfaceY = nil,

        MonitorConn = nil, MonitorGui = nil,
    }

    pcall(function()
        _sup.RodStats    = require(ReplicatedStorage.Shared.PlayerStatsUtility)
        _sup.RodItems    = require(ReplicatedStorage.Shared.ItemUtility)
        _sup.RodReplion  = require(ReplicatedStorage.Packages.Replion).Client:WaitReplion("Data")
        _sup.RodSupported = true
    end)

    pcall(function()
        _sup.VFXController   = require(ReplicatedStorage:WaitForChild("Controllers").VFXController)
        _sup.VFXOrigHandle   = _sup.VFXController.Handle
        _sup.VFXOrigAtPoint  = _sup.VFXController.RenderAtPoint
        _sup.VFXOrigInstance = _sup.VFXController.RenderInstance
        _sup.VFXSupported    = true
    end)

    pcall(function()
        _sup.CutsceneCtrl = require(
            ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("CutsceneController")
        )
        if _sup.CutsceneCtrl and _sup.CutsceneCtrl.Play then
            _sup.CutsceneOrigPlay = _sup.CutsceneCtrl.Play
            _sup.CutsceneCtrl.Play = function(selfArg, ...)
                if _sup.CutsceneDisabled then return end
                return _sup.CutsceneOrigPlay(selfArg, ...)
            end
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        if _sup.WaterEnabled then
            task.wait(0.5)
            if _sup.WaterConn   then _sup.WaterConn:Disconnect();  _sup.WaterConn  = nil end
            if _sup.WaterAlign  then _sup.WaterAlign:Destroy();    _sup.WaterAlign = nil end
            if _sup.WaterPlatform then _sup.WaterPlatform:Destroy(); _sup.WaterPlatform = nil end
            _sup.WaterEnabled = false
        end
    end)

    local SupportSection = FishingTab:AddSection("Support Features")

    SupportSection:AddToggle({
        Title    = "No Fishing Animation",
        Default  = false,
        Callback = function(on)
            if on then
                if _sup.AnimEnabled then return end
                _sup.AnimEnabled  = true
                _sup.SavedPose    = {}
                _sup.AnimBlocker  = nil

                pcall(function()
                    local char = LocalPlayer.Character
                    if not char then return end
                    for _, desc in pairs(char:GetDescendants()) do
                        if desc:IsA("Motor6D") then
                            _sup.SavedPose[desc.Name] = { Part = desc, C0 = desc.C0, C1 = desc.C1 }
                        end
                    end
                end)

                pcall(function()
                    local char = LocalPlayer.Character
                    if not char then return end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if not hum then return end
                    local animator = hum:FindFirstChildOfClass("Animator")
                    if not animator then return end
                    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                        track:Stop(0)
                    end
                end)

                pcall(function()
                    local char = LocalPlayer.Character
                    if not char then return end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if not hum then return end
                    local animator = hum:FindFirstChildOfClass("Animator")
                    if not animator then return end
                    _sup.AnimBlocker = animator.AnimationPlayed:Connect(function(track)
                        if _sup.AnimEnabled then track:Stop(0) end
                    end)
                end)

                task.wait(0.1)
                _sup.AnimConn = RunService.Heartbeat:Connect(function()
                    if not _sup.AnimEnabled then return end
                    pcall(function()
                        local char = LocalPlayer.Character
                        if not char then return end
                        for jointName, poseData in pairs(_sup.SavedPose) do
                            local motor = char:FindFirstChild(jointName, true)
                            if motor and motor:IsA("Motor6D") then
                                motor.C0 = poseData.C0
                                motor.C1 = poseData.C1
                            end
                        end
                    end)
                end)
            else
                _sup.AnimEnabled = false
                if _sup.AnimConn    then _sup.AnimConn:Disconnect();    _sup.AnimConn    = nil end
                if _sup.AnimBlocker then _sup.AnimBlocker:Disconnect(); _sup.AnimBlocker = nil end
                _sup.SavedPose = {}
            end
        end,
    })

    SupportSection:AddToggle({
        Title    = "Auto Equip Rod" .. (_sup.RodSupported and "" or " (Not Supported)"),
        Default  = false,
        Callback = function(on)
            if not _sup.RodSupported then
                if on then warn("[AutoEquipRod] Tidak support di executor ini") end
                return
            end
            if on then
                if _sup.RodEnabled then return end
                _sup.RodEnabled = true
                _sup.RodThread  = task.spawn(function()
                    while _sup.RodEnabled do
                        pcall(function()
                            local isEquipped = false
                            local uuid = _sup.RodReplion:Get("EquippedId")
                            if uuid then
                                local item = _sup.RodStats:GetItemFromInventory(
                                    _sup.RodReplion,
                                    function(i) return i.UUID == uuid end
                                )
                                if item then
                                    local data = _sup.RodItems:GetItemData(item.Id)
                                    isEquipped = data and data.Data.Type == "Fishing Rods"
                                end
                            end
                            if not isEquipped then
                                local remote = _G.EventResolver:GetRemoteEvent("EquipToolFromHotbar")
                                if remote then remote:FireServer(1) end
                            end
                        end)
                        task.wait(1)
                    end
                end)
            else
                _sup.RodEnabled = false
                if _sup.RodThread then task.cancel(_sup.RodThread); _sup.RodThread = nil end
            end
        end,
    })

    SupportSection:AddToggle({
        Title    = "Lock Position",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                if _sup.LockEnabled then return end
                _sup.LockEnabled = true
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local root = char:WaitForChild("HumanoidRootPart")
                _sup.LockedCFrame = root.CFrame
                _sup.LockConn = RunService.Heartbeat:Connect(function()
                    if not _sup.LockEnabled then return end
                    local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if r then r.CFrame = _sup.LockedCFrame end
                end)
            else
                _sup.LockEnabled = false
                if _sup.LockConn then _sup.LockConn:Disconnect(); _sup.LockConn = nil end
            end
        end,
    })

    SupportSection:AddToggle({
        Title    = "Show Real Ping Panel",
        Default  = false,
        Callback = function(on)
            if on then
                local TweenService     = game:GetService("TweenService")
                local Stats            = game:GetService("Stats")
                local UserInputService = game:GetService("UserInputService")
                local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

                local _theme = {
                    Bg      = Color3.fromRGB(15,  15,  20),
                    Stroke  = Color3.fromRGB(255, 140, 50),
                    Header  = Color3.fromRGB(255, 140, 50),
                    Sub     = Color3.fromRGB(180, 180, 180),
                    Good    = Color3.fromRGB(100, 255, 150),
                    Warn    = Color3.fromRGB(255, 220, 100),
                    Bad     = Color3.fromRGB(255, 100, 100),
                }

                local existing = PlayerGui:FindFirstChild("LynxPanelMonitor")
                if existing then existing:Destroy(); task.wait(0.05) end

                local screenGui = Instance.new("ScreenGui")
                screenGui.Name           = "LynxPanelMonitor"
                screenGui.ResetOnSpawn   = false
                screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
                screenGui.DisplayOrder   = 999999
                screenGui.IgnoreGuiInset = true
                screenGui.Parent         = PlayerGui

                local container = Instance.new("Frame")
                container.Size                   = UDim2.new(0, 200, 0, 45)
                container.Position               = UDim2.new(0.5, -100, 0, 15)
                container.BackgroundColor3       = _theme.Bg
                container.BackgroundTransparency = 0.25
                container.BorderSizePixel        = 0
                container.Parent                 = screenGui
                Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)

                local stroke = Instance.new("UIStroke")
                stroke.Color           = _theme.Stroke
                stroke.Thickness       = 1.5
                stroke.Transparency    = 0.6
                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                stroke.Parent          = container

                local grad = Instance.new("UIGradient")
                grad.Color    = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, _theme.Bg),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 35)),
                }
                grad.Rotation = 45
                grad.Parent   = container

                local logo = Instance.new("ImageLabel")
                logo.Size               = UDim2.new(0, 32, 0, 32)
                logo.Position           = UDim2.new(0, 6, 0.5, -16)
                logo.BackgroundTransparency = 1
                logo.Image              = "rbxassetid://118176705805619"
                logo.ScaleType          = Enum.ScaleType.Fit
                logo.Parent             = container
                Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 6)

                local content = Instance.new("Frame")
                content.Size               = UDim2.new(1, -46, 1, 0)
                content.Position           = UDim2.new(0, 43, 0, 0)
                content.BackgroundTransparency = 1
                content.Parent             = container

                local function _makeLabel(text, size, posY, fontSize, color)
                    local lbl = Instance.new("TextLabel")
                    lbl.Size             = UDim2.new(1, -8, 0, size)
                    lbl.Position         = UDim2.new(0, 4, 0, posY)
                    lbl.BackgroundTransparency = 1
                    lbl.Text             = text
                    lbl.TextColor3       = color or _theme.Sub
                    lbl.TextSize         = fontSize
                    lbl.Font             = Enum.Font.GothamBold
                    lbl.TextXAlignment   = Enum.TextXAlignment.Left
                    lbl.Parent           = content
                    return lbl
                end

                _makeLabel("LYNX PANEL", 14, 4, 11, _theme.Header)
                local statsLabel = _makeLabel("Ping: --ms | CPU: --ms | FPS: --", 16, 16, 9)
                statsLabel.RichText = true
                local notifLabel  = _makeLabel("Notifications : 0", 12, 32, 9)

                local _drag = { active = false, input = nil, startPos = nil, startCont = nil }
                container.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch
                    then
                        _drag.active   = true
                        _drag.startPos = input.Position
                        _drag.startCont = container.Position
                        TweenService:Create(stroke, TweenInfo.new(0.2), { Transparency = 0.3, Thickness = 2 }):Play()
                        input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                _drag.active = false
                                TweenService:Create(stroke, TweenInfo.new(0.3), { Transparency = 0.6, Thickness = 1.5 }):Play()
                            end
                        end)
                    end
                end)
                container.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch
                    then _drag.input = input end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if input == _drag.input and _drag.active then
                        local delta = input.Position - _drag.startPos
                        container.Position = UDim2.new(
                            _drag.startCont.X.Scale, _drag.startCont.X.Offset + delta.X,
                            _drag.startCont.Y.Scale, _drag.startCont.Y.Offset + delta.Y
                        )
                    end
                end)

                _sup.MonitorGui = { screenGui = screenGui, statsLabel = statsLabel, notifLabel = notifLabel }

                local _fps, _cpu, _currentFPS, _lastUpdate = 0, 0, 0, 0
                _sup.MonitorConn = RunService.Heartbeat:Connect(function(dt)
                    _fps += dt
                    if _fps >= 0.5 then _currentFPS = math.floor(1 / dt); _fps = 0 end
                    _cpu = _cpu * 0.9 + math.clamp((dt / 0.01667) * 35, 0, 100) * 0.1

                    local now = tick()
                    if now - _lastUpdate < 0.35 then return end
                    _lastUpdate = now

                    local ping = 0
                    pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
                    if ping <= 0 then pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end) end
                    ping = math.max(ping, 0)

                    local cpuMs = math.floor(_cpu)

                    local notifCount = 0
                    pcall(function()
                        local gui = LocalPlayer.PlayerGui:FindFirstChild("Text Notifications")
                        if gui then
                            local frame = gui:FindFirstChild("Frame")
                            if frame then
                                for _, child in ipairs(frame:GetChildren()) do
                                    if child.Name == "Tile" and child:IsA("Frame") then notifCount += 1 end
                                end
                            end
                        end
                    end)

                    local function _colorTag(val, good, warn, rev)
                        local c = rev
                            and ((val >= good and _theme.Good) or (val >= warn and _theme.Warn) or _theme.Bad)
                            or  ((val <= good and _theme.Good) or (val <= warn and _theme.Warn) or _theme.Bad)
                        return string.format('<font color="rgb(%d,%d,%d)">', c.R*255, c.G*255, c.B*255)
                    end

                    statsLabel.Text = string.format(
                        "Ping: %s%dms</font> | CPU: %s%dms</font> | FPS: %s%d</font>",
                        _colorTag(ping, 50, 100, false), ping,
                        _colorTag(cpuMs, 50, 80, false),  cpuMs,
                        _colorTag(_currentFPS, 50, 30, true), _currentFPS
                    )
                    notifLabel.Text = string.format("Notifications : %d", notifCount)
                end)
            else
                if _sup.MonitorConn then _sup.MonitorConn:Disconnect(); _sup.MonitorConn = nil end
                if _sup.MonitorGui  then _sup.MonitorGui.screenGui:Destroy(); _sup.MonitorGui = nil end
            end
        end,
    })

    SupportSection:AddToggle({
        Title    = "Disable Cutscenes",
        Default  = false,
        Callback = function(on)
            _sup.CutsceneDisabled = on
            if on and not _sup.CutsceneCtrl then
                pcall(function()
                    _sup.CutsceneCtrl = require(
                        ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("CutsceneController")
                    )
                    if _sup.CutsceneCtrl and _sup.CutsceneCtrl.Play then
                        _sup.CutsceneOrigPlay = _sup.CutsceneCtrl.Play
                        _sup.CutsceneCtrl.Play = function(selfArg, ...)
                            if _sup.CutsceneDisabled then return end
                            return _sup.CutsceneOrigPlay(selfArg, ...)
                        end
                    end
                end)
            end
        end,
    })

    SupportSection:AddToggle({
        Title    = "Disable Obtained Fish Notification",
        Default  = false,
        Callback = function(on)
            if on then
                if _sup.NotifConn then return end
                local PlayerGui = LocalPlayer.PlayerGui
                local notifGui  = PlayerGui:FindFirstChild("Small Notification")
                               or PlayerGui:WaitForChild("Small Notification", 5)
                if not notifGui then return end
                notifGui.Enabled = false
                _sup.NotifConn = notifGui:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if notifGui.Enabled then notifGui.Enabled = false end
                end)
            else
                if _sup.NotifConn then _sup.NotifConn:Disconnect(); _sup.NotifConn = nil end
                local notifGui = LocalPlayer.PlayerGui:FindFirstChild("Small Notification")
                if notifGui then notifGui.Enabled = true end
            end
        end,
    })

    SupportSection:AddToggle({
        Title    = "Disable Skin Effect" .. (_sup.VFXSupported and "" or " (Not Supported)"),
        Default  = false,
        Callback = function(on)
            if not _sup.VFXSupported then
                if on then warn("[DisableSkinEffect] Tidak support di executor ini") end
                return
            end
            if on then
                if _sup.VFXDisabled then return end
                _sup.VFXDisabled = true
                _sup.VFXController.Handle         = function() end
                _sup.VFXController.RenderAtPoint  = function() end
                _sup.VFXController.RenderInstance = function() end
            else
                _sup.VFXDisabled = false
                _sup.VFXController.Handle         = _sup.VFXOrigHandle
                _sup.VFXController.RenderAtPoint  = _sup.VFXOrigAtPoint
                _sup.VFXController.RenderInstance = _sup.VFXOrigInstance
            end
        end,
    })

    SupportSection:AddToggle({
        Title    = "Walk On Water",
        Default  = false,
        Callback = function(on)
            _sup.WaterEnabled = on
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local root = char:WaitForChild("HumanoidRootPart")
            if on then
                if _sup.WaterConn     then _sup.WaterConn:Disconnect();    _sup.WaterConn    = nil end
                if _sup.WaterAlign    then _sup.WaterAlign:Destroy();      _sup.WaterAlign   = nil end
                if _sup.WaterPlatform then _sup.WaterPlatform:Destroy();   _sup.WaterPlatform = nil end
                local rayParams = RaycastParams.new()
                rayParams.FilterType                 = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = { char }
                rayParams.IgnoreWater                = false
                local rayResult = workspace:Raycast(
                    root.Position + Vector3.new(0, 10, 0),
                    Vector3.new(0, -200, 0),
                    rayParams
                )
                _sup.WaterSurfaceY = (rayResult and rayResult.Position.Y) or root.Position.Y
                local platform        = Instance.new("Part")
                platform.Name         = "WaterLockPlatform"
                platform.Size         = Vector3.new(15, 1, 15)
                platform.Anchored     = true
                platform.CanCollide   = false
                platform.Transparency = 1
                platform.Material     = Enum.Material.SmoothPlastic
                platform.CastShadow   = false
                platform.CanQuery     = false
                platform.CanTouch     = false
                platform.Position     = Vector3.new(root.Position.X, _sup.WaterSurfaceY, root.Position.Z)
                platform.Parent       = workspace
                _sup.WaterPlatform    = platform
                _sup.WaterConn = RunService.Heartbeat:Connect(function()
                    if not _sup.WaterEnabled then return end
                    local c = LocalPlayer.Character
                    local r = c and c:FindFirstChild("HumanoidRootPart")
                    if not c or not r then return end
                    local surfaceY = _sup.WaterSurfaceY
                    platform.Position  = Vector3.new(r.Position.X, surfaceY, r.Position.Z)
                    platform.CanCollide = r.Position.Y >= (surfaceY - 0.5)
                end)
            else
                if _sup.WaterConn     then _sup.WaterConn:Disconnect();    _sup.WaterConn     = nil end
                if _sup.WaterAlign    then _sup.WaterAlign:Destroy();      _sup.WaterAlign    = nil end
                if _sup.WaterPlatform then _sup.WaterPlatform:Destroy();   _sup.WaterPlatform = nil end
                _sup.WaterSurfaceY = nil
            end
        end,
    })
end

do
    local _stable = { enabled = false }

    local StableSection = FishingTab:AddSection("Stable Result Good/Perfection")

    StableSection:AddToggle({
        Title    = "Stable Result Good/Perfection",
        Default  = false,
        Callback = function(on)
            if on then
                if _stable.enabled then return end
                local remote = _G.EventResolver:GetRemoteFunction("UpdateAutoFishingState")
                if not remote then return end
                if not pcall(function() remote:InvokeServer(true) end) then return end
                _stable.enabled = true
                pcall(function() LocalPlayer:SetAttribute("Loading", nil) end)
            else
                if not _stable.enabled then return end
                _stable.enabled = false
                local remote = _G.EventResolver:GetRemoteFunction("UpdateAutoFishingState")
                if remote then pcall(function() remote:InvokeServer(false) end) end
                pcall(function() LocalPlayer:SetAttribute("Loading", false) end)
            end
        end,
    })
end

do
    local _legit = {
        active      = false,
        autoShaking = false,
        settings    = { clickWait = 0.01, shakeDelay = 0.05 },
        fishThread  = nil,
        shakeThread = nil,
        watchConn   = nil,
    }

    local _replionData = nil

    local function _getController()
        if not fishingController then
            local folder = ReplicatedStorage:FindFirstChild("Controllers")
            local module = folder and folder:FindFirstChild("FishingController")
            if not module then return nil end
            fishingController = require(module)
        end
        return fishingController
    end

    local function _getReplion()
        if _replionData then return _replionData end
        local ok, data = pcall(function()
            return require(ReplicatedStorage.Packages.Replion).Client:WaitReplion("Data")
        end)
        if ok then _replionData = data end
        return ok and data or nil
    end

    local function _setAutoFishing(state)
        local remote = NetEvents.RF_UpdateAutoFishingState
        if not remote then warn("[LegitFishing] RF_UpdateAutoFishingState tidak ditemukan!"); return false end
        local ok = pcall(function() remote:InvokeServer(state) end)
        return ok
    end

    local LegitSection = FishingTab:AddSection("Legit Fishing", false)

    LegitSection:AddInput({
        Title    = "Shake Delay",
        Default  = "0.05",
        Callback = function(value)
            local num = tonumber(value)
            if num and num >= 0 then
                _legit.settings.clickWait  = num
                _legit.settings.shakeDelay = num
            end
        end,
    })

    LegitSection:AddToggle({
        Title    = "Enable Legit Fishing",
        Default  = false,
        Callback = function(on)
            if on then
                local ctrl = _getController()
                if not ctrl then warn("[LegitFishing] FishingController tidak ditemukan!"); return end

                local replionData = _getReplion()
                if not replionData then warn("[LegitFishing] Replion Data tidak ditemukan!"); return end

                if not _setAutoFishing(true) then
                    warn("[LegitFishing] Gagal invoke remote!"); return
                end

                _legit.active = true

                _legit.watchConn = replionData:OnChange("AutoFishing", function(newState)
                    if _legit.active and not newState then
                        warn("[LegitFishing] AutoFishing off, menyalakan ulang...")
                        _setAutoFishing(true)
                    end
                end)

                _legit.fishThread = task.spawn(function()
                    while _legit.active do
                        pcall(function()
                            if ctrl:GetCurrentGUID() then ctrl:RequestFishingMinigameClick() end
                        end)
                        task.wait(_legit.settings.clickWait)
                    end
                end)

            else
                _legit.active = false
                if _legit.watchConn  then _legit.watchConn:Disconnect();    _legit.watchConn  = nil end
                if _legit.fishThread then task.cancel(_legit.fishThread);    _legit.fishThread = nil end
                _setAutoFishing(false)
            end
        end,
    })

    LegitSection:AddToggle({
        Title    = "Auto Shake (klik terus)",
        Default  = false,
        Callback = function(on)
            if on then
                local ctrl = _getController()
                if not ctrl then return end
                _legit.autoShaking = true
                _legit.shakeThread = task.spawn(function()
                    while _legit.autoShaking do
                        pcall(function() ctrl:RequestFishingMinigameClick() end)
                        task.wait(_legit.settings.shakeDelay)
                    end
                end)
            else
                _legit.autoShaking = false
                if _legit.shakeThread then task.cancel(_legit.shakeThread); _legit.shakeThread = nil end
            end
        end,
    })
end

do
    local _instant = {
        active       = false,
        castMode     = "normal",
        settings     = { completeDelay = 0 },
        loopThread   = nil,
    }

    local InstantSection = FishingTab:AddSection("Instant Fishing")

    InstantSection:AddDropdown({
        Title    = "Mode Cast",
        Options  = { "Normal", "Perfect" },
        Default  = "Normal",
        Callback = function(value)
            _instant.castMode = value:lower()
        end,
    })

    InstantSection:AddInput({
        Title    = "Instant Delay",
        Default  = "0.04",
        Callback = function(value)
            local num = tonumber(value)
            if num then _instant.settings.completeDelay = num end
        end,
    })

    InstantSection:AddToggle({
        Title    = "Enable Instant",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                if not _G.EventResolver:IsReady() then return end
                _instant.active     = true
                _instant.loopThread = task.spawn(function()
                    while _instant.active do
                        if not _G.EventResolver:IsReady() then task.wait(1); continue end

                        if _instant.castMode == "perfect" then
                            local sTime     = workspace:GetServerTimeNow()
                            local speed     = Random.new(sTime):NextInteger(4, 10)
                            local bestDelay = math.huge
                            for k = 0, 10 do
                                local d = (math.pi * (1 + 2 * k)) / speed
                                if d > 0 and d < bestDelay then bestDelay = d end
                            end
                            local chargeTime  = sTime
                            local perfectTime = sTime + bestDelay
                            safeFire(function() NetEvents.RF_ChargeFishingRod:InvokeServer(nil, nil, chargeTime, nil) end)
                            local waitTime = perfectTime - workspace:GetServerTimeNow() - 0.01
                            if waitTime > 0 then task.wait(waitTime) end
                            local speed2 = Random.new(chargeTime):NextInteger(4, 10)
                            local power  = math.clamp(
                                (1 - math.sin(math.pi / 2 + (workspace:GetServerTimeNow() - chargeTime) * speed2)) / 2,
                                0, 1
                            )
                            safeFire(function() NetEvents.RF_RequestMinigame:InvokeServer(-1.2, power, chargeTime) end)
                            task.wait(_instant.settings.completeDelay)
                            safeFire(function() NetEvents.RE_FishingCompleted:FireServer() end)
                            task.wait(0.2)
                        else
                            local sTime = workspace:GetServerTimeNow()
                            safeFire(function() NetEvents.RF_CancelFishingInputs:InvokeServer(true) end)
                            task.wait()
                            safeFire(function() NetEvents.RF_ChargeFishingRod:InvokeServer(nil, nil, sTime, nil) end)
                            safeFire(function() NetEvents.RF_RequestMinigame:InvokeServer(-1.2, 0.5, sTime) end)
                            task.wait(_instant.settings.completeDelay)
                            safeFire(function() NetEvents.RE_FishingCompleted:FireServer() end)
                            task.wait()
                        end
                    end
                end)
            else
                _instant.active = false
                if _instant.loopThread then task.cancel(_instant.loopThread); _instant.loopThread = nil end
                safeFire(function() NetEvents.RF_CancelFishingInputs:InvokeServer() end)
            end
        end,
    })
end

do
    local _ifr = {
        active       = false,
        castMode     = "normal",
        settings     = { completeDelay = 0.02, baitSpeed = 100, notifMult = 1.175 },
        loopThread   = nil,
        animConn     = nil,
        connections  = {},
        curveUtil    = nil, origCurve    = nil,
        notifCtrl    = nil, origDeliver  = nil, notifHooked = false,
    }

    local IFRSection = FishingTab:AddSection("Instant Fast Reel [BETA]", false)

    IFRSection:AddDropdown({
        Title    = "Mode",
        Default  = "normal",
        Options  = { "normal", "perfect" },
        Callback = function(value) _ifr.castMode = value end,
    })

    IFRSection:AddInput({
        Title    = "Complete Delay",
        Default  = "0.02",
        Callback = function(value)
            local num = tonumber(value)
            if num and num >= 0 then _ifr.settings.completeDelay = num end
        end,
    })

    IFRSection:AddToggle({
        Title    = "Instant Fast Reel",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                if not _G.EventResolver:IsReady() then
                    warn("[InstantFastReel] EventResolver belum siap!"); return
                end
                _ifr.active = true

                pcall(function()
                    local cu = require(ReplicatedStorage.Modules.Util.CurveUtil)
                    _ifr.curveUtil = cu
                    _ifr.origCurve = cu.GetCurveBetween
                    cu.GetCurveBetween = function(params)
                        if not _ifr.active then return _ifr.origCurve(params) end
                        local finishPos = params.finish or params["finish"]
                        if (_ifr.settings.baitSpeed or 999) >= 99 then
                            return { CFrame.new(finishPos), CFrame.new(finishPos) }
                        end
                        local orig   = _ifr.origCurve(params)
                        local total  = #orig
                        local target = math.max(2, math.floor(total / _ifr.settings.baitSpeed))
                        local result = {}
                        for i = 1, target do
                            local idx = math.clamp(math.round((i-1)/(target-1)*(total-1))+1, 1, total)
                            table.insert(result, orig[idx])
                        end
                        return result
                    end
                end)

                pcall(function()
                    local nc = require(ReplicatedStorage.Controllers.TextNotificationController)
                    _ifr.notifCtrl   = nc
                    _ifr.origDeliver = nc.DeliverNotification
                    _ifr.notifHooked = true
                    nc.DeliverNotification = function(selfArg, params)
                        params = table.clone(params)
                        if not params.CustomDuration then
                            local base = 3
                            if params.Type == "Location" then base = 4
                            elseif params.Type == "Event" then base = 5 end
                            params.CustomDuration = base * _ifr.settings.notifMult
                        else
                            params.CustomDuration = params.CustomDuration * _ifr.settings.notifMult
                        end
                        return _ifr.origDeliver(selfArg, params)
                    end
                end)

                local blockedVFX     = { ["Bait Dive"] = true, ["Water Impact"] = true }
                local cosmeticFolder = workspace:WaitForChild("CosmeticFolder", 10)
                if cosmeticFolder then
                    for _, child in ipairs(cosmeticFolder:GetChildren()) do
                        if blockedVFX[child.Name] then child.Parent = nil end
                    end
                    table.insert(_ifr.connections, cosmeticFolder.ChildAdded:Connect(function(child)
                        if _ifr.active and blockedVFX[child.Name] then child.Parent = nil end
                    end))
                end

                task.wait(0.5)
                _ifr.animConn = RunService.Heartbeat:Connect(function()
                    if not _ifr.active then return end
                    local char = LocalPlayer.Character
                    if not char then return end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if not hum then return end
                    local animator = hum:FindFirstChildOfClass("Animator")
                    if not animator then return end
                    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                        if track.Name:find("Reel") or track.Name:find("Fish") then
                            track:Stop(0)
                        end
                    end
                end)

                _ifr.loopThread = task.spawn(function()
                    while _ifr.active do
                        if not _G.EventResolver:IsReady() then task.wait(1); continue end

                        if _ifr.castMode == "perfect" then
                            local sTime     = workspace:GetServerTimeNow()
                            local speed     = Random.new(sTime):NextInteger(4, 10)
                            local bestDelay = math.huge
                            for k = 0, 10 do
                                local d = (math.pi * (1 + 2 * k)) / speed
                                if d > 0 and d < bestDelay then bestDelay = d end
                            end
                            local chargeTime  = sTime
                            local perfectTime = sTime + bestDelay
                            safeFire(function() NetEvents.RF_ChargeFishingRod:InvokeServer(nil, nil, chargeTime, nil) end)
                            local waitTime = perfectTime - workspace:GetServerTimeNow() - 0.01
                            if waitTime > 0 then task.wait(waitTime) end
                            local speed2 = Random.new(chargeTime):NextInteger(4, 10)
                            local power  = math.clamp(
                                (1 - math.sin(math.pi / 2 + (workspace:GetServerTimeNow() - chargeTime) * speed2)) / 2,
                                0, 1
                            )
                            safeFire(function() NetEvents.RF_RequestMinigame:InvokeServer(-1.2, power, chargeTime) end)
                            task.wait(_ifr.settings.completeDelay)
                            safeFire(function() NetEvents.RE_FishingCompleted:FireServer() end)
                            task.wait(0.2)
                        else
                            local sTime = workspace:GetServerTimeNow()
                            safeFire(function() NetEvents.RF_CancelFishingInputs:InvokeServer(true) end)
                            task.wait()
                            safeFire(function() NetEvents.RF_ChargeFishingRod:InvokeServer(nil, nil, sTime, nil) end)
                            safeFire(function() NetEvents.RF_RequestMinigame:InvokeServer(-1.2, 0.5, sTime) end)
                            task.wait(_ifr.settings.completeDelay)
                            safeFire(function() NetEvents.RE_FishingCompleted:FireServer() end)
                            task.wait()
                        end
                    end
                end)

                Library:MakeNotify({
                    Title       = "Instant Fast Reel",
                    Description = "Mode: " .. _ifr.castMode,
                    Delay       = 2,
                })
            else
                _ifr.active = false

                if _ifr.loopThread then task.cancel(_ifr.loopThread); _ifr.loopThread = nil end
                if _ifr.animConn   then _ifr.animConn:Disconnect();   _ifr.animConn   = nil end

                if _ifr.curveUtil and _ifr.origCurve then
                    _ifr.curveUtil.GetCurveBetween = _ifr.origCurve
                    _ifr.curveUtil = nil
                    _ifr.origCurve = nil
                end

                if _ifr.notifHooked and _ifr.notifCtrl then
                    _ifr.notifCtrl.DeliverNotification = _ifr.origDeliver
                    _ifr.notifHooked = false
                end

                for _, c in ipairs(_ifr.connections) do c:Disconnect() end
                _ifr.connections = {}

                safeFire(function() NetEvents.RF_CancelFishingInputs:InvokeServer() end)

                Library:MakeNotify({
                    Title       = "Instant Fast Reel",
                    Description = "Dimatikan.",
                    Delay       = 2,
                })
            end
        end,
    })
end

do
    local _ub = {
        active        = false,
        completeDelay = 0.04,
        spamDelay     = 0.3,
        loopThread    = nil,
        fishConn      = nil,
    }

    local UBSection = FishingTab:AddSection("Ini Blatant kayaknya", false)

    UBSection:AddInput({
        Title    = "Complete Delay",
        Default  = "0.3",
        Callback = function(value)
            local num = tonumber(value)
            if num and num >= 0 then _ub.completeDelay = num end
        end,
    })

    UBSection:AddToggle({
        Title    = "Enable Ultra Blatant",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                if not _G.EventResolver:IsReady() then return end
                _ub.active     = true
                _ub.loopThread = task.spawn(function()
                    while _ub.active do
                        local sTime = tick()
                        pcall(function() UltraBlatantRemoteFunctions.ChargeRod:InvokeServer({ [1] = sTime }) end)
                        pcall(function() UltraBlatantRemoteFunctions.StartMinigame:InvokeServer(1, 0, sTime) end)
                        task.wait(_ub.completeDelay)
                        pcall(function() UltraBlatantRemoteEvents.FishCompleted:FireServer() end)
                        task.wait(_ub.spamDelay)
                    end
                end)

                task.spawn(function()
                    local elapsed = 0
                    while not UltraBlatantRemoteEvents.FishCaught and elapsed < 10 do
                        task.wait(0.5); elapsed += 0.5
                    end
                    if not UltraBlatantRemoteEvents.FishCaught then return end

                    _ub.fishConn = UltraBlatantRemoteEvents.FishCaught.OnClientEvent:Connect(function(fishName)
                        if not _ub.active or isSpoofing or not isEquippedRodAllowed() then return end
                        task.spawn(function()
                            if _ub.completeDelay > 0 then task.wait(_ub.completeDelay) end
                            local selectedFish
                            if fishName and fishName ~= "" then
                                local items    = getItems()
                                local fishTier = 1
                                if items then
                                    for _, itemData in pairs(items) do
                                        if itemData.Data
                                            and itemData.Data.Name == fishName
                                            and itemData.Data.Type == "Fish"
                                        then
                                            fishTier = (itemData.Probability and itemData.Probability.Chance
                                                and getTierFromChance(itemData.Probability.Chance))
                                                or itemData.Data.Tier or 1
                                            break
                                        end
                                    end
                                end
                                if fishTier >= 4 then
                                    local rare     = getFishListByTiers({ 3 })
                                    local uncommon = getFishListByTiers({ 2 })
                                    if math.random(1, 10) <= 8 and #rare > 0 then
                                        selectedFish = rare[math.random(1, #rare)]
                                    elseif #uncommon > 0 then
                                        selectedFish = uncommon[math.random(1, #uncommon)]
                                    elseif #rare > 0 then
                                        selectedFish = rare[math.random(1, #rare)]
                                    end
                                else
                                    if math.random(1, 10) <= 7 then
                                        selectedFish = { Name = fishName, Id = getFishIdByName(fishName) }
                                    else
                                        local sameTier = getFishListByTiers({ fishTier })
                                        local other    = {}
                                        for _, f in ipairs(sameTier) do
                                            if f.Name ~= fishName then table.insert(other, f) end
                                        end
                                        selectedFish = (#other > 0 and other[math.random(1, #other)])
                                                    or { Name = fishName, Id = getFishIdByName(fishName) }
                                    end
                                end
                            end
                            if selectedFish then spoofFishCaughtVisual(selectedFish) end
                        end)
                    end)
                end)
            else
                _ub.active = false
                if _ub.loopThread then task.cancel(_ub.loopThread); _ub.loopThread = nil end
                if _ub.fishConn   then _ub.fishConn:Disconnect();   _ub.fishConn   = nil end
                pcall(function() UltraBlatantRemoteFunctions.CancelInputs:InvokeServer() end)
            end
        end,
    })
end

do
    local _bv1 = {
        active   = false,
        settings = { spamDelay = 0.05, completeDelay = 0.01, chargeSpam = 3 },
        thread   = nil,
    }

    local BV1Section = FishingTab:AddSection("Blatant [BETA]")

    BV1Section:AddToggle({
        Title    = "Enable Blatant V1",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                if not _G.EventResolver:IsReady() then return end
                _bv1.active = true
                _bv1.thread = task.spawn(function()
                    while _bv1.active do
                        if not _G.EventResolver:IsReady() then task.wait(1); continue end
                        local sTime = Workspace:GetServerTimeNow()
                        for i = 1, _bv1.settings.chargeSpam do
                            safeFire(function() NetEvents.RF_ChargeFishingRod:InvokeServer(nil, nil, sTime, nil) end)
                            safeFire(function() NetEvents.RF_RequestMinigame:InvokeServer(-1.2331848144531, 0.89899236174132, sTime) end)
                            if i < _bv1.settings.chargeSpam then task.wait(0.05) end
                        end
                        task.wait(_bv1.settings.completeDelay)
                        safeFire(function() NetEvents.RE_FishingCompleted:FireServer() end)
                        task.wait(0.01)
                        safeFire(function() NetEvents.RF_CancelFishingInputs:InvokeServer() end)
                        task.wait(_bv1.settings.spamDelay)
                    end
                end)
            else
                _bv1.active = false
                if _bv1.thread then task.cancel(_bv1.thread); _bv1.thread = nil end
            end
        end,
    })

    BV1Section:AddInput({
        Title    = "Spam Cast Delay v1",
        Default  = "0.05",
        Callback = function(value)
            local num = tonumber(value)
            if num then _bv1.settings.spamDelay = num end
        end,
    })

    BV1Section:AddInput({
        Title    = "Complete Delay v1",
        Default  = "0.01",
        Callback = function(value)
            local num = tonumber(value)
            if num then _bv1.settings.completeDelay = num end
        end,
    })
end

do
    local _bv2 = {
        active   = false,
        settings = { completeDelay = 0.01, spamDelay = 0.05, chargeSpam = 1 },
        thread   = nil,
        minConn  = nil,
    }

    local function _safe(fn) task.spawn(function() pcall(fn) end) end

    local BV2Section = FishingTab:AddSection("Blatant V2 [BETA]")

    BV2Section:AddToggle({
        Title    = "Enable Blatant V2",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                if not _G.EventResolver:IsReady() then
                    warn("[BlatantV2] EventResolver belum siap!"); return
                end
                _bv2.active = true

                if NetEvents.RE_MinigameChanged then
                    _bv2.minConn = NetEvents.RE_MinigameChanged.OnClientEvent:Connect(function()
                        if not _bv2.active then return end
                        task.spawn(function()
                            task.wait(_bv2.settings.completeDelay)
                            _safe(function() NetEvents.RE_FishingCompleted:FireServer() end)
                        end)
                    end)
                end

                _bv2.thread = task.spawn(function()
                    while _bv2.active do
                        if not _G.EventResolver:IsReady() then continue end
                        local sTime = tick()
                        for i = 1, _bv2.settings.chargeSpam do
                            _safe(function() NetEvents.RF_ChargeFishingRod:InvokeServer({ [1] = sTime }) end)
                            _safe(function() NetEvents.RF_RequestMinigame:InvokeServer(1, 0, sTime) end)
                            task.wait(_bv2.settings.completeDelay)
                            _safe(function() NetEvents.RE_FishingCompleted:FireServer() end)
                            if i < _bv2.settings.chargeSpam then task.wait(0.5) end
                        end
                        _safe(function() NetEvents.RE_FishingCompleted:FireServer() end)
                        task.wait(_bv2.settings.spamDelay)
                    end
                end)
            else
                _bv2.active = false
                if _bv2.thread  then task.cancel(_bv2.thread);   _bv2.thread  = nil end
                if _bv2.minConn then _bv2.minConn:Disconnect();  _bv2.minConn = nil end
            end
        end,
    })

    BV2Section:AddInput({
        Title    = "Spam Cast Delay v2",
        Default  = "0.05",
        Callback = function(value)
            local num = tonumber(value)
            if num then _bv2.settings.spamDelay = num end
        end,
    })

    BV2Section:AddInput({
        Title    = "Complete Delay v2",
        Default  = "0.01",
        Callback = function(value)
            local num = tonumber(value)
            if num then _bv2.settings.completeDelay = num end
        end,
    })
end

do
    local FavoriteTab    = MainWindow:AddTab({ Name = "Favorite", Icon = "star" })
    local AutoFavSection = FavoriteTab:AddSection("Auto Favorite")

    local _favState = {
        enabled         = false,
        isScanning      = false,
        onChangeHooked  = false,
        selectedName    = {},
        selectedRarity  = {},
        selectedVariant = {},
    }

    local _favCache = {
        refsReady      = false,
        itemUtility    = nil,
        replionData    = nil,
        itemsFolder    = nil,
        variantsFolder = nil,
    }

    local _favFishList, _favVariantList = {}, {}

    local TIER_NAMES = {
        [1] = "Common",    [2] = "Uncommon", [3] = "Rare",
        [4] = "Epic",      [5] = "Legendary",[6] = "Mythic",
        [7] = "SECRET",    [8] = "FORGOTTEN",
    }

    local function favInitRefs()
        if _favCache.refsReady then return true end
        local ok = pcall(function()
            _favCache.itemUtility    = require(ReplicatedStorage.Shared.ItemUtility)
            _favCache.replionData    = require(ReplicatedStorage.Packages.Replion).Client:WaitReplion("Data")
            _favCache.itemsFolder    = ReplicatedStorage:WaitForChild("Items")
            _favCache.variantsFolder = ReplicatedStorage:WaitForChild("Variants")
            _favCache.refsReady      = true
        end)
        return ok and _favCache.refsReady
    end

    local function toSet(arr)
        local s = {}
        for _, v in ipairs(arr) do s[v] = true end
        return s
    end

    local function favBuildFishList()
        _favFishList = {}
        if not _favCache.refsReady or not _favCache.itemsFolder then return end
        local function scanFolder(folder)
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("ModuleScript") then
                    local ok, data = pcall(require, child)
                    if ok and data and data.Data then
                        local name = data.Data.DisplayName or data.Data.Name
                        if name and not table.find(_favFishList, name) then
                            table.insert(_favFishList, name)
                        end
                    end
                elseif child:IsA("Folder") then
                    scanFolder(child)
                end
            end
        end
        pcall(function()
            scanFolder(_favCache.itemsFolder)
            table.sort(_favFishList)
        end)
    end

    local function favBuildVariantList()
        _favVariantList = {}
        if not _favCache.refsReady or not _favCache.variantsFolder then return end
        pcall(function()
            for _, m in ipairs(_favCache.variantsFolder:GetChildren()) do
                if m:IsA("ModuleScript") and m.Name ~= "1x1x1x1" and not table.find(_favVariantList, m.Name) then
                    table.insert(_favVariantList, m.Name)
                end
            end
            table.sort(_favVariantList)
        end)
    end

    local function favScanInventory()
        if not _favState.enabled    then return end
        if not _favCache.refsReady  then return end
        if _favState.isScanning     then return end

        local hasName    = next(_favState.selectedName)    ~= nil
        local hasVariant = next(_favState.selectedVariant) ~= nil
        local hasRarity  = next(_favState.selectedRarity)  ~= nil

        if not hasName and not hasVariant and not hasRarity then return end

        _favState.isScanning = true
        pcall(function()
            local inventory = _favCache.replionData:GetExpect({"Inventory", "Items"})
            for _, item in ipairs(inventory) do
                if not _favState.enabled then break end
                if item.Favorited then continue end

                local fishData = _favCache.itemUtility:GetItemData(item.Id)
                if not fishData or not fishData.Data then continue end

                local fishName  = fishData.Data.DisplayName or fishData.Data.Name
                local fishTier  = fishData.Data.Tier
                local variantId = item.Metadata and item.Metadata.VariantId or "None"
                local tierName  = TIER_NAMES[fishTier]

                local shouldFav = false

                if hasName or hasVariant then
                    local nameOk    = true
                    local variantOk = true

                    if hasName then
                        nameOk = fishName ~= nil and _favState.selectedName[fishName] == true
                    end

                    if hasVariant then
                        variantOk = variantId ~= "None" and _favState.selectedVariant[variantId] == true
                    end

                    if nameOk and variantOk then
                        shouldFav = true
                    end
                end

                if hasRarity then
                    if tierName and _favState.selectedRarity[tierName] == true then
                        shouldFav = true
                    end
                end

                if shouldFav then
                    pcall(function() NetEvents.RE_FavoriteItem:FireServer(item.UUID) end)
                    task.wait(0.15)
                end
            end
        end)
        _favState.isScanning = false
    end

    task.spawn(function()
        if not game:IsLoaded() then game.Loaded:Wait() end
        task.wait(1)
        if not favInitRefs() then task.wait(2); favInitRefs() end
        favBuildFishList()
        favBuildVariantList()
    end)

    AutoFavSection:AddParagraph({
        Title   = "Filter Logic",
        Content = "Semua filter aktif bekerja bersamaan (AND). Pilih satu atau kombinasikan Name, Variant, dan Rarity.",
    })

    local nameDropdownRef = AutoFavSection:AddDropdown({
        Title    = "Name",
        Multi    = true,
        Options  = #_favFishList > 0 and _favFishList or {"Loading..."},
        Default  = {},
        Callback = function(selected)
            _favState.selectedName = toSet(type(selected) == "table" and selected or {})
            if _favState.enabled then task.spawn(favScanInventory) end
        end,
    })

    local variantDropdownRef = AutoFavSection:AddDropdown({
        Title    = "Variant",
        Multi    = true,
        Options  = #_favVariantList > 0 and _favVariantList or {"Loading..."},
        Default  = {},
        Callback = function(selected)
            _favState.selectedVariant = toSet(type(selected) == "table" and selected or {})
            if _favState.enabled then task.spawn(favScanInventory) end
        end,
    })

    AutoFavSection:AddDropdown({
        Title    = "Rarity",
        Multi    = true,
        Options  = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","SECRET","FORGOTTEN"},
        Default  = {},
        Callback = function(selected)
            _favState.selectedRarity = toSet(type(selected) == "table" and selected or {})
            if _favState.enabled then task.spawn(favScanInventory) end
        end,
    })

    AutoFavSection:AddToggle({
        Title    = "Auto Favorite",
        Default  = false,
        Callback = function(on)
            if on then
                if not favInitRefs() then
                    Library:MakeNotify({ Title = "Auto Favorite", Content = "Failed to initialize", Delay = 3 })
                    return
                end

                _favState.enabled = true

                if Library and Library.ConfigSystem then
                    local sn = Library.ConfigSystem.Get("MultiDropdowns.Name",    {})
                    local sv = Library.ConfigSystem.Get("MultiDropdowns.Variant", {})
                    local sr = Library.ConfigSystem.Get("MultiDropdowns.Rarity",  {})
                    if type(sn) == "table" then _favState.selectedName    = toSet(sn) end
                    if type(sv) == "table" then _favState.selectedVariant = toSet(sv) end
                    if type(sr) == "table" then _favState.selectedRarity  = toSet(sr) end
                end

                task.spawn(favScanInventory)

                if not _favState.onChangeHooked and _favCache.replionData then
                    _favState.onChangeHooked = true
                    _favCache.replionData:OnChange({"Inventory", "Items"}, function()
                        if _favState.enabled then
                            task.spawn(function()
                                task.wait(0.3)
                                favScanInventory()
                            end)
                        end
                    end)
                end

                Library:MakeNotify({ Title = "Auto Favorite", Content = "Started", Delay = 2 })
            else
                _favState.enabled = false
                Library:MakeNotify({ Title = "Auto Favorite", Content = "Stopped", Delay = 2 })
            end
        end,
    })

    AutoFavSection:AddButton({
        Title    = "Refresh Lists",
        Callback = function()
            _favFishList    = {}
            _favVariantList = {}
            favBuildFishList()
            favBuildVariantList()

            if nameDropdownRef and nameDropdownRef.SetOptions then
                nameDropdownRef:SetOptions(#_favFishList > 0 and _favFishList or {"No Fish Found"})
            end
            if variantDropdownRef and variantDropdownRef.SetOptions then
                variantDropdownRef:SetOptions(#_favVariantList > 0 and _favVariantList or {"No Variants Found"})
            end

            Library:MakeNotify({
                Title   = "Refresh",
                Content = "Fish: " .. #_favFishList .. " | Variant: " .. #_favVariantList,
                Delay   = 3,
            })
        end,
    })
end

do
    local _tp = {
        SelectedIsland            = nil,
        SelectedPlayer            = nil,
        AutoTeleportEnabled       = false,
        AutoTeleportConnection    = nil,
        ReplicatedEventData       = {},
        EventDataLoaded           = false,
        WorkspaceEventCache       = {},
        IsTeleporting             = false,
        CurrentEventName          = nil,
        CachedEventPosition       = nil,
        CachedEventObject         = nil,
        IsEventActive             = false,
        LastManualScanTime        = 0,
        LastAutoScanTime          = 0,
        TeleportLoopThread        = nil,
        ScanCooldown              = 5,
        HeightOffset              = 15,
        SafeRadius                = 150,
        CheckInterval             = 8,
        WaitTimeout               = 300,
    }

    local _islandCoords = {
        ["Ancient Jungle"]        = Vector3.new(1467.848,    7.447,    -327.597),
        ["Ancient Ruin"]          = Vector3.new(6045.402,  -588.600,   4608.937),
        ["Coral Reefs"]           = Vector3.new(-2921.858,   3.249,   2083.297),
        ["Crater Island"]         = Vector3.new(1078.454,    5.072,   5099.396),
        ["Esoteric Depths"]       = Vector3.new(3224.075, -1302.854,  1404.934),
        ["Fisherman Island"]      = Vector3.new(92.806,      9.531,   2762.082),
        ["Kohana"]                = Vector3.new(-643.305,   16.035,    622.360),
        ["Kohana Volcano"]        = Vector3.new(-572.024,   39.492,    112.492),
        ["Lost Isle"]             = Vector3.new(-3701.151,   5.425,  -1058.910),
        ["Sysiphus Statue"]       = Vector3.new(-3656.562, -134.531,  -964.316),
        ["Sacred Temple"]         = Vector3.new(1476.308,  -21.849,   -630.822),
        ["Treasure Room"]         = Vector3.new(-3601.568, -266.573, -1578.998),
        ["Tropical Grove"]        = Vector3.new(-2104.467,   6.268,   3718.254),
        ["Underground Cellar"]    = Vector3.new(2162.577,  -91.198,   -725.591),
        ["Pirate Cove"]           = Vector3.new(3334.47,    10.2,     3502.92),
        ["Leviathan Den"]         = Vector3.new(3471.41,  -287.84,    3468.87),
        ["Pirate Treasure Room"]  = Vector3.new(3337.64,  -302.75,    3089.56),
        ["Crystal Depths"]        = Vector3.new(5729.04,  -904.82,   15407.97),
        ["Vulcanic Cavern"]       = Vector3.new(1118.181,   85.990, -10250.158),
        ["Lava Basin"]            = Vector3.new(871.716,    96.938, -10176.625),
        ["Weather Machine"]       = Vector3.new(-1513.924,   6.499,   1892.106),
        ["Underwater City"]       = Vector3.new(-3140.417, -643.484,-10421.276),
        ["Planetary Observatory"] = Vector3.new(390.897,     7.251,   2205.069),
        ["Sawers"]                = Vector3.new(-1449.486,-1041.597,-10443.539),
        ["Easter Cave"]           = Vector3.new( 1061.720,  -48.696,   2645.637),
        ["Easter Island"]         = Vector3.new( 1134.182,    4.831,   2745.896),
    }

    local _eventFallback = {
        ["Shark Hunt"]      = {
            Vector3.new(1.649,    -1.350, 2095.72),
            Vector3.new(1369.94,  -1.350,  930.125),
            Vector3.new(-1585.5,  -1.350, 1242.87),
            Vector3.new(-1896.8,  -1.350, 2634.37),
        },
        ["Worm Hunt"]       = {
            Vector3.new(2190.85,  -1.399,   97.574),
            Vector3.new(-2450.6,  -1.399,  139.731),
            Vector3.new(-267.47,  -1.399, 5188.53),
        },
        ["Megalodon Hunt"]  = {
            Vector3.new(-1076.3,  -1.399, 1676.19),
            Vector3.new(-1191.8,  -1.399, 3597.30),
            Vector3.new(412.700,  -1.399, 4134.39),
        },
        ["Ghost Shark Hunt"] = {
            Vector3.new(489.558,  -1.350,   25.406),
            Vector3.new(-1358.2,  -1.350, 4100.55),
            Vector3.new(627.859,  -1.350, 3798.08),
        },
    }

    local HttpService = game:GetService("HttpService")
    local SAVE_FOLDER = "LynxGUI_Configs"
    local SAVE_FILE   = SAVE_FOLDER .. "/LynxSavedLocation.json"

    local function _notify(title, desc, color)
        Library:MakeNotify({
            Title       = title,
            Description = desc,
            Delay       = 3,
        })
    end

    local function _getRootPart()
        local char = LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    local function _forceTeleport(targetCFrame)
        task.spawn(function()
            for _ = 1, 10 do
                local root = _getRootPart()
                if root then root.CFrame = targetCFrame end
                task.wait(0.1)
            end
        end)
    end

    local function _loadSavedPosition()
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(SAVE_FILE))
        end)
        if not ok or not data then return nil end
        return CFrame.new(table.unpack(data))
    end

    local function _isAlive(obj)
        if not obj then return false end
        local ok, result = pcall(function()
            return obj.Parent ~= nil and obj:IsDescendantOf(workspace)
        end)
        return ok and result
    end

    local function _posFromInstance(obj)
        if obj:IsA("Model") then
            if obj.PrimaryPart then return obj.PrimaryPart.Position end
            local ok, cf, size = pcall(function() return obj:GetBoundingBox() end)
            if ok and cf then
                return Vector3.new(cf.Position.X, cf.Position.Y - (size.Y / 4), cf.Position.Z)
            end
        elseif obj:IsA("BasePart") then
            return obj.Position
        end
    end

    local function _withOffset(pos)
        return Vector3.new(pos.X, pos.Y + _tp.HeightOffset, pos.Z)
    end

    local function _doTeleport(targetPos)
        local root = _getRootPart()
        if not root then return false end
        if (root.Position - targetPos).Magnitude <= _tp.SafeRadius then return true end

        local ok = pcall(function()
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local r    = char:FindFirstChild("HumanoidRootPart")
            if not r then return end
            if char.PrimaryPart then
                char:PivotTo(CFrame.new(targetPos))
            else
                r.CFrame = CFrame.new(targetPos)
            end
            r.Anchored = false
            r.Velocity = Vector3.zero
        end)
        return ok
    end

    local function _findPropsContainers(parent, result, depth)
        depth  = depth  or 0
        result = result or {}
        if depth > 4 then return end
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "Props" and (child:IsA("Model") or child:IsA("Folder")) then
                table.insert(result, child)
            end
            if child:IsA("Model") or child:IsA("Folder") then
                _findPropsContainers(child, result, depth + 1)
            end
        end
        return result
    end

    local function _loadEventData()
        local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
        if not eventsFolder then
            local ok, res = pcall(function() return ReplicatedStorage:WaitForChild("Events", 5) end)
            if ok and res then eventsFolder = res end
        end
        if not eventsFolder then return end

        _tp.ReplicatedEventData = {}
        for _, child in ipairs(eventsFolder:GetChildren()) do
            if child:IsA("ModuleScript") then
                local ok, data = pcall(function() return require(child) end)
                if ok and data and type(data) == "table" and data.Name then
                    local coords = {}
                    if data.Coordinates then
                        for _, c in ipairs(data.Coordinates) do table.insert(coords, c) end
                    end
                    _tp.ReplicatedEventData[data.Name] = { coords = coords, icon = data.Icon }
                end
            end
        end
        _tp.EventDataLoaded = true
    end

    local function _scanAllProps()
        local now = tick()
        if now - _tp.LastAutoScanTime < 3 then return _tp.WorkspaceEventCache end
        _tp.LastAutoScanTime = now

        if not _tp.EventDataLoaded then _loadEventData() end
        _tp.WorkspaceEventCache = {}

        for _, container in ipairs(_findPropsContainers(workspace)) do
            for _, item in ipairs(container:GetChildren()) do
                local matched = nil
                if _tp.ReplicatedEventData[item.Name] then
                    matched = item.Name
                else
                    for eventName in pairs(_tp.ReplicatedEventData) do
                        if item.Name:find(eventName, 1, true) or eventName:find(item.Name, 1, true) then
                            matched = eventName; break
                        end
                    end
                end
                if matched and _isAlive(item) then
                    local pos = _posFromInstance(item)
                    if pos then
                        _tp.WorkspaceEventCache[matched] = { position = _withOffset(pos), object = item }
                    end
                end
            end
        end
        return _tp.WorkspaceEventCache
    end

    local function _scanEventPos(eventName)
        local now = tick()
        if now - _tp.LastManualScanTime < _tp.ScanCooldown then
            if _tp.CachedEventPosition and _isAlive(_tp.CachedEventObject) then
                return _tp.CachedEventPosition
            end
        end
        _tp.LastManualScanTime = now
        _scanAllProps()

        local cached = _tp.WorkspaceEventCache[eventName]
        if cached and _isAlive(cached.object) then
            _tp.CachedEventPosition = cached.position
            _tp.CachedEventObject   = cached.object
            _tp.IsEventActive       = true
            return _tp.CachedEventPosition
        end

        local allCoords = {}
        local rep = _tp.ReplicatedEventData[eventName]
        if rep and rep.coords then for _, c in ipairs(rep.coords) do table.insert(allCoords, c) end end
        local fb = _eventFallback[eventName]
        if fb then for _, c in ipairs(fb) do table.insert(allCoords, c) end end

        for _, coord in ipairs(allCoords) do
            local region = Region3.new(
                coord - Vector3.new(50, 50, 50),
                coord + Vector3.new(50, 50, 50)
            ):ExpandToGrid(4)
            local ok, parts = pcall(function() return workspace:FindPartsInRegion3(region, nil, 100) end)
            if ok and parts then
                for _, part in ipairs(parts) do
                    if typeof(part) == "Instance"
                        and part:IsA("BasePart")
                        and _isAlive(part)
                        and (part.Position - coord).Magnitude <= 40
                    then
                        _tp.CachedEventPosition = _withOffset(part.Position)
                        _tp.CachedEventObject   = part
                        _tp.IsEventActive       = true
                        return _tp.CachedEventPosition
                    end
                end
            end
        end

        _tp.IsEventActive = false
        return nil
    end

    local function _getEventNameList()
        if not _tp.EventDataLoaded then _loadEventData() end
        _scanAllProps()
        local list, seen = {}, {}
        for name in pairs(_tp.ReplicatedEventData) do
            if not seen[name] then
                seen[name] = true
                table.insert(list, _tp.WorkspaceEventCache[name] and (name .. " *") or name)
            end
        end
        for name in pairs(_tp.WorkspaceEventCache) do
            if not seen[name] then
                seen[name] = true
                table.insert(list, name .. " *")
            end
        end
        table.sort(list)
        return list
    end

    local function _cleanEventName(name)
        return name and name:gsub(" %*$", "") or nil
    end

    local function _stopEventTeleport()
        _tp.IsTeleporting       = false
        _tp.CachedEventPosition = nil
        _tp.CachedEventObject   = nil
        _tp.IsEventActive       = false
        if _tp.TeleportLoopThread and _tp.TeleportLoopThread ~= coroutine.running() then
            task.cancel(_tp.TeleportLoopThread)
        end
        _tp.TeleportLoopThread = nil
    end

    local function _startEventTeleport(eventName)
        if _tp.IsTeleporting then return false end
        if not _tp.EventDataLoaded then _loadEventData() end

        _tp.IsTeleporting       = true
        _tp.CurrentEventName    = eventName
        _tp.CachedEventPosition = nil
        _tp.CachedEventObject   = nil
        _tp.IsEventActive       = false
        _tp.LastManualScanTime  = 0

        _tp.TeleportLoopThread = task.spawn(function()
            local startTime   = tick()
            local eventPos    = nil
            while tick() - startTime < _tp.WaitTimeout do
                eventPos = _scanEventPos(eventName)
                if eventPos then break end
                task.wait(5)
            end
            if not eventPos then _stopEventTeleport(); return end

            _doTeleport(eventPos)

            local failCount = 0
            while _tp.IsTeleporting do
                if _tp.CachedEventObject and not _isAlive(_tp.CachedEventObject) then
                    _tp.CachedEventPosition = nil
                    _tp.CachedEventObject   = nil
                    _tp.IsEventActive       = false
                end
                local newPos = _scanEventPos(eventName)
                if newPos then
                    _doTeleport(newPos)
                    failCount = 0
                else
                    failCount += 1
                    if failCount >= 3 then _stopEventTeleport(); break end
                end
                task.wait(_tp.CheckInterval)
            end
        end)
        return true
    end

    workspace.ChildAdded:Connect(function(child)
        if child.Name == "Props" then
            task.wait(0.5)
            _tp.LastAutoScanTime = 0
            _scanAllProps()
        end
    end)
    workspace.ChildRemoved:Connect(function(child)
        if child.Name == "Props" then
            _tp.LastAutoScanTime = 0
            _scanAllProps()
        end
    end)
    workspace.DescendantAdded:Connect(function(desc)
        if desc.Name == "Props" and (desc:IsA("Model") or desc:IsA("Folder")) then
            task.wait(0.5)
            _tp.LastAutoScanTime = 0
            _scanAllProps()
        end
    end)

    task.spawn(function()
        task.wait(2)
        _loadEventData()
        _scanAllProps()
    end)

    local TeleportTab = MainWindow:AddTab({ Name = "Teleport", Icon = "gps" })

    local IslandSection  = TeleportTab:AddSection("Teleport to Island")
    local _islandList    = {}
    for name in pairs(_islandCoords) do table.insert(_islandList, name) end
    table.sort(_islandList)

    IslandSection:AddDropdown({
        Title    = "Select Island",
        Multi    = false,
        Options  = _islandList,
        Default  = nil,
        Callback = function(v)
            _tp.SelectedIsland = v
        end,
    })

    IslandSection:AddButton({
        Title    = "Teleport",
        Callback = function()
            if not _tp.SelectedIsland or _tp.SelectedIsland == "" then
                _notify("Teleport", "Pilih island dulu dari dropdown!", Color3.fromRGB(255, 179, 71))
                return
            end
            local targetPos = _islandCoords[_tp.SelectedIsland]
            if not targetPos then
                _notify("Teleport", "Island tidak valid!", Color3.fromRGB(255, 85, 127))
                return
            end
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local root = char:WaitForChild("HumanoidRootPart")
            root.CFrame = CFrame.new(targetPos)
            _notify("Teleport", "Teleported to " .. _tp.SelectedIsland, Color3.fromRGB(123, 239, 178))
        end,
    })

    local PlayerSection  = TeleportTab:AddSection("Teleport to Player", false)
    local _playerList    = {}
    local _playerDropRef = nil

    local function _refreshPlayerList()
        table.clear(_playerList)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then table.insert(_playerList, player.Name) end
        end
        table.sort(_playerList)
    end
    _refreshPlayerList()

    _playerDropRef = PlayerSection:AddDropdown({
        Title    = "Select Player",
        Multi    = false,
        Options  = _playerList,
        Default  = nil,
        NoSave   = false,
        Callback = function(v)
            _tp.SelectedPlayer = v
        end,
    })

    PlayerSection:AddButton({
        Title    = "Teleport Now",
        Callback = function()
            if not _tp.SelectedPlayer or _tp.SelectedPlayer == "" then
                _notify("Teleport", "Pilih player dulu dari dropdown!", Color3.fromRGB(255, 179, 71))
                return
            end
            local target  = Players:FindFirstChild(_tp.SelectedPlayer)
            local myChar  = LocalPlayer.Character
            if not target or not target.Character then
                _notify("Teleport", "Player tidak ditemukan!", Color3.fromRGB(255, 85, 127))
                return
            end
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            local myRoot     = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if targetRoot and myRoot then
                myRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
                _notify("Teleport", "Teleported to " .. _tp.SelectedPlayer, Color3.fromRGB(123, 239, 178))
            else
                _notify("Teleport", "HumanoidRootPart tidak ditemukan!", Color3.fromRGB(255, 85, 127))
            end
        end,
    })

    PlayerSection:AddButton({
        Title    = "Refresh Player List",
        Callback = function()
            _refreshPlayerList()
            if _playerDropRef and _playerDropRef.SetValues then
                _playerDropRef:SetValues(_playerList, nil)
            end
            _notify("Teleport", "Player list diperbarui.", Color3.fromRGB(100, 200, 255))
        end,
    })

    local SavedSection = TeleportTab:AddSection("Saved Location", false)

    SavedSection:AddButton({
        Title    = "Save Current Location",
        Callback = function()
            local root = _getRootPart()
            if not root then
                _notify("Error", "Character tidak ditemukan!", Color3.fromRGB(255, 85, 127))
                return
            end
            pcall(function()
                if not isfolder(SAVE_FOLDER) then makefolder(SAVE_FOLDER) end
            end)
            local ok = pcall(function()
                writefile(SAVE_FILE, HttpService:JSONEncode({ root.CFrame:GetComponents() }))
            end)
            if ok then
                _notify("Saved", "Lokasi berhasil disimpan!", Color3.fromRGB(123, 239, 178))
            else
                _notify("Error", "Gagal menyimpan lokasi!", Color3.fromRGB(255, 85, 127))
            end
        end,
    })

    SavedSection:AddButton({
        Title    = "Teleport to Saved",
        Callback = function()
            local savedCFrame = _loadSavedPosition()
            if not savedCFrame then
                _notify("Error", "Tidak ada lokasi tersimpan!", Color3.fromRGB(255, 85, 127))
                return
            end
            if not _getRootPart() then
                _notify("Error", "Character tidak ditemukan!", Color3.fromRGB(255, 85, 127))
                return
            end
            _forceTeleport(savedCFrame)
            _notify("Teleported", "Teleport ke lokasi tersimpan berhasil!", Color3.fromRGB(123, 239, 178))
        end,
    })

    SavedSection:AddButton({
        Title    = "Reset Saved Location",
        Callback = function()
            pcall(function()
                if isfile(SAVE_FILE) then delfile(SAVE_FILE) end
            end)
            _notify("Reset", "Lokasi tersimpan telah dihapus.", Color3.fromRGB(255, 179, 71))
        end,
    })

    SavedSection:AddToggle({
        Title    = "Auto Teleport on Spawn",
        Default  = false,
        Callback = function(on)
            if on then
                if _tp.AutoTeleportEnabled then return end
                _tp.AutoTeleportEnabled = true

                local function _onCharAdded(char)
                    task.spawn(function()
                        local root = char:WaitForChild("HumanoidRootPart", 10)
                        if not root then return end
                        task.wait(1.5)
                        local saved = _loadSavedPosition()
                        if saved then
                            _forceTeleport(saved)
                            _notify("Auto Teleport", "Teleported ke lokasi tersimpan!", Color3.fromRGB(123, 239, 178))
                        end
                    end)
                end

                _tp.AutoTeleportConnection = LocalPlayer.CharacterAdded:Connect(_onCharAdded)
                if LocalPlayer.Character then _onCharAdded(LocalPlayer.Character) end
            else
                _tp.AutoTeleportEnabled = false
                if _tp.AutoTeleportConnection then
                    _tp.AutoTeleportConnection:Disconnect()
                    _tp.AutoTeleportConnection = nil
                end
            end
        end,
    })

    local _ev = {
        active         = false,
        selectedEvents = {},
        priorityEvent  = nil,
        loopThread     = nil,
        origCF         = nil,
        curCF          = nil,
        curEventName   = nil,
        flt            = false,
        con            = nil,
    }

    local LocalPlayer = game.Players.LocalPlayer
    local RS          = game:GetService("ReplicatedStorage")
    local RunService  = game:GetService("RunService")

    local _evReplion  = require(RS.Packages.Replion).Client:WaitReplion("Events")
    local _evData     = require(RS.Events)

    local _ignoreList = {
        Cloudy             = true,
        Day                = true,
        ["Increased Luck"] = true,
        Mutated            = true,
        Night              = true,
        Snow               = true,
        ["Sparkling Cove"] = true,
        Storm              = true,
        Wind               = true,
        Radiant            = true,
        ["Present Rain"]   = true,
        ["Admin - Super Mutated"]     = true,
        ["Admin - Shocked"]           = true,
        ["Admin - MEGA Luck"]         = true,
        ["Admin - Super Luck"]        = true,
        ["Admin - Night Celebration"] = true,
        ["Admin - Forgotten Tier"]    = true,
        ["Admin - Galaxy Storm"]      = true,
    }

    local TELEPORT_OFFSET = 12

    local function _getActiveEventNames()
        local active = _evReplion:Get("Events")
        if not active then return {} end
        local result = {}
        for _, name in pairs(active) do
            if typeof(name) == "string" then
                result[name] = true
            end
        end
        return result
    end

    local function _getEventList()
        local result = {}
        for eventId, info in pairs(_evData) do
            if info.Coordinates and not _ignoreList[eventId] then
                table.insert(result, eventId)
            end
        end
        table.sort(result)
        return result
    end

    local function _getRoot(char)
        return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart"))
    end

    local function _setAnchored(char, state)
        if not char then return end
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.Anchored = state end
        end
    end

    local function _setFloat(char, root, enabled)
        if _ev.flt and _ev.con then _ev.con:Disconnect() end
        _ev.flt = enabled or false
        if enabled then
            local fp = char:FindFirstChild("FloatPart") or Instance.new("Part")
            fp.CanCollide   = true
            fp.Anchored     = true
            fp.Transparency = 1
            fp.Size         = Vector3.new(3, 0.2, 3)
            fp.Name         = "FloatPart"
            fp.Parent       = char
            _ev.con = RunService.Heartbeat:Connect(function()
                if char and root and fp then
                    fp.CFrame = root.CFrame * CFrame.new(0, -3.1, 0)
                end
            end)
        else
            local fp = char and char:FindFirstChild("FloatPart")
            if fp then fp:Destroy() end
        end
    end

    local function _findEventPart(eventName)
        if not eventName then return nil end

        local propsFolders = {}
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name == "Props" then
                table.insert(propsFolders, obj)
            end
        end

        for _, props in ipairs(propsFolders) do
            for _, group in ipairs(props:GetChildren()) do
                for _, desc in ipairs(group:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Name == "DisplayName" then
                        local txt = desc.ContentText ~= "" and desc.ContentText or desc.Text
                        if txt:lower() == eventName:lower() then
                            local part = desc:FindFirstAncestorWhichIsA("BasePart")
                            if part then return part end
                            local p = group:FindFirstChild("Part")
                            if p and p:IsA("BasePart") then return p end
                        end
                    end
                end
            end
        end

        for _, props in ipairs(propsFolders) do
            local group = props:FindFirstChild(eventName)
            if group then
                local namedPart = group:FindFirstChild(eventName, true)
                if namedPart and namedPart:IsA("BasePart") then return namedPart end
                local p = group:FindFirstChild("Part")
                if p and p:IsA("BasePart") then return p end
                local bestPart = nil
                local lowestY  = math.huge
                for _, desc in ipairs(group:GetDescendants()) do
                    if desc:IsA("BasePart") and desc.Position.Y < lowestY and desc.Position.Y > -10 then
                        lowestY  = desc.Position.Y
                        bestPart = desc
                    end
                end
                if bestPart then return bestPart end
            end
        end

        local info = _evData[eventName]
        if info and info.Coordinates and #info.Coordinates > 0 then
            local root    = _getRoot(LocalPlayer.Character)
            local bestPos = info.Coordinates[1]

            if #info.Coordinates > 1 and root then
                local closestDist = math.huge
                for _, coord in ipairs(info.Coordinates) do
                    local dist = (root.Position - coord).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        bestPos     = coord
                    end
                end
            end

            local fake = Instance.new("Part")
            fake.Anchored     = true
            fake.CanCollide   = false
            fake.Transparency = 1
            fake.Size         = Vector3.new(1, 1, 1)
            fake.CFrame       = CFrame.new(bestPos)
            fake.Parent       = workspace
            task.delay(5, function() pcall(function() fake:Destroy() end) end)
            return fake
        end

        return nil
    end

    local function _stopEvent()
        _ev.active = false
        if _ev.loopThread then task.cancel(_ev.loopThread); _ev.loopThread = nil end
        local char = LocalPlayer.Character
        _setAnchored(char, false)
        _setFloat(char, nil, false)
        if _ev.origCF and char then char:PivotTo(_ev.origCF) end
        _ev.origCF       = nil
        _ev.curCF        = nil
        _ev.curEventName = nil
    end

    local function _startEvent()
        if _ev.active then _stopEvent() end
        if #_ev.selectedEvents == 0 and not _ev.priorityEvent then return false end

        _ev.active       = true
        _ev.origCF       = nil
        _ev.curCF        = nil
        _ev.curEventName = nil

        _ev.loopThread = task.spawn(function()
            while _ev.active do
                local activeNames = _getActiveEventNames()
                local foundPart   = nil
                local foundName   = nil

                if _ev.priorityEvent and activeNames[_ev.priorityEvent] then
                    local part = _findEventPart(_ev.priorityEvent)
                    if part then
                        foundPart = part
                        foundName = _ev.priorityEvent
                    end
                end

                if not foundPart then
                    for _, evName in ipairs(_ev.selectedEvents) do
                        if activeNames[evName] then
                            local part = _findEventPart(evName)
                            if part then
                                foundPart = part
                                foundName = evName
                                break
                            end
                        end
                    end
                end

                local char = LocalPlayer.Character
                local root = _getRoot(char)

                if foundPart and root then
                    if _ev.curEventName ~= foundName then
                        _setAnchored(char, false)
                        _setFloat(char, nil, false)
                        _ev.curCF        = nil
                        _ev.curEventName = foundName
                    end

                    if not _ev.origCF then
                        _ev.origCF = root.CFrame
                    end

                    if (root.Position - foundPart.Position).Magnitude > 40 then
                        local targetPos = Vector3.new(
                            foundPart.Position.X,
                            foundPart.Position.Y + TELEPORT_OFFSET,
                            foundPart.Position.Z
                        )
                        _ev.curCF = CFrame.new(targetPos)
                        char:PivotTo(_ev.curCF)
                        _setFloat(char, root, true)
                    end

                elseif foundPart == nil and _ev.curCF and root then
                    _setAnchored(char, false)
                    _setFloat(char, nil, false)
                    if _ev.origCF then
                        char:PivotTo(_ev.origCF)
                        _ev.origCF = nil
                    end
                    _ev.curCF        = nil
                    _ev.curEventName = nil
                end

                task.wait(0.2)
            end

            local char = LocalPlayer.Character
            _setAnchored(char, false)
            _setFloat(char, nil, false)
            if _ev.origCF and char then char:PivotTo(_ev.origCF) end
            _ev.origCF       = nil
            _ev.curCF        = nil
            _ev.curEventName = nil
        end)

        return true
    end

    LocalPlayer.CharacterAdded:Connect(function(char)
        if not _ev.active then return end
        task.spawn(function()
            local root = char:WaitForChild("HumanoidRootPart", 5)
            task.wait(0.3)
            if not root then return end
            if _ev.curCF then
                char:PivotTo(_ev.curCF)
                _setFloat(char, root, true)
            elseif _ev.origCF then
                char:PivotTo(_ev.origCF)
                _setFloat(char, root, true)
            end
        end)
    end)

    local EventSection = TeleportTab:AddSection("Event Teleport", false)
    local _dropRef     = nil
    local _toggleRef   = nil

    local function _refreshDropdown(silent)
        local names = _getEventList()
        if _dropRef and _dropRef.Refresh then
            local keepList = {}
            for _, sel in ipairs(_ev.selectedEvents) do
                for _, name in ipairs(names) do
                    if name == sel then table.insert(keepList, name); break end
                end
            end
            _dropRef:Refresh(names, #keepList == 0)
            if #keepList > 0 then pcall(function() _dropRef:SetValue(keepList) end) end
        end
        if _priorityDropRef and _priorityDropRef.Refresh then
            local keepPriority = nil
            if _ev.priorityEvent then
                for _, name in ipairs(names) do
                    if name == _ev.priorityEvent then keepPriority = name; break end
                end
            end
            _priorityDropRef:Refresh(names, keepPriority == nil)
            if keepPriority then pcall(function() _priorityDropRef:SetValue(keepPriority) end) end
        end
        if not silent then
            _notify("Event Scan", "Ditemukan " .. #names .. " event.", Color3.fromRGB(100, 200, 255))
        end
    end

    _dropRef = EventSection:AddDropdown({
        Title    = "Select Event",
        Options  = _getEventList(),
        Default  = nil,
        Multi    = true,
        Callback = function(selected)
            _ev.selectedEvents = type(selected) == "table" and selected or (selected and { selected } or {})
            if _toggleRef and _toggleRef.Value and #_ev.selectedEvents > 0 then
                _stopEvent()
                task.wait(0.1)
                _startEvent()
            end
        end,
    })

    local _priorityDropRef = nil
    _priorityDropRef = EventSection:AddDropdown({
        Title    = "Priority Event",
        Options  = _getEventList(),
        Default  = nil,
        Multi    = false,
        Callback = function(selected)
            _ev.priorityEvent = (selected and selected ~= "") and selected or nil
            if _toggleRef and _toggleRef.Value then
                _stopEvent()
                task.wait(0.1)
                _startEvent()
            end
        end,
    })

    EventSection:AddButton({
        Title    = "Refresh Event List",
        Callback = function() _refreshDropdown(false) end,
    })

    _toggleRef = EventSection:AddToggle({
        Title    = "Auto Event Teleport",
        Default  = false,
        Callback = function(on)
            if on then
                if #_ev.selectedEvents == 0 then
                    _notify("Auto Teleport", "Pilih event terlebih dahulu!", Color3.fromRGB(255, 100, 100))
                    if _toggleRef then _toggleRef:SetValue(false) end
                    return
                end
                local ok = _startEvent()
                if ok then
                    _notify("Auto Teleport", "Monitoring " .. #_ev.selectedEvents .. " event...", Color3.fromRGB(100, 200, 255))
                else
                    _notify("Auto Teleport", "Gagal start. Pilih event lagi.", Color3.fromRGB(255, 180, 50))
                    if _toggleRef then _toggleRef:SetValue(false) end
                end
            else
                _stopEvent()
                _notify("Auto Teleport", "Auto teleport dimatikan.", Color3.fromRGB(255, 100, 100))
            end
        end,
    })

    _evReplion:OnChange("Events", function()
        _refreshDropdown(true)
    end)

    task.spawn(function()
        task.wait(3)
        _refreshDropdown(true)
        while task.wait(10) do
            if not _ev.active then
                _refreshDropdown(true)
            end
        end
    end)
end

do
    local ItemUtility, ReplionData
    pcall(function()
        ItemUtility  = require(ReplicatedStorage.Shared.ItemUtility)
        ReplionData  = require(ReplicatedStorage.Packages.Replion).Client:GetReplion("Data")
    end)

    local ShopTab            = MainWindow:AddTab({ Name = "Shop", Icon = "cart" })
    local SellPresentSection = ShopTab:AddSection("Auto Sell Present")
    local _presentState      = { enabled = false, interval = 10, task = nil, lastSell = 0 }

    SellPresentSection:AddInput({
        Title    = "Interval (Seconds)",
        Default  = "10",
        Callback = function(value)
            local n = tonumber(value)
            if n and n >= 1 then _presentState.interval = n end
        end,
    })

    SellPresentSection:AddToggle({
        Title    = "Enable Auto Sell Present",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                if _presentState.enabled then return end
                local sellRemote = NetEvents.RF_SellItem
                if not sellRemote or not ReplionData or not ItemUtility then return end

                _presentState.enabled = true
                _presentState.task = task.spawn(function()
                    while _presentState.enabled do
                        pcall(function()
                            if tick() - _presentState.lastSell >= 0.5 then
                                local inventory = ReplionData:GetExpect({"Inventory", "Items"})
                                for _, item in ipairs(inventory) do
                                    local d = ItemUtility:GetItemData(item.Id)
                                    if d and d.Present == true then
                                        pcall(function() sellRemote:InvokeServer(item.UUID) end)
                                        task.wait(0.1)
                                    end
                                end
                                _presentState.lastSell = tick()
                            end
                        end)
                        task.wait(_presentState.interval)
                    end
                end)
            else
                _presentState.enabled = false
                if _presentState.task then
                    task.cancel(_presentState.task)
                    _presentState.task = nil
                end
            end
        end,
    })

    SellPresentSection:AddButton({
        Title    = "Sell Present Now",
        Callback = function()
            local sellRemote = NetEvents.RF_SellItem
            if not sellRemote or not ReplionData or not ItemUtility then return end
            pcall(function()
                local inventory = ReplionData:GetExpect({"Inventory", "Items"})
                for _, item in ipairs(inventory) do
                    local d = ItemUtility:GetItemData(item.Id)
                    if d and d.Present == true then
                        pcall(function() sellRemote:InvokeServer(item.UUID) end)
                        task.wait(0.1)
                    end
                end
            end)
        end,
    })

    local SellSection = ShopTab:AddSection("Auto Sell")
    local _sellState  = { enabled = false, mode = "Timer", interval = 5, target = 235, lastSell = 0, timerTask = nil, countTask = nil }

    local function getSellAllRemote()
        return _G.EventResolver and _G.EventResolver:GetRemoteFunction("SellAllItems") or nil
    end
    local function parseNumber(text)
        if not text or text == "" then return 0 end
        local cleaned = tostring(text):gsub("%D", "")
        return tonumber(cleaned == "" and "0" or cleaned) or 0
    end
    local function getBagCount()
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if not gui then return 0 end
        local inv = gui:FindFirstChild("Inventory")
        if not inv then return 0 end
        local label = inv:FindFirstChild("Main")
            and inv.Main:FindFirstChild("Top")
            and inv.Main.Top:FindFirstChild("Options")
            and inv.Main.Top.Options:FindFirstChild("Fish")
            and inv.Main.Top.Options.Fish:FindFirstChild("Label")
            and inv.Main.Top.Options.Fish.Label:FindFirstChild("BagSize")
        if not label or not label:IsA("TextLabel") then return 0 end
        local cur = label.Text:match("(.+)%/")
        return parseNumber(cur)
    end
    local function executeSellAll()
        local remote = getSellAllRemote()
        if not remote then return end
        if tick() - _sellState.lastSell < 0.5 then return end
        pcall(function() remote:InvokeServer() end)
        _sellState.lastSell = tick()
    end
    local function stopSellLoops()
        if _sellState.timerTask then task.cancel(_sellState.timerTask); _sellState.timerTask = nil end
        if _sellState.countTask then task.cancel(_sellState.countTask); _sellState.countTask = nil end
    end
    local function startSellLoop()
        stopSellLoops()
        if _sellState.mode == "Timer" then
            _sellState.timerTask = task.spawn(function()
                while _sellState.enabled do
                    task.wait(_sellState.interval)
                    if _sellState.enabled then executeSellAll() end
                end
            end)
        else
            _sellState.countTask = task.spawn(function()
                local lastSellTime = 0
                while _sellState.enabled do
                    task.wait(1.5)
                    if not _sellState.enabled then break end
                    local current = getBagCount()
                    if current >= _sellState.target and tick() - lastSellTime >= 3 then
                        lastSellTime = tick()
                        executeSellAll()
                        task.wait(2)
                    end
                end
            end)
        end
    end

    SellSection:AddButton({ Title = "Sell All Now", Callback = executeSellAll })

    SellSection:AddDropdown({
        Title    = "Auto Sell Mode",
        Options  = {"Timer", "By Count"},
        Default  = "Timer",
        Callback = function(selected)
            _sellState.mode = selected
            if _sellState.enabled then startSellLoop() end
        end,
    })

    SellSection:AddInput({
        Title    = "Value (Seconds / Fish Count)",
        Default  = "5",
        Callback = function(value)
            local n = tonumber(value)
            if n and n >= 1 then
                _sellState.interval = n
                _sellState.target   = n
            end
        end,
    })

    SellSection:AddToggle({
        Title    = "Enable Auto Sell",
        Default  = false,
        Callback = function(on)
            _sellState.enabled = on
            if on then
                if not getSellAllRemote() then _sellState.enabled = false; return end
                startSellLoop()
            else
                stopSellLoops()
            end
        end,
    })

    local WeatherSection = ShopTab:AddSection("Auto Buy Weather")
    local _weatherState  = { enabled = false, selected = {"Cloudy", "Storm", "Wind"}, task = nil }

    WeatherSection:AddDropdown({
        Title    = "Weather",
        Multi    = true,
        Options  = {"Cloudy", "Storm", "Wind", "Snow", "Radiant", "Shark Hunt"},
        Default  = _weatherState.selected,
        Callback = function(selected)
            _weatherState.selected = type(selected) == "table" and selected or {}
        end,
    })

    WeatherSection:AddToggle({
        Title    = "Enable Auto Buy Weather",
        Default  = false,
        Callback = function(on)
            if on then
                if _weatherState.enabled then return end
                if #_weatherState.selected == 0 then return end
                local remote = _G.EventResolver and _G.EventResolver:GetRemoteFunction("PurchaseWeatherEvent") or nil
                if not remote then return end
                _weatherState.enabled = true
                _weatherState.task = task.spawn(function()
                    while _weatherState.enabled do
                        for _, weather in ipairs(_weatherState.selected) do
                            if not _weatherState.enabled then break end
                            pcall(function() remote:InvokeServer(weather) end)
                            task.wait(0.1)
                        end
                        task.wait(10)
                    end
                end)
            else
                _weatherState.enabled = false
                if _weatherState.task then
                    task.cancel(_weatherState.task)
                    _weatherState.task = nil
                end
            end
        end,
    })

    local MerchantSection = ShopTab:AddSection("Remote Merchant")
    local PlayerGui       = LocalPlayer:FindFirstChild("PlayerGui")

    MerchantSection:AddButton({
        Title    = "Open Merchant",
        Callback = function()
            pcall(function()
                local gui      = PlayerGui or LocalPlayer:WaitForChild("PlayerGui", 5)
                local merchant = gui and (gui:FindFirstChild("Merchant") or gui:WaitForChild("Merchant", 3))
                if merchant then merchant.Enabled = true end
            end)
        end,
    })

    MerchantSection:AddButton({
        Title    = "Close Merchant",
        Callback = function()
            pcall(function()
                local gui      = PlayerGui or LocalPlayer:FindFirstChild("PlayerGui")
                local merchant = gui and gui:FindFirstChild("Merchant")
                if merchant then merchant.Enabled = false end
            end)
        end,
    })
end

do

    local AutoTab = MainWindow:AddTab({ Name = "Automation", Icon = "next" })
    local CS      = game:GetService("CollectionService")
    local RS      = game:GetService("ReplicatedStorage")
    local Replion = require(RS.Packages.Replion)

    local EggHuntSection = AutoTab:AddSection("Easter Egg Event", false)
    local _eggHunt       = { enabled = false, delay = 1.5, task = nil }
    local _eggPlace      = { enabled = false, delay = 1.5, task = nil }

    local ISLAND_POSITIONS = {
        [1] = Vector3.new(32.52,   9.88,  2810.28),
        [2] = Vector3.new(-643.30, 16.03, 622.36),
        [3] = Vector3.new(1146.24, 10.83, 2688.45),
    }

    local function getDataReplion()
        local ok, result = pcall(function() return Replion.Client:WaitReplion("Data") end)
        return ok and result or nil
    end

    local function firePrompt(prompt)
        local ok = pcall(fireproximityprompt, prompt)
        if not ok then
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(0.15)
                prompt:InputHoldEnd()
            end)
        end
    end

    local function teleportTo(part)
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0)) end
    end

    local function teleportToIsland(step)
        local pos  = ISLAND_POSITIONS[step]
        if not pos then return false end
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
        return true
    end

    local function isNearIsland(step, radius)
        local pos  = ISLAND_POSITIONS[step]
        if not pos then return false end
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        return (hrp.Position - pos).Magnitude < (radius or 300)
    end

    local function forceEnableEggHunt(prompt, currentStep)
        local parent = prompt.Parent
        local step   = tonumber(parent.Name)
        local active = step == currentStep

        parent.Transparency = active and 0 or 1
        prompt.Enabled      = active

        local sound = parent:FindFirstChildOfClass("Sound")
        if sound then sound.Volume = active and 0.5 or 0 end

        for _, v in parent:GetDescendants() do
            if v:IsA("ParticleEmitter") then v.Enabled = active end
        end

        return active
    end

    local function getEggHuntTargets(currentStep)
        local targets = {}
        for _, prompt in ipairs(CS:GetTagged("EggHunt")) do
            if prompt:IsA("ProximityPrompt") then
                local isActive = forceEnableEggHunt(prompt, currentStep)
                if isActive then
                    local parent = prompt.Parent
                    local part   = parent:IsA("BasePart") and parent
                                or parent:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        table.insert(targets, { prompt = prompt, part = part, name = parent.Name })
                    end
                end
            end
        end
        return targets
    end

    local function getEnabledPrompts(tag)
        local targets = {}
        for _, prompt in ipairs(CS:GetTagged(tag)) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                local parent = prompt.Parent
                local part   = parent:IsA("BasePart") and parent
                            or parent:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    table.insert(targets, { prompt = prompt, part = part, name = parent.Name })
                end
            end
        end
        return targets
    end

    EggHuntSection:AddParagraph({
        Title   = "Info",
        Content = "Auto Egg Hunt  → Teleport ke pulau sesuai step lalu ambil egg otomatis.\nAuto Place Eggs → Place egg Mosiac sesuai step (tag: EasterMosiacEgg).",
    })

    EggHuntSection:AddToggle({
        Title    = "Enable Auto Egg Hunt",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                if _eggHunt.enabled then return end
                local dataReplion = getDataReplion()
                if not dataReplion then
                    Library:MakeNotify({ Title = "Auto Egg Hunt", Description = "Gagal mendapatkan Data replion!", Delay = 3 })
                    return
                end
                _eggHunt.enabled = true
                Library:MakeNotify({ Title = "Auto Egg Hunt", Description = "Auto Egg Hunt dimulai...", Delay = 2 })
                _eggHunt.task = task.spawn(function()
                    while _eggHunt.enabled do
                        local currentStep = dataReplion:Get("EasterHuntStep") or 0

                        if ISLAND_POSITIONS[currentStep] and not isNearIsland(currentStep) then
                            Library:MakeNotify({ Title = "Auto Egg Hunt", Description = "Teleport ke pulau step " .. currentStep .. "...", Delay = 2 })
                            teleportToIsland(currentStep)
                            local waited = 0
                            repeat
                                task.wait(1)
                                waited = waited + 1
                                if not _eggHunt.enabled then return end
                            until #getEggHuntTargets(currentStep) > 0 or waited >= 10
                        end

                        local targets = getEggHuntTargets(currentStep)

                        if #targets == 0 then
                            task.wait(1)
                        else
                            Library:MakeNotify({ Title = "Auto Egg Hunt", Description = "Step " .. currentStep .. " — " .. #targets .. " egg ditemukan!", Delay = 3 })

                            local done = 0
                            for _, target in ipairs(targets) do
                                if not _eggHunt.enabled then break end
                                teleportTo(target.part)
                                task.wait(0.4)
                                if not _eggHunt.enabled then break end
                                forceEnableEggHunt(target.prompt, currentStep)
                                firePrompt(target.prompt)
                                done = done + 1
                                Library:MakeNotify({ Title = "Auto Egg Hunt", Description = "[" .. done .. "/" .. #targets .. "] " .. target.name, Delay = 2 })
                                task.wait(_eggHunt.delay)
                            end

                            if _eggHunt.enabled then
                                Library:MakeNotify({ Title = "Auto Egg Hunt", Description = "Step " .. currentStep .. " selesai! Menunggu step berikutnya...", Delay = 3 })
                                local newStep = currentStep
                                while _eggHunt.enabled and newStep == currentStep do
                                    task.wait(1)
                                    newStep = dataReplion:Get("EasterHuntStep") or 0
                                end
                            end
                        end
                    end
                end)
            else
                _eggHunt.enabled = false
                if _eggHunt.task then task.cancel(_eggHunt.task); _eggHunt.task = nil end
                Library:MakeNotify({ Title = "Auto Egg Hunt", Description = "Auto Egg Hunt dihentikan.", Delay = 2 })
            end
        end,
    })

    EggHuntSection:AddToggle({
        Title    = "Enable Auto Place Eggs",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                if _eggPlace.enabled then return end
                local dataReplion = getDataReplion()
                if not dataReplion then
                    Library:MakeNotify({ Title = "Auto Place Eggs", Description = "Gagal mendapatkan Data replion!", Delay = 3 })
                    return
                end
                _eggPlace.enabled = true
                Library:MakeNotify({ Title = "Auto Place Eggs", Description = "Auto Place Eggs dimulai...", Delay = 2 })
                _eggPlace.task = task.spawn(function()
                    while _eggPlace.enabled do
                        local currentStep = dataReplion:Get("EasterHuntStep") or 0
                        local targets     = getEnabledPrompts("EasterMosiacEgg")

                        if #targets == 0 then
                            task.wait(1)
                        else
                            Library:MakeNotify({ Title = "Auto Place Eggs", Description = "Step " .. currentStep .. " — " .. #targets .. " slot ditemukan!", Delay = 3 })

                            local done = 0
                            for _, target in ipairs(targets) do
                                if not _eggPlace.enabled then break end
                                teleportTo(target.part)
                                task.wait(0.4)
                                if not _eggPlace.enabled then break end
                                firePrompt(target.prompt)
                                done = done + 1
                                Library:MakeNotify({ Title = "Auto Place Eggs", Description = "[" .. done .. "/" .. #targets .. "] " .. target.name, Delay = 2 })
                                task.wait(_eggPlace.delay)
                            end

                            if _eggPlace.enabled then
                                Library:MakeNotify({ Title = "Auto Place Eggs", Description = "Semua egg diplace! Menunggu step berikutnya...", Delay = 3 })
                                local newStep = currentStep
                                while _eggPlace.enabled and newStep == currentStep do
                                    task.wait(1)
                                    newStep = dataReplion:Get("EasterHuntStep") or 0
                                end
                            end
                        end
                    end
                end)
            else
                _eggPlace.enabled = false
                if _eggPlace.task then task.cancel(_eggPlace.task); _eggPlace.task = nil end
                Library:MakeNotify({ Title = "Auto Place Eggs", Description = "Auto Place Eggs dihentikan.", Delay = 2 })
            end
        end,
    })

    local BuyCharmSection = AutoTab:AddSection("Auto Buy Charm", false)

    local _charmState = {
        charmList    = {},
        selectedId   = nil,
        selectedName = nil,
        selectedPrice= nil,
        amount       = 1,
        delay        = 0.5,
        isBuying     = false,
    }

    local _charmPriceParagraph = BuyCharmSection:AddParagraph({
        Title   = "Charm Info",
        Content = "Memuat daftar charm...",
    })

    local _charmDropdown = BuyCharmSection:AddDropdown({
        Title    = "Charm Type",
        Options  = { "Loading..." },
        Default  = "Loading...",
        Callback = function(selected)
            for _, entry in ipairs(_charmState.charmList) do
                if entry.Name == selected then
                    _charmState.selectedId    = entry.Id
                    _charmState.selectedName  = entry.Name
                    _charmState.selectedPrice = entry.Price
                    _charmPriceParagraph:SetContent(
                        "Name: " .. entry.Name .. "\nPrice: " .. tostring(entry.Price) .. " coins"
                    )
                    break
                end
            end
        end,
    })

    task.spawn(function()
        task.wait(2)
        pcall(function()
            local RS           = game:GetService("ReplicatedStorage")
            local charmsFolder = RS:WaitForChild("Charms", 10)
            local newList      = {}

            for _, mod in ipairs(charmsFolder:GetChildren()) do
                if mod:IsA("ModuleScript") then
                    local ok, data = pcall(require, mod)
                    if ok and type(data) == "table" and data.Data then
                        local price = data.Price or 0
                        if price > 0 then
                            table.insert(newList, {
                                Name  = tostring(data.Data.Name or mod.Name),
                                Id    = data.Data.Id,
                                Price = price,
                            })
                        end
                    end
                end
            end

            table.sort(newList, function(a, b) return (a.Id or 9999) < (b.Id or 9999) end)
            _charmState.charmList = newList

            local names = {}
            for _, e in ipairs(newList) do table.insert(names, e.Name) end

            if #names > 0 then
                if _charmDropdown and _charmDropdown.SetOptions then
                    _charmDropdown:SetOptions(names)
                end
                local first = newList[1]
                _charmState.selectedId    = first.Id
                _charmState.selectedName  = first.Name
                _charmState.selectedPrice = first.Price
                _charmPriceParagraph:SetContent(
                    "Name: " .. first.Name .. "\nPrice: " .. tostring(first.Price) .. " coins"
                )
            else
                _charmPriceParagraph:SetContent("Tidak ada charm ditemukan di game.")
            end
        end)
    end)

    BuyCharmSection:AddInput({
        Title    = "Amount",
        Default  = "1",
        Callback = function(value)
            local n = tonumber(value)
            if n and n > 0 and n <= 1000 then
                _charmState.amount = math.floor(n)
            end
        end,
    })

    BuyCharmSection:AddInput({
        Title    = "Delay (Seconds)",
        Default  = "0.5",
        Callback = function(value)
            local n = tonumber(value)
            if n and n >= 0 and n <= 10 then
                _charmState.delay = n
            end
        end,
    })

    BuyCharmSection:AddButton({
        Title    = "Buy Charm",
        Callback = function()
            if _charmState.isBuying then return end
            if not _charmState.selectedId then return end

            local remote = NetEvents.RF_PurchaseCharm
            if not remote then return end

            _charmState.isBuying = true
            task.spawn(function()
                local total = _charmState.amount
                local id    = _charmState.selectedId
                for i = 1, total do
                    if not _charmState.isBuying then break end
                    pcall(function() remote:InvokeServer(id) end)
                    if i < total and _charmState.isBuying then
                        task.wait(_charmState.delay)
                    end
                end
                _charmState.isBuying = false
            end)
        end,
    })

    BuyCharmSection:AddButton({
        Title    = "Stop Buying",
        Callback = function()
            _charmState.isBuying = false
        end,
    })

    BuyCharmSection:AddButton({
        Title    = "Refresh Charm List",
        Callback = function()
            pcall(function()
                local RS           = game:GetService("ReplicatedStorage")
                local charmsFolder = RS:WaitForChild("Charms", 10)
                local newList      = {}

                for _, mod in ipairs(charmsFolder:GetChildren()) do
                    if mod:IsA("ModuleScript") then
                        local ok, data = pcall(require, mod)
                        if ok and type(data) == "table" and data.Data then
                            local price = data.Price or 0
                            if price > 0 then
                                table.insert(newList, {
                                    Name  = tostring(data.Data.Name or mod.Name),
                                    Id    = data.Data.Id,
                                    Price = price,
                                })
                            end
                        end
                    end
                end

                table.sort(newList, function(a, b) return (a.Id or 9999) < (b.Id or 9999) end)
                _charmState.charmList = newList

                local names = {}
                for _, e in ipairs(newList) do table.insert(names, e.Name) end

                if #names > 0 then
                    if _charmDropdown and _charmDropdown.SetOptions then
                        _charmDropdown:SetOptions(names)
                    end
                    local first = newList[1]
                    _charmState.selectedId    = first.Id
                    _charmState.selectedName  = first.Name
                    _charmState.selectedPrice = first.Price
                    _charmPriceParagraph:SetContent(
                        "Name: " .. first.Name .. "\nPrice: " .. tostring(first.Price) .. " coins"
                    )
                else
                    _charmPriceParagraph:SetContent("Tidak ada charm ditemukan.")
                end
            end)
        end,
    })

    local ClaimSection = AutoTab:AddSection("Auto Claim Pirate Chest", false)

    local _claimState = { enabled = false, task = nil, watcher = nil }

    local function claimChest(chestName)
        pcall(function()
            local r = _G.EventResolver:GetRemoteEvent("ClaimPirateChest")
            if r then r:FireServer(chestName) end
        end)
    end

    ClaimSection:AddToggle({
        Title    = "Enable Auto Claim",
        Default  = false,
        Callback = function(on)
            if on then
                if _claimState.enabled then return end
                _claimState.enabled = true

                _claimState.task = task.spawn(function()
                    while _claimState.enabled do
                        pcall(function()
                            local chestStorage = Workspace:FindFirstChild("PirateChestStorage")
                            if chestStorage then
                                for _, chest in pairs(chestStorage:GetChildren()) do
                                    if not _claimState.enabled then break end
                                    if chest:IsA("Model") then
                                        claimChest(chest.Name)
                                        task.wait(1.0)
                                    end
                                end
                            end
                        end)
                        task.wait(0.3)
                    end
                end)

                _claimState.watcher = Workspace.DescendantAdded:Connect(function(d)
                    if not _claimState.enabled then return end
                    if d.Parent and d.Parent.Name == "PirateChestStorage" then
                        task.wait(0.2)
                        if d:IsA("Model") then
                            claimChest(d.Name)
                        end
                    end
                end)
            else
                _claimState.enabled = false
                if _claimState.task    then task.cancel(_claimState.task);    _claimState.task    = nil end
                if _claimState.watcher then _claimState.watcher:Disconnect(); _claimState.watcher = nil end
            end
        end,
    })

    local PotionSection = AutoTab:AddSection("Auto Use Potion", false)

    local _potionState = {
        enabled  = false,
        task     = nil,
        selected = {},
        interval = 30,
    }

    local POTIONS = {
        { Name = "Luck I Potion",     Id = 1  },
        { Name = "Coin I Potion",     Id = 2  },
        { Name = "Mutation I Potion", Id = 4  },
        { Name = "Luck II Potion",    Id = 6  },
        { Name = "Love I Potion",     Id = 15 },
    }

    local POTION_NAMES   = {}
    local POTION_BY_NAME = {}
    for _, p in ipairs(POTIONS) do
        table.insert(POTION_NAMES, p.Name)
        POTION_BY_NAME[p.Name] = p
    end

    PotionSection:AddDropdown({
        Title    = "Select Potions",
        Options  = POTION_NAMES,
        Multi    = true,
        Default  = {},
        Callback = function(selected)
            _potionState.selected = selected or {}
        end,
    })

    PotionSection:AddInput({
        Title    = "Interval (Seconds)",
        Default  = "30",
        Callback = function(value)
            local n = tonumber(value)
            if n and n >= 1 then _potionState.interval = n end
        end,
    })

    PotionSection:AddToggle({
        Title    = "Auto Use Potions",
        Default  = false,
        Callback = function(on)
            if on then
                if _potionState.enabled then return end
                if #_potionState.selected == 0 then return end

                local RS   = game:GetService("ReplicatedStorage")
                local Data = nil
                pcall(function()
                    Data = require(RS.Packages.Replion).Client:WaitReplion("Data")
                end)
                if not Data then return end

                _potionState.enabled = true
                _potionState.task    = task.spawn(function()
                    while _potionState.enabled do
                        pcall(function()
                            local inventory = Data:GetExpect({ "Inventory", "Potions" })
                            if not inventory then return end

                            for _, potionName in ipairs(_potionState.selected) do
                                local potion = POTION_BY_NAME[potionName]
                                if potion then
                                    for _, item in ipairs(inventory) do
                                        if item.Id == potion.Id then
                                            pcall(function()
                                                NetEvents.RF_ConsumePotion:InvokeServer(item.UUID, 1)
                                            end)
                                            break
                                        end
                                    end
                                end
                            end
                        end)
                        task.wait(_potionState.interval)
                    end
                end)
            else
                _potionState.enabled = false
                if _potionState.task then
                    task.cancel(_potionState.task)
                    _potionState.task = nil
                end
            end
        end,
    })

    local EnchantSection = AutoTab:AddSection("Enchant Features", false)

    local _enchantState = {
        enabled              = false,
        task                 = nil,
        rollCount            = 0,
        targetEnchantId      = 10,
        targetEnchantName    = "XPerienced I",
        enchantType          = 1,
        enchantStoneItemId   = 10,
        waitingForUpdate     = false,
        currentCycleRunning  = false,
    }

    local enchantMapping = {}
    local enchantNames   = {}
    pcall(function()
        local RS           = game:GetService("ReplicatedStorage")
        local enchantFolder = RS:WaitForChild("Enchants", 10)
        if enchantFolder then
            for _, child in ipairs(enchantFolder:GetChildren()) do
                if child:IsA("ModuleScript") then
                    local ok, data = pcall(require, child)
                    if ok and data and data.Data and data.Data.Name and data.Data.Id then
                        enchantMapping[data.Data.Name] = data.Data.Id
                        table.insert(enchantNames, data.Data.Name)
                    end
                end
            end
            table.sort(enchantNames)
        end
    end)

    local _enchantData = nil
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        _enchantData = require(RS.Packages.Replion).Client:WaitReplion("Data")
    end)

    local EnchantStatusParagraph = EnchantSection:AddParagraph({
        Title   = "Enchant Status",
        Content = "Current Rod : None\nCurrent Enchant : None\nEnchant Stones Left : 0",
    })

    task.spawn(function()
        local RS          = game:GetService("ReplicatedStorage")
        local ItemUtility = nil
        pcall(function() ItemUtility = require(RS.Shared.ItemUtility) end)

        while true do
            task.wait(2)
            if not _enchantData or not ItemUtility then continue end
            pcall(function()
                local rodName    = "None"
                local enchantName = "None"
                local stoneCount = 0

                local equippedItems = _enchantData:Get("EquippedItems") or {}
                local fishingRods   = _enchantData:Get({"Inventory", "Fishing Rods"}) or {}

                for _, uuid in pairs(equippedItems) do
                    for _, rod in ipairs(fishingRods) do
                        if rod.UUID == uuid then
                            local itemData = ItemUtility:GetItemData(rod.Id)
                            rodName = itemData and itemData.Data.Name or "None"
                            if rod.Metadata and rod.Metadata.EnchantId then
                                local eData = ItemUtility:GetEnchantData(rod.Metadata.EnchantId)
                                if eData and eData.Data and eData.Data.Name then
                                    enchantName = eData.Data.Name
                                end
                            end
                            break
                        end
                    end
                end

                for _, item in pairs(_enchantData:GetExpect({"Inventory", "Items"})) do
                    if item.Id == _enchantState.enchantStoneItemId then
                        stoneCount = stoneCount + 1
                    end
                end

                EnchantStatusParagraph:SetContent(
                    ("Current Rod : %s\nCurrent Enchant : %s\nEnchant Stones Left : %d"):format(
                        rodName, enchantName, stoneCount
                    )
                )
            end)
        end
    end)

    pcall(function()
        local RS           = game:GetService("ReplicatedStorage")
        local UpdateRemote = RS.Packages._Index["ytrev_replion@2.0.0-rc.3"].replion.Remotes.Update

        if UpdateRemote then
            UpdateRemote.OnClientEvent:Connect(function(_, path, data)
                if not _enchantState.enabled or not _enchantState.waitingForUpdate then return end

                _enchantState.waitingForUpdate    = false
                _enchantState.currentCycleRunning = false

                if path and type(path) == "table" and #path >= 4 then
                    if path[1] == "Inventory" and path[2] == "Fishing Rods" and path[4] == "Metadata" then
                        if data and data.EnchantId then
                            _enchantState.rollCount = _enchantState.rollCount + 1

                            if data.EnchantId == _enchantState.targetEnchantId then
                                _enchantState.enabled = false
                            else
                                task.wait(8)
                                if _enchantState.enabled then
                                    task.spawn(function() _enchantState.currentCycleRunning = false end)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)

    EnchantSection:AddDropdown({
        Title    = "Enchant Type",
        Options  = { "Normal Enchant", "Second Enchant", "Evolved Enchant", "Candy Enchant" },
        Default  = "Normal Enchant",
        Callback = function(value)
            if value == "Evolved Enchant" then
                _enchantState.enchantStoneItemId = 558
                _enchantState.enchantType        = 1
            elseif value == "Second Enchant" then
                _enchantState.enchantStoneItemId = 246
                _enchantState.enchantType        = 2
            elseif value == "Candy Enchant" then
                _enchantState.enchantStoneItemId = 714
                _enchantState.enchantType        = 1
            else
                _enchantState.enchantStoneItemId = 10
                _enchantState.enchantType        = 1
            end
        end,
    })

    EnchantSection:AddDropdown({
        Title    = "Target Enchant",
        Options  = enchantNames,
        Default  = "XPerienced I",
        Callback = function(value)
            local id = enchantMapping[value]
            if id then
                _enchantState.targetEnchantId   = id
                _enchantState.targetEnchantName = value
            end
        end,
    })

    EnchantSection:AddToggle({
        Title    = "Auto Enchant Reroll",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                if _enchantState.enabled then return end
                _enchantState.enabled             = true
                _enchantState.rollCount           = 0
                _enchantState.waitingForUpdate    = false
                _enchantState.currentCycleRunning = false

                _enchantState.task = task.spawn(function()
                    local LP = game:GetService("Players").LocalPlayer

                    while _enchantState.enabled do
                        if _enchantState.currentCycleRunning then
                            task.wait(0.5)
                            continue
                        end

                        _enchantState.currentCycleRunning = true

                        local character = LP.Character
                        if not character or not character:FindFirstChild("HumanoidRootPart") then
                            _enchantState.currentCycleRunning = false
                            task.wait(1)
                            continue
                        end

                        if _enchantState.enchantType == 2 then
                            character.HumanoidRootPart.CFrame = CFrame.new(1478.29846, 126.044891, -613.519653)
                        else
                            character.HumanoidRootPart.CFrame = CFrame.new(3245, -1301, 1394)
                        end
                        task.wait(2)

                        if not _enchantState.enabled then break end

                        local stoneUUID = nil
                        pcall(function()
                            for _, item in pairs(_enchantData:GetExpect({"Inventory", "Items"})) do
                                if item.Id == _enchantState.enchantStoneItemId then
                                    stoneUUID = item.UUID
                                    break
                                end
                            end
                        end)

                        if not stoneUUID then
                            _enchantState.enabled             = false
                            _enchantState.currentCycleRunning = false
                            break
                        end

                        local slotKey = nil
                        local timeout = tick()
                        while tick() - timeout < 5 do
                            if not _enchantState.enabled then break end
                            local equippedItems = _enchantData:Get("EquippedItems") or {}
                            for key, uuid in pairs(equippedItems) do
                                if uuid == stoneUUID then slotKey = key end
                            end
                            if not slotKey then
                                pcall(function() NetEvents.RE_EquipItem:FireServer(stoneUUID, "Enchant Stones") end)
                                task.wait(0.3)
                            else
                                break
                            end
                        end

                        if not slotKey or not _enchantState.enabled then
                            _enchantState.currentCycleRunning = false
                            task.wait(1)
                            continue
                        end

                        pcall(function() NetEvents.RF_EquipToolFromHotbar:FireServer(slotKey) end)
                        task.wait(0.2)

                        for _ = 1, 3 do
                            pcall(function()
                                if _enchantState.enchantType == 2 then
                                    NetEvents.RE_ActivateSecondEnchantingAltar:FireServer()
                                else
                                    NetEvents.RE_ActivateEnchantingAltar:FireServer()
                                end
                            end)
                            task.wait(0.5)
                        end

                        _enchantState.waitingForUpdate = true
                        pcall(function() NetEvents.RE_RollEnchant:FireServer() end)

                        local startTime = tick()
                        while _enchantState.waitingForUpdate and tick() - startTime < 3.5 do
                            task.wait(0.1)
                        end
                        _enchantState.waitingForUpdate = false

                        task.wait(0.5)
                    end
                end)
            else
                _enchantState.enabled             = false
                _enchantState.waitingForUpdate    = false
                _enchantState.currentCycleRunning = false
                if _enchantState.task then
                    task.cancel(_enchantState.task)
                    _enchantState.task = nil
                end
            end
        end,
    })

    EnchantSection:AddButton({
        Title    = "Teleport to Altar 1",
        Callback = function()
            local character = game:GetService("Players").LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = CFrame.new(3245, -1301, 1394)
            end
        end,
    })

    EnchantSection:AddButton({
        Title    = "Teleport to Altar 2",
        Callback = function()
            local character = game:GetService("Players").LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = CFrame.new(1478.29846, 126.044891, -613.519653)
            end
        end,
    })

    local TotemSection = AutoTab:AddSection("Auto Spawn Totem", false)

    local _totemState = {
        enabled       = false,
        task          = nil,
        selectedTotem = "Luck Totem",
        interval      = 3605,
        data          = nil,
        remote        = nil,
    }

    local TOTEM_DATA = {
        ["Luck Totem"]     = { Id = 1 },
        ["Mutation Totem"] = { Id = 2 },
        ["Shiny Totem"]    = { Id = 3 },
    }

    local TOTEM_NAMES = { "Luck Totem", "Mutation Totem", "Shiny Totem" }

    local function initTotemRefs()
        if _totemState.data and _totemState.remote then return true end
        local ok = pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            _totemState.data   = require(RS.Packages.Replion).Client:WaitReplion("Data")
            _totemState.remote = _G.EventResolver:GetRemoteEvent("SpawnTotem")
        end)
        return ok and _totemState.data ~= nil and _totemState.remote ~= nil
    end

    local function spawnTotemNow()
        if not initTotemRefs() then
            warn("[AutoSpawnTotem] Gagal init remote/data")
            return
        end
        pcall(function()
            local entry    = TOTEM_DATA[_totemState.selectedTotem]
            local targetId = entry and entry.Id
            if not targetId then return end

            local totemUUID = nil
            local ok, inv   = pcall(function() return _totemState.data:Get("Inventory") end)
            if ok and inv and inv.Totems then
                for _, item in pairs(inv.Totems) do
                    if item and item.UUID and tonumber(item.Id) == targetId then
                        if (item.Count or 1) >= 1 then
                            totemUUID = item.UUID
                            break
                        end
                    end
                end
            end

            if totemUUID then
                pcall(function() _totemState.remote:FireServer(totemUUID) end)
                print("[AutoSpawnTotem] Spawned: " .. _totemState.selectedTotem)
            else
                warn("[AutoSpawnTotem] Totem tidak ada di inventory: " .. _totemState.selectedTotem)
            end
        end)
    end

    TotemSection:AddDropdown({
        Title    = "Totem Type",
        Options  = TOTEM_NAMES,
        Default  = "Luck Totem",
        Callback = function(selected)
            _totemState.selectedTotem = selected
        end,
    })

    TotemSection:AddToggle({
        Title    = "Enable Auto Spawn",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                if _totemState.enabled then return end
                if not initTotemRefs() then
                    warn("[AutoSpawnTotem] Gagal init remote/data")
                    return
                end

                _totemState.enabled = true
                _totemState.task    = task.spawn(function()
                    while _totemState.enabled do
                        spawnTotemNow()
                        task.wait(_totemState.interval)
                    end
                end)
            else
                _totemState.enabled = false
                if _totemState.task then
                    task.cancel(_totemState.task)
                    _totemState.task = nil
                end
            end
        end,
    })

    TotemSection:AddButton({
        Title    = "Spawn Now",
        Callback = function()
            spawnTotemNow()
        end,
    })

    local EVENT_LIST = {
        {
            Name          = "Ancient Lochness Monster",
            Position      = Vector3.new(6096.14, -585.92, 4669.50),
            LookDirection = Vector3.new(-0.8317, -0.4007, 0.3842),
            Duration      = 600,
            ScheduleWIB   = {
                { hour = 3,  minute = 0 },
                { hour = 7,  minute = 0 },
                { hour = 11, minute = 0 },
                { hour = 15, minute = 0 },
                { hour = 19, minute = 0 },
                { hour = 23, minute = 0 },
            },
        },
        {
            Name          = "Mutant Runic Koi",
            Position      = Vector3.new(-3140.3860, -643.4843, -10451.0654),
            LookDirection = Vector3.new(1.0000, 0.0000, -0.0054),
            Duration      = 600,
            ScheduleWIB   = {
                { hour = 3,  minute = 0 },
                { hour = 7,  minute = 0 },
                { hour = 11, minute = 0 },
                { hour = 15, minute = 0 },
                { hour = 19, minute = 0 },
                { hour = 23, minute = 0 },
            },
        },
    }

    local function ev_getUserOffset()
        local now     = DateTime.now()
        local utc     = now:ToUniversalTime()
        local local_t = now:ToLocalTime()
        local diff    = local_t.Hour - utc.Hour
        if diff > 12 then diff -= 24 elseif diff < -12 then diff += 24 end
        return diff
    end

    local function ev_getLocalSchedule(scheduleWIB)
        local diff     = ev_getUserOffset() - 7
        local schedule = {}
        for _, e in ipairs(scheduleWIB) do
            table.insert(schedule, { hour = (e.hour + diff) % 24, minute = e.minute })
        end
        table.sort(schedule, function(a, b)
            return a.hour == b.hour and a.minute < b.minute or a.hour < b.hour
        end)
        return schedule
    end

    local function ev_nowSeconds()
        local t = DateTime.now():ToLocalTime()
        return t.Hour * 3600 + t.Minute * 60 + t.Second
    end

    local function ev_isActive(schedule, duration)
        local now = ev_nowSeconds()
        for _, e in ipairs(schedule) do
            local s  = e.hour * 3600 + e.minute * 60
            local en = s + duration
            if en >= 86400 then
                if now >= s or now < (en - 86400) then return true end
            else
                if now >= s and now < en then return true end
            end
        end
        return false
    end

    local function ev_getNext(schedule)
        local now = ev_nowSeconds()
        for _, e in ipairs(schedule) do
            local s = e.hour * 3600 + e.minute * 60
            if s > now then return e, s - now end
        end
        local first = schedule[1]
        return first, (86400 - now) + first.hour * 3600 + first.minute * 60
    end

    local function ev_formatCountdown(sec)
        sec = math.floor(sec)
        local h = math.floor(sec / 3600)
        local m = math.floor((sec % 3600) / 60)
        local s = sec % 60
        if h > 0 then return ("%dh %dm %ds"):format(h, m, s)
        elseif m > 0 then return ("%dm %ds"):format(m, s)
        else return ("%ds"):format(s) end
    end

    local function ev_teleport(targetCFrame)
        for _ = 1, 10 do
            local char = game:GetService("Players").LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(1); continue end
            pcall(function()
                hrp.Anchored = true
                hrp.CFrame   = targetCFrame
                if char.PrimaryPart then char:PivotTo(targetCFrame) end
            end)
            task.wait(0.1)
            pcall(function()
                hrp.Anchored = false
                hrp.AssemblyLinearVelocity  = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
            task.wait(0.3)
            local hrp2 = char:FindFirstChild("HumanoidRootPart")
            if hrp2 and (hrp2.Position - targetCFrame.Position).Magnitude < 50 then return true end
            task.wait(0.3)
        end
        return false
    end

    local TIMEZONE_NAMES = { [7] = "WIB", [8] = "WITA", [9] = "WIT" }

    for _, cfg in ipairs(EVENT_LIST) do

        local _evState = {
            enabled    = false,
            task       = nil,
            eventStart = nil,
            savedPos   = nil,
        }

        local EventSection = AutoTab:AddSection("Auto " .. cfg.Name, false)

        local ScheduleParagraph = EventSection:AddParagraph({
            Title   = "Event Schedule",
            Content = "Loading schedule...",
        })

        local StatusParagraph = EventSection:AddParagraph({
            Title   = "Status",
            Content = "Idle...",
        })

        task.spawn(function()
            task.wait(0.5)
            local offset   = ev_getUserOffset()
            local tzName   = TIMEZONE_NAMES[offset] or ("UTC%+d"):format(offset)
            local schedule = ev_getLocalSchedule(cfg.ScheduleWIB)
            local text     = "Timezone: " .. tzName .. "\n\nEvent Times:\n"
            for i, e in ipairs(schedule) do
                text = text .. ("%d. %02d:%02d\n"):format(i, e.hour, e.minute)
            end
            text = text .. "\nDuration: " .. (cfg.Duration / 60) .. " minutes per event"
            ScheduleParagraph:SetContent(text)
        end)

        task.spawn(function()
            while true do
                task.wait(1)
                if not _evState.enabled then
                    StatusParagraph:SetTitle("Status")
                    StatusParagraph:SetContent("Idle...")
                    continue
                end
                local schedule = ev_getLocalSchedule(cfg.ScheduleWIB)
                if ev_isActive(schedule, cfg.Duration) then
                    local elapsed   = os.time() - (_evState.eventStart or os.time())
                    local remaining = math.max(0, cfg.Duration - elapsed)
                    StatusParagraph:SetTitle("EVENT ACTIVE")
                    StatusParagraph:SetContent(
                        "Location: " .. cfg.Name ..
                        "\nTime Left: " .. ev_formatCountdown(remaining)
                    )
                else
                    local nextEvent, secondsUntil = ev_getNext(schedule)
                    StatusParagraph:SetTitle("Waiting for Event")
                    StatusParagraph:SetContent(
                        ("Next Event: %02d:%02d\nStarts in: %s"):format(
                            nextEvent.hour, nextEvent.minute,
                            ev_formatCountdown(secondsUntil)
                        )
                    )
                end
            end
        end)

        EventSection:AddParagraph({
            Title   = "How it works",
            Content = "Automatically teleports to " .. cfg.Name .. " event.\n"
                   .. "• Saves your position before teleport\n"
                   .. "• Stays for " .. (cfg.Duration / 60) .. " minutes\n"
                   .. "• Returns to saved position after\n"
                   .. "• 6 events per day",
        })

        EventSection:AddButton({
            Title    = "Teleport Now",
            Callback = function()
                local char = game:GetService("Players").LocalPlayer.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then _evState.savedPos = hrp.CFrame end
                task.wait(0.3)
                ev_teleport(CFrame.lookAt(cfg.Position, cfg.Position + cfg.LookDirection))
            end,
        })

        EventSection:AddButton({
            Title    = "Return to Saved Position",
            Callback = function()
                if not _evState.savedPos then return end
                ev_teleport(_evState.savedPos)
                _evState.savedPos = nil
            end,
        })

        EventSection:AddToggle({
            Title    = "Enable Auto Event",
            Default  = false,
            Callback = function(on)
                if on then
                    if _evState.enabled then return end
                    _evState.enabled = true

                    _evState.task = task.spawn(function()
                        game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
                            if not _evState.enabled then return end
                            task.wait(3)
                            if ev_isActive(ev_getLocalSchedule(cfg.ScheduleWIB), cfg.Duration) then
                                task.wait(1)
                                ev_teleport(CFrame.lookAt(cfg.Position, cfg.Position + cfg.LookDirection))
                            end
                        end)

                        while _evState.enabled do
                            local schedule = ev_getLocalSchedule(cfg.ScheduleWIB)
                            if ev_isActive(schedule, cfg.Duration) then
                                local char = game:GetService("Players").LocalPlayer.Character
                                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                                if hrp then _evState.savedPos = hrp.CFrame end
                                task.wait(0.5)

                                local success = ev_teleport(
                                    CFrame.lookAt(cfg.Position, cfg.Position + cfg.LookDirection)
                                )

                                if success then
                                    _evState.eventStart = os.time()
                                    local countdown = cfg.Duration
                                    while countdown > 0 and _evState.enabled do
                                        task.wait(1)
                                        countdown -= 1
                                    end
                                    if _evState.enabled and _evState.savedPos then
                                        task.wait(1)
                                        ev_teleport(_evState.savedPos)
                                        _evState.savedPos = nil
                                    end
                                    _evState.eventStart = nil
                                else
                                    task.wait(10)
                                end
                            end
                            task.wait(1)
                        end
                    end)
                else
                    _evState.enabled = false
                    if _evState.task then
                        task.cancel(_evState.task)
                        _evState.task = nil
                    end
                end
            end,
        })

    end

end

do

    local TradeTab = MainWindow:AddTab({ Name = "Trade", Icon = "payment" })

    local RS      = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local LP      = Players.LocalPlayer

    local Replion, ItemUtility, VendorUtility, PlayerStatsUtility, TradeData
    local Data
    pcall(function()
        Replion              = require(RS.Packages.Replion)
        ItemUtility          = require(RS.Shared.ItemUtility)
        VendorUtility        = require(RS.Shared.VendorUtility)
        PlayerStatsUtility   = require(RS.Shared.PlayerStatsUtility)
        TradeData            = require(RS.Shared.Trading.TradeData)
        Data                 = Replion.Client:WaitReplion("Data")
    end)

    local TIER_FISH = {
        [1]="Common",[2]="Uncommon",[3]="Rare",
        [4]="Epic",[5]="Legendary",[6]="Mythic",[7]="Secret",
    }

    local ENCHANT_STONE_IDS = {
        ["Normal"] = 10, ["Double"] = 246, ["Evolved"] = 558,
    }

    local MAX_ITEMS_PER_TRADE = 20

    local _tradeState = {
        enabled               = false,
        task                  = nil,
        targetPlayer          = nil,
        playerManuallySelected = false,
        tradeMode             = "ByName",
        selectedItem          = nil,
        itemAmount            = 1,
        targetCoins           = 0,
        selectedRarity        = "Common",
        rarityAmount          = 1,
        selectedStoneType     = "Normal",
        stoneAmount           = 1,
        totalAttempted        = 0,
        totalSuccess          = 0,
        totalFailed           = 0,
        targetAmount          = 0,
        status                = "Idle",
        lastTradedItem        = "",
        coinTraded            = 0,
    }

    local _activeMonitorParagraph = nil
    local _activeToggleRef        = nil

    local function updateMonitor()
        if not _activeMonitorParagraph then return end
        local coinInfo = _tradeState.coinTraded > 0
            and ("\nCoins Traded: %d"):format(_tradeState.coinTraded)
            or ""
        pcall(function()
            _activeMonitorParagraph:SetContent(
                ("%s\nProgress: %d/%d | Success: %d | Failed: %d%s"):format(
                    _tradeState.status or "?",
                    _tradeState.totalSuccess,
                    _tradeState.targetAmount,
                    _tradeState.totalSuccess,
                    _tradeState.totalFailed,
                    coinInfo
                )
            )
        end)
    end

    local function setStatus(s)
        _tradeState.status = s
        updateMonitor()
    end

    local function executeTradeMulti(itemList, totalCoinValue)
        if not _tradeState.enabled then return false end
        if not itemList or #itemList == 0 then return false end

        local targetPlayer = Players:FindFirstChild(_tradeState.targetPlayer)
        if not targetPlayer then
            setStatus("Error: Player tidak ditemukan")
            return false
        end

        _tradeState.totalAttempted += 1
        local label = #itemList == 1
            and itemList[1].Name
            or ("%d items"):format(#itemList)
        setStatus(("Sending offer: %s (%d/%d)"):format(
            label, _tradeState.totalAttempted, _tradeState.targetAmount
        ))

        local tradeResult  = nil
        local tradeReplion = nil

        local connCompleted = TradeData.Remotes.TradeCompleted.OnClientEvent:Connect(function()
            if tradeResult == nil then tradeResult = true end
        end)
        local connEnded = TradeData.Remotes.TradeEnded.OnClientEvent:Connect(function()
            if tradeResult == nil then tradeResult = false end
        end)
        local connStarted = TradeData.Remotes.TradeStarted.OnClientEvent:Connect(function(replionId)
            local rep = Replion.Client:GetReplion(replionId)
            if rep then tradeReplion = rep end
        end)

        local sendOk, sendErr = pcall(function()
            TradeData.Remotes.SendTradeOffer:InvokeServer(targetPlayer)
        end)
        if not sendOk then
            connCompleted:Disconnect(); connEnded:Disconnect(); connStarted:Disconnect()
            _tradeState.totalFailed += 1
            setStatus("Error: Gagal kirim offer - " .. tostring(sendErr))
            updateMonitor(); task.wait(1)
            return false
        end

        local t0 = tick()
        while not tradeReplion and tick() - t0 < 15 do
            if not _tradeState.enabled then
                connCompleted:Disconnect(); connEnded:Disconnect(); connStarted:Disconnect()
                return false
            end
            task.wait(0.1)
        end
        connStarted:Disconnect()

        if not tradeReplion then
            connCompleted:Disconnect(); connEnded:Disconnect()
            _tradeState.totalFailed += 1
            setStatus("Error: Target tidak accept offer")
            updateMonitor(); task.wait(1)
            return false
        end

        setStatus(("Offer accepted! Adding %d item(s)..."):format(#itemList))

        for _, item in ipairs(itemList) do
            if not _tradeState.enabled then
                pcall(function() TradeData.Remotes.CancelTrade:InvokeServer() end)
                connCompleted:Disconnect(); connEnded:Disconnect()
                return false
            end
            if tradeResult ~= nil then
                connCompleted:Disconnect(); connEnded:Disconnect()
                _tradeState.totalFailed += 1
                setStatus("Failed: Trade berakhir saat add item")
                updateMonitor(); task.wait(1)
                return false
            end
            local addOk, addErr = pcall(function()
                TradeData.Remotes.AddItem:InvokeServer(item.Type, item.UUID)
            end)
            if not addOk then
                pcall(function() TradeData.Remotes.CancelTrade:InvokeServer() end)
                connCompleted:Disconnect(); connEnded:Disconnect()
                _tradeState.totalFailed += 1
                setStatus("Error: Gagal add item - " .. tostring(addErr))
                updateMonitor(); task.wait(1)
                return false
            end
            task.wait(0.05)
        end

        local lockDuration = TradeData.ConfirmCountdownTime or 5
        local tLock = tick()
        while tick() - tLock < lockDuration do
            if not _tradeState.enabled then
                pcall(function() TradeData.Remotes.CancelTrade:InvokeServer() end)
                connCompleted:Disconnect(); connEnded:Disconnect()
                return false
            end
            if tradeResult ~= nil then break end
            task.wait(0.1)
        end

        if tradeResult ~= nil then
            connCompleted:Disconnect(); connEnded:Disconnect()
            if tradeResult then
                _tradeState.totalSuccess   += 1
                _tradeState.lastTradedItem  = itemList[#itemList].Name
                _tradeState.coinTraded     += (totalCoinValue or 0)
                setStatus(("Success: %s (%d/%d)"):format(label, _tradeState.totalSuccess, _tradeState.targetAmount))
                updateMonitor(); task.wait(1.5)
                return true
            else
                _tradeState.totalFailed += 1
                setStatus(("Failed (cancel): %s"):format(label))
                updateMonitor(); task.wait(1)
                return false
            end
        end

        if not _tradeState.enabled then
            pcall(function() TradeData.Remotes.CancelTrade:InvokeServer() end)
            connCompleted:Disconnect(); connEnded:Disconnect()
            return false
        end

        setStatus("Setting ready...")
        local readyOk, readyErr = pcall(function()
            TradeData.Remotes.SetReady:InvokeServer(true)
        end)
        if not readyOk then
            pcall(function() TradeData.Remotes.CancelTrade:InvokeServer() end)
            connCompleted:Disconnect(); connEnded:Disconnect()
            _tradeState.totalFailed += 1
            setStatus("Error: SetReady gagal - " .. tostring(readyErr))
            updateMonitor(); task.wait(1)
            return false
        end

        local t1 = tick()
        local playersReady = false
        while tick() - t1 < 15 do
            if not _tradeState.enabled then
                pcall(function() TradeData.Remotes.CancelTrade:InvokeServer() end)
                connCompleted:Disconnect(); connEnded:Disconnect()
                return false
            end
            if tradeResult ~= nil then break end
            local d = tradeReplion.Data
            if d then
                if d.PlayersReady == true then
                    playersReady = true; break
                end
                if type(d.PlayersReady) == "table" then
                    local allReady = true
                    for _, v in pairs(d.PlayersReady) do
                        if not v then allReady = false; break end
                    end
                    if allReady then playersReady = true; break end
                end
            end
            task.wait(0.1)
        end

        if tradeResult ~= nil then
            connCompleted:Disconnect(); connEnded:Disconnect()
            if tradeResult then
                _tradeState.totalSuccess   += 1
                _tradeState.lastTradedItem  = itemList[#itemList].Name
                _tradeState.coinTraded     += (totalCoinValue or 0)
                setStatus(("Success: %s (%d/%d)"):format(label, _tradeState.totalSuccess, _tradeState.targetAmount))
                updateMonitor(); task.wait(1.5)
                return true
            else
                _tradeState.totalFailed += 1
                setStatus(("Failed: %s"):format(label))
                updateMonitor(); task.wait(1)
                return false
            end
        end

        if not playersReady then
            pcall(function() TradeData.Remotes.CancelTrade:InvokeServer() end)
            connCompleted:Disconnect(); connEnded:Disconnect()
            _tradeState.totalFailed += 1
            setStatus("Error: Lawan tidak ready")
            updateMonitor(); task.wait(1)
            return false
        end

        setStatus("Confirming trade...")
        pcall(function() TradeData.Remotes.ConfirmTrade:InvokeServer() end)

        local t2 = tick()
        while tradeResult == nil and tick() - t2 < 8 do
            if not _tradeState.enabled then break end
            task.wait(0.1)
        end

        connCompleted:Disconnect(); connEnded:Disconnect()

        if tradeResult == true then
            _tradeState.totalSuccess   += 1
            _tradeState.lastTradedItem  = itemList[#itemList].Name
            _tradeState.coinTraded     += (totalCoinValue or 0)
            setStatus(("Success: %s (%d/%d)"):format(label, _tradeState.totalSuccess, _tradeState.targetAmount))
            updateMonitor(); task.wait(1.5)
            return true
        else
            _tradeState.totalFailed += 1
            setStatus(("Failed: %s"):format(label))
            updateMonitor(); task.wait(1)
            return false
        end
    end

    local function getFreshFishByName(name)
        local result = {}
        local inventory = Data:GetExpect({"Inventory", "Items"})
        for _, item in ipairs(inventory) do
            if not item.Favorited then
                local d = ItemUtility.GetItemDataFromItemType("Items", item.Id)
                if d and d.Data.Type == "Fish" and d.Data.Name == name then
                    table.insert(result, { UUID=item.UUID, Type="Fish", Name=name, CoinValue=0 })
                end
            end
        end
        return result
    end

    local function getFreshFishByRarity(rarity)
        local result = {}
        local inventory = Data:GetExpect({"Inventory", "Items"})
        for _, item in ipairs(inventory) do
            if not item.Favorited then
                local d = ItemUtility.GetItemDataFromItemType("Items", item.Id)
                if d and d.Data and d.Data.Type == "Fish" then
                    if TIER_FISH[d.Data.Tier] == rarity then
                        table.insert(result, {
                            UUID=item.UUID,
                            Name=d.Data.Name or "Unknown",
                            Type=d.Data.Type,
                            CoinValue=0,
                        })
                    end
                end
            end
        end
        return result
    end

    local function runByName()
        local initialFish = getFreshFishByName(_tradeState.selectedItem)
        if #initialFish == 0 then setStatus("Error: Item tidak ada di inventory"); return end

        local total = math.min(_tradeState.itemAmount, #initialFish)
        _tradeState.targetAmount = math.ceil(total / MAX_ITEMS_PER_TRADE)
        local traded = 0

        while traded < total do
            if not _tradeState.enabled then break end
            local fresh = getFreshFishByName(_tradeState.selectedItem)
            if #fresh == 0 then setStatus("Error: Inventory habis"); break end
            local batchSize = math.min(MAX_ITEMS_PER_TRADE, total - traded, #fresh)
            local batch = {}
            for i = 1, batchSize do table.insert(batch, fresh[i]) end
            if #batch == 0 then break end
            local ok = executeTradeMulti(batch, 0)
            if ok then
                traded += #batch
            else
                task.wait(2)
            end
        end
    end

    local function runByCoin()
        local fishList = {}
        local inventory = Data:GetExpect({"Inventory", "Items"})
        local playerMods = PlayerStatsUtility:GetPlayerModifiers(LP)

        for _, item in ipairs(inventory) do
            if not item.Favorited then
                local d = ItemUtility:GetItemData(item.Id)
                if d and d.Data and d.Data.Type == "Fish" then
                    local sellPrice  = VendorUtility:GetSellPrice(item) or d.SellPrice or 0
                    local finalPrice = math.ceil(sellPrice * (playerMods and playerMods.CoinMultiplier or 1))
                    if finalPrice > 0 then
                        table.insert(fishList, {
                            UUID=item.UUID, Name=d.Data.Name,
                            Price=finalPrice, Type=d.Data.Type,
                        })
                    end
                end
            end
        end

        if #fishList == 0 then setStatus("Error: Tidak ada ikan di inventory"); return end
        table.sort(fishList, function(a, b) return a.Price > b.Price end)

        local selected   = {}
        local totalValue = 0
        for _, fish in ipairs(fishList) do
            if totalValue >= _tradeState.targetCoins then break end
            if totalValue + fish.Price <= _tradeState.targetCoins then
                table.insert(selected, fish)
                totalValue += fish.Price
            end
        end

        if totalValue < _tradeState.targetCoins and #fishList > 0 then
            local selectedUUIDs = {}
            for _, s in ipairs(selected) do selectedUUIDs[s.UUID] = true end
            for i = #fishList, 1, -1 do
                if not selectedUUIDs[fishList[i].UUID] then
                    table.insert(selected, fishList[i])
                    totalValue += fishList[i].Price
                    break
                end
            end
        end

        if #selected == 0 then setStatus("Error: Tidak ada ikan yang cocok"); return end

        local batches = {}
        local batch = {}
        local batchCoin = 0
        for _, fish in ipairs(selected) do
            table.insert(batch, { UUID=fish.UUID, Type=fish.Type, Name=fish.Name, CoinValue=fish.Price })
            batchCoin += fish.Price
            if #batch >= MAX_ITEMS_PER_TRADE then
                table.insert(batches, { items=batch, coin=batchCoin })
                batch = {}; batchCoin = 0
            end
        end
        if #batch > 0 then table.insert(batches, { items=batch, coin=batchCoin }) end

        _tradeState.targetAmount = #batches
        setStatus(("Starting ByCoin: %d item(s) ~%d coins dalam %d trade"):format(
            #selected, totalValue, #batches
        ))

        for _, b in ipairs(batches) do
            if not _tradeState.enabled then break end
            executeTradeMulti(b.items, b.coin)
        end
    end

    local function runByRarity()
        local initialFish = getFreshFishByRarity(_tradeState.selectedRarity)
        if #initialFish == 0 then
            setStatus("Error: Tidak ada ikan rarity " .. _tradeState.selectedRarity); return
        end

        local total = math.min(_tradeState.rarityAmount, #initialFish)
        _tradeState.targetAmount = math.ceil(total / MAX_ITEMS_PER_TRADE)
        local traded = 0

        while traded < total do
            if not _tradeState.enabled then break end
            local fresh = getFreshFishByRarity(_tradeState.selectedRarity)
            if #fresh == 0 then
                setStatus("Error: Inventory habis / tidak ada lagi ikan " .. _tradeState.selectedRarity); break
            end
            local remaining  = total - traded
            local batchSize  = math.min(MAX_ITEMS_PER_TRADE, remaining, #fresh)
            local batch = {}
            for i = 1, batchSize do
                table.insert(batch, { UUID=fresh[i].UUID, Type=fresh[i].Type, Name=fresh[i].Name, CoinValue=0 })
            end
            if #batch == 0 then break end
            local ok = executeTradeMulti(batch, 0)
            if ok then
                traded += #batch
            else
                task.wait(2)
            end
        end
    end

    local function runByEnchantStone()
        local stoneItemId = ENCHANT_STONE_IDS[_tradeState.selectedStoneType]
        if not stoneItemId then setStatus("Error: Stone type tidak valid"); return end

        local stoneName = _tradeState.selectedStoneType .. " Enchant Stone"
        local stoneType = "Items"

        pcall(function()
            local inventory = Data:GetExpect({"Inventory", "Items"})
            for _, item in pairs(inventory) do
                if item.Id == stoneItemId then
                    local d = ItemUtility.GetItemDataFromItemType("Items", item.Id)
                    if d then
                        stoneName = d.Data.Name or stoneName
                        stoneType = d.Data.Type or "Items"
                    end
                    break
                end
            end
        end)

        _tradeState.targetAmount = _tradeState.stoneAmount
        setStatus(("Starting EnchantStone: %s x%d"):format(stoneName, _tradeState.stoneAmount))

        local traded = 0
        while traded < _tradeState.stoneAmount do
            if not _tradeState.enabled then break end

            local currentUUID = nil
            pcall(function()
                local inventory = Data:GetExpect({"Inventory", "Items"})
                for _, item in pairs(inventory) do
                    if item.Id == stoneItemId then
                        currentUUID = item.UUID
                        break
                    end
                end
            end)

            if not currentUUID then
                setStatus("Error: Tidak ada lagi " .. stoneName .. " di inventory")
                break
            end

            local ok = executeTradeMulti(
                {{ UUID = currentUUID, Type = stoneType, Name = stoneName, CoinValue = 0 }},
                0
            )

            if ok then
                traded += 1
            else
                task.wait(2)
            end
        end
    end

    local function startTrade()
        if _tradeState.enabled then return end
        if not _tradeState.targetPlayer or not _tradeState.playerManuallySelected then
            setStatus("Error: Target player belum dipilih"); return
        end
        if not Players:FindFirstChild(_tradeState.targetPlayer) then
            setStatus("Error: Target player tidak ditemukan"); return
        end

        _tradeState.enabled        = true
        _tradeState.totalAttempted = 0
        _tradeState.totalSuccess   = 0
        _tradeState.totalFailed    = 0
        _tradeState.targetAmount   = 0
        _tradeState.status         = "Starting..."
        _tradeState.lastTradedItem = ""
        _tradeState.coinTraded     = 0
        updateMonitor()

        _tradeState.task = task.spawn(function()
            if     _tradeState.tradeMode == "ByName"         then runByName()
            elseif _tradeState.tradeMode == "ByCoin"         then runByCoin()
            elseif _tradeState.tradeMode == "ByRarity"       then runByRarity()
            elseif _tradeState.tradeMode == "ByEnchantStone" then runByEnchantStone()
            end

            if _tradeState.enabled then
                _tradeState.enabled = false
                setStatus(("Completed! %d/%d sukses"):format(
                    _tradeState.totalSuccess, _tradeState.targetAmount
                ))
                if _activeToggleRef and _activeToggleRef.SetValue then
                    pcall(function() _activeToggleRef:SetValue(false) end)
                end
            else
                setStatus(("Stopped: %d/%d sukses"):format(
                    _tradeState.totalSuccess, _tradeState.targetAmount
                ))
            end
        end)
    end

    local function stopTrade()
        if not _tradeState.enabled then return end
        _tradeState.enabled = false
        if _tradeState.task then
            task.cancel(_tradeState.task)
            _tradeState.task = nil
        end
        setStatus(("Stopped: %d/%d sukses"):format(
            _tradeState.totalSuccess, _tradeState.targetAmount
        ))
    end

    local function resetStats(paragraphRef)
        _tradeState.totalAttempted = 0
        _tradeState.totalSuccess   = 0
        _tradeState.totalFailed    = 0
        _tradeState.targetAmount   = 0
        _tradeState.status         = "Idle"
        _tradeState.lastTradedItem = ""
        _tradeState.coinTraded     = 0
        if paragraphRef and paragraphRef.SetContent then
            pcall(function() paragraphRef:SetContent("Idle") end)
        end
    end

    local PlayerSection = TradeTab:AddSection("Select Player", false)

    local _playerDropdown = PlayerSection:AddDropdown({
        Title    = "Target Player",
        Options  = {},
        Default  = nil,
        NoSave   = true,
        Callback = function(value)
            _tradeState.targetPlayer           = value
            _tradeState.playerManuallySelected = true
        end,
    })

    PlayerSection:AddButton({
        Title    = "Refresh Players",
        Callback = function()
            local list = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP then table.insert(list, p.Name) end
            end
            if _playerDropdown and _playerDropdown.SetOptions then
                _playerDropdown:SetOptions(list)
            end
        end,
    })

    local ByNameSection = TradeTab:AddSection("Trade By Name", false)

    local ByNameMonitor = ByNameSection:AddParagraph({
        Title   = "Status",
        Content = "Idle",
    })

    local _itemDropdown = ByNameSection:AddDropdown({
        Title    = "Select Item",
        Options  = {},
        Default  = nil,
        Callback = function(value)
            if value then
                _tradeState.selectedItem = value:match("^(.-) x") or value
            end
        end,
    })

    ByNameSection:AddButton({
        Title    = "Refresh Fish Items",
        Callback = function()
            if not Data then return end
            local grouped = {}
            pcall(function()
                local inventory = Data:GetExpect({"Inventory", "Items"})
                for _, item in ipairs(inventory) do
                    if not item.Favorited then
                        local d = ItemUtility.GetItemDataFromItemType("Items", item.Id)
                        if d and d.Data.Type == "Fish" then
                            local name = d.Data.Name
                            grouped[name] = (grouped[name] or 0) + 1
                        end
                    end
                end
            end)
            local display = {}
            for name, count in pairs(grouped) do
                table.insert(display, ("%s x%d"):format(name, count))
            end
            if _itemDropdown and _itemDropdown.SetOptions then
                _itemDropdown:SetOptions(display)
            end
        end,
    })

    ByNameSection:AddInput({
        Title    = "Amount",
        Default  = "1",
        Callback = function(value)
            _tradeState.itemAmount = tonumber(value) or 1
        end,
    })

    local _byNameToggle
    _byNameToggle = ByNameSection:AddToggle({
        Title    = "Start Trade ByName",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                _activeMonitorParagraph = ByNameMonitor
                _activeToggleRef        = _byNameToggle
                _tradeState.tradeMode   = "ByName"
                startTrade()
            else
                stopTrade()
            end
        end,
    })

    ByNameSection:AddButton({
        Title    = "Reset Stats",
        Callback = function() resetStats(ByNameMonitor) end,
    })

    local ByCoinSection = TradeTab:AddSection("Trade By Coin", false)

    local ByCoinMonitor = ByCoinSection:AddParagraph({
        Title   = "Status",
        Content = "Idle",
    })

    ByCoinSection:AddInput({
        Title    = "Target Coins",
        Default  = "0",
        Callback = function(value)
            _tradeState.targetCoins = tonumber(value) or 0
        end,
    })

    local _byCoinToggle
    _byCoinToggle = ByCoinSection:AddToggle({
        Title    = "Start Trade ByCoin",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                _activeMonitorParagraph = ByCoinMonitor
                _activeToggleRef        = _byCoinToggle
                _tradeState.tradeMode   = "ByCoin"
                startTrade()
            else
                stopTrade()
            end
        end,
    })

    ByCoinSection:AddButton({
        Title    = "Reset Stats",
        Callback = function() resetStats(ByCoinMonitor) end,
    })

    local ByRaritySection = TradeTab:AddSection("Trade By Rarity", false)

    local ByRarityMonitor = ByRaritySection:AddParagraph({
        Title   = "Status",
        Content = "Idle",
    })

    ByRaritySection:AddDropdown({
        Title    = "Select Rarity",
        Options  = { "Common","Uncommon","Rare","Epic","Legendary","Mythic","Secret" },
        Default  = "Common",
        Callback = function(value)
            _tradeState.selectedRarity = value
        end,
    })

    ByRaritySection:AddInput({
        Title    = "Amount",
        Default  = "1",
        Callback = function(value)
            _tradeState.rarityAmount = tonumber(value) or 1
        end,
    })

    local _byRarityToggle
    _byRarityToggle = ByRaritySection:AddToggle({
        Title    = "Start Trade ByRarity",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                _activeMonitorParagraph = ByRarityMonitor
                _activeToggleRef        = _byRarityToggle
                _tradeState.tradeMode   = "ByRarity"
                startTrade()
            else
                stopTrade()
            end
        end,
    })

    ByRaritySection:AddButton({
        Title    = "Reset Stats",
        Callback = function() resetStats(ByRarityMonitor) end,
    })

    local ByStoneSection = TradeTab:AddSection("Trade Enchant Stone", false)

    local ByStoneMonitor = ByStoneSection:AddParagraph({
        Title   = "Status",
        Content = "Idle",
    })

    ByStoneSection:AddDropdown({
        Title    = "Stone Type",
        Options  = { "Normal", "Double", "Evolved" },
        Default  = "Normal",
        Callback = function(value)
            _tradeState.selectedStoneType = value
        end,
    })

    ByStoneSection:AddInput({
        Title    = "Amount",
        Default  = "1",
        Callback = function(value)
            _tradeState.stoneAmount = tonumber(value) or 1
        end,
    })

    ByStoneSection:AddButton({
        Title    = "Check Enchant Stones",
        Callback = function()
            if not Data then return end
            local display = {}
            pcall(function()
                local inventory = Data:GetExpect({"Inventory", "Items"})
                for stoneType, stoneId in pairs(ENCHANT_STONE_IDS) do
                    local count = 0
                    for _, item in pairs(inventory) do
                        if item.Id == stoneId then count += (item.Quantity or 1) end
                    end
                    if count > 0 then
                        table.insert(display, ("%s x%d"):format(stoneType, count))
                    end
                end
            end)
            ByStoneMonitor:SetContent(
                #display > 0
                and ("Inventory: " .. table.concat(display, ", "))
                or "No enchant stones found"
            )
        end,
    })

    local _byStoneToggle
    _byStoneToggle = ByStoneSection:AddToggle({
        Title    = "Start Trade EnchantStone",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                _activeMonitorParagraph = ByStoneMonitor
                _activeToggleRef        = _byStoneToggle
                _tradeState.tradeMode   = "ByEnchantStone"
                startTrade()
            else
                stopTrade()
            end
        end,
    })

    ByStoneSection:AddButton({
        Title    = "Reset Stats",
        Callback = function() resetStats(ByStoneMonitor) end,
    })

    local AcceptSection = TradeTab:AddSection("Auto Accept Trade", false)

    local _acceptState = {
        enabled     = false,
        hooked      = false,
        connections = {},
        origFire    = nil,
    }

    AcceptSection:AddParagraph({
        Title   = "Info",
        Content = "Hook ke PromptController.\nOtomatis accept semua trade request masuk tanpa klik.",
    })

    AcceptSection:AddToggle({
        Title    = "Enable Auto Accept Trade",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            if on then
                if _acceptState.enabled then return end

                if not _acceptState.hooked then
                    pcall(function()
                        local ctrl = require(RS.Controllers.PromptController)
                        _acceptState.origFire = ctrl.FirePrompt
                        ctrl.FirePrompt = function(self, message, ...)
                            if _acceptState.enabled then
                                local msg = tostring(message or ""):lower()
                                if msg:find("trade request") or msg:find("do you want to accept") then
                                    local Promise = require(RS.Packages.Promise)
                                    return Promise.resolve(true)
                                end
                            end
                            return _acceptState.origFire(self, message, ...)
                        end
                        _acceptState.hooked = true
                    end)
                end

                _acceptState.enabled = true

                local conn = TradeData.Remotes.TradeStarted.OnClientEvent:Connect(function(replionId)
                    if not _acceptState.enabled then return end
                    task.spawn(function()
                        task.wait(0.5)
                        local tradeReplion = Replion.Client:GetReplion(replionId)
                        if not tradeReplion then return end

                        local lockDuration = TradeData.ConfirmCountdownTime or 5

                        local d1 = tick() + 120
                        while tick() < d1 do
                            if not _acceptState.enabled or tradeReplion.Destroyed then return end
                            local lmt = tradeReplion.Data and tradeReplion.Data.LastModifiedTime
                            if lmt and lmt > 0 then break end
                            task.wait(0.2)
                        end

                        if not _acceptState.enabled or tradeReplion.Destroyed then return end

                        local lastSeen, stableStart = nil, nil
                        local d2 = tick() + 120
                        while tick() < d2 do
                            if not _acceptState.enabled or tradeReplion.Destroyed then return end
                            local current = tradeReplion.Data and tradeReplion.Data.LastModifiedTime
                            if current ~= lastSeen then
                                lastSeen = current; stableStart = tick()
                            elseif stableStart and (tick() - stableStart) >= 0.5 then
                                break
                            end
                            task.wait(0.1)
                        end

                        if not _acceptState.enabled or tradeReplion.Destroyed then return end

                        local d3 = tick() + 30
                        while tick() < d3 do
                            if not _acceptState.enabled or tradeReplion.Destroyed then return end
                            local data = tradeReplion.Data
                            if not data or not data.LastModifiedTime then break end
                            local remaining = data.LastModifiedTime + lockDuration - workspace:GetServerTimeNow()
                            if remaining <= 0 then break end
                            task.wait(0.05)
                        end

                        if not _acceptState.enabled or tradeReplion.Destroyed then return end

                        local readyOk = false
                        for _ = 1, 10 do
                            if not _acceptState.enabled then return end
                            local s, r = pcall(function()
                                return TradeData.Remotes.SetReady:InvokeServer(true)
                            end)
                            if s and r then readyOk = true; break end
                            task.wait(0.3)
                        end
                        if not readyOk then return end

                        local d4 = tick() + 30
                        while tick() < d4 do
                            if not _acceptState.enabled or tradeReplion.Destroyed then return end
                            local data = tradeReplion.Data
                            if data and data.PlayersReady == true then break end
                            task.wait(0.1)
                        end

                        if not _acceptState.enabled or tradeReplion.Destroyed then return end
                        local data = tradeReplion.Data
                        if not data or data.PlayersReady ~= true then return end

                        pcall(function() TradeData.Remotes.ConfirmTrade:InvokeServer() end)
                    end)
                end)

                table.insert(_acceptState.connections, conn)

                Library:MakeNotify({
                    Title       = "Auto Accept Trade",
                    Description = "Auto Accept Trade dimulai",
                    Delay       = 2,
                })
            else
                _acceptState.enabled = false
                if _acceptState.hooked then
                    pcall(function()
                        local ctrl = require(RS.Controllers.PromptController)
                        if _acceptState.origFire then
                            ctrl.FirePrompt = _acceptState.origFire
                        end
                    end)
                    _acceptState.origFire = nil
                    _acceptState.hooked   = false
                end

                for _, c in ipairs(_acceptState.connections) do
                    c:Disconnect()
                end
                _acceptState.connections = {}

                Library:MakeNotify({
                    Title       = "Auto Accept Trade",
                    Description = "Auto Accept Trade dihentikan",
                    Delay       = 2,
                })
            end
        end,
    })

end

do
    local function getHTTP()
        local candidates = { "request", "http_request" }
        for _, name in ipairs(candidates) do
            local f = rawget(getfenv and getfenv(0) or _G, name)
                   or rawget(getgenv and getgenv() or {}, name)
            if type(f) == "function" then return f end
        end
        local tables = { syn, fluxus, solara, http }
        for _, tbl in ipairs(tables) do
            if type(tbl) == "table" and type(tbl.request) == "function" then
                return tbl.request
            end
        end
        return nil
    end

    local function sendHTTP(url, payload)
        local httpFn = getHTTP()
        if not httpFn or not url or url == "" then return false end
        local ok, err = pcall(function()
            httpFn({
                Url     = url,
                Method  = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body    = game:GetService("HttpService"):JSONEncode(payload),
            })
        end)
        if not ok then warn("[Webhook] Gagal kirim request:", err) end
        return ok
    end

    local AVATAR_URL  = "https://raw.githubusercontent.com/habibrodriguez7-art/kontol/refs/heads/main/majesticons--planet-ring-2.png"
    local BOT_NAME    = "Lynx"
    local TIER_NAMES  = { [1]="Common",[2]="Uncommon",[3]="Rare",[4]="Epic",[5]="Legendary",[6]="Mythic",[7]="SECRET",[8]="FORGOTTEN" }
    local TIER_COLORS = { [1]=9807270,[2]=3066993,[3]=3447003,[4]=10181046,[5]=15844367,[6]=16711680,[7]=65535,[8]=16711680 }

    local function formatPrice(n)
        return tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    end

    local Items, Variants
    local function loadItems()
        if Items and Variants then return true end
        local ok = pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            Items    = require(RS:WaitForChild("Items", 5))
            Variants = require(RS:WaitForChild("Variants", 5))
        end)
        return ok and Items ~= nil
    end
    local function getFish(itemId)
        if not Items then loadItems() end
        if not Items then return nil end
        for _, f in pairs(Items) do
            if f.Data and f.Data.Id == itemId then return f end
        end
        return nil
    end
    local function getVariant(id)
        if not Variants then return nil end
        local idStr = tostring(id)
        for _, v in pairs(Variants) do
            if v.Data and (tostring(v.Data.Id) == idStr or tostring(v.Data.Name) == idStr) then return v end
        end
        return nil
    end
    local function getDiscordImageUrl(assetId)
        if not assetId then return nil end
        local httpFn = getHTTP()
        if not httpFn then return nil end
        local success, result = pcall(function()
            local response = httpFn({
                Url    = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%s&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false", tostring(assetId)),
                Method = "GET",
            })
            if response and response.Body then
                local data = game:GetService("HttpService"):JSONDecode(response.Body)
                if data and data.data and data.data[1] then return data.data[1].imageUrl end
            end
        end)
        return (success and result) or nil
    end
    local function getFishImageUrl(fish)
        local assetId = nil
        if     fish.Data.Icon    then assetId = tostring(fish.Data.Icon):match("%d+")
        elseif fish.Data.ImageId then assetId = tostring(fish.Data.ImageId)
        elseif fish.Data.Image   then assetId = tostring(fish.Data.Image):match("%d+")
        end
        if assetId then local url = getDiscordImageUrl(assetId); if url then return url end end
        return "https://i.imgur.com/UMWNYK7.png"
    end

    local WebhookTab         = MainWindow:AddTab({ Name = "Webhook", Icon = "send" })

    local FishSection        = WebhookTab:AddSection("Fish Caught Webhook")
    local _fishState         = { url = "", id = "", hide = "", rarities = {}, running = false, conn = nil }

    FishSection:AddInput({
        Title       = "Webhook URL",
        Default     = "",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback    = function(value)
            _fishState.url = value:gsub("^%s*(.-)%s*$", "%1")
        end,
    })

    FishSection:AddInput({
        Title       = "Discord User ID (mention)",
        Default     = "",
        Placeholder = "123456789012345678",
        Callback    = function(value)
            _fishState.id = value:gsub("^%s*(.-)%s*$", "%1")
        end,
    })

    FishSection:AddInput({
        Title       = "Hide Identity (nama custom)",
        Default     = "",
        Placeholder = "Isi nama kustom...",
        Callback    = function(value)
            _fishState.hide = value:gsub("^%s*(.-)%s*$", "%1")
        end,
    })

    FishSection:AddDropdown({
        Title    = "Rarity Filter (kosong = semua)",
        Options  = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET", "FORGOTTEN" },
        Multi    = true,
        Default  = {},
        Callback = function(selected)
            _fishState.rarities = type(selected) == "table" and selected or {}
        end,
    })

    FishSection:AddToggle({
        Title    = "Enable Fish Webhook",
        Default  = false,
        Callback = function(on)
            if on then
                if _fishState.running then return end
                if _fishState.url == "" then
                    warn("[Webhook] URL Fish belum diisi!")
                    return
                end
                if not getHTTP() then
                    warn("[Webhook] Executor tidak support HTTP request!")
                    return
                end
                task.spawn(loadItems)
                local re = NetEvents.RE_ObtainedNewFishNotification
                if not re then warn("[Webhook] Event tidak ditemukan!"); return end

                _fishState.running = true
                _fishState.conn    = re.OnClientEvent:Connect(function(itemId, metadata, extraData)
                    task.spawn(function()
                        local t0 = tick()
                        while not Items and tick() - t0 < 5 do task.wait(0.2) end

                        local fish = getFish(itemId)
                        if not fish then return end

                        local meta  = metadata  or {}
                        local extra = extraData  or {}
                        local tier  = TIER_NAMES[fish.Data and fish.Data.Tier]  or "Unknown"
                        local color = TIER_COLORS[fish.Data and fish.Data.Tier] or 3447003

                        local filter = _fishState.rarities
                        if filter and next(filter) then
                            local pass = false
                            for _, v in pairs(filter) do if v == tier or v == true then pass = true; break end end
                            for k, v in pairs(filter) do if type(k) == "string" and k == tier and v then pass = true; break end end
                            if not pass then return end
                        end

                        local variantId  = extra.Variant or extra.Mutation or extra.VariantId
                                        or meta.Variant  or meta.Mutation  or meta.VariantId
                        local isShiny    = meta.Shiny or extra.Shiny
                        local mutText    = "None"
                        local finalPrice = fish.SellPrice or 0

                        if isShiny then mutText = "Shiny"; finalPrice = finalPrice * 2 end
                        if variantId then
                            local v = getVariant(variantId)
                            if v then
                                mutText    = (v.Data and v.Data.Name or tostring(variantId)) .. " (" .. tostring(v.SellMultiplier or "?") .. "x)"
                                finalPrice = finalPrice * (v.SellMultiplier or 1)
                            else
                                mutText = tostring(variantId)
                            end
                        end

                        local playerName = (_fishState.hide ~= "") and _fishState.hide
                                        or (LocalPlayer.DisplayName or LocalPlayer.Name)
                        local fishName   = (fish.Data and (fish.Data.Name or fish.Data.DisplayName)) or "Unknown"
                        local imageUrl   = getFishImageUrl(fish)

                        task.spawn(function()
                            sendHTTP(_fishState.url, {
                                username   = BOT_NAME,
                                avatar_url = AVATAR_URL,
                                embeds = {{
                                    author      = { name = BOT_NAME .. " Webhook | Fish Caught" },
                                    description = string.format("**%s** You have obtained a new **%s** fish!", playerName, tier),
                                    color       = color,
                                    fields = {
                                        { name = "Fish Name :",  value = " " .. fishName,                             inline = false },
                                        { name = "Fish Tier :",  value = " " .. tier,                                 inline = false },
                                        { name = "Weight :",     value = string.format(" %.2f Kg", meta.Weight or 0), inline = false },
                                        { name = "Mutation :",   value = " " .. mutText,                              inline = false },
                                        { name = "Sell Price :", value = " " .. formatPrice(finalPrice),              inline = false },
                                    },
                                    image     = { url = imageUrl },
                                    footer    = { text = BOT_NAME .. " Webhook • " .. os.date("%m/%d/%Y %I:%M"), icon_url = AVATAR_URL },
                                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                                }},
                            })
                        end)
                    end)
                end)
            else
                _fishState.running = false
                if _fishState.conn then _fishState.conn:Disconnect(); _fishState.conn = nil end
            end
        end,
    })

    FishSection:AddButton({
        Title    = "Test Fish Webhook",
        Callback = function()
            if _fishState.url == "" then
                warn("[Webhook] URL Fish belum diisi!")
                Library:MakeNotify({ Title = "Webhook", Description = "URL webhook belum diisi!", Delay = 3 })
                return
            end
            local ok = pcall(function()
                sendHTTP(_fishState.url, {
                    username   = BOT_NAME,
                    avatar_url = AVATAR_URL,
                    embeds = {{
                        title       = "🎣 Webhook Test — Fish Caught",
                        description = "✅ **Koneksi berhasil!** Webhook siap menerima notifikasi ikan.",
                        color       = 9055487,
                        fields = {
                            { name = "📊 Status", value = "```diff\n+ Webhook Active\n+ Logger Ready\n+ Notifications ON```", inline = true },
                            { name = "⚙️ Game",  value = "```yaml\nGame: Fish It\nMode: Auto-log```",                         inline = true },
                        },
                        footer    = { text = BOT_NAME .. " • Test berhasil", icon_url = AVATAR_URL },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    }},
                })
            end)
            if ok then
               Library:MakeNotify({
                    Title       = "Webhook",
                    Description = "Test message terkirim ke Discord!",
                    Delay       = 3,
                })
            else
                Library:MakeNotify({
                    Title       = "Webhook",
                    Description = "Gagal kirim test! Cek executor / URL.",
                    Delay       = 4,
                })
            end
        end,
    })

    local DisconnectSection  = WebhookTab:AddSection("Disconnect Webhook")
    local _dcState           = { url = "", id = "", hide = "", enabled = false, setup = false, fired = false }

    DisconnectSection:AddParagraph({
        Title   = "Info",
        Content = "Kirim notif ke Discord saat Roblox disconnect, lalu auto-rejoin.",
    })

    DisconnectSection:AddInput({
        Title       = "Webhook URL",
        Default     = "",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback    = function(value)
            _dcState.url = value:gsub("^%s*(.-)%s*$", "%1")
        end,
    })

    DisconnectSection:AddInput({
        Title       = "Discord User ID (mention)",
        Default     = "",
        Placeholder = "123456789012345678",
        Callback    = function(value)
            _dcState.id = value:gsub("^%s*(.-)%s*$", "%1")
        end,
    })

    DisconnectSection:AddInput({
        Title       = "Hide Identity (nama custom)",
        Default     = "",
        Placeholder = "Isi nama kustom...",
        Callback    = function(value)
            _dcState.hide = value:gsub("^%s*(.-)%s*$", "%1")
        end,
    })

    DisconnectSection:AddToggle({
        Title    = "Enable Disconnect Webhook",
        Default  = false,
        Callback = function(on)
            _dcState.enabled = on
            if on and not _dcState.setup then
                _dcState.setup = true
                _dcState.fired = false

                local function onDisconnect(reason)
                    if _dcState.fired or not _dcState.enabled then return end
                    if not _dcState.url or _dcState.url == "" then return end
                    _dcState.fired = true

                    local playerName = (_dcState.hide ~= "") and _dcState.hide
                                    or (LocalPlayer and LocalPlayer.Name) or "Unknown"
                    local mention    = (_dcState.id ~= "") and ("<@" .. _dcState.id:gsub("%D", "") .. ">") or ""

                    sendHTTP(_dcState.url, {
                        content    = mention ~= "" and (mention .. " Akunmu disconnect dari server!") or nil,
                        username   = BOT_NAME,
                        avatar_url = AVATAR_URL,
                        embeds = {{
                            author      = { name = BOT_NAME .. " | Disconnect Alert" },
                            title       = "Connection Lost",
                            description = "**Roblox session kamu terputus.**\n\nMencoba rejoin...",
                            color       = 9055487,
                            fields = {
                                { name = "Account", value = "```" .. playerName .. "```",                          inline = true  },
                                { name = "Time",    value = "```" .. os.date("%m/%d/%Y at %I:%M %p") .. "```",     inline = true  },
                                { name = "Reason",  value = "```" .. (reason or "Disconnected") .. "```",          inline = false },
                            },
                            footer    = { text = BOT_NAME .. " • Auto-rejoin enabled", icon_url = AVATAR_URL },
                            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                        }},
                    })
                    task.wait(2)
                    pcall(function()
                        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                    end)
                end

                pcall(function()
                    game:GetService("GuiService").ErrorMessageChanged:Connect(function(msg)
                        if msg and msg ~= "" then onDisconnect(msg) end
                    end)
                end)
                pcall(function()
                    local promptGui = game:GetService("CoreGui"):FindFirstChild("RobloxPromptGui")
                    if promptGui then
                        local overlay = promptGui:FindFirstChild("promptOverlay")
                        if overlay then
                            overlay.ChildAdded:Connect(function(child)
                                if child.Name == "ErrorPrompt" then
                                    task.wait(1)
                                    local lbl = child:FindFirstChildWhichIsA("TextLabel", true)
                                    onDisconnect(lbl and lbl.Text or "Disconnected")
                                end
                            end)
                        end
                    end
                end)
            end
        end,
    })

    DisconnectSection:AddButton({
        Title    = "Test Disconnect Webhook",
        Callback = function()
            if _dcState.url == "" then
                warn("[Webhook] URL disconnect belum diisi!")
                Vyper:MakeNotify({ Title = "Webhook", Description = "URL disconnect belum diisi!", Color = Color3.fromRGB(255, 179, 71), Delay = 3 })
                return
            end
            local playerName = (_dcState.hide ~= "") and _dcState.hide
                            or (LocalPlayer and LocalPlayer.Name) or "Unknown"
            local mention    = (_dcState.id ~= "") and ("<@" .. _dcState.id:gsub("%D", "") .. ">") or ""
            local ok = pcall(function()
                sendHTTP(_dcState.url, {
                    content    = mention ~= "" and (mention .. " Akunmu disconnect dari server!") or nil,
                    username   = BOT_NAME,
                    avatar_url = AVATAR_URL,
                    embeds = {{
                        author      = { name = BOT_NAME .. " | Disconnect Alert" },
                        title       = "Connection Lost",
                        description = "**Roblox session kamu terputus.**\n\nMencoba rejoin...",
                        color       = 9055487,
                        fields = {
                            { name = "Account", value = "```" .. playerName .. "```",                          inline = true  },
                            { name = "Time",    value = "```" .. os.date("%m/%d/%Y at %I:%M %p") .. "```",     inline = true  },
                            { name = "Reason",  value = "```Test Successfully :3```",                          inline = false },
                        },
                        footer    = { text = BOT_NAME .. " • Auto-rejoin enabled", icon_url = AVATAR_URL },
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                    }},
                })
            end)
            if ok then
                Library:MakeNotify({ Title = "Webhook", Description = "Test disconnect terkirim!", Delay = 3 })
            else
                Library:MakeNotify({ Title = "Webhook", Description = "Gagal kirim test! Cek executor / URL.", Delay = 4 })
            end
        end,
    })

end

do
    local SkinTab = MainWindow:AddTab({ Name = "Skin Features", Icon = "menu" })

    local AccessorySection = SkinTab:AddSection("Accessory Changer")
    local _accessory       = { selected = nil, enabled = false }

    local AccessoryFolder  = game.ReplicatedStorage.Controllers.AccessoryReplicationController.Accessory

    local function _getAccessoryList()
        local list = {}
        for _, v in ipairs(AccessoryFolder:GetChildren()) do
            table.insert(list, v.Name)
        end
        table.sort(list)
        return list
    end

    local function _applyAccessory()
        if not _accessory.selected then return false end
        local ok = pcall(function()
            LocalPlayer:SetAttribute("FishingRodSkin", _accessory.selected)
        end)
        return ok
    end

    local function _removeAccessory()
        pcall(function()
            LocalPlayer:SetAttribute("FishingRodSkin", nil)
        end)
    end

    AccessorySection:AddDropdown({
        Title    = "Pilih Accessory",
        Options  = _getAccessoryList(),
        NoSave   = false,
        Callback = function(v)
            _accessory.selected = v
            if _accessory.enabled then
                local ok = _applyAccessory()
                Library:MakeNotify({
                    Title       = "Accessory",
                    Description = ok
                        and ("Accessory aktif: " .. v)
                        or  "Gagal apply accessory!",
                    Delay       = 3,
                })
            end
        end,
    })

    AccessorySection:AddToggle({
        Title    = "Enable Accessory",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            _accessory.enabled = on
            if on then
                if not _accessory.selected then
                    Library:MakeNotify({
                        Title       = "Accessory",
                        Description = "Pilih accessory dulu dari dropdown!",
                        Delay       = 2,
                    })
                    _accessory.enabled = false
                    return
                end
                local ok = _applyAccessory()
                Library:MakeNotify({
                    Title       = "Accessory",
                    Description = ok
                        and ("Accessory aktif: " .. _accessory.selected)
                        or  "Gagal apply accessory!",
                    Delay       = 3,
                })
            else
                _removeAccessory()
                Library:MakeNotify({
                    Title       = "Accessory",
                    Description = "Accessory dilepas.",
                    Delay       = 2,
                })
            end
        end,
    })

    AccessorySection:AddButton({
        Title    = "Remove Accessory",
        Callback = function()
            _accessory.enabled = false
            _removeAccessory()
            Library:MakeNotify({
                Title       = "Accessory",
                Description = "Accessory dilepas.",
                Delay       = 2,
            })
        end,
    })

        local AvatarSection = SkinTab:AddSection("Avatar Changer")

    local _avatar = {
        enabled      = false,
        selectedId   = nil,
        selectedName = "",
        applyConn    = nil,
        currentDesc  = nil,
    }

    local _originalDesc = nil

    task.spawn(function()
        local Players  = game:GetService("Players")
        local LP       = Players.LocalPlayer
        local ok, desc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(LP.UserId)
        end)
        if ok and desc then
            _originalDesc = desc
        end
    end)

    local AVATAR_LIST = {
        { Id = 7077243300,  Label = "TV_TIKMAN" },
        { Id = 6010134024,  Label = "Ninjaso02YT" },
        { Id = 1105009763,  Label = "s1mple" },
        { Id = 3232392707,  Label = "G0DG0MER" },
        { Id = 8673396266,  Label = "spiderman" },
        { Id = 9939245108,  Label = "ApiqqStoreeX8" },
        { Id = 8849874931,  Label = "SnoopDogs" },
        { Id = 495215054,   Label = "SnoopDog" },
        { Id = 3658593465,  Label = "CFIDxMuell" },
        { Id = 8723543936,  Label = "Izyy" },
        { Id = 9068204572,  Label = "Cero" },
        { Id = 1922874709,  Label = "StanniBunny" },
        { Id = 3853262070,  Label = "S4INTRL" },
        { Id = 1718757907,  Label = "1_PFT" },
        { Id = 8343523,     Label = "Neko_Overlord" },
        { Id = 925872199,   Label = "gamer" },
        { Id = 9758684471,  Label = "Azure" },
        { Id = 776077949,   Label = "DuckXander" },
        { Id = 293229095,   Label = "SinisterUGC" },
        { Id = 3622565596,  Label = "Bluff_006" },
        { Id = 77696047,    Label = "caIIdrops" },
        { Id = 32958887,    Label = "Juno" },
        { Id = 63578527,    Label = "MistyPhantom" },
        { Id = 293215507,   Label = "LoneWalker_L" },
        { Id = 178596165,   Label = "LilDisquit" },
        { Id = 7712365803,  Label = "TATA" },
        { Id = 9331384193,  Label = "Ficha_NR" },
        { Id = 8898545773,  Label = "Gracee" },
        { Id = 8997690084,  Label = "3quinox" },
        { Id = 9273180503,  Label = "Your_Miffy" },
        { Id = 425367613,   Label = "QueenChroma" },
        { Id = 147302717,   Label = "Hoshiko" },
        { Id = 8476353635,  Label = "kify168" },
        { Id = 40397833,    Label = "WILDES" },
        { Id = 75974130,    Label = "TALON" },
        { Id = 7909420830,  Label = "ZAER" },
        { Id = 111233359,   Label = "EA_GAMES" },
        { Id = 56602747,    Label = "Stealthy" },
        { Id = 47058434,    Label = "RZXTL" },
    }

    local BODY_PARTS = {
        "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
        "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm",
        "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand",
        "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
        "LeftFoot", "RightFoot",
    }

    local function _getAvatarOptions()
        local list = {}
        for _, v in ipairs(AVATAR_LIST) do
            table.insert(list, v.Label)
        end
        return list
    end

    local function _getIdByLabel(label)
        for _, v in ipairs(AVATAR_LIST) do
            if v.Label == label then return v.Id end
        end
        return nil
    end

    local function _copyDummyToChar(dummyChar, char, desc)
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Accessory")
            or obj:IsA("Hat")
            or obj:IsA("Shirt")
            or obj:IsA("Pants")
            or obj:IsA("ShirtGraphic")
            or obj:IsA("CharacterMesh") then
                obj:Destroy()
            end
        end

        for _, obj in ipairs(dummyChar:GetChildren()) do
            if obj:IsA("Accessory") or obj:IsA("Hat") then
                pcall(function()
                    local clone  = obj:Clone()
                    clone.Parent = char

                    local handle = clone:FindFirstChild("Handle")
                    if handle then
                        local oldWeld = handle:FindFirstChild("AccessoryWeld")
                        if oldWeld then oldWeld:Destroy() end

                        local attName = nil
                        for _, child in ipairs(handle:GetChildren()) do
                            if child:IsA("Attachment") then
                                attName = child.Name
                                break
                            end
                        end

                        local targetPart = nil
                        local targetAtt  = nil

                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("Attachment") and part.Name == attName then
                                if part.Parent ~= handle then
                                    targetPart = part.Parent
                                    targetAtt  = part
                                    break
                                end
                            end
                        end

                        if targetPart and targetPart:IsA("BasePart") then
                            local weld          = Instance.new("Weld")
                            weld.Name           = "AccessoryWeld"
                            weld.Part0          = targetPart
                            weld.Part1          = handle
                            weld.C0             = targetAtt.CFrame
                            local handleAtt     = handle:FindFirstChild(attName)
                            weld.C1             = handleAtt and handleAtt.CFrame or CFrame.new()
                            weld.Parent         = handle
                        else
                            local root = char:FindFirstChild("Head")
                                or char:FindFirstChild("HumanoidRootPart")
                            if root then
                                local weld  = Instance.new("Weld")
                                weld.Name   = "AccessoryWeld"
                                weld.Part0  = root
                                weld.Part1  = handle
                                weld.Parent = handle
                            end
                        end
                    end
                end)
            elseif obj:IsA("Shirt")
            or obj:IsA("Pants")
            or obj:IsA("ShirtGraphic")
            or obj:IsA("CharacterMesh") then
                pcall(function()
                    local clone = obj:Clone()
                    clone.Parent = char
                end)
            end
        end

        local hasShirt = char:FindFirstChildOfClass("Shirt") ~= nil
        local hasPants = char:FindFirstChildOfClass("Pants") ~= nil
        if not hasShirt and desc and desc.Shirt and desc.Shirt ~= 0 then
            pcall(function()
                local shirt = Instance.new("Shirt")
                shirt.ShirtTemplate = "rbxassetid://" .. tostring(desc.Shirt)
                shirt.Parent = char
            end)
        end
        if not hasPants and desc and desc.Pants and desc.Pants ~= 0 then
            pcall(function()
                local pants = Instance.new("Pants")
                pants.PantsTemplate = "rbxassetid://" .. tostring(desc.Pants)
                pants.Parent = char
            end)
        end
        if desc and desc.GraphicTShirt and desc.GraphicTShirt ~= 0 then
            if not char:FindFirstChildOfClass("ShirtGraphic") then
                pcall(function()
                    local tshirt = Instance.new("ShirtGraphic")
                    tshirt.Graphic = "rbxassetid://" .. tostring(desc.GraphicTShirt)
                    tshirt.Parent = char
                end)
            end
        end

        local dummyBC = dummyChar:FindFirstChildOfClass("BodyColors")
        local myBC    = char:FindFirstChildOfClass("BodyColors")
        if dummyBC and myBC then
            myBC.HeadColor3     = dummyBC.HeadColor3
            myBC.TorsoColor3    = dummyBC.TorsoColor3
            myBC.LeftArmColor3  = dummyBC.LeftArmColor3
            myBC.RightArmColor3 = dummyBC.RightArmColor3
            myBC.LeftLegColor3  = dummyBC.LeftLegColor3
            myBC.RightLegColor3 = dummyBC.RightLegColor3
        end

        local dummyHead = dummyChar:FindFirstChild("Head")
        local myHead    = char:FindFirstChild("Head")
        if dummyHead and myHead then
            local dummyMesh = dummyHead:FindFirstChild("Mesh")
                or dummyHead:FindFirstChildOfClass("SpecialMesh")
            local myMesh    = myHead:FindFirstChild("Mesh")
                or myHead:FindFirstChildOfClass("SpecialMesh")

            if dummyMesh then
                if not myMesh then
                    myMesh        = Instance.new("SpecialMesh")
                    myMesh.Name   = "Mesh"
                    myMesh.Parent = myHead
                end
                pcall(function()
                    myMesh.MeshType  = dummyMesh.MeshType
                    myMesh.MeshId    = dummyMesh.MeshId    or ""
                    myMesh.TextureId = dummyMesh.TextureId or ""
                    myMesh.Scale     = dummyMesh.Scale
                    myMesh.Offset    = dummyMesh.Offset
                end)
            end

            local myFace = myHead:FindFirstChild("face")
                or myHead:FindFirstChildOfClass("Decal")
            if desc and desc.Face and desc.Face ~= 0 then
                if not myFace then
                    myFace        = Instance.new("Decal")
                    myFace.Name   = "face"
                    myFace.Face   = Enum.NormalId.Front
                    myFace.Parent = myHead
                end
                pcall(function()
                    myFace.Texture = "rbxassetid://" .. tostring(desc.Face)
                end)
            end

            pcall(function() myHead.Color = dummyHead.Color end)
        end

        for _, partName in ipairs(BODY_PARTS) do
            local dummyPart = dummyChar:FindFirstChild(partName)
            local myPart    = char:FindFirstChild(partName)
            if dummyPart and myPart then
                pcall(function() myPart.Color = dummyPart.Color end)

                local dummySA = dummyPart:FindFirstChildOfClass("SurfaceAppearance")
                local mySA    = myPart:FindFirstChildOfClass("SurfaceAppearance")
                if dummySA then
                    if not mySA then
                        mySA        = Instance.new("SurfaceAppearance")
                        mySA.Parent = myPart
                    end
                    pcall(function()
                        mySA.ColorMap     = dummySA.ColorMap
                        mySA.NormalMap    = dummySA.NormalMap
                        mySA.RoughnessMap = dummySA.RoughnessMap
                        mySA.MetalnessMap = dummySA.MetalnessMap
                    end)
                elseif mySA then
                    mySA:Destroy()
                end
            end
        end
    end

    local function _spawnDummyAndCopy(desc, char)
        local Players   = game:GetService("Players")
        local dummyChar = nil

        local dummyOk = pcall(function()
            dummyChar = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
        end)
        if not dummyOk or not dummyChar then return false end

        pcall(function()
            dummyChar.Parent = workspace
            if dummyChar.PrimaryPart then
                dummyChar:SetPrimaryPartCFrame(CFrame.new(0, -99999, 0))
            end
        end)

        task.wait(3)

        local success = pcall(function()
            _copyDummyToChar(dummyChar, char, desc)

            local myHumanoid = char:FindFirstChildOfClass("Humanoid")
            if myHumanoid then
                pcall(function()
                    myHumanoid.BodyDepthScale.Value  = desc.DepthScale
                    myHumanoid.BodyHeightScale.Value = desc.HeightScale
                    myHumanoid.BodyWidthScale.Value  = desc.WidthScale
                    myHumanoid.HeadScale.Value       = desc.HeadScale
                end)
            end
        end)

        pcall(function() dummyChar:Destroy() end)
        return success
    end

    local function _applyAvatarDirect(userId)
        local Players  = game:GetService("Players")
        local LP       = Players.LocalPlayer
        local char     = LP.Character
        if not char then return false end

        local ok, desc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(userId)
        end)
        if not ok or not desc then return false end

        local success = _spawnDummyAndCopy(desc, char)
        if success then
            _avatar.currentDesc = desc
        end
        return success
    end

    local function _removeAvatar()
        local Players  = game:GetService("Players")
        local LP       = Players.LocalPlayer
        local char     = LP.Character
        if not char then return end

        local descToUse = _originalDesc
        if not descToUse then
            local ok, freshDesc = pcall(function()
                return Players:GetHumanoidDescriptionFromUserId(LP.UserId)
            end)
            if not ok or not freshDesc then return end
            descToUse = freshDesc
        end

        _spawnDummyAndCopy(descToUse, char)
        _avatar.currentDesc = nil
    end

    AvatarSection:AddDropdown({
        Title    = "Select Avatar",
        Options  = _getAvatarOptions(),
        Default  = nil,
        NoSave   = true,
        Callback = function(selected)
            local id = _getIdByLabel(selected)
            _avatar.selectedId   = id
            _avatar.selectedName = selected

            if _avatar.enabled and id then
                task.spawn(function()
                    local ok = _applyAvatarDirect(id)
                    Library:MakeNotify({
                        Title       = "Avatar Changer",
                        Description = ok
                            and ("Avatar: " .. selected)
                            or  "Gagal apply avatar!",
                        Color = ok
                            and Color3.fromRGB(100, 200, 255)
                            or  Color3.fromRGB(255, 100, 100),
                        Delay = 2,
                    })
                end)
            end
        end,
    })

    AvatarSection:AddToggle({
        Title    = "Enable Avatar Changer",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            _avatar.enabled = on

            if on then
                if not _avatar.selectedId then
                    Library:MakeNotify({
                        Title       = "Avatar Changer",
                        Description = "Pilih avatar dari dropdown dulu!",
                        Delay       = 2,
                    })
                    return
                end

                task.spawn(function()
                    local ok = _applyAvatarDirect(_avatar.selectedId)
                    Library:MakeNotify({
                        Title       = "Avatar Changer",
                        Description = ok
                            and ("Avatar aktif: " .. _avatar.selectedName)
                            or  "Gagal apply avatar!",
                        Color = ok
                            and Color3.fromRGB(100, 200, 255)
                            or  Color3.fromRGB(255, 100, 100),
                        Delay = 3,
                    })
                end)

                if _avatar.applyConn then
                    _avatar.applyConn:Disconnect()
                    _avatar.applyConn = nil
                end

                _avatar.applyConn = game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(newChar)
                    if not _avatar.enabled or not _avatar.selectedId then return end
                    task.wait(2)

                    local Players  = game:GetService("Players")
                    local ok, desc = pcall(function()
                        return Players:GetHumanoidDescriptionFromUserId(_avatar.selectedId)
                    end)
                    if not ok or not desc then return end

                    _spawnDummyAndCopy(desc, newChar)
                end)

            else
                if _avatar.applyConn then
                    _avatar.applyConn:Disconnect()
                    _avatar.applyConn = nil
                end
                task.spawn(function()
                    _removeAvatar()
                    Library:MakeNotify({
                        Title       = "Avatar Changer",
                        Description = "Avatar dikembalikan ke asli.",
                        Delay       = 2,
                    })
                end)
            end
        end,
    })

    AvatarSection:AddButton({
        Title    = "Apply Now",
        Callback = function()
            if not _avatar.selectedId then
                Library:MakeNotify({
                    Title       = "Avatar Changer",
                    Description = "Pilih avatar dari dropdown dulu!",
                    Delay       = 2,
                })
                return
            end
            task.spawn(function()
                local ok = _applyAvatarDirect(_avatar.selectedId)
                Library:MakeNotify({
                    Title       = "Avatar Changer",
                    Description = ok
                        and ("Applied: " .. _avatar.selectedName)
                        or  "Gagal apply avatar!",
                    Color = ok
                        and Color3.fromRGB(100, 200, 255)
                        or  Color3.fromRGB(255, 100, 100),
                    Delay = 2,
                })
            end)
        end,
    })

    AvatarSection:AddButton({
        Title    = "Reset to Original",
        Callback = function()
            _avatar.enabled = false
            if _avatar.applyConn then
                _avatar.applyConn:Disconnect()
                _avatar.applyConn = nil
            end
            task.spawn(function()
                _removeAvatar()
                Library:MakeNotify({
                    Title       = "Avatar Changer",
                    Description = "Avatar dikembalikan ke asli.",
                    Delay       = 2,
                })
            end)
        end,
    })

    local AuraSection  = SkinTab:AddSection("Aura Skin")
    local _aura        = { current = nil, enabled = false, autoReapply = false, charConn = nil }

    local AurasFolder  = game.ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Auras")

    local function _getAuraList()
        local list = {}
        for _, v in ipairs(AurasFolder:GetChildren()) do
            table.insert(list, v.Name)
        end
        return list
    end

    local function _applyAura(auraName)
        local char = LocalPlayer.Character
        if not char or not auraName then return end
        local aura = AurasFolder:FindFirstChild(auraName)
        if not aura then return end
        for _, part in ipairs(char:GetChildren()) do
            for _, effect in ipairs(part:GetChildren()) do
                if effect:GetAttribute("IsAura") then effect:Destroy() end
            end
        end
        for _, auraPart in ipairs(aura:GetChildren()) do
            local charPart = char:FindFirstChild(auraPart.Name)
            if charPart then
                for _, effect in ipairs(auraPart:GetChildren()) do
                    local clone = effect:Clone()
                    clone:SetAttribute("IsAura", true)
                    clone.Parent = charPart
                end
            end
        end
    end

    local function _removeAura()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetChildren()) do
            for _, effect in ipairs(part:GetChildren()) do
                if effect:GetAttribute("IsAura") then effect:Destroy() end
            end
        end
    end

    AuraSection:AddDropdown({
        Title    = "Pilih Aura",
        Options  = _getAuraList(),
        NoSave   = false,
        Callback = function(v)
            _aura.current = v
            if _aura.enabled then
                _applyAura(v)
            end
        end,
    })

    AuraSection:AddToggle({
        Title    = "Enable Aura",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            _aura.enabled = on
            if on then
                if _aura.current then
                    _applyAura(_aura.current)
                end
            else
                _removeAura()
            end
        end,
    })

    AuraSection:AddToggle({
        Title    = "Auto Re-apply saat Respawn",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            _aura.autoReapply = on
            if on then
                if _aura.charConn then return end
                _aura.charConn = LocalPlayer.CharacterAdded:Connect(function()
                    task.wait(1)
                    if _aura.autoReapply and _aura.enabled and _aura.current then
                        _applyAura(_aura.current)
                    end
                end)
            else
                if _aura.charConn then
                    _aura.charConn:Disconnect()
                    _aura.charConn = nil
                end
            end
        end,
    })

    AuraSection:AddButton({
        Title    = "Remove Aura",
        Callback = function()
            _aura.enabled = false
            _removeAura()
            Library:MakeNotify({
                Title       = "Aura",
                Description = "Aura berhasil dihapus.",
                Delay       = 2,
            })
        end,
    })

    local SkinSection  = SkinTab:AddSection("Skin Animation")
    local _skinAnim    = { enabled = false, current = "", conns = {}, pools = {}, poolIdx = {}, killed = {}, active = {}, replacing = {} }

    local RunService   = game:GetService("RunService")
    local char         = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid     = char:WaitForChild("Humanoid")
    local Animator     = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)

    local ANIM_DB      = { FishCaught={}, EquipIdle={}, RodThrow={}, ReelStart={}, ReelingIdle={}, ReelIntermission={} }
    local LOOPED       = { EquipIdle=true, ReelingIdle=true }
    local PRIORITY     = {
        FishCaught=Enum.AnimationPriority.Action4, EquipIdle=Enum.AnimationPriority.Action3,
        RodThrow=Enum.AnimationPriority.Action4,   ReelStart=Enum.AnimationPriority.Action4,
        ReelingIdle=Enum.AnimationPriority.Action3, ReelIntermission=Enum.AnimationPriority.Action4,
    }
    local PATTERNS     = {
        ReelingIdle      = { "reelingidle", "reeling idle" },
        ReelIntermission = { "reelintermission", "reel intermission" },
        ReelStart        = { "reelstart", "reel start" },
        RodThrow         = { "rodthrow", "rod throw" },
        FishCaught       = { "fishcaught", "fish caught" },
        EquipIdle        = { "equipidle", "equip idle" },
    }
    local DETECT_ORDER = { "ReelingIdle","ReelIntermission","ReelStart","RodThrow","FishCaught","EquipIdle" }

    local skinNames    = {}
    local animsFolder  = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
                      and game:GetService("ReplicatedStorage").Modules:FindFirstChild("Animations")
    if animsFolder then
        for _, animObj in ipairs(animsFolder:GetChildren()) do
            local ok, animId = pcall(function() return animObj.AnimationId end)
            if not (ok and animId and animId ~= "") then continue end
            local nameLower = string.lower(animObj.Name)
            local detectedType = nil
            for _, t in ipairs(DETECT_ORDER) do
                for _, p in ipairs(PATTERNS[t]) do
                    if string.find(nameLower, p) then detectedType = t; break end
                end
                if detectedType then break end
            end
            if not detectedType then continue end
            local skinName = string.match(animObj.Name, "^(.-)%s*%-")
            if not skinName or skinName == "" then continue end
            skinName = skinName:match("^%s*(.-)%s*$")
            ANIM_DB[detectedType][skinName] = animId
            local found = false
            for _, v in ipairs(skinNames) do if v == skinName then found = true; break end end
            if not found then table.insert(skinNames, skinName) end
        end
    end

    local function _isCustom(track)
        if not track then return false end
        local n = string.lower(track.Name or "")
        for t in pairs(ANIM_DB) do
            if string.find(n, string.lower(t) .. "_pool") then return true end
        end
        return false
    end

    local function _detectType(track)
        if not track or not track.Animation then return nil end
        if _isCustom(track) then return nil end
        local tName = string.lower(track.Name or "")
        local aName = string.lower(track.Animation.Name or "")
        for _, t in ipairs(DETECT_ORDER) do
            for _, p in ipairs(PATTERNS[t]) do
                if string.find(tName, p) or string.find(aName, p) then return t end
            end
        end
        return nil
    end

    local function _loadPool(animType, skinName)
        local animId = ANIM_DB[animType] and ANIM_DB[animType][skinName]
        if not animId then return false end
        if _skinAnim.pools[animType] then
            for _, t in ipairs(_skinAnim.pools[animType]) do
                pcall(function() t:Stop(0); t:Destroy() end)
            end
        end
        _skinAnim.pools[animType]    = {}
        _skinAnim.poolIdx[animType]  = 1
        _skinAnim.active[animType]   = nil
        _skinAnim.replacing[animType] = false
        local isLooped = LOOPED[animType] or false
        local priority = PRIORITY[animType] or Enum.AnimationPriority.Action4
        local anim     = Instance.new("Animation")
        anim.AnimationId = animId
        anim.Name        = "CUSTOM_" .. animType:upper()
        for i = 1, (isLooped and 1 or 3) do
            local ok, track = pcall(function() return Animator:LoadAnimation(anim) end)
            if ok and track then
                track.Priority = priority
                track.Looped   = isLooped
                track.Name     = animType .. "_POOL_" .. i
                table.insert(_skinAnim.pools[animType], track)
            end
        end
        return #_skinAnim.pools[animType] > 0
    end

    local function _loadAllPools(skinName)
        local any = false
        for t in pairs(ANIM_DB) do if _loadPool(t, skinName) then any = true end end
        return any
    end

    local function _stopCustomExcept(except)
        for t, track in pairs(_skinAnim.active) do
            if t ~= except and track and track.IsPlaying then
                pcall(function() track:Stop(0.1) end)
                _skinAnim.active[t] = nil
            end
        end
    end

    local function _replace(origTrack, animType)
        if _skinAnim.replacing[animType] then
            _skinAnim.killed[origTrack] = tick()
            pcall(function() origTrack:Stop(0); origTrack:AdjustSpeed(0) end)
            return
        end
        local current = _skinAnim.active[animType]
        if current and current.IsPlaying then
            _skinAnim.killed[origTrack] = tick()
            pcall(function() origTrack:Stop(0); origTrack:AdjustSpeed(0) end)
            return
        end
        local pool = _skinAnim.pools[animType]
        if not pool or #pool == 0 then return end
        _skinAnim.replacing[animType] = true
        _skinAnim.killed[origTrack]   = tick()
        pcall(function() origTrack:Stop(0); origTrack:AdjustSpeed(0); origTrack.TimePosition = 0 end)
        if animType == "FishCaught" then
            _stopCustomExcept("FishCaught")
            for _, t in ipairs(humanoid:GetPlayingAnimationTracks()) do
                if not _isCustom(t) and not _skinAnim.killed[t] then
                    _skinAnim.killed[t] = tick()
                    pcall(function() t:Stop(0); t:AdjustSpeed(0) end)
                end
            end
        elseif not LOOPED[animType] then
            for ot, ot2 in pairs(_skinAnim.active) do
                if ot ~= animType and not LOOPED[ot] and ot ~= "FishCaught" and ot2 and ot2.IsPlaying then
                    pcall(function() ot2:Stop(0.1) end)
                    _skinAnim.active[ot] = nil
                end
            end
        end
        local nextTrack = nil
        for _, t in ipairs(pool) do if not t.IsPlaying then nextTrack = t; break end end
        if not nextTrack then
            local idx = (_skinAnim.poolIdx[animType] or 1) % #pool + 1
            _skinAnim.poolIdx[animType] = idx
            nextTrack = pool[idx]
            pcall(function() nextTrack:Stop(0) end)
        end
        pcall(function() nextTrack.Looped = LOOPED[animType] or false; nextTrack:Play(0,1,1); nextTrack:AdjustSpeed(1) end)
        _skinAnim.active[animType] = nextTrack
        local conn; conn = nextTrack.Stopped:Connect(function()
            if _skinAnim.active[animType] == nextTrack then _skinAnim.active[animType] = nil end
            if conn then conn:Disconnect(); conn = nil end
        end)
        _skinAnim.replacing[animType] = false
        task.delay(2, function() _skinAnim.killed[origTrack] = nil end)
    end

    local function _setupConns()
        _skinAnim.conns.animPlayed = humanoid.AnimationPlayed:Connect(function(track)
            if not _skinAnim.enabled or _isCustom(track) then return end
            local t = _detectType(track)
            if t and _skinAnim.pools[t] and #_skinAnim.pools[t] > 0 then
                task.spawn(function() _replace(track, t) end)
            end
        end)
        _skinAnim.conns.heartbeat = RunService.Heartbeat:Connect(function()
            if not _skinAnim.enabled then return end
            for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                if _isCustom(track) or not track.IsPlaying then continue end
                if _skinAnim.killed[track] then
                    pcall(function() track:Stop(0); track:AdjustSpeed(0) end); continue
                end
                local t = _detectType(track)
                if not t or not (_skinAnim.pools[t] and #_skinAnim.pools[t] > 0) then continue end
                local cur = _skinAnim.active[t]
                if not cur or not cur.IsPlaying then
                    task.spawn(function() _replace(track, t) end)
                else
                    _skinAnim.killed[track] = tick()
                    pcall(function() track:Stop(0); track:AdjustSpeed(0) end)
                end
            end
        end)
    end

    local function _disconnectConns()
        for _, c in pairs(_skinAnim.conns) do
            if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
        end
        _skinAnim.conns = {}
    end

    LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(1.5)
        char      = newChar
        humanoid  = char:WaitForChild("Humanoid")
        Animator  = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
        _skinAnim.killed    = {}
        _skinAnim.active    = {}
        _skinAnim.replacing = {}
        if _skinAnim.enabled and _skinAnim.current ~= "" then
            task.wait(0.5)
            _loadAllPools(_skinAnim.current)
            _disconnectConns()
            _setupConns()
        end
    end)

    local defaultSkin = skinNames[1] or ""
    if defaultSkin ~= "" then _skinAnim.current = defaultSkin end

    SkinSection:AddDropdown({
        Title    = "Select Skin",
        Options  = skinNames,
        Default  = defaultSkin,
        NoSave   = false,
        Callback = function(selected)
            _skinAnim.current = selected
            if _skinAnim.enabled then
                _skinAnim.active    = {}
                _skinAnim.replacing = {}
                _loadAllPools(selected)
            end
        end,
    })

    SkinSection:AddToggle({
        Title    = "Enable Skin Animation",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            _skinAnim.enabled = on
            if on then
                if _skinAnim.current == "" then return end
                local ok = _loadAllPools(_skinAnim.current)
                if ok then
                    _skinAnim.killed    = {}
                    _skinAnim.active    = {}
                    _skinAnim.replacing = {}
                    _setupConns()
                end
            else
                _disconnectConns()
                _skinAnim.killed    = {}
                _skinAnim.active    = {}
                _skinAnim.replacing = {}
                for _, pool in pairs(_skinAnim.pools) do
                    for _, t in ipairs(pool) do pcall(function() t:Stop(0) end) end
                end
            end
        end,
    })
end

do
    local EmoteTab     = MainWindow:AddTab({ Name = "Emote", Icon = "user" })
    local EmoteSection = EmoteTab:AddSection("Emote", false)

    local RunService        = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local _emote = {
        selected  = "",
        enabled   = false,
        conn      = nil,
        track     = nil,
        loaded    = {},
        dataMap   = {},
        list      = {},
    }

    for _, moduleScript in ipairs(ReplicatedStorage.Emotes:GetChildren()) do
        local ok, data = pcall(require, moduleScript)
        if ok and type(data) == "table" and data.Data and data.Data.Name and data.AnimationId then
            local displayName = data.Data.Name
            table.insert(_emote.list, displayName)
            _emote.dataMap[displayName] = {
                AnimationId = data.AnimationId,
                Priority    = data.AnimationPriority or Enum.AnimationPriority.Action3,
                Looped      = data.Looped           or false,
                Speed       = data.PlaybackSpeed    or 1,
            }
        end
    end
    table.sort(_emote.list)
    _emote.selected = _emote.list[1] or ""

    local function _getAnimator()
        local char = LocalPlayer.Character
        if not char then return nil end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return nil end
        return humanoid:FindFirstChildOfClass("Animator")
            or Instance.new("Animator", humanoid)
    end

    local function _stopEmote()
        if _emote.track and _emote.track.IsPlaying then
            pcall(function() _emote.track:Stop(0.2) end)
        end
        _emote.track = nil
    end

    local function _playEmote(emoteName)
        local data = _emote.dataMap[emoteName]
        if not data then return end

        local animator = _getAnimator()
        if not animator then return end

        _stopEmote()

        if not _emote.loaded[emoteName] then
            local anim        = Instance.new("Animation")
            anim.AnimationId  = data.AnimationId
            local ok, track   = pcall(function() return animator:LoadAnimation(anim) end)
            if not ok or not track then return end
            _emote.loaded[emoteName] = track
        end

        local track    = _emote.loaded[emoteName]
        track.Priority = data.Priority
        track.Looped   = data.Looped

        pcall(function() track:Play(0.1, 1, data.Speed) end)
        _emote.track = track
    end

    local function _disconnectConn()
        if _emote.conn then
            _emote.conn:Disconnect()
            _emote.conn = nil
        end
    end

    LocalPlayer.CharacterAdded:Connect(function()
        _emote.loaded = {}
        _emote.track  = nil
        if _emote.enabled and _emote.selected ~= "" then
            task.wait(1)
            _playEmote(_emote.selected)
        end
    end)

    EmoteSection:AddDropdown({
        Title    = "Select Emote",
        Options  = _emote.list,
        Default  = _emote.selected,
        NoSave   = false,
        Callback = function(v)
            _emote.selected = v
            if _emote.enabled then
                _playEmote(_emote.selected)
            end
        end,
    })

    EmoteSection:AddToggle({
        Title    = "Enable Emote",
        Default  = false,
        NoSave   = true,
        Callback = function(on)
            _emote.enabled = on
            if on then
                if _emote.selected == "" then return end
                _playEmote(_emote.selected)
                _emote.conn = RunService.Heartbeat:Connect(function()
                    if not _emote.enabled then return end
                    if not _emote.track or not _emote.track.IsPlaying then
                        task.spawn(function() _playEmote(_emote.selected) end)
                    end
                end)
            else
                _disconnectConn()
                _stopEmote()
            end
        end,
    })

    EmoteSection:AddButton({
        Title    = "Play Once",
        Callback = function()
            if _emote.selected == "" then
                Library:MakeNotify({
                    Title       = "Emote",
                    Description = "Pilih emote dulu dari dropdown!",
                    Delay       = 2,
                })
                return
            end
            _playEmote(_emote.selected)
            Library:MakeNotify({
                Title       = "Emote",
                Description = "Emote dimainkan: " .. _emote.selected,
                Delay       = 2,
            })
        end,
    })

    EmoteSection:AddButton({
        Title    = "Stop Emote",
        Callback = function()
            _stopEmote()
            Library:MakeNotify({
                Title       = "Emote",
                Description = "Emote dihentikan.",
                Delay       = 2,
            })
        end,
    })
end

do
    local _data = nil
    pcall(function()
        _data = require(ReplicatedStorage.Packages.Replion).Client:WaitReplion("Data")
    end)

    local _RS          = game:GetService("ReplicatedStorage")
    local _ItemsFolder = _RS:FindFirstChild("Items") or _RS:WaitForChild("Items", 10)
    local _BaitsFolder = _RS:FindFirstChild("Baits") or _RS:WaitForChild("Baits", 10)

    local function _getJungle()
        return workspace:FindFirstChild("JUNGLE INTERACTIONS")
    end

    local _artifactPositions = {
        ["Arrow Artifact"]             = CFrame.new(875,  3,   -368) * CFrame.Angles(0, math.rad(90),   0),
        ["Crescent Artifact"]          = CFrame.new(1403, 3,    123) * CFrame.Angles(0, math.rad(180),  0),
        ["Hourglass Diamond Artifact"] = CFrame.new(1487, 3,   -842) * CFrame.Angles(0, math.rad(180),  0),
        ["Diamond Artifact"]           = CFrame.new(1844, 3,   -287) * CFrame.Angles(0, math.rad(-90),  0),
    }
    local _artifactOrder = {
        "Arrow Artifact", "Crescent Artifact",
        "Hourglass Diamond Artifact", "Diamond Artifact",
    }
    local _artifactIds = {
        ["Arrow Artifact"]             = 265,
        ["Crescent Artifact"]          = 266,
        ["Diamond Artifact"]           = 267,
        ["Hourglass Diamond Artifact"] = 271,
    }

    local function _hasArtifactInInventory(artifactName)
        if not _data then return false end
        local targetId = _artifactIds[artifactName]
        if not targetId then return false end
        local ok, inv = pcall(function() return _data:Get({"Inventory"}) end)
        if not ok or not inv then return false end
        local buckets = { inv.Items, inv.Gears, inv.Artifacts }
        for _, bucket in ipairs(buckets) do
            if bucket then
                for _, item in pairs(bucket) do
                    if item and tonumber(item.Id) == targetId then
                        return true
                    end
                end
            end
        end
        return false
    end

    local _rodPriority = {
        "Diamond Rod", "Element Rod", "Ghostfin Rod",
        "Bambo Rod", "Angler Rod", "Ares Rod",
        "Hazmat Rod", "Astral Rod", "Midnight Rod",
    }

    local _fishTargetIds = {
        ["Freshwater Piranha"]    = 284,
        ["Goliath Tiger"]         = 270,
        ["Sacred Guardian Squid"] = 283,
        ["Crocodile"]             = 263,
    }
    local _ruinTiers = {
        "Freshwater Piranha",
        "Goliath Tiger",
        "Sacred Guardian Squid",
        "Crocodile",
    }
    local _rodNameCache  = {}
    local _baitNameCache = {}

    local _TP_MIN_DIST = 5

    local function _tp(cf, force)
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local targetCF  = typeof(cf) == "Vector3" and CFrame.new(cf) or cf
        local targetPos = targetCF.Position
        if not force then
            local dist = (root.Position - targetPos).Magnitude
            if dist <= _TP_MIN_DIST then return end
        end
        local rng    = Random.new()
        local jitter = Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2))
        root.CFrame  = CFrame.new(targetPos + jitter) * (targetCF - targetCF.Position)
    end

    local function _getItemName(folder, id, itemType)
        for _, v in ipairs(folder:GetChildren()) do
            if v:IsA("ModuleScript") then
                local ok, d = pcall(require, v)
                if ok and d and d.Data then
                    if d.Data.Id == id and (not itemType or d.Data.Type == itemType) then
                        return d.IsSkin and nil or d.Data.Name
                    end
                end
            end
        end
        return nil
    end

    local function _getRodName(id)
        if _rodNameCache[id] ~= nil then return _rodNameCache[id] or nil end
        local n = _getItemName(_ItemsFolder, id, "Fishing Rods")
        _rodNameCache[id] = n or false
        return n
    end

    local function _getBaitName(id)
        if _baitNameCache[id] ~= nil then return _baitNameCache[id] or nil end
        local n = _getItemName(_BaitsFolder, id)
        _baitNameCache[id] = n or false
        return n
    end

    local function _hasRodById(id)
        if not _data then return false end
        for _, v in ipairs((_data:Get({"Inventory"}) or {})["Fishing Rods"] or {}) do
            if v.Id == id then return true end
        end
        return false
    end

    local function _hasBaitById(id)
        if not _data then return false end
        for _, v in ipairs((_data:Get({"Inventory"}) or {}).Baits or {}) do
            if v.Id == id then return true end
        end
        return false
    end

    local function _getLeverStatus()
        local result = {}
        local _ji = _getJungle()
        if not _ji then return result end
        for _, v in ipairs(_ji:GetDescendants()) do
            if v:IsA("Model") and v.Name == "TempleLever" then
                local t = v:GetAttribute("Type")
                if t then
                    result[t] = not v:FindFirstChild("RootPart")
                        or not v.RootPart:FindFirstChildWhichIsA("ProximityPrompt")
                end
            end
        end
        return result
    end

    local function _triggerLeverByType(leverType)
        local remote = NetEvents.RE_PlaceLeverItem
        if remote then
            local ok = pcall(function() remote:FireServer(leverType) end)
            if ok then return true end
        end
        local _ji = _getJungle()
        if not _ji then return false end
        for _, v in ipairs(_ji:GetDescendants()) do
            if v:IsA("Model") and v.Name == "TempleLever"
                and v:GetAttribute("Type") == leverType
            then
                local prompt = v:FindFirstChild("RootPart")
                    and v.RootPart:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then
                    fireproximityprompt(prompt)
                    return true
                end
            end
        end
        return false
    end

    local function _artifactToLeverType(artifactName)
        return artifactName
    end

    local function _leverIsDoneByType(leverType)
        if _data then
            local ok, tl = pcall(function() return _data:GetExpect({"TempleLevers"}) end)
            if ok and tl and tl[leverType] then return true end
            ok, tl = pcall(function() return _data:Get({"TempleLevers"}) end)
            if ok and tl and tl[leverType] then return true end
        end
        local _ji = _getJungle()
        if not _ji then return false end
        for _, v in ipairs(_ji:GetDescendants()) do
            if v:IsA("Model") and v.Name == "TempleLever"
                and v:GetAttribute("Type") == leverType
            then
                local prompt = v:FindFirstChild("RootPart")
                    and v.RootPart:FindFirstChildWhichIsA("ProximityPrompt")
                return (prompt == nil)
            end
        end
        return false
    end

    local function _artifactIsDone(artifactName)
        return _leverIsDoneByType(_artifactToLeverType(artifactName))
    end

    local function _readTracker(trackerName)
        local rings = workspace:FindFirstChild("!!! MENU RINGS")
        local node  = rings and rings:FindFirstChild(trackerName)
        if not node then return "" end
        local content = node:FindFirstChild("Board")
            and node.Board:FindFirstChild("Gui")
            and node.Board.Gui:FindFirstChild("Content")
        if not content then return "" end
        local lines, n = {}, 1
        for _, v in ipairs(content:GetChildren()) do
            if v:IsA("TextLabel") and v.Name ~= "Header" then
                table.insert(lines, n .. ". " .. v.Text)
                n += 1
            end
        end
        return table.concat(lines, "\n")
    end

    local function _artifactStatusText()
        local lines = {}
        for _, name in ipairs(_artifactOrder) do
            local done   = _artifactIsDone(name)
            local label  = name:gsub(" Artifact", "")
            local status = done and "[DONE]" or "[PENDING]"
            table.insert(lines, ("%s : %s"):format(label, status))
        end
        return table.concat(lines, "\n")
    end

    local function _equipRod(uuid)
        pcall(function()
            if NetEvents.RF_CancelFishingInputs then
                NetEvents.RF_CancelFishingInputs:InvokeServer()
                task.wait(0.4)
            end
            if NetEvents.RE_EquipItem then
                NetEvents.RE_EquipItem:FireServer(uuid, "Fishing Rods")
                task.wait(0.4)
            end
            if NetEvents.RF_EquipToolFromHotbar then
                NetEvents.RF_EquipToolFromHotbar:FireServer(1)
            end
        end)
    end

    local function _hasItemsToSell()
        if not _data then return false end
        local inv = _data:Get({"Inventory"}) or {}
        return inv.Items and #inv.Items > 0
    end

    local function _parseFishName(fishData)
        if type(fishData) == "string" then return fishData end
        if type(fishData) == "table" then
            return fishData.Name or fishData.name or fishData.FishName
                or fishData.fishName or fishData.ItemName or tostring(fishData)
        end
        return tostring(fishData)
    end

    local _questLocations = {
        ["A New Adventure"]        = CFrame.new(109,    3,    -8),
        ["Lost Treasure"]          = CFrame.new(-3601, -283, -1611),
        ["Swimming Narwhals"]      = CFrame.new(-3699, -135,  -890),
        ["Suited Up"]              = CFrame.new(-552,   19,   183),
        ["Diamond Researcher"]     = CFrame.new(109,    3,    -8),
        ["Volcanic Fish"]          = CFrame.new(-552,   19,   183),
        ["The Mysterious Cave"]    = CFrame.new(-2084,  3,  3700),
        ["Frog Army"]              = CFrame.new(-2084,  3,  3700),
        ["Deadman's Treasure"]     = CFrame.new(109,    3,    -8),
        ["Black Pearl"]            = CFrame.new(-3601, -283, -1611),
        ["Deep Sea Quest"]         = CFrame.new(-3599, -276, -1641),
        ["Element Quest"]          = CFrame.new(1484,   3,   -336),
        ["Diamond Rod Quest"]      = CFrame.new(-2084,  3,  3700),
        ["Complete a Epic Bounty"] = CFrame.new(109,    3,    -8),
    }

    local _questStages = {
        ["Deep Sea Quest"] = {
            { keyword = "treasure", location = CFrame.new(-3601, -283, -1611) },
            { keyword = "sisyphus", location = CFrame.new(-3699, -135,  -890) },
            { keyword = "secret",   location = CFrame.new(-3699, -135,  -890) },
            { keyword = "mythic",   location = CFrame.new(-3699, -135,  -890) },
            { keyword = "earn",     location = CFrame.new( 109,    3,    -8)  },
            { keyword = "default",  location = CFrame.new(-3601, -283, -1611) },
        },
        ["Element Quest"] = {
            { keyword = "ancient jungle", location = CFrame.new(1484,   3, -336) },
            { keyword = "sacred temple",  location = CFrame.new(1453, -22, -636) },
            { keyword = "transcended",    location = CFrame.new(1480, 128, -593) },
            { keyword = "default",        location = CFrame.new(1484,   3, -336) },
        },
        ["Diamond Rod Quest"] = {
            { keyword = "tropical", location = CFrame.new(-2084,   3, 3700) },
            { keyword = "coral",    location = CFrame.new(-3350, -80, 2100) },
            { keyword = "secret",   location = CFrame.new(-2084,   3, 3700) },
            { keyword = "default",  location = CFrame.new(-2084,   3, 3700) },
        },
    }

    local function _getQuestLocation(questName, objText)
        local lower  = (objText or ""):lower()
        local stages = _questStages[questName]
        if stages then
            local default = nil
            for _, s in ipairs(stages) do
                if s.keyword == "default" then
                    default = s.location
                elseif lower:find(s.keyword, 1, true) then
                    return s.location
                end
            end
            if default then return default end
        end
        return _questLocations[questName]
    end

    local function _getActiveQuests()
        local result   = {}
        local questGui = LocalPlayer.PlayerGui:FindFirstChild("Quest")
        if not questGui then return result end
        local inside = questGui:FindFirstChild("List")
            and questGui.List:FindFirstChild("Inside")
        if not inside then return result end
        for _, f in ipairs(inside:GetChildren()) do
            if not (f:IsA("Frame") and f.Name == "Quest") then continue end
            local top  = f:FindFirstChild("Top") and f.Top:FindFirstChild("TopFrame")
            local name = top and top:FindFirstChild("Header") and top.Header.Text or ""
            if name == "" or name == "?" then continue end
            local entry   = { name = name, objectives = {} }
            local content = f:FindFirstChild("Content")
            if content then
                for _, obj in ipairs(content:GetChildren()) do
                    if not (obj:IsA("Frame") and obj.Name:find("Objective")) then continue end
                    local bar     = obj:FindFirstChild("BarFrame")
                    local progTxt = bar and bar:FindFirstChild("Progress")
                        and bar.Progress.Text or "0 / 0"
                    local disp    = obj:FindFirstChild("Content")
                        and obj.Content:FindFirstChild("Display")
                    local prefix  = disp and disp:FindFirstChild("Prefix")
                        and disp.Prefix.Text or ""
                    local cur, max = progTxt:match("(%d+)%s*/%s*(%d+)")
                    cur = tonumber(cur) or 0
                    max = tonumber(max) or 1
                    table.insert(entry.objectives, {
                        text     = prefix,
                        progress = cur,
                        max      = max,
                        done     = cur >= max,
                    })
                end
            end
            table.insert(result, entry)
        end
        return result
    end

    local QuestTab = MainWindow:AddTab({ Name = "Quest [BETA]", Icon = "scroll" })

    -- =========================================================================
    -- KAITUN
    -- =========================================================================
    do
        local _ROD_MIDNIGHT_ID   = 80
        local _ROD_ASTRAL_ID     = 5
        local _ROD_DIAMOND_ID    = 95
        local _BAIT_MIDNIGHT_ID  = 3
        local _BAIT_ASTRAL_ID    = 15
        local _BAIT_FLORAL_ID    = 20
        local _ROD_MIDNIGHT_COST = 53000
        local _ROD_ASTRAL_COST   = 1000000
        local _BAIT_FLORAL_COST  = 4000000

        -- Koordinat NPC Diamond Researcher
        local _DIAMOND_NPC_CF = CFrame.new(
            -1775.255, -222.634995, 23922.1328,
             0.707134247, 0, -0.707079291,
             0,           1,  0,
             0.707079291, 0,  0.707134247
        )
        local _DIAMOND_NPC_NAMES = {
            "Diamond Researcher",
            "Lary the Scientist",
            "Lary",
        }
        local _DIAMOND_LOC_ORDER = { "Coral Reefs", "Tropical Grove" }
        local _DIAMOND_LOCS = {
            ["Coral Reefs"]    = CFrame.new(-3350, -80, 2100),
            ["Tropical Grove"] = CFrame.new(-2084,   3, 3700),
        }

        local _farmLocations = {
            ["Kohana Volcano"] = Vector3.new(-552, 19,  183),
            ["Tropical Grove"] = Vector3.new(-2084, 3, 3700),
        }

        -- ── Deep Sea: SISYPHUS dulu, baru TREASURE ROOM ──────────────────────
        -- Stage:
        --   "SISYPHUS"  = perlu mancing di Sisyphus (q1 belum done)
        --   "TREASURE"  = q1 done, perlu ke Treasure Room (q2)
        --   "DONE"      = semua selesai
        local function _scanDeepProgress()
            if not _data then return "UNKNOWN" end
            local ok, ds = pcall(function()
                return _data:Get({"DeepSea", "Available", "Forever"})
            end)
            if not ok or not ds then
                ok, ds = pcall(function()
                    local d = _data:Get({"DeepSea"})
                    return d and d.Available and d.Available.Forever
                end)
            end
            if not ds then return "SISYPHUS" end

            if ds.CompletedAllQuests then return "DONE" end

            local quests = ds.Quests or {}
            -- q1 = quest Sisyphus (secret fish / mythic)
            -- q2 = quest Treasure Room
            local q1 = quests[1]
            local q2 = quests[2]
            local q1done = q1 and (q1.Progress ~= nil) and (q1.Progress <= 0)
            local q2done = q2 and (q2.Progress ~= nil) and (q2.Progress <= 0)

            if q1done and q2done then return "DONE" end
            if q1done then return "TREASURE" end
            return "SISYPHUS"
        end

        local function _scanElemProgress()
            if not _data then return "UNKNOWN" end
            local ok, ej = pcall(function()
                return _data:Get({"ElementJungle", "Available", "Forever"})
            end)
            if not ok or not ej then
                ok, ej = pcall(function()
                    local d = _data:Get({"ElementJungle"})
                    return d and d.Available and d.Available.Forever
                end)
            end
            if not ej then return "STAGE1" end
            if ej.CompletedAllQuests then return "DONE" end
            local quests = ej.Quests or {}
            local q1 = quests[1]; local q2 = quests[2]; local q3 = quests[3]
            local q1done = q1 and q1.Progress ~= nil and q1.Progress <= 0
            local q2done = q2 and q2.Progress ~= nil and q2.Progress <= 0
            local q3done = q3 and q3.Progress ~= nil and q3.Progress <= 0
            if q1done and q2done and q3done then return "DONE" end
            if q1done and q2done then return "STAGE3" end
            if q1done then return "STAGE2" end
            return "STAGE1"
        end

        local function _scanArtProgress()
            for _, name in ipairs(_artifactOrder) do
                if not _artifactIsDone(name) then return "PENDING" end
            end
            return "DONE"
        end

        local function _scanDiamondProgress()
            if _hasRodById(_ROD_DIAMOND_ID) then return "DONE" end
            if _data then
                local cq = _data:Get({"CompletedQuests"}) or {}
                for _, v in ipairs(cq) do
                    if v == "Diamond Researcher" then return "DONE" end
                end
                local nt = _data:Get({"NPCTags"}) or {}
                if nt["Diamond Researcher"] then return "IN_PROGRESS" end
            end
            local questGui = LocalPlayer.PlayerGui:FindFirstChild("Quest")
            if questGui then
                local inside = questGui:FindFirstChild("List")
                    and questGui.List:FindFirstChild("Inside")
                if inside then
                    for _, f in ipairs(inside:GetChildren()) do
                        if f:IsA("Frame") and f.Name == "Quest" then
                            local top  = f:FindFirstChild("Top")
                                and f.Top:FindFirstChild("TopFrame")
                            local name = top and top:FindFirstChild("Header")
                                and top.Header.Text or ""
                            local lower = name:lower()
                            if lower:find("diamond", 1, true)
                            or lower:find("researcher", 1, true) then
                                return "IN_PROGRESS"
                            end
                        end
                    end
                end
            end
            return "NEED_NPC"
        end

        -- ── State ─────────────────────────────────────────────────────────────
        local _kaitun = {
            enabled         = false,
            farmLoc         = "Kohana Volcano",
            -- items
            hasMidnight     = false,
            hasAstral       = false,
            hasFloral       = false,
            -- quest flags (urutan linear)
            deepDone        = false,   -- step 3+4: Sisyphus → Treasure
            artDone         = false,   -- step 5: Artifact Quest
            floralDone      = false,   -- step 6: beli Floral Bait
            elemDone        = false,   -- step 7: Element Quest
            diamondNpcDone  = false,   -- step 8a: ngobrol NPC
            diamondDone     = false,   -- step 8b: dapat Diamond Rod
            diamondLocIndex = 1,
            lastBuyTime     = 0,
            BUY_COOLDOWN    = 15,
            SELL_INTERVAL   = 1800,
            pendingArtifact = nil,
            sellThread      = nil,
            mainThread      = nil,
            fishConn        = nil,
            panelGui        = nil,
        }

        local function _setStatus(text)
            if _kaitun.panelGui and _kaitun.panelGui.status then
                _kaitun.panelGui.status.Text = tostring(text or "...")
            end
        end

        local function _tryBuy(label, fn)
            local now  = tick()
            local wait = _kaitun.BUY_COOLDOWN - (now - _kaitun.lastBuyTime)
            if wait > 0 then
                _setStatus(("Cooldown beli %s... %.0fs"):format(label, wait))
                task.wait(math.min(wait, 2))
                return false
            end
            _setStatus("Membeli " .. label .. "...")
            _kaitun.lastBuyTime = tick()
            local ok, err = pcall(fn)
            if not ok then _setStatus("Gagal beli: " .. tostring(err)) end
            task.wait(5)
            return true
        end

        -- ── Panel Builder ─────────────────────────────────────────────────────
        local function _buildPanel()
            local CoreGui  = game:GetService("CoreGui")
            local Lighting = game:GetService("Lighting")
            local old = CoreGui:FindFirstChild("LynxKaitunPanel")
            if old then old:Destroy() end

            local blur = Lighting:FindFirstChildOfClass("BlurEffect")
                or Instance.new("BlurEffect", Lighting)
            blur.Size    = 25
            blur.Enabled = true

            local screen = Instance.new("ScreenGui")
            screen.Name           = "LynxKaitunPanel"
            screen.IgnoreGuiInset = true
            screen.ResetOnSpawn   = false
            screen.ZIndexBehavior = Enum.ZIndexBehavior.Global
            screen.Parent         = CoreGui

            local vp    = workspace.CurrentCamera.ViewportSize
            local sw, sh = vp.X, vp.Y
            local scale = sw < 480 and 0.55 or sw < 768 and 0.72 or sw < 1024 and 0.85 or 1.0
            local panelW = math.min(math.floor(560 * scale), sw - 24)
            local panelH = math.min(math.floor(680 * scale), sh - 24)

            local fTitle    = math.max(12, math.floor(22 * scale))
            local fSub      = math.max(9,  math.floor(12 * scale))
            local fRow      = math.max(9,  math.floor(13 * scale))
            local fHdr      = math.max(8,  math.floor(10 * scale))
            local fBlock    = math.max(8,  math.floor(12 * scale))
            local rowH      = math.max(16, math.floor(22 * scale))
            local statusH   = math.max(20, math.floor(34 * scale))
            local progressH = math.max(100, math.floor(160 * scale))
            local artifactH = math.max(40,  math.floor(56 * scale))
            local questH    = math.max(40,  math.floor(60 * scale))

            local overlay = Instance.new("Frame", screen)
            overlay.Size                   = UDim2.new(1, 0, 1, 0)
            overlay.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
            overlay.BackgroundTransparency = 0.45
            overlay.BorderSizePixel        = 0
            overlay.ZIndex                 = 1

            local container = Instance.new("Frame", screen)
            container.Size                   = UDim2.new(0, panelW, 0, panelH)
            container.AnchorPoint            = Vector2.new(0.5, 0.5)
            container.Position               = UDim2.new(0.5, 0, 0.5, 0)
            container.BackgroundTransparency = 1
            container.BorderSizePixel        = 0
            container.ZIndex                 = 2

            local layout = Instance.new("UIListLayout", container)
            layout.Padding             = UDim.new(0, math.max(3, math.floor(6 * scale)))
            layout.SortOrder           = Enum.SortOrder.LayoutOrder
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

            local uiPad = Instance.new("UIPadding", container)
            uiPad.PaddingLeft   = UDim.new(0, math.max(6, math.floor(12 * scale)))
            uiPad.PaddingRight  = UDim.new(0, math.max(6, math.floor(12 * scale)))
            uiPad.PaddingTop    = UDim.new(0, math.max(6, math.floor(10 * scale)))
            uiPad.PaddingBottom = UDim.new(0, math.max(6, math.floor(10 * scale)))

            local function _makeLabel(parent, text, size, color, bold, order, transparency)
                local lbl = Instance.new("TextLabel", parent)
                lbl.Size                   = UDim2.new(1, 0, 0, size + 6)
                lbl.BackgroundTransparency = 1
                lbl.Font                   = bold and Enum.Font.GothamBold or Enum.Font.Gotham
                lbl.Text                   = text
                lbl.TextSize               = size
                lbl.TextColor3             = color
                lbl.TextTransparency       = transparency or 0
                lbl.TextXAlignment         = Enum.TextXAlignment.Center
                lbl.TextWrapped            = true
                lbl.RichText               = true
                lbl.LayoutOrder            = order or 0
                return lbl
            end

            local function _makeDivider(parent, order)
                local div = Instance.new("Frame", parent)
                div.Size                   = UDim2.new(0.6, 0, 0, 1)
                div.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
                div.BackgroundTransparency = 0.75
                div.BorderSizePixel        = 0
                div.LayoutOrder            = order
                return div
            end

            local function _makeRow(parent, labelText, order)
                local row = Instance.new("Frame", parent)
                row.Size                   = UDim2.new(1, 0, 0, rowH)
                row.BackgroundTransparency = 1
                row.LayoutOrder            = order
                local lbl = Instance.new("TextLabel", row)
                lbl.Size = UDim2.new(0.5, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.Gotham
                lbl.Text = labelText
                lbl.TextSize = fRow
                lbl.TextColor3 = Color3.fromRGB(255, 160, 60)
                lbl.TextXAlignment = Enum.TextXAlignment.Right
                lbl.TextTransparency = 0.1
                local sep = Instance.new("TextLabel", row)
                sep.Size = UDim2.new(0, 20, 1, 0)
                sep.Position = UDim2.new(0.5, -10, 0, 0)
                sep.BackgroundTransparency = 1
                sep.Font = Enum.Font.Gotham
                sep.Text = ":"
                sep.TextSize = fRow
                sep.TextColor3 = Color3.fromRGB(255, 255, 255)
                sep.TextTransparency = 0.5
                sep.TextXAlignment = Enum.TextXAlignment.Center
                local val = Instance.new("TextLabel", row)
                val.Size = UDim2.new(0.5, -10, 1, 0)
                val.Position = UDim2.new(0.5, 10, 0, 0)
                val.BackgroundTransparency = 1
                val.Font = Enum.Font.GothamBold
                val.Text = "..."
                val.TextSize = fRow
                val.TextColor3 = Color3.fromRGB(255, 255, 255)
                val.TextXAlignment = Enum.TextXAlignment.Left
                val.RichText = true
                return val
            end

            local function _makeBlock(parent, labelText, h, order)
                local wrap = Instance.new("Frame", parent)
                wrap.Size                   = UDim2.new(1, 0, 0, h + math.floor(24 * scale))
                wrap.BackgroundTransparency = 1
                wrap.LayoutOrder            = order
                local hdr = Instance.new("TextLabel", wrap)
                hdr.Size = UDim2.new(1, 0, 0, math.max(10, math.floor(14 * scale)))
                hdr.BackgroundTransparency = 1
                hdr.Font = Enum.Font.GothamBold
                hdr.Text = labelText:upper()
                hdr.TextSize = fHdr
                hdr.TextColor3 = Color3.fromRGB(255, 140, 30)
                hdr.TextXAlignment = Enum.TextXAlignment.Center
                hdr.TextTransparency = 0.2
                local val = Instance.new("TextLabel", wrap)
                val.Size = UDim2.new(1, 0, 0, h)
                val.Position = UDim2.new(0, 0, 0, math.max(10, math.floor(16 * scale)))
                val.BackgroundTransparency = 1
                val.Font = Enum.Font.Gotham
                val.Text = "..."
                val.TextSize = fBlock
                val.TextColor3 = Color3.fromRGB(230, 230, 230)
                val.TextXAlignment = Enum.TextXAlignment.Center
                val.TextYAlignment = Enum.TextYAlignment.Top
                val.TextWrapped = true
                val.RichText = true
                return val
            end

            local title = _makeLabel(container,
                '<font color="rgb(255,160,40)">LYNX</font>  <font color="rgb(255,255,255)">-  KAITUN PANEL</font>',
                fTitle, Color3.fromRGB(255,255,255), true, 1)
            title.RichText = true

            _makeLabel(container, "Auto Quest & Farming Manager",
                fSub, Color3.fromRGB(180,180,200), false, 2, 0.3)
            _makeDivider(container, 3)

            local coinsVal = _makeRow(container, "Coins",    4)
            local rodsVal  = _makeRow(container, "Best Rod", 5)
            local baitsVal = _makeRow(container, "Baits",    6)
            _makeDivider(container, 7)

            local statusVal   = _makeBlock(container, "Flow Status",    statusH,   8)
            _makeDivider(container, 9)
            local progressVal = _makeBlock(container, "Progress",       progressH, 10)
            _makeDivider(container, 11)
            local artifactVal = _makeBlock(container, "Artifact Quest", artifactH, 12)
            _makeDivider(container, 13)
            local questVal    = _makeBlock(container, "Active Quest",   questH,    14)

            return {
                screen   = screen,
                blur     = blur,
                coins    = coinsVal,
                rods     = rodsVal,
                baits    = baitsVal,
                status   = statusVal,
                progress = progressVal,
                artifact = artifactVal,
                quest    = questVal,
            }
        end

        -- ── Update Panel ──────────────────────────────────────────────────────
        local function _updatePanel(k)
            local gui = k.panelGui
            if not gui or not _data then return end
            pcall(function()
                local coins = _data:Get({"Coins"}) or 0
                local inv   = _data:Get({"Inventory"}) or {}

                gui.coins.Text = ("$%d"):format(coins)

                local bestRod, bestPrio = nil, math.huge
                for _, v in ipairs(inv["Fishing Rods"] or {}) do
                    local n = _getRodName(v.Id)
                    if n then
                        for i, kw in ipairs(_rodPriority) do
                            if n:lower():find(kw:lower(), 1, true) and i < bestPrio then
                                bestPrio = i; bestRod = n; break
                            end
                        end
                    end
                end
                gui.rods.Text = bestRod or "None"

                local _baitPrio = { "Floral Bait", "Astral Bait", "Midnight Bait" }
                local bestBait, bestBaitPrio = nil, math.huge
                for _, v in ipairs(inv.Baits or {}) do
                    local n = _getBaitName(v.Id)
                    if n then
                        for i, kw in ipairs(_baitPrio) do
                            if n:lower():find(kw:lower(), 1, true) and i < bestBaitPrio then
                                bestBaitPrio = i; bestBait = n; break
                            end
                        end
                    end
                end
                if not bestBait then
                    for _, v in ipairs(inv.Baits or {}) do
                        local n = _getBaitName(v.Id)
                        if n then bestBait = n; break end
                    end
                end
                gui.baits.Text = bestBait or "None"

                local function ck(b)
                    return b
                        and '<font color="rgb(80,230,120)">V</font>'
                        or  '<font color="rgb(255,80,80)">X</font>'
                end
                -- Urutan progress sesuai urutan misi
                gui.progress.Text = table.concat({
                    ck(k.hasMidnight)    .. " [1] Midnight Rod",
                    ck(k.hasAstral)      .. " [2] Astral Rod",
                    ck(k.deepDone)       .. " [3] Deep Sea Quest (Sisyphus + Treasure)",
                    ck(k.artDone)        .. " [4] Artifact Quest",
                    ck(k.hasFloral)      .. " [5] Floral Bait",
                    ck(k.elemDone)       .. " [6] Element Quest",
                    ck(k.diamondNpcDone) .. " [7a] Diamond NPC",
                    ck(k.diamondDone)    .. " [7b] Diamond Rod",
                }, "\n")

                gui.artifact.Text = _artifactStatusText()

                local quests = _getActiveQuests()
                if #quests > 0 then
                    local lines = {}
                    for _, q in ipairs(quests) do
                        table.insert(lines, q.name)
                        for _, obj in ipairs(q.objectives) do
                            table.insert(lines, ("  %s %s (%d/%d)"):format(
                                obj.done and "[v]" or "[ ]",
                                obj.text, obj.progress, obj.max))
                        end
                    end
                    gui.quest.Text = table.concat(lines, "\n")
                else
                    gui.quest.Text = "Tidak ada quest aktif"
                end
            end)
        end

        -- ── Fish event connector ──────────────────────────────────────────────
        local function _connectFishEvent(k)
            if k.fishConn then k.fishConn:Disconnect(); k.fishConn = nil end
            local fishEvent = NetEvents.RE_FishCaught
            if not fishEvent then
                warn("[Kaitun] RE_FishCaught tidak ditemukan!")
                return
            end
            k.fishConn = fishEvent.OnClientEvent:Connect(function(fishData)
                if not k.enabled or not k.pendingArtifact then return end
                local fishName = _parseFishName(fishData)
                local keyword  = string.split(k.pendingArtifact, " ")[1]
                if keyword and tostring(fishName):find(keyword, 1, true) then
                    task.wait(0)
                    _triggerLeverByType(k.pendingArtifact)
                    k.pendingArtifact = nil
                end
            end)
        end

        -- ── Diamond NPC trigger ───────────────────────────────────────────────
        local function _triggerDiamondNpc()
            local triggered = false
            local function _tryNPC(root)
                for _, npcName in ipairs(_DIAMOND_NPC_NAMES) do
                    local npc = root:FindFirstChild(npcName, true)
                    if npc then
                        local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            pcall(fireproximityprompt, prompt)
                            triggered = true
                            return
                        end
                    end
                end
            end
            _tryNPC(workspace:FindFirstChild("NPC") or workspace)
            if not triggered then _tryNPC(workspace) end
            if not triggered then return false end

            local deadline = tick() + 5
            repeat task.wait(0.1) until
                LocalPlayer.PlayerGui:FindFirstChild("DialoguePrompt") ~= nil
                or tick() > deadline

            local dp = LocalPlayer.PlayerGui:FindFirstChild("DialoguePrompt")
            if not dp then return false end
            task.wait(0.2)

            local list = dp:FindFirstChild("Content")
                and dp.Content:FindFirstChild("Inside")
                and dp.Content.Inside:FindFirstChild("List")
            if not list then return false end

            for _, slot in ipairs(list:GetChildren()) do
                if slot:IsA("ImageButton") then
                    local items = slot:FindFirstChild("Items")
                    local label = items and items:FindFirstChild("QuestLabel")
                    if label and label.Text == "Diamond Researcher Quest" then
                        pcall(firebutton, slot)
                        return true
                    end
                end
            end
            return false
        end

        -- ── Main Loop ─────────────────────────────────────────────────────────
        -- Urutan misi:
        --   1. Beli Midnight Rod
        --   2. Beli Astral Rod
        --   3. Deep Sea: Sisyphus (q1) → Treasure Room (q2)
        --   4. Artifact Quest
        --   5. Beli Floral Bait
        --   6. Element Quest
        --   7. Diamond NPC → mancing Diamond Rod Quest
        local function _runKaitun(k)
            while k.enabled do
                task.wait(1)
                if not _data then
                    _setStatus("Menunggu data sync...")
                    task.wait(3); continue
                end

                local coins = _data:Get({"Coins"}) or 0

                k.hasMidnight    = _hasRodById(_ROD_MIDNIGHT_ID)
                k.hasAstral      = _hasRodById(_ROD_ASTRAL_ID)
                k.hasFloral      = _hasBaitById(_BAIT_FLORAL_ID)
                k.deepDone       = (_scanDeepProgress() == "DONE")
                k.artDone        = (_scanArtProgress() == "DONE")
                k.elemDone       = (_scanElemProgress() == "DONE")
                local _dp        = _scanDiamondProgress()
                k.diamondDone    = (_dp == "DONE")
                k.diamondNpcDone = (_dp == "IN_PROGRESS" or _dp == "DONE")

                _updatePanel(k)

                -- ── Step 1: Beli Midnight Rod ──────────────────────────────
                if not k.hasMidnight then
                    if coins >= _ROD_MIDNIGHT_COST then
                        _tryBuy("Midnight Rod", function()
                            if NetEvents.RF_PurchaseFishingRod then
                                NetEvents.RF_PurchaseFishingRod:InvokeServer(_ROD_MIDNIGHT_ID)
                            end
                            task.wait(1.5)
                            if NetEvents.RF_PurchaseBait then
                                NetEvents.RF_PurchaseBait:InvokeServer(_BAIT_MIDNIGHT_ID)
                            end
                        end)
                    else
                        _setStatus(("Farming Midnight Rod $%d/$%d"):format(
                            coins, _ROD_MIDNIGHT_COST))
                        _tp(_farmLocations[k.farmLoc] or _farmLocations["Kohana Volcano"])
                    end
                    continue

                -- ── Step 2: Beli Astral Rod ────────────────────────────────
                elseif not k.hasAstral then
                    if coins >= _ROD_ASTRAL_COST then
                        _tryBuy("Astral Rod", function()
                            if NetEvents.RF_PurchaseFishingRod then
                                NetEvents.RF_PurchaseFishingRod:InvokeServer(_ROD_ASTRAL_ID)
                            end
                            task.wait(1.5)
                            if NetEvents.RF_PurchaseBait then
                                NetEvents.RF_PurchaseBait:InvokeServer(_BAIT_ASTRAL_ID)
                            end
                        end)
                    else
                        _setStatus(("Farming Astral Rod $%d/$%d"):format(
                            coins, _ROD_ASTRAL_COST))
                        _tp(_farmLocations[k.farmLoc] or _farmLocations["Kohana Volcano"])
                    end
                    continue

                -- ── Step 3: Deep Sea Quest (Sisyphus dulu, baru Treasure) ──
                elseif not k.deepDone then
                    local dp = _scanDeepProgress()
                    if dp == "DONE" then
                        k.deepDone = true
                        _setStatus("Deep Sea Quest selesai!")
                        task.wait(0.5)
                    elseif dp == "SISYPHUS" then
                        -- q1 belum done: mancing di Sisyphus Statue
                        _setStatus("Deep Sea: Mancing di Sisyphus Statue...")
                        _tp(CFrame.new(-3699, -135, -890))
                    elseif dp == "TREASURE" then
                        -- q1 done, q2 belum: ke Treasure Room
                        _setStatus("Deep Sea: Menuju Treasure Room...")
                        _tp(CFrame.new(-3599, -276, -1641))
                    else
                        _setStatus("Deep Sea: Menunggu data...")
                    end
                    continue

                -- ── Step 4: Artifact Quest ─────────────────────────────────
                elseif not k.artDone then
                    local allDone = true
                    for _, name in ipairs(_artifactOrder) do
                        if not _artifactIsDone(name) then
                            allDone = false
                            -- Sudah punya artifact di inventory? Langsung pasang
                            if _hasArtifactInInventory(name) then
                                local leverType = _artifactToLeverType(name)
                                _setStatus("Pasang " .. name .. " ke lever...")
                                _tp(_artifactPositions[name])
                                task.wait(1.5)
                                local triggered = _triggerLeverByType(leverType)
                                if not triggered then
                                    task.wait(2); _triggerLeverByType(leverType)
                                end
                                k.pendingArtifact = nil
                                task.wait(1)
                            elseif k.pendingArtifact == name then
                                -- Sedang menunggu ikan dari event
                                _setStatus("Menunggu ikan " .. name .. "...")
                                task.wait(1)
                            else
                                -- Belum punya, pergi mancing
                                k.pendingArtifact = name
                                _setStatus("Mancing untuk " .. name .. "...")
                                _tp(_artifactPositions[name])
                                task.wait(1)
                            end
                            break
                        end
                    end
                    if allDone then
                        k.pendingArtifact = nil
                        k.artDone = true
                        _setStatus("Artifact Quest selesai!")
                        task.wait(0.5)
                    end
                    continue

                -- ── Step 5: Beli Floral Bait ───────────────────────────────
                elseif not k.hasFloral then
                    if coins >= _BAIT_FLORAL_COST then
                        _tryBuy("Floral Bait", function()
                            if NetEvents.RF_PurchaseBait then
                                NetEvents.RF_PurchaseBait:InvokeServer(_BAIT_FLORAL_ID)
                            end
                        end)
                    else
                        _setStatus(("Farming Floral Bait $%d/$%d"):format(
                            coins, _BAIT_FLORAL_COST))
                        _tp(_farmLocations[k.farmLoc] or _farmLocations["Kohana Volcano"])
                    end
                    continue

                -- ── Step 6: Element Quest ──────────────────────────────────
                elseif not k.elemDone then
                    local ep = _scanElemProgress()
                    if ep == "DONE" then
                        k.elemDone = true
                        _setStatus("Element Quest selesai!")
                        task.wait(0.5)
                    elseif ep == "STAGE1" then
                        _setStatus("Element: Stage 1 - Ancient Jungle...")
                        _tp(CFrame.new(1484, 3, -336) * CFrame.Angles(0, math.rad(180), 0))
                    elseif ep == "STAGE2" then
                        _setStatus("Element: Stage 2 - Sacred Temple...")
                        _tp(CFrame.new(1453, -22, -636))
                    elseif ep == "STAGE3" then
                        _setStatus("Element: Stage 3 - Transcended Stones...")
                        _tp(CFrame.new(1480, 128, -593))
                    else
                        _setStatus("Element: Menunggu data...")
                    end
                    continue

                -- ── Step 7a: Trigger Diamond NPC ───────────────────────────
                elseif not k.diamondNpcDone then
                    _setStatus("Menuju Diamond Researcher...")
                    _tp(_DIAMOND_NPC_CF)
                    task.wait(4)
                    local triggered = _triggerDiamondNpc()
                    if triggered then
                        _setStatus("Memilih Diamond Researcher Quest...")
                        task.wait(3)
                        local dp2 = _scanDiamondProgress()
                        if dp2 == "IN_PROGRESS" or dp2 == "DONE" then
                            k.diamondNpcDone = true
                            _setStatus("Quest Diamond Researcher aktif!")
                        else
                            _setStatus("Quest belum aktif, coba lagi...")
                        end
                    else
                        _setStatus("Gagal trigger NPC / dialog tidak muncul!")
                        task.wait(5)
                    end
                    continue

                -- ── Step 7b: Mancing Diamond Rod Quest ────────────────────
                elseif not k.diamondDone then
                    local dp2 = _scanDiamondProgress()
                    if dp2 == "DONE" then
                        k.diamondDone = true
                        _setStatus("Diamond Rod Quest selesai! Rod didapat!")
                        task.wait(1)
                    elseif dp2 == "NEED_NPC" then
                        k.diamondNpcDone = false
                        _setStatus("Quest hilang, kembali ke Diamond Researcher...")
                        task.wait(2)
                    else
                        local locName = _DIAMOND_LOC_ORDER[k.diamondLocIndex]
                            or _DIAMOND_LOC_ORDER[1]
                        _setStatus(("Mancing Diamond Quest: %s"):format(locName))
                        _tp(_DIAMOND_LOCS[locName])
                        task.wait(10)
                        k.diamondLocIndex = (k.diamondLocIndex % #_DIAMOND_LOC_ORDER) + 1
                    end
                    continue

                -- ── Semua selesai: farming coins / handle quest lain ───────
                else
                    local quests    = _getActiveQuests()
                    local anyActive = false
                    for _, q in ipairs(quests) do
                        for _, obj in ipairs(q.objectives) do
                            if not obj.done then
                                anyActive = true
                                local loc = _getQuestLocation(q.name, obj.text)
                                _setStatus(("Quest: %s | %s (%d/%d)"):format(
                                    q.name, obj.text, obj.progress, obj.max))
                                if loc then _tp(loc) end
                                break
                            end
                        end
                        if anyActive then break end
                    end
                    if not anyActive then
                        _setStatus("Semua selesai! Farming coins...")
                        _tp(_farmLocations[k.farmLoc] or _farmLocations["Kohana Volcano"])
                    end
                end
            end
        end

        -- ── UI ────────────────────────────────────────────────────────────────
        local KaitunSection = QuestTab:AddSection("Semi Kaitun [BETA]", false)

        KaitunSection:AddDropdown({
            Title    = "Farming Location",
            Options  = { "Kohana Volcano", "Tropical Grove" },
            Default  = "Kohana Volcano",
            NoSave   = false,
            Callback = function(v) _kaitun.farmLoc = v end,
        })

        KaitunSection:AddToggle({
            Title    = "Start Kaitun",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _kaitun.enabled = on
                if on then
                    _kaitun.panelGui        = _buildPanel()
                    _kaitun.pendingArtifact = nil
                    _kaitun.diamondLocIndex = 1

                    _kaitun.hasMidnight    = _hasRodById(_ROD_MIDNIGHT_ID)
                    _kaitun.hasAstral      = _hasRodById(_ROD_ASTRAL_ID)
                    _kaitun.hasFloral      = _hasBaitById(_BAIT_FLORAL_ID)
                    _kaitun.deepDone       = (_scanDeepProgress() == "DONE")
                    _kaitun.artDone        = (_scanArtProgress() == "DONE")
                    _kaitun.elemDone       = (_scanElemProgress() == "DONE")
                    local _initDp          = _scanDiamondProgress()
                    _kaitun.diamondDone    = (_initDp == "DONE")
                    _kaitun.diamondNpcDone = (_initDp == "IN_PROGRESS" or _initDp == "DONE")

                    _setStatus("Scanning progress game...")
                    _connectFishEvent(_kaitun)

                    _kaitun.sellThread = task.spawn(function()
                        while _kaitun.enabled do
                            task.wait(_kaitun.SELL_INTERVAL)
                            if not _kaitun.enabled then break end
                            if _hasItemsToSell() then
                                pcall(function()
                                    if NetEvents.RF_SellAllItems then
                                        NetEvents.RF_SellAllItems:InvokeServer()
                                    end
                                end)
                                task.wait(2)
                            end
                        end
                    end)

                    _kaitun.mainThread = task.spawn(function()
                        _runKaitun(_kaitun)
                    end)
                else
                    _kaitun.enabled         = false
                    _kaitun.pendingArtifact = nil
                    if _kaitun.fishConn then
                        _kaitun.fishConn:Disconnect(); _kaitun.fishConn = nil
                    end
                    if _kaitun.sellThread then
                        task.cancel(_kaitun.sellThread); _kaitun.sellThread = nil
                    end
                    if _kaitun.mainThread then
                        task.cancel(_kaitun.mainThread); _kaitun.mainThread = nil
                    end
                    if _kaitun.panelGui and _kaitun.panelGui.screen then
                        pcall(function() _kaitun.panelGui.screen:Destroy() end)
                        _kaitun.panelGui = nil
                    end
                    local Lighting = game:GetService("Lighting")
                    local blur = Lighting:FindFirstChildOfClass("BlurEffect")
                    if blur then blur.Enabled = false end
                end
            end,
        })

        KaitunSection:AddToggle({
            Title    = "Hide Kaitun Panel",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                if _kaitun.panelGui and _kaitun.panelGui.screen then
                    local c = _kaitun.panelGui.screen:FindFirstChildWhichIsA("Frame")
                    if c then c.Visible = not on end
                end
            end,
        })
    end

    -- =========================================================================
    -- AUTO EQUIP BEST ROD
    -- =========================================================================
    do
        local _autoRod = { enabled = false, thread = nil }

        local function _isEquipped(uuid)
            if not _data or not uuid then return false end
            local equippedAll = _data:Get({"EquippedItems"}) or {}
            for _, v in pairs(equippedAll) do
                if v == uuid then return true end
            end
            return false
        end

        local function _getBestUUID()
            if not _data then return nil end
            local inv = _data:Get({"Inventory"}) or {}
            local bestPriority, bestUUID = math.huge, nil
            for _, v in ipairs(inv["Fishing Rods"] or {}) do
                if v.UUID then
                    local name = _getRodName(v.Id)
                    if name then
                        for i, kw in ipairs(_rodPriority) do
                            if name:lower():find(kw:lower(), 1, true) then
                                if i < bestPriority then
                                    bestPriority = i; bestUUID = v.UUID
                                end
                                break
                            end
                        end
                    end
                end
            end
            return bestUUID
        end

        local function _equipBest()
            local bestUUID = _getBestUUID()
            if bestUUID and not _isEquipped(bestUUID) then
                _equipRod(bestUUID)
            end
        end

        local RodSection = QuestTab:AddSection("Auto Equip Best Rod", false)
        RodSection:AddToggle({
            Title    = "Auto Equip Best Rod",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _autoRod.enabled = on
                if on then
                    pcall(_equipBest)
                    _autoRod.thread = task.spawn(function()
                        while _autoRod.enabled do
                            task.wait(5)
                            if _autoRod.enabled then pcall(_equipBest) end
                        end
                    end)
                else
                    _autoRod.enabled = false
                    if _autoRod.thread then
                        task.cancel(_autoRod.thread); _autoRod.thread = nil
                    end
                end
            end,
        })
    end

    -- =========================================================================
    -- AUTO EQUIP BEST BAIT
    -- =========================================================================
    do
        local _autoBait      = { enabled = false, thread = nil }
        local _baitPriceCache = {}

        local function _getBaitPrice(name)
            if _baitPriceCache[name] ~= nil then return _baitPriceCache[name] end
            if not _BaitsFolder then return 0 end
            for _, mod in ipairs(_BaitsFolder:GetChildren()) do
                if mod:IsA("ModuleScript") then
                    local ok, d = pcall(require, mod)
                    if ok and d and d.Data and d.Data.Name == name then
                        local price = d.Price or d.Data.Price or 0
                        _baitPriceCache[name] = price
                        return price
                    end
                end
            end
            _baitPriceCache[name] = 0
            return 0
        end

        local function _getBestBaitUUID()
            if not _data then return nil end
            local inv = _data:Get({"Inventory"}) or {}
            local bestPrice, bestUUID = -1, nil
            for _, v in ipairs(inv.Baits or {}) do
                if v.UUID then
                    local name = _getBaitName(v.Id)
                    if name then
                        local price = _getBaitPrice(name)
                        if price > bestPrice then
                            bestPrice = price; bestUUID = v.UUID
                        end
                    end
                end
            end
            return bestUUID
        end

        local function _isBaitEquipped(uuid)
            if not _data or not uuid then return false end
            local equipped = _data:Get({"EquippedItems"}) or {}
            for _, v in ipairs(equipped) do if v == uuid then return true end end
            for _, v in pairs(equipped) do if v == uuid then return true end end
            return false
        end

        local function _equipBestBait()
            if not _data then return end
            local inv = _data:Get({"Inventory"}) or {}
            local bestPrice, bestId = -1, nil
            for _, v in ipairs(inv.Baits or {}) do
                local name = _getBaitName(v.Id)
                if name then
                    local price = _getBaitPrice(name)
                    if price > bestPrice then bestPrice = price; bestId = v.Id end
                end
            end
            if not bestId then return end
            local equippedBait = _data:Get({"EquippedItems", "Bait"})
                or _data:Get({"EquippedBait"})
            if equippedBait == bestId then return end
            pcall(function() NetEvents.RE_EquipBait:FireServer(bestId) end)
        end

        local BaitSection = QuestTab:AddSection("Auto Equip Best Bait", false)
        BaitSection:AddToggle({
            Title    = "Auto Equip Best Bait",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _autoBait.enabled = on
                if on then
                    pcall(_equipBestBait)
                    _autoBait.thread = task.spawn(function()
                        while _autoBait.enabled do
                            task.wait(5)
                            if _autoBait.enabled then pcall(_equipBestBait) end
                        end
                    end)
                else
                    _autoBait.enabled = false
                    if _autoBait.thread then
                        task.cancel(_autoBait.thread); _autoBait.thread = nil
                    end
                end
            end,
        })
        BaitSection:AddButton({
            Title    = "Debug: Force Equip Best Bait",
            Callback = function()
                local bestUUID = _getBestBaitUUID()
                print("Best UUID:", bestUUID)
                print("Is equipped:", _isBaitEquipped(bestUUID))
                print("Firing RE_EquipItem...")
                pcall(function() NetEvents.RE_EquipItem:FireServer(bestUUID, "Baits") end)
                print("Done")
            end,
        })
    end

    -- =========================================================================
    -- ARTIFACT LEVER (standalone)
    -- =========================================================================
    do
        local _art = { enabled = false, pendingLeverType = nil, thread = nil, fishConn = nil }

        local ArtSection  = QuestTab:AddSection("Artifact Lever", false)
        local _artParaRef = ArtSection:AddParagraph({
            Title = "Artifact Status", Content = "Belum di-scan",
        })

        task.spawn(function()
            while task.wait(1) do
                pcall(function()
                    if _artParaRef and _artParaRef.SetContent then
                        _artParaRef:SetContent(_artifactStatusText())
                    end
                end)
            end
        end)

        ArtSection:AddToggle({
            Title    = "Auto Artifact Progress",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _art.enabled = on
                if on then
                    if _art.fishConn then _art.fishConn:Disconnect(); _art.fishConn = nil end
                    local fishEvent = NetEvents.RE_FishCaught
                    if fishEvent then
                        _art.fishConn = fishEvent.OnClientEvent:Connect(function(fishData)
                            if not _art.enabled or not _art.pendingLeverType then return end
                            local fishName = _parseFishName(fishData)
                            local keyword  = string.split(_art.pendingLeverType, " ")[1]
                            if tostring(fishName):find(keyword, 1, true) then
                                task.wait(0)
                                _triggerLeverByType(_art.pendingLeverType)
                                _art.pendingLeverType = nil
                            end
                        end)
                    end

                    _art.thread = task.spawn(function()
                        while _art.enabled do
                            local allDone = true
                            for _, name in ipairs(_artifactOrder) do
                                if not _artifactIsDone(name) then
                                    allDone = false
                                    local leverType = _artifactToLeverType(name)
                                    if _hasArtifactInInventory(name) then
                                        local char = LocalPlayer.Character
                                            or LocalPlayer.CharacterAdded:Wait()
                                        local root = char:FindFirstChild("HumanoidRootPart")
                                        if root then root.CFrame = _artifactPositions[name] end
                                        task.wait(1.5)
                                        local triggered = _triggerLeverByType(leverType)
                                        if not triggered then
                                            task.wait(2); _triggerLeverByType(leverType)
                                        end
                                        _art.pendingLeverType = nil
                                        task.wait(1)
                                        break
                                    end
                                    if _art.pendingLeverType == leverType then
                                        task.wait(1); break
                                    end
                                    _art.pendingLeverType = leverType
                                    local char = LocalPlayer.Character
                                        or LocalPlayer.CharacterAdded:Wait()
                                    local root = char:FindFirstChild("HumanoidRootPart")
                                    if root then root.CFrame = _artifactPositions[name] end
                                    local deadline = tick() + 60
                                    repeat
                                        if _hasArtifactInInventory(name) then
                                            task.wait(0)
                                            _triggerLeverByType(leverType)
                                            _art.pendingLeverType = nil
                                            break
                                        end
                                        task.wait(1)
                                    until not _art.pendingLeverType
                                        or _artifactIsDone(name)
                                        or not _art.enabled
                                        or tick() > deadline
                                    _art.pendingLeverType = nil
                                    break
                                end
                            end
                            if allDone then
                                _art.enabled = false
                                Library:MakeNotify({
                                    Title       = "Artifact",
                                    Description = "Semua artifact selesai!",
                                    Delay       = 3,
                                })
                                break
                            end
                            task.wait(1)
                        end
                        if _art.fishConn then
                            _art.fishConn:Disconnect(); _art.fishConn = nil
                        end
                    end)
                else
                    _art.pendingLeverType = nil
                    if _art.fishConn then _art.fishConn:Disconnect(); _art.fishConn = nil end
                    if _art.thread then task.cancel(_art.thread); _art.thread = nil end
                end
            end,
        })

        ArtSection:AddButton({ Title = "TP: Arrow Artifact",
            Callback = function() _tp(_artifactPositions["Arrow Artifact"]) end })
        ArtSection:AddButton({ Title = "TP: Crescent Artifact",
            Callback = function() _tp(_artifactPositions["Crescent Artifact"]) end })
        ArtSection:AddButton({ Title = "TP: Hourglass Diamond Artifact",
            Callback = function() _tp(_artifactPositions["Hourglass Diamond Artifact"]) end })
        ArtSection:AddButton({ Title = "TP: Diamond Artifact",
            Callback = function() _tp(_artifactPositions["Diamond Artifact"]) end })
    end

    -- =========================================================================
    -- DEEP SEA QUEST (standalone)
    -- =========================================================================
    do
        local _deep = { enabled = false, thread = nil }
        local DeepSection  = QuestTab:AddSection("Deep Sea Quest", false)
        local _deepParaRef = DeepSection:AddParagraph({
            Title = "Deep Sea Tracker", Content = "Belum di-scan",
        })
        task.spawn(function()
            while task.wait(2) do
                pcall(function()
                    if not (_deepParaRef and _deepParaRef.SetContent) then return end
                    if not _data then _deepParaRef:SetContent("Menunggu data..."); return end
                    local ok, ds = pcall(function()
                        return _data:Get({"DeepSea", "Available", "Forever"})
                    end)
                    if not ok or not ds then
                        _deepParaRef:SetContent("Data DeepSea belum tersedia"); return
                    end
                    if ds.CompletedAllQuests then
                        _deepParaRef:SetContent("Deep Sea Quest SELESAI"); return
                    end
                    local lines  = {}
                    local quests = ds.Quests or {}
                    for i, q in ipairs(quests) do
                        if q then
                            local done = q.Progress ~= nil and q.Progress <= 0
                            table.insert(lines, ("%d. %s [%s]"):format(
                                i,
                                q.QuestId or ("Quest " .. i),
                                done and "DONE" or ("remaining: " .. (q.Progress or "?"))))
                        end
                    end
                    _deepParaRef:SetContent(
                        #lines > 0 and table.concat(lines, "\n") or "Belum ada quest data")
                end)
            end
        end)
        DeepSection:AddToggle({
            Title    = "Auto Deep Sea Quest",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _deep.enabled = on
                if on then
                    _deep.thread = task.spawn(function()
                        while _deep.enabled do
                            local stage = "SISYPHUS"
                            pcall(function()
                                if not _data then return end
                                local ok, ds = pcall(function()
                                    return _data:Get({"DeepSea", "Available", "Forever"})
                                end)
                                if not ok or not ds then return end
                                if ds.CompletedAllQuests then stage = "DONE"; return end
                                local quests = ds.Quests or {}
                                local q1 = quests[1]
                                local q1done = q1 and q1.Progress ~= nil and q1.Progress <= 0
                                stage = q1done and "TREASURE" or "SISYPHUS"
                            end)

                            local root = LocalPlayer.Character
                                and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if root then
                                if stage == "DONE" then
                                    _deep.enabled = false
                                    Library:MakeNotify({
                                        Title       = "Deep Sea Quest",
                                        Description = "Deep Sea Quest selesai!",
                                        Delay       = 3,
                                    })
                                    break
                                elseif stage == "TREASURE" then
                                    root.CFrame = CFrame.new(-3599, -276, -1641)
                                else
                                    -- SISYPHUS
                                    root.CFrame = CFrame.new(-3763, -135, -995)
                                        * CFrame.Angles(0, math.rad(180), 0)
                                end
                            end
                            task.wait(1.5)
                        end
                    end)
                else
                    if _deep.thread then task.cancel(_deep.thread); _deep.thread = nil end
                end
            end,
        })
        DeepSection:AddButton({
            Title    = "TP: Sisyphus Statue",
            Callback = function() _tp(CFrame.new(-3698, -135, -1008)) end,
        })
        DeepSection:AddButton({
            Title    = "TP: Treasure Room",
            Callback = function() _tp(CFrame.new(-3601, -283, -1611)) end,
        })
    end

    -- =========================================================================
    -- ELEMENT QUEST (standalone)
    -- =========================================================================
    do
        local _elem = { enabled = false, thread = nil }
        local ElemSection  = QuestTab:AddSection("Element Quest", false)
        local _elemParaRef = ElemSection:AddParagraph({
            Title = "Element Tracker", Content = "Belum di-scan",
        })
        task.spawn(function()
            while task.wait(2) do
                pcall(function()
                    if not (_elemParaRef and _elemParaRef.SetContent) then return end
                    if not _data then _elemParaRef:SetContent("Menunggu data..."); return end
                    local ok, ej = pcall(function()
                        return _data:Get({"ElementJungle", "Available", "Forever"})
                    end)
                    if not ok or not ej then
                        _elemParaRef:SetContent("Data ElementJungle belum tersedia"); return
                    end
                    if ej.CompletedAllQuests then
                        _elemParaRef:SetContent("Element Quest SELESAI"); return
                    end
                    local quests = ej.Quests or {}
                    local function _qs(q, label)
                        if not q then return label .. " : -" end
                        local done = q.Progress ~= nil and q.Progress <= 0
                        local rem  = (not done and q.Progress)
                            and (" (%d remaining)"):format(q.Progress) or ""
                        return ("%s : %s%s"):format(label,
                            done and "[DONE]" or "[PENDING]", rem)
                    end
                    _elemParaRef:SetContent(table.concat({
                        _qs(quests[1], "Stage 1 - Ancient Jungle"),
                        _qs(quests[2], "Stage 2 - Sacred Temple"),
                        _qs(quests[3], "Stage 3 - Transcended Stones"),
                    }, "\n"))
                end)
            end
        end)
        ElemSection:AddToggle({
            Title    = "Auto Element Quest",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _elem.enabled = on
                if on then
                    _elem.thread = task.spawn(function()
                        while _elem.enabled do
                            local stage = "STAGE1"
                            pcall(function()
                                if not _data then return end
                                local ok, ej = pcall(function()
                                    return _data:Get({"ElementJungle", "Available", "Forever"})
                                end)
                                if not ok or not ej then return end
                                if ej.CompletedAllQuests then stage = "DONE"; return end
                                local quests = ej.Quests or {}
                                local q1 = quests[1]; local q2 = quests[2]; local q3 = quests[3]
                                local q1d = q1 and q1.Progress ~= nil and q1.Progress <= 0
                                local q2d = q2 and q2.Progress ~= nil and q2.Progress <= 0
                                local q3d = q3 and q3.Progress ~= nil and q3.Progress <= 0
                                if q1d and q2d and q3d then stage = "DONE"
                                elseif q1d and q2d then stage = "STAGE3"
                                elseif q1d then stage = "STAGE2"
                                else stage = "STAGE1" end
                            end)
                            local root = LocalPlayer.Character
                                and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if root then
                                if stage == "DONE" then
                                    _elem.enabled = false
                                    Library:MakeNotify({
                                        Title       = "Element Quest",
                                        Description = "Element Quest selesai!",
                                        Delay       = 3,
                                    })
                                    break
                                elseif stage == "STAGE1" then
                                    root.CFrame = CFrame.new(1484, 3, -336)
                                        * CFrame.Angles(0, math.rad(180), 0)
                                elseif stage == "STAGE2" then
                                    root.CFrame = CFrame.new(1453, -22, -636)
                                elseif stage == "STAGE3" then
                                    root.CFrame = CFrame.new(1480, 128, -593)
                                end
                            end
                            task.wait(2)
                        end
                    end)
                else
                    if _elem.thread then task.cancel(_elem.thread); _elem.thread = nil end
                end
            end,
        })
        ElemSection:AddButton({
            Title    = "TP: Ancient Jungle (Stage 1)",
            Callback = function()
                _tp(CFrame.new(1484, 3, -336) * CFrame.Angles(0, math.rad(180), 0))
            end,
        })
        ElemSection:AddButton({
            Title    = "TP: Sacred Temple (Stage 2)",
            Callback = function() _tp(CFrame.new(1453, -22, -636)) end,
        })
        ElemSection:AddButton({
            Title    = "TP: Transcended Stones (Stage Final)",
            Callback = function() _tp(CFrame.new(1480, 128, -593)) end,
        })
        ElemSection:AddButton({
            Title    = "TP: Underground Cellar",
            Callback = function() _tp(CFrame.new(2136, -91, -701)) end,
        })
    end

    -- =========================================================================
    -- AUTO ANCIENT RUIN
    -- =========================================================================
    do
        local _ruin        = { enabled = false, thread = nil }
        local _CollService = game:GetService("CollectionService")

        local function _getPlates()
            local result = {}
            for _, part in ipairs(_CollService:GetTagged("PressurePlate")) do
                local plateModel = part.Parent
                local t = plateModel and plateModel:GetAttribute("Type")
                if t then result[t] = part end
            end
            return result
        end

        local function _getPlateStatus()
            if not _data then return {} end
            local ok, rpp = pcall(function()
                return _data:GetExpect({"RuinPressurePlates"})
            end)
            if not ok or not rpp then
                ok, rpp = pcall(function() return _data:Get({"RuinPressurePlates"}) end)
            end
            return (ok and rpp) or {}
        end

        local function _allDone(status)
            for _, tier in ipairs(_ruinTiers) do
                if not status[tier] then return false end
            end
            return true
        end

        local RuinSection  = QuestTab:AddSection("Auto Ancient Ruin", false)
        local _ruinParaRef = RuinSection:AddParagraph({
            Title = "Ancient Ruin Status", Content = "Checking...",
        })

        task.spawn(function()
            while task.wait(1) do
                pcall(function()
                    if not (_ruinParaRef and _ruinParaRef.SetContent) then return end
                    local status = _getPlateStatus()
                    if not next(status) and not _data then
                        _ruinParaRef:SetContent("Menunggu data sync..."); return
                    end
                    if _allDone(status) then
                        _ruinParaRef:SetContent("Semua plate selesai!"); return
                    end
                    local lines = {}
                    for _, tier in ipairs(_ruinTiers) do
                        local done = status[tier] == true
                        table.insert(lines, ("%s: %s"):format(
                            tier, done and "[DONE]" or "[PENDING]"))
                    end
                    _ruinParaRef:SetContent(table.concat(lines, "\n"))
                end)
            end
        end)

        RuinSection:AddToggle({
            Title    = "Auto Ancient Ruin",
            Default  = false,
            NoSave   = true,
            Callback = function(on)
                _ruin.enabled = on
                if on then
                    _ruin.thread = task.spawn(function()
                        while _ruin.enabled do
                            pcall(function()
                                if not _data then return end
                                local status = _getPlateStatus()
                                if _allDone(status) then
                                    _ruin.enabled = false
                                    Library:MakeNotify({
                                        Title       = "Ancient Ruin",
                                        Description = "Semua pressure plate selesai!",
                                        Delay       = 3,
                                    })
                                    return
                                end
                                local inv    = (_data:Get({"Inventory"}) or {}).Items or {}
                                local plates = _getPlates()
                                for _, tier in ipairs(_ruinTiers) do
                                    if status[tier] then continue end
                                    local targetId = _fishTargetIds[tier]
                                    local hasIt    = false
                                    for _, v in ipairs(inv) do
                                        if v.Id == targetId then hasIt = true; break end
                                    end
                                    if hasIt then
                                        local part = plates[tier]
                                        if part then
                                            local root = LocalPlayer.Character
                                                and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                            if root then
                                                root.CFrame = CFrame.new(
                                                    part.Position + Vector3.new(0, 3, 0))
                                                task.wait(0.5)
                                            end
                                        end
                                        local remote = NetEvents.RE_PlacePressureItem
                                        if remote then
                                            pcall(function() remote:FireServer(tier) end)
                                            task.wait(0.5)
                                        end
                                    end
                                end
                            end)
                            task.wait(1.5)
                        end
                    end)
                else
                    if _ruin.thread then task.cancel(_ruin.thread); _ruin.thread = nil end
                end
            end,
        })
    end
end

do
    local SettingsTab = MainWindow:AddTab({ Name = "Settings", Icon = "settings" })

    local ProtectionSection = SettingsTab:AddSection("Protection")
    local _stayActive       = { enabled = false, conns = {}, task = nil }
    local _antiStaff        = { enabled = false, task = nil }

    local GROUP_ID    = 35102746
    local STAFF_RANKS = {
        [2]=true,[3]=true,[4]=true,[30]=true,[35]=true,[55]=true,
        [75]=true,[76]=true,[79]=true,[100]=true,[145]=true,
        [250]=true,[252]=true,[254]=true,[255]=true,
    }

    ProtectionSection:AddToggle({
        Title    = "Stay Active",
        Default  = true,
        Callback = function(on)
            if on then
                if _stayActive.enabled then return end
                _stayActive.enabled = true
                local didDisable = false
                if getconnections and type(getconnections) == "function" then
                    pcall(function()
                        for _, c in ipairs(getconnections(LocalPlayer.Idled)) do
                            if c then
                                if c.Disable then pcall(c.Disable, c) end
                                if c.DisableConnection then pcall(c.DisableConnection, c) end
                                table.insert(_stayActive.conns, c)
                                didDisable = true
                            end
                        end
                    end)
                end
                if not didDisable then
                    local VirtualUser = game:GetService("VirtualUser")
                    _stayActive.task = task.spawn(function()
                        while _stayActive.enabled do
                            task.wait(math.random() * 50 + 40)
                            if not _stayActive.enabled then break end
                            pcall(function()
                                VirtualUser:CaptureController()
                                VirtualUser:ClickButton2(Vector2.new(), workspace.CurrentCamera.CFrame)
                            end)
                        end
                    end)
                end
            else
                _stayActive.enabled = false
                if _stayActive.task then
                    task.cancel(_stayActive.task)
                    _stayActive.task = nil
                end
                pcall(function()
                    for _, c in ipairs(_stayActive.conns) do
                        if c then
                            if c.Enable then pcall(c.Enable, c) end
                            if c.EnableConnection then pcall(c.EnableConnection, c) end
                        end
                    end
                    _stayActive.conns = {}
                end)
            end
        end,
    })

    ProtectionSection:AddToggle({
        Title    = "Anti Staff (Auto Kick)",
        Default  = false,
        Callback = function(on)
            _antiStaff.enabled = on
            if on then
                if _antiStaff.task then return end
                _antiStaff.task = task.spawn(function()
                    while _antiStaff.enabled do
                        for _, player in ipairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer then
                                local rank = player:GetRankInGroup(GROUP_ID)
                                if STAFF_RANKS[rank] then
                                    LocalPlayer:Kick("Staff Detected! Auto Kicked for Safety.")
                                    return
                                end
                            end
                        end
                        task.wait(1)
                    end
                end)
            else
                if _antiStaff.task then
                    task.cancel(_antiStaff.task)
                    _antiStaff.task = nil
                end
            end
        end,
    })

    local PlayerSection = SettingsTab:AddSection("Player Features")
    local _sprint       = { enabled = false, conn = nil, walkSpeed = 16, sprintSpeed = 32 }
    local _infJump      = { enabled = false, conn = nil }

    local function getHumanoid()
        local char = LocalPlayer.Character
        return char and char:FindFirstChildOfClass("Humanoid")
    end

    PlayerSection:AddToggle({
        Title    = "Sprint (Hold Shift)",
        Default  = false,
        Callback = function(on)
            _sprint.enabled = on
            if on then
                if _sprint.conn then return end
                _sprint.conn = game:GetService("RunService").Heartbeat:Connect(function()
                    if not _sprint.enabled then return end
                    local hum = getHumanoid()
                    if not hum then return end
                    hum.WalkSpeed = game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift)
                        and _sprint.sprintSpeed or _sprint.walkSpeed
                end)
                LocalPlayer.CharacterAdded:Connect(function()
                    task.wait(0.5)
                    local hum = getHumanoid()
                    if hum and _sprint.enabled then hum.WalkSpeed = _sprint.walkSpeed end
                end)
            else
                if _sprint.conn then _sprint.conn:Disconnect(); _sprint.conn = nil end
                local hum = getHumanoid()
                if hum then hum.WalkSpeed = _sprint.walkSpeed end
            end
        end,
    })

    PlayerSection:AddInput({
        Title    = "Sprint Speed",
        Default  = "32",
        Callback = function(value)
            local n = tonumber(value)
            if n then _sprint.sprintSpeed = n end
        end,
    })

    PlayerSection:AddInput({
        Title    = "Walk Speed",
        Default  = "16",
        Callback = function(value)
            local n = tonumber(value)
            if n then _sprint.walkSpeed = n end
        end,
    })

    PlayerSection:AddToggle({
        Title    = "Infinite Jump",
        Default  = false,
        Callback = function(on)
            _infJump.enabled = on
            if on then
                if _infJump.conn then return end
                _infJump.conn = game:GetService("UserInputService").JumpRequest:Connect(function()
                    if not _infJump.enabled then return end
                    local char = LocalPlayer.Character
                    local hum  = char and char:FindFirstChildOfClass("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end)
            else
                if _infJump.conn then _infJump.conn:Disconnect(); _infJump.conn = nil end
            end
        end,
    })

    local HideStatsSection = SettingsTab:AddSection("Hide Stats")
    local _hideStats = {
        enabled         = false,
        showScriptLabel = true,
        premiumLogo     = false,
        verifyLogo      = false,
        fakeName        = "LynX",
        fakeLevel       = "501",
        scriptName      = "discord.gg/lynxx",
        origTexts       = {},
        origPLName      = nil,
        updateLoop      = false,
        plConn          = nil,
    }

    local PREMIUM_CHAR  = ""
    local VERIFY_CHAR   = ""

    local function _getBuiltName()
        local name = _hideStats.fakeName
        if _hideStats.premiumLogo then name = name .. PREMIUM_CHAR end
        if _hideStats.verifyLogo  then name = name .. VERIFY_CHAR  end
        return name
    end

    local function _getOverhead()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        return hrp and hrp:FindFirstChild("Overhead")
    end

    local function _removeScriptLabel()
        local overhead = _getOverhead()
        if not overhead then return end
        local lynxFrame = overhead:FindFirstChild("LynxFrame")
        if not lynxFrame then return end
        local nameLabel = overhead:FindFirstChild("Header", true)
        if nameLabel then
            local nameFrame = nameLabel.Parent
            if nameFrame and nameFrame:IsA("Frame") then
                local p = nameFrame.Position
                nameFrame.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale - 0.25, p.Y.Offset)
            end
        end
        lynxFrame:Destroy()
    end

    local function _createScriptLabel(nameLabel, overhead)
        if not nameLabel or not overhead then return end
        if overhead:FindFirstChild("LynxFrame") then return end
        local nameFrame = nameLabel.Parent
        if not nameFrame or not nameFrame:IsA("Frame") then return end
        local origPos = nameFrame.Position
        nameFrame.Position = UDim2.new(origPos.X.Scale, origPos.X.Offset, origPos.Y.Scale + 0.25, origPos.Y.Offset)
        local lynxFrame                  = Instance.new("Frame")
        lynxFrame.Name                   = "LynxFrame"
        lynxFrame.Size                   = nameFrame.Size
        lynxFrame.Position               = origPos
        lynxFrame.BackgroundTransparency = 1
        lynxFrame.Parent                 = overhead
        local lbl                        = nameLabel:Clone()
        lbl.Name                         = "LynxLabel"
        lbl.Text                         = _hideStats.scriptName
        lbl.TextScaled                   = true
        lbl.Font                         = Enum.Font.GothamBold
        lbl.TextStrokeTransparency       = 0.5
        lbl.TextStrokeColor3             = Color3.fromRGB(0, 0, 0)
        lbl.TextColor3                   = Color3.fromRGB(255, 140, 0)
        lbl.Parent                       = lynxFrame
    end

    local function _updateStats()
        if not _hideStats.enabled then _removeScriptLabel(); return end
        local overhead = _getOverhead()
        if not overhead or not overhead:IsA("BillboardGui") then return end

        local existingFrame = overhead:FindFirstChild("LynxFrame")
        if _hideStats.showScriptLabel and not existingFrame then
        elseif not _hideStats.showScriptLabel and existingFrame then
            _removeScriptLabel()
        end

        for _, obj in pairs(overhead:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local path = obj:GetFullName()
                if not _hideStats.origTexts[path] then
                    _hideStats.origTexts[path] = obj.Text
                end
                local orig = _hideStats.origTexts[path]
                if orig and orig ~= "" then
                    if obj.Name == "Header" then
                        if _hideStats.showScriptLabel then
                            _createScriptLabel(obj, overhead)
                        end
                        obj.Text = _getBuiltName()
                    elseif string.find(string.lower(orig), "lvl") then
                        obj.Text = string.gsub(orig, "%d+", _hideStats.fakeLevel)
                    end
                end
            end
        end
    end

    local function _getPlayerListLabel()
        local userId = tostring(LocalPlayer.UserId)
        local ok, result = pcall(function()
            local coreGui    = game:GetService("CoreGui")
            local playerList = coreGui:FindFirstChild("PlayerList", true)
            if not playerList then return nil end
            for _, obj in pairs(playerList:GetDescendants()) do
                if obj:IsA("TextLabel") and obj.Name == "PlayerName" then
                    if string.find(obj:GetFullName(), userId) then
                        return obj
                    end
                end
            end
            return nil
        end)
        return ok and result or nil
    end

    local function _applyPlayerListName()
        if not _hideStats.enabled then return end
        local lbl = _getPlayerListLabel()
        if not lbl then return end
        if not _hideStats.origPLName then
            _hideStats.origPLName = lbl.Text
        end
        lbl.Text = _getBuiltName()
    end

    local function _restorePlayerListName()
        local lbl = _getPlayerListLabel()
        if lbl and _hideStats.origPLName then
            lbl.Text = _hideStats.origPLName
        end
        _hideStats.origPLName = nil
    end

    local function _startPlayerListLoop()
        if _hideStats.plConn then return end
        _hideStats.plConn = game:GetService("RunService").Heartbeat:Connect(function()
            if not _hideStats.enabled then return end
            pcall(_applyPlayerListName)
        end)
    end

    local function _stopPlayerListLoop()
        if _hideStats.plConn then
            _hideStats.plConn:Disconnect()
            _hideStats.plConn = nil
        end
    end

    HideStatsSection:AddToggle({
        Title    = "Enable Hide Stats",
        Default  = false,
        Callback = function(on)
            _hideStats.enabled = on
            if on then
                if not _hideStats.updateLoop then
                    _hideStats.updateLoop = true
                    task.spawn(function()
                        while _hideStats.updateLoop do
                            task.wait(0.2)
                            if _hideStats.enabled then _updateStats() end
                        end
                    end)
                end
                _updateStats()
                _startPlayerListLoop()
            else
                _hideStats.updateLoop = false
                for path, origText in pairs(_hideStats.origTexts) do
                    local obj = game
                    for part in string.gmatch(path, "[^.]+") do
                        obj = obj:FindFirstChild(part)
                        if not obj then break end
                    end
                    if obj and obj:IsA("TextLabel") then obj.Text = origText end
                end
                _removeScriptLabel()
                _stopPlayerListLoop()
                _restorePlayerListName()
            end
        end,
    })

    HideStatsSection:AddToggle({
        Title    = "Show Script Title",
        Default  = true,
        Callback = function(on)
            _hideStats.showScriptLabel = on
            if _hideStats.enabled then
                if not on then
                    _removeScriptLabel()
                end
                _updateStats()
            end
        end,
    })

    HideStatsSection:AddToggle({
        Title    = "Enable Premium Logo",
        Default  = false,
        Callback = function(on)
            _hideStats.premiumLogo = on
            if _hideStats.enabled then
                _updateStats()
                pcall(_applyPlayerListName)
            end
        end,
    })

    HideStatsSection:AddToggle({
        Title    = "Enable Verification Logo",
        Default  = false,
        Callback = function(on)
            _hideStats.verifyLogo = on
            if _hideStats.enabled then
                _updateStats()
                pcall(_applyPlayerListName)
            end
        end,
    })

    HideStatsSection:AddInput({
        Title    = "Fake Name",
        Default  = "Guest",
        Callback = function(value)
            _hideStats.fakeName = value or "Guest"
            if _hideStats.enabled then
                _updateStats()
                pcall(_applyPlayerListName)
            end
        end,
    })

    HideStatsSection:AddInput({
        Title    = "Fake Level",
        Default  = "1",
        Callback = function(value)
            _hideStats.fakeLevel = tostring(value or "1")
            if _hideStats.enabled then _updateStats() end
        end,
    })

    LocalPlayer.CharacterAdded:Connect(function()
        _hideStats.origTexts = {}
        task.wait(1)
        if _hideStats.enabled then _updateStats() end
    end)

    local ServerSection = SettingsTab:AddSection("Server")

    ServerSection:AddButton({
        Title    = "Rejoin Server",
        Callback = function()
            pcall(function()
                game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
            end)
        end,
    })

    local ReconnectSection = SettingsTab:AddSection("Auto Reconnect")
    local _reconnect       = { enabled = false, setup = false, fired = false }

    ReconnectSection:AddParagraph({
        Title   = "Info",
        Content = "Otomatis rejoin server saat disconnect.\nBekerja dengan deteksi ErrorPrompt dari Roblox.",
    })

    ReconnectSection:AddToggle({
        Title    = "Enable Auto Reconnect",
        Default  = false,
        Callback = function(on)
            _reconnect.enabled = on
            if on then
                if not _reconnect.setup then
                    _reconnect.setup = true
                    local function handleReconnect(reason)
                        if not _reconnect.enabled or _reconnect.fired then return end
                        _reconnect.fired = true
                        task.wait(2)
                        pcall(function()
                            game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                        end)
                    end
                    pcall(function()
                        game:GetService("GuiService").ErrorMessageChanged:Connect(function(msg)
                            if msg and msg ~= "" then handleReconnect(msg) end
                        end)
                    end)
                    pcall(function()
                        local overlay = game:GetService("CoreGui")
                            :FindFirstChild("RobloxPromptGui")
                            and game:GetService("CoreGui").RobloxPromptGui:FindFirstChild("promptOverlay")
                        if overlay then
                            overlay.ChildAdded:Connect(function(child)
                                if child.Name == "ErrorPrompt" then
                                    task.wait(0.5)
                                    local lbl = child:FindFirstChildWhichIsA("TextLabel", true)
                                    handleReconnect(lbl and lbl.Text or "Disconnected")
                                end
                            end)
                        end
                    end)
                end
                Library:MakeNotify({
                    Title       = "Auto Reconnect",
                    Description = "Aktif — akan rejoin otomatis saat disconnect.",
                    Delay       = 2,
                })
            else
                Library:MakeNotify({
                    Title       = "Auto Reconnect",
                    Description = "Dimatikan.",
                    Delay       = 2,
                })
            end
        end,
    })

    ReconnectSection:AddButton({
        Title    = "Force Reconnect",
        Callback = function()
            pcall(function()
                game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
            end)
        end,
    })

    local PerformanceSection = SettingsTab:AddSection("Performance")
    local _fpsBooster        = {
        enabled    = false,
        origStates = { reflectance = {}, transparency = {}, material = {}, surfaces = {}, lighting = {}, effects = {}, water = {}, decalTextures = {} },
        newObjConn = nil,
    }
    local _disableRender = { enabled = false, conn = nil }
    local _unlockFPS     = { enabled = false, cap = 60 }

    local Terrain    = workspace:FindFirstChildOfClass("Terrain")
    local RunService = game:GetService("RunService")
    local Lighting   = game:GetService("Lighting")

    local function _optimizeObj(obj)
        if not _fpsBooster.enabled then return end
        pcall(function()
            if obj:IsA("BasePart") then
                if not _fpsBooster.origStates.reflectance[obj] then
                    _fpsBooster.origStates.reflectance[obj] = obj.Reflectance
                    _fpsBooster.origStates.material[obj]    = obj.Material
                    _fpsBooster.origStates.surfaces[obj]    = {
                        BackSurface   = obj.BackSurface,   BottomSurface = obj.BottomSurface,
                        FrontSurface  = obj.FrontSurface,  LeftSurface   = obj.LeftSurface,
                        RightSurface  = obj.RightSurface,  TopSurface    = obj.TopSurface,
                    }
                end
                obj.Reflectance   = 0
                obj.CastShadow    = false
                obj.Material      = Enum.Material.Plastic
                obj.BackSurface   = Enum.SurfaceType.SmoothNoOutlines
                obj.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
                obj.FrontSurface  = Enum.SurfaceType.SmoothNoOutlines
                obj.LeftSurface   = Enum.SurfaceType.SmoothNoOutlines
                obj.RightSurface  = Enum.SurfaceType.SmoothNoOutlines
                obj.TopSurface    = Enum.SurfaceType.SmoothNoOutlines
            end
            if obj:IsA("Decal") then
                if not _fpsBooster.origStates.transparency[obj] then
                    _fpsBooster.origStates.transparency[obj]  = obj.Transparency
                    _fpsBooster.origStates.decalTextures[obj] = obj.Texture
                end
                obj.Transparency = 1
                obj.Texture      = ""
            end
            if obj:IsA("Texture") then
                if not _fpsBooster.origStates.transparency[obj] then
                    _fpsBooster.origStates.transparency[obj] = obj.Transparency
                end
                obj.Transparency = 1
            end
            if obj:IsA("SurfaceAppearance") then obj:Destroy() end
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj.Enabled = false end
            if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("ForceField") then
                RunService.Heartbeat:Wait()
                pcall(function() obj:Destroy() end)
            end
        end)
    end

    local function _restoreObj(obj)
        pcall(function()
            if obj:IsA("BasePart") then
                if _fpsBooster.origStates.reflectance[obj] then
                    obj.Reflectance = _fpsBooster.origStates.reflectance[obj]
                    obj.CastShadow  = true
                end
                if _fpsBooster.origStates.material[obj] then
                    obj.Material = _fpsBooster.origStates.material[obj]
                end
                if _fpsBooster.origStates.surfaces[obj] then
                    local s = _fpsBooster.origStates.surfaces[obj]
                    obj.BackSurface   = s.BackSurface;   obj.BottomSurface = s.BottomSurface
                    obj.FrontSurface  = s.FrontSurface;  obj.LeftSurface   = s.LeftSurface
                    obj.RightSurface  = s.RightSurface;  obj.TopSurface    = s.TopSurface
                end
            end
            if obj:IsA("Decal") then
                if _fpsBooster.origStates.transparency[obj]  then obj.Transparency = _fpsBooster.origStates.transparency[obj]  end
                if _fpsBooster.origStates.decalTextures[obj] then obj.Texture       = _fpsBooster.origStates.decalTextures[obj] end
            end
            if obj:IsA("Texture") then
                if _fpsBooster.origStates.transparency[obj] then obj.Transparency = _fpsBooster.origStates.transparency[obj] end
            end
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj.Enabled = true end
        end)
    end

    PerformanceSection:AddToggle({
        Title    = "FPS Booster",
        Default  = false,
        Callback = function(on)
            _fpsBooster.enabled = on
            if on then
                task.spawn(function()
                    local descendants = game:GetDescendants()
                    for i = 1, #descendants, 50 do
                        for j = i, math.min(i + 49, #descendants) do
                            _optimizeObj(descendants[j])
                        end
                        task.wait()
                    end
                end)
                if Terrain then
                    pcall(function()
                        _fpsBooster.origStates.water = {
                            WaterReflectance  = Terrain.WaterReflectance,
                            WaterWaveSize     = Terrain.WaterWaveSize,
                            WaterWaveSpeed    = Terrain.WaterWaveSpeed,
                            WaterTransparency = Terrain.WaterTransparency,
                        }
                        Terrain.WaterWaveSize     = 0
                        Terrain.WaterWaveSpeed    = 0
                        Terrain.WaterReflectance  = 0
                        Terrain.WaterTransparency = 1
                    end)
                end
                pcall(function()
                    _fpsBooster.origStates.lighting = {
                        GlobalShadows = Lighting.GlobalShadows,
                        FogEnd        = Lighting.FogEnd,
                        FogStart      = Lighting.FogStart,
                    }
                    Lighting.GlobalShadows = false
                    Lighting.FogStart      = 9e9
                    Lighting.FogEnd        = 9e9
                end)
                pcall(function()
                    for _, effect in ipairs(Lighting:GetChildren()) do
                        if effect:IsA("PostEffect") then
                            _fpsBooster.origStates.effects[effect] = effect.Enabled
                            effect.Enabled = false
                        end
                    end
                end)
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                _fpsBooster.newObjConn = workspace.DescendantAdded:Connect(function(obj)
                    if not _fpsBooster.enabled then return end
                    task.spawn(function()
                        if obj:IsA("ForceField") or obj:IsA("Sparkles") or obj:IsA("Smoke") or obj:IsA("Fire") then
                            RunService.Heartbeat:Wait()
                            pcall(function() obj:Destroy() end)
                        else
                            task.defer(_optimizeObj, obj)
                        end
                    end)
                end)
                Library:MakeNotify({
                    Title       = "FPS Booster",
                    Description = "FPS Booster aktif, grafik diringankan.",
                    Delay       = 3,
                })
            else
                task.spawn(function()
                    local descendants = game:GetDescendants()
                    for i = 1, #descendants, 50 do
                        for j = i, math.min(i + 49, #descendants) do
                            _restoreObj(descendants[j])
                        end
                        task.wait()
                    end
                end)
                if Terrain and _fpsBooster.origStates.water then
                    pcall(function()
                        Terrain.WaterReflectance  = _fpsBooster.origStates.water.WaterReflectance
                        Terrain.WaterWaveSize     = _fpsBooster.origStates.water.WaterWaveSize
                        Terrain.WaterWaveSpeed    = _fpsBooster.origStates.water.WaterWaveSpeed
                        Terrain.WaterTransparency = _fpsBooster.origStates.water.WaterTransparency
                    end)
                end
                pcall(function()
                    local l = _fpsBooster.origStates.lighting
                    if l and l.GlobalShadows ~= nil then
                        Lighting.GlobalShadows = l.GlobalShadows
                        Lighting.FogEnd        = l.FogEnd
                        Lighting.FogStart      = l.FogStart
                    end
                end)
                pcall(function()
                    for effect, state in pairs(_fpsBooster.origStates.effects) do
                        if effect and effect.Parent then effect.Enabled = state end
                    end
                end)
                settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
                if _fpsBooster.newObjConn then
                    _fpsBooster.newObjConn:Disconnect()
                    _fpsBooster.newObjConn = nil
                end
                _fpsBooster.origStates = { reflectance = {}, transparency = {}, material = {}, surfaces = {}, lighting = {}, effects = {}, water = {}, decalTextures = {} }
                Library:MakeNotify({
                    Title       = "FPS Booster",
                    Description = "FPS Booster dimatikan, grafik dikembalikan.",
                    Delay       = 3,
                })
            end
        end,
    })

    PerformanceSection:AddToggle({
        Title    = "Disable 3D Rendering",
        Default  = false,
        Callback = function(on)
            _disableRender.enabled = on
            if on then
                if _disableRender.conn then return end
                pcall(function() RunService:Set3dRenderingEnabled(false) end)
                _disableRender.conn = RunService.RenderStepped:Connect(function()
                    pcall(function() RunService:Set3dRenderingEnabled(false) end)
                end)
                LocalPlayer.CharacterAdded:Connect(function()
                    if not _disableRender.enabled then return end
                    task.wait(0.5)
                    pcall(function() RunService:Set3dRenderingEnabled(false) end)
                end)
                Library:MakeNotify({
                    Title       = "Disable Rendering",
                    Description = "3D Rendering dimatikan.",
                    Delay       = 3,
                })
            else
                if _disableRender.conn then
                    _disableRender.conn:Disconnect()
                    _disableRender.conn = nil
                end
                pcall(function() RunService:Set3dRenderingEnabled(true) end)
                Library:MakeNotify({
                    Title       = "Disable Rendering",
                    Description = "3D Rendering dinyalakan kembali.",
                    Delay       = 3,
                })
            end
        end,
    })

    PerformanceSection:AddToggle({
        Title    = "Unlock FPS",
        Default  = false,
        Callback = function(on)
            _unlockFPS.enabled = on
            if on then
                if setfpscap then
                    setfpscap(_unlockFPS.cap)
                    Library:MakeNotify({
                        Title       = "Unlock FPS",
                        Description = "FPS Cap diset ke " .. tostring(_unlockFPS.cap) .. " FPS.",
                        Delay       = 3,
                    })
                else
                    warn("[UnlockFPS] setfpscap() tidak tersedia di executor kamu.")
                    Library:MakeNotify({
                        Title       = "Unlock FPS",
                        Description = "setfpscap() tidak tersedia di executor kamu.",
                        Delay       = 3,
                    })
                end
            else
                if setfpscap then setfpscap(60) end
                Library:MakeNotify({
                    Title       = "Unlock FPS",
                    Description = "FPS Cap dikembalikan ke 60 FPS.",
                    Delay       = 3,
                })
            end
        end,
    })

    PerformanceSection:AddDropdown({
        Title    = "FPS Cap",
        Options  = { "60", "90", "120", "240" },
        Default  = "60",
        Callback = function(selected)
            _unlockFPS.cap = tonumber(selected) or 60
            if _unlockFPS.enabled and setfpscap then
                setfpscap(_unlockFPS.cap)
                Library:MakeNotify({
                    Title       = "FPS Cap",
                    Description = "FPS Cap diubah ke " .. selected .. " FPS.",
                    Delay       = 2,
                })
            end
        end,
    })
end
