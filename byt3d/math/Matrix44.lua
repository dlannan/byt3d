--~ /*
--~  * Created by David Lannan.
--~  * User: David Lannan
--~  * Date: 5/19/2012
--~  * Time: 7:14 PM
--~  *
--~  */
--~ // General Matrix Utilities
------------------------------------------------------------------------------------------------------------

require("scripts/utils/copy")

------------------------------------------------------------------------------------------------------------
-- Some supporting Vector4 functions

Vector4 = { 0.0, 0.0, 0.0, 0.0 }

function VecCross(vec1, vec2)
	local ret = {}
	ret[1] = vec1[2] * vec2[3] - vec2[2] * vec1[3]
	ret[2] = vec1[3] * vec2[1] - vec2[3] * vec1[1]
	ret[3] = vec1[1] * vec2[2] - vec2[1] * vec1[2]
	ret[4] = 0.0
	return ret
end

function VecDot(vec1, vec2)
    local res = vec1[1] * vec2[1] + vec1[2] * vec2[2] + vec1[3] * vec2[3]
    return res
end

function VecMult(vec1, scalar)
    local res = { vec1[1] * scalar,  vec1[2]  * scalar,  vec1[3] * scalar }
    return res
end


function VecNormalize(vec)
	local d = 1.0 / math.sqrt( vec[1] * vec[1] + vec[2] * vec[2] + vec[3] * vec[3] + vec[4] * vec[4] )
	local ret = { vec[1] * d, vec[2] * d, vec[3] * d, vec[4] * d } 
	return ret
end

function FFIMatrixPrint( m )
    local mat = " " 
    for i=0, 15 do 
    	mat = mat.." "..m[i] 
    end
    print(mat) 
end

------------------------------------------------------------------------------------------------------------

Matrix44 = {

    -- Declare an array to store the data elements.
    m = { 
    	1.0, 0.0, 0.0, 0.0,
    	0.0, 1.0, 0.0, 0.0,
    	0.0, 0.0, 1.0, 0.0, 
    	0.0, 0.0, 0.0, 1.0 
    	}
}

------------------------------------------------------------------------------------------------------------

function Matrix44:print()
    local mat = " " 
    for i=1, 16 do 
    	mat = mat.." "..self.m[i] 
    end
    print("Matrix:"..mat) 
end


------------------------------------------------------------------------------------------------------------
-- Matrix44 cleanup

function Matrix44:cleanup()

    local tmp = {}
    for k,v in pairs(self.m) do
        local tk = tonumber(k)
        tmp[tk] = v
    end
    self.m = tmp
end

------------------------------------------------------------------------------------------------------------

function Matrix44:right()  	return { self.m[1],  self.m[2],  self.m[3],  self.m[4] } end 
function Matrix44:up() 		return { self.m[5],  self.m[6],  self.m[7],  self.m[8] } end 
function Matrix44:view()  	return { self.m[9],  self.m[10], self.m[11], self.m[12] } end 
function Matrix44:pos()   	return { self.m[13], self.m[14], self.m[15], self.m[16] } end 

------------------------------------------------------------------------------------------------------------

function Matrix44:SetRight( vec ) 	self.m[1] = vec[1]; 	self.m[2] = vec[2]; 	self.m[3] = vec[3]; 	self.m[4] = vec[4]; end
function Matrix44:SetUp( vec ) 		self.m[5] = vec[1]; 	self.m[6] = vec[2]; 	self.m[7] = vec[3]; 	self.m[8] = vec[4]; end
function Matrix44:SetView( vec ) 	self.m[9] = vec[1]; 	self.m[10] = vec[2]; 	self.m[11] = vec[3]; 	self.m[12] = vec[4]; end
function Matrix44:SetPos( vec ) 	self.m[13] = vec[1]; 	self.m[14] = vec[2]; 	self.m[15] = vec[3]; 	self.m[16] = vec[4]; end

------------------------------------------------------------------------------------------------------------
-- Matrix44 s

function Matrix44:FromVec4(r, u, v, p) 
    self.m[1] = r[1]; 	self.m[2] = r[2]; 	self.m[3] = r[3]; 	self.m[4] = r[4]
    self.m[5] = u[1]; 	self.m[6] = u[2]; 	self.m[7] = u[3]; 	self.m[8] = u[4]
    self.m[9] = v[1]; 	self.m[10] = v[2]; 	self.m[11] = v[3]; 	self.m[12] = v[4]
    self.m[13] = p[1]; 	self.m[14] = p[2]; 	self.m[15] = p[3]; 	self.m[16] = p[4]
