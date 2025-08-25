-- Constants
local CARD_WIDTH = 80
local CARD_HEIGHT = 80
local CARD_SPACING = 30
local BOARD_ROWS = 5
local BOARD_COLS = 5
local PLAYER_START_ROW = 5
local PLAYER_START_COL = 3
local PLAYER_MOVE_DURATION = 0.1
local PLAYER_START_HEALTH = 10
local PORTAL_ID = 25
local BOARD_TEXTURE_SCALE = 1.2
local TIMER_DURATION = 30 -- 30-second timer
local JUMPSCARE_DURATION = 5 -- 5-second jumpscare duration

-- Global variables
local board = {}
local cards = {}
local score = 0
local level = 1
local gameWon = false
local gameOver = false
local menuActive = true
local menu
local player, startX, startY
local playerImage, enemyImage, portalImage, healthImage, hoverboardImage
local gameFont, cardFont
local scoreanim = {}
local enemySound, healSound
local soundPitch = 1
local hoverboardImageAlpha = 1
local justReset = false -- Flag to prevent immediate level change
local firstUpdatePostReset = false -- Flag for first update after reset
local menuLocked = false -- Lock to prevent menu re-entry post-reset
local stabilizationFrame = false -- Extra frame for state stabilization
local gameInitialized = false -- Flag to confirm full initialization
local backgroundMusic -- Variable for background music
local highestScore = 0 -- Variable to track highest score
local timer = TIMER_DURATION -- Timer variable
local playerPath = {} -- Track player's path
local jumpscareImage -- Image for jumpscare
local jumpscareSound -- Sound for jumpscare
local showingJumpscare = false -- Flag to track jumpscare state
local jumpscareTimer = 0 -- Timer for jumpscare duration

local function loadImage(path)
    if love.filesystem.getInfo(path) then
        local image = love.graphics.newImage(path)
        image:setFilter("nearest", "nearest")
        return image
    end
    print("Warning: Failed to load image at " .. path)
    return nil
end

local function loadSound(path)
    if love.filesystem.getInfo(path) then
        return love.audio.newSource(path, "static")
    end
    print("Warning: Failed to load sound at " .. path)
    return nil
end

local function calculateBoardOffsets()
    startX = (love.graphics.getWidth() - (BOARD_COLS * (CARD_WIDTH + CARD_SPACING) - CARD_SPACING)) / 2
    startY = (love.graphics.getHeight() - (BOARD_ROWS * (CARD_HEIGHT + CARD_SPACING) - CARD_SPACING)) / 2
end

local function updatePlayerVisualPosition()
    player.visualX = startX + (player.position.col - 1) * (CARD_WIDTH + CARD_SPACING) + CARD_WIDTH / 2
    player.visualY = startY + (player.position.row - 1) * (CARD_HEIGHT + CARD_SPACING) + CARD_HEIGHT / 2
end

local function scoreAnimation(points, x, y)
    table.insert(scoreanim, {
        points = points,
        x = x,
        y = y,
        timer = 1,
        alpha = 1
    })
end

local function updatescoreAnimation(dt)
    for i = #scoreanim, 1, -1 do
        local anim = scoreanim[i]
        anim.timer = anim.timer - dt
        anim.y = anim.y - 50 * dt
        anim.alpha = anim.timer
        if anim.timer <= 0 then
            table.remove(scoreanim, i)
        end
    end
end

local function hueToRgb(h)
    h = h % 1
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local q = 1 - f
    local t = f

    if i == 0 then r, g, b = 1, t, 0
    elseif i == 1 then r, g, b = q, 1, 0
    elseif i == 2 then r, g, b = 0, 1, t
    elseif i == 3 then r, g, b = 0, q, 1
    elseif i == 4 then r, g, b = t, 0, 1
    else r, g, b = 1, 0, q end
    return r, g, b
end

-- Player Functions
local function initializePlayer()
    player = {
        health = PLAYER_START_HEALTH,
        position = {row = PLAYER_START_ROW, col = PLAYER_START_COL},
        targetPosition = {row = PLAYER_START_ROW, col = PLAYER_START_COL},
        visualX = 0,
        visualY = 0,
        moveTimer = 0,
        moveDuration = PLAYER_MOVE_DURATION
    }
    playerPath = {{row = PLAYER_START_ROW, col = PLAYER_START_COL}} -- Initialize path with starting position
end

