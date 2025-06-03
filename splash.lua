local game = require("reel_spin")

local function start_splash()
    -- Always start this sound when entering this screen
    Sound.startSFX(4)

    local upper_image = Image.load("assets/sprites/Cover.png", VRAM)
    local lower_image = Image.load("assets/sprites/Cover_lower.png", VRAM)

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
            Image.destroy(upper_image)
            Image.destroy(lower_image)

            Sound.stopAllSFX()
            game()
            Sound.startSFX(4)

            upper_image = Image.load("assets/sprites/Cover.png", VRAM)
            lower_image = Image.load("assets/sprites/Cover_lower.png", VRAM)
        elseif Keys.newPress.Start then
            Image.destroy(lower_image)
            Image.destroy(upper_image)
            return 1 -- When quitting, we need to return 1 to actually quit cleanly
        end

        -- Draw Images
        screen.blit(SCREEN_UP, 0, 0, upper_image)
        screen.blit(SCREEN_DOWN, 0, 0, lower_image)

        screen.drawFillRect(SCREEN_DOWN, 0, 180, 256, 192, Color.new256(0, 0, 0))
        screen.print(SCREEN_DOWN, 65, 182, "A: Begin | START: Quit", Color.new256(200, 200, 200))

        render()
    end
end

return start_splash