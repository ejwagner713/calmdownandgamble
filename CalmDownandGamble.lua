

-- Declare the new addon and load the libraries we want to use 
CalmDownandGamble = LibStub("AceAddon-3.0"):NewAddon("CalmDownandGamble", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "AceSerializer-3.0")
local CalmDownandGamble	= LibStub("AceAddon-3.0"):GetAddon("CalmDownandGamble")
local AceGUI = LibStub("AceGUI-3.0")

local DEBUG = false

-- Basic Adddon Initialization stuff, virtually inherited functions 
-- ================================================================ 

-- CONSTRUCTOR 
function CalmDownandGamble:OnInitialize()
	if DEBUG then self:Print("Load Begin") end

	-- Set up Infrastructure
	local defaults = {
	    global = {
			rankings = { },
			ban_list = { },
			chat_index = 1,
			game_mode_index = 1, 
			game_stage_index = 1,
			window_shown = false
		}
	}

    self.db = LibStub("AceDB-3.0"):New("CalmDownandGambleDB", defaults)
	self:ConstructUI()
	self:RegisterCallbacks()
	self:InitState()

	if DEBUG then self:Print("Load Complete!!") end
end

-- INIT FOR ENABLE  
function CalmDownandGamble:OnEnable()
end

-- DESTRUCTOR  
function CalmDownandGamble:OnDisable()
end


-- Initialization Helper Functions
-- ===========================================
function CalmDownandGamble:InitState()
	-- Chat Context -- 
	self.chat = {}
	self.game = {}
	self:SetChannelSettings()
	self:SetGameMode()
	self:ResetGameStage()
	
end

function CalmDownandGamble:SetChannelSettings() 

	self.chat.options = {
			{ label = "Raid"  , const = "RAID"  , addon_const = "RAID", callback = "CHAT_MSG_RAID"  , callback_leader = "CHAT_MSG_RAID_LEADER"  }, -- Index 1
			{ label = "Party" , const = "PARTY" , addon_const = "PARTY", callback = "CHAT_MSG_PARTY" , callback_leader = "CHAT_MSG_PARTY_LEADER" }, -- Index 2
			{ label = "Guild" , const = "GUILD" , addon_const = "GUILD", callback = "CHAT_MSG_GUILD" , callback_leader = nil },                     -- Index 3
			{ label = "Say"   , const = "SAY"   , addon_const = "GUILD", callback = "CHAT_MSG_SAY"   , callback_leader = nil },                     -- Index 4
	}	
	self.chat.channel_const = "RAID"   -- What the WoW API is looking for, CHANNEL for numeric channels
	
	if DEBUG then self:Print(self.chat.options[self.db.global.chat_index].label) end
	
	self.chat.channel_const = self.chat.options[self.db.global.chat_index].const
	self.chat.addon_const = self.chat.options[self.db.global.chat_index].addon_const
	self.ui.chat_channel:SetText(self.chat.options[self.db.global.chat_index].label)
	self.chat.channel_callback = self.chat.options[self.db.global.chat_index].callback
	self.chat.channel_callback_leader = self.chat.options[self.db.global.chat_index].callback_leader

end

function CalmDownandGamble:SetGameMode() 

	self.game.options = {
			{ label = "High-Low",  evaluate = function() self:HighLow() end, init = function() self:DefaultGameInit() end }, -- Index 1
			{ label = "Inverse",   evaluate = function() self:Inverse() end, init = function() self:DefaultGameInit() end }, -- Index 2
			{ label = "MiddleMan", evaluate = function() self:Median() end,  init = function() self:DefaultGameInit() end }, -- Index 3
			{ label = "Yahtzee",   evaluate = function() self:Yahtzee() end, init = function() self:YahtzeeInit() end },     -- Index 4
			{ label = "BigTWOS",   evaluate = function() self:Twos() end, init = function() self:TwosInit() end },     -- Index 5
	}	
	
	if DEBUG then self:Print(self.game.options[self.db.global.game_mode_index].label) end
	self.ui.game_mode:SetText(self.game.options[self.db.global.game_mode_index].label)

end

function CalmDownandGamble:ResetGameStage() 
	self.db.global.game_stage_index = 1
	self:SetGameStage()
end

