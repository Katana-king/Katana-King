local menu = {}

menu.state = "main"
menu.buttons = {
    main = {
        {text = "Play", width = 200, height = 50, action = function() 
            _G.menuActive = false
            menu.state = "main"
            if _G.resetGame then _G.resetGame() end
            print("Play button pressed: menuActive = false, state = main")
        end},
        {text = "Settings", width = 200, height = 50, action = function() 
            menu.state = "settings"
            print("Switched to settings state")
        end},
        {text = "Exit", width = 200, height = 50, action = function() 
            love.event.quit()
            print("Exit button pressed")
        end}
    },
    pause = {
        {text = "Back to Game", width = 200, height = 50, action = function() 
            _G.menuActive = false
            print("Back to Game pressed: menuActive = false")
        end},
        {text = "Restart", width = 200, height = 50, action = function() 
            if _G.resetGame then _G.resetGame() end
            print("Restart pressed: resetGame called")
        end},
        {text = "Settings", width = 200, height = 50, action = function() 
            menu.state = "settings"
            print("Switched to settings state from pause")
        end},
        {text = "Exit", width = 200, height = 50, action = function() 
            love.event.quit()
            print("Exit button pressed from pause")
        end}
    }
}

local settings = require("settings")
settings.init(menu)
menu.buttons.settings = settings.buttons

local menuFont = love.filesystem.getInfo("assets/Creepster-Regular.ttf") and 
    love.graphics.newFont("assets/Creepster-Regular.ttf", 32) or love.graphics.newFont(32)
local ambientSound = love.filesystem.getInfo("assets/audio/ambient_horror.wav") and 
    love.audio.newSource("assets/audio/ambient_horror.wav", "static") or nil
local glitchTimer = 0
local GLITCH_CHANCE = 0.05 * (_G.curseIntensity or 0.5)

function menu.update(dt)
    local mx, my = love.mouse.getPosition()
    local windowWidth, windowHeight = love.graphics.getWidth(), love.graphics.getHeight()
    print("Updating menu in state: " .. menu.state .. ", window size: " .. windowWidth .. "x" .. windowHeight)
    
    glitchTimer = glitchTimer + dt
    
    if math.random() < 0.01 and ambientSound then
        love.audio.play(ambientSound)
        print("Playing menu ambient horror sound")
    end

    if menu.state == "settings" then
        if settings.update then 
            settings.update(dt) 
            print("Settings update executed")
        else
            print("Error: Settings update function not found")
        end
    else
        local currentButtons = menu.buttons[menu.state]
        local totalHeight = #currentButtons * 50 + (#currentButtons - 1) * 20
        local startY = (windowHeight - totalHeight) / 2
        for i, button in ipairs(currentButtons) do
            button.x = (windowWidth - button.width) / 2
            button.y = startY + (i - 1) * (button.height + 20)
            button.hovered = mx >= button.x and mx <= button.x + button.width and my >= button.y and my <= button.y + button.height
            print("Button '" .. (type(button.text) == "function" and button.text() or button.text) .. "' at (" .. button.x .. ", " .. button.y .. "), size (" .. button.width .. ", " .. button.height .. ")")
        end
    end
end

function menu.draw()
    local windowWidth, windowHeight = love.graphics.getWidth(), love.graphics.getHeight()
    print("Drawing menu in state: " .. menu.state)
    
    love.graphics.setColor(0.8, 0, 0, 0.3)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    
    if math.random() < 0.05 then
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.setFont(menuFont)
        love.graphics.printf("The curse watches you...", 0, windowHeight / 3, windowWidth, "center")
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(menuFont)
    love.graphics.printf(menu.state == "main" and "Cursed Menu" or menu.state == "settings" and "Dark Settings" or "Paused in Fear", 0, windowHeight / 4, windowWidth, "center")

    if menu.state == "settings" and settings.draw then
        settings.draw()
        print("Settings draw executed")
    else
        for _, button in ipairs(menu.buttons[menu.state]) do
            love.graphics.push()
            if math.random() < GLITCH_CHANCE then
                love.graphics.translate(math.random(-5, 5), math.random(-5, 5))
            end
            love.graphics.setColor(button.hovered and {0.5, 0, 0} or {0.3, 0, 0})
            love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10)
            love.graphics.setColor(1, 1, 1, math.random() < 0.05 and 0.5 or 1)
            local buttonText = type(button.text) == "function" and button.text() or button.text
            love.graphics.printf(buttonText, button.x, button.y + button.height / 2 - 10, button.width, "center")
            love.graphics.pop()
        end
    end
    love.graphics.setColor(1, 1, 1)
end

function menu.mousepressed(x, y, button)
    if button == 1 then
        print("Mouse pressed at (" .. x .. ", " .. y .. ") in state " .. menu.state)
        if menu.state == "settings" and settings.mousepressed then
            print("Delegating mousepressed to settings module")
            settings.mousepressed(x, y, button)
        else
            for _, btn in ipairs(menu.buttons[menu.state]) do
                print("Checking button '" .. (type(btn.text) == "function" and btn.text() or btn.text) .. "' at (" .. btn.x .. ", " .. btn.y .. "), size (" .. btn.width .. ", " .. btn.height .. ")")
                if x >= btn.x and x <= btn.x + btn.width and y >= btn.y and y <= btn.y + btn.height then
                    print("Clicked on button: " .. (type(btn.text) == "function" and btn.text() or btn.text))
                    btn.action()
                    return
                else
                    print("Click outside button '" .. (type(btn.text) == "function" and btn.text() or btn.text) .. "': x(" .. x .. ") not in [" .. btn.x .. ", " .. (btn.x + btn.width) .. "], y(" .. y .. ") not in [" .. btn.y .. ", " .. (btn.y + btn.height) .. "]")
                end
            end
            print("No button clicked at (" .. x .. ", " .. y .. ")")
        end
    end
end

function menu.keypressed(key)
    if menu.state == "main" then
        if key == "r" then
            _G.menuActive = false
            if _G.resetGame then _G.resetGame() end
            print("Key 'r' (main menu): menuActive = false, resetGame called")
        elseif key == "q" then
            love.event.quit()
            print("Key 'q' (main menu): quitting game")
        elseif key == "t" then
            menu.state = "settings"
            print("Key 't' (main menu): state = settings")
        end
    elseif menu.state == "settings" then
        if key == "b" then
            menu.state = "main"
            print("Key 'b' (settings): state = main")
        end
    elseif menu.state == "pause" then
        if key == "r" then
            _G.menuActive = false
            print("Key 'r' (pause menu): menuActive = false")
        elseif key == "q" then
            if _G.resetGame then _G.resetGame() end
            print("Key 'q' (pause menu): resetGame called")
        elseif key == "t" then
            menu.state = "settings"
            print("Key 't' (pause menu): state = settings")
        elseif key == "e" then
            love.event.quit()
            print("Key 'e' (pause menu): quitting game")
        end
    end
end

return menu