end

------------------------------------------------------------------------------------------------------------
-- Matrix Copy
function Matrix44:Copy( mat )
	self.m = deepcopy(mat.m) 
end

------------------------------------------------------------------------------------------------------------

function Matrix44:Add( m )
	for k,v in pairs(m) do
		self.m[k] = self.m[k] + m[k]
	end
end

------------------------------------------------------------------------------------------------------------

function Matrix44:Sub( m ) 
	for k,v in pairs(m) do
		self.m[k] = self.m[k] - m[k]
	end
end

------------------------------------------------------------------------------------------------------------

function Matrix44:Div( f ) 
	 local oof = 1.0 / f
	for k,v in pairs(m) do
		self.m[k] = self.m[k] * oof
	end
end

------------------------------------------------------------------------------------------------------------

function Matrix44:MultFloat( f )

	for k,v in pairs(m) do
		self.m[k] = self.m[k] * f
	end
end

------------------------------------------------------------------------------------------------------------

function Matrix44:Mult44( p, q )
	
	local out = Matrix44:New()
	out.m[1]	= p.m[1] * q.m[1] + p.m[2] * q.m[5] + p.m[3] * q.m[9] + p.m[4] * q.m[13]
	out.m[2]	= p.m[1] * q.m[2] + p.m[2] * q.m[6] + p.m[3] * q.m[10] + p.m[4] * q.m[14]
	out.m[3]	= p.m[1] * q.m[3] + p.m[2] * q.m[7] + p.m[3] * q.m[11] + p.m[4] * q.m[15]
	out.m[4]	= p.m[1] * q.m[4] + p.m[2] * q.m[8] + p.m[3] * q.m[12] + p.m[4] * q.m[16]
	
	out.m[5]	= p.m[5] * q.m[1] + p.m[6] * q.m[5] + p.m[7] * q.m[9] + p.m[8] * q.m[13]
	out.m[6]	= p.m[5] * q.m[2] + p.m[6] * q.m[6] + p.m[7] * q.m[10] + p.m[8] * q.m[14]
	out.m[7]	= p.m[5] * q.m[3] + p.m[6] * q.m[7] + p.m[7] * q.m[11] + p.m[8] * q.m[15]
	out.m[8]	= p.m[5] * q.m[4] + p.m[6] * q.m[8] + p.m[7] * q.m[12] + p.m[8] * q.m[16]
	
	out.m[9]	= p.m[9] * q.m[1] + p.m[10] * q.m[5] + p.m[11]  * q.m[9] + p.m[12] * q.m[13]
	out.m[10]	= p.m[9] * q.m[2] + p.m[10] * q.m[6] + p.m[11] * q.m[10] + p.m[12] * q.m[14]
	out.m[11]	= p.m[9] * q.m[3] + p.m[10] * q.m[7] + p.m[11] * q.m[11] + p.m[12] * q.m[15]
	out.m[12]	= p.m[9] * q.m[4] + p.m[10] * q.m[8] + p.m[11] * q.m[12] + p.m[12] * q.m[16]

	out.m[13]	= p.m[13] * q.m[1] + p.m[14] * q.m[5] + p.m[15]  * q.m[9] + p.m[16] * q.m[13]
	out.m[14]	= p.m[13] * q.m[2] + p.m[14] * q.m[6] + p.m[15] * q.m[10] + p.m[16] * q.m[14]
	out.m[15]	= p.m[13] * q.m[3] + p.m[14] * q.m[7] + p.m[15] * q.m[11] + p.m[16] * q.m[15]
	out.m[16]	= p.m[13] * q.m[4] + p.m[14] * q.m[8] + p.m[15] * q.m[12] + p.m[16] * q.m[16]
	return out
end

------------------------------------------------------------------------------------------------------------

function Matrix44:MultVec4( v )
	local ret = {}
    ret[1] = v[1] * self.m[1] + v[2] * self.m[2] + v[3] * self.m[3]  + v[4] * self.m[4]
    ret[2] = v[1] * self.m[5] + v[2] * self.m[6] + v[3] * self.m[7] + v[4] * self.m[8]
    ret[3] = v[1] * self.m[9] + v[2] * self.m[10] + v[3] * self.m[11] + v[4] * self.m[12]
    ret[4] = v[1] * self.m[13] + v[2] * self.m[14] + v[3] * self.m[15] + v[4] * self.m[16]
    return ret