function CalmDownandGamble:SetGameStage() 

	self.game.stages = {
			{ label = "New Game",  callback = function() self:StartGame() end }, -- Index 1
			{ label = "Last Call!",   callback = function() self:LastCall() end }, -- Index 2
			{ label = "Start Rolls!", callback = function() self:StartRolls() end }, -- Index 3
			{ label = "Roll Status", callback = function() self:RollStatus() end }, -- Index 4
	}	
	
	if DEBUG then self:Print(self.game.stages[self.db.global.game_stage_index].label) end
	self.ui.game_stage:SetText(self.game.stages[self.db.global.game_stage_index].label)

end

-- Slash Command Setup and Calls
-- =========================================================
function CalmDownandGamble:RegisterCallbacks()
	-- Register Some Slash Commands
	self:RegisterChatCommand("cdgm", "ShowUI")
	self:RegisterChatCommand("cdghide", "HideUI")
	self:RegisterChatCommand("cdgreset", "ResetStats")
	self:RegisterChatCommand("cdgdebug", "SetDebug")
	self:RegisterChatCommand("cdgban", "BanPlayer")
	self:RegisterChatCommand("cdgunban", "UnbanPlayer")
	self:RegisterChatCommand("cdgbanreset", "ResetBans")
	
	-- UNIT TESTING -- 
	self:RegisterChatCommand("cdgTESTA", "TESTA")
	self:RegisterChatCommand("cdgTESTB", "TESTB")
	self:RegisterChatCommand("cdgTESTC", "TESTC")
	-- self:RegisterComm("CDG_NEW_GAME", "NewGameCallback")
    -- self:RegisterComm("CDG_NEW_ROLL", "NewRollsCallback")
    -- self:RegisterComm("CDG_END_GAME", "GameResultsCallback")
end


function CalmDownandGamble:TESTA()
	
	self.current_game.player_rolls.Metafuzz = 2
	self.current_game.player_rolls.PlayerA = 1
	self.current_game.player_rolls.PlayerB = 1
	self.current_game.player_rolls.PlayerC = 1
	self:CheckRollsComplete()

end

function CalmDownandGamble:TESTB()

	self.current_game.player_rolls.PlayerA = 1
	self.current_game.player_rolls.PlayerB = 1
	self.current_game.player_rolls.PlayerC = 1
	self:CheckRollsComplete()

end

function CalmDownandGamble:TESTC()
	
	self.current_game.player_rolls.PlayerA = 2
	self.current_game.player_rolls.PlayerB = 2
	self.current_game.player_rolls.PlayerC = 1
	self:CheckRollsComplete()

end


function CalmDownandGamble:SetDebug()
	DEBUG = not DEBUG
end

function CalmDownandGamble:BanPlayer(player, editbox)
	self.db.global.ban_list[player] = true
end

function CalmDownandGamble:UnbanPlayer(player, editbox)
	self.db.global.ban_list[player] = nil
end

function CalmDownandGamble:ResetBans()
	self.db.global.ban_list = {}
end

function CalmDownandGamble:ShowUI()
	self.ui.CDG_Frame:Show()
	self.db.global.window_shown = true
end

function CalmDownandGamble:HideUI()
	self.ui.CDG_Frame:Hide()
	self.db.global.window_shown = false
end

function CalmDownandGamble:ResetStats()
	self.db.global.rankings = {}
end


-- Game State Machine 
-- ================================================

