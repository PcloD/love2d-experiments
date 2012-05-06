local time, width, height = 0, 0, 0

local test_img
local octaves = 6

function love.load()
	width = love.graphics.getWidth()
	height = love.graphics.getHeight()
	regen_perlin()
end

function love.draw()
	love.graphics.draw(test_img, 0, 0)
	love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 20)
end

function love.update(dt)
	time = time + dt
end

function smooth(noise, octave)
	local smooth_noise = {}

	local samplePeriod = 2^octave
	local sampleFrequency = 1 / samplePeriod
	for x=0, #noise-1 do
		table.insert(smooth_noise, {})
		local sample_x0 = math.floor(x / samplePeriod) * samplePeriod
		local sample_x1 = (sample_x0 + samplePeriod) % #noise
		local horizontal_blend = (x - sample_x0) * sampleFrequency
		for y=0, #noise[x+1]-1 do
			local sample_y0 = math.floor(y /samplePeriod) * samplePeriod
			local sample_y1 = (sample_y0 + samplePeriod) % #noise[x+1]
			local vertical_blend = (y - sample_y0) * sampleFrequency

			local top = interpolate(noise[sample_x0+1][sample_y0+1], noise[sample_x1+1][sample_y0+1], horizontal_blend)
			local bottom = interpolate(noise[sample_x0+1][sample_y1+1], noise[sample_x1+1][sample_y1+1], horizontal_blend)

			table.insert(smooth_noise[x+1], interpolate(top, bottom, vertical_blend))
		end
	end
	return smooth_noise
end

function interpolate(x0, x1, alpha)
	return interpolate_linear(x0, x1, alpha)
end

function interpolate_linear(x0, x1, alpha)
	return x0 * (1 - alpha) + alpha * x1
end

function interpolate_cos(x0, x1, alpha)
	local alpha2 = (1-math.cos(alpha*math.pi))/2
	return (x0*(1-alpha2) + x1*alpha2)
end

function perlin(noise, octaves)
	local persistance = 0.7
	local amplitude = 1.0
	local totalAmplitude = 0.0
	local smoothNoise = {}
	for i = 0, octaves-1 do
		table.insert(smoothNoise, smooth(noise, i))
	end

	local perlinNoise = {}
	for x = 1, width do
		table.insert(perlinNoise, {})
		for y = 1, height do
			table.insert(perlinNoise[x], 0)
		end
	end

	for octave = octaves, 1, -1 do
		amplitude = amplitude * persistance
		totalAmplitude = totalAmplitude + amplitude
		for x = 1, width do
			for y = 1, height do
				perlinNoise[x][y] = perlinNoise[x][y] + smoothNoise[octave][x][y] * amplitude
			end
		end
	end

	for x = 1, width do
		for y = 1, height do
			perlinNoise[x][y] = perlinNoise[x][y] / totalAmplitude
		end
	end

	return perlinNoise
end

function regen_perlin()
	local noise = {}
	for x = 1, width do
		table.insert(noise, {})
		for y = 1, height do
			table.insert(noise[x], math.random())
		end
	end
	local perlinNoise = perlin(noise, octaves)
	local img_data = love.image.newImageData(width, height)
	for x= 1, width do
		for y = 1, height do
			img_data:setPixel(x-1, y-1, perlinNoise[x][y]*255, 0, 0, 255)
		end
	end
	test_img = love.graphics.newImage(img_data)
end

function love.keypressed(key)
	if key == "up" then
		octaves = octaves + 1
		regen_perlin()
	elseif key == "down" then
		octaves = octaves - 1
		regen_perlin()
	elseif key == "r" then
		regen_perlin()
	end
end