end

------------------------------------------------------------------------------------------------------------

function Matrix44:Set( x,  y,  z,  w) 	
	self.m[1] = x; self.m[2] = y; self.m[3] = z; self.m[4] = w; 
end

------------------------------------------------------------------------------------------------------------

function Matrix44:Lerp( p1, p2, t)
	p2:Sub(p1)
	p2:MultFloat(t)
	self.m = p2
end

------------------------------------------------------------------------------------------------------------

function Matrix44:Identity()
    self.m = { 
    	1.0, 0.0, 0.0, 0.0,
    	0.0, 1.0, 0.0, 0.0,
    	0.0, 0.0, 1.0, 0.0, 
    	0.0, 0.0, 0.0, 1.0 
    	}
end

------------------------------------------------------------------------------------------------------------

function Matrix44:Transform33( src )
	local dst = {}
	dst[1] = m[1] * src[1] + m[5] * src[2] + m[9] * src[3]
	dst[2] = m[2] * src[1] + m[6] * src[2] + m[10] * src[3]
	dst[3] = m[3] * src[1] + m[7] * src[2] + m[11] * src[3]
	return dst
end

------------------------------------------------------------------------------------------------------------

function Matrix44:Transform44( src )
	local dst = {}
	dst[1] = m[1] * src[1] + m[5] * src[2] + m[9] * src[3]
	dst[2] = m[2] * src[1] + m[6] * src[2] + m[10] * src[3]
	dst[3] = m[3] * src[1] + m[7] * src[2] + m[11] * src[3]
	dst[4] = 1.0  -- This is fairly traditional way to treat homogenous coords
	return dst
end

------------------------------------------------------------------------------------------------------------

function Matrix44:Scale( x, y, z )  
	self.m[1] 	= self.m[1] * x 
	self.m[6] 	= self.m[6] * y
	self.m[11] 	= self.m[11] * z 
end

------------------------------------------------------------------------------------------------------------

function Matrix44:RotateAxis( angle, x, y, z)
    local r = math.rad(angle)
    local s = math.sin(r)
    local c = math.cos(r)
    
    self:Identity();
    self.m[1] = c + (1 - c) * x * x
    self.m[2] = (1 - c) * x * y - z * s
    self.m[3] = (1 - c) * x * z + y * s
    self.m[5] = (1 - c) * x * y + z * s
    self.m[6] = c + (1 - c) * y * y
    self.m[7] = (1 - c) * y * z - x * s
    self.m[9] = (1 - c) * x * z - y * s
    self.m[10] = (1 - c) * y * z + x * s
    self.m[11] = c + (1 - c) * z * z
end

------------------------------------------------------------------------------------------------------------
-- Yaw, Pitch Roll rotation
function Matrix44:RotationHPR( x, y, z ) 

	-- Make xyz into radians
	local out1 = Matrix44:New()
    local tm3 = Matrix44:New()
    if( math.abs(z) > 0.0 ) then
        tm3:RotateAxis(z,  0, 0, 1 )
        out1 = out1:Mult44(out1, tm3)
    end
    local tm2 = Matrix44:New()
    if( math.abs(y) > 0.0 ) then
        tm2:RotateAxis(y,  1, 0, 0 )
        out1 = out1:Mult44(out1, tm2)
    end
	local tm1 = Matrix44:New()
	if( math.abs(x) > 0.0 ) then 
		tm1:RotateAxis(x, 0, 1, 0) 
		out1 = out1:Mult44(out1, tm1)
	end

	self.m = out1.m
end

------------------------------------------------------------------------------------------------------------

function Matrix44:RotateHPR( x, y, z )

	-- Make xyz into radians
	local out1 = self
    local tm1 = Matrix44:New()
    if( math.abs(x) > 0.0 ) then
        tm1:RotateAxis(x, 0, 1, 0)
        out1 = out1:Mult44(out1, tm1)
    end
    local tm2 = Matrix44:New()
    if( math.abs(y) > 0.0 ) then
        tm2:RotateAxis(y,  1, 0, 0 )
        out1 = out1:Mult44(out1, tm2)
    end
    local tm3 = Matrix44:New()
    if( math.abs(z) > 0.0 ) then
        tm3:RotateAxis(z,  0, 0, 1 )
        out1 = out1:Mult44(out1, tm3)
    end

    self.m = out1.m
end

------------------------------------------------------------------------------------------------------------

