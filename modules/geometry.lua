-- Simple Geometry Method Collection
geometry = {}
geometry.__index = geometry 

function geometry.newVector(x,y) 
    instance = setmetatable({}, geometry)
    instance.x = x 
    instance.y = y 
    return instance 
end

function geometry:printVectors()
    print(self.x .. " | " ..  self.y)
end

function geometry.subVectors(v1, v2)
    instance = setmetatable({}, geometry)
    instance.xdiff = (v2.x - v1.x) 
    instance.ydiff = (v2.y - v1.y)
    instance.difference = {instance.xdiff, instance.ydiff} -- 1 for x & 2 for y
    return instance 
end 

function geometry.addVectors(v1, v2) 
    instance = setmetatable({}, geometry)
    instance.xadd = (v1.x + v2.x) 
    instance.yadd = (v1.y + v2.y) 
    instance.addition = {instance.xadd, instance.yadd} -- 1 for x & 2 for y
    return instance
end

function geometry.manhattan(XDIFF, YDIFF)
    instance = setmetatable({}, geometry)
    instance.distance = math.sqrt((XDIFF)^2 + (YDIFF)^2) -- Pythagorian Theorum
    return instance
end
