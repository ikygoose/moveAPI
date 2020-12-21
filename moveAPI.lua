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

--- orientation constants
X = 1
Y = 2
Z = 3
DIRECTION = 4


--- private turtle data
local data = {
    orientation = {0, 0, 0, NORTH},
    refuelSlot = 1,
    refuelAmount = 1,
}

--- turns the turtle to a given relative or absolute direction
function turn( direction )
    --- handle the absolute directions
    if direction >= NORTH and direction <= WEST then
        if direction == (data.orientation[DIRECTION] + RIGHT) % DIRECTIONS then
            turtle.turnRight()
        elseif direction == (data.orientation[DIRECTION] + LEFT) % DIRECTIONS then
            turtle.turnLeft()
        elseif direction ~= data.orientation[DIRECTION] then
            turtle.turnRight()
            turtle.turnRight()
        end
        data.orientation[DIRECTION] = direction
    --- handle the relative directions
    elseif direction == RIGHT or direction == LEFT then
        if direction == RIGHT then
            turtle.turnRight()
        else
            turtle.turnLeft()
        end
        data.orientation[DIRECTION] = (data.orientation[DIRECTION] + direction) % DIRECTIONS
    end
end

--- moves the turtle in a given direction, returns false on collision or running out of fuel
function move( direction, distance, collisionCallBack, fuelCallBack )
    if direction >= NORTH and direction <= WEST or direction == RIGHT or direction == LEFT then
        turn(direction)
        moveLoop(FORWARD, distance, turtle.forward, collisionCallBack, fuelCallBack)
    elseif direction == UP then
        moveLoop(UP, distance, turtle.up, collisionCallBack, fuelCallBack)
    elseif direction == DOWN then
        moveLoop(DOWN, distance, turtle.down, collisionCallBack, fuelCallBack)
    elseif direction == BACK then
        moveLoop(BACK, distance, turtle.back, collisionCallBack, fuelCallBack)
    end
end

--- handles the movement logic for moving in a single direction
function moveLoop(direction, distance, moveCallBack, collisionCallBack, fuelCallBack)
    i = distance
    while i > 0 do
        if moveCallBack() then
            updatePosition(direction)
        else
            if requiresFuel() then
                if not refuel() then
                    fuelCallBack()
                    return false
                end
            else
                collisionCallBack()
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
        data.orientation[Y] = data.orientation[Y] + 1
    elseif direction == DOWN then
        data.orientation[Y] = data.orientation[Y] - 1

    elseif direction == NORTH then
        data.orientation[Z] = data.orientation[Z] - 1
    elseif direction == SOUTH then
        data.orientation[Z] = data.orientation[Z] + 1

    elseif direction == EAST then
        data.orientation[X] = data.orientation[X] + 1
    elseif direction == WEST then
        data.orientation[X] = data.orientation[X] - 1
    end

    --- handles the relative directions
    if direction == FORWARD then
        updatePosition(data.orientation[DIRECTION])
    elseif direction == BACK then
        updatePosition((data.orientation[DIRECTION] + 2) % DIRECTIONS)
    end
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
