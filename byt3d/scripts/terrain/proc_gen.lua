------------------------------------------------------------------------------------------------------------
-- Procedurally generated terrain 
--
------------------------------------------------------------------------------------------------------------

local bit = require("bit")

--///
--/// Basic implementation of a 2D value noise using permutation table
--///
local Simple2DNoiseB = {}

Simple2DNoiseB.kMaxVertices		= 256
Simple2DNoiseB.kMaxVerticesMask = Simple2DNoiseB.kMaxVertices - 1;

Simple2DNoiseB.r 		= {}
Simple2DNoiseB.perm 	= {}

------------------------------------------------------------------------------------------------------------
function Mix( a, b, t )

    return a * ( 1 - t ) + b * t;
end

------------------------------------------------------------------------------------------------------------
function Smoothstep( t )

    return t * t * ( 3 - 2 * t )
end

------------------------------------------------------------------------------------------------------------

function Simple2DNoiseB:NewNoise( seed )

    self.imageWidth 	= 512
    self.imageHeight 	= 512
    
    self.invImageWidth = 1.0 / self.imageWidth
    self.invImageHeight = 1.0 / self.imageHeight

	if seed == nil then seed = 2011 end
    math.randomseed( seed );
    for i = 0, self.kMaxVertices-1 do

        self.r[ i ] 	= math.random();
        -- /// assign value to permutation array
        self.perm[ i ] 	= i;
    end
    -- /// randomly swap values in permutationa array
    for i = 0, self.kMaxVertices-1 do

        local swapIndex = math.random(0, self.kMaxVerticesMask) 
        local temp = self.perm[ swapIndex ]
        self.perm[ swapIndex ] = self.perm[ i ]
        self.perm[ i ] = temp
        self.perm[ i + self.kMaxVertices ] = self.perm[ i ]
    end
end

------------------------------------------------------------------------------------------------------------

function findnoise(x)
           
	local x = bit.bor(bit.lshift(x, 13), x)
	return ( 1.0 - bit.band( (x * (x * x * 15731 + 789221) + 1376312589),  Ox7fffffff) / 1073741824.0)   
end

------------------------------------------------------------------------------------------------------------

function findnoise2(x, y)

	local n = x + y * 57
	n = bit.bor(bit.lshift(n, 13) , n )
	local nn = bit.band((n*(n*n*60493+19990303)+1376312589), 0x7fffffff)
 	return 1.0 - (nn/1073741824.0)
end

------------------------------------------------------------------------------------------------------------

function interpolate1( a, b, x )

	local ft = x * 3.1415927
	local f  = (1.0-math.cos(ft)) * 0.5
	return a * (1.0-f) + b * f
end

------------------------------------------------------------------------------------------------------------

function noise(pt)

	local x = pt.x
	local y = pt.y

	local floorx=math.floor(x)
	local floory=math.floor(y)
	local s,t,u,v  -- Integer declaration

	s=findnoise2(floorx, floory)
	t=findnoise2(floorx+1, floory)
	u=findnoise2(floorx, floory+1) --Get the surrounding pixels to calculate the transition.
	v=findnoise2(floorx+1, floory+1)

	local int1 = interpolate1(s, t, x-floorx)   --Interpolate between the values.
	local int2 = interpolate1(u, v, x-floorx)   --Here we use x-floorx, to get 1st dimension. Don't mind the x-floorx thingie, it's part of the cosine formula.
	return interpolate1(int1, int2, y-floory) --Here we use y-floory, to get the 2nd dimension.
end
     
------------------------------------------------------------------------------------------------------------
-- /// Evaluate the noise function at position x
function Simple2DNoiseB:eval( pt )

    local xi = math.floor( pt.x )
    local yi = math.floor( pt.y )
 
    local tx = pt.x - xi
    local ty = pt.y - yi
 
    local rx0 = bit.band(xi, self.kMaxVerticesMask)
    local rx1 = bit.band(( rx0 + 1 ), self.kMaxVerticesMask)
    local ry0 = bit.band(yi, self.kMaxVerticesMask)
    local ry1 = bit.band(( ry0 + 1 ), self.kMaxVerticesMask)
 
    -- /// random values at the corners of the cell using permutation table
    local c00 = self.r[ self.perm[ self.perm[ rx0 ] + ry0 ] ]
    local c10 = self.r[ self.perm[ self.perm[ rx1 ] + ry0 ] ]
    local c01 = self.r[ self.perm[ self.perm[ rx0 ] + ry1 ] ]
    local c11 = self.r[ self.perm[ self.perm[ rx1 ] + ry1 ] ]
 
    -- /// remapping of tx and ty using the Smoothstep function
    local sx = Smoothstep( tx )
    local sy = Smoothstep( ty )
 
    -- /// linearly interpolate values along the x axis
    local nx0 = Mix( c00, c10, sx )
    local nx1 = Mix( c01, c11, sx )
 
    -- /// linearly interpolate the nx0/nx1 along they y axis
    return Mix( nx0, nx1, sy )
end

------------------------------------------------------------------------------------------------------------
-- returns floating point
fBm_first = true;

