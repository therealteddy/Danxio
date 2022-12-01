-- Libraries 
require("modules/geometry") -- fancy stuff!
require("modules/wait") -- sleep() 

wf = require "modules/windfield" -- love.physics wrapper 
anim = require "modules/anim8" -- animation library
sti = require "modules/sti" --Tiled implementation

function love.load() 

    -- ? Game state 
    gameState = {} 
    gameState.levels = {} 
    gameState.levels.isLevelLoaded = false 

    -- Stop Blur /w scale 
    love.graphics.setDefaultFilter("nearest", "nearest") 

    -- Sound Sources
    sounds = {} 
    sounds.bg = {}
    sounds.sfx = {} 
    sounds.bg.airship_blues = love.audio.newSource("sounds/airship_blues.mp3", "stream") 
    sounds.bg.dreamchasers_on_route = love.audio.newSource("sounds/dreamchasers_on_route.mp3", "stream")
    sounds.bg.currentMusic = sounds.bg.dreamchasers_on_route
    sounds.bg.currentMusic:setLooping(true)
    sounds.bg.currentMusic:play()
    sounds.sfx.jump = love.audio.newSource("sounds/sfx/jump.wav", "static") 

    -- Physics World 
    world = wf.newWorld(0, 0, true)
    world:setGravity(0, 512)
    world:addCollisionClass('Player')
    world:addCollisionClass('Platform')
    world:addCollisionClass('Enemy')

    -- Maps 
    startMap = sti("maps/start.lua")
    levelMap = sti("maps/level.lua") 

    -- Collision Walls 
    walls = {} 
    walls.bottom = {}
    walls.top = {} 
    walls.left = {} 
    walls.right = {} 
    walls.platform = {}

    if startMap.layers['bottom_walls'] then 
        for i, obj in pairs(startMap.layers["bottom_walls"].objects) do 
            local OFFSET_BOTTOM_Y = obj.y - obj.height/2 -- Up by 16 
            bottom_wall = world:newRectangleCollider(obj.x, OFFSET_BOTTOM_Y, obj.width, obj.height) 
            bottom_wall:setType('static') 
            bottom_wall:setCollisionClass("Platform")
            table.insert( walls.bottom, bottom_wall ) 
        end
    end
    if startMap.layers["left_walls"] then 
        for i, obj in pairs(startMap.layers["left_walls"].objects) do 
            local OFFSET_LEFT_X = obj.x - obj.width*2 -- Left by 64
            left_wall = world:newRectangleCollider(OFFSET_LEFT_X, obj.y, obj.width, obj.height) 
            left_wall:setType('static') 
            table.insert(walls.left, left_wall)
        end
    end
    if startMap.layers["right_walls"] then 
        for i, obj in pairs(startMap.layers["right_walls"].objects) do 
            local OFFSET_RIGHT_X = obj.x + obj.width -- Right by 32
            right_wall = world:newRectangleCollider(OFFSET_RIGHT_X, obj.y, obj.width, obj.height) 
            right_wall:setType('static') 
            table.insert(walls.right, right_wall) 
        end
    end
    if startMap.layers["top_walls"] then 
        for i, obj in pairs(startMap.layers["top_walls"].objects) do 
            local OFFSET_TOP_Y = obj.y - ( 1.5 * obj.height) -- Up by 48? 
            top_wall = world:newRectangleCollider(obj.x, OFFSET_TOP_Y, obj.width, obj.height)
            top_wall:setType('static') 
            table.insert(walls.top, top_wall)
        end
    end

    -- Player 
    player = {}
    player.position = geometry.newVector(0, 0) 
    player.size = {w=32, h=32}
    player.spriteScale = {x=2.5, y=2.5} 
    player.spriteSheet = love.graphics.newImage("art/runner-sheet.png")
    player.grid = anim.newGrid(32, 32, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())
    player.animations = {} 
    player.animations.idleRight = anim.newAnimation(player.grid('1-5', 1), 0.1) -- 1-4 coloums and 1st row
    player.animations.moveRight = anim.newAnimation(player.grid('1-8', 2), 0.1)
    player.animations.jumpRight = anim.newAnimation(player.grid('1-4', 3), 0.1)
    player.animations.idleLeft = player.animations.idleRight:clone():flipH() 
    player.animations.moveLeft = player.animations.moveRight:clone():flipH() 
    player.animations.jumpLeft = player.animations.jumpRight:clone():flipH()
    player.animations.state = player.animations.idleRight
    player.isRight = true
    player.inAir = false 
    player.isDead = false 
    player.collider = world:newRectangleCollider(player.position.x, player.position.y, (player.size.w*player.spriteScale.x), (player.size.h*player.spriteScale.y))
    player.collider.isOnGround = false 
    player.collider:setCollisionClass('Player') 

    -- Jumping Mechanics 
    local function groundCollision(collider1, collider2) 
        if collider1.collision_class == 'Player' and collider2.collision_class == 'Platform' then 
            player.collider.isOnGround = true
        end 
    end
    
    player.collider:setPreSolve(groundCollision)
