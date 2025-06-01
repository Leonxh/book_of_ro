local utils = {}
local remaining_bonus_spins = 0
local current_score = 0
local total_score = 0
local bonus_symbol = nil

local SYMBOL_SIZE = 30
local REEL_WIDTH = SYMBOL_SIZE + 11
local screen_offset_x = 28
local screen_offset_y = 10

local background_img = Image.load("assets/sprites/Background.png", VRAM)

local symbol_names = { "A", "K", "Q", "J", "Ten", "Scarab", "Sungod", "Explorer", "Book"}
local symbol_chances = { Ten=15, J=15, Q=15, K=12, A=12, Scarab=10, Sungod=8, Explorer=5, Book=3 }
local symbol_values = {
    Ten = {0, 5, 25, 100}, J = {0, 5, 25, 100}, Q = {0, 5, 25, 100},
    K = {0, 5, 40, 150}, A = {0, 5, 40, 150},
    Scarab = {5, 30, 100, 750}, Sungod = {5, 30, 100, 750}, Explorer = {10, 100, 1000, 5000}, Book={0,20,200,250}
}

local paylines = {
    {2,2,2,2,2}, {1,1,1,1,1}, {3,3,3,3,3}, {1,2,3,2,1}, {3,2,1,2,3},
    {2,3,3,3,2}, {2,1,1,1,2}, {3,3,2,1,1}, {1,1,2,3,3}, {3,2,2,2,1}
}

local symbol_images = {}
for _, name in ipairs(symbol_names) do
    symbol_images[name] = Image.load("assets/symbols/" .. name .. ".png", RAM)
end

local hit_images = {}
for i = 1, 10 do
    hit_images[i] = Image.load("assets/symbols/crosses/" .. i .. ".png", RAM)
end


local function build_weighted_symbols()
    local symbols = {}
    for symbol, weight in pairs(symbol_chances) do
        for _ = 1, weight do table.insert(symbols, symbol) end
    end
    return symbols
end

local function draw_bonus_game_ui()
    -- Draw background on upper screen
    screen.blit(SCREEN_UP, 0, 0, background_img)

    -- Clear lower screen area
    screen.drawFillRect(SCREEN_DOWN, 0, 0, 256, 192, Color.new256(0, 0, 0))

    -- Game stats
    screen.print(SCREEN_DOWN, 10, 100, "Bonus Spins Left: " .. remaining_bonus_spins, Color.new256(255, 215, 0))
    screen.print(SCREEN_DOWN, 10, 120, "Current Score: " .. current_score, Color.new256(200, 200, 255))
    screen.print(SCREEN_DOWN, 10, 150, "Total Score: " .. total_score, Color.new256(255, 255, 0))

    -- Bonus symbol display
    if bonus_symbol ~= nil then
        screen.blit(SCREEN_DOWN, 100, 60, symbol_images[bonus_symbol])
    end

    -- Control hints
    screen.print(SCREEN_DOWN, 10, 180, "A: Spin | B: Auto | START: Quit", Color.new256(200, 200, 200))
end


