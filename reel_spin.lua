local run_bonus_game = dofile("bonus_game.lua")
local utils = dofile("utils.lua")



local function init_reels()
    utils.reels = {}

    for i = 1, 5 do
        utils.reels[i] = { symbols = {}, scroll_offset = 0, scroll_timer = 50 + i * 20, stopped = false }
        for _ = 1, 20 do
            table.insert(utils.reels[i].symbols, utils.weighted_symbols[math.random(#utils.weighted_symbols)])
        end
    end
end


-- Animation for Scenechange
local function start_bonus_rounds()
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
            utils.bonus_symbol = nil
            utils.draw_game_ui()
            render()
        end
    end
    cleanup()
end

return run_game
