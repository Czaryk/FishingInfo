_addon.author = "Czaryk"
_addon.name = "FishingInfo"
_addon.version = "2.0"

--> Services <--
require("common")

--> Variables <--
local DefaultConfig = {
	UI = {
		Font = "Arial",
		Size = 36,
		TextColor = 4294967295,
		BackgroundColor = 2147483648,
		Position = { 0, 0 },
	},
	Colors = {
		Green = "FF00FF00",
		Yellow = "FFFFFF00",
		Red = "FFFF0000",
		Brown = "FF745637",
	},
	Sounds = {
		Hook = { Enabled = true, File = "Hook.wav" },
		Fail = { Enabled = true, File = "Fail.wav" },
	},
}

local Config = DefaultConfig

local FishTypes = {
	["Small fish"] = { Text = "Something caught the hook!", Color = Config.Colors.Green, Sound = "Hook" },
	["Large fish"] = { Text = "Something caught the hook!!!", Color = Config.Colors.Yellow, Sound = "Hook" },
	["Item"] = { Text = "You feel something pulling at your line.", Color = Config.Colors.Brown, Sound = "Hook" },
	["Monster"] = { Text = "Something clamps onto your line ferociously!", Color = Config.Colors.Red, Sound = "Hook" },
	["Failed catch"] = { Text = "You didn't catch anything.", Color = Config.Colors.Red, Sound = "Fail" },
}

local FeelingTypes = {
	["Good feeling"] = { Text = "You have a good feeling about this one!", Color = Config.Colors.Green },
	["Bad feeling"] = { Text = "You have a bad feeling about this one.", Color = Config.Colors.Yellow },
	["Don't know if you have enough skill"] = {
		Text = "You don't know if you have enough skill to reel this one in.",
		Color = Config.Colors.Red,
	},
	["Fairly sure you don't have enough skill"] = {
		Text = "You're fairly sure you don't have enough skill to reel this one in.",
		Color = Config.Colors.Red,
	},
	["Epic catch"] = {
		Text = "This strength... You get the sense that you are on the verge of an epic catch!",
		Color = Config.Colors.Yellow,
	},
}

local CurrentFish = ""
local CurrentFishColor = ""
local CurrentFeeling = ""
local CurrentFeelingColor = ""

local Visible = false

--> Functions <--
--> Get the config and make the ui <--
local function Loaded()
	Config = ashita.settings.load_merged(_addon.path .. "Settings.json", Config)

	local UI = AshitaCore:GetFontManager():Create("FishingInfo_UI")
	UI:SetFontFamily(Config.UI.Font)
	UI:SetFontHeight(Config.UI.Size)
	UI:SetColor(Config.UI.TextColor)
	UI:GetBackground():SetColor(Config.UI.BackgroundColor)
	UI:SetPositionX(Config.UI.Position[1])
	UI:SetPositionY(Config.UI.Position[2])
	UI:SetText("")
	UI:SetVisibility(false)
	UI:GetBackground():SetVisibility(true)
	UI:SetBold(true)
end

--> Get the UI and it's position and save it + the settings then delete the UI <--
local function UnLoaded()
	local UI = AshitaCore:GetFontManager():Get("FishingInfo_UI")
	Config.UI.Position = { UI:GetPositionX(), UI:GetPositionY() }

	ashita.settings.save(_addon.path .. "Settings.json", Config)

	AshitaCore:GetFontManager():Delete("FishingInfo_UI")
end

