
local story = require("story")
local ui = require("spaceUI")
local Utils = require("utils")

local space = {}
space.stars = require("stars")
space.mode = "search" --search, listen, process, send
space.selectedStar = nil
space.selectedFreq = nil -- nil, "A", "B", "C", "D"
space.playSignal = false
space.playingSignal = false
space.signalTime = 0 -- Used for timing signals
space.sigStep = 1
space.showComments = false
space.selectedComment = nil
space.message = ""
space.isSignal = false
space.hintStar = "Delta-702"
space.hintCount = 0
space.mood = 0
space.goToE = false
space.analyseBool = false
space.analyseTime = 0

local ship = {} --Space ship/probe data
ship.angle = 180
ship.speed = 35
ship.fov = 90

space.ship = ship
space.story = story

local toneA = love.audio.newSource("audio/tone1.mp3", "static")
local toneB = love.audio.newSource("audio/tone2.mp3", "static")
local toneC = love.audio.newSource("audio/tone3.mp3", "static")
local toneD = love.audio.newSource("audio/tone4.mp3", "static")

local function loadWorld(game)
    ship.fovToView = 360 / ship.fov
    space.stars.load()
    ui.load(game, space)
    space.line = {50, 600, 400, 650}
end
space.load = loadWorld

local function hideUI() -- Hide all UI buttons
    freq1.draw = false
    freq2.draw = false
    freq3.draw = false
    freq4.draw = false
    freq1.active = false
    freq2.active = false
    freq3.active = false
    freq4.active = false
    play.draw = false
    play.active = false
    stop.draw = false
    stop.active = false
    send.draw = false
    send.active = false
    comment1.draw = false
    comment1.active = false
    comment2.draw = false
    comment2.active = false
    comment3.draw = false
    comment3.active = false
    response1.draw = false
    response1.active = false
    exit.draw = false
    exit.active = false
    back.draw = false
    back.active = false
end

local function listenUI()
    hideUI()
    freq1.draw = true
    freq2.draw = true
    freq3.draw = true
    freq4.draw = true
    freq1.active = true
    freq2.active = true
    freq3.active = true
    freq4.active = true
    exit.draw = true
    exit.active = true
end

local function processUI()
    hideUI()
    if space.isSignal then
        play.draw = true 
        play.active = true
        stop.draw = true 
        stop.active = true
        send.draw = true
        send.active = true
    else 
        back.draw = true
        back.active = true
    end
    exit.draw = true
    exit.active = true
    if space.showComments then 
        send.draw = false
        send.active = false
        comment1.draw = true 
        comment1.active = true
        comment2.draw = true
        comment2.active = true 
        comment3.draw = true 
        comment3.active = true
    end
end

local function messageUI()
    hideUI()
    response1.draw = true
    response1.active = true
end

local function updateSignal(dt)
    local signal = space.stars.getSelectedSignal(space.selectedStar, space.selectedFreq)
    local signalStep = 2
    space.signalTime = space.signalTime + dt
    if space.signalTime < 0.5 then 
        signalStep = 1
    elseif space.signalTime < 1.0 then 
        signalStep = 2
    elseif space.signalTime < 1.5 then 
        signalStep = 3
    elseif space.signalTime < 2.0 then 
        signalStep = 4
    elseif space.signalTime < 2.5 then 
        signalStep = 5
    elseif space.signalTime < 3.0 then 
        signalStep = 6
    elseif space.signalTime < 3.5 then 
        signalStep = 7
    elseif space.signalTime < 4.0 then 
        signalStep = 8
    elseif space.signalTime < 4.5 then 
        signalStep = 9
    elseif space.signalTime < 5.0 then 
        signalStep = 10
    else 
        space.signalTime = 0
        signalStep = 2
    end
    space.sigStep = signalStep

    if space.selectedFreq == "A" then
        if not toneA:isPlaying() then
            toneA:setVolume(signal[signalStep] / 10) 
            toneA:play()
        end
    elseif space.selectedFreq == "B" then 
        if not toneB:isPlaying() then
            toneB:setVolume(signal[signalStep] / 10) 
            toneB:play()
        end
    elseif space.selectedFreq == "C" then 
        if not toneC:isPlaying() then
            toneC:setVolume(signal[signalStep] / 10) 
            toneC:play()
        end
    elseif space.selectedFreq == "D" then 
        if not toneD:isPlaying() then
            toneD:setVolume(signal[signalStep] / 10) 
            toneD:play()
        end
    end