local function pick_bonus_symbol()
    local weighted_symbols = build_weighted_symbols()
    
    -- Remove Books from Bonus Symbols
    for i = #weighted_symbols, 1, -1 do
        if weighted_symbols[i] == "Book" then
            table.remove(weighted_symbols, i)
        end
    end

    local reel = { symbols = {}, scroll_offset = 0, scroll_timer = 90, stopped = false }

    for i = 1, 20 do
        table.insert(reel.symbols, weighted_symbols[math.random(#weighted_symbols)])
    end

    local SCROLL_SPEED = 16

    while true do
        Controls.read()
        draw_bonus_game_ui()
        screen.print(SCREEN_UP, 45, 20, "Selecting Bonus Symbol...", Color.new256(255, 215, 0))

        if not reel.stopped then
            reel.scroll_offset = reel.scroll_offset + SCROLL_SPEED
            if reel.scroll_offset >= SYMBOL_SIZE + 10 then
                reel.scroll_offset = 0
                table.insert(reel.symbols, 1, table.remove(reel.symbols))
            end
            reel.scroll_timer = reel.scroll_timer - 1
            if reel.scroll_timer <= 0 then reel.stopped = true end
        end

        for row = 0, 2 do
            local sym = reel.symbols[row + 1]
            local y = screen_offset_y + row * SYMBOL_SIZE - reel.scroll_offset + 40 + (10 * row)
            screen.blit(SCREEN_UP, screen_offset_x + 2 * REEL_WIDTH + 2, y, symbol_images[sym])
        end

        local center_y = screen_offset_y + SYMBOL_SIZE + 40 + 10 * 1
        screen.drawRect(SCREEN_UP, screen_offset_x + 2 * REEL_WIDTH, center_y - 2, screen_offset_x + 2 * REEL_WIDTH + SYMBOL_SIZE + 6, center_y + SYMBOL_SIZE + 4, Color.new256(255, 0, 0))
        render()

        if reel.stopped then
            local chosen = reel.symbols[2]

            -- Pause and show the chosen symbol
            for frame = 1, 60 do
                Controls.read()
                draw_bonus_game_ui()
                screen.print(SCREEN_UP, 50, 20, "Chosen Bonus Symbol:", Color.new256(255, 255, 0))
                screen.blit(SCREEN_UP, 100, 60, symbol_images[chosen])
                render()
            end

            return chosen
        end
    end
end


local function roll_bonus_reels()
    local reels = {}
    local weighted_symbols = build_weighted_symbols()

    for i = 1, 5 do
        reels[i] = { symbols = {}, scroll_offset = 0, scroll_timer = 50 + i * 20, stopped = false }
        for _ = 1, 20 do
            table.insert(reels[i].symbols, weighted_symbols[math.random(#weighted_symbols)])
        end
    end

    local SCROLL_SPEED = 8
    local spinning = true

    Sound.startSFX(3)
    while spinning do
        Controls.read()
        draw_bonus_game_ui()

        for i = 1, 5 do
            local reel = reels[i]
            local x = screen_offset_x + (i - 1) * REEL_WIDTH + 2

            if not reel.stopped then
                reel.scroll_offset = reel.scroll_offset + SCROLL_SPEED
                if reel.scroll_offset >= SYMBOL_SIZE + 10 then
                    reel.scroll_offset = 0
                    table.insert(reel.symbols, 1, table.remove(reel.symbols))
                end
                reel.scroll_timer = reel.scroll_timer - 1
                if reel.scroll_timer <= 0 then reel.stopped = true end
            end

            for row = 0, 2 do
                local sym = reel.symbols[row + 1]
                local y = screen_offset_y + row * SYMBOL_SIZE - reel.scroll_offset + 40 + 10 * row
                if y >= 30 then screen.blit(SCREEN_UP, x, y, symbol_images[sym]) end
            end
        end

        render()
        spinning = false
        for i = 1, 5 do if not reels[i].stopped then spinning = true break end end
    end

    return reels
end

local function render_expansion_frames(reels, expansion_positions)

    local function display_reels(reels)
        draw_bonus_game_ui()
        for col = 1, 5 do
            local x = screen_offset_x + (col - 1) * REEL_WIDTH + 2
            for row = 0, 2 do
                local sym = reels[col].symbols[row + 1]
                local y = screen_offset_y + row * SYMBOL_SIZE + 40 + (10 * row)
                screen.blit(SCREEN_UP, x, y, symbol_images[sym])
            end
        end
        render()
    end


    for k, v in pairs(expansion_positions) do
        for i = 1, 3 do
            if reels[v.col].symbols[i] ~= bonus_symbol then
                reels[v.col].symbols[i] = bonus_symbol
                display_reels(reels)
                for frame = 1, 200 do
                    Controls.read() 
                end
            end
        end
    end
end

local function apply_expanding_symbols(reels)

    local expansion_positions = {}

    for col = 1, 5 do
        for row = 1, 3 do
            if reels[col].symbols[row] == bonus_symbol then
                table.insert(expansion_positions, {col = col, set_row = row})
                break
            end
        end
    end
    render_expansion_frames(reels, expansion_positions)
    return reels
end

local function evaluate_reels(reels)
    local total = 0
    local winning_lines = {}

    for idx, line in ipairs(paylines) do
        local first = reels[1].symbols[line[1]]
        local count, sym = 1, first

        for i = 2, 5 do
            local cur = reels[i].symbols[line[i]]
            if cur == sym or cur == "Book" or sym == "Book" then
                count = count + 1
                if cur ~= "Book" then sym = cur end
            else
                break
            end
        end

        local is_high = sym == "Scarab" or sym == "Sungod" or sym == "Explorer"
        if (count == 2 and is_high) or count >= 3 then
            total = total + (symbol_values[sym] and symbol_values[sym][count - 1] or 0) * count
            local positions = {}; for i=1, count do positions[i] = line[i] end
            table.insert(winning_lines, {line = idx, positions=positions})
        end
    end
    return total, winning_lines
end


-- TODO: add functionality for bonus symbol evaluation
local function evaluate_bonus_board(reels)
    return evaluate_reels(reels)
end

local function render_winning_lines(reels, winning_lines, duration_per_line)
    local duration = duration_per_line or 55

    for index, line in ipairs(winning_lines) do
        local line_sound_played = false

        for frame = 1, duration do
            Controls.read()
            draw_bonus_game_ui()

            -- Draw all symbols
            for col = 1, 5 do
                local reel = reels[col]
                local x = screen_offset_x + (col - 1) * REEL_WIDTH + 2

                for row = 0, 2 do
                    local sym = reel.symbols[row + 1]
                    local y = screen_offset_y + row * SYMBOL_SIZE + 40 + 10 * row
                    screen.blit(SCREEN_UP, x, y, symbol_images[sym])
                end
            end

            -- Highlight winning line
            for col = 1, 5 do
                local row = line.positions[col]
                if row then
                    local x = screen_offset_x + (col - 1) * REEL_WIDTH + 2
                    local y = screen_offset_y + (row - 1) * SYMBOL_SIZE + 40 + 10 * (row - 1)

                    if y >= 30 then
                        if not line_sound_played then
                            Sound.startSFX(math.random(0, 2))
                            line_sound_played = true
                        end
                        screen.blit(SCREEN_UP, x, y, hit_images[line.line])
                    end
                end
            end

            render()
        end
    end
end

local function run_bonus_game(new_utils)
    utils = new_utils
    remaining_bonus_spins = 10
    total_score = 0
    current_score = 0
    bonus_symbol = pick_bonus_symbol()

    while remaining_bonus_spins > 0 do
        local reels = roll_bonus_reels()
        current_score, winning_lines = evaluate_reels(reels)
        total_score = total_score + current_score
        if winning_lines ~= nil and #winning_lines > 0 then
            render_winning_lines(reels, winning_lines, 55)
        end

        -- Check for retrigger (3+ Books)
        local book_count = 0
        for i = 1, 5 do
            for j = 1, 3 do
                if reels[i].symbols[j] == "Book" then
                    book_count = book_count + 1
                end
            end
        end

        if book_count >= 3 then
            remaining_bonus_spins = remaining_bonus_spins + 10
        end

        reels = apply_expanding_symbols(reels)
        current_score, winning_lines = evaluate_bonus_board(reels)
        total_score = total_score + current_score
        if winning_lines ~= nil and #winning_lines > 0 then
            render_winning_lines(reels, winning_lines, 55)
        end
        

        remaining_bonus_spins = remaining_bonus_spins - 1
    end
    return total_score
end


return run_bonus_game
