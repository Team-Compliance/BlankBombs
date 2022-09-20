BlankBombsMod = RegisterMod("Blank Bombs", 1)
local mod = BlankBombsMod

CollectibleType.COLLECTIBLE_BLANK_BOMBS = Isaac.GetItemIdByName("Blank Bombs")
local BombsInRoom = {}

if EID then
	EID:addCollectible(CollectibleType.COLLECTIBLE_BLANK_BOMBS, "Placed bombs destroy all enemy projectiles and confuse all enemies for 1 second upon exploding#+5 Bombs", "Blank Bombs", "en_us")
	EID:addCollectible(CollectibleType.COLLECTIBLE_BLANK_BOMBS, "Las bombas que exploten eliminarán todos los disparos enemigos y confundirán a los enemigos por 1 segundo#+5 Bombas", "Bomas de Fogueo", "spa")
	EID:addCollectible(CollectibleType.COLLECTIBLE_BLANK_BOMBS, "Размещенные бомбы уничтожают все вражеские снаряды и сбивают с толку всех врагов на 1 секунду после взрыва#+5 бомб.", "Пустые бомбы", "ru")
	EID:addCollectible(CollectibleType.COLLECTIBLE_BLANK_BOMBS, "Bombas colocadas destroem todos projéteis de enemigos e confundi todos enemigos por 1 segundo depois de explodir#+5 Bombas", "Bombas de Festim", "pt_br")
end
if MiniMapiItemsAPI then
    local frame = 1
    local blankbombsSprite = Sprite()
    blankbombsSprite:Load("gfx/ui/minimapitems/antibirthitempack_blankbombs_icon.anm2", true)
    MiniMapiItemsAPI:AddCollectible(CollectibleType.COLLECTIBLE_BLANK_BOMBS, blankbombsSprite, "CustomIconBlankBombs", frame)
end

local Wiki = {
  BlankBombs = {
    { -- Effect
      {str = "Effect", fsize = 2, clr = 3, halign = 0},
      {str = "Gives the player 5 bombs."},
      {str = "Blank Bomb explosions destroy all enemy projectiles."},
      {str = "Explosions confuse all enemies in the current room for 1 second."},
	},
	{ -- Interactions
      {str = "Interactions", fsize = 2, clr = 3, halign = 0},
      {str = "External Item Descriptions: Provides a description for the item."},
      {str = "Encyclopedia: Provides a more detailed description for the item."},
	  {str = "MinimapiItemsAPI: Provides a minimap icon for the item."},
    },
    { -- Trivia
      {str = "Trivia", fsize = 2, clr = 3, halign = 0},
      {str = "Blank Bombs were a scrapped item from the acclaimed Antibirth mod."},
      {str = "Originally, Blank Bombs were meant to explode instantly and not damage the player, this idea was later revised by _Kilburn."},
	  {str = "This mod was coded by kittenchilly, with spritework done by Royal and ALADAR!"},
    },
  }
}

if Encyclopedia then
	Encyclopedia.AddItem({
	  ID = CollectibleType.COLLECTIBLE_BLANK_BOMBS,
	  WikiDesc = Wiki.BlankBombs,
	  Pools = {
		Encyclopedia.ItemPools.POOL_TREASURE,
		Encyclopedia.ItemPools.POOL_GREED_TREASURE,
	  	Encyclopedia.ItemPools.POOL_BOMB_BUM,
	  },
	})
end


---@param player EntityPlayer
---@return integer
local function GetPlayerIndex(player)
	return player:GetCollectibleRNG(1):GetSeed()
end


---@param bomb Entity
---@return boolean
local function IsBlankBomb(bomb)
	if not bomb then return false end
	if bomb.Type ~= EntityType.ENTITY_BOMB then return false end
	bomb = bomb:ToBomb()
	if bomb.Variant ~= BombVariant.BOMB_NORMAL then return false end
	if bomb:HasTearFlags(TearFlags.TEAR_BRIMSTONE_BOMB) then return false end

	local player = mod:GetPlayerFromTear(bomb)
	if not player then return false end
	if not player:HasCollectible(CollectibleType.COLLECTIBLE_BLANK_BOMBS) then return false end

	return true
end


---@param bomb EntityBomb
---@return number
local function GetBombExplosionRadius(bomb)
	local damage = bomb.ExplosionDamage
	local radiusMult = bomb.RadiusMultiplier
	local radius

	if damage >= 175.0 then
		radius = 105.0
	else
		if damage <= 140.0 then
			radius = 75.0
		else
			radius = 90.0
		end
	end

	return radius * radiusMult
end


