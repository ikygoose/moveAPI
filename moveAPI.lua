---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by ikygoose.
--- DateTime: 12/21/2020 12:35 PM
---

--- movement constants
DIRECTIONS = 4

NORTH = 0
EAST = 1
SOUTH = 2
WEST = 3

RIGHT = 2 * DIRECTIONS + 1
LEFT = 2 * DIRECTIONS - 1

UP = 10
DOWN = 11
FORWARD = 12
BACK = 13

--- axis constants
X = 1
Y = 2
Z = 3

--- private turtle data
local data = {
    orientation = {
        x = 0,
        y = 0,
        z = 0,
        direction = NORTH
    },
    refuelSlot = 1,
    refuelAmount = 1,
}

local yieldTime = os.clock()
local function yield()
    if os.clock() - yieldTime > 2 then
        os.queueEvent("yieldEvent")
        os.pullEvent("yieldEvent")
        yieldTime = os.clock()
    end
end

--- allow somewhat controlled access to the movement data
function getOrientation()
    return data.orientation
end

function getRefuelSlot()
    return data.refuelSlot
end

function getRefuelAmount()
    return data.refuelAmount
end

function setOrientation( orientation )
    data.orientation = orientation
end

function setRefuelSlot( slot )
    data.refuelSlot = slot
end

function setRefuelAmount( amount )
    data.refuelAmount = amount
end

Node = {
    x = 0,
    y = 0,
    z = 0,
    g = 0,
    h = 0,
    f = 0,
    walkable = true,
    parent = nil,
}

function Node:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Node:key()
    return self:generateKey( self.x, self.y, self.z )
end

function Node:generateKey(x, y, z)
    return x .. ":" .. y .. ":" .. z
end

function Node:reset( maxCost )
    self.g = maxCost
    self.f = maxCost
end

function Node:calculateH( target )
    self.h = math.abs(target.x - self.x) + math.abs(target.y - self.y) + math.abs(target.z - self.z)
end

function Node:calculateF()
    self.f = self.g + self.h
end

function Node:calculateG( parent )
    self.g = parent.g + 1
    self.parent = parent
end

function Node:lessThan( node )
    return self.f < node.f
end

--- adaptive move function
--- uses A* to path find around obstacles
function pathTo( x, y, z, maxCost, unreachableCallBack, collisionCallBack, saveCallBack, fuelCallBack )
    unreachableCallBack = unreachableCallBack or function() end
    saveCallBack = saveCallBack or function() end
    fuelCallBack = fuelCallBack or function() end

    nodes = {}
    searching = true
    order = {X,Y,Z}

    function collision(direction)
        if direction == UP then
            if turtle.detectUp() then
                nodes[Node:generateKey(data.orientation.x,data.orientation.y + 1,data.orientation.z)].walkable = false
            end
        elseif direction == DOWN then
            if turtle.detectDown() then
                nodes[Node:generateKey(data.orientation.x,data.orientation.y - 1,data.orientation.z)].walkable = false
            end

        elseif turtle.detect() then
            if data.orientation.direction == NORTH then
                nodes[Node:generateKey(data.orientation.x,data.orientation.y,data.orientation.z - 1)].walkable = false
            elseif data.orientation.direction == SOUTH then
                nodes[Node:generateKey(data.orientation.x,data.orientation.y,data.orientation.z + 1)].walkable = false

            elseif data.orientation.direction == EAST then
                nodes[Node:generateKey(data.orientation.x + 1,data.orientation.y,data.orientation.z)].walkable = false
            elseif data.orientation.direction == WEST then
                nodes[Node:generateKey(data.orientation.x - 1,data.orientation.y,data.orientation.z)].walkable = false
            end
        end
        collisionCallBack(direction)
    end

    while searching do
        target = findPath( x, y, z, nodes, maxCost )

        if target == nil then
            unreachableCallBack()
            return false
        end

        stack = {}
        while target ~= nil do
            table.insert(stack, 1, target )
            target = target.parent
        end

        reached = false
        for i, node in ipairs(stack) do
            reached = moveTo(node.x, node.y, node.z, order, saveCallBack, collision, fuelCallBack )
            if not reached then
                newNodes = {}
                for key, node in pairs(nodes) do
                    if not node.walkable then
                        newNodes[key] = node
                    end
                end
                nodes = newNodes
                break
            end
        end

        if reached then
            searching = false
        end
    end
    return true
end

