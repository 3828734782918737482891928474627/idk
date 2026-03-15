-- blueprint.lua on discord

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local HttpService = game:GetService('HttpService')

pcall(function()
    setthreadidentity(2)
end)

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local Fsys = require(ReplicatedStorage:WaitForChild("Fsys"))
local LoadModule = Fsys.load

local ClientData = LoadModule("ClientData")
local RouterClient = LoadModule("RouterClient")
local UIManager = LoadModule("UIManager")
local InventoryDB = LoadModule("InventoryDB")
local KindDB = LoadModule("KindDB")
local DownloadClient = LoadModule("DownloadClient")
local AnimationManager = LoadModule("AnimationManager")
local PetRigs = LoadModule("new:PetRigs")
local AilmentsClient = LoadModule("new:AilmentsClient")
local AilmentsDB = LoadModule("new:AilmentsDB")
local CharWrapperClient = LoadModule("CharWrapperClient")

_G.InventoryDB = InventoryDB

local TradeHistoryApp = UIManager.apps.TradeHistoryApp
local TradeApp = UIManager.apps.TradeApp

if TradeHistoryApp._ORIGINAL_create_trade_frame then
   TradeHistoryApp._create_trade_frame = TradeHistoryApp._ORIGINAL_create_trade_frame
end
if TradeApp._ORIGINAL_change_local_trade_state then
   TradeApp._change_local_trade_state = TradeApp._ORIGINAL_change_local_trade_state
end
if TradeApp._ORIGINAL_overwrite_local_trade_state then
   TradeApp._overwrite_local_trade_state = TradeApp._ORIGINAL_overwrite_local_trade_state
end

TradeHistoryApp._ORIGINAL_create_trade_frame = TradeHistoryApp._create_trade_frame
TradeApp._ORIGINAL_change_local_trade_state = TradeApp._change_local_trade_state
TradeApp._ORIGINAL_overwrite_local_trade_state = TradeApp._overwrite_local_trade_state

local tradeCache = {}
local currentTradeItems = nil

function TradeApp._change_local_trade_state(self, changes, ...)
   local currentState = TradeApp.local_trade_state

   if currentState and currentState.trade_id then
       local isSender = currentState.sender == LocalPlayer
       local isRecipient = currentState.recipient == LocalPlayer

       if isSender and changes.sender_offer and changes.sender_offer.items then
           tradeCache[currentState.trade_id] = {
               items = table.clone(changes.sender_offer.items),
               isSender = true
           }
           currentTradeItems = changes.sender_offer.items
       elseif isRecipient and changes.recipient_offer and changes.recipient_offer.items then
           tradeCache[currentState.trade_id] = {
               items = table.clone(changes.recipient_offer.items),
               isSender = false
           }
           currentTradeItems = changes.recipient_offer.items
       end
   end

   return TradeApp._ORIGINAL_change_local_trade_state(self, changes, ...)
end

function TradeApp._overwrite_local_trade_state(self, tradeState, ...)
   if tradeState then
       local isSender = tradeState.sender == LocalPlayer
       local isRecipient = tradeState.recipient == LocalPlayer

       if isSender and tradeState.sender_offer and currentTradeItems then
           tradeState.sender_offer.items = currentTradeItems
       elseif isRecipient and tradeState.recipient_offer and currentTradeItems then
           tradeState.recipient_offer.items = currentTradeItems
       end
   else
       currentTradeItems = nil
       if TradeApp._last_trade_id then
           tradeCache[TradeApp._last_trade_id] = nil
           TradeApp._last_trade_id = nil
       end
   end

   return TradeApp._ORIGINAL_overwrite_local_trade_state(self, tradeState, ...)
end

function TradeHistoryApp._create_trade_frame(self, tradeData, ...)
   if tradeData.trade_id and tradeCache[tradeData.trade_id] then
       local cachedData = tradeCache[tradeData.trade_id]
       local modifiedData = table.clone(tradeData)

       if cachedData.isSender then
           modifiedData.sender_items = table.clone(cachedData.items)
       else
           modifiedData.recipient_items = table.clone(cachedData.items)
       end

       return TradeHistoryApp._ORIGINAL_create_trade_frame(self, modifiedData, ...)
   end

   return TradeHistoryApp._ORIGINAL_create_trade_frame(self, tradeData, ...)
end

local HighTierPets = {
    "Shadow Dragon", "Bat Dragon", "Frost Dragon", "Giraffe", "Owl", "Parrot", "Crow",
    "Evil Unicorn", "Arctic Reindeer", "Hedgehog", "Dalmatian", "Turtle", "Kangaroo",
    "Lion", "Elephant", "Rhino", "Blazing Lion", "African Wild Dog", "Flamingo",
    "Diamond Butterfly", "Mini Pig", "Caterpillar", "Albino Monkey", "Candyfloss Chick",
    "Pelican", "Blue Dog", "Pink Cat", "Haetae", "Peppermint Penguin", "Winged Tiger",
    "Sugar Glider", "Shark Puppy", "Goat", "Sheeeeep", "Lion Cub", "Nessie",
    "Frostbite Bear", "Balloon Unicorn", "Honey Badger", "Hot Doggo", "Crocodile",
    "Hare", "Ram", "Yeti", "Meetkat", "Jellyfish", "Happy Clown", "Orchid Butterfly",
    "Many Mackerel", "Strawberry Shortcake Bat Dragon", "Zombie Buffalo", "Fairy Bat Dragon",
    "Chocolate Chip Bat Dragon", "Cow", "Giant Panda", "Candicorn", "Gumball Caterpillar",
}

local SpawnedPets = {}
local PetModelCache = {}
local EquippedPet = nil
local CurrentRideId = nil
local RideAnimationTrack = nil
local PetAilmentsCache = {}
local SpawnedItems = {}

