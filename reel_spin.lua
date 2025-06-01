local run_bonus_game = dofile("bonus_game.lua")

-- Constants
local SCROLL_SPEED, SYMBOL_SIZE, REEL_WIDTH = 8, 30, 41
local screen_offset_x, screen_offset_y, DISPLAY_TIME = 28, 10, 55

-- Assets and State
local background_img = Image.load("assets/sprites/Background.png", VRAM)
local background_img_lower = Image.load("assets/sprites/Background_lower.png", VRAM)
local symbol_images, hit_images, reels = {}, {}, {}
local symbol_names = { "A", "K", "Q", "J", "Ten", "Scarab", "Sungod", "Explorer", "Book" }
local paylines = {
    {2,2,2,2,2}, {1,1,1,1,1}, {3,3,3,3,3}, {1,2,3,2,1}, {3,2,1,2,3},
    {2,3,3,3,2}, {2,1,1,1,2}, {3,3,2,1,1}, {1,1,2,3,3}, {3,2,2,2,1}
}

local symbol_values = {
    Ten={0,5,25,100}, J={0,5,25,100}, Q={0,5,25,100}, K={0,5,40,150}, A={0,5,40,150},
    Scarab={5,30,100,750}, Sungod={5,30,100,750}, Explorer={10,100,1000,5000}, Book={0,20,200,250}
}
local symbol_chances = { Ten=15, J=15, Q=15, K=12, A=12, Scarab=10, Sungod=8, Explorer=5, Book=3 }
local weighted_symbols = {}
for s, w in pairs(symbol_chances) do for _=1,w do table.insert(weighted_symbols,s) end end

-- Game Runtime State
local current_score, bonus_games, total_score = 0, false, 0
local winning_lines, winning_line_sounded, current_line_index, line_display_timer = {}, 0, 0, 0
local spinning, auto_spin = false, false
local quitting = false
local spins_done = 0


-- Initialization
local function load_assets()
    for _, name in ipairs(symbol_names) do
        symbol_images[name] = Image.load("assets/symbols/"..name..".png", VRAM)
    end
    for i=1,10 do
        hit_images[i] = Image.load("assets/symbols/crosses/"..i..".png", RAM)
    end
end

local function init_reels()
    reels = {}

    for i = 1, 5 do
        reels[i] = { symbols = {}, scroll_offset = 0, scroll_timer = 50 + i * 20, stopped = false }
        for _ = 1, 20 do
            table.insert(reels[i].symbols, weighted_symbols[math.random(#weighted_symbols)])
        end
    end
end


local function evaluate_bonus()
    local books = 0
    for i=1,5 do for j=1,3 do if reels[i].symbols[j]=="Book" then books = books + 1 end end end
    return books >= 3
end

local function handle_input()
    Controls.read()
    if Keys.newPress.Start then quitting = true end
    if Keys.newPress.B then auto_spin = not auto_spin end
end


local function draw_game_ui()
    -- Upper screen
    screen.blit(SCREEN_UP, 0, 0, background_img)

    -- Lower Background
    screen.blit(SCREEN_DOWN, 0, 0, background_img_lower)

    -- === Game Stats ===
    local text_color = current_score, Color.new256(0, 0, 0)
    screen.print(SCREEN_DOWN, 170, 65, "" .. current_score, text_color)
    screen.print(SCREEN_DOWN, 170, 85, "" .. total_score, text_color)
    screen.print(SCREEN_DOWN, 170, 105, "" .. spins_done, text_color)

    local average_score = spins_done > 0 and math.floor(total_score / spins_done) or 0
    screen.print(SCREEN_DOWN, 170, 125, "" .. average_score, text_color)

    -- === Bonus Symbol (in this case just an X) ===
    screen.blit(SCREEN_DOWN, 170, 140, hit_images[6])

    -- === Controls ===
    screen.drawFillRect(SCREEN_DOWN, 0, 180, 256, 192, Color.new256(0, 0, 0))
    screen.print(SCREEN_DOWN, 40, 182, "A: Spin | B: Auto | START: Quit", Color.new256(200, 200, 200))

    -- We also need to check user input here (yes, it's kinda ugly)
    handle_input()
end


local function display_reels()
    draw_game_ui()
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

local function render_winning_lines(reels, winning_lines, duration_per_line)
    local duration = duration_per_line or 55

    for index, line in ipairs(winning_lines) do
        local line_sound_played = false

        for frame = 1, duration do
            draw_game_ui()

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
    display_reels()
end


-- Animation for Scenechange
local function play_bonus_animation()
    for frame = 0, 89 do
        Controls.read()
        screen.drawFillRect(SCREEN_UP, 0, 0, 256, 192, Color.new256(0, 0, 0))
        screen.print(SCREEN_UP, 60, 80, "BONUS GAME!", Color.new256(255, 215, 0))
        if frame % 10 < 5 then
            screen.print(SCREEN_UP, 70, 100, "Get ready...", Color.new256(255, 0, 0))
        end
        render()
    end
    for _ = 1, 15 do render() end
    return run_bonus_game()
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

local function cleanup()
    for _, img in pairs(symbol_images) do if img then Image.destroy(img) end end
    for _, img in pairs(hit_images) do if img then Image.destroy(img) end end
    Image.destroy(background_img)
    Image.destroy(background_img_lower)
    collectgarbage("collect")
end


local function roll_reels()
    spins_done = spins_done + 1

    reels = {}

    for i = 1, 5 do
        reels[i] = { symbols = {}, scroll_offset = 0, scroll_timer = 50 + i * 20, stopped = false }
        for _ = 1, 20 do
            table.insert(reels[i].symbols, weighted_symbols[math.random(#weighted_symbols)])
        end
    end

    local spinning = true

    Sound.startSFX(3)
    while spinning do
        draw_game_ui()

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


local function run_game()
    math.randomseed(os.time()) for _ = 1, 5 do math.random() end
    load_assets()
    init_reels()


    while true do
        Controls.read()
        -- Calling this twice is really shitty but i'm having trouble with only one screen refreshing on calling render()
        -- This is a workaround for that issue. The "bug" is only noticeable on initial load of the game
        display_reels()
        display_reels()

        
        -- Wait for user input to continue spin
        while true do
            handle_input()
            if auto_spin or Keys.newPress.A or quitting then
                break
            end
        end

        if quitting then
            break
        end

        current_score = 0
        reels = roll_reels()
        current_score, winning_lines = evaluate_reels(reels)
        total_score = total_score + current_score
        if winning_lines ~= nil and #winning_lines > 0 then
            render_winning_lines(reels, winning_lines, 55)
        end

        if evaluate_bonus() then
            total_score = total_score + play_bonus_animation()
            draw_game_ui()
            render()
        end
    end
    cleanup()
end

return run_game