function findPath(x, y, z, nodes, maxCost, yieldCount )
    minCost = 0
    target = Node:new({x = x, y = y, z = z} )
    start = Node:new({x = data.orientation.x, y = data.orientation.y, z = data.orientation.z} )
    stop = nil

    open = {}
    closed = {}

    for key, node in pairs(nodes) do
        node:reset( maxCost )
        open[key] = node
    end

    open[start:key()] = start

    while minCost < maxCost do
        yield()
        current = nil
        for key, node in pairs(open) do
            current = node
            break
        end
        --- select the node of least cost
        for key, node in pairs(open) do
            yield()
            if node:lessThan(current) then
                current = node
            end
        end

        closed[current:key()] = current
        open[current:key()] = nil

        minCost = current.f

        --- if we cannot reach the target because it's blocked, exit
        if open[target:key()] ~= nil and not open[target:key()].walkable or closed[target:key()] ~= nil and not closed[target:key()].walkable then
            return nil
        end

        --- if we have found the target, return the stopping node
        if current.x == x and current.y == y and current.z == z then
            stop = current
            break
        end

        --- calculate neighboring blocks
        neighbours = {}
        for i = -1, 1, 2 do
            node1 = Node:new( {x = current.x + i, y = current.y, z = current.z } )
            node2 = Node:new( {x = current.x, y = current.y + i, z = current.z } )
            node3 = Node:new( {x = current.x, y = current.y, z = current.z + i } )
            neighbours[node1:key()] = node1
            neighbours[node2:key()] = node2
            neighbours[node3:key()] = node3
        end

        --- calculate cost of neighbors
        for key, node in pairs(neighbours) do
            node:reset(maxCost)
            if (open[key] == nil or open[key].walkable) and closed[key] == nil then
                if open[key] == nil then
                    open[key] = node
                    open[key]:calculateH(target)
                end
                if current:lessThan(open[key]) then
                    open[key]:calculateG(current)
                    open[key]:calculateF()
                    open[key].parent = current
                end
            end
        end
    end

    --- populate the nodes table with the discovered blocks
    for key, node in pairs(open) do
        yield()
        nodes[key] = node
    end
    for key, node in pairs(closed) do
        yield()
        nodes[key] = node
    end
    return stop
end


--- turns the turtle to a given relative or absolute direction
--- saveCallBack is called after finishing a full turn
function turn( direction, saveCallBack )
    saveCallBack = saveCallBack or function() end

    --- handle the absolute directions
    if direction >= NORTH and direction <= WEST then
        if direction == (data.orientation.direction + RIGHT) % DIRECTIONS then
            turtle.turnRight()
        elseif direction == (data.orientation.direction + LEFT) % DIRECTIONS then
            turtle.turnLeft()
        elseif direction ~= data.orientation.direction then
            turtle.turnRight()
            turtle.turnRight()
        end
        data.orientation.direction = direction
    --- handle the relative directions
    elseif direction == RIGHT or direction == LEFT then
        if direction == RIGHT then
            turtle.turnRight()
        else
            turtle.turnLeft()
        end
        data.orientation.direction = (data.orientation.direction + direction) % DIRECTIONS
        saveCallBack()
    end
end

--- moves the turtle in a given direction, returns false on collision or running out of fuel
function move( direction, distance, saveCallBack, collisionCallBack, fuelCallBack )
    saveCallBack = saveCallBack or function() end
    collisionCallBack = collisionCallBack or function(direction) end
    fuelCallBack = fuelCallBack or function() end

    if direction >= NORTH and direction <= WEST or direction == RIGHT or direction == LEFT or direction == FORWARD then
        turn(direction, saveCallBack)
        return moveLoop(FORWARD, distance, turtle.forward, saveCallBack, collisionCallBack, fuelCallBack)
    elseif direction == UP then
        return moveLoop(UP, distance, turtle.up, saveCallBack, collisionCallBack, fuelCallBack)
    elseif direction == DOWN then
        return moveLoop(DOWN, distance, turtle.down, saveCallBack, collisionCallBack, fuelCallBack)
    elseif direction == BACK then
        return moveLoop(BACK, distance, turtle.back, saveCallBack, collisionCallBack, fuelCallBack)
    end
    return true
end