end

local function drawSignalLine(signal, x, y)
    local xSegment = 20
    local yScale = 10
    love.graphics.setLineWidth(0.2)
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("line", x - 10, y - 110, 200, 115)
    love.graphics.setColor(0.0, 0.9, 0.0)
    love.graphics.line(x, signal[1] * -yScale + y,
        x + xSegment * 1, signal[2] * -yScale + y,
        x + xSegment * 2, signal[3] * -yScale + y,
        x + xSegment * 3, signal[4] * -yScale + y,
        x + xSegment * 4, signal[5] * -yScale + y,
        x + xSegment * 5, signal[6] * -yScale + y,
        x + xSegment * 6, signal[7] * -yScale + y,
        x + xSegment * 7, signal[8] * -yScale + y,
        x + xSegment * 8, signal[9] * -yScale + y,
        x + xSegment * 9, signal[10] * -yScale + y) 
    love.graphics.setColor(0.9, 0.0, 0.0)   
    love.graphics.line(x + (space.sigStep * xSegment) - xSegment, y,
        x + (space.sigStep * xSegment) - xSegment, y - 100)
end

local function drawStarPortrait(star, game)
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("fill", 25, 510, 100, 100)
    love.graphics.setColor(star.color[1], star.color[2], star.color[3])
    local x = 65
    local y = 560
    love.graphics.translate(x, y)
    love.graphics.polygon("fill", star.portrait)
    love.graphics.translate(-x, -y)
    love.graphics.setColor(0.9,0.9,0.9)
    love.graphics.setFont(game.textFont)
    love.graphics.print(star.name, 30, 610)
end

local function drawStarInfo(star)
    love.graphics.setColor(0.9,0.9,0.9)
    love.graphics.print("Distance: "..star.distance.." light years", 140, 510)
end

local function fovPoly(x, y)
    local width = 40
    local height = 120
    local poly = {x, y,
        x - width, y + height,
        x + width, y + height,
    }
    return poly 
end

local function drawShip(game)
    love.graphics.setColor(0.0, 0.9, 0.0)
    love.graphics.setLineWidth(0.1)
    love.graphics.rectangle("line", 1000, 500, 150, 180)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle('fill', 1065, 540, 20, 80)
    love.graphics.rectangle('fill', 1045, 560, 60, 5)
    love.graphics.rectangle('fill', 1045, 600, 60, 5)
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.polygon('fill', {1045, 520, 1045, 650, 1010, 640})
    love.graphics.polygon('fill', {1105, 520, 1105, 650, 1140, 640})

    local x = 1075
    local y = 550
    love.graphics.setColor(0.8, 0.0, 0.0, 0.5)
    love.graphics.translate(x, y)
    love.graphics.rotate(math.rad(ship.angle))   
    love.graphics.polygon('fill', fovPoly(0, 0))
    love.graphics.rotate(math.rad(-ship.angle))
    love.graphics.translate(-x, -y)

    love.graphics.setColor(0.8,0.8,0.8)
    love.graphics.setFont(game.textFontSmall)
    love.graphics.print("Camera angle: "..Utils.round(ship.angle).."°", 1000, 682)
end