-- (1) Game will always start here in start game
function CalmDownandGamble:StartGame()
	-- Init our game
	self.current_game = {
		accepting_players = true,
		accepting_rolls = false,
		high_tiebreaker = false,
		low_tiebreaker = false,
		winner = nil,
		loser = nil,
		winning_roll = nil,
		losing_roll = nil,
		high_roller_playoff = {},
		low_roller_playoff = {},
		player_rolls = {}
	}
	
	self.game.options[self.db.global.game_mode_index].init()
	
	-- Register game callbacks
	-- TODO: Only in non-group channels self:RegisterComm("CDG_ROLL_DICE", "RollCallback")
	self:RegisterEvent("CHAT_MSG_SYSTEM", function(...) self:RollCallback(...) end)
	self:RegisterEvent(self.chat.channel_callback, function(...) self:ChatChannelCallback(...) end)
	if (self.chat.channel_callback_leader) then
		self:RegisterEvent(self.chat.channel_callback_leader, function(...) self:ChatChannelCallback(...) end)
	end
	
	if DEBUG then self:Print("Init'd game state and registered callbacks") end
	
	local player_name, realm_name = UnitName("player")
	local welcome_msg = "CDG is now in session! Mode: "..self.game.options[self.db.global.game_mode_index].label..", Bet: "..self.current_game.gold_amount.." gold"

	-- Secret meepz mode
	if (player_name == "Meepz") then 
		welcome_msg = "Welcome to Meepz's Gambling Intervention! Help Me!  "..self.game.options[self.db.global.game_mode_index].label.." - "..self.current_game.gold_amount.." gold"
	end
	
	SendChatMessage(welcome_msg, self.chat.channel_const)
	SendChatMessage("Press 1 to Join!", self.chat.channel_const)
	
	local start_args = self.current_game.roll_lower.." "..self.current_game.roll_upper.." "..self.current_game.gold_amount.." "..self.chat.channel_const
	self:SendCommMessage("CDG_NEW_GAME", start_args, self.chat.addon_const)
	if DEBUG then self:Print(start_args) end
end

-- (2) After accepting entries via chat callbacks, start the rolls
function CalmDownandGamble:StartRolls()
	self.current_game.accepting_rolls = true
	self.current_game.accepting_players = false
	
	local roll_msg = ""
	if self.current_game.high_tiebreaker then 
		roll_msg = "High Tiebreaker!! "..format_player_names(self.current_game.player_rolls)
	elseif self.current_game.low_tiebreaker then 
		roll_msg = "Low Tiebreaker!! "..format_player_names(self.current_game.player_rolls)
	else
		roll_msg = "Time to roll! Good Luck! Command:   /roll "..self.current_game.roll_range
	end
	SendChatMessage(roll_msg, self.chat.channel_const)
end

    -- Helper func for StartRolls
function format_player_names(players)
	local return_str = ""
	for player, _ in pairs(players) do
		return_str = return_str..player.." vs "
	end
	return_str = return_str.."!!"
	return string.gsub(return_str, " vs !", "")
end

-- (3) Called from game mode evaluate function, will log values of
-- current_winner/current_loser - can be called twice like in middleman
function CalmDownandGamble:LogResults() 
	if (self.db.global.rankings[self.current_game.winner] ~= nil) then
		self.db.global.rankings[self.current_game.winner] = self.db.global.rankings[self.current_game.winner] + self.current_game.cash_winnings
	else
		self.db.global.rankings[self.current_game.winner] = self.current_game.cash_winnings
	end
	
	if (self.db.global.rankings[self.current_game.loser] ~= nil) then
		self.db.global.rankings[self.current_game.loser] = self.db.global.rankings[self.current_game.loser] - self.current_game.cash_winnings
	else
		self.db.global.rankings[self.current_game.loser] = (-1*self.current_game.cash_winnings)
	end
end

-- (4) Resets the game state machine, called from game mode evaluate after game
-- is done and all tiebreakers have been resolved
function CalmDownandGamble:EndGame()
	-- Show me the results
	local end_args = self.current_game.winner.." "..self.current_game.loser.." "..self.current_game.cash_winnings
	self:SendCommMessage("CDG_END_GAME", end_args, self.chat.addon_const)
	self.ui.CDG_Frame:SetStatusText(self.current_game.cash_winnings.."g  "..self.current_game.loser.." => "..self.current_game.winner)

	
	-- Register game callbacks
	self:UnregisterEvent("CHAT_MSG_SYSTEM")
	self:UnregisterEvent(self.chat.channel_callback)
	if (self.chat.channel_callback_leader) then
		self:UnregisterEvent(self.chat.channel_callback_leader)
	end
	
	-- Init our game
	self:ResetGameStage()
	self.current_game = nil
end


-- Game Utililties -- Needed by game for basic common actions
-- =============================================================
function CalmDownandGamble:SetGoldAmount() 

	local text_box = self.ui.gold_amount_entry:GetText()
	local text_box_valid = (not string.match(text_box, "[^%d]")) and (text_box ~= '')
	if ( text_box_valid ) then
		self.current_game.gold_amount = text_box
	else
		self.current_game.gold_amount = 100
	end

end