function Matrix44:RotationXYZ( x, y, z)

	self:RotationHPR( y, x, z )
end

------------------------------------------------------------------------------------------------------------

function Matrix44:RotateXYZ( x, y, z)
		
	self:RotateHPR( y, x, z )
end

------------------------------------------------------------------------------------------------------------

function Matrix44:Inverse()

	m = matrix.invert(m)
end

------------------------------------------------------------------------------------------------------------

function Matrix44:Transpose()

    local tm = Matrix44:New()
    tm:Copy(self)
    tm.m[2] = self.m[5]; tm.m[5] = self.m[2]
    tm.m[3] = self.m[9]; tm.m[9] = self.m[3]
    tm.m[4] = self.m[13]; tm.m[13] = self.m[4]
    tm.m[7] = self.m[10]; tm.m[10] = self.m[7]
    tm.m[8] = self.m[14]; tm.m[14] = self.m[8]
    tm.m[12] = self.m[15]; tm.m[15] = self.m[12]
    self.m = tm.m
end
------------------------------------------------------------------------------------------------------------

function Matrix44:Translate( x, y, z )

    self.m[13] = self.m[13] + (self.m[1] * x + self.m[5] * y + self.m[9]  * z)
    self.m[14] = self.m[14] + (self.m[2] * x + self.m[6] * y + self.m[10] * z)
    self.m[15] = self.m[15] + (self.m[3] * x + self.m[7] * y + self.m[11] * z)
    self.m[16] = self.m[16] + (self.m[4] * x + self.m[8] * y + self.m[12] * z)
end

------------------------------------------------------------------------------------------------------------

function Matrix44:Position( x, y, z )

	self.m[13] = x; self.m[14] = y; self.m[15] = z; self.m[16] = 1.0
end

------------------------------------------------------------------------------------------------------------
 -- TODO: Some more examination here needed - dont like this.

function Matrix44:LookAt( eye, target )

    local Eye 	= { eye[1], eye[2], eye[3], 1.0 }
	local At 	= { target[1], target[2], target[3], 0.0 }
	local Up	= { 0.0, 1.0, 0.0, 0.0 }

	local lookvec   = { At[1] - Eye[1], At[2] - Eye[2], At[3] - Eye[3], 0.0 }
    local lookvecN  = VecNormalize(lookvec)
    local xzplane   = { lookvec[1], 0.0, lookvec[3], 0.0 }
    xzplane         = VecNormalize(xzplane)

    -- Heading is the angle away from 0, 0, -1
    local theta     = math.acos( VecDot( xzplane, { 0.0, 0.0, -1.0 } ) )
    local rho       = math.acos( VecDot( lookvecN, xzplane ))

    local heading   = math.deg(theta)
    local pitch     = -math.deg(rho)
    local roll      = 0.0

    self:Identity()
    self:Translate( -Eye[1], -Eye[2], -Eye[3] )
    self:RotateHPR( heading, pitch, roll )

    return heading, pitch
end

------------------------------------------------------------------------------------------------------------
-- Return a frustum matrix44 given the left, right, bottom, top,
--   near, and far values for the frustum boundaries.
function Matrix44:Frustum( left,  right,  bottom,  top,  znear,  zfar)

    local zDelta = (zfar-znear)
    local dir = (right-left)
    local height = (top-bottom)
    local zNear2 = 2*znear

    self.m[1]= zNear2 / dir
    self.m[2]=0.0
    self.m[3]=0.0
    self.m[4]=0.0

    self.m[5]=0.0
    self.m[6]= zNear2 / height
    self.m[7]=0.0
    self.m[8]=0.0

    self.m[9]= (right + left) / dir
    self.m[10]= (top + bottom) / height
    self.m[11]=-(zfar + znear) / zDelta;
    self.m[12]=-1.0

    self.m[13]=0.0
    self.m[14]=0.0
    self.m[15]=-zNear2 * zfar / zDelta
    self.m[16]=0.0
end

------------------------------------------------------------------------------------------------------------
-- Return a perspective matrix44 given the field-of-view in the Y
--   direction in degrees, the aspect ratio of Y/X, and near and
--   far plane distances.
-- function GetMatrixArray
-- 		arguments:	float *tMat					this variable gets set with the transformation matrix values and must be allocated ahead of time by the user
-- 		returns:	void
--  Uses the calculated values to create an OpenGL ES 2.0 compatible matrix that the user can put in a vertex shader
function Matrix44:GetMatrixArray()

    local tproj = ffi.new("float[16]",
        {
            self.m[1], self.m[2], self.m[3], 0.0,
            self.m[5], self.m[6], self.m[7], 0.0,
            self.m[9], self.m[10], self.m[11], 0.0,
            - VecDot(self:right(), self:pos()), -VecDot(self:up(), self:pos()), -VecDot(self:view(), self:pos()), 1.0
        }
    )
    return tproj
