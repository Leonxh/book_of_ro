local run_bonus_game = dofile("bonus_game.lua")

local function start_reel_spin()
    -- Constants
    local SCROLL_SPEED, SYMBOL_SIZE, REEL_WIDTH = 8, 30, 41
    local screen_offset_x, screen_offset_y, DISPLAY_TIME = 28, 10, 55

    -- Assets and State
    local background_img = Image.load("assets/sprites/Background.png", VRAM)
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
    local score, bonus_games, overall_score = 0, false, 0
    local winning_lines, winning_line_sounded, current_line_index, line_display_timer = {}, 0, 0, 0
    local spinning, running, auto_spin = false, true, false

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
            reels[i] = {symbols={}, scroll_offset=0, scroll_timer=30+i*10, stopped=false}
            for _=1,20 do
                table.insert(reels[i].symbols, weighted_symbols[math.random(#weighted_symbols)])
            end
        end
    end

    -- Game Actions
    local function start_spin()
        Sound.startSFX(3)
        for i=1,5 do
            reels[i].scroll_timer = 50 + i * 20
            reels[i].stopped = false
        end
        spinning, winning_lines, current_line_index, line_display_timer = true, {}, 0, 0
    end

    local function update_and_check_reels()
        local still_spinning = false
        for i=1,5 do
            local r = reels[i]
            if not r.stopped then
                r.scroll_offset = r.scroll_offset + SCROLL_SPEED
                if r.scroll_offset >= SYMBOL_SIZE + 10 then
                    r.scroll_offset = 0
                    table.insert(r.symbols, 1, table.remove(r.symbols))
                end
                r.scroll_timer = r.scroll_timer - 1
                if r.scroll_timer <= 0 then r.stopped = true end
                still_spinning = true
            end
        end
        spinning = still_spinning
    end

    

    local function evaluate_bonus()
        local books = 0
        for i=1,5 do for j=1,3 do if reels[i].symbols[j]=="Book" then books = books + 1 end end end
        return books >= 3
    end

    local function render_winning_lines()
        if current_line_index == 0 then return end

        local line = winning_lines[current_line_index]
        if not line then return end

        for col = 1, 5 do
            local reel = reels[col]
            local row = line.positions[col]
            if row then
                local x = screen_offset_x + (col - 1) * REEL_WIDTH + 2
                local y = screen_offset_y + (row - 1) * SYMBOL_SIZE - reel.scroll_offset + 40 + 10 * (row - 1)

                if y >= 30 then
                    if winning_line_sounded < current_line_index then
                        winning_line_sounded = current_line_index
                        Sound.startSFX(math.random(0, 2))
                    end
                    screen.blit(SCREEN_UP, x, y, hit_images[line.line])
                end
            end
        end
    end

    local function render_game_screen()
        screen.blit(SCREEN_UP, 0, 0, background_img)
        screen.drawFillRect(SCREEN_DOWN, 0, 0, 256, 192, Color.new256(0, 0, 0))

        -- Draw all symbols
        for col = 1, 5 do
            local reel = reels[col]
            local x = screen_offset_x + (col - 1) * REEL_WIDTH + 2
            for row = 0, 2 do
                local sym = reel.symbols[row+1]
                local y = screen_offset_y + row * SYMBOL_SIZE - reel.scroll_offset + 40 + 10 * row
                if y >= 30 then
                    screen.blit(SCREEN_UP, x, y, symbol_images[sym])
                end
            end
        end

        -- Overlay highlights for winning lines
        render_winning_lines()

        screen.print(SCREEN_DOWN, 10, 120, "Should Bonus Games start?: " .. tostring(bonus_games), Color.new256(255,255,0))
        screen.print(SCREEN_DOWN, 10, 140, "Score: " .. score, Color.new256(255,255,0))
        screen.print(SCREEN_DOWN, 10, 160, "Total Score: " .. overall_score, Color.new256(255,255,0))
        if not spinning and current_line_index == 0 then
            screen.print(SCREEN_DOWN, 10, 180, "Press A to spin | START to exit", Color.new256(200,200,200))
        end

        render()
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
        collectgarbage("collect")
    end

    -- Main Flow
    math.randomseed(os.time()) for _ = 1, 5 do math.random() end
    load_assets()
    init_reels()

    while running do
        Controls.read()
        if Keys.newPress.Start then break end
        if Keys.newPress.B then auto_spin = not auto_spin end
        if (auto_spin or Keys.newPress.A) and not spinning and current_line_index == 0 then
            init_reels()
            start_spin()
        end

        if spinning then
            update_and_check_reels()
            if not spinning then
                score, winning_lines = evaluate_reels(reels)
                bonus_games = evaluate_bonus()
                overall_score = overall_score + score
                winning_line_sounded = 0
                if #winning_lines > 0 then
                    current_line_index, line_display_timer = 1, DISPLAY_TIME
                end
            end
        elseif current_line_index > 0 then
            line_display_timer = line_display_timer - 1
            if line_display_timer <= 0 then
                current_line_index = current_line_index + 1
                if current_line_index > #winning_lines then
                    current_line_index = 0
                else
                    line_display_timer = DISPLAY_TIME
                end
            end
        elseif bonus_games then
            overall_score = overall_score + play_bonus_animation()
            bonus_games = false
        end

        render_game_screen()
    end

    cleanup()
end

return start_reel_spin