local function GenerateUniquePetName()
    local prefixes = {"★", "☆", "♡", "☁️", "✨", "🍓", "🌸", "🍯", "☕", "🌙", "🌈", "❄️", "🫧", "🍬", "🍪", "🥛"}
    local names = {"Shadow", "Blaze", "Frost", "Thunder", "Moon", "Star", "Sky", "Ocean", "River", "Storm", 
                   "Ember", "Ash", "Dusk", "Dawn", "Night", "Day", "Sun", "Wind", "Rain", "Snow", "Ice", "Fire",
                   "Nova", "Cosmo", "Galaxy", "Orbit", "Comet", "Meteor", "Aurora", "Nebula", "Crystal", "Gem",
                   "Ruby", "Sapphire", "Emerald", "Diamond", "Gold", "Silver", "Mystic", "Magic", "Enchant"}
    
    local usePrefix = math.random(1, 3) == 1
    local name = names[math.random(1, #names)]
    
    if usePrefix then
        return prefixes[math.random(1, #prefixes)] .. name
    else
        return name .. " " .. prefixes[math.random(1, #prefixes)]
    end
end

local NewnessGroups = {
    mega_neon_flyable_rideable = 990000,
    mega_neon_flyable = 980000,
    mega_neon_rideable = 970000,
    mega_neon = 960000,
    neon_flyable_rideable = 950000,
    neon_flyable = 940000,
    neon_rideable = 930000,
    neon = 920000,
    flyable_rideable = 910000,
    flyable = 900000,
    rideable = 890000,
    regular = 880000
}

local function GetPropertyGroup(properties)
    local isMega = properties.mega_neon or false
    local isNeon = properties.neon or false
    local canFly = properties.flyable or false
    local canRide = properties.rideable or false

    if isMega then
        if canFly and canRide then return "mega_neon_flyable_rideable"
        elseif canFly then return "mega_neon_flyable"
        elseif canRide then return "mega_neon_rideable"
        else return "mega_neon" end
    elseif isNeon then
        if canFly and canRide then return "neon_flyable_rideable"
        elseif canFly then return "neon_flyable"
        elseif canRide then return "neon_rideable"
        else return "neon" end
    else
        if canFly and canRide then return "flyable_rideable"
        elseif canFly then return "flyable"
        elseif canRide then return "rideable"
        else return "regular" end
    end
end

local function UpdateClientData(dataPath, modifier)
    local identity = get_thread_identity and get_thread_identity() or 8
    set_thread_identity(2)
    local currentData = ClientData.get(dataPath)
    local clonedData = table.clone(currentData)
    local result = modifier(clonedData)
    ClientData.predict(dataPath, result)
    set_thread_identity(identity)
    return result
end

local function GenerateUniqueID()
    return HttpService:GenerateGUID(false)
end

local function FindInTable(array, checker)
    for index, value in pairs(array) do
        if checker(value, index) then
            return index
        end
    end
    return nil
end

local originalGetServer = ClientData.get_server

function ClientData.get_server(player, key, ...)
    local data = originalGetServer(player, key, ...)

    if key == "ailments_manager" and player == LocalPlayer then
        local ailmentsData = {}
        if data then
            for k, v in pairs(data) do
                ailmentsData[k] = type(v) == "table" and table.clone(v) or v
            end
        end
        
        ailmentsData.ailments = ailmentsData.ailments or {}
        
        for petId, _ in pairs(SpawnedPets) do
            if PetAilmentsCache[petId] then
                ailmentsData.ailments[petId] = PetAilmentsCache[petId]
            else
                local ailmentTypes = {}
                for kind, _ in pairs(AilmentsDB) do
                    if kind ~= "at_work" and kind ~= "mystery" and kind ~= "walking" then
                        table.insert(ailmentTypes, kind)
                    end
                end

                local ailmentCount = math.random(2, 4)
                local petAilments = {}
                local usedTypes = {}

                for i = 1, math.min(ailmentCount, #ailmentTypes) do
                    local ailmentKind
                    repeat
                        ailmentKind = ailmentTypes[math.random(1, #ailmentTypes)]
                    until not usedTypes[ailmentKind]
                    usedTypes[ailmentKind] = true

                    local ailmentId = GenerateUniqueID()
                    petAilments[ailmentId] = {
                        components = {},
                        created_timestamp = os.time(),
                        kind = ailmentKind,
                        progress = 0,
                        rate = 0,
                        rate_timestamp = os.time(),
                        sort_order = i * 100
                    }
                end

                PetAilmentsCache[petId] = petAilments
                ailmentsData.ailments[petId] = petAilments
            end
        end

        return ailmentsData
    end

    return data
end

local function FetchPetModel(petKind)
    if PetModelCache[petKind] then
        return PetModelCache[petKind]
    end
    local model = DownloadClient.promise_download_copy("Pets", petKind):expect()
    PetModelCache[petKind] = model
    return model
end

local function ApplyNeonVisuals(petModel, petData)
    local modelInstance = petModel:FindFirstChild("PetModel")
    if modelInstance and (petData.properties.neon or petData.properties.mega_neon) then
        local petKindData = KindDB[petData.id]
        for partName, partProps in pairs(petKindData.neon_parts) do
            local geoPart = PetRigs.get(modelInstance).get_geo_part(modelInstance, partName)
            if geoPart then
                geoPart.Material = partProps.Material
                geoPart.Color = partProps.Color
            end
        end
    end
end

local function RegisterPetWrapper(wrapperData)
    UpdateClientData("pet_char_wrappers", function(wrappers)
        wrapperData.unique = #wrappers + 1
        wrapperData.index = #wrappers + 1
        wrappers[#wrappers + 1] = wrapperData
        return wrappers
    end)
end

local function RegisterPetState(stateManager)
    UpdateClientData("pet_state_managers", function(managers)
        managers[#managers + 1] = stateManager
        return managers
    end)
end

local function RemovePetWrapper(petUniqueId)
    UpdateClientData("pet_char_wrappers", function(wrappers)
        local wrapperIndex = FindInTable(wrappers, function(w)
            return w.pet_unique == petUniqueId
        end)
        if wrapperIndex then
            table.remove(wrappers, wrapperIndex)
            for i = wrapperIndex, #wrappers do
                wrappers[i].unique = i
                wrappers[i].index = i
            end
        end
        return wrappers
    end)
end

local function RemovePetState(petUniqueId)
    local pet = SpawnedPets[petUniqueId]
    if not pet or not pet.model then return end

    UpdateClientData("pet_state_managers", function(managers)
        local managerIndex = FindInTable(managers, function(m)
            return m.char == pet.model
        end)
        if managerIndex then
            table.remove(managers, managerIndex)
        end
        return managers
    end)
end

local function ClearPetStates(petUniqueId)
    local pet = SpawnedPets[petUniqueId]
    if not pet or not pet.model then return end

    UpdateClientData("pet_state_managers", function(managers)
        local managerIndex = FindInTable(managers, function(m)
            return m.char == pet.model
        end)
        if managerIndex then
            local updated = table.clone(managers)
            updated[managerIndex] = table.clone(updated[managerIndex])
            updated[managerIndex].states = {}
            return updated
        end
        return managers
    end)
end

local function SetPetState(petUniqueId, stateId)
    local pet = SpawnedPets[petUniqueId]
    if not pet or not pet.model then return end

    UpdateClientData("pet_state_managers", function(managers)
        local managerIndex = FindInTable(managers, function(m)
            return m.char == pet.model
        end)
        if managerIndex then
            local updated = table.clone(managers)
            updated[managerIndex] = table.clone(updated[managerIndex])
            updated[managerIndex].states = {{ id = stateId }}
            return updated
        end
        return managers
    end)
end

local function ClearPlayerStates()
    UpdateClientData("state_manager", function(stateManager)
        local updated = table.clone(stateManager)
        updated.states = {}
        updated.is_sitting = false
        return updated
    end)
end

local function SetPlayerState(stateId)
    UpdateClientData("state_manager", function(stateManager)
        local updated = table.clone(stateManager)
        updated.states = {{ id = stateId }}
        updated.is_sitting = true
        return updated
    end)
end

local function AttachRideConstraint(petModel)
    local character = LocalPlayer.Character
    if not character or not character.PrimaryPart then return false end

    local ridePos = petModel:FindFirstChild("RidePosition", true)
    if not ridePos then return false end

    local sourceAttach = Instance.new("Attachment")
    sourceAttach.Parent = ridePos
    sourceAttach.Position = Vector3.new(0, 1.237, 0)
    sourceAttach.Name = "SourceAttachment"

    local rigidConstraint = Instance.new("RigidConstraint")
    rigidConstraint.Name = "StateConnection"
    rigidConstraint.Attachment0 = sourceAttach
    rigidConstraint.Attachment1 = character.PrimaryPart.RootAttachment
    rigidConstraint.Parent = character

    return true
end

local function DismountPet()
    if not CurrentRideId then return end

    local pet = SpawnedPets[CurrentRideId]
    if pet and pet.model then
        if RideAnimationTrack then
            RideAnimationTrack:Stop()
            RideAnimationTrack:Destroy()
            RideAnimationTrack = nil
        end

        local sourceAttach = pet.model:FindFirstChild("SourceAttachment", true)
        if sourceAttach then sourceAttach:Destroy() end

        local character = LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part:GetAttribute("HaveMass") then
                    part.Massless = false
                end
            end
        end

        ClearPetStates(CurrentRideId)
        ClearPlayerStates()
        pet.model:ScaleTo(1)
    end
    CurrentRideId = nil
end

local function MountPet(petUniqueId, playerState, petState)
    local pet = SpawnedPets[petUniqueId]
    if not pet or not pet.model then return end

    local character = LocalPlayer.Character
    if not character or not character.PrimaryPart or not character:FindFirstChild("Humanoid") then return end

    DismountPet()
    CurrentRideId = petUniqueId

    SetPetState(petUniqueId, petState)
    SetPlayerState(playerState)
    pet.model:ScaleTo(2)
    AttachRideConstraint(pet.model)

    RideAnimationTrack = character.Humanoid.Animator:LoadAnimation(AnimationManager.get_track("PlayerRidingPet"))
    character.Humanoid.Sit = true

    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Massless == false then
            part.Massless = true
            part:SetAttribute("HaveMass", true)
        end
    end

    RideAnimationTrack:Play()
end

local function RidePet(petUniqueId)
    MountPet(petUniqueId, "PlayerRidingPet", "PetBeingRidden")
end

local function FlyPet(petUniqueId)
    MountPet(petUniqueId, "PlayerFlyingPet", "PetBeingFlown")
end

local function UnequipPet(petData)
    local pet = SpawnedPets[petData.unique]
    if not pet or not pet.model then return end

    if CurrentRideId == petData.unique then
        DismountPet()
    end

    RemovePetWrapper(petData.unique)
    RemovePetState(petData.unique)
    pet.model:Destroy()
    pet.model = nil

    if EquippedPet and EquippedPet.unique == petData.unique then
        EquippedPet = nil
    end

    PetAilmentsCache[petData.unique] = nil
    task.wait(0.15)
    AilmentsClient.on_ailments_changed(LocalPlayer)
end

local function EquipPet(petData)
    if petData.category ~= "pets" then return end

    if EquippedPet then
        UnequipPet(EquippedPet)
    end

    for _, wrapper in pairs(ClientData.get("pet_char_wrappers")) do
        if wrapper.controller == LocalPlayer then
            RouterClient.get("ToolAPI/Unequip"):InvokeServer(wrapper.pet_unique)
        end
    end

    if not SpawnedPets[petData.unique] then
        SpawnedPets[petData.unique] = { data = petData, model = nil }
    end

    local petModel = FetchPetModel(petData.kind):Clone()
    petModel.Parent = workspace
    SpawnedPets[petData.unique].model = petModel
    ApplyNeonVisuals(petModel, petData)

    EquippedPet = petData

    task.defer(function()
        RegisterPetWrapper({
            char = petModel,
            mega_neon = petData.properties.mega_neon or false,
            neon = petData.properties.neon or false,
            player = LocalPlayer,
            entity_controller = LocalPlayer,
            controller = LocalPlayer,
            rp_name = petData.properties.rp_name or "",
            pet_trick_level = petData.properties.pet_trick_level or 0,
            pet_unique = petData.unique,
            pet_id = petData.id,
            location = {
                full_destination_id = "housing",
                destination_id = "housing",
                house_owner = LocalPlayer
            },
            pet_progression = {
                age = petData.properties.age or math.random(1, 6),
                percentage = math.random(0, 99) / 100
            },
            are_colors_sealed = false,
            is_pet = true,
        })

        RegisterPetState({
            char = petModel,
            player = LocalPlayer,
            store_key = "pet_state_managers",
            is_sitting = false,
            chars_connected_to_me = {},
            states = {}
        })
        task.wait(0.15)
        AilmentsClient.on_ailments_changed(LocalPlayer)
    end)
end

local NextToyOrder = 60000

local function CreateInventoryItem(itemId, category, properties)
    local uniqueId = GenerateUniqueID()
    local itemKindData = KindDB[itemId]

    if not itemKindData then
        warn("Item not found: " .. itemId)
        return nil
    end

    properties = properties or {}
    local newnessValue = NextToyOrder

    if category == "pets" then
        local groupKey = GetPropertyGroup(properties)
        NewnessGroups[groupKey] = NewnessGroups[groupKey] - 1
        newnessValue = NewnessGroups[groupKey]

        if not properties.ailments_completed then
            properties.ailments_completed = 0
        end

        if not properties.rp_name or properties.rp_name == "" then
            properties.rp_name = GenerateUniquePetName()
        end
    else
        NextToyOrder = NextToyOrder - 1
        newnessValue = NextToyOrder
    end

    local itemData = {
        unique = uniqueId,
        category = category,
        id = itemId,
        kind = itemKindData.kind,
        newness_order = newnessValue,
        properties = properties,
        _source = "blueprint.lua"
    }

    local identity = get_thread_identity and get_thread_identity() or 8
    set_thread_identity(2)
    local inventory = ClientData.get("inventory")
    if inventory and inventory[category] then
        inventory[category][uniqueId] = itemData
    end
    set_thread_identity(identity)

    if category == "pets" then
        SpawnedPets[uniqueId] = { data = itemData, model = nil }
    end
    
    SpawnedItems[uniqueId] = true

    task.defer(function()
        if UIManager and UIManager.apps and UIManager.apps.BackpackApp then
            UIManager.apps.BackpackApp:refresh_rendered_items()
        end
    end)

    return itemData
end

local function DeleteAllSpawnedPets()
    local identity = get_thread_identity and get_thread_identity() or 8
    set_thread_identity(2)
    
    local inventory = ClientData.get("inventory")
    local removed = 0
    
    if inventory and inventory.pets then
        for uniqueId, _ in pairs(SpawnedItems) do
            if inventory.pets[uniqueId] and inventory.pets[uniqueId]._source == "blueprint.lua" then
                inventory.pets[uniqueId] = nil
                removed = removed + 1
            end
        end
    end
    
    set_thread_identity(identity)
    
    for uniqueId, _ in pairs(SpawnedPets) do
        if SpawnedPets[uniqueId] and SpawnedPets[uniqueId].data and SpawnedPets[uniqueId].data._source == "blueprint.lua" then
            if SpawnedPets[uniqueId].model then
                SpawnedPets[uniqueId].model:Destroy()
            end
        end
    end
    
    SpawnedPets = {}
    SpawnedItems = {}
    PetAilmentsCache = {}
    EquippedPet = nil
    CurrentRideId = nil
    
    task.defer(function()
        if UIManager and UIManager.apps and UIManager.apps.BackpackApp then
            UIManager.apps.BackpackApp:refresh_rendered_items()
        end
    end)
    
    return removed
end

local function FindPetId(petName)
    for id, info in pairs(InventoryDB.pets) do
        if info.name:lower() == petName:lower() then
            return id
        end
    end
    return nil
end

local function FindToyId(toyName)
    for id, info in pairs(InventoryDB.toys) do
        if info.name:lower() == toyName:lower() then
            return id
        end
    end
    return nil
end

local function FindItemId(itemName)
    local categories = {
        {name = "pets", finder = FindPetId},
        {name = "toys", finder = FindToyId}
    }
    
    for _, cat in ipairs(categories) do
        local id = cat.finder(itemName)
        if id then return id, cat.name end
    end
    return nil, nil
end

local OriginalRouterGet = RouterClient.get

function RouterClient.get(endpoint)
    if endpoint == "ToolAPI/Equip" then
        return {
            InvokeServer = function(_, uniqueId)
                local pet = SpawnedPets[uniqueId]
                if not pet then
                    return OriginalRouterGet("ToolAPI/Equip"):InvokeServer(uniqueId)
                end
                EquipPet(pet.data)
                return true, { action = "equip", is_server = true }
            end
        }
    elseif endpoint == "ToolAPI/Unequip" then
        return {
            InvokeServer = function(_, uniqueId)
                local pet = SpawnedPets[uniqueId]
                if not pet then
                    return OriginalRouterGet("ToolAPI/Unequip"):InvokeServer(uniqueId)
                end
                UnequipPet(pet.data)
                return true, { action = "unequip", is_server = true }
            end
        }
    elseif endpoint == "AdoptAPI/RidePet" then
        return {
            InvokeServer = function(_, petData)
                local pet = SpawnedPets[petData.pet_unique]
                if not pet then
                    return OriginalRouterGet("AdoptAPI/RidePet"):InvokeServer(petData)
                end
                RidePet(petData.pet_unique)
                return true
            end
        }
    elseif endpoint == "AdoptAPI/FlyPet" then
        return {
            InvokeServer = function(_, petData)
                local pet = SpawnedPets[petData.pet_unique]
                if not pet then
                    return OriginalRouterGet("AdoptAPI/FlyPet"):InvokeServer(petData)
                end
                FlyPet(petData.pet_unique)
                return true
            end
        }
    elseif endpoint == "AdoptAPI/ExitSeatStates" then
        return {
            FireServer = function()
                if CurrentRideId then
                    DismountPet()
                    return true
                end
                return OriginalRouterGet("AdoptAPI/ExitSeatStates"):FireServer()
            end
        }
    elseif endpoint == "SettingsAPI/SetPetRoleplayName" then
        return {
            InvokeServer = function(_, petUniqueId, newName)
                local pet = SpawnedPets[petUniqueId]
                if not pet then
                    return OriginalRouterGet("SettingsAPI/SetPetRoleplayName"):InvokeServer(petUniqueId, newName)
                end
                
                local identity = get_thread_identity and get_thread_identity() or 8
                set_thread_identity(2)
                
                local inventory = ClientData.get("inventory")
                if inventory and inventory.pets and inventory.pets[petUniqueId] then
                    inventory.pets[petUniqueId].properties.rp_name = newName
                end
                
                if pet.data then
                    pet.data.properties.rp_name = newName
                end
                
                local wrappers = ClientData.get("pet_char_wrappers")
                for _, wrapper in pairs(wrappers) do
                    if wrapper.pet_unique == petUniqueId then
                        wrapper.rp_name = newName
                        break
                    end
                end
                
                set_thread_identity(identity)
                return true
            end
        }
    else
        return OriginalRouterGet(endpoint)
    end
end

for _, wrapper in pairs(ClientData.get("pet_char_wrappers")) do
    OriginalRouterGet("ToolAPI/Unequip"):InvokeServer(wrapper.pet_unique)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "blueprint_lua"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 300)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local uiScale = Instance.new("UIScale", mainFrame)
uiScale.Scale = 0.7

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 3
uiStroke.Color = Color3.fromRGB(0, 220, 255)
uiStroke.Parent = mainFrame

local palette = {
    Color3.fromRGB(0, 220, 255),
    Color3.fromRGB(120, 90, 255),
    Color3.fromRGB(255, 80, 160),
    Color3.fromRGB(0, 200, 180)
}
local colorIdx = 1
task.spawn(function()
    while true do
        colorIdx = colorIdx % #palette + 1
        TweenService:Create(uiStroke, TweenInfo.new(4), { Color = palette[colorIdx] }):Play()
        task.wait(4)
    end
end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 20)
title.Position = UDim2.new(0, 0, 0, 4)
title.BackgroundTransparency = 1
title.Text = "DC : 0ksam"
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextColor3 = Color3.fromRGB(235, 240, 255)
title.Parent = mainFrame

local tabContainer = Instance.new('Frame')
tabContainer.Size = UDim2.new(0.94, 0, 0, 20)
tabContainer.Position = UDim2.new(0.03, 0, 0, 26)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

local tabs = {
    { key = 'Spawn',   label = 'Spawn'   },
    { key = 'Tools',   label = 'Tools'   },
    { key = 'Wears',   label = 'Wears'   },
    { key = 'Colours', label = 'Colours' },
    { key = 'Tricks',  label = 'Tricks'  },
}

local activeTab = 'Spawn'
local tabElements = {}

local function SwitchTab(tabName)
    activeTab = tabName
    for name, data in pairs(tabElements) do
        local isActive = name == tabName
        data.button.BackgroundColor3 = isActive and Color3.fromRGB(50, 50, 60) or Color3.fromRGB(40, 40, 50)
        data.stroke.Color = isActive and Color3.fromRGB(100, 100, 255) or Color3.fromRGB(80, 80, 80)
        data.stroke.Thickness = isActive and 1.2 or 0.8
    end
    -- panel visibility handled after panels are created
    if spawnPanel   then spawnPanel.Visible   = (tabName == 'Spawn')   end
    if toolsPanel   then toolsPanel.Visible   = (tabName == 'Tools')   end
    if wearsPanel   then wearsPanel.Visible   = (tabName == 'Wears')   end
    if coloursPanel then coloursPanel.Visible = (tabName == 'Colours') end
    if tricksPanel  then tricksPanel.Visible  = (tabName == 'Tricks')  end
end

for i, tab in ipairs(tabs) do
    local tabButton = Instance.new('TextButton')
    tabButton.Size = UDim2.new(1 / #tabs - 0.02, 0, 1, 0)
    tabButton.Position = UDim2.new((i - 1) * (1 / #tabs), (i == 1) and 0 or 4, 0, 0)
    tabButton.BackgroundColor3 = i == 1 and Color3.fromRGB(50, 50, 60) or Color3.fromRGB(40, 40, 50)
    tabButton.BackgroundTransparency = 0.2
    tabButton.Text = tab.label
    tabButton.Font = Enum.Font.GothamBold
    tabButton.TextSize = 9
    tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabButton.Parent = tabContainer
    
    Instance.new("UICorner", tabButton).CornerRadius = UDim.new(0, 6)
    
    local tabStroke = Instance.new('UIStroke')
    tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    tabStroke.Color = i == 1 and Color3.fromRGB(100, 100, 255) or Color3.fromRGB(80, 80, 80)
    tabStroke.Thickness = i == 1 and 1.2 or 0.8
    tabStroke.Transparency = 0.3
    tabStroke.Parent = tabButton
    
    tabElements[tab.key] = { button = tabButton, stroke = tabStroke }
    
    tabButton.MouseButton1Click:Connect(function()
        SwitchTab(tab.key)
    end)
end

local spawnPanel = Instance.new("Frame")
spawnPanel.Size = UDim2.new(0.94, 0, 1, -48)
spawnPanel.Position = UDim2.new(0.03, 0, 0, 46)
spawnPanel.BackgroundTransparency = 1
spawnPanel.Visible = true
spawnPanel.Parent = mainFrame

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0, 10)
nameLabel.Position = UDim2.new(0, 0, 0, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "🐾 Pet Name"
nameLabel.Font = Enum.Font.Gotham
nameLabel.TextSize = 8
nameLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = spawnPanel

local nameInput = Instance.new("TextBox")
nameInput.Size = UDim2.new(1, 0, 0, 22)
nameInput.Position = UDim2.new(0, 0, 0, 11)
nameInput.BackgroundColor3 = Color3.fromRGB(32, 36, 58)
nameInput.TextColor3 = Color3.fromRGB(240, 240, 255)
nameInput.TextSize = 11
nameInput.Font = Enum.Font.Gotham
nameInput.PlaceholderText = "Enter pet name..."
nameInput.PlaceholderColor3 = Color3.fromRGB(140, 150, 180)
nameInput.ClearTextOnFocus = false
nameInput.Text = "Bat Dragon"
nameInput.Parent = spawnPanel

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = nameInput

local glowColors = {
    neutral = Color3.fromRGB(220, 220, 255),
    valid = Color3.fromRGB(120, 255, 150),
    invalid = Color3.fromRGB(255, 120, 120)
}

local inputGlow = Instance.new("UIStroke")
inputGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
inputGlow.Color = glowColors.neutral
inputGlow.Thickness = 2
inputGlow.Transparency = 0.3
inputGlow.Parent = nameInput

local ageLabel = Instance.new("TextLabel")
ageLabel.Size = UDim2.new(1, 0, 0, 10)
ageLabel.Position = UDim2.new(0, 0, 0, 38)
ageLabel.BackgroundTransparency = 1
ageLabel.Text = "📅 Age"
ageLabel.Font = Enum.Font.Gotham
ageLabel.TextSize = 8
ageLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
ageLabel.TextXAlignment = Enum.TextXAlignment.Left
ageLabel.Parent = spawnPanel

local ageGrid = Instance.new("Frame")
ageGrid.Size = UDim2.new(1, 0, 0, 20)
ageGrid.Position = UDim2.new(0, 0, 0, 49)
ageGrid.BackgroundTransparency = 1
ageGrid.Parent = spawnPanel

local ageCodes = {"N", "J", "P", "T", "P", "F"}
local ageDescriptions = {"Newborn", "Junior", "Pre-Teen", "Teen", "Post-Teen", "Full Grown"}
local currentAge = 1

for i, code in ipairs(ageCodes) do
    local ageButton = Instance.new("TextButton")
    ageButton.Size = UDim2.new(1/6 - 0.01, 0, 1, 0)
    ageButton.Position = UDim2.new((i-1) * (1/6), (i > 1) and 2 or 0, 0, 0)
    ageButton.Text = code
    ageButton.BackgroundColor3 = i == 1 and Color3.fromRGB(80, 80, 100) or Color3.fromRGB(40, 44, 66)
    ageButton.Font = Enum.Font.GothamBold
    ageButton.TextColor3 = Color3.fromRGB(240, 240, 255)
    ageButton.TextSize = 11
    ageButton.Parent = ageGrid
    
    local ageCorner = Instance.new("UICorner")
    ageCorner.CornerRadius = UDim.new(0, 6)
    ageCorner.Parent = ageButton
    
    local hintBox = Instance.new("TextLabel")
    hintBox.Text = ageDescriptions[i]
    hintBox.BackgroundColor3 = Color3.fromRGB(22, 26, 40)
    hintBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    hintBox.TextSize = 7
    hintBox.Font = Enum.Font.Gotham
    hintBox.Size = UDim2.new(0, 0, 0, 0)
    hintBox.Visible = false
    hintBox.Parent = ageButton
    Instance.new("UICorner", hintBox).CornerRadius = UDim.new(0, 4)
    
    ageButton.MouseEnter:Connect(function()
        hintBox.Size = UDim2.new(0, 65, 0, 15)
        hintBox.Position = UDim2.new(0, 0, -1.2, 0)
        hintBox.Visible = true
    end)
    
    ageButton.MouseLeave:Connect(function()
        hintBox.Visible = false
    end)
    
    ageButton.MouseButton1Click:Connect(function()
        currentAge = i
        for _, btn in pairs(ageGrid:GetChildren()) do
            if btn:IsA("TextButton") then
                btn.BackgroundColor3 = Color3.fromRGB(40, 44, 66)
            end
        end
        ageButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    end)
end

local flagLabel = Instance.new("TextLabel")
flagLabel.Size = UDim2.new(1, 0, 0, 10)
flagLabel.Position = UDim2.new(0, 0, 0, 74)
flagLabel.BackgroundTransparency = 1
flagLabel.Text = "✨ Pet Flags"
flagLabel.Font = Enum.Font.Gotham
flagLabel.TextSize = 8
flagLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
flagLabel.TextXAlignment = Enum.TextXAlignment.Left
flagLabel.Parent = spawnPanel

local flagGrid = Instance.new("Frame")
flagGrid.Size = UDim2.new(1, 0, 0, 24)
flagGrid.Position = UDim2.new(0, 0, 0, 85)
flagGrid.BackgroundTransparency = 1
flagGrid.Parent = spawnPanel

local flagColors = {
    M = Color3.fromRGB(170, 0, 255),
    N = Color3.fromRGB(0, 255, 100),
    F = Color3.fromRGB(0, 200, 255),
    R = Color3.fromRGB(255, 50, 150)
}

local flagOrder = {"M", "N", "F", "R"}
local flagState = {M = false, N = false, F = true, R = true}

for i, flag in ipairs(flagOrder) do
    local flagButton = Instance.new("TextButton")
    flagButton.Size = UDim2.new(0.23, -2, 1, 0)
    flagButton.Position = UDim2.new((i-1) * 0.25, (i > 1) and 3 or 0, 0, 0)
    flagButton.Text = flag
    flagButton.BackgroundColor3 = flagState[flag] and flagColors[flag] or Color3.fromRGB(40, 44, 66)
    flagButton.Font = Enum.Font.GothamBold
    flagButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    flagButton.TextSize = 12
    flagButton.Parent = flagGrid
    
    local flagCorner = Instance.new("UICorner")
    flagCorner.CornerRadius = UDim.new(0, 8)
    flagCorner.Parent = flagButton
    
    local flagStroke = Instance.new("UIStroke")
    flagStroke.Color = flagColors[flag]
    flagStroke.Thickness = flagState[flag] and 2.5 or 1.5
    flagStroke.Transparency = flagState[flag] and 0.2 or 0.5
    flagStroke.Parent = flagButton
    
    flagButton.MouseButton1Click:Connect(function()
        if flag == "M" and flagState["N"] then return end
        if flag == "N" and flagState["M"] then return end
        
        flagState[flag] = not flagState[flag]
        
        if flagState[flag] then
            flagButton.BackgroundColor3 = flagColors[flag]
            TweenService:Create(flagStroke, TweenInfo.new(0.2), {
                Thickness = 2.5,
                Transparency = 0.2
            }):Play()
        else
            flagButton.BackgroundColor3 = Color3.fromRGB(40, 44, 66)
            TweenService:Create(flagStroke, TweenInfo.new(0.2), {
                Thickness = 1.5,
                Transparency = 0.5
            }):Play()
        end
    end)
end

local quickLabel = Instance.new("TextLabel")
quickLabel.Size = UDim2.new(1, 0, 0, 10)
quickLabel.Position = UDim2.new(0, 0, 0, 114)
quickLabel.BackgroundTransparency = 1
quickLabel.Text = "⚡ Quick Select"
quickLabel.Font = Enum.Font.Gotham
quickLabel.TextSize = 8
quickLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
quickLabel.TextXAlignment = Enum.TextXAlignment.Left
quickLabel.Parent = spawnPanel

local quickGrid = Instance.new("Frame")
quickGrid.Size = UDim2.new(1, 0, 0, 42)
quickGrid.Position = UDim2.new(0, 0, 0, 125)
quickGrid.BackgroundTransparency = 1
quickGrid.Parent = spawnPanel

local quickPets = {
    {"Shadow Dragon", Color3.fromRGB(100, 0, 100)},
    {"Frost Dragon", Color3.fromRGB(0, 150, 255)},
    {"Bat Dragon", Color3.fromRGB(150, 0, 0)},
    {"Giraffe", Color3.fromRGB(200, 150, 0)},
    {"Owl", Color3.fromRGB(150, 100, 50)},
    {"Parrot", Color3.fromRGB(255, 100, 0)}
}

for i, petData in ipairs(quickPets) do
    local row = math.floor((i-1) / 3)
    local col = (i-1) % 3
    
    local quickButton = Instance.new("TextButton")
    quickButton.Size = UDim2.new(0.32, -2, 0.45, 0)
    quickButton.Position = UDim2.new(col * 0.33, (col > 0) and 3 or 0, row * 0.5, (row > 0) and 3 or 0)
    
    if i <= 3 then
        quickButton.Text = petData[1]
    else
        quickButton.Text = petData[1]:match("^(%w+)") or petData[1]
    end
    
    quickButton.BackgroundColor3 = petData[2]
    quickButton.Font = Enum.Font.GothamBold
    quickButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    quickButton.TextSize = 7
    quickButton.Parent = quickGrid
    
    local quickCorner = Instance.new("UICorner")
    quickCorner.CornerRadius = UDim.new(0, 6)
    quickCorner.Parent = quickButton
    
    quickButton.MouseButton1Click:Connect(function()
        nameInput.Text = petData[1]
    end)
end

local spawnAllButton = Instance.new("TextButton")
spawnAllButton.Size = UDim2.new(1, 0, 0, 24)
spawnAllButton.Position = UDim2.new(0, 0, 0, 180)
spawnAllButton.Text = "👑 SPAWN ALL HIGH TIERS"
spawnAllButton.Font = Enum.Font.GothamBold
spawnAllButton.TextSize = 9
spawnAllButton.BackgroundColor3 = Color3.fromRGB(180, 120, 50)
spawnAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnAllButton.Parent = spawnPanel

local allCorner = Instance.new("UICorner")
allCorner.CornerRadius = UDim.new(0, 8)
allCorner.Parent = spawnAllButton

local allStroke = Instance.new("UIStroke")
allStroke.Color = Color3.fromRGB(255, 200, 100)
allStroke.Thickness = 1.5
allStroke.Transparency = 0.3
allStroke.Parent = spawnAllButton

local spawnButton = Instance.new("TextButton")
spawnButton.Size = UDim2.new(1, 0, 0, 28)
spawnButton.Position = UDim2.new(0, 0, 1, -36)
spawnButton.Text = "✨ SPAWN PET"
spawnButton.Font = Enum.Font.GothamBold
spawnButton.TextSize = 12
spawnButton.BackgroundColor3 = Color3.fromRGB(0, 140, 200)
spawnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnButton.Parent = spawnPanel

local spawnCorner = Instance.new("UICorner")
spawnCorner.CornerRadius = UDim.new(0, 10)
spawnCorner.Parent = spawnButton

local toolsPanel = Instance.new("Frame")
toolsPanel.Size = UDim2.new(0.94, 0, 1, -48)
toolsPanel.Position = UDim2.new(0.03, 0, 0, 46)
toolsPanel.BackgroundTransparency = 1
toolsPanel.Visible = false
toolsPanel.Parent = mainFrame

local toolsTitle = Instance.new("TextLabel")
toolsTitle.Size = UDim2.new(1, 0, 0, 16)
toolsTitle.Position = UDim2.new(0, 0, 0, 0)
toolsTitle.BackgroundTransparency = 1
toolsTitle.Text = "🔧 Tools"
toolsTitle.Font = Enum.Font.GothamBold
toolsTitle.TextSize = 11
toolsTitle.TextColor3 = Color3.fromRGB(235, 240, 255)
toolsTitle.TextXAlignment = Enum.TextXAlignment.Left
toolsTitle.Parent = toolsPanel

local deleteButton = Instance.new("TextButton")
deleteButton.Size = UDim2.new(1, 0, 0, 24)
deleteButton.Position = UDim2.new(0, 0, 0, 20)
deleteButton.Text = "🗑️ Delete All Pets"
deleteButton.Font = Enum.Font.GothamBold
deleteButton.TextSize = 9
deleteButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
deleteButton.Parent = toolsPanel
Instance.new("UICorner", deleteButton).CornerRadius = UDim.new(0, 8)

deleteButton.MouseButton1Click:Connect(function()
    local count = DeleteAllSpawnedPets()
    deleteButton.Text = "✓ DELETED " .. count .. "!"
    task.wait(1)
    deleteButton.Text = "🗑️ Delete All Pets"
end)

local scaleLabel = Instance.new("TextLabel")
scaleLabel.Size = UDim2.new(1, 0, 0, 10)
scaleLabel.Position = UDim2.new(0, 0, 0, 52)
scaleLabel.BackgroundTransparency = 1
scaleLabel.Text = "📏 UI Scale (70% default)"
scaleLabel.Font = Enum.Font.Gotham
scaleLabel.TextSize = 7
scaleLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
scaleLabel.TextXAlignment = Enum.TextXAlignment.Left
scaleLabel.Parent = toolsPanel

local scaleControls = Instance.new("Frame")
scaleControls.Size = UDim2.new(1, 0, 0, 20)
scaleControls.Position = UDim2.new(0, 0, 0, 63)
scaleControls.BackgroundTransparency = 1
scaleControls.Parent = toolsPanel

local scaleDown = Instance.new("TextButton")
scaleDown.Size = UDim2.new(0.2, 0, 1, 0)
scaleDown.Position = UDim2.new(0, 0, 0, 0)
scaleDown.Text = "−"
scaleDown.Font = Enum.Font.GothamBold
scaleDown.TextSize = 12
scaleDown.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
scaleDown.TextColor3 = Color3.fromRGB(255, 255, 255)
scaleDown.Parent = scaleControls
Instance.new("UICorner", scaleDown).CornerRadius = UDim.new(0, 6)

local scaleValue = Instance.new("TextLabel")
scaleValue.Size = UDim2.new(0.5, 0, 1, 0)
scaleValue.Position = UDim2.new(0.25, 0, 0, 0)
scaleValue.BackgroundColor3 = Color3.fromRGB(32, 36, 58)
scaleValue.TextColor3 = Color3.fromRGB(240, 240, 255)
scaleValue.Text = "70%"
scaleValue.Font = Enum.Font.GothamBold
scaleValue.TextSize = 9
scaleValue.Parent = scaleControls
Instance.new("UICorner", scaleValue).CornerRadius = UDim.new(0, 6)

local scaleUp = Instance.new("TextButton")
scaleUp.Size = UDim2.new(0.2, 0, 1, 0)
scaleUp.Position = UDim2.new(0.8, 0, 0, 0)
scaleUp.Text = "+"
scaleUp.Font = Enum.Font.GothamBold
scaleUp.TextSize = 12
scaleUp.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
scaleUp.TextColor3 = Color3.fromRGB(255, 255, 255)
scaleUp.Parent = scaleControls
Instance.new("UICorner", scaleUp).CornerRadius = UDim.new(0, 6)

local resetScale = Instance.new("TextButton")
resetScale.Size = UDim2.new(1, 0, 0, 20)
resetScale.Position = UDim2.new(0, 0, 0, 88)
resetScale.Text = "↪️ Reset to 70%"
resetScale.Font = Enum.Font.GothamBold
resetScale.TextSize = 8
resetScale.BackgroundColor3 = Color3.fromRGB(100, 100, 180)
resetScale.TextColor3 = Color3.fromRGB(255, 255, 255)
resetScale.Parent = toolsPanel
Instance.new("UICorner", resetScale).CornerRadius = UDim.new(0, 6)

local lockButton = Instance.new("TextButton")
lockButton.Size = UDim2.new(1, 0, 0, 20)
lockButton.Position = UDim2.new(0, 0, 0, 113)
lockButton.Text = "🔓 Unlocked"
lockButton.Font = Enum.Font.GothamBold
lockButton.TextSize = 8
lockButton.BackgroundColor3 = Color3.fromRGB(150, 150, 50)
lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lockButton.Parent = toolsPanel
Instance.new("UICorner", lockButton).CornerRadius = UDim.new(0, 6)

local currentScale = 0.7

scaleDown.MouseButton1Click:Connect(function()
    currentScale = math.max(0.5, currentScale - 0.1)
    uiScale.Scale = currentScale
    scaleValue.Text = math.floor(currentScale * 100) .. "%"
end)

scaleUp.MouseButton1Click:Connect(function()
    currentScale = math.min(2.0, currentScale + 0.1)
    uiScale.Scale = currentScale
    scaleValue.Text = math.floor(currentScale * 100) .. "%"
end)

resetScale.MouseButton1Click:Connect(function()
    currentScale = 0.7
    uiScale.Scale = currentScale
    scaleValue.Text = "70%"
end)

local uiLocked = false
lockButton.MouseButton1Click:Connect(function()
    uiLocked = not uiLocked
    if uiLocked then
        lockButton.Text = "🔒 Locked"
        lockButton.BackgroundColor3 = Color3.fromRGB(50, 150, 150)
    else
        lockButton.Text = "🔓 Unlocked"
        lockButton.BackgroundColor3 = Color3.fromRGB(150, 150, 50)
    end
end)

local dragging = false
local dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
    if not uiLocked and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if not uiLocked and dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

tabElements.Spawn.button.MouseButton1Click:Connect(function()
    SwitchTab('Spawn')
end)

tabElements.Tools.button.MouseButton1Click:Connect(function()
    SwitchTab('Tools')
end)

spawnButton.MouseButton1Click:Connect(function()
    local petName = nameInput.Text
    if petName == "" then return end
    
    local petId = FindPetId(petName)
    if not petId then return end
    
    local ageMap = {1, 2, 3, 4, 5, 6}
    local options = {
        mega_neon = flagState["M"],
        neon = flagState["N"],
        flyable = flagState["F"],
        rideable = flagState["R"],
        age = ageMap[currentAge],
        trick_level = 5,
        ailments_completed = 0,
        rp_name = GenerateUniquePetName()
    }
    
    local item = CreateInventoryItem(petId, "pets", options)
    if item then
        spawnButton.Text = "✓ SPAWNED!"
        task.wait(0.5)
        spawnButton.Text = "✨ SPAWN PET"
    end
end)

spawnAllButton.MouseButton1Click:Connect(function()
    local ageMap = {1, 2, 3, 4, 5, 6}
    local options = {
        mega_neon = flagState["M"],
        neon = flagState["N"],
        flyable = flagState["F"],
        rideable = flagState["R"],
        age = ageMap[currentAge],
        trick_level = 5,
        ailments_completed = 0
    }
    
    local successCount = 0
    spawnAllButton.Text = "⚡ SPAWNING..."
    
    for _, petName in ipairs(HighTierPets) do
        local petId = FindPetId(petName)
        if petId then
            local petOptions = table.clone(options)
            petOptions.rp_name = GenerateUniquePetName()
            
            local item = CreateInventoryItem(petId, "pets", petOptions)
            if item then
                successCount = successCount + 1
            end
        end
    end
    
    spawnAllButton.Text = "✓ SPAWNED " .. successCount .. "!"
    task.wait(1.5)
    spawnAllButton.Text = "👑 SPAWN ALL HIGH TIERS"
end)

nameInput:GetPropertyChangedSignal("Text"):Connect(function()
    local text = nameInput.Text
    if text == "" then
        inputGlow.Color = glowColors.neutral
        return
    end
    
    local isValid = FindPetId(text) ~= nil
    inputGlow.Color = isValid and glowColors.valid or glowColors.invalid
end)

print("DC : 0ksam — credits to m0_3a for base functions")

-- ══════════════════════════════════════════════
--  FORWARD DECLARE NEW PANELS (used by SwitchTab)
-- ══════════════════════════════════════════════
local wearsPanel   = Instance.new("Frame")
wearsPanel.Size    = UDim2.new(0.94, 0, 1, -48)
wearsPanel.Position = UDim2.new(0.03, 0, 0, 46)
wearsPanel.BackgroundTransparency = 1
wearsPanel.Visible = false
wearsPanel.Parent  = mainFrame

local coloursPanel  = Instance.new("Frame")
coloursPanel.Size   = UDim2.new(0.94, 0, 1, -48)
coloursPanel.Position = UDim2.new(0.03, 0, 0, 46)
coloursPanel.BackgroundTransparency = 1
coloursPanel.Visible = false
coloursPanel.Parent  = mainFrame

local tricksPanel  = Instance.new("Frame")
tricksPanel.Size   = UDim2.new(0.94, 0, 1, -48)
tricksPanel.Position = UDim2.new(0.03, 0, 0, 46)
tricksPanel.BackgroundTransparency = 1
tricksPanel.Visible = false
tricksPanel.Parent  = mainFrame

-- wire up new tab buttons
tabElements.Wears.button.MouseButton1Click:Connect(function()   SwitchTab('Wears')   end)
tabElements.Colours.button.MouseButton1Click:Connect(function() SwitchTab('Colours') end)
tabElements.Tricks.button.MouseButton1Click:Connect(function()  SwitchTab('Tricks')  end)

-- ══════════════════════════════════════════════
--  HELPER: get the equipped pet model from wrappers
-- ══════════════════════════════════════════════
local function GetEquippedPetModel()
    local Fsys2 = require(game.ReplicatedStorage:WaitForChild("Fsys"))
    local clientData2 = Fsys2.load("ClientData")
    local wrappers = clientData2.get("pet_char_wrappers")
    if not wrappers or #wrappers == 0 then return nil end
    local m = wrappers[#wrappers].char
    if m and m:IsDescendantOf(workspace) then return m end
    return nil
end

-- ══════════════════════════════════════════════
--  PET WEARS PANEL
-- ══════════════════════════════════════════════
local wearsTitle = Instance.new("TextLabel")
wearsTitle.Size = UDim2.new(1, 0, 0, 14)
wearsTitle.Position = UDim2.new(0, 0, 0, 0)
wearsTitle.BackgroundTransparency = 1
wearsTitle.Text = "🪽 Pet Wears"
wearsTitle.Font = Enum.Font.GothamBold
wearsTitle.TextSize = 10
wearsTitle.TextColor3 = Color3.fromRGB(220, 180, 255)
wearsTitle.TextXAlignment = Enum.TextXAlignment.Left
wearsTitle.Parent = wearsPanel

local wearNameLabel = Instance.new("TextLabel")
wearNameLabel.Size = UDim2.new(1, 0, 0, 10)
wearNameLabel.Position = UDim2.new(0, 0, 0, 17)
wearNameLabel.BackgroundTransparency = 1
wearNameLabel.Text = "Accessory Name"
wearNameLabel.Font = Enum.Font.Gotham
wearNameLabel.TextSize = 8
wearNameLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
wearNameLabel.TextXAlignment = Enum.TextXAlignment.Left
wearNameLabel.Parent = wearsPanel

local wearInput = Instance.new("TextBox")
wearInput.Size = UDim2.new(1, 0, 0, 22)
wearInput.Position = UDim2.new(0, 0, 0, 28)
wearInput.BackgroundColor3 = Color3.fromRGB(32, 36, 58)
wearInput.TextColor3 = Color3.fromRGB(240, 240, 255)
wearInput.TextSize = 11
wearInput.Font = Enum.Font.Gotham
wearInput.PlaceholderText = "Enter accessory name..."
wearInput.PlaceholderColor3 = Color3.fromRGB(140, 150, 180)
wearInput.ClearTextOnFocus = false
wearInput.Text = ""
wearInput.Parent = wearsPanel
Instance.new("UICorner", wearInput).CornerRadius = UDim.new(0, 8)
local wearInputStroke = Instance.new("UIStroke")
wearInputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
wearInputStroke.Color = Color3.fromRGB(220, 180, 255)
wearInputStroke.Thickness = 1.5
wearInputStroke.Transparency = 0.3
wearInputStroke.Parent = wearInput

local addWearBtn = Instance.new("TextButton")
addWearBtn.Size = UDim2.new(1, 0, 0, 24)
addWearBtn.Position = UDim2.new(0, 0, 0, 54)
addWearBtn.Text = "✦ Add Pet Wear"
addWearBtn.Font = Enum.Font.GothamBold
addWearBtn.TextSize = 10
addWearBtn.BackgroundColor3 = Color3.fromRGB(130, 60, 200)
addWearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addWearBtn.Parent = wearsPanel
Instance.new("UICorner", addWearBtn).CornerRadius = UDim.new(0, 8)
local addWearStroke = Instance.new("UIStroke")
addWearStroke.Color = Color3.fromRGB(220, 180, 255)
addWearStroke.Thickness = 1.5
addWearStroke.Transparency = 0.2
addWearStroke.Parent = addWearBtn

local PREPPY_WEARS = { "Unicorn Horn", "Pink Cat Ear Headphones", "Rainbow Maker", "2022 Birthday Cupcake Shoes" }

local preppyWearBtn = Instance.new("TextButton")
preppyWearBtn.Size = UDim2.new(1, 0, 0, 24)
preppyWearBtn.Position = UDim2.new(0, 0, 0, 82)
preppyWearBtn.Text = "🎀 Add Preppy Pet Wear"
preppyWearBtn.Font = Enum.Font.GothamBold
preppyWearBtn.TextSize = 10
preppyWearBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 160)
preppyWearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
preppyWearBtn.Parent = wearsPanel
Instance.new("UICorner", preppyWearBtn).CornerRadius = UDim.new(0, 8)
local preppyWearStroke = Instance.new("UIStroke")
preppyWearStroke.Color = Color3.fromRGB(255, 180, 220)
preppyWearStroke.Thickness = 1.5
preppyWearStroke.Transparency = 0.2
preppyWearStroke.Parent = preppyWearBtn

local function GetPetWearByName(name)
    local Fsys2 = require(game.ReplicatedStorage:WaitForChild("Fsys"))
    local IDB2 = Fsys2.load("InventoryDB")
    for id, v in pairs(IDB2.pet_accessories or {}) do
        if v.name and v.name:lower() == name:lower() then return id end
    end
    return nil
end

local function EquipWearOnPet(wearId)
    local Fsys2 = require(game.ReplicatedStorage:WaitForChild("Fsys"))
    local IDB2 = Fsys2.load("InventoryDB")
    local dl = Fsys2.load("DownloadClient")
    local helper = Fsys2.load("PetAccessoryEquipHelper")
    local wearEntry = IDB2.pet_accessories and IDB2.pet_accessories[wearId]
    if not wearEntry then
        game.StarterGui:SetCore("SendNotification", {Title="Not Found", Text="Wear entry missing.", Duration=3})
        return
    end
    local petModel = GetEquippedPetModel()
    if not petModel then
        game.StarterGui:SetCore("SendNotification", {Title="No Pet", Text="Equip a pet first!", Duration=3})
        return
    end
    task.spawn(function()
        local ok, asset = pcall(function()
            return dl.promise_download_copy("PetAvatarResources", wearEntry.model_handle):expect()
        end)
        if not ok or not asset then
            game.StarterGui:SetCore("SendNotification", {Title="Download Failed", Text="Could not load accessory model.", Duration=4})
            return
        end
        local ok2, _ = pcall(function()
            helper.equip_accessory({
                pet_model = petModel,
                accessory_base_asset = asset,
                accessory_item_entry = wearEntry,
                play_poof_effect = true,
                is_mannequin = false,
            })
        end)
        if ok2 then
            game.StarterGui:SetCore("SendNotification", {Title="🪽 Equipped!", Text=(wearEntry.name or wearId).." equipped!", Duration=3})
        else
            game.StarterGui:SetCore("SendNotification", {Title="Equip Failed", Text="Check console.", Duration=3})
        end
    end)
end

addWearBtn.MouseButton1Click:Connect(function()
    local name = wearInput.Text
    if name == "" then
        game.StarterGui:SetCore("SendNotification", {Title="Error", Text="Enter an accessory name!", Duration=3})
        return
    end
    local id = GetPetWearByName(name)
    if id then
        EquipWearOnPet(id)
    else
        game.StarterGui:SetCore("SendNotification", {Title="Not Found", Text='"'..name..'" not found.', Duration=4})
    end
end)

preppyWearBtn.MouseButton1Click:Connect(function()
    local added = 0
    for _, wName in ipairs(PREPPY_WEARS) do
        local id = GetPetWearByName(wName)
        if id then EquipWearOnPet(id); added = added + 1 end
    end
    game.StarterGui:SetCore("SendNotification", {
        Title = "🎀 Preppy Wear!",
        Text = added .. " accessory(ies) equipped.",
        Duration = 4,
    })
end)

-- ══════════════════════════════════════════════
--  COLOURS PANEL
-- ══════════════════════════════════════════════
local coloursTitle = Instance.new("TextLabel")
coloursTitle.Size = UDim2.new(1, 0, 0, 14)
coloursTitle.Position = UDim2.new(0, 0, 0, 0)
coloursTitle.BackgroundTransparency = 1
coloursTitle.Text = "🖌️ Pet Colours"
coloursTitle.Font = Enum.Font.GothamBold
coloursTitle.TextSize = 10
coloursTitle.TextColor3 = Color3.fromRGB(180, 220, 255)
coloursTitle.TextXAlignment = Enum.TextXAlignment.Left
coloursTitle.Parent = coloursPanel

local hexLabel = Instance.new("TextLabel")
hexLabel.Size = UDim2.new(1, 0, 0, 10)
hexLabel.Position = UDim2.new(0, 0, 0, 17)
hexLabel.BackgroundTransparency = 1
hexLabel.Text = "Hex Colour (e.g. FF90C8)"
hexLabel.Font = Enum.Font.Gotham
hexLabel.TextSize = 8
hexLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
hexLabel.TextXAlignment = Enum.TextXAlignment.Left
hexLabel.Parent = coloursPanel

local hexInput = Instance.new("TextBox")
hexInput.Size = UDim2.new(1, 0, 0, 22)
hexInput.Position = UDim2.new(0, 0, 0, 28)
hexInput.BackgroundColor3 = Color3.fromRGB(32, 36, 58)
hexInput.TextColor3 = Color3.fromRGB(240, 240, 255)
hexInput.TextSize = 11
hexInput.Font = Enum.Font.Gotham
hexInput.PlaceholderText = "FF90C8"
hexInput.PlaceholderColor3 = Color3.fromRGB(140, 150, 180)
hexInput.ClearTextOnFocus = false
hexInput.Text = ""
hexInput.Parent = coloursPanel
Instance.new("UICorner", hexInput).CornerRadius = UDim.new(0, 8)
local hexGlow = Instance.new("UIStroke")
hexGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
hexGlow.Color = Color3.fromRGB(255, 180, 220)
hexGlow.Thickness = 1.5
hexGlow.Transparency = 0.3
hexGlow.Parent = hexInput

local function HexToColor3(hex)
    hex = hex:gsub("^#", ""):gsub("%s+", "")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1,2), 16)
    local g = tonumber(hex:sub(3,4), 16)
    local b = tonumber(hex:sub(5,6), 16)
    if not r or not g or not b then return nil end
    return Color3.fromRGB(r, g, b)
end

hexInput:GetPropertyChangedSignal("Text"):Connect(function()
    local col = HexToColor3(hexInput.Text)
    local target = col and Color3.fromRGB(120, 255, 150)
        or (hexInput.Text == "" and Color3.fromRGB(255, 180, 220) or Color3.fromRGB(255, 100, 100))
    TweenService:Create(hexGlow, TweenInfo.new(0.3), {Color = target}):Play()
end)

local savedEyeColours = {}
local function SnapshotEyes(root)
    savedEyeColours = {}
    local eyeKws = {"eye","pupil","iris","cornea","sclera","eyelid","eyelash","eyebrow","retina","lens","highlight","gloss","shine","spec"}
    for _, part in ipairs(root:GetDescendants()) do
        if part:IsA("BasePart") then
            local nm = part.Name:lower()
            local isEye = false
            for _, kw in ipairs(eyeKws) do
                if nm:find(kw) then isEye = true; break end
            end
            local sz = part.Size
            local small = sz.X < 0.15 and sz.Y < 0.15 and sz.Z < 0.15
            local c = part.Color
            local br = (c.R + c.G + c.B) / 3
            local isSat = math.abs(c.R-c.G) > 0.15 or math.abs(c.G-c.B) > 0.15 or math.abs(c.R-c.B) > 0.15
            if isEye or (small and (br < 0.12 or (br > 0.88 and not isSat))) then
                savedEyeColours[part] = part.Color
            end
        end
    end
end

local function ApplyColourToPet(targetColor)
    local petModel = GetEquippedPetModel()
    if not petModel then
        game.StarterGui:SetCore("SendNotification", {Title="No Pet", Text="Equip a pet first!", Duration=3})
        return 0
    end
    local root = petModel:FindFirstChild("PetModel") or petModel
    SnapshotEyes(root)
    local count = 0
    for _, part in ipairs(root:GetDescendants()) do
        if part:IsA("BasePart") and part.Material ~= Enum.Material.Neon then
            if not savedEyeColours[part] then
                part.Color = targetColor
                count = count + 1
            end
        end
    end
    for part, orig in pairs(savedEyeColours) do
        if part and part.Parent then part.Color = orig end
    end
    return count
end

local changeColourBtn = Instance.new("TextButton")
changeColourBtn.Size = UDim2.new(1, 0, 0, 24)
changeColourBtn.Position = UDim2.new(0, 0, 0, 54)
changeColourBtn.Text = "🖌️ Apply Colour"
changeColourBtn.Font = Enum.Font.GothamBold
changeColourBtn.TextSize = 10
changeColourBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 180)
changeColourBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
changeColourBtn.Parent = coloursPanel
Instance.new("UICorner", changeColourBtn).CornerRadius = UDim.new(0, 8)
local changeColourStroke = Instance.new("UIStroke")
changeColourStroke.Color = Color3.fromRGB(180, 140, 255)
changeColourStroke.Thickness = 1.5
changeColourStroke.Transparency = 0.2
changeColourStroke.Parent = changeColourBtn

changeColourBtn.MouseButton1Click:Connect(function()
    local col = HexToColor3(hexInput.Text)
    if not col then
        game.StarterGui:SetCore("SendNotification", {Title="Invalid Hex", Text="Enter a valid 6-digit hex e.g. FF90C8", Duration=3})
        return
    end
    local n = ApplyColourToPet(col)
    if n > 0 then
        game.StarterGui:SetCore("SendNotification", {Title="🖌️ Colour Applied!", Text="#"..hexInput.Text:gsub("^#",""):upper().." on "..n.." parts.", Duration=4})
    end
end)

local preppyColourBtn = Instance.new("TextButton")
preppyColourBtn.Size = UDim2.new(1, 0, 0, 24)
preppyColourBtn.Position = UDim2.new(0, 0, 0, 82)
preppyColourBtn.Text = "🎀 Colour Preppy (#FF90C8)"
preppyColourBtn.Font = Enum.Font.GothamBold
preppyColourBtn.TextSize = 10
preppyColourBtn.BackgroundColor3 = Color3.fromRGB(255, 130, 180)
preppyColourBtn.TextColor3 = Color3.fromRGB(80, 20, 50)
preppyColourBtn.Parent = coloursPanel
Instance.new("UICorner", preppyColourBtn).CornerRadius = UDim.new(0, 8)
local preppyColourStroke = Instance.new("UIStroke")
preppyColourStroke.Color = Color3.fromRGB(255, 200, 230)
preppyColourStroke.Thickness = 1.5
preppyColourStroke.Transparency = 0.2
preppyColourStroke.Parent = preppyColourBtn

preppyColourBtn.MouseButton1Click:Connect(function()
    local n = ApplyColourToPet(Color3.fromRGB(255, 144, 200))
    if n > 0 then
        game.StarterGui:SetCore("SendNotification", {Title="🎀 Preppy!", Text="#FF90C8 applied to "..n.." parts.", Duration=4})
    end
end)

-- ══════════════════════════════════════════════
--  TRICKS PANEL
-- ══════════════════════════════════════════════
local tricksTitle = Instance.new("TextLabel")
tricksTitle.Size = UDim2.new(0.6, 0, 0, 14)
tricksTitle.Position = UDim2.new(0, 0, 0, 0)
tricksTitle.BackgroundTransparency = 1
tricksTitle.Text = "🎪 Pet Tricks"
tricksTitle.Font = Enum.Font.GothamBold
tricksTitle.TextSize = 10
tricksTitle.TextColor3 = Color3.fromRGB(180, 160, 255)
tricksTitle.TextXAlignment = Enum.TextXAlignment.Left
tricksTitle.Parent = tricksPanel

local unlockAllBtn = Instance.new("TextButton")
unlockAllBtn.Size = UDim2.new(0.55, 0, 0, 14)
unlockAllBtn.Position = UDim2.new(0.45, 0, 0, 0)
unlockAllBtn.Text = "🔓 Unlock All"
unlockAllBtn.Font = Enum.Font.GothamBold
unlockAllBtn.TextSize = 8
unlockAllBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 60)
unlockAllBtn.TextColor3 = Color3.fromRGB(180, 255, 200)
unlockAllBtn.Parent = tricksPanel
Instance.new("UICorner", unlockAllBtn).CornerRadius = UDim.new(0, 5)
local unlockStroke = Instance.new("UIStroke")
unlockStroke.Color = Color3.fromRGB(100, 255, 150)
unlockStroke.Thickness = 1
unlockStroke.Transparency = 0.2
unlockStroke.Parent = unlockAllBtn

local refreshTricksBtn = Instance.new("TextButton")
refreshTricksBtn.Size = UDim2.new(0, 18, 0, 14)
refreshTricksBtn.Position = UDim2.new(1, -18, 0, 0)
refreshTricksBtn.Text = "↻"
refreshTricksBtn.Font = Enum.Font.GothamBold
refreshTricksBtn.TextSize = 10
refreshTricksBtn.BackgroundColor3 = Color3.fromRGB(50, 40, 80)
refreshTricksBtn.TextColor3 = Color3.fromRGB(180, 150, 255)
refreshTricksBtn.Parent = tricksPanel
Instance.new("UICorner", refreshTricksBtn).CornerRadius = UDim.new(0, 5)

local trickScroll = Instance.new("ScrollingFrame")
trickScroll.Size = UDim2.new(1, 0, 1, -18)
trickScroll.Position = UDim2.new(0, 0, 0, 18)
trickScroll.BackgroundColor3 = Color3.fromRGB(22, 24, 36)
trickScroll.BackgroundTransparency = 0.3
trickScroll.BorderSizePixel = 0
trickScroll.ScrollBarThickness = 4
trickScroll.ScrollBarImageColor3 = Color3.fromRGB(120, 80, 200)
trickScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
trickScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
trickScroll.Parent = tricksPanel
Instance.new("UICorner", trickScroll).CornerRadius = UDim.new(0, 8)
local trickScrollStroke = Instance.new("UIStroke")
trickScrollStroke.Color = Color3.fromRGB(100, 70, 160)
trickScrollStroke.Thickness = 1.2
trickScrollStroke.Transparency = 0.3
trickScrollStroke.Parent = trickScroll
local trickLayout = Instance.new("UIListLayout")
trickLayout.SortOrder = Enum.SortOrder.LayoutOrder
trickLayout.Padding = UDim.new(0, 3)
trickLayout.Parent = trickScroll
local trickPad = Instance.new("UIPadding")
trickPad.PaddingTop = UDim.new(0, 4)
trickPad.PaddingLeft = UDim.new(0, 4)
trickPad.PaddingRight = UDim.new(0, 4)
trickPad.Parent = trickScroll

local noTrickLabel = Instance.new("TextLabel")
noTrickLabel.Size = UDim2.new(1, 0, 0, 36)
noTrickLabel.BackgroundTransparency = 1
noTrickLabel.Text = "Equip a pet to see tricks!"
noTrickLabel.Font = Enum.Font.Gotham
noTrickLabel.TextSize = 10
noTrickLabel.TextColor3 = Color3.fromRGB(160, 160, 200)
noTrickLabel.TextXAlignment = Enum.TextXAlignment.Center
noTrickLabel.LayoutOrder = 1
noTrickLabel.Parent = trickScroll

-- ── Tricks logic ──
local PetEntityManager = nil
local AnimationManager2 = nil
pcall(function()
    local Fsys2 = require(game.ReplicatedStorage:WaitForChild("Fsys"))
    PetEntityManager = Fsys2.load("PetEntityManager")
    AnimationManager2 = Fsys2.load("AnimationManager")
end)

-- Track which trick is currently playing so we can toggle it off
local activeTrickTrack = nil
local activeTrickName  = nil

local function DoTrick(animName, btn)
    if not PetEntityManager or not AnimationManager2 then return false end
    local entities = PetEntityManager.get_local_owned_pet_entities()
    if not entities or #entities == 0 then
        game.StarterGui:SetCore("SendNotification", {Title="No Pet", Text="Equip a pet first!", Duration=3})
        return false
    end
    local entity = entities[#entities]
    local petModel = entity.base.pet_model
    if not petModel then return false end
    if not AnimationManager2.animations[animName] then return false end

    -- If this trick is already playing → stop it
    if activeTrickName == animName and activeTrickTrack then
        activeTrickTrack:Stop(0.2)
        activeTrickTrack = nil
        activeTrickName  = nil
        if btn then
            btn.BackgroundColor3 = Color3.fromRGB(50, 40, 75)
            btn.TextColor3 = Color3.fromRGB(210, 180, 255)
        end
        return true
    end

    -- Stop any currently playing trick first
    if activeTrickTrack then
        activeTrickTrack:Stop(0.1)
        activeTrickTrack = nil
    end
    -- Reset all trick buttons to default colour
    for _, child in ipairs(trickScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 = Color3.fromRGB(50, 40, 75)
            child.TextColor3 = Color3.fromRGB(210, 180, 255)
        end
    end

    local animator = (entity.shared_cache and entity.shared_cache.Animator)
        or petModel:FindFirstChildWhichIsA("Animator", true)
    if not animator then
        local ac = petModel:FindFirstChildOfClass("AnimationController")
        if not ac then ac = Instance.new("AnimationController"); ac.Parent = petModel end
        animator = ac:FindFirstChildOfClass("Animator")
        if not animator then animator = Instance.new("Animator"); animator.Parent = ac end
    end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local n = track.Name:lower()
        if n:find("trick") or n:find("rollover") or n:find("dance") or n:find("backflip") then
            track:Stop(0.1)
        end
    end
    local track = animator:LoadAnimation(AnimationManager2.get_track(animName))
    track:Play()
    activeTrickTrack = track
    activeTrickName  = animName
    -- Highlight active button
    if btn then
        btn.BackgroundColor3 = Color3.fromRGB(80, 55, 130)
        btn.TextColor3 = Color3.fromRGB(255, 230, 100)
    end
    -- Auto-clear when animation ends
    track.Stopped:Connect(function()
        if activeTrickName == animName then
            activeTrickTrack = nil
            activeTrickName  = nil
            if btn and btn.Parent then
                btn.BackgroundColor3 = Color3.fromRGB(50, 40, 75)
                btn.TextColor3 = Color3.fromRGB(210, 180, 255)
            end
        end
    end)
    return true
end

local function UnlockAllTricks()
    if not PetEntityManager then return end
    local entities = PetEntityManager.get_local_owned_pet_entities()
    if not entities or #entities == 0 then return end
    local entity = entities[#entities]
    if entity.base.char_wrapper and entity.base.char_wrapper.pet_progression then
        entity.base.char_wrapper.pet_progression.age = 6
    end
    local uid = entity.base.char_wrapper and entity.base.char_wrapper.pet_unique
    if uid then
        pcall(function()
            local Fsys2 = require(game.ReplicatedStorage:WaitForChild("Fsys"))
            Fsys2.load("RouterClient").get("PetAPI/UpdatePetTrickLevel"):FireServer(uid)
        end)
    end
end

local function BuildTrickList()
    for _, c in ipairs(trickScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    activeTrickTrack = nil
    activeTrickName  = nil
    if not PetEntityManager or not AnimationManager2 then
        noTrickLabel.Text = "PetEntityManager not available."
        noTrickLabel.Visible = true
        return
    end
    local entities = PetEntityManager.get_local_owned_pet_entities()
    if not entities or #entities == 0 then
        noTrickLabel.Text = "Equip a pet to see tricks!"
        noTrickLabel.Visible = true
        return
    end
    local entity = entities[#entities]
    local tricks = entity.base.entry and entity.base.entry.tricks
    if not tricks or #tricks == 0 then
        noTrickLabel.Text = "This pet has no tricks!"
        noTrickLabel.Visible = true
        return
    end
    noTrickLabel.Visible = false
    local petName = entity.base.entry and entity.base.entry.name or "Pet"
    for i, trick in ipairs(tricks) do
        local trickName = trick[1]
        local animName  = trick[2]
        if AnimationManager2.animations[animName] then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 26)
            btn.BackgroundColor3 = Color3.fromRGB(50, 40, 75)
            btn.BackgroundTransparency = 0.1
            btn.Text = "✦  " .. trickName
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 10
            btn.TextColor3 = Color3.fromRGB(210, 180, 255)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.LayoutOrder = i + 1
            btn.Parent = trickScroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            local bStroke = Instance.new("UIStroke")
            bStroke.Color = Color3.fromRGB(130, 90, 200)
            bStroke.Thickness = 1
            bStroke.Transparency = 0.35
            bStroke.Parent = btn
            local bPad = Instance.new("UIPadding")
            bPad.PaddingLeft = UDim.new(0, 8)
            bPad.Parent = btn
            btn.MouseEnter:Connect(function()
                if activeTrickName ~= animName then
                    TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(70,55,110)}):Play()
                end
            end)
            btn.MouseLeave:Connect(function()
                if activeTrickName ~= animName then
                    TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(50,40,75)}):Play()
                end
            end)
            btn.MouseButton1Click:Connect(function()
                local ok = DoTrick(animName, btn)
                if ok and activeTrickName == animName then
                    game.StarterGui:SetCore("SendNotification", {
                        Title = "🎪 " .. trickName,
                        Text = petName .. " is performing: " .. trickName,
                        Duration = 2,
                    })
                end
            end)
        end
    end
end

unlockAllBtn.MouseButton1Click:Connect(function()
    UnlockAllTricks()
    game.StarterGui:SetCore("SendNotification", {Title="🔓 Unlocked!", Text="All tricks unlocked!", Duration=3})
    task.wait(0.5)
    BuildTrickList()
end)

refreshTricksBtn.MouseButton1Click:Connect(function() BuildTrickList() end)

tabElements.Tricks.button.MouseButton1Click:Connect(function()
    SwitchTab('Tricks')
    BuildTrickList()
end)

if PetEntityManager then
    pcall(function()
        PetEntityManager.get_local_owned_pet_entity_updated_signal():Connect(function()
            if tricksPanel.Visible then BuildTrickList() end
        end)
    end)
end
