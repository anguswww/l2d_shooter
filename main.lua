function newVec2(x,y)
	return {
		x = x or 0,
		y = y or 0,

		length = function(self)
			return math.sqrt(self.x * self.x + self.y * self.y)
		end,
		normalize = function(self)
			local x
			local y
			local len = self.length(self)
		    if len ~= 0 then
		        x = self.x / len
		        y = self.y / len
		    end
		    return newVec2(x,y)
		end
	}
end

function vecDist( v1, v2 )
	return math.sqrt(math.pow(v1.x - v2.x, 2) + math.pow(v1.y - v2.y,2 ))

end

function newBullet(x, y, rotation)
	return {
		pos = newVec2(x,y),
		dir = rotation or newVec2(1,0),
		speed = 550,
		radius = 8,
		update = function (self, dt)
			self.pos.x = self.pos.x + self.dir.x * self.speed * dt
			self.pos.y = self.pos.y + self.dir.y * self.speed  * dt

		end,
		draw = function (self)
			love.graphics.circle('fill', self.pos.x, self.pos.y, self.radius)
		end
	}
end

function newEnemy(x, y, r, follow)
	return {
		pos = newVec2(x,y),
		follow = follow or player,
		dir =  newVec2(1,0),
		speed = 200,
		radius = r or 16,
		active = true,
		sound = love.audio.newSource("sound/hit.wav", "static"),
		update = function (self, dt)
		
			if self.active == true then
				self.dir.x = math.sin(angleFromPoints( self.follow.pos.x, self.follow.pos.y, self.pos.x, self.pos.y ))
				self.dir.y = math.cos(angleFromPoints( self.follow.pos.x, self.follow.pos.y, self.pos.x, self.pos.y ))
				self.pos.x = self.pos.x + self.dir.x * self.speed * dt
				self.pos.y = self.pos.y + self.dir.y * self.speed * dt

				-- collisions
				for i = 1, #enemies do
					if vecDist(enemies[i].pos, self.pos) <= self.radius*2 and enemies[i].active == true then
						if enemies[i].pos.x ~= self.pos.x and enemies[i].pos.y ~= self.pos.y then
							angle = angleFromPoints(enemies[i].pos.x, enemies[i].pos.y, self.pos.x, self.pos.y)
							self.pos.x = self.pos.x + 2 * (math.cos(angle))
							self.pos.y = self.pos.y + 2 * (math.sin(angle))
						end
					end
				end

				for i = 1, #bullets do
					if vecDist(bullets[i].pos, self.pos) < self.radius + bullets[i].radius then
						self.destroy(self)
						score = score + 100
					end
				end
			end
		end,
		draw = function (self)
			if self.active == true then
				love.graphics.circle('line', self.pos.x, self.pos.y, self.radius)
			end
		end,

		destroy =  function (self, playSound)
			sound = playSound or true
			self.active = false
			if sound then
				love.audio.play(self.sound)
			end
		end
	}
end

function newPlayer(x, y, radius)
	return {
		pos = newVec2(x,y),
		r = radius or 50, 
		speed = 500,
		dir = newVec2(0,0),
		bulletCooldown = 0.07,
		bulletTimer = 0.07,
		recoil = 600,
		health = 10,
		damageCooldown = 0.4,
		update = function (self, dt)

			local moving = false
			local shooting = false
			local deadzone = 0.4

			if controllerMode then
				local input = newVec2(controller:getAxis(1), controller:getAxis(2))
				if input.length(input) > deadzone then
					self.dir = input.normalize(input)
				end
				if controller:isDown(1) and controller:isDown(2) == false then
					moving = true
				end
				if controller:isDown(2) then
					shooting = true
				end
			else
				self.dir = newVec2(math.cos(mouseDir), math.sin(mouseDir))
				if love.keyboard.isDown("z") and love.keyboard.isDown("x") == false then
					moving = true
				end
				if love.keyboard.isDown("x") then
					shooting = true
				end
			end

			if moving then

			 	if (self.pos.x + self.dir.x * self.speed * -1 * dt > self.r) then
					if (self.pos.x + self.dir.x * self.speed * -1 * dt < sWidth - self.r) then
						self.pos.x = self.pos.x + self.dir.x * self.speed * -1 * dt
					end
				end

				if (self.pos.y + self.dir.y * self.speed * -1 * dt > self.r) then
					if (self.pos.y + self.dir.y * self.speed * -1 * dt < sWidth - self.r) then
						self.pos.y = self.pos.y + self.dir.y * self.speed * -1 * dt
					end
				end

			end

			if shooting and self.bulletTimer <= 0 then
				table.insert(bullets, newBullet( self.pos.x+self.dir.x*self.r, self.pos.y+self.dir.y*self.r, self.dir ))
				self.pos.x = self.pos.x + self.dir.x * self.recoil * -1 * dt
				self.pos.y = self.pos.y + self.dir.y * self.recoil * -1 * dt
				self.bulletTimer = self.bulletCooldown
				love.audio.stop(snd_shoot)
				love.audio.play(snd_shoot)
			end

			if self.pos.x - self.r < 0 then
				self.pos.x = self.pos.x + 4
			end
			if self.pos.y - self.r < 0 then
				self.pos.y = self.pos.y + 4
			end
			if self.pos.x > sWidth - self.r then
				self.pos.x = self.pos.x - 4
			end
			if self.pos.y > sHeight - self.r then
				self.pos.y = self.pos.y - 4
			end

			if self.bulletTimer > 0 then
				self.bulletTimer = self.bulletTimer - dt
			end

			for i = 1, #enemies do
				if vecDist(enemies[i].pos, self.pos) < self.r + enemies[i].radius  and enemies[i].active then
					if self.damageCooldown < 0 then
						self.health = self.health - 1
						love.audio.stop(snd_boom)
						love.audio.play(snd_boom)
						-- self.damageCooldown = 0.4
						if self.health < 0 then
							self.health = 0
						end
					end
					enemies[i].destroy(enemies[i], false)
					
				end
			end
			self.damageCooldown = self.damageCooldown - dt
		end,

		draw = function (self)
			love.graphics.circle( 'line', self.pos.x, self.pos.y, self.r )
			love.graphics.line( self.pos.x, self.pos.y, self.pos.x+self.dir.x*self.r, self.pos.y+self.dir.y*self.r )
		end,
		hurt = function( self )
			self.health = self.health - 1
			love.audio.stop(snd_boom)
			love.audio.play(snd_boom)
		end
	}
