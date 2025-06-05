local utils = {}

local bonus_active = false
local remaining_bonus_spins = 0
local current_score = 0
local total_score = 0
local bonus_symbol = nil

utils.SCROLL_SPEED = 8
utils.SYMBOL_SIZE = 30
utils.REEL_WIDTH = 41
utils.screen_offset_x = 28
utils.screen_offset_y = 10
utils.DISPLAY_TIME = 55

utils.reels = {}
utils.weighted_symbols = {}
utils.symbol_names = { "A", "K", "Q", "J", "Ten", "Scarab", "Sungod", "Explorer", "Book" }
utils.paylines = {
    {2,2,2,2,2}, {1,1,1,1,1}, {3,3,3,3,3}, {1,2,3,2,1}, {3,2,1,2,3},
    {2,3,3,3,2}, {2,1,1,1,2}, {3,3,2,1,1}, {1,1,2,3,3}, {3,2,2,2,1}
}
utils.symbol_values = {
    Ten={0,5,25,100}, J={0,5,25,100}, Q={0,5,25,100}, K={0,5,40,150}, A={0,5,40,150},
    Scarab={5,30,100,750}, Sungod={5,30,100,750}, Explorer={10,100,1000,5000}, Book={0,20,200,250}
}
utils.symbol_chances = { Ten=15, J=15, Q=15, K=12, A=12, Scarab=10, Sungod=8, Explorer=5, Book=30 }

function utils.create_weighted_symbols()
    utils.weighted_symbols = {}
    for s, w in pairs(utils.symbol_chances) do 
        for _=1,w do 
            table.insert(utils.weighted_symbols,s) 
        end 
    end
end
utils.create_weighted_symbols()

utils.current_score = 0
utils.total_score = 0
utils.winning_lines = {}
utils.auto_spin = false
utils.quitting = false
utils.spins_done = 0


function utils.load_assets()
    -- LOAD ASSETS
    utils.background_img = Image.load("assets/sprites/Background.png", VRAM)
    utils.background_img_bonus = Image.load("assets/sprites/Background_bonus.png", VRAM)
    utils.background_img_lower = Image.load("assets/sprites/Background_lower.png", VRAM)

    utils.hit_images = {}
    utils.symbol_images = {}
    for _, name in ipairs(utils.symbol_names) do
        utils.symbol_images[name] = Image.load("assets/symbols/"..name..".png", RAM)
    end
    for i=1,10 do
        utils.hit_images[i] = Image.load("assets/symbols/crosses/"..i..".png", RAM)
    end    

    utils.font_game = Font.load("assets/fonts/gamefont.bin")
end

function utils.evaluate_bonus()
    local books = 0
    for i=1,5 do for j=1,3 do if utils.reels[i].symbols[j]=="Book" then books = books + 1 end end end
    return books >= 3
end

function utils.evaluate_reels()
    utils.current_score = 0
    utils.winning_lines = {}

    for idx, line in ipairs(utils.paylines) do
        local first = utils.reels[1].symbols[line[1]]
        local count, sym = 1, first

        for i = 2, 5 do
            local cur = utils.reels[i].symbols[line[i]]
            if cur == sym or cur == "Book" or sym == "Book" then
                count = count + 1
                if cur ~= "Book" then sym = cur end
            else
                break
            end
        end

        local is_high = sym == "Scarab" or sym == "Sungod" or sym == "Explorer"
        if (count == 2 and is_high) or count >= 3 then
            utils.current_score = utils.current_score + (utils.symbol_values[sym] and utils.symbol_values[sym][count - 1] or 0) * count
            local positions = {}; for i=1, count do positions[i] = line[i] end
            table.insert(utils.winning_lines, {line = idx, positions=positions})
        end
    end
end

function utils.handle_input()
    Controls.read()
    if Keys.newPress.Start then utils.quitting = true end
    if Keys.newPress.B then utils.auto_spin = not utils.auto_spin end
end

