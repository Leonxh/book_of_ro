-- https://sourceforge.net/p/microlua/wiki/API471/

-- Load all modules TODO: Load utils here and pass it down to other behaviour
local splash = dofile("splash.lua")
Sound.loadBank("assets/sound/soundbank.bin")
for i = 0, 4 do
    Sound.loadSFX(i)
end

-- Launch the splash screen
while not splash() == 1 do
end

for i = 1, 4 do
    Sound.unloadSFX(i)
end
Sound.unloadBank()