local function updatePlayerMovement(dt)
    if player.moveTimer <= 0 then return end

    player.moveTimer = math.max(0, player.moveTimer - dt)
    local t = 1 - player.moveTimer / player.moveDuration
    local startPosX = startX + (player.position.col - 1) * (CARD_WIDTH + CARD_SPACING) + CARD_WIDTH / 2
    local startPosY = startY + (player.position.row - 1) * (CARD_HEIGHT + CARD_SPACING) + CARD_HEIGHT / 2
    local targetPosX = startX + (player.targetPosition.col - 1) * (CARD_WIDTH + CARD_SPACING) + CARD_WIDTH / 2
    local targetPosY = startY + (player.targetPosition.row - 1) * (CARD_HEIGHT + CARD_SPACING) + CARD_HEIGHT / 2
    player.visualX = startPosX + (targetPosX - startPosX) * t
    player.visualY = startPosY + (targetPosY - startPosY) * t
    if player.moveTimer <= 0 then
        player.position.row = player.targetPosition.row
        player.position.col = player.targetPosition.col
    end
end

local function movePlayerTo(row, col, card)
    player.targetPosition = {row = row, col = col}
    player.moveTimer = player.moveDuration
    -- Add new position to path if not already present
    for _, pos in ipairs(playerPath) do
        if pos.row == row and pos.col == col then
            return -- Position already in path, no need to add
        end
    end
    table.insert(playerPath, {row = row, col = col})
    local points = 0

    if card and not card.defeated then
        if card.type == "portal" then
            points = 50
        elseif card.type == "health" then
            player.health = player.health + card.health
            points = 5
            board[row][col] = nil
            if healSound then
                love.audio.play(healSound)
            end
        else
            player.health = player.health - card.health
            card.defeated = true
            points = 10
            board[row][col] = nil
            if enemySound then
                enemySound:setPitch(soundPitch)
                love.audio.play(enemySound)
                soundPitch = soundPitch + 0.1
            end
        end
        score = score + points
        if points > 0 then
            scoreAnimation(points, player.visualX, player.visualY)
        end
    end
end

