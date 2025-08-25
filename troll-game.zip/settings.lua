local settings = {}
local menu

function settings.init(m)
    menu = m
    _G.curseIntensity = _G.curseIntensity or 0.5
    settings.buttons = {
        {text = function() return love.window.getFullscreen() and "Windowed Mode" or "Fullscreen Mode" end, 
         width = 200, height = 50, action = function()
            local isFullscreen = love.window.getFullscreen()
            love.window.setFullscreen(not isFullscreen)
            print("Fullscreen toggled: fullscreen = " .. tostring(not isFullscreen))
        end},
        {text = function() return "Curse Intensity: " .. math.floor(_G.curseIntensity * 100) .. "%" end, 
         width = 200, height = 50, action = function()
            _G.curseIntensity = math.min(1, math.max(0, _G.curseIntensity + 0.1))
            print("Curse Intensity set to: " .. _G.curseIntensity)
        end},
        {text = "Back", width = 200, height = 50, action = function() 
            menu.state = "main"
            print("Back button pressed: state = main")
        end}
    }
end

settings.buttons = {}

local settingsFont = love.filesystem.getInfo("assets/Creepster-Regular.ttf") and 
    love.graphics.newFont("assets/Creepster-Regular.ttf", 32) or love.graphics.newFont(32)

function settings.update(dt)
    local mx, my = love.mouse.getPosition()
    local windowWidth, windowHeight = love.graphics.getWidth(), love.graphics.getHeight()
    local totalHeight = #settings.buttons * 50 + (#settings.buttons - 1) * 20
    local startY = (windowHeight - totalHeight) / 2
    for i, button in ipairs(settings.buttons) do
        button.x = (windowWidth - button.width) / 2
        button.y = startY + (i - 1) * (button.height + 20)
        button.hovered = mx >= button.x and mx <= button.x + button.width and my >= button.y and my <= button.y + button.height
        print("Settings button '" .. (type(button.text) == "function" and button.text() or button.text) .. "' at (" .. button.x .. ", " .. button.y .. "), size (" .. button.width .. ", " .. button.height .. ")")
    end
    print("Settings update completed")
end

function settings.draw()
    print("Drawing settings interface")
    local windowWidth, windowHeight = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(0.1, 0, 0, 0.8)
    love.graphics.rectangle("fill", windowWidth * 0.1, windowHeight * 0.1, windowWidth * 0.8, windowHeight * 0.8, 10)
    love.graphics.setColor(0.8, 0, 0, 0.3)
    love.graphics.rectangle("fill", windowWidth * 0.1, windowHeight * 0.1, windowWidth * 0.8, windowHeight * 0.8, 10)
    love.graphics.setFont(settingsFont)
    for _, button in ipairs(settings.buttons) do
        love.graphics.setColor(button.hovered and {0.5, 0, 0} or {0.3, 0, 0})
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10)
        love.graphics.setColor(1, 1, 1, math.random() < 0.05 and 0.5 or 1)
        local buttonText = type(button.text) == "function" and button.text() or button.text
        love.graphics.printf(buttonText, button.x, button.y + button.height / 2 - 10, button.width, "center")
    end
    love.graphics.setColor(1, 1, 1)
    print("Settings draw completed")
end

function settings.mousepressed(x, y, button)
    if button == 1 then
        print("Settings mouse pressed at (" .. x .. ", " .. y .. ")")
        for _, btn in ipairs(settings.buttons) do
            if x >= btn.x and x <= btn.x + btn.width and y >= btn.y and y <= btn.y + btn.height then
                print("Clicked settings button: " .. (type(btn.text) == "function" and btn.text() or btn.text))
                btn.action()
                return
            else
                print("Click outside settings button '" .. (type(btn.text) == "function" and btn.text() or btn.text) .. "': x(" .. x .. ") not in [" .. btn.x .. ", " .. (btn.x + btn.width) .. "], y(" .. y .. ") not in [" .. btn.y .. ", " .. (btn.y + btn.height) .. "]")
            end
        end
        print("No settings button clicked at (" .. x .. ", " .. y .. ")")
    end
end

return settings