local run_bonus_game = dofile("bonus_game.lua")
local utils = dofile("utils.lua")



local function init_reels()
    utils.reels = {}
    utils.create_weighted_symbols()
    for i = 1, 5 do
        utils.reels[i] = { symbols = {}, scroll_offset = 0, scroll_timer = 50 + i * 20, stopped = false }
        for _ = 1, 20 do
            table.insert(utils.reels[i].symbols, utils.weighted_symbols[math.random(#utils.weighted_symbols)])
        end
    end
end


-- Animation for Scenechange
local function start_bonus_rounds()
    for frame = 0, 90 do
        utils.draw_game_ui()
        for col = 1, 5 do
            local x = utils.screen_offset_x + (col - 1) * utils.REEL_WIDTH + 2
            for row = 0, 2 do
                local sym = utils.reels[col].symbols[row + 1]
                local y = utils.screen_offset_y + row * utils.SYMBOL_SIZE + 40 + (10 * row)
                screen.blit(SCREEN_UP, x, y, utils.symbol_images[sym])
            end
        end
        if frame % 5 ~= 0 then
            screen.print(SCREEN_DOWN, 95, 45, "!!!BONUS!!!", Color.new256(150, 0, 0))
        end
        render()
    end

    utils.bonus_active = true
    return run_bonus_game(utils)
end


local function cleanup()
    for _, img in pairs(utils.symbol_images) do if img then Image.destroy(img) end end
    for _, img in pairs(utils.hit_images) do if img then Image.destroy(img) end end
    Image.destroy(utils.background_img)
    Image.destroy(utils.background_img_lower)
    collectgarbage("collect")
    
    -- Reset some variables to later start with a clean game
    utils.quitting = false
    utils.auto_spin = false
    utils.current_score = 0
    utils.total_score = 0
    utils.spins_done = 0
    utils.bonus_active = false
end


local function run_game()
    math.randomseed(os.time()) for _ = 1, 5 do math.random() end
    utils.load_assets()
    init_reels()


    while true do
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
            break
        end

        utils.current_score = 0
        utils.roll_reels()
        utils.evaluate_reels()
        utils.total_score = utils.total_score + utils.current_score
        if utils.winning_lines ~= nil and #utils.winning_lines > 0 then
            utils.render_winning_lines()
        end

        if utils.evaluate_bonus() then
            start_bonus_rounds()
            utils.bonus_active = false
            utils.draw_game_ui()
            render()
        end
    end
    cleanup()
end

return run_game