function CalmDownandGamble:CheckRollsComplete(print_players)

	local rolls_complete = true
	
	if DEBUG then self:Print("CHECK ROLLS COMPLETE") end 

	for player, roll in pairs(self.current_game.player_rolls) do
		if (roll == -1) then
			rolls_complete = false
			if print_players then
				SendChatMessage("Player: "..player.." still needs to roll", self.chat.channel_const) 
			end
		end
	end
	
	if (rolls_complete) then
		self.game.accepting_rolls = false
		self.game.options[self.db.global.game_mode_index].evaluate()
	end
	
end


-- Game Modes -- Each Game Mode must define an init (or use default) and an
-- evaluate function, init sets roll_range and gold value, eval sets 
-- cashwinnings winner and loser
-- ============================================================================

-- SCORING FUNCTION
-- ===================
function CalmDownandGamble:EvaluateScores()
	
	if DEBUG then self:Print("Evaluating Scores") end
	
	
	-- UNDER CONSTRUCTION
	-- TODO 
	-- AHHHh
	local winning_roll, losing_roll, high_roller_playoff, low_roller_playoff = nil, nil, {}, {}
	local winner, loser = nil, nil
	
    -- Loop over the players and look for highest/lowest/etc
	-- TODO -- Sort from high to low
	local sort_descending = function(t,a,b) return t[b] < t[a] end
	for player, roll in self:sortedpairs(self.current_game.player_rolls, sort_descending) do
	
		player_score = tonumber(roll)
		if DEBUG then self:Print(player.." "..player_score) end
		
		if (winning_roll == nil) then  -- haven't seen anything yet
			winning_roll = player_score
			high_roller_playoff[player] = -1
			winner = player
			
		elseif (player_score > winning_roll) then  -- saw something better, reset 
			high_roller_playoff = {}
			winning_roll = player_score
			high_roller_playoff[player] = -1
			winner = player
			
		elseif (player_score == winning_roll) then -- can add them in 
			high_roller_playoff[player] = -1
		
		elseif (losing_roll == nil) then        --- haven't found a loser yet, doesnt qualify as a winner
			losing_roll = player_score
			low_roller_playoff[player] = -1
			loser = player
			
		elseif (player_score < losing_roll) then   -- MAYBE THIS IS THE WORST
			low_roller_playoff = {}
			losing_roll = player_score
			low_roller_playoff[player] = -1
			loser = player
			
		elseif (player_score == losing_roll)  then  -- also the worst
			low_roller_playoff[player] = -1
			
		else
		end
			
	end
	
	local high_roller_count = self:TableLength(high_roller_playoff)
	local low_roller_count = self:TableLength(low_roller_playoff)
	
	local found_winner = (high_roller_count == 1) 
	local found_loser = (low_roller_count == 1) 
	
	-- High Tiebreaker -- 
	if self.current_game.high_tiebreaker then 
		if found_winner then 
			self.current_game.winner = winner
			self.current_game.winning_roll = winning_roll
			self.current_game.high_tiebreaker = false
			self.current_game.high_roller_playoff = {}
		else
			self.current_game.player_rolls = self:CopyTable(high_roller_playoff)
			self.current_game.high_tiebreaker = true
			self:StartRolls()
			if DEBUG then self:Print("HIGHTIE2") end
			return false
		end
	-- Low Tiebreaker -- 
	elseif self.current_game.low_tiebreaker then 

		
		-- if total_players == high_rollers
		if (high_roller_count == self:TableLength(self.current_game.player_rolls)) then
			
		end
	
		if found_loser then 
			self.current_game.loser = loser
			self.current_game.losing_roll = losing_roll
			self.current_game.low_tiebreaker = false
			self.current_game.low_roller_playoff = {}
		elseif (high_roller_count == self:TableLength(self.current_game.player_rolls)) then
		-- all low tied again? will show up in "high_roller_playoff"
			self.current_game.player_rolls = self:CopyTable(high_roller_playoff)
			self.current_game.low_tiebreaker = true
			self:StartRolls()
			if DEBUG then self:Print("LOWTIE4") end
			return false
		else
			self.current_game.player_rolls = self:CopyTable(low_roller_playoff)
			self.current_game.low_tiebreaker = true
			self:StartRolls()
			if DEBUG then self:Print("LOWTIE2") end
			return false
		end
	-- No Tiebreaker -- 
	else
		if found_winner then 
			self.current_game.winner = winner
			self.current_game.winning_roll = winning_roll
			self.current_game.high_tiebreaker = false
			self.current_game.high_roller_playoff = {}
		else 
			self.current_game.high_roller_playoff = self:CopyTable(high_roller_playoff)
		end
		
		if found_loser then 
			self.current_game.loser = loser
			self.current_game.losing_roll = losing_roll
			self.current_game.low_tiebreaker = false
			self.current_game.low_roller_playoff = {}
		else
			self.current_game.low_roller_playoff = self:CopyTable(low_roller_playoff)
		end

	end
	
	
	if (self:TableLength(self.current_game.low_roller_playoff) > 1) then 
		if DEBUG then self:Print("LOWTIE1") end
		-- start low tiebreaker -- 
		self.current_game.low_tiebreaker = true
		self.current_game.player_rolls = self:CopyTable(self.current_game.low_roller_playoff)
		self:StartRolls()
		return false
	elseif (self:TableLength(self.current_game.high_roller_playoff) > 1) then 
		if DEBUG then self:Print("HIGHTIE1") end
		self.current_game.high_tiebreaker = true
		self.current_game.player_rolls = self:CopyTable(self.current_game.high_roller_playoff)
		self:StartRolls()
		return false
	elseif (self.current_game.loser == nil) and (not found_loser) then  -- special case, everyone was a high roller
		if DEBUG then self:Print("LOWTIE3") end
		self.current_game.low_tiebreaker = true
		self.current_game.player_rolls = self:CopyTable(low_roller_playoff)
		self:StartRolls()
		return false
	elseif (self.current_game.loser == nil) and found_loser then  -- special case, everyone was a high roller, 1v1
		self.current_game.loser = loser
		self.current_game.losing_roll = losing_roll
		return true
	else
		return true
	end
		