--- moves to a give coordinate in the axis order specified by the 'order' table
--- order = {Y, X, Z} where X, Y, and Z are the orientation constants
--- returns false if unable to move
function moveTo( x, y, z, order, saveCallBack, collisionCallBack, fuelCallBack )
    saveCallBack = saveCallBack or function() end
    collisionCallBack = collisionCallBack or function(direction) end
    fuelCallBack = fuelCallBack or function() end

    --- calculate the differentials
    dx = x - data.orientation.x
    dy = y - data.orientation.y
    dz = z - data.orientation.z

    --- move the turtle in the ordering given by the order table
    for i, axis in ipairs(order) do
        if axis == X then
            if not moveOrdering(dx, EAST, WEST, saveCallBack, collisionCallBack, fuelCallBack ) then
                return false
            end
        end
        if axis == Y then
            if not moveOrdering(dy, UP, DOWN, saveCallBack, collisionCallBack, fuelCallBack ) then
                return false
            end
        end
        if axis == Z then
            if not moveOrdering(dz, SOUTH, NORTH, saveCallBack, collisionCallBack, fuelCallBack ) then
                return false
            end
        end
    end
    return true
end

--- handles which direction to go based on the differential
function moveOrdering( dl, positiveDirect, negativeDirection, saveCallBack, collisionCallBack, fuelCallBack)
    if dl > 0 then
        return move(positiveDirect, dl, saveCallBack, collisionCallBack, fuelCallBack )
    elseif dl < 0 then
        return move(negativeDirection, math.abs(dl), saveCallBack, collisionCallBack, fuelCallBack )
    end
    return true
end

--- checks if fuel is required
function requiresFuel()
    return turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() <= 0
end

--- tries to refuel from the refuel slot, returns true if successful
function refuel()
    slot = turtle.getSelectedSlot()
    turtle.select( data.refuelSlot )
    refueled = turtle.refuel( data.refuelAmount )
    turtle.select( slot )
    return refueled
end

--- saves the movement data to a given file location
function saveData( file )
    fileHandle = fs.open(file, "w")
    text = textutils.serialize( data )
    fileHandle.write(text)
    fileHandle.close()
end

--- loads movement data from a given file location
function loadData ( file )
    fileHandle = fs.open(file, "r")
    text = fileHandle.readAll()
    data = textutils.unserialize( text )
    fileHandle.close()
end

--- attempts to locate the turtle's position and direction using two gps calls
--- the turtle attempts to move forward after the first gps call to calculate the direction
function locate( timeout, gpsCallBack, saveCallBack, collisionCallBack, fuelCallBack )
    gpsCallBack = gpsCallBack or function() end
    saveCallBack = saveCallBack or function() end
    collisionCallBack = collisionCallBack or function(direction) end
    fuelCallBack = fuelCallBack or function() end

    x1, y1, z1 = gps.locate(timeout)
    if x1 == nil then
        gpsCallBack()
        return false
    end

    if not move(FORWARD, 1, saveCallBack, collisionCallBack, fuelCallBack ) then
        return false
    end

    x2, y2, z2 = gps.locate(timeout)

    if x2 == nil then
        gpsCallBack()
        return false
    end

    dx = x2 - x1
    dz = z2 - z1

    data.orientation.x = x2
    data.orientation.y = y2
    data.orientation.z = z2

    if dx > 0 then
        data.orientation.direction = EAST
    elseif dx < 0 then
        data.orientation.direction = WEST
    elseif dz > 0 then
        data.orientation.direction = SOUTH
    elseif dz < 0 then
        data.orientation.direction = NORTH
    end

    saveCallBack()
    return true
end

--- handles the movement logic for moving in a single direction
--- saveCallBack is run after each movement is made
function moveLoop(direction, distance, moveCallBack, saveCallBack, collisionCallBack, fuelCallBack)
    i = distance
    while i > 0 do
        if moveCallBack() then
            updatePosition(direction)
            saveCallBack()
        else
            if requiresFuel() then
                if not refuel() then
                    fuelCallBack()
                    return false
                end
            else
                collisionCallBack( direction )
                return false
            end
        end
        i = i - 1
    end
    return true
end

--- updates the position by 1 for a given direction
function updatePosition( direction )
    --- handles the base case, absolute directions
    if direction == UP then
        data.orientation.y = data.orientation.y + 1
    elseif direction == DOWN then
        data.orientation.y = data.orientation.y - 1

    elseif direction == NORTH then
        data.orientation.z = data.orientation.z - 1
    elseif direction == SOUTH then
        data.orientation.z = data.orientation.z + 1

    elseif direction == EAST then
        data.orientation.x = data.orientation.x + 1
    elseif direction == WEST then
        data.orientation.x = data.orientation.x - 1
    end

    --- handles the relative directions
    if direction == FORWARD then
        updatePosition(data.orientation.direction)
    elseif direction == BACK then
        updatePosition((data.orientation.direction + 2) % DIRECTIONS)
    end
end
