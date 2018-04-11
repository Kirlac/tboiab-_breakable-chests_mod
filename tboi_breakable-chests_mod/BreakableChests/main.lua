local BreakableChests = RegisterMod("BreakableChests" , 1)
local game = Game()

local CHEST_HIT_DISTANCE = 15
local CHEST_HIT_POINTS = 12
local CHEST_KNOCKBACK_MULTIPLIER = 4
local COLOR_RED = Color(1, 0, 0, 1, 1, 1, 1)

-- Uncomment chest types below to enable them to be shot
local CHEST_ENTITY_VARIANTS = {
    -- PickupVariant.PICKUP_CHEST,
    -- PickupVariant.PICKUP_BOMBCHEST,
    PickupVariant.PICKUP_SPIKEDCHEST,
    -- PickupVariant.PICKUP_ETERNALCHEST,
    PickupVariant.PICKUP_MIMICCHEST,
    -- PickupVariant.PICKUP_LOCKEDCHEST
}

local ChestDestroyedAction = {
    NOTHING = 0,
    SPAWN_POOP = 1,
    OPEN_CHEST = 2,
    RANDOM = 3
}

local CHEST_DESTROYED_ACTION = ChestDestroyedAction.RANDOM

function BreakableChests:OnTearUpdate(tear)
    local player = Isaac.GetPlayer(0)
    local entities = Isaac:GetRoomEntities()
    for ei, entity in pairs(entities) do
        if entity.Type == EntityType.ENTITY_PICKUP then
            for _, variant in pairs(CHEST_ENTITY_VARIANTS) do
                if entity.Variant == variant then
                    if entity.SubType == ChestSubType.CHEST_CLOSED then
                        if entity.Position:Distance(tear.Position) < CHEST_HIT_DISTANCE then
                            local knockback = tear.Velocity:__div(CHEST_KNOCKBACK_MULTIPLIER)
                            BreakableChests.DamageChest(entity, player.Damage, knockback)
                            tear:Kill()
                            return
                        end
                    end
                end
            end
        end
    end
end

function BreakableChests.DamageChest(chest, damage, knockback)
    chest.HitPoints = chest.HitPoints - damage
    if chest.HitPoints < 1 then
        BreakableChests:DestroyChest(chest)
    else
        chest:SetColor(COLOR_RED, 1, 1, true, true)
        chest:AddVelocity(knockback)
    end
end

function BreakableChests:OnPickupInit(pickup)
    for _, variant in pairs(CHEST_ENTITY_VARIANTS) do
        if pickup.Variant == variant then
            pickup.HitPoints = CHEST_HIT_POINTS
        end
    end
end

function BreakableChests:DestroyChest(chest)
    local action = CHEST_DESTROYED_ACTION
    if action == ChestDestroyedAction.RANDOM then
        local rng = chest:GetDropRNG()
        action = rng:RandomInt(ChestDestroyedAction.RANDOM)
    end

    if action == ChestDestroyedAction.NOTHING then
        -- Do nothing
        chest:Kill()
    elseif action == ChestDestroyedAction.SPAWN_POOP then
        chest:Kill()
        Isaac.GridSpawn(GridEntityType.GRID_POOP, 0, chest.Position, false)
    elseif action == ChestDestroyedAction.OPEN_CHEST then
        -- TODO: Chest opening logic
        chest:ToPickup():TryOpenChest()
    end
end

BreakableChests:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, BreakableChests.OnPickupInit)

BreakableChests:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, BreakableChests.OnTearUpdate)
BreakableChests:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, BreakableChests.OnTearUpdate)
BreakableChests:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, BreakableChests.OnTearUpdate)
BreakableChests:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, BreakableChests.OnTearUpdate)