end

-- GAME MODE INITS 
-- =========================

-- DEFAULT INIT -- Used by almost everything
function CalmDownandGamble:DefaultGameInit() 
	self:SetGoldAmount()
	self.current_game.roll_upper = self.current_game.gold_amount
	self.current_game.roll_lower = 1
	self.current_game.roll_range = "(1-"..self.current_game.gold_amount..")"
end

-- Yahtzee Init -- Yahtzee is different because fun. 
function CalmDownandGamble:YahtzeeInit() 
	self:SetGoldAmount()
	self.current_game.roll_range = "(11111-99999)"
	self.current_game.roll_upper = 99999
	self.current_game.roll_lower = 11111
end

-- Twos Init -- Yahtzee is different because fun. 
function CalmDownandGamble:TwosInit() 
	self:SetGoldAmount()
	self.current_game.roll_range = "(1-2)"
	self.current_game.roll_upper = 2
	self.current_game.roll_lower = 1
end

-- Game mode: High Low
-- =================================================
function CalmDownandGamble:HighLow()
	if (CalmDownandGamble:EvaluateScores()) then
		self.current_game.cash_winnings = self.current_game.winning_roll - self.current_game.losing_roll
		SendChatMessage(self.current_game.loser.." owes "..self.current_game.winner.." "..self.current_game.cash_winnings.." gold!", self.chat.channel_const)
		
		-- Log Results -- All game modes must call these two explicitly
		self:LogResults()
		self:EndGame()
	end
end

-- Game mode: Twos
-- =================================================
function CalmDownandGamble:Twos()
	if (CalmDownandGamble:EvaluateScores()) then
		self.current_game.cash_winnings = self.current_game.gold_amount
		SendChatMessage(self.current_game.loser.." owes "..self.current_game.winner.." "..self.current_game.cash_winnings.." gold!", self.chat.channel_const)
	
		-- Log Results -- All game modes must call these two explicitly
		self:LogResults()
		self:EndGame()
	end
end


-- Game mode: Inverse
-- =================================================
function CalmDownandGamble:Inverse()
	if (CalmDownandGamble:EvaluateScores()) then
		
		self.current_game.cash_winnings = self.current_game.winning_roll - self.current_game.losing_roll
		self.current_game.winner, self.current_game.loser = self.current_game.loser, self.current_game.winner
		SendChatMessage(self.current_game.loser.." owes "..self.current_game.winner.." "..self.current_game.cash_winnings.." gold!", self.chat.channel_const)
	
		-- Log Results -- All game modes must call these two explicitly
		self:LogResults()
		self:EndGame()
	end