function mod:OnNewRoom()
	BombsInRoom = {}
	for _, bomb in ipairs(Isaac.FindByType(EntityType.ENTITY_BOMB)) do
		bomb = bomb:ToBomb()

		if IsBlankBomb(bomb) then
			local sprite = bomb:GetSprite()

			if bomb:HasTearFlags(TearFlags.TEAR_GOLDEN_BOMB) then
				sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/bombs/costumes/blank_bombs_gold.png")
			else
				sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/bombs/costumes/blank_bombs.png")
			end
			sprite:LoadGraphics()

			table.insert(BombsInRoom, GetPtrHash(bomb))
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)


---@param bomb EntityBomb
function mod:OnBombInitLate(bomb)
	local sprite = bomb:GetSprite()

	if bomb:HasTearFlags(TearFlags.TEAR_GOLDEN_BOMB) then
		sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/bombs/costumes/blank_bombs_gold.png")
	else
		sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/bombs/costumes/blank_bombs.png")
	end
	sprite:LoadGraphics()

	local wasInRoom = false
	local bombPtr = GetPtrHash(bomb)
	for _, bombInRoom in ipairs(BombsInRoom) do
		if bombPtr == bombInRoom then
			wasInRoom = true
		end
	end

	if wasInRoom then return end

	--Instantly explode if player isn't pressing ctrl
	local player = mod:GetPlayerFromTear(bomb)
	local controller = player.ControllerIndex

	if not Input.IsActionPressed(ButtonAction.ACTION_DROP, controller) then
		if not player:HasEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK) then
			player:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)
			player:GetData().AddNoKnockBackFlag = 2
		end

		bomb:SetExplosionCountdown(0)
	end
end


---@param bomb EntityBomb
function mod:BombUpdate(bomb)
	if not IsBlankBomb(bomb) then return end

	if bomb.FrameCount == 1 then
		mod:OnBombInitLate(bomb)
	end

	local sprite = bomb:GetSprite()
	if sprite:IsPlaying("Explode") then
		local explosionRadius = GetBombExplosionRadius(bomb)
		mod:DoBlankEffect(bomb.Position, explosionRadius)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, mod.BombUpdate)


---@param center Vector
---@param radius number
function mod:DoBlankEffect(center, radius)
	--Remove projectiles in radius
	for _, projectile in ipairs(Isaac.FindInRadius(center, radius * 3, EntityPartition.BULLET)) do
		projectile:Die()
	end

	--Push enemies back
	for _, entity in ipairs(Isaac.FindInRadius(center, radius * 3, EntityPartition.ENEMY)) do
		if entity:IsActiveEnemy(false) and entity:IsVulnerableEnemy() then
			local pushDirection = (entity.Position - center):Normalized()
			entity:AddVelocity(pushDirection * 20)
		end
	end
end


---@param entity Entity
---@param source EntityRef
function mod:OnPlayerDamage(entity, _, _, source)
	local bomb = source.Entity
	if not IsBlankBomb(bomb) then return end

	local bombPlayer = mod:GetPlayerFromTear(bomb)
	local player = entity:ToPlayer()

	if GetPlayerIndex(player) == GetPlayerIndex(bombPlayer) then
		return false
	end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.OnPlayerDamage, EntityType.ENTITY_PLAYER)


---@param player EntityPlayer
function mod:OnPlayerUpdate(player)
	if not player:GetData().AddNoKnockBackFlag then return end

	player:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)

	player:GetData().AddNoKnockBackFlag = player:GetData().AddNoKnockBackFlag - 1

	if player:GetData().AddNoKnockBackFlag == 0 then
		player:GetData().AddNoKnockBackFlag = nil
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.OnPlayerUpdate)


function mod:OnPlayerRender(player)
	local str = player:HasEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK)

	Isaac.RenderText(tostring(str), 100, 100, 1, 1, 0, 1)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, mod.OnPlayerRender)

-------

function mod:GetPlayerFromTear(tear)
	local check = tear.Parent or tear.SpawnerEntity
	if check then
		if check.Type == EntityType.ENTITY_PLAYER then
			return mod:GetPtrHashEntity(check):ToPlayer()
		elseif check.Type == EntityType.ENTITY_FAMILIAR and check.Variant == FamiliarVariant.INCUBUS then
			local data = tear:GetData()
			data.IsIncubusTear = true
			return check:ToFamiliar().Player:ToPlayer()
		end
	end
	return nil
end


function mod:GetPtrHashEntity(entity)
	if entity then
		if entity.Entity then
			entity = entity.Entity
		end
		for _, matchEntity in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, false)) do
			if GetPtrHash(entity) == GetPtrHash(matchEntity) then
				return matchEntity
			end
		end
	end
	return nil
end