function Simple2DNoiseB:fBm( snoise, P, H, lacunarity, octaves )

	if H == nil then H = math.random() end
	if lacunarity == nil then lacunarity = 2.3 end
	if octaves == nil then octaves = 14 end 
	
	local frequency = 1.0/256.0
	    
    if fBm_first == true then
    	frequency = 1.0;
    	self.exp_array = {}
    	for i=0, self.kMaxVerticesMask do
    		self.exp_array[i] = math.pow( frequency, -H )
    		frequency = frequency * lacunarity
    	end    
    	fBm_first = false
    end
    
    local value = 0.0
    for i = 0, octaves do
    -- print("Octaves: ", octaves, P.x, P.y, self.exp_array[i], i, value)
    	value = value + noise( P ) * self.exp_array[i]
    	P.x = P.x * lacunarity
    	P.y = P.y * lacunarity
    end
    
    local remainder = octaves - math.floor(octaves)
    if remainder > 0.0 then
    	value = value + remainder * noise( P ) * self.exp_array[i]
    end
    
    return value / 1.5
end

------------------------------------------------------------------------------------------------------------
function Simple2DNoiseB:SimpleNoise( snoise, P )

    return snoise:eval( P )
end

------------------------------------------------------------------------------------------------------------
function Simple2DNoiseB:SignedNoise( snoise, P )

    return ( 2 * snoise:eval( P ) - 1 )
end

------------------------------------------------------------------------------------------------------------

function Simple2DNoiseB:GenerateImage( image, cmap )

	self:NewNoise(os.clock())

    imageBuffer = image.data
    local currPixel = 0

	local rx =  math.random()
	local ry =  math.random()
    for j = 0,self.imageHeight-1 do
        for i = 0,self.imageWidth-1 do
            local P = { x=i * self.invImageWidth + rx, y=j * self.invImageHeight + ry }
            local height = self:fBm( self, P ) * 0.75 -- + self:SignedNoise( self, P ) * 0.25
            local index = math.floor(height * 255.0) + 255
            if index < 1 then index = 1 end
            if index > 255 then index = 255 end

            local c = { index, index, index }
            if cmap ~= nil then c = cmap[index] end
        	imageBuffer[currPixel * 4] = c[1]
        	imageBuffer[currPixel * 4 + 1] = c[2]
        	imageBuffer[currPixel * 4 + 2] = c[3]
        	imageBuffer[currPixel * 4 + 3] = 255.0
            currPixel = currPixel + 1
		end
    end    
end

------------------------------------------------------------------------------------------------------------

function Simple2DNoiseB:Colorize( image, cmap )

    imageBuffer = image.data
    local currPixel = 0
    
    for j = 0,self.imageHeight-1 do
        for i = 0,self.imageWidth-1 do
           	local c = cmap[imageBuffer[currPixel * 4]]
            if c then
            	imageBuffer[currPixel * 4] = c[1]
            	imageBuffer[currPixel * 4 + 1] = c[2]
            	imageBuffer[currPixel * 4 + 2] = c[3]
            	imageBuffer[currPixel * 4 + 3] = 255.0
            	currPixel = currPixel + 1
            end
        end
    end
end

------------------------------------------------------------------------------------------------------------

function Simple2DNoiseB:Quantize(image, size)

    imageBuffer = image.data
    local currPixel = 0
	
    for j = 0,self.imageHeight-1, size do
        for i = 0,self.imageWidth-1, size do
			       
			local color = { 0, 0, 0 }
        	for sy = 0, size-1 do
        		for sx = 0, size-1 do
            		color[1] = color[1] + imageBuffer[(j + sy) * self.imageWidth * 4 + (i + sx) * 4]
            		color[2] = color[2] + imageBuffer[(j + sy) * self.imageWidth * 4 + (i + sx) * 4 + 1]
            		color[3] = color[3] + imageBuffer[(j + sy) * self.imageWidth * 4 + (i + sx) * 4 + 2]
            	end
            end
            color[1] = color[1] / (size * size)
            color[2] = color[2] / (size * size)
            color[3] = color[3] / (size * size)

        	for sy = 0, size-1 do
        		for sx = 0, size-1 do
            		imageBuffer[(j + sy) * self.imageWidth * 4 + (i + sx) * 4] = color[1]
            		imageBuffer[(j + sy) * self.imageWidth * 4 + (i + sx) * 4 + 1] = color[2]
            		imageBuffer[(j + sy) * self.imageWidth * 4 + (i + sx) * 4 + 2] = color[3]
            	end
            end                     	
		end		
    end
end

------------------------------------------------------------------------------------------------------------

function Simple2DNoiseB:CreateNoiseImage( gcairo, cmap )

	self:NewNoise(os.clock())
	
    local image = gcairo:DataImage( self.imageWidth, self.imageHeight )
	self:GenerateImage( image, cmap )
	--self:Colorize( image, cmap)
    
    return image
end

------------------------------------------------------------------------------------------------------------

return Simple2DNoiseB

------------------------------------------------------------------------------------------------------------