end 

function love.update(dt) 

    -- Initial player position and velocity
    player.collider.isOnGround = false
    vx , vy = player.collider:getLinearVelocity()

    -- Movement and Animation State 
    function love.keypressed( key ) 
    
        if key == 'return' then 
            gameState.levels.isLevelLoaded = true 
        else 
            gameState.levels.isLevelLoaded = false 
        end

        if key == 'd' then 
            player.animations.state = player.animations.moveRight
            player.collider:setLinearVelocity(300, vy)
            player.isRight = true 
            player.inAir = false 
        end 

        if key == 'a' then 
            player.animations.state = player.animations.moveLeft
            player.collider:setLinearVelocity(-300, vy)
            player.isRight = false  
            player.inAir = false 
        end
    
        if key == 'w' and player.collider.isOnGround then 
            sounds.sfx.jump:play()
            player.collider:applyLinearImpulse(0, -3000)
            if player.isRight == true then 
                player.animations.state = player.animations.jumpRight
                player.inAir = true 
            end
            if player.isRight == false then 
                player.animations.state = player.animations.jumpLeft
                player.inAir = true
            end
        end
    end

    function love.keyreleased( key ) 

        if key == 'd' then 
            player.animations.state = player.animations.idleRight
            player.collider:setLinearVelocity(0, vy) -- Disable Inertia
            if love.keyboard.isDown('a') then 
                player.animations.state = player.animations.moveLeft 
                player.collider:setLinearVelocity(-300, vy)
            end
        end

        if key == 'a' then 
            player.animations.state = player.animations.idleLeft
            player.collider:setLinearVelocity(0, vy) -- Disable Inertia
            if love.keyboard.isDown('d') then 
                player.animations.state = player.animations.moveRight
                player.collider:setLinearVelocity(300, vy)
            end
        end

        if key == 'w' then
            player.inAir = false
            player.collider:setLinearVelocity(vx, 0)
            if player.isRight == true and player.inAir == false then 
                player.animations.state = player.animations.idleRight 
                if love.keyboard.isDown('d') then 
                    player.animations.state = player.animations.moveRight
                    player.collider:setLinearVelocity(300, vy)
                end
            end 
            if player.isRight == false and player.inAir == false then 
                player.animations.state = player.animations.idleLeft
                if love.keyboard.isDown('a') then 
                    player.animations.state = player.animations.moveLeft
                    player.collider:setLinearVelocity(-300, vy)
                end
            end 
        end

    end

    -- Update Animation Instance (anim8)
    player.animations.state:update(dt)

    
    -- Physics Update 
    player.position.x = player.collider:getX() - player.size.w --Offset On X
    player.position.y = player.collider:getY() - player.size.h --Offset on X
    world:update(dt)
end

function love.draw() 

    startMap:draw()

    -- Follow Player -> Camera 
    love.graphics.push() 
    love.graphics.translate(-player.collider:getX()+(600/2), -player.collider:getY()+(800/2))
    love.graphics.pop()

    -- DRAW_METHOD                     SURFACE:           X_POS:             Y_POS:        ROTATION:            SCALE X/Y:
    player.animations.state:draw(player.spriteSheet, player.position.x, player.position.y, nil, player.spriteScale.x, player.spriteScale.y)
    
    -- * Collider Debuging
    -- world:draw()

end


