BlankBombsMod = RegisterMod("Blank Bombs", 1)
local mod = BlankBombsMod

CollectibleType.COLLECTIBLE_BLANK_BOMBS = Isaac.GetItemIdByName("Blank Bombs")
local BLANK_EXPLOSION_EFFECT_VARIANT = Isaac.GetEntityVariantByName("blank explosion")
local BombsInRoom = {}
local RocketsAboutToExplode = {}

if EID then
	EID:addCollectible(CollectibleType.COLLECTIBLE_BLANK_BOMBS, "{{Bomb}} +5 Bombs#The player is immune from their own bomb damage#Placed bombs destroy enemy projectiles and knock back enemies within a radius#Bombs explode instantly upon placement#Press {{ButtonRT}} + {{ButtonLB}} to place normal bombs", "Blank Bombs", "en_us")
	EID:addCollectible(CollectibleType.COLLECTIBLE_BLANK_BOMBS, "{{Bomb}} +5 Bombas#El jugador es inmune a sus bombas#Las bombas que exploten eliminarán los disparos enemigos y empujarán a los enemigos cercanos#Las bombas explotan inmediatamente#Pula {{ButtonRT}} + {{ButtonLB}} para poner bombas normales", "Bombas de Fogueo", "spa")
	EID:addCollectible(CollectibleType.COLLECTIBLE_BLANK_BOMBS, "{{Bomb}} +5 бомб#Игрок невосприимчив к урону от собственной бомбы#Размещенные бомбы уничтожают вражеские снаряды и отбрасывают врагов в радиусе#Бомбы мгновенно взрываются при размещении#Нажмите кнопку {{ButtonRT}} + {{ButtonLB}}, чтобы разместить обычные бомбы", "Пустые бомбы", "ru")
	EID:addCollectible(CollectibleType.COLLECTIBLE_BLANK_BOMBS, "{{Bomb}} +5 Bombas#O jogador e imune a dano de suas próprias bombas#Bombas colocadas destroem projetéis de inimigos e derrubam eles assim que elas são colocadas#Pressione {{ButtonRT}} + {{ButtonLB}} para colocar bombas normais", "Bombas de Festim", "pt_br")
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
      {str = "The player is immune from their own bomb damage."},
      {str = "Blank Bombs explode instantly upon placement."},
      {str = "If the Drop Key + Bomb Key is pressed, bombs get placed normally."},
      {str = "Blank Bomb explosions destroy all enemy projectiles within a radius."},
      {str = "Blank Bomb explosions knock back enemies within a radius."},
    },
    { -- Interactions
      {str = "Interactions", fsize = 2, clr = 3, halign = 0},
      {str = "External Item Descriptions: Provides a description for the item."},
      {str = "Encyclopedia: Provides a more detailed description for the item."},
      {str = "MinimapiItemsAPI: Provides a minimap icon for the item."},
    },
    { -- Trivia
      {str = "Trivia", fsize = 2, clr = 3, halign = 0},
      {str = "Blank Bombs were a scrapped item concept from the acclaimed Antibirth mod."},
      {str = "This item was coded by kittenchilly and Thicco Catto, with spritework done by Royal, ALADAR, and Demi!"},
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
	if bomb.Variant ~= BombVariant.BOMB_NORMAL and bomb.Variant ~= BombVariant.BOMB_GIGA and
	bomb.Variant ~= BombVariant.BOMB_ROCKET then return false end

	local player = mod:GetPlayerFromTear(bomb)
	if not player then return false end

	local isRandomNancyBlankBomb = false
	if player:HasCollectible(CollectibleType.COLLECTIBLE_NANCY_BOMBS) and not
	player:HasCollectible(CollectibleType.COLLECTIBLE_BLANK_BOMBS) then
		local rng = RNG()
		rng:SetSeed(bomb.InitSeed, 35)

		isRandomNancyBlankBomb = rng:RandomInt(100) < 7
	end

	if not player:HasCollectible(CollectibleType.COLLECTIBLE_BLANK_BOMBS) and not isRandomNancyBlankBomb then return false end

	return true
end


---@param bomb EntityBomb
local function CanBombInstaDetonate(bomb)
	local wasInRoom = false
	local bombPtr = GetPtrHash(bomb)
	for _, bombInRoom in ipairs(BombsInRoom) do
		if bombPtr == bombInRoom then
			wasInRoom = true
		end
	end

	return not (wasInRoom or bomb.IsFetus or bomb.Variant == BombVariant.BOMB_ROCKET or
	bomb.Variant == BombVariant.BOMB_GIGA or bomb.Variant == BombVariant.BOMB_ROCKET_GIGA)
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
	if bomb.Variant == BombVariant.BOMB_GIGA then return end

	local sprite = bomb:GetSprite()

	local spritesheetPreffix = ""
	local spritesheetSuffix = ""

	if bomb.Variant == BombVariant.BOMB_ROCKET then
		spritesheetPreffix = "rocket_"
	elseif bomb:HasTearFlags(TearFlags.TEAR_BRIMSTONE_BOMB) then
		spritesheetPreffix = "brimstone_"
	end

	if bomb:HasTearFlags(TearFlags.TEAR_GOLDEN_BOMB) then
		spritesheetSuffix = "_gold"
	end

	sprite:ReplaceSpritesheet(0, "gfx/items/pick ups/bombs/costumes/" .. spritesheetPreffix .. "blank_bombs" .. spritesheetSuffix .. ".png")
	sprite:LoadGraphics()

	--Instantly explode if player isn't pressing ctrl
	if not CanBombInstaDetonate(bomb) then return end

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
		if bomb:HasTearFlags(TearFlags.TEAR_SCATTER_BOMB) then
			for _, scatterBomb in ipairs(Isaac.FindByType(EntityType.ENTITY_BOMB)) do
				if scatterBomb.FrameCount == 0 then
					table.insert(BombsInRoom, GetPtrHash(scatterBomb))
				end
			end
		end

		local explosionRadius = GetBombExplosionRadius(bomb)
		if bomb:HasTearFlags(TearFlags.TEAR_GIGA_BOMB) then
			explosionRadius = 99999
		end
		mod:DoBlankEffect(bomb.Position, explosionRadius)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, mod.BombUpdate)


