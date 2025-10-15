local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

local Window = MacLib:Window({
	Title = "Exploit Window",
	Subtitle = "Hero Upgrade Exploit",
	Size = UDim2.fromOffset(400, 300),
	DragStyle = 1,
	DisabledWindowControls = {},
	ShowUserInfo = true,
	Keybind = Enum.KeyCode.RightControl,
	AcrylicBlur = true,
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

sections.MainSection:Button({
	Name = "Get Infinite Items",
	Callback = function()
		for i = 1, 1500 do
			local args = {
				[1] = "英雄升级";
				[2] = {
					["OnlyID"] = 1017;
					["CountVt"] = {
						[1] = 0;
					};
					["ItemVt"] = {
						[1] = i;
					};
				};
			};
			game:GetService("ReplicatedStorage"):WaitForChild("Msg", 9e9):WaitForChild("RemoteFunction", 9e9):InvokeServer(unpack(args))
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