end

-- returns the angle from two points in radians
function angleFromPoints( x, y, a, b )

	return math.atan2(x-a,y-b)

end

function love.load()
	round = 0
	score = 0
	enemies = {}
	bullets = {}
	font = love.graphics.newFont("fonts/Open 24 Display St.ttf", 60)
	love.graphics.setFont(font)
	sWidth, sHeight = love.graphics.getDimensions( )
	areaSize = 450
	areaPos = newVec2(math.random(0, sWidth-areaSize),math.random(0, sHeight-areaSize))
	controllerMode = false
	snd_shoot = love.audio.newSource( "sound/shoot.wav", "static" )
	snd_hit = love.audio.newSource( "sound/hit.wav", "static" )
	snd_boom = love.audio.newSource( "sound/boom.wav", "static" )
	snd_beep = love.audio.newSource( "sound/beep.wav", "static" )
	local joysticks = love.joystick.getJoysticks()
	if #joysticks > 0 then
		controller = joysticks[1]
		controllerMode = true
	end
	player = newPlayer( sWidth/2, sHeight/2, 50 )
	spawnTimer = 3
	love.audio.play(snd_beep)
end

function spawnEnemies(count, areaVec, areaSize)
	spawnPositions = {}
	i = 1
	while i < count do
		x = love.math.random(10, sWidth - 10)
		y = love.math.random(10, sHeight - 10)
		if x >= areaVec.x and x <= areaVec.x + areaSize then
			if y >= areaVec.y and y <= areaVec.y + areaSize then
				goto continue
			end
		end
		
		

		table.insert( spawnPositions, newVec2(x, y) )
		i = i + 1
		::continue::
	end
	for i = 1, #spawnPositions do
		table.insert( enemies, newEnemy(spawnPositions[i].x, spawnPositions[i].y, 16, player) )
	end
	areaPos = newVec2(math.random(0, sWidth-areaSize),math.random(0, sHeight-areaSize))
	spawnTimer = 10
end

function drawHealthBar(player, x, y, w, h)
	love.graphics.setColor(0.5, 0, 0)
	love.graphics.rectangle("fill",x, y, w, h)
	love.graphics.setColor(0, 0.6, 0)
	love.graphics.rectangle("fill",x, y, w * player.health / 10, h)
	love.graphics.setColor(0.6, 0.6, 0.6)
	love.graphics.rectangle("line",x, y, w, h)
	love.graphics.setColor(1, 1, 1)
end

function love.update(dt)
	if player.health > 0 then
		mouseX = love.mouse.getX()
		mouseY = love.mouse.getY()
		mouseDir = -angleFromPoints( player.pos.x, player.pos.y, mouseX, mouseY ) - math.pi/2
		player.update(player, dt)
		if spawnTimer <= 0 then
			spawnEnemies((round + 1)*5, areaPos, areaSize)
			love.audio.play(snd_beep)
			round = round + 1
		end
		spawnTimer = spawnTimer - dt
		for i = 1, #bullets do
	  		bullets[i].update(bullets[i], dt)
		end
		for i = 1, #enemies do
	  		enemies[i].update(enemies[i], dt)
		end
	else
		if love.keyboard.isDown("c") then
			love.load()
		end
		if controllerMode then
			if controller:isDown(3) then
				love.load()
			end
		end
	end
end

function love.draw()
	if player.health > 0 then
		player.draw(player)
		for i = 1, #bullets do
	  		bullets[i].draw(bullets[i])
		end
		for i = 1, #enemies do
	  		enemies[i].draw(enemies[i])
		end
		love.graphics.rectangle("line", areaPos.x, areaPos.y, areaSize, areaSize) -- safe zone
		love.graphics.setColor(0, 0.6, 0, 0.3)
		love.graphics.rectangle("fill", areaPos.x, areaPos.y, areaSize, areaSize) -- safe zone
		love.graphics.setColor(1, 1, 1)
		love.graphics.print( tostring(math.floor(spawnTimer)), 10, 40 )
		drawHealthBar(player, 10, 10, 300, 30)
		love.graphics.print( "ROUND:" .. tostring(round), 320, -10 )
		love.graphics.print( "SCORE:" .. tostring(score), 320, 40 )

	else

		love.graphics.print( "GAME OVER", sWidth/2 - 130, sHeight/2 - 40)
		love.graphics.print( "SCORE:" .. tostring(score), sWidth/2 - 130, sHeight/2 + 20 )
	end
end