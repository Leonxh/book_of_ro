-- https://sourceforge.net/p/microlua/wiki/API471/

-- Load all modules
local splash = dofile("splash.lua")
local game = require("reel_spin")
Sound.loadBank("assets/sound/soundbank.bin")
for i = 0, 4 do
    Sound.loadSFX(i)
end

-- Stub implementations of module handlers
function run_game()
    game()
    return
end

-- Launch the splash screen

local startup_sound_handle = Sound.startSFX(4)
while not splash() == 1 do
end

for i = 1, 4 do
    Sound.unloadSFX(i)
end
Sound.unloadBank()