function mod:OnMonstroUpdate(monstro)
	if monstro:GetData().IsAbusedMonstro then

		SFXManager():Stop(SoundEffect.SOUND_FORESTBOSS_STOMPS)

		for _, effect in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.POOF02)) do
			if effect.FrameCount == 0 then
				effect:Remove()
			end
		end

		monstro:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mod.OnMonstroUpdate, EntityType.ENTITY_MONSTRO)


---@param rocket EntityEffect
function mod:OnEpicFetusRocketUpdate(rocket)
	if rocket.Timeout ~= 0 then return end

	local ptrHash = GetPtrHash(rocket)

	local isGonnaExplode = false

	for i, otherPtr in ipairs(RocketsAboutToExplode) do
		if ptrHash == otherPtr then
			table.remove(RocketsAboutToExplode, i)
			isGonnaExplode = true
		end
	end

	if isGonnaExplode then
		mod:DoBlankEffect(rocket.Position, 90)
	else
		table.insert(RocketsAboutToExplode, ptrHash)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.OnEpicFetusRocketUpdate, EffectVariant.ROCKET)


function ScreenWobble(position)
	local abusedMonstro = Isaac.Spawn(EntityType.ENTITY_MONSTRO, 0, 0, position, Vector.Zero, nil)
	abusedMonstro = abusedMonstro:ToNPC()

	abusedMonstro.Visible = false
	abusedMonstro.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
	abusedMonstro.GridCollisionClass = GridCollisionClass.COLLISION_NONE
	abusedMonstro:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
	abusedMonstro.State = NpcState.STATE_STOMP

	local monstroSpr = abusedMonstro:GetSprite()
	monstroSpr:Play("JumpDown", true)
	monstroSpr:SetFrame(32)

	abusedMonstro:GetData().IsAbusedMonstro = true
end


---@param center Vector
---@param radius number
function mod:DoBlankEffect(center, radius)
	--Spawn cool explosion effect
	local blankExplosion = Isaac.Spawn(EntityType.ENTITY_EFFECT, BLANK_EXPLOSION_EFFECT_VARIANT, 0, center, Vector.Zero, nil)
	blankExplosion:GetSprite():Play("Explode", true)
	blankExplosion.DepthOffset = 9999
	blankExplosion.SpriteScale = blankExplosion.SpriteScale * (radius/90)
	blankExplosion.Color = Color(1, 1, 1, math.min(1, radius/90))

	--Do screen wobble
	ScreenWobble(center)

	--Remove projectiles in radius
	for _, projectile in ipairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE)) do
		projectile = projectile:ToProjectile()

		local realPosition = projectile.Position - Vector(0, projectile.Height)

		if realPosition:DistanceSquared(center) <= (radius * 3) ^ 2 then
			if projectile:HasProjectileFlags(ProjectileFlags.ACID_GREEN) or
			projectile:HasProjectileFlags(ProjectileFlags.ACID_RED) or
			projectile:HasProjectileFlags(ProjectileFlags.CREEP_BROWN) or
			projectile:HasProjectileFlags(ProjectileFlags.EXPLODE) or
			projectile:HasProjectileFlags(ProjectileFlags.BURST) or
			projectile:HasProjectileFlags(ProjectileFlags.ACID_GREEN) then
				--If the projectile has any flag that triggers on hit, we need to remove the projectile
				projectile:Remove()
			else
				projectile:Die()
			end
		end
	end

	--Push enemies back
	for _, entity in ipairs(Isaac.FindInRadius(center, radius * 3, EntityPartition.ENEMY)) do
		if entity:IsActiveEnemy(false) and entity:IsVulnerableEnemy() then
			local pushDirection = (entity.Position - center):Normalized()
			entity:AddVelocity(pushDirection * 30)
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


---@param effect EntityEffect
function mod:OnBlankExplosionUpdate(effect)
	local spr = effect:GetSprite()

	if spr:IsFinished("Explode") then
		effect:Remove()
	end
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.OnBlankExplosionUpdate, BLANK_EXPLOSION_EFFECT_VARIANT)


---@param locust EntityFamiliar
---@param collider Entity
function mod:OnLocustCollision(locust, collider)
	if locust.SubType ~= CollectibleType.COLLECTIBLE_BLANK_BOMBS then return end
	if collider.Type ~= EntityType.ENTITY_PROJECTILE then return end

	local projectile = collider:ToProjectile()

	if projectile:HasProjectileFlags(ProjectileFlags.ACID_GREEN) or
	projectile:HasProjectileFlags(ProjectileFlags.ACID_RED) or
	projectile:HasProjectileFlags(ProjectileFlags.CREEP_BROWN) or
	projectile:HasProjectileFlags(ProjectileFlags.EXPLODE) or
	projectile:HasProjectileFlags(ProjectileFlags.BURST) or
	projectile:HasProjectileFlags(ProjectileFlags.ACID_GREEN) then
		--If the projectile has any flag that triggers on hit, we need to remove the projectile
		projectile:Remove()
	else
		projectile:Die()
	end
end
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, mod.OnLocustCollision, FamiliarVariant.ABYSS_LOCUST)

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
