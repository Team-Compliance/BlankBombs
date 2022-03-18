BlankBombsMod = RegisterMod("Blank Bombs", 1)
local mod = BlankBombsMod

CollectibleType.COLLECTIBLE_BLANK_BOMBS = Isaac.GetItemIdByName("Blank Bombs")

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

function mod:BombUpdate(bomb)
	local player = mod:GetPlayerFromTear(bomb)
	if player then
		if bomb.Type == EntityType.ENTITY_BOMB then
			if bomb.Variant ~= BombVariant.BOMB_THROWABLE then
				if player:HasCollectible(CollectibleType.COLLECTIBLE_BLANK_BOMBS) then
					local sprite = bomb:GetSprite()
					
					if bomb.FrameCount == 1 then
						if bomb.Variant == BombVariant.BOMB_NORMAL then
							if not bomb:HasTearFlags(TearFlags.TEAR_BRIMSTONE_BOMB) then
								if bomb:HasTearFlags(TearFlags.TEAR_GOLDEN_BOMB) then
									sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/bombs/costumes/blank_bombs_gold.png")
									sprite:LoadGraphics()
								else
									sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/bombs/costumes/blank_bombs.png")
									sprite:LoadGraphics()
								end
							end
						end
					end
						
					if sprite:IsPlaying("Explode") then
						mod:DoBlankEffect(player)
					end	
				end
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, mod.BombUpdate)

function mod:DoBlankEffect(player)
	local entities = Isaac.GetRoomEntities()
	for i=1,#entities do
		if entities[i]:IsVulnerableEnemy() then
			entities[i]:AddConfusion(EntityRef(player), 30, true)
		end
		if entities[i].Type == EntityType.ENTITY_PROJECTILE then
			entities[i]:Die()
		end
	end
end

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