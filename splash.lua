local game = require("reel_spin")

local function start_splash()
    -- Always start this sound when entering this screen
    Sound.startSFX(4)

    local splash = Image.load("assets/sprites/Cover.png", VRAM)

    while true do
        Controls.read()

        if Keys.newPress.Down then
            selected = selected + 1
            if selected > total_items then selected = 1 end
        elseif Keys.newPress.Up then
            selected = selected - 1
            if selected < 1 then selected = total_items end
        end

        if Keys.newPress.A then
            Image.destroy(splash)

            Sound.stopAllSFX()
            game()
            Sound.startSFX(4)

            splash = Image.load("assets/sprites/Cover.png", VRAM)
        elseif Keys.newPress.Start then
            Image.destroy(splash)
            return 1 -- When quitting, we need to return 1 to actually quit cleanly
        end

        screen.blit(SCREEN_UP, 0, 0, splash)

        -- TODO: Instead of this text, add an entire background splash screen for the bottom screen
        screen.print(SCREEN_DOWN, 110, 80, "Begin", Color.new256(200, 200, 200))

        screen.print(SCREEN_DOWN, 65, 182, "A: Begin | START: Quit", Color.new256(200, 200, 200))

        render()
    end
end

return start_splash