function utils.draw_game_ui()

    -- Upper screen
    if utils.bonus_active then
        screen.blit(SCREEN_UP, 0, 0, utils.background_img_bonus)
    else
        screen.blit(SCREEN_UP, 0, 0, utils.background_img)
    end
    
    -- Lower Background
    screen.blit(SCREEN_DOWN, 0, 0, utils.background_img_lower)

    -- === Game Stats ===
    local text_color = Color.new256(0, 0, 0)
    screen.printFont(SCREEN_DOWN, 170, 63, "" .. utils.current_score, text_color, utils.font_game)
    screen.printFont(SCREEN_DOWN, 170, 83, "" .. utils.total_score, text_color, utils.font_game)
    screen.printFont(SCREEN_DOWN, 170, 103, "" .. utils.spins_done, text_color, utils.font_game)

    local average_score = utils.spins_done > 0 and math.floor(utils.total_score / utils.spins_done) or 0
    screen.printFont(SCREEN_DOWN, 170, 123, "" .. average_score, text_color, utils.font_game)

    -- === Bonus Symbol (in this case just an X) ===
    if utils.bonus_active and utils.bonus_symbol ~= nil then
        screen.printFont(SCREEN_DOWN, 65, 40, "BONUS SPINS: " .. utils.remaining_bonus_spins, text_color, utils.font_game)
        screen.blit(SCREEN_DOWN, 170, 140, utils.symbol_images[utils.bonus_symbol])
    else
        -- Draw Placeholder symbol
        screen.blit(SCREEN_DOWN, 170, 140, utils.hit_images[6])
    end


    -- === Controls ===
    screen.drawFillRect(SCREEN_DOWN, 0, 180, 256, 192, Color.new256(0, 0, 0))
    screen.print(SCREEN_DOWN, 25, 182, "Tap/A: Spin | B: Auto | START: Quit", Color.new256(200, 200, 200))

    -- We also need to check user input here (yes, it's kinda ugly)
    utils.handle_input()
end

function utils.display_reels()
    utils.draw_game_ui()
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

function utils.roll_reels()
    utils.spins_done = utils.spins_done + 1

    utils.reels = {}

    for i = 1, 5 do
        utils.reels[i] = { symbols = {}, scroll_offset = 0, scroll_timer = 50 + i * 20, stopped = false }
        for _ = 1, 20 do
            table.insert(utils.reels[i].symbols, utils.weighted_symbols[math.random(#utils.weighted_symbols)])
        end
    end

    local spinning = true

    Sound.startSFX(3)
    while spinning do
        utils.draw_game_ui()

        for i = 1, 5 do
            local reel = utils.reels[i]
            local x = utils.screen_offset_x + (i - 1) * utils.REEL_WIDTH + 2

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
                local y = utils.screen_offset_y + row * utils.SYMBOL_SIZE - reel.scroll_offset + 40 + 10 * row
                if y >= 30 then screen.blit(SCREEN_UP, x, y, utils.symbol_images[sym]) end
            end
        end

        render()
        spinning = false
        for i = 1, 5 do if not utils.reels[i].stopped then spinning = true break end end
    end
end

function utils.render_winning_lines()

    for index, line in ipairs(utils.winning_lines) do
        local line_sound_played = false

        for frame = 1, utils.DISPLAY_TIME do
            utils.draw_game_ui()

            -- Draw all symbols
            for col = 1, 5 do
                local reel = utils.reels[col]
                local x = utils.screen_offset_x + (col - 1) * utils.REEL_WIDTH + 2

                for row = 0, 2 do
                    local sym = reel.symbols[row + 1]
                    local y = utils.screen_offset_y + row * utils.SYMBOL_SIZE + 40 + 10 * row
                    screen.blit(SCREEN_UP, x, y, utils.symbol_images[sym])
                end
            end

            -- Highlight winning line
            for col = 1, 5 do
                local row = line.positions[col]
                if row then
                    local x = utils.screen_offset_x + (col - 1) * utils.REEL_WIDTH + 2
                    local y = utils.screen_offset_y + (row - 1) * utils.SYMBOL_SIZE + 40 + 10 * (row - 1)

                    if y >= 30 then
                        if not line_sound_played then
                            Sound.startSFX(math.random(0, 2))
                            line_sound_played = true
                        end
                        screen.blit(SCREEN_UP, x, y, utils.hit_images[line.line])
                    end
                end
            end

            render()
        end
    end
    utils.display_reels()
end

return utils