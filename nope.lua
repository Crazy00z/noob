local items = items or {} -- Items to target (empty means all items except specified)
local amount = amount or 10000 -- Amount to sell (script will use negative value)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Disable notification screen first
local player = Players.LocalPlayer
local notificationScreen = player.PlayerGui:WaitForChild("MainScreenFolder"):WaitForChild("NotificationScreen")
notificationScreen.Enabled = false

local sellRemote = ReplicatedStorage:WaitForChild("LobbyFolder"):WaitForChild("Remotes"):WaitForChild("Sell")
local senzuBeanUUID = nil
local foundUUIDs = {}

-- Function to find Senzu Bean UUID dynamically
local function findSenzuBeanUUID()
    local slotClass = ReplicatedStorage:FindFirstChild("MainSharedFolder")
    if slotClass then
        slotClass = slotClass:FindFirstChild("Classes")
        if slotClass then
            slotClass = slotClass:FindFirstChild("SlotClass")
            if slotClass then
                local success, data = pcall(require, slotClass)
                if success and data.Slots then
                    -- Search through ALL slots for Senzu Bean
                    for itemName, itemData in pairs(data.Slots) do
                        if itemData.Info and itemData.Info.GUID then
                            -- Check if Name exists and matches
                            if itemData.Info.Name and itemData.Info.Name == "Senzu Bean" then
                                print("✅ Found Senzu Bean with Name: " .. itemData.Info.GUID)
                                return itemData.Info.GUID
                            end
                            -- Also check DisplayName in case it's different
                            if itemData.Info.DisplayName and itemData.Info.DisplayName == "Senzu Bean" then
                                print("✅ Found Senzu Bean with DisplayName: " .. itemData.Info.GUID)
                                return itemData.Info.GUID
                            end
                            -- Check if the item key itself contains senzu
                            if string.find(string.lower(itemName), "senzu") then
                                print("✅ Found Senzu Bean by key name: " .. itemData.Info.GUID)
                                return itemData.Info.GUID
                            end
                        end
                    end
                    print("❌ Senzu Bean not found in any slots")
                end
            end
        end
    end
    return nil
end

-- Find Senzu Bean UUID dynamically
senzuBeanUUID = findSenzuBeanUUID()

-- Sell Senzu Bean with -1/0 first, then 1/0 if found
if senzuBeanUUID then
    print("🔥 Selling Senzu Bean with infinity...")
    -- First sell with -1/0
    local senzuArgs1 = {
        senzuBeanUUID,
        -1/0
    }
    sellRemote:FireServer(unpack(senzuArgs1))
    wait(0.5) -- Longer wait for infinity operations
    
    -- Then sell with 1/0
    local senzuArgs2 = {
        senzuBeanUUID,
        1/0
    }
    sellRemote:FireServer(unpack(senzuArgs2))
    wait(0.5)
    print("✅ Senzu Bean infinity sell complete!")
else
    print("⚠️ Senzu Bean not found, skipping infinity sell")
end

-- Collect other UUIDs
local slotClass = ReplicatedStorage:FindFirstChild("MainSharedFolder")
if slotClass then
    slotClass = slotClass:FindFirstChild("Classes")
    if slotClass then
        slotClass = slotClass:FindFirstChild("SlotClass")
        if slotClass then
            local success, data = pcall(require, slotClass)
            if success and data.Slots then
                -- Collect UUIDs based on items parameter
                if #items == 0 then
                    -- If no specific items listed, sell all except Senzu Bean
                    for itemName, itemData in pairs(data.Slots) do
                        if itemData.Info and itemData.Info.GUID then
                            if itemData.Info.GUID ~= senzuBeanUUID then -- Don't include Senzu Bean again
                                table.insert(foundUUIDs, itemData.Info.GUID)
                            end
                        end
                    end
                else
                    -- Only sell specified items
                    for itemName, itemData in pairs(data.Slots) do
                        if itemData.Info and itemData.Info.Name and itemData.Info.GUID then
                            for _, targetItem in ipairs(items) do
                                if itemData.Info.Name == targetItem and itemData.Info.GUID ~= senzuBeanUUID then
                                    table.insert(foundUUIDs, itemData.Info.GUID)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Remove duplicates from UUIDs
local uniqueUUIDs = {}
local seen = {}

for _, uuid in ipairs(foundUUIDs) do
    if not seen[uuid] then
        seen[uuid] = true
        table.insert(uniqueUUIDs, uuid)
    end
end

-- Sell items with negative amount
print("🔥 Selling " .. #uniqueUUIDs .. " items with amount: -" .. amount)
for i, uuid in ipairs(uniqueUUIDs) do
    local args = {
        uuid,
        -amount -- Use negative value
    }
    
    sellRemote:FireServer(unpack(args))
    wait(0.1)
end

print("✅ Script complete! Sold " .. #uniqueUUIDs .. " items with amount: -" .. amount)