end

------------------------------------------------------------------------------------------------------------
-- Return a perspective matrix44 given the field-of-view in the Y
--   direction in degrees, the aspect ratio of Y/X, and near and
--   far plane distances.

function Matrix44:Perspective( fovY,  aspect,  znear,  zfar)
    -- These paramaters are about lens properties.
    -- The "near" and "far" create the Depth of Field.
    -- The "angleOfView", as the name suggests, is the angle of view.
    -- The "aspectRatio" is the cool thing about this matrix. OpenGL doesn't
    -- has any information about the screen you are rendering for. So the
    -- results could seem stretched. But this variable puts the thing into the
    -- right path. The aspect ratio is your device screen (or desired area) width divided
    -- by its height. This will give you a number < 1.0 the the area has more vertical
    -- space and a number > 1.0 is the area has more horizontal space.
    -- Aspect Ratio of 1.0 represents a square area.

    -- Some calculus before the formula.
    local frustumH = znear * math.tan(math.rad(fovY)/2.0)
    local frustumW = frustumH * aspect

    self:Frustum(-frustumW, frustumW, -frustumH, frustumH, znear, zfar)
end

------------------------------------------------------------------------------------------------------------
-- Return an orthographic matrix44 given the left, right, bottom, top,
--  near, and far values for the frustum boundaries.
function Matrix44:Ortho( l,  r,  b,  t,  n,  f)

	local width = r-l
	local height = t-b
	local depth = f-n

	self.m[1] = 2.0 / width
	self.m[2] = 0.0
	self.m[3] = 0.0
	self.m[4] = 0.0

	self.m[5] = 0.0
	self.m[6] = 2.0 / height
	self.m[7] = 0.0
	self.m[8] = 0.0

	self.m[9] = 0.0
	self.m[10] = 0.0
	self.m[11] = -2.0 / depth
	self.m[12] = 0.0

	self.m[13] = -(r + l) / width
    self.m[14] = -(t + b) / height
	self.m[15] = -(f + n) / depth
	self.m[16] = 0.0
end

------------------------------------------------------------------------------------------------------------
function Matrix44:RotateInvert()

    local tm = self:New().m
    local m = self.m
    local det = m[1]*m[6]*m[11] + m[2]*m[7]*m[9] + m[3]*m[5]*m[10] - m[1]*m[7]*m[10] - m[2]*m[5]*m[11] - m[3]*m[6]*m[9]

    tm[1] = (m[5]*m[11] - m[7]*m[10])/det
    tm[2] = (m[3]*m[10] - m[2]*m[11])/det
    tm[3] = (m[2]*m[7] - m[3]*m[6])/det
    tm[5] = (m[7]*m[9] - m[5]*m[11])/det
    tm[6] = (m[1]*m[11] - m[3]*m[9])/det
    tm[7] = (m[3]*m[5] - m[1]*m[7])/det
    tm[9] = (m[5]*m[10] - m[6]*m[9])/det
    tm[10] = (m[2]*m[9] - m[1]*m[10])/det
    tm[11] = (m[1]*m[6] - m[2]*m[5])/det
    self.m = tm
end

------------------------------------------------------------------------------------------------------------

