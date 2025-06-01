local utils = {}


local function pick_bonus_symbol()
    
    -- Remove Books from Bonus Symbols
    for i = #utils.weighted_symbols, 1, -1 do
        if utils.weighted_symbols[i] == "Book" then
            table.remove(utils.weighted_symbols, i)
        end
    end

    local reel = { symbols = {}, scroll_offset = 0, scroll_timer = 90, stopped = false }

    for i = 1, 20 do
        table.insert(reel.symbols, utils.weighted_symbols[math.random(#utils.weighted_symbols)])
    end
    utils.create_weighted_symbols()

    local SCROLL_SPEED = 16

    while true do
        Controls.read()
        utils.draw_game_ui(true)
        screen.print(SCREEN_UP, 45, 20, "Selecting Bonus Symbol...", Color.new256(255, 215, 0))

        if not reel.stopped then
            reel.scroll_offset = reel.scroll_offset + utils.SCROLL_SPEED
            if reel.scroll_offset >= utils.SYMBOL_SIZE + 10 then
                reel.scroll_offset = 0
                table.insert(reel.symbols, 1, table.remove(reel.symbols))
            end
            reel.scroll_timer = reel.scroll_timer - 1
            if reel.scroll_timer <= 0 then reel.stopped = true end
        end

        for row = 0, 2 do
            local sym = reel.symbols[row + 1]
            local y = utils.screen_offset_y + row * utils.SYMBOL_SIZE - reel.scroll_offset + 40 + (10 * row)
            screen.blit(SCREEN_UP, utils.screen_offset_x + 2 * utils.REEL_WIDTH + 2, y, utils.symbol_images[sym])
        end

        local center_y = utils.screen_offset_y + utils.SYMBOL_SIZE + 40 + 10 * 1
        screen.drawRect(SCREEN_UP, utils.screen_offset_x + 2 * utils.REEL_WIDTH, center_y - 2, utils.screen_offset_x + 2 * utils.REEL_WIDTH + utils.SYMBOL_SIZE + 6, center_y + utils.SYMBOL_SIZE + 4, Color.new256(255, 0, 0))
        render()

        if reel.stopped then
            utils.bonus_symbol = reel.symbols[2]

            -- Pause and show the chosen symbol
            for frame = 1, 60 do
                Controls.read()
                utils.draw_game_ui(true)
                screen.print(SCREEN_UP, 50, 20, "Chosen Bonus Symbol:", Color.new256(255, 255, 0))
                screen.blit(SCREEN_UP, 100, 60, utils.symbol_images[utils.bonus_symbol])
                render()
            end
            return
        end
    end
end


local function render_expansion_frames(expansion_positions)

    local function display_reels()
        utils.draw_game_ui(true)
        for col = 1, 5 do
            local x = utils.screen_offset_x + (col - 1) * utils.REEL_WIDTH + 2
            for row = 0, 2 do
                local sym = utils.reels[col].symbols[row + 1]
                local y = utils.screen_offset_y + row * utils.SYMBOL_SIZE + 40 + (10 * row)
                screen.blit(SCREEN_UP, x, y, utils.symbol_images[sym])
            end
        end
        render()
    end


    for k, v in pairs(expansion_positions) do
        for i = 1, 3 do
            if utils.reels[v.col].symbols[i] ~= utils.bonus_symbol then
                utils.reels[v.col].symbols[i] = utils.bonus_symbol
                display_reels()

                -- Wait a little to show each symbol being placed
                for frame = 1, 200 do
                    Controls.read() 
                end
            end
        end
    end
end

local function apply_expanding_symbols()

    local expansion_positions = {}

    for col = 1, 5 do
        for row = 1, 3 do
            if utils.reels[col].symbols[row] == utils.bonus_symbol then
                table.insert(expansion_positions, {col = col, set_row = row})
                break
            end
        end
    end
    render_expansion_frames(expansion_positions)
end

-- TODO: add functionality for bonus symbol evaluation
local function evaluate_bonus_board()
    utils.evaluate_reels()
end


local function run_bonus_game(new_utils)
    utils = new_utils
    utils.remaining_bonus_spins = 10
    utils.current_score = 0
    
    pick_bonus_symbol()

    while utils.remaining_bonus_spins > 0 do

        Controls.read()
        -- Calling this twice is really shitty but i'm having trouble with only one screen refreshing on calling render()
        -- This is a workaround for that issue. The "bug" is only noticeable on initial load of the game
        utils.display_reels()
        utils.display_reels()

        -- Wait for user input to continue spin
        while true do
            utils.handle_input()
            if utils.auto_spin or Keys.newPress.A or utils.quitting then
                break
            end
        end

        if utils.quitting then
            return {quitting=true}
        end

        utils.current_score = 0
        utils.roll_reels()
        utils.evaluate_reels()
        utils.total_score = utils.total_score + utils.current_score
        if utils.winning_lines ~= nil and #utils.winning_lines > 0 then
            utils.render_winning_lines()
        end

        -- Check for retrigger (3+ Books)
        if utils.evaluate_bonus() then
            utils.remaining_bonus_spins = utils.remaining_bonus_spins + 10
        end


        apply_expanding_symbols()
        evaluate_bonus_board()
        utils.total_score = utils.total_score + utils.current_score
        if utils.winning_lines ~= nil and #utils.winning_lines > 0 then
            utils.render_winning_lines()
        end
        

        utils.remaining_bonus_spins = utils.remaining_bonus_spins - 1
    end
    return total_score
end


return run_bonus_game