-- Card Functions
local function createCards()
    cards = {}
    local numHealthCards = math.random(3, 5)
    local numEnemyCards = 23 - numHealthCards
    local minHealth = level or 1
    local maxHealth = minHealth + 1

    for i = 1, numEnemyCards do
        cards[#cards + 1] = {id = i, health = math.random(minHealth, maxHealth), defeated = false, type = "enemy"}
    end
    for i = 1, numHealthCards do
        cards[#cards + 1] = {id = 100 + i, health = level + 1, defeated = false, type = "health"}
    end
    cards[#cards + 1] = {id = PORTAL_ID, health = 0, defeated = false, type = "portal"}

    for i = #cards, 2, -1 do
        local j = math.random(i)
        cards[i], cards[j] = cards[j], cards[i]
    end
end

local function initializeBoard()
    board = {}
    for row = 1, BOARD_ROWS do
        board[row] = {}
        for col = 1, BOARD_COLS do
            board[row][col] = nil
        end
    end

    local portal
    for i, card in ipairs(cards) do
        if card.id == PORTAL_ID then
            portal = card
            table.remove(cards, i)
            break
        end
    end
    -- Avoid placing portal in column 3 (player start)
    local portalCol = math.random(1, BOARD_COLS)
    while portalCol == PLAYER_START_COL do
        portalCol = math.random(1, BOARD_COLS)
    end
    board[1][portalCol] = portal
    board[PLAYER_START_ROW][PLAYER_START_COL] = nil

    local availablePositions = {}
    for row = 1, BOARD_ROWS do
        for col = 1, BOARD_COLS do
            if not (row == PLAYER_START_ROW and col == PLAYER_START_COL) and not (row == 1 and col == portalCol) then
                availablePositions[#availablePositions + 1] = {row = row, col = col}
            end
        end
    end
    for i = #availablePositions, 2, -1 do
        local j = math.random(i)
        availablePositions[i], availablePositions[j] = availablePositions[j], availablePositions[i]
    end
    for i, card in ipairs(cards) do
        if i <= #availablePositions then
            local pos = availablePositions[i]
            board[pos.row][pos.col] = card
        end
    end
end

local function verifyBoard()
    if board[PLAYER_START_ROW][PLAYER_START_COL] then
        print("Error: Player spawn position should be nil")
    end
    local portalFound = false
    for col = 1, BOARD_COLS do
        if board[1][col] and board[1][col].id == PORTAL_ID then
            portalFound = true
            break
        end
    end
    if not portalFound then
        print("Error: Portal not found in first row")
    end
    -- Check and fix player-portal collision
    if board[player.position.row][player.position.col] and board[player.position.row][player.position.col].id == PORTAL_ID then
        print("Warning: Player on portal at (" .. player.position.row .. "," .. player.position.col .. "). Moving to (5,3).")
        player.position = {row = PLAYER_START_ROW, col = PLAYER_START_COL}
        player.targetPosition = {row = PLAYER_START_ROW, col = PLAYER_START_COL}
        updatePlayerVisualPosition()
    end
end

-- Game Reset Function
function resetGame()
    score = 0
    level = 1
    gameWon = false
    gameOver = false
    soundPitch = 1.0
    scoreanim = {}
    playerPath = {{row = PLAYER_START_ROW, col = PLAYER_START_COL}} -- Reset path
    initializePlayer()
    initializeLevel()
    menuActive = false -- Ensure game starts without menu
    if menu then menu.state = "main" end -- Only set state if menu is valid
    justReset = true -- Prevent immediate level change for 2 frames
    firstUpdatePostReset = true -- Flag for first update after reset
    menuLocked = true -- Lock menu state post-reset
    gameInitialized = false -- Require full initialization
    timer = TIMER_DURATION -- Reset timer to 30 seconds
    showingJumpscare = false -- Reset jumpscare state
    jumpscareTimer = 0 -- Reset jumpscare timer
    if jumpscareSound then jumpscareSound:stop() end -- Stop any playing jumpscare sound
    if backgroundMusic then
        backgroundMusic:play()
        backgroundMusic:setLooping(true)
    end
    print("resetGame: level = 1, menuActive = " .. tostring(menuActive) .. ", menu.state = " .. tostring(menu and menu.state or "nil") .. ", justReset = " .. tostring(justReset) .. ", firstUpdatePostReset = " .. tostring(firstUpdatePostReset) .. ", menuLocked = " .. tostring(menuLocked) .. ", gameInitialized = " .. tostring(gameInitialized) .. ", timer = " .. timer)
end

function love.load()
    math.randomseed(os.time())
    json = require("dkjson") -- Load JSON library
    menu = require("menu")
    print("Menu loaded: ", menu ~= nil)
    initializePlayer()
    playerImage = loadImage("assets/player.png")
    enemyImage = loadImage("assets/enemy1.png")
    portalImage = loadImage("assets/portal.png")
    healthImage = loadImage("assets/health.png")
    hoverboardImage = loadImage("assets/hoverboard.png")
    enemySound = loadSound("assets/audio/sfx1.wav")
    healSound = loadSound("assets/audio/sfx1.wav")
    local musicPath = "assets/audio/music.mp3"
    if love.filesystem.getInfo(musicPath) then
        backgroundMusic = love.audio.newSource(musicPath, "stream")
        backgroundMusic:setLooping(true)
        love.audio.play(backgroundMusic)
    else
        print("Warning: Background music file not found at " .. musicPath)
    end
    gameFont = love.graphics.newFont("assets/font.ttf", 32) or love.graphics.newFont(32)
    cardFont = love.graphics.newFont("assets/font.ttf", 40) or love.graphics.newFont(40)
    love.graphics.setFont(gameFont)
    jumpscareImage = loadImage("assets/jumpscare.jpg")
    jumpscareSound = loadSound("assets/jumpscare.mp3")
    if not jumpscareImage then
        print("Warning: Jumpscare image not found at assets/jumpscare.jpg")
    end
    if not jumpscareSound then
        print("Warning: Jumpscare sound not found at assets/jumpscare.mp3")
    end
    -- Load high score if exists
    if love.filesystem.getInfo("game_data.json") then
        local data = love.filesystem.read("game_data.json")
        local decoded = json.decode(data)
        if decoded and decoded.highestScore then
            highestScore = decoded.highestScore
        end
    end
    initializeLevel()
    calculateBoardOffsets()
    print("love.load: Initial menuActive = " .. tostring(menuActive) .. ", timer = " .. timer)
end

function love.resize(w, h)
    calculateBoardOffsets()
    updatePlayerVisualPosition()
end

function initializeLevel()
    createCards()
    initializeBoard()
    verifyBoard()
    player.position = nil -- Clear player position temporarily
    player.position = {row = PLAYER_START_ROW, col = PLAYER_START_COL} -- Reassign after board setup
    player.targetPosition = {row = PLAYER_START_ROW, col = PLAYER_START_COL}
    player.moveTimer = 0
    playerPath = {{row = PLAYER_START_ROW, col = PLAYER_START_COL}} -- Reset path
    calculateBoardOffsets()
    updatePlayerVisualPosition()
    justReset = true -- Prevent immediate level change
    print("initializeLevel: level = " .. level .. ", player at (" .. player.position.row .. "," .. player.position.col .. "), justReset = " .. tostring(justReset) .. ", timer = " .. timer)
end

function love.update(dt)
    print("love.update: dt = " .. dt .. ", menuActive = " .. tostring(menuActive) .. ", justReset = " .. tostring(justReset) .. ", firstUpdatePostReset = " .. tostring(firstUpdatePostReset) .. ", stabilizationFrame = " .. tostring(stabilizationFrame) .. ", menuLocked = " .. tostring(menuLocked) .. ", gameInitialized = " .. tostring(gameInitialized) .. ", player at (" .. player.position.row .. "," .. player.position.col .. "), timer = " .. timer .. ", gameOver = " .. tostring(gameOver) .. ", level = " .. level .. ", showingJumpscare = " .. tostring(showingJumpscare) .. ", jumpscareTimer = " .. jumpscareTimer)

    -- Handle jumpscare first to ensure it takes priority
    if showingJumpscare then
        jumpscareTimer = jumpscareTimer + dt
        print("Jumpscare active: jumpscareTimer = " .. jumpscareTimer .. ", duration = " .. JUMPSCARE_DURATION)
        if jumpscareSound and not jumpscareSound:isPlaying() then
            jumpscareSound:play()
            print("Jumpscare sound playing started")
        end
        if jumpscareTimer >= JUMPSCARE_DURATION then
            showingJumpscare = false
            jumpscareTimer = 0
            if jumpscareSound then jumpscareSound:stop() end
            print("Jumpscare ended after 5 seconds, simulating Tab keypress and exiting")
            love.keypressed("tab") -- Simulate Tab keypress to save data
            love.event.quit() -- Exit to desktop
            return
        end
        return
    end

    if menuActive then
        menu.update(dt)
        return
    end

    if firstUpdatePostReset then
        menuActive = false -- Force menu off after reset
        justReset = true -- Extend protection
        stabilizationFrame = true -- Add stabilization frame
        firstUpdatePostReset = false
        print("First update post-reset: menuActive forced to false, justReset extended, stabilizationFrame set")
    elseif stabilizationFrame then
        stabilizationFrame = false -- Allow initialization check
        gameInitialized = true -- Mark initialization complete
        menuLocked = false -- Unlock menu after stabilization
        print("Stabilization frame: State stabilized, gameInitialized set to true, menuLocked released")
    elseif justReset and gameInitialized then
        justReset = false -- Reset after initial protection
        print("Post-reset update: justReset cleared, game ready")
    end

    if not gameInitialized then return end -- Wait for full initialization

    updatePlayerMovement(dt)
    updatescoreAnimation(dt)

    -- Update highest score
    if score > highestScore then
        highestScore = score
    end

    -- Update and check timer
    if not gameWon and not gameOver then
        timer = timer - dt
        if timer <= 0 then
            gameOver = true
            print("Game over due to timer expiration")
        end
    end

    local allDefeated = true
    for row = 1, BOARD_ROWS do
        for col = 1, BOARD_COLS do
            if board[row][col] and not board[row][col].defeated and board[row][col].type == "enemy" then
                allDefeated = false
                break
            end
        end
        if not allDefeated then break end
    end
    if not justReset and board[player.position.row][player.position.col] and board[player.position.row][player.position.col].id == PORTAL_ID then
        level = level + 1
        soundPitch = 1.0
        initializeLevel()
        timer = TIMER_DURATION -- Reset timer when advancing level
        print("Level advanced to " .. level)
        return
    end
    gameWon = allDefeated
    if player.health <= 0 then
        gameOver = true
        print("Game over due to health depletion")
    end

    -- Trigger jumpscare if level >= 5 and game over
    if gameOver and level >= 5 and not showingJumpscare then
        print("Jumpscare triggered: gameOver = " .. tostring(gameOver) .. ", level = " .. level .. ", jumpscareImage exists = " .. tostring(jumpscareImage ~= nil) .. ", jumpscareSound exists = " .. tostring(jumpscareSound ~= nil))
        showingJumpscare = true
        if backgroundMusic then love.audio.pause(backgroundMusic) end -- Pause background music
        jumpscareTimer = 0 -- Reset timer for jumpscare
    end
end

function love.draw()
    if showingJumpscare then
        if jumpscareImage then
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(jumpscareImage, 0, 0, 0, love.graphics.getWidth() / jumpscareImage:getWidth(), love.graphics.getHeight() / jumpscareImage:getHeight())
        else
            -- Fallback if jumpscare image is missing
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(gameFont)
            love.graphics.printf("Jumpscare!", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
        end
        return
    end

    -- Draw background or fallback
    love.graphics.setColor(0, 0, 0.5) -- Solid blue background as fallback
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw board texture
    if hoverboardImage then
        love.graphics.setColor(1, 1, 1, hoverboardImageAlpha)
        local boardWidth = BOARD_COLS * (CARD_WIDTH + CARD_SPACING) - CARD_SPACING
        local boardHeight = BOARD_ROWS * (CARD_HEIGHT + CARD_SPACING) - CARD_SPACING
        local scaledWidth = boardWidth * BOARD_TEXTURE_SCALE
        local scaledHeight = boardHeight * BOARD_TEXTURE_SCALE
        local offsetX = (boardWidth - scaledWidth) / 2
        local offsetY = (boardHeight - scaledHeight) / 2
        love.graphics.draw(hoverboardImage, startX + offsetX, startY + offsetY, 0, scaledWidth / hoverboardImage:getWidth(), scaledHeight / hoverboardImage:getHeight())
    end

    -- Draw borders for player's path
    love.graphics.setColor(1, 1, 0) -- Yellow border
    love.graphics.setLineWidth(4) -- Thick border
    for _, pos in ipairs(playerPath) do
        local x = startX + (pos.col - 1) * (CARD_WIDTH + CARD_SPACING) - 2 -- Slight offset for visibility
        local y = startY + (pos.row - 1) * (CARD_HEIGHT + CARD_SPACING) - 2
        love.graphics.rectangle("line", x, y, CARD_WIDTH + 4, CARD_HEIGHT + 4, 10)
    end
    love.graphics.setLineWidth(1) -- Reset line width

    for row = 1, BOARD_ROWS do
        for col = 1, BOARD_COLS do
            local card = board[row][col]
            local x = startX + (col - 1) * (CARD_WIDTH + CARD_SPACING)
            local y = startY + (row - 1) * (CARD_HEIGHT + CARD_SPACING)
            if card then
                if card.defeated then
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT, 10)
                elseif card.type == "portal" then
                    love.graphics.setColor(1, 1, 1)
                    if portalImage then
                        love.graphics.draw(portalImage, x, y, 0, CARD_WIDTH / portalImage:getWidth(), CARD_HEIGHT / portalImage:getHeight())
                    else
                        love.graphics.setColor(0, 1, 0)
                        love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT, 10)
                    end
                elseif card.type == "health" then
                    love.graphics.setColor(1, 1, 1)
                    if healthImage then
                        love.graphics.draw(healthImage, x, y, 0, CARD_WIDTH / healthImage:getWidth(), CARD_HEIGHT / healthImage:getHeight())
                    else
                        love.graphics.setColor(0, 1, 1)
                        love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT, 10)
                    end
                    love.graphics.setFont(cardFont)
                    love.graphics.printf("+" .. card.health, x, y + CARD_HEIGHT - 10, CARD_WIDTH - 5, "right")
                else
                    love.graphics.setColor(1, 1, 1)
                    if enemyImage then
                        love.graphics.draw(enemyImage, x, y, 0, CARD_WIDTH / enemyImage:getWidth(), CARD_HEIGHT / enemyImage:getHeight())
                    else
                        love.graphics.setColor(1, 0, 0)
                        love.graphics.rectangle("fill", x, y, CARD_WIDTH, CARD_HEIGHT, 10)
                    end
                    love.graphics.setFont(cardFont)
                    love.graphics.printf(tostring(card.health), x, y + CARD_HEIGHT - 10, CARD_WIDTH - 5, "right")
                end
            end
        end
    end

    love.graphics.setColor(1, 1, 1)
    if playerImage then
        love.graphics.draw(playerImage, player.visualX - CARD_WIDTH / 2, player.visualY - CARD_HEIGHT / 2, 0, CARD_WIDTH / playerImage:getWidth(), CARD_HEIGHT / playerImage:getHeight())
    else
        love.graphics.setColor(1, 1, 0)
        love.graphics.rectangle("fill", player.visualX - CARD_WIDTH / 2, player.visualY - CARD_HEIGHT / 2, CARD_WIDTH, CARD_HEIGHT, 10)
    end
    love.graphics.setFont(gameFont)
    love.graphics.printf("Time: " .. string.format("%.1f", timer), 0, 10, love.graphics.getWidth(), "center")
    love.graphics.printf("Health: " .. player.health .. " Level: " .. level, 0, 50, love.graphics.getWidth(), "center")
    love.graphics.printf("Score: " .. score, 0, love.graphics.getHeight() - 40, love.graphics.getWidth(), "center")

    for _, anim in ipairs(scoreanim) do
        local r, g, b = hueToRgb(anim.timer)
        love.graphics.setColor(r, g, b, anim.alpha)
        love.graphics.setFont(gameFont)
        love.graphics.printf("+" .. anim.points, anim.x - 50, anim.y, 100, "center")
    end

    if gameWon then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(gameFont)
        love.graphics.printf("Score: " .. score, 0, love.graphics.getHeight() / 2 + 50, love.graphics.getWidth(), "center")
    elseif gameOver and not showingJumpscare then
        love.graphics.setColor(1, 0, 0)
        love.graphics.setFont(gameFont)
        love.graphics.printf("Game Over!\nLevel: " .. level .. "\nScore: " .. score .. "\nHighest Score: " .. highestScore .. "\nPress 'r' to Replay, 'q' to Exit", 0, love.graphics.getHeight() / 2 - 50, love.graphics.getWidth(), "center")
    end

    if menuActive then
        menu.draw()
    end
end

function love.mousepressed(x, y, button)
    print("Global mousepressed at (" .. x .. ", " .. y .. "), menuActive = " .. tostring(menuActive) .. ", menuLocked = " .. tostring(menuLocked))
    if menuActive then
        if menu and menu.mousepressed then
            print("Passing to menu.mousepressed")
            menu.mousepressed(x, y, button)
        else
            print("Menu or menu.mousepressed is nil")
        end
    elseif not gameInitialized then
        print("Game not initialized, ignoring click")
        return
    elseif button == 1 and not gameWon and not gameOver and player.moveTimer <= 0 then
        for row = 1, BOARD_ROWS do
            for col = 1, BOARD_COLS do
                local cardX = startX + (col - 1) * (CARD_WIDTH + CARD_SPACING)
                local cardY = startY + (row - 1) * (CARD_HEIGHT + CARD_SPACING)
                if x >= cardX and x <= cardX + CARD_WIDTH and y >= cardY and y <= cardY + CARD_HEIGHT then
                    if math.abs(row - player.position.row) + math.abs(col - player.position.col) == 1 then
                        movePlayerTo(row, col, board[row][col])
                    end
                end
            end
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        if gameWon or gameOver then
            menuActive = true
            if menu then menu.state = "main" end
            menuLocked = false
            print("Escape (gameWon/gameOver): menuActive = true, state = main, menuLocked = false")
        elseif not menuActive then
            menuActive = true
            if menu then menu.state = "pause" end
            print("Escape (gameplay): menuActive = true, state = pause")
        else
            menuActive = false
            print("Escape (menu active): menuActive = false")
        end
        return
    end

    if key == "tab" then
        print("Tab key pressed: Saving game data")
        local gameData = {
            score = score,
            level = level,
            highestScore = highestScore,
            timestamp = os.time()
        }
        love.filesystem.write("game_data.json", json.encode(gameData))
        return
    end

    if key == "x" then
        gameOver = true
        level = 5
        print("Debug: Forced gameOver = true, level = 5 to trigger jumpscare")
        return
    end

    if menuActive and not menuLocked then
        if menu and menu.keypressed then
            menu.keypressed(key)
        else
            print("Menu or menu.keypressed is nil")
        end
        return
    end

    if not gameInitialized then return end

    if not gameWon and not gameOver and player.moveTimer <= 0 then
        local newRow, newCol = player.position.row, player.position.col
        if key == "up" then newRow = newRow - 1
        elseif key == "down" then newRow = newRow + 1
        elseif key == "left" then newCol = newCol - 1
        elseif key == "right" then newCol = newCol + 1 end
        if newRow >= 1 and newRow <= BOARD_ROWS and newCol >= 1 and newCol <= BOARD_COLS then
            local card = board[newRow][newCol]
            if card == nil or not card.defeated then
                movePlayerTo(newRow, newCol, card)
            end
        end
    end

    if gameOver and not showingJumpscare then
        if key == "r" then
            resetGame()
            print("Replaying game")
        elseif key == "q" then
            love.event.quit()
            print("Exiting game")
        end
    end
end