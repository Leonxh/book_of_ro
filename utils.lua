local remaining_bonus_spins = 0,
local current_score = 0,
local total_score = 0,
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

local function draw_bonus_game_ui()
    -- Draw background on upper screen
    screen.blit(SCREEN_UP, 0, 0, background_img)

    -- Clear lower screen area
    screen.drawFillRect(SCREEN_DOWN, 0, 0, 256, 192, Color.new256(0, 0, 0))

    -- Game stats
    screen.print(SCREEN_DOWN, 10, 100, "Bonus Spins Left: " .. state.remaining_bonus_spins, Color.new256(255, 215, 0))
    screen.print(SCREEN_DOWN, 10, 120, "Current Score: " .. state.current_score, Color.new256(200, 200, 255))
    screen.print(SCREEN_DOWN, 10, 150, "Total Score: " .. state.total_score, Color.new256(255, 255, 0))

    -- Bonus symbol display
    if state.bonus_symbol ~= nil then
        screen.blit(SCREEN_DOWN, 100, 60, symbol_images[state.bonus_symbol])
    end

    -- Control hints
    screen.print(SCREEN_DOWN, 10, 180, "A: Spin | B: Auto | START: Quit", Color.new256(200, 200, 200))
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

return {
    state,
    evaluate_reels=evaluate_reels, 
    render_winning_lines=render_winning_lines, 
    draw_bonus_game_ui=draw_bonus_game_ui,
    symbol_names=symbol_names,
    symbol_chances=symbol_chances,
    symbol_values=symbol_values,
    paylines=paylines,
    symbol_images=symbol_images,
    hit_images=hit_images,
    SYMBOL_SIZE=SYMBOL_SIZE,
    REEL_WIDTH=REEL_WIDTH,
    screen_offset_x=screen_offset_x,
    screen_offset_y=screen_offset_y
}

