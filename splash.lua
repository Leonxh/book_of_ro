local function start_splash()
    local splash = Image.load("assets/sprites/Cover.png", VRAM)

    local menu_items = { "Book of Ro" }
    local selected = 1
    local total_items = #menu_items

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
            if selected == 1 then 
                Sound.stopAllSFX()
                run_game()
            end
            splash = Image.load("assets/sprites/Cover.png", VRAM)
        elseif Keys.newPress.Start then
            Image.destroy(splash)
            return 1
        end

        screen.blit(SCREEN_UP, 0, 0, splash)

        for i = 1, total_items do
            local color = (i == selected) and Color.new256(255, 255, 0) or Color.new256(200, 200, 200)
            screen.print(SCREEN_DOWN, 40, 30 + (i - 1) * 20, (i == selected and "> " or "  ") .. menu_items[i], color)
        end

        screen.print(SCREEN_DOWN, 10, 170, "Use UP/DOWN, A to select", Color.new256(200, 200, 200))
        screen.print(SCREEN_DOWN, 10, 182, "Press START to quit", Color.new256(200, 200, 200))

        render()
    end
end

return start_splash