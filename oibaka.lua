local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

local player = game:GetService("Players").LocalPlayer
local equiped = player["装备"] -- 装备
local charIds = {}
local charIdOptions = {}

local equipSlot = equiped["1"]
if equipSlot and equipSlot:IsA("Instance") then
    for i = 1, 10 do -- assume up to 10 equipped units
        local unitInstance = equipSlot:FindFirstChild(tostring(i))
        if unitInstance then
            local id = unitInstance.Value
            table.insert(charIds, id)
            table.insert(charIdOptions, tostring(id))
        end
    end
end

local selectedCharId = charIds[1] 
local Window = MacLib:Window({
	Title = "hitlet is real",
	Subtitle = "we love hitler",
	Size = UDim2.fromOffset(900, 700),
	DragStyle = 2,
	DisabledWindowControls = {},
	ShowUserInfo = false,
	Keybind = Enum.KeyCode.RightControl,
	AcrylicBlur = false,
})

local tabGroups = {
	TabGroup1 = Window:TabGroup()
}

local tabs = {
	Main = tabGroups.TabGroup1:Tab({ Name = "Exploit", Image = "rbxassetid://18821914323" }),
}

local sections = {
	MainSection = tabs.Main:Section({ Side = "Left" }),
}

sections.MainSection:Dropdown({
	Name = "Select Character ID",
	Multi = false,
	Required = true,
	Options = charIdOptions,
	Default = 1,
	Callback = function(Value)
		selectedCharId = tonumber(Value) or 1017
		Window:Notify({
			Title = "Exploit",
			Description = "Selected Character ID: " .. selectedCharId,
			Lifetime = 3
		})
	end,
}, "CharDropdown")

sections.MainSection:Button({
	Name = "Get Infinite Items",
	Callback = function()
		for i = 1, 1500 do
			local args = {
				[1] = "英雄升级";
				[2] = {
					["OnlyID"] = selectedCharId;
					["CountVt"] = {
						[1] = 0/0;
					};
					["ItemVt"] = {
						[1] = i;
					};
				};
			};
			game:GetService("ReplicatedStorage"):WaitForChild("Msg", 9e9):WaitForChild("RemoteFunction", 9e9):InvokeServer(unpack(args))
			wait(0.1) -- add a small delay to avoid rate limiting
		end
		Window:Notify({
			Title = "Exploit",
			Description = "Infinite items attempt completed.",
			Lifetime = 5
		})
	end,
})

MacLib:SetFolder("Maclib")
tabs.Main:Select()
MacLib:LoadAutoLoadConfig()