function Matrix44:Invert()

    local inv = {}
	local m = self.m

    inv[1] = m[6]  * m[11] * m[16] - 
             m[6]  * m[12] * m[15] - 
             m[10]  * m[7]  * m[16] + 
             m[10]  * m[8]  * m[15] +
             m[14] * m[7]  * m[12] - 
             m[14] * m[8]  * m[11]

    inv[5] = -m[5]  * m[11] * m[16] + 
              m[5]  * m[12] * m[15] + 
              m[9]  * m[7]  * m[16] - 
              m[9]  * m[8]  * m[15] - 
              m[13] * m[7]  * m[12] + 
              m[13] * m[8]  * m[11]

    inv[9] = m[5]  * m[10] * m[16] - 
             m[5]  * m[12] * m[14] - 
             m[9]  * m[6] * m[16] + 
             m[9]  * m[8] * m[14] + 
             m[13] * m[6] * m[12] - 
             m[13] * m[8] * m[10]

    inv[13] = -m[5]  * m[10] * m[15] + 
               m[5]  * m[11] * m[14] +
               m[9]  * m[6] * m[15] - 
               m[9]  * m[7] * m[14] - 
               m[13] * m[6] * m[11] + 
               m[13] * m[7] * m[10]

    inv[2] = -m[2]  * m[11] * m[16] + 
              m[2]  * m[12] * m[15] + 
              m[10]  * m[3] * m[16] - 
              m[10]  * m[4] * m[15] - 
              m[14] * m[3] * m[12] + 
              m[14] * m[4] * m[11]

    inv[6] = m[1]  * m[11] * m[16] - 
             m[1]  * m[12] * m[15] - 
             m[9]  * m[3] * m[16] + 
             m[9]  * m[4] * m[15] + 
             m[13] * m[3] * m[12] - 
             m[13] * m[4] * m[11]

    inv[10] = -m[1]  * m[10] * m[16] + 
              m[1]  * m[12] * m[14] + 
              m[9]  * m[2] * m[16] - 
              m[9]  * m[4] * m[14] - 
              m[13] * m[2] * m[12] + 
              m[13] * m[4] * m[10]

    inv[14] = m[1]  * m[10] * m[15] - 
              m[1]  * m[11] * m[14] - 
              m[9]  * m[2] * m[15] + 
              m[9]  * m[3] * m[14] + 
              m[13] * m[2] * m[11] - 
              m[13] * m[3] * m[10]

    inv[3] = m[2]  * m[7] * m[16] - 
             m[2]  * m[8] * m[15] - 
             m[6]  * m[3] * m[16] + 
             m[6]  * m[4] * m[15] + 
             m[14] * m[3] * m[8] - 
             m[14] * m[4] * m[7]

    inv[7] = -m[1]  * m[7] * m[16] + 
              m[1]  * m[8] * m[15] + 
              m[5]  * m[3] * m[16] - 
              m[5]  * m[4] * m[15] - 
              m[13] * m[3] * m[8] + 
              m[13] * m[4] * m[7]

    inv[11] = m[1]  * m[6] * m[16] - 
              m[1]  * m[8] * m[14] - 
              m[5]  * m[2] * m[16] + 
              m[5]  * m[4] * m[14] + 
              m[13] * m[2] * m[8] - 
              m[13] * m[4] * m[6]

    inv[15] = -m[1]  * m[6] * m[15] + 
               m[1]  * m[7] * m[14] + 
               m[5]  * m[2] * m[15] - 
               m[5]  * m[3] * m[14] - 
               m[13] * m[2] * m[7] + 
               m[13] * m[3] * m[6]

    inv[4] = -m[2] * m[7] * m[12] + 
              m[2] * m[8] * m[11] + 
              m[6] * m[3] * m[12] - 
              m[6] * m[4] * m[11] - 
              m[10] * m[3] * m[8] + 
              m[10] * m[4] * m[7]

    inv[8] = m[1] * m[7] * m[12] - 
             m[1] * m[8] * m[11] - 
             m[5] * m[3] * m[12] + 
             m[5] * m[4] * m[11] + 
             m[9] * m[3] * m[8] - 
             m[9] * m[4] * m[7]

    inv[12] = -m[1] * m[6] * m[12] + 
               m[1] * m[8] * m[10] + 
               m[5] * m[2] * m[12] - 
               m[5] * m[4] * m[10] - 
               m[9] * m[2] * m[8] + 
               m[9] * m[4] * m[6]

    inv[16] = m[1] * m[6] * m[11] - 
              m[1] * m[7] * m[10] - 
              m[5] * m[2] * m[11] + 
              m[5] * m[3] * m[10] + 
              m[9] * m[2] * m[7] - 
              m[9] * m[3] * m[6]

    det = m[1] * inv[1] + m[2] * inv[5] + m[3] * inv[9] + m[4] * inv[13]
    if (det == 0) then return false end

    det = 1.0 / det

	-- Put the result in the matrix
    for i = 1, 16 do self.m[i] = inv[i] * det; end
    return true
end

------------------------------------------------------------------------------------------------------------
-- Rad to Deg and Deg to Rad via math.rad() and math.deg()

function Matrix44:New()

	local newMat = deepcopy(Matrix44)
    return newMat
end

------------------------------------------------------------------------------------------------------------