local function updateWorld(dt, game)
    if space.mode == "search" then
        local move = "none"
        if love.keyboard.isDown('right', 'd') then
            ship.angle = ship.angle + (ship.speed * dt)
            move = "right"
        elseif love.keyboard.isDown('left', 'a') then
            ship.angle = ship.angle - (ship.speed * dt)
            move = "left"
        end

        if (ship.angle > 360) then 
            local amtOver = ship.angle - 360
            ship.angle = amtOver
        end
        if (ship.angle < 0) then 
            local amtUnder = ship.angle + 360
            ship.angle = amtUnder
        end
        space.stars.update(dt, game, space, ship, move)
    elseif space.mode == "listen" then 
        uare.update(dt, love.mouse.getX(), love.mouse.getY())
    elseif space.mode == "process" then
        local signal = space.stars.getSelectedSignal(space.selectedStar, space.selectedFreq)
        if signal == nil then 
            space.playSignal = false 
            space.sigStep = 1
        end
        if space.playSignal then 
            if not space.playingSignal then 
                space.signalTime = 0
                space.playingSignal = true
            end
            updateSignal(dt)
        end
        uare.update(dt, love.mouse.getX(), love.mouse.getY())
    elseif space.mode == "message" then  
        uare.update(dt, love.mouse.getX(), love.mouse.getY())
    elseif space.mode == "analyseMessage" then 
        if not space.analyseBool then
            space.analyseBool = true
            space.analyseTime = 0
        end
        space.analyseTime = space.analyseTime + dt 
        space.line[2] = space.line[2] + dt * 60
        space.line[4] = space.line[4] + dt * 60 
        if space.line[2] > 660 then space.line[2] = 600 end
        if space.line[4] > 660 then space.line[4] = 600 end
        if space.analyseTime > 1.5 then 
            space.analyseBool = false 
            space.mode = "message"
        end
    end
end
space.update = updateWorld

local function drawWorld(game)
    space.stars.draw(game, space, ship)
    drawShip(game)

    if space.mode == "listen" then
        listenUI()
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", 15, 500, 850, 185)
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.setFont(game.textFont)
        love.graphics.print("Choose frequency to listen on", 430, 510)
        drawStarPortrait(space.selectedStar, game)
        drawStarInfo(space.selectedStar)
        uare.draw()
    elseif space.mode == "process" then 
        processUI()
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", 15, 500, 850, 185)
        local signal = space.stars.getSelectedSignal(space.selectedStar, space.selectedFreq)
        love.graphics.setColor(0.9, 0.9, 0.9)
        drawStarPortrait(space.selectedStar, game)
        if signal ~= nil then  
            drawSignalLine(signal, 200, 630)
            space.isSignal = true
            if space.showComments then 
                love.graphics.setFont(game.textFont)
                love.graphics.setColor(0.9,0.9,0.9)
                love.graphics.print("What is your opinion?", 480, 510)
                comment1.text.display = signal.comments[1]
                comment2.text.display = signal.comments[2]
                comment3.text.display = signal.comments[3]
            end
        else 
            space.showComments = false
            space.isSignal = false
            love.graphics.setFont(game.textFont)
            love.graphics.print("No signal detected on this frequency", 230, 510)
        end
        uare.draw()
    elseif space.mode == "message" then 
        messageUI()
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", 15, 500, 850, 185)
        love.graphics.setColor(0.9,0.9,0.9)
        love.graphics.setFont(game.textFont)
        love.graphics.print(space.message[1], 80, 520)
        if space.message[2] ~= nil then
            love.graphics.print(space.message[2], 80, 535)
        end
        if space.message[3] ~= nil then
            love.graphics.print(space.message[3], 80, 580)
        end
        uare.draw()
    elseif space.mode == "analyseMessage" then
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", 15, 500, 850, 185)
        love.graphics.setColor(0.9,0.9,0.9)
        love.graphics.setFont(game.textFont)
        love.graphics.print("Mission control is analysing this signal. Please wait", 80, 520)
        love.graphics.setColor(0,0.8,0)
        love.graphics.setLineWidth(1.5)
        love.graphics.line(space.line[1], space.line[2], space.line[3], space.line[4])
    end
end
space.draw = drawWorld


return space