end


-- Game mode: Yahtzee
-- =================================================
function format_yahtzee_roll(roll)
	local ret_string = ""
	for digit in string.gmatch(roll, "%d") do
		ret_string = ret_string..digit.."-"
    end
	ret_string = ret_string.."!!"
	return string.gsub(ret_string, "-!!", "")
end

function CalmDownandGamble:ScoreYahtzee(roll)

	local score = 0
	for digit in string.gmatch(roll, "%d") do
		local _, count = string.gsub(roll, digit, "")
		if DEBUG then self:Print(digit.." #"..count) end
		score = score + (count * digit)
    end
	
	return score
end

function CalmDownandGamble:Yahtzee()

	local player_scores = {}
	for player, roll in pairs(self.current_game.player_rolls) do
		local score = self:ScoreYahtzee(roll)
		player_scores[player] = score
	end
	
	local sort_by_score = function(t,a,b) return t[b] < t[a] end
	for player, score in self:sortedpairs(player_scores, sort_by_score) do
		SendChatMessage(player.." Roll: "..format_yahtzee_roll(self.current_game.player_rolls[player]).." Score: "..score, self.chat.channel_const)
	end

	self.current_game.player_rolls = {}
	self.current_game.player_rolls = self:CopyTable(player_scores)
	
	if (self:EvaluateScores()) then 
		self.current_game.cash_winnings = self.current_game.gold_amount
		SendChatMessage(self.current_game.loser.." owes "..self.current_game.winner.." "..self.current_game.cash_winnings.." gold!", self.chat.channel_const)
	
		-- Log Results -- All game modes must call these two explicitly
		self:LogResults()
		self:EndGame()
	end
	
end

-- Game mode: MiddleMan
-- =================================================
function CalmDownandGamble:Median()
	
	local sort_by_score = function(t,a,b) return t[b] < t[a] end
	local high_player, median_player, low_player = "", "", ""
	local high_score, median_score, low_score = 0, 0, 0
	
	local total_players = self:TableLength(self.current_game.player_rolls)
	local last_number = total_players
	local median_number = math.floor((total_players + 1) / 2)

	local player_index = 1
	for player, roll in self:sortedpairs(self.current_game.player_rolls, sort_by_score) do
		if DEBUG then self:Print(player.." "..roll) end
		if player_index == 1 then 
			high_player = player
			high_score = roll
		elseif player_index == median_number then
			median_player = player
			median_score = roll
		elseif player_index == last_number then
			low_player = player
			low_score = roll
		else 
		end
		player_index = player_index + 1
	end

	if median_player == "" then
		SendChatMessage("You need at least 3 players!!", self.chat.channel_const)
		median_player = high_player
	end
	self.current_game.winner = median_player
	

	self.current_game.loser = high_player
	self.current_game.cash_winnings = math.abs(median_score - high_score)
	SendChatMessage(self.current_game.loser.." owes "..self.current_game.winner.." "..self.current_game.cash_winnings.." gold!", self.chat.channel_const)
	self:LogResults()
	
	self.current_game.loser = low_player
	self.current_game.cash_winnings = math.abs(median_score - low_score)
	SendChatMessage(self.current_game.loser.." owes "..self.current_game.winner.." "..self.current_game.cash_winnings.." gold!", self.chat.channel_const)
	self:LogResults()
	
	self:EndGame()
end


-- ChatFrame Interaction Callbacks (Entry and Rolls)
-- ==================================================== 
function CalmDownandGamble:RollCallback(...)

	-- Parse the input Args 
	local channel = select(1, ...)
	local roll_text = select(2, ...)
	local message = self:SplitString(roll_text, "%S+")
	local player, roll, roll_range = message[1], message[3], message[4]
	
	if DEBUG then self:Print("CHECK VALID ROLL "..self.current_game.roll_range) end
	if DEBUG then self:Print("Player: "..player.." Roll: "..roll) end
	-- Check that the roll is valid ( also that the message is for us)
	local valid_roll = (self.current_game.roll_range == roll_range) and self.current_game.accepting_rolls

	if valid_roll then 
		if (self.current_game.player_rolls[player] == -1) then
			if DEBUG then self:Print("Player: "..player.." Roll: "..roll.." RollRange: "..roll_range) end
			-- TODO: Only in NONGROUP channels if channel == "CDG_ROLL_DICE" then SendSystemMessage(roll_text) end
			self.current_game.player_rolls[player] = tonumber(roll)
			self:CheckRollsComplete(false)
		end
	end
	
end

function CalmDownandGamble:ChatChannelCallback(...)
	local message = select(2, ...)
	local sender = select(3, ...)
	
	message = message:gsub("%s+", "") -- trim whitespace
	sender = Ambiguate(sender, "short")


	local player_join = (
		(self.current_game.player_rolls[sender] == nil) 
		and (self.current_game.accepting_players) 
		and (message == "1")
        and (not self.db.global.ban_list[sender])
	)
	
	if (player_join) then
		self.current_game.player_rolls[sender] = -1
		if DEBUG then self:Print("JOINED "..sender) end
	end

end


-- Button Interaction Callbacks (State and Settings)
-- ==================================================== 
function CalmDownandGamble:PrintBanlist()
	SendChatMessage("Hall of GTFO:", self.chat.channel_const)
	for player, _ in pairs(self.db.global.ban_list) do
		SendChatMessage(player, self.chat.channel_const)
    end
end

function CalmDownandGamble:PrintRanklist()

	SendChatMessage("Hall of Fame: ", self.chat.channel_const)
	local index = 1
	local sort_descending = function(t,a,b) return t[b] < t[a] end
	for player, gold in self:sortedpairs(self.db.global.rankings, sort_descending) do
		if gold <= 0 then break end
		
		local msg = string.format("%d. %s won %d gold.", index, player, gold)
		SendChatMessage(msg, self.chat.channel_const)
		index = index + 1
	end
	
	SendChatMessage("~~~~~~", self.chat.channel_const)
	
	SendChatMessage("Hall of Shame: ", self.chat.channel_const)
	index = 1
	local sort_ascending = function(t,a,b) return t[b] > t[a] end
	for player, gold in self:sortedpairs(self.db.global.rankings, sort_ascending) do
		if gold >= 0 then break end
	
		local msg = string.format("%d. %s lost %d gold.", index, player, math.abs(gold))
		SendChatMessage(msg, self.chat.channel_const)
		index = index + 1
	end
	
end

function CalmDownandGamble:RollForMe()
	if self.current_game == nil then 
		SendSystemMessage("You need an active game for me to roll for you!")
		return
	end
	RandomRoll(self.current_game.roll_lower, self.current_game.roll_upper)
end

function CalmDownandGamble:EnterForMe()
	SendChatMessage("1", self.chat.channel_const)
end

function CalmDownandGamble:TimedStart() 
	if (self.current_game ~= nil) then
		if not self.current_game.accepting_rolls then 
			self.db.global.game_stage_index = 4 -- 4 is the final stage
			self:SetGameStage()
			self:StartRolls()
		end
	end
end

function CalmDownandGamble:LastCall()
	SendChatMessage("Last call! 10 seconds left!", self.chat.channel_const)
	self:ScheduleTimer("TimedStart", 10)
end

function CalmDownandGamble:RollStatus()
	self:CheckRollsComplete(true)
end

function CalmDownandGamble:ResetGame()
	-- Register game callbacks
	self:UnregisterEvent("CHAT_MSG_SYSTEM")
	self:UnregisterEvent(self.chat.channel_callback)
	if (self.chat.channel_callback_leader) then
		self:UnregisterEvent(self.chat.channel_callback_leader)
	end
	
	self.current_game = nil
	self:ResetGameStage()
	SendChatMessage("Game has been reset.", self.chat.channel_const)
end

function CalmDownandGamble:ChatChannelToggle()
	self.db.global.chat_index = self.db.global.chat_index + 1
	if self.db.global.chat_index > table.getn(self.chat.options) then self.db.global.chat_index = 1 end

	self:SetChannelSettings()
end

function CalmDownandGamble:ButtonGameMode()
	self.db.global.game_mode_index = self.db.global.game_mode_index + 1
	if self.db.global.game_mode_index > table.getn(self.game.options) then self.db.global.game_mode_index = 1 end

	self:SetGameMode()
end

function CalmDownandGamble:ButtonGameStage()
	self.game.stages[self.db.global.game_stage_index].callback()
	if self.db.global.game_stage_index < table.getn(self.game.stages) then 
		self.db.global.game_stage_index = self.db.global.game_stage_index + 1 
		self:SetGameStage()
	end
end


-- UI ELEMENTS 
-- ======================================================
function CalmDownandGamble:ConstructUI()
	
	-- Settings to be used -- 
	local cdg_ui_elements = {
		-- Main Box Frame -- 
		main_frame = {
			width = 443,
			height = 145	
		},
		
		-- Order in which the buttons are layed out -- 
		button_index = {
			"game_stage",
			"enter_for_me",
			"roll_for_me",
			"chat_channel",
			"game_mode",
			"print_stats_table",
			"reset_game"
			--"print_ban_list",
		},
		
		-- Button Definitions -- 
		buttons = {
			chat_channel = {
				width = 100,
				label = "Raid",
				click_callback = function() self:ChatChannelToggle() end
			},
			game_mode = {
				width = 100,
				label = "(Classic)",
				click_callback = function() self:ButtonGameMode() end
			},
			print_ban_list = {
				width = 100,
				label = "Print bans",
				click_callback = function() self:PrintBanlist() end
			},
			print_stats_table = {
				width = 100,
				label = "Print stats",
				click_callback = function() self:PrintRanklist() end
			},
			reset_game = {
				width = 100,
				label = "Reset",
				click_callback = function() self:ResetGame() end
			},
			enter_for_me = {
				width = 100,
				label = "Enter me",
				click_callback = function() self:EnterForMe() end
			},			
			roll_for_me = {
				width = 100,
				label = "Roll!",
				click_callback = function() self:RollForMe() end
			},
			start_gambling = {
				width = 100,
				label = "Start roll",
				click_callback = function() self:StartRolls() end
			},
			last_call = {
				width = 100,
				label = "Last call!",
				click_callback = function() self:LastCall() end
			},
			game_stage = {
				width = 100,
				label = "New game",
				click_callback = function() self:ButtonGameStage() end

			}
		}
		
		
	};
	
	-- Give us a base UI Table to work with -- 
	self.ui = {}
	
	-- Constructor Calls -- 
	self.ui.CDG_Frame = AceGUI:Create("Frame")
	self.ui.CDG_Frame:SetTitle("Calm Down Gambling")
	self.ui.CDG_Frame:SetStatusText("")
	self.ui.CDG_Frame:SetLayout("Flow")
	self.ui.CDG_Frame:SetStatusTable(cdg_ui_elements.main_frame)
	self.ui.CDG_Frame:EnableResize(false)
	self.ui.CDG_Frame:SetCallback("OnClose", function() self:HideUI() end)
	
	-- Set up edit box for gold -- 
	self.ui.gold_amount_entry = AceGUI:Create("EditBox")
	self.ui.gold_amount_entry:SetLabel("Gold Amount")
	self.ui.gold_amount_entry:SetWidth(100)
	self.ui.CDG_Frame:AddChild(self.ui.gold_amount_entry)
	
	-- Set up Buttons Above Text Box-- 
	for _, button_name in pairs(cdg_ui_elements.button_index) do
		local button_settings = cdg_ui_elements.buttons[button_name]
	
		self.ui[button_name] = AceGUI:Create("Button")
		self.ui[button_name]:SetText(button_settings.label)
		self.ui[button_name]:SetWidth(button_settings.width)
		self.ui[button_name]:SetCallback("OnClick", button_settings.click_callback)
		
		self.ui.CDG_Frame:AddChild(self.ui[button_name])
	end
	
	if not self.db.global.window_shown then
		self.ui.CDG_Frame:Hide()
	end
	
end


-- Util Functions -- Lua doesnt provide alot of basic functionality
-- =======================================================================
function CalmDownandGamble:SplitString(str, pattern)
	local ret_list = {}
	local index = 1
	for token in string.gmatch(str, pattern) do
		ret_list[index] = token
		index = index + 1
	end
	return ret_list
end

function CalmDownandGamble:CopyTable(T)
  local u = { }
  for k, v in pairs(T) do u[k] = v end
  return setmetatable(u, getmetatable(T))
end

function CalmDownandGamble:TableLength(T)
  if (T == nil) then return 0 end
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function CalmDownandGamble:PrintTable(T)
	for k, v in pairs(T) do
		CalmDownandGamble:Print(k.."  "..v)
	end
end

function CalmDownandGamble:sortedpairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end
    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end