--> Input commands <--
local function Commands(Cmd, NType)
	local Arguments = Cmd:args()
	local UI = AshitaCore:GetFontManager():Get("FishingInfo_UI")

	if #Arguments == 0 then
		return false
	end

	if Arguments[1]:lower() == "/fishinginfo" or Arguments[1]:lower() == "/fi" then
		if #Arguments == 1 then
			Visible = not Visible

			local Result

			if Visible == true then
				Result = "\30\02Enabled"
			else
				Result = "\30\68Disabled"
			end

			print(string.format("\31\200[\31\05FishingInfo\31\200] %s", Result))
		elseif Arguments[2]:lower() == "on" then
			Visible = true

			print(string.format("\31\200[\31\05FishingInfo\31\200] %s", "\30\02Enabled"))
		elseif Arguments[2]:lower() == "off" then
			Visible = false

			print(string.format("\31\200[\31\05FishingInfo\31\200] %s", "\30\68Disabled"))
		elseif Arguments[2]:lower() == "pos" then
			if #Arguments < 4 then
				local X = "X:" .. UI:GetPositionX()
				local Y = "Y:" .. UI:GetPositionY()

				print("\31\200[\31\05FishingInfo\31\200] \31\130Position: " .. X .. " " .. Y)
			elseif #Arguments == 4 then
				UI:SetPositionX(tonumber(Arguments[3]))
				UI:SetPositionY(tonumber(Arguments[4]))
			else
				print("\30\68Error Setting Postion")
			end
		elseif Arguments[2]:lower() == "help" then
			local Commands = {
				["/fi"] = "--Toggles on or off",
				["/fi on"] = "--Toggles on",
				["/fi off"] = "--Toggles off",
				["/fi pos"] = "--Prints current position",
				["/fi pos x y"] = "--Changes position to given numbers",
			}
			for Command, Description in pairs(Commands) do
				print(
					"\31\200[\31\05FishingInfo\31\200]\30\01 "
						.. "\30\68Syntax:\30\02 "
						.. Command
						.. "\30\71 "
						.. Description
				)
			end
		end
	end

	return false
end

--> Makes sure it exist and plays the sound (not made by me) <--
local function play_alert_sound(name)
	-- Ensure the main config table exists..
	if Config == nil or type(Config) ~= "table" then
		return false
	end

	-- Ensure the alerts table exists..
	local t = Config.Sounds
	if t == nil or type(t) ~= "table" then
		return false
	end

	-- Ensure the configuration table exists for the given name..
	t = t[name]
	if t == nil or type(t) ~= "table" then
		return false
	end

	-- Play the sound file..
	local fullpath = string.format("%s\\sounds\\%s", _addon.path, t.File)
	ashita.misc.play_sound(fullpath)
end

--> Checks the message's mode and then loop through the tables to set the fish and color and sound <--
local function IncomingText(Mode, Message, ModifiedMode, ModifiedMessage, Blocked)
	if Mode == 654 then
		for Fish, Info in pairs(FishTypes) do
			if Message:contains(Info.Text) then
				CurrentFish = Fish
				CurrentFishColor = Info.Color
				play_alert_sound(Info.Sound)
			end
		end

		for Feeling, Info in pairs(FeelingTypes) do
			if Message:contains(Info.Text) then
				CurrentFeeling = Feeling
				CurrentFeelingColor = Info.Color
			end
		end

		if Message:find("angler's") then
			local FirstHalf = Message:sub(63)
			local LastHalf = FirstHalf:gsub("[%p%d]+", "")
			CurrentFeeling = "Angler's Senses"
			CurrentFeelingColor = Config.Colors.Green
			CurrentFish = LastHalf
		end
	end
	return false
end

--> When user does /fish it resets the UI's text <--
local function OutgoingText(Mode, Message, ModifiedMode, ModifiedMessage, Blocked)
	if Mode == 1 or 2 and Message:contains("/fish") then
		CurrentFish = ""
		CurrentFeeling = ""
	end
	return false
end

--> Show the UI to the player <--
local function Render()
	local UI = AshitaCore:GetFontManager():Get("FishingInfo_UI")
	UI:SetVisibility(Visible)
	UI:SetText(string.format(
		[[Fish: |c%s|%s|r
Feeling: |c%s|%s|r]],
		CurrentFishColor,
		CurrentFish,
		CurrentFeelingColor,
		CurrentFeeling
	))
end

--> Events <--
ashita.register_event("load", Loaded)
ashita.register_event("unload", UnLoaded)
ashita.register_event("command", Commands)
ashita.register_event("incoming_text", IncomingText)
ashita.register_event("outgoing_text", OutgoingText)
ashita.register_event("render", Render)
