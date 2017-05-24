--
-- Created by David Lannan
-- User: grover
-- Date: 11/05/13
-- Time: 8:02 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--
------------------------------------------------------------------------------------------------------------

local mtx = require("byt3d/fmad/Common/fTypes")

-- //********************************************************************************************************************
-- // floating point random utility

function frandom01()  return ( math.random() ) end

-- //********************************************************************************************************************
-- // classify a value relative to the interval between two bounds:
-- //     returns -1 when below the lower bound
-- //     returns  0 when between the bounds (inside the interval)
-- //     returns +1 when above the upper bound

function fIntervalComparison ( x, lowerBound, upperBound )

    if (x < lowerBound) then return -1 end
    if (x > upperBound) then return 1 end
    return 0
end

-- // ----------------------------------------------------------------------------
-- // Constrain a given value (x) to be between two (ordered) bounds: min
-- // and max.  Returns x if it is between the bounds, otherwise returns
-- // the nearer bound.

function fClip (x, min, max )

    if (x < min) then return min end
    if (x > max) then return max end
    return x
end

-- //********************************************************************************************************************

function fInterpolate( alpha, x0, x1 )

    return x0 + ((x1 - x0) * alpha)
end

-- //********************************************************************************************************************

function dInterpolate( alpha,  x0,  x1)

    return x0 + ((x1 - x0) * alpha)
end

-- //********************************************************************************************************************

function v3Interpolate( alpha, x0, x1 )

    vec = ffi.new("fVector3")
    vec.x = fInterpolate(alpha, x0.x, x1.x)
    vec.y = fInterpolate(alpha, x0.y, x1.y)
    vec.z = fInterpolate(alpha, x0.z, x1.z)
    return vec
end

-- //********************************************************************************************************************
-- // Beware this is integer based!! Whole numbers only!!

function iInterpolate( alpha, x0, x1 )

    return x0 + ((x1 - x0) * alpha)
end

-- // ----------------------------------------------------------------------------
-- // blends new values into an accumulator to produce a smoothed time series
-- //
-- // Modifies its third argument, a reference to the float accumulator holding
-- // the "smoothed time series."
-- //
-- // The first argument (smoothRate) is typically made proportional to "dt" the
-- // simulation time step.  If smoothRate is 0 the accumulator will not change,
-- // if smoothRate is 1 the accumulator will be set to the new value with no
-- // smoothing.  Useful values are "near zero".
-- //
-- // Usage:
-- //         blendIntoAccumulator (dt * 0.4f, currentFPS, smoothedFPS);

function fBlendIntoAccumulator ( smoothRate, newValue, smoothedAccumulator)

    smoothedAccumulator = fInterpolate (fClip(smoothRate, 0, 1), smoothedAccumulator, newValue)
end

-- //********************************************************************************************************************

function v3BlendIntoAccumulator ( smoothRate, newValue, smoothedAccumulator)

    smoothedAccumulator = v3Interpolate (fClip(smoothRate, 0, 1), smoothedAccumulator, newValue)
end

-- //********************************************************************************************************************
------------------------------------------------------------------------------------------------------------

function fMat44_Scale( x, y, z)

    local M = ffi.new("fMat44")

    M.m00 = x
    M.m01 = 0.0
    M.m02 = 0.0
    M.m03 = 0.0

    M.m10 = 0.0
    M.m11 = y
    M.m12 = 0.0
    M.m13 = 0.0

    M.m20 = 0.0
    M.m21 = 0.0
    M.m22 = z
    M.m23 = 0.0

    M.m30 = 0.0
    M.m31 = 0.0
    M.m32 = 0.0
    M.m33 = 1.0

    return M
end

-- //********************************************************************************************************************

function fMat44_Scalar(s, A)

    local M = ffi.new("fMat44")

    M.m00 = s*A.m00
    M.m01 = s*A.m01
    M.m02 = s*A.m02
    M.m03 = s*A.m03

    M.m10 = s*A.m10
    M.m11 = s*A.m11
    M.m12 = s*A.m12
    M.m13 = s*A.m13

    M.m20 = s*A.m20
    M.m21 = s*A.m21
    M.m22 = s*A.m22
    M.m23 = s*A.m23

    M.m30 = s*A.m30
    M.m31 = s*A.m31
    M.m32 = s*A.m32
    M.m33 = s*A.m33

    return M
end

-- //********************************************************************************************************************

function fMat44_Add( A, B )

    local M = ffi.new("fMat44")

    M.m00 = A.m00 + B.m00
    M.m01 = A.m01 + B.m01
    M.m02 = A.m02 + B.m02
    M.m03 = A.m03 + B.m03

    M.m10 = A.m10 + B.m10
    M.m11 = A.m11 + B.m11
    M.m12 = A.m12 + B.m12
    M.m13 = A.m13 + B.m13

    M.m20 = A.m20 + B.m20
    M.m21 = A.m21 + B.m21
    M.m22 = A.m22 + B.m22
    M.m23 = A.m23 + B.m23

    M.m30 = A.m30 + B.m30
    M.m31 = A.m31 + B.m31
    M.m32 = A.m32 + B.m32
    M.m33 = A.m33 + B.m33

    return M
end

-- //********************************************************************************************************************

function  fMat44_RotXYZ( x, y, z )

    local M = ffi.new("fMat44")
    local cx = math.math.cos(x)
    local cy = math.math.cos(y)
    local cz = math.math.cos(z)

    local sx = math.math.sin(x)
    local sy = math.math.sin(y)
    local sz = math.math.sin(z)

    -- // x y z rotation order
    M.m00 = cy*cz
    M.m01 = cy*sz
    M.m02 = -sy
    M.m03 = 0.0

    M.m10 = sx*sy*cz - cx*sz
    M.m11 = sx*sy*sz + cx*cz
    M.m12 = sx*cy
    M.m13 = 0.0

    M.m20 = cx*sy*cz + sx*sz
    M.m21 = cx*sy*sz - sx*cz
    M.m22 = cx*cy
    M.m23 = 0.0

    M.m30 = 0.0
    M.m31 = 0.0
    M.m32 = 0.0
    M.m33 = 1.0

    return M
end

-- //********************************************************************************************************************

function fMat44_RotQuat( x, y, z, w )

    local M = ffi.new("fMat44")

    -- // calculate coefficients
    local x2 = x + x
    local y2 = y + y
    local z2 = z + z

    local xx = x * x2
    local xy = x * y2
    local xz = x * z2

    local yy = y * y2
    local yz = y * z2

    local zz = z * z2

    local wx = w * x2
    local wy = w * y2
    local wz = w * z2

    -- // LH quat gen?
    M.m00 = 1.0 - (yy + zz)
    M.m10 = xy - wz
    M.m20 = xz + wy
    M.m30 = 0.0

    M.m01 = xy + wz
    M.m11 = 1.0 - (xx + zz)
    M.m21 = yz - wx
    M.m31 = 0.0

    M.m02 = xz - wy
    M.m12 = yz + wx
    M.m22 = 1.0 - (xx + yy)
    M.m32 = 0.0

    M.m03 = 0
    M.m13 = 0
    M.m23 = 0
    M.m33 = 1

    return M
end

-- //********************************************************************************************************************

function fMat44_SkewSymetric( x, y, z )

    local M = ffi.new("fMat44")

    M.m00		= 0.0
    M.m01		= -z
    M.m02		= y
    M.m03		= 0.0

    M.m10		= z
    M.m11		= 0.0
    M.m12		= -x
    M.m13		= 0.0

    M.m20		= -y
    M.m21		= x
    M.m22		= 0.0
    M.m23		= 0.0

    M.m30		= 0.0
    M.m31		= 0.0
    M.m32		= 0.0
    M.m33		= 1.0

    return M
end

-- //********************************************************************************************************************

function fMat44_ToQuat( M )

    local ool = 0.0
    local diag = M.m00 + M.m11 + M.m22 + 1.0

    local Q = ffi.new(mtx.fVector4)
    if(diag > 0.0) then

        local scale = math.sqrt(diag) * 2.0 -- // get scale from diagonal

        -- // TODO: speed this up
        Q.x = (M.m21 - M.m12) / scale
        Q.y = (M.m02 - M.m20) / scale
        Q.z = (M.m10 - M.m01) / scale
        Q.w = 0.25 * scale
    else

        if ( M.m00 > M.m11 and M.m00 > M.m22) then

            -- // 1st element of diag is greatest value
            -- // find scale according to 1st element, and double it
            local scale = math.sqrt( 1.0 + M.m00 - M.m11 - M.m22) * 2.0

            -- // TODO: speed this up
            Q.x = 0.25 * scale
            Q.y = (M.m01 + M.m10) / scale
            Q.z = (M.m20 + M.m02) / scale
            Q.w = (M.m21 - M.m12) / scale

        elseif ( M.m11 > M.m22) then

            -- // 2nd element of diag is greatest value
            -- // find scale according to 2nd element, and double it
            local scale = math.sqrt( 1.0 + M.m11 - M.m00 - M.m22) * 2.0

            -- // TODO: speed this up
            Q.x = (M.m01 + M.m10 ) / scale
            Q.y = 0.25 * scale
            Q.z = (M.m12 + M.m21) / scale
            Q.w = (M.m02 - M.m20) / scale

        else

            -- // 3rd element of diag is greatest value
            -- // find scale according to 3rd element, and double it
            local scale = math.sqrt( 1.0 + M.m22 - M.m00 - M.m11) * 2.0

            -- // TODO: speed this up
            Q.x = (M.m02 + M.m20) / scale
            Q.y = (M.m12 + M.m21) / scale
            Q.z = 0.25 * scale
            Q.w = (M.m10 - M.m01) / scale
        end
    end

    ool = 1.0 / sqrtf(Q.x*Q.x + Q.y*Q.y + Q.z*Q.z + Q.w*Q.w)
    Q.x = Q.x * -ool
    Q.y = Q.y * -ool
    Q.z = Q.z * -ool
    Q.w = Q.w * ool
    return Q
end

-- //********************************************************************************************************************

function fMat44_LookAt( Vx, Vy, Vz, Ux, Uy, Uz)

    local Yx, Yy, Yz, Zx, Zy, Zz, ooX, ooY, ooZ
    -- // x axis
    local Xx = (Uy*Vz - Uz*Vy)
    local Xy = (Uz*Vx - Ux*Vz)
    local Xz = (Ux*Vy - Uy*Vx)
    local R = ffi.new(mtx.fMat44)

    -- // if V dot U  == 1
    if ((Xx*Xx + Xy*Xy + Xz*Xz) == 0) then

        ftrace("warning fMat44_LookAt: V.U == 0 : %f %f %f : %f %f %f\n", Vx, Vy, Vz, Ux, Uy, Uz)
        Xx =  1.0; Xy =  0.0; Xz =  0.0
    end

    -- // y axis
    Yx = (Vy*Xz - Vz*Xy)
    Yy = (Vz*Xx - Vx*Xz)
    Yz = (Vx*Xy - Vy*Xx)

    Zx = Vx
    Zy = Vy
    Zz = Vz

    -- // normalize
    ooX = 1.0 / math.sqrt(Xx*Xx + Xy*Xy + Xz*Xz)
    ooY = 1.0 / math.sqrt(Yx*Yx + Yy*Yy + Yz*Yz)
    ooZ = 1.0 / math.sqrt(Zx*Zx + Zy*Zy + Zz*Zz)

    Xx = Xx * ooX
    Xy = Xy * ooX
    Xz = Xz * ooX

    Yx = Yx * ooY
    Yy = Yy * ooY
    Yz = Yz * ooY

    Zx = Zx * ooZ
    Zy = Zy * ooZ
    Zz = Zz * ooZ

    R.m00 = Xx
    R.m10 = Xy
    R.m20 = Xz
    R.m30 = 0

    R.m01 = Yx
    R.m11 = Yy
    R.m21 = Yz
    R.m31 = 0

    R.m02 = Zx
    R.m12 = Zy
    R.m22 = Zz
    R.m32 = 0

    R.m03 = 0
    R.m13 = 0
    R.m23 = 0
    R.m33 = 1

    return R
end

-- //********************************************************************************************************************

function fMat44_TransXYZ( x, y, z )

    local M = ffi.new("fMat44")

    M.m00 = 1.0
    M.m01 = 0.0
    M.m02 = 0.0
    M.m03 = x

    M.m10 = 0.0
    M.m11 = 1.0
    M.m12 = 0.0
    M.m13 = y

    M.m20 = 0.0
    M.m21 = 0.0
    M.m22 = 1.0
    M.m23 = z

    M.m30 = 0.0
    M.m31 = 0.0
    M.m32 = 0.0
    M.m33 = 1.0

    return M
end

-- //********************************************************************************************************************

function fMat44_Transpose( a )

    local M = ffi.new("fMat44")

    M.m00 = a.m00
    M.m10 = a.m01
    M.m20 = a.m02
    M.m30 = a.m03

    M.m01 = a.m10
    M.m11 = a.m11
    M.m21 = a.m12
    M.m31 = a.m13

    M.m02 = a.m20
    M.m12 = a.m21
    M.m22 = a.m22
    M.m32 = a.m23

    M.m03 = a.m30
    M.m13 = a.m31
    M.m23 = a.m32
    M.m33 = a.m33

    return M
end

-- //********************************************************************************************************************

function fMat44_Mul(a, b)

    local c = ffi.new("fMat44")

    c.m00 = a.m00*b.m00 + a.m01*b.m10 + a.m02*b.m20 + a.m03*b.m30
    c.m01 = a.m00*b.m01 + a.m01*b.m11 + a.m02*b.m21 + a.m03*b.m31
    c.m02 = a.m00*b.m02 + a.m01*b.m12 + a.m02*b.m22 + a.m03*b.m32
    c.m03 = a.m00*b.m03 + a.m01*b.m13 + a.m02*b.m23 + a.m03*b.m33

    c.m10 = a.m10*b.m00 + a.m11*b.m10 + a.m12*b.m20 + a.m13*b.m30
    c.m11 = a.m10*b.m01 + a.m11*b.m11 + a.m12*b.m21 + a.m13*b.m31
    c.m12 = a.m10*b.m02 + a.m11*b.m12 + a.m12*b.m22 + a.m13*b.m32
    c.m13 = a.m10*b.m03 + a.m11*b.m13 + a.m12*b.m23 + a.m13*b.m33

    c.m20 = a.m20*b.m00 + a.m21*b.m10 + a.m22*b.m20 + a.m23*b.m30
    c.m21 = a.m20*b.m01 + a.m21*b.m11 + a.m22*b.m21 + a.m23*b.m31
    c.m22 = a.m20*b.m02 + a.m21*b.m12 + a.m22*b.m22 + a.m23*b.m32
    c.m23 = a.m20*b.m03 + a.m21*b.m13 + a.m22*b.m23 + a.m23*b.m33

    c.m30 = a.m30*b.m00 + a.m31*b.m10 + a.m32*b.m20 + a.m33*b.m30
    c.m31 = a.m30*b.m01 + a.m31*b.m11 + a.m32*b.m21 + a.m33*b.m31
    c.m32 = a.m30*b.m02 + a.m31*b.m12 + a.m32*b.m22 + a.m33*b.m32
    c.m33 = a.m30*b.m03 + a.m31*b.m13 + a.m32*b.m23 + a.m33*b.m33

    return c
end

-- //********************************************************************************************************************

function fMat44_MulVec( a, b )

    local v = ffi.new(mtx.fVector3)

    v.x = a.m00*b.x + a.m01*b.y + a.m02*b.z + a.m03
    v.y = a.m10*b.x + a.m11*b.y + a.m12*b.z + a.m13
    v.z = a.m20*b.x + a.m21*b.y + a.m22*b.z + a.m23

    return v
end

-- //********************************************************************************************************************

function fMat44_DotRow0( a,  x,  y,  z)

    return a.m00*x + a.m01*y + a.m02*z + a.m03
end

-- //********************************************************************************************************************

function fMat44_DotRow1( a,  x,  y,  z)

    return a.m10*x + a.m11*y + a.m12*z + a.m13
end

-- //********************************************************************************************************************

function fMat44_DotRow2( a,  x,  y,  z)

    return a.m20*x + a.m21*y + a.m22*z + a.m23
end

-- //********************************************************************************************************************

function fMat44_ftrace( a, Desc)

    ftrace("%s 0: %f %f %f %f\n", Desc, a.m00,a.m01,a.m02,a.m03)
    ftrace("%s 1: %f %f %f %f\n", Desc, a.m10,a.m11,a.m12,a.m13)
    ftrace("%s 2: %f %f %f %f\n", Desc, a.m20,a.m21,a.m22,a.m23)
    ftrace("%s 3: %f %f %f %f\n", Desc, a.m30,a.m31,a.m32,a.m33)
end

-- //********************************************************************************************************************

function fMat44_dtrace( a, Desc)

    dtrace("%s 0: %f %f %f %f\n", Desc, a.m00,a.m01,a.m02,a.m03)
    dtrace("%s 1: %f %f %f %f\n", Desc, a.m10,a.m11,a.m12,a.m13)
    dtrace("%s 2: %f %f %f %f\n", Desc, a.m20,a.m21,a.m22,a.m23)
    dtrace("%s 3: %f %f %f %f\n", Desc, a.m30,a.m31,a.m32,a.m33)
end

-- //********************************************************************************************************************

function fMat44_Identity(void)

    local M = ffi.new("fMat44")
    M.m00 = 1.0
    M.m01 = 0.0
    M.m02 = 0.0
    M.m03 = 0.0

    M.m10 = 0.0
    M.m11 = 1.0
    M.m12 = 0.0
    M.m13 = 0.0

    M.m20 = 0.0
    M.m21 = 0.0
    M.m22 = 1.0
    M.m23 = 0.0

    M.m30 = 0.0
    M.m31 = 0.0
    M.m32 = 0.0
    M.m33 = 1.0

    return M
end

-- //********************************************************************************************************************

function fMat44_Projection( fieldOfView, aspectRatio, zNear, zFar )

    local myPi = 3.14159265358979323846
    local sine, cotangent, deltaZ
    local radians = fieldOfView / 2.0 * myPi / 180.0
    local M = ffi.new("fMat44")

    deltaZ = zFar - zNear
    sine = math.sin(radians)

    -- // Should be non-zero to avoid division by zero
    fAssert(deltaZ)
    fAssert(sine)
    fAssert(aspectRatio)
    cotangent = math.cos(radians) / sine

    -- // post-multiply, positive z depth (same as d3d)
    M.m00 = cotangent / aspectRatio
    M.m01 = 0.0
    M.m02 = 0.0
    M.m03 = 0.0

    M.m10 = 0.0
    M.m11 = cotangent
    M.m12 = 0.0
    M.m13 = 0.0

    M.m20 = 0.0
    M.m21 = 0.0
    M.m22 = (zFar + zNear) / deltaZ
    M.m23 = -2 * zNear * zFar / deltaZ

    M.m30 = 0.0
    M.m31 = 0.0
    M.m32 = 1
    M.m33 = 0

    return M
end

-- //********************************************************************************************************************

function fMat44_iProjection( fieldOfView, aspectRatio, zNear, zFar)

    local myPi = 3.14159265358979323846
    local sine, cotangent, deltaZ
    local radians = fieldOfView / 2.0 * myPi / 180.0
    local M = ffi.new("fMat44")

    deltaZ = zFar - zNear
    sine = math.sin(radians)

    -- // Should be non-zero to avoid division by zero
    fAssert(deltaZ)
    fAssert(sine)
    fAssert(aspectRatio)
    cotangent = math.cos(radians) / sine

    -- // post-multiply, positive z depth (same as d3d)
    M.m00 = aspectRatio / cotangent
    M.m01 = 0.0
    M.m02 = 0.0
    M.m03 = 0.0

    M.m10 = 0.0
    M.m11 = 1.0/cotangent
    M.m12 = 0.0
    M.m13 = 0.0

    M.m20 = 0.0
    M.m21 = 0.0
    M.m22 = 0
    M.m23 = -1

    M.m30 = 0.0
    M.m31 = 0.0
    M.m32 = -deltaZ / (2 * zNear * zFar)
    M.m33 = -(zFar + zNear) / (2 * zNear * zFar)

    return M
end

-- //********************************************************************************************************************

function fMat44_Orthographic(left, right, bottom, top, tnear,  tfar)

    local M = ffi.new("fMat44")

    M.m00 = 2.0 / (right - left)
    M.m01 = 0.0
    M.m02 = 0.0
    M.m03 = -(right + left) / (right - left)

    M.m10 = 0.0
    M.m11 = 2.0 / (top - bottom)
    M.m12 = 0.0
    M.m13 = -(top + bottom) / (top - bottom)

    M.m20 = 0.0
    M.m21 = 0.0
    M.m22 = 2.0 / (tfar - tnear)
    M.m23 = -(tfar + tnear) / (tfar - tnear)

    M.m30 = 0.0
    M.m31 = 0.0
    M.m32 = 0.0
    M.m33 = 1.0

    return M
end

-- //********************************************************************************************************************

function fMat44_iOrthographic( left, right, bottom, top, tnear, tfar)

    local M = ffi.new("fMat44")

    local Sx = (right - left) / 2.0
    local Sy = (top - bottom) / 2.0
    local Sz = (tfar - tnear) / 2.0

    M.m00 = Sx
    M.m01 = 0.0
    M.m02 = 0.0
    M.m03 = Sx*(right + left) / (right - left)

    M.m10 = 0.0
    M.m11 = Sy
    M.m12 = 0.0
    M.m13 = Sy*(top + bottom) / (top - bottom)

    M.m20 = 0.0
    M.m21 = 0.0
    M.m22 = Sz
    M.m23 = Sz*(tfar + tnear) / (tfar - tnear)

    M.m30 = 0.0
    M.m31 = 0.0
    M.m32 = 0.0
    M.m33 = 1.0

    return M
end

-- //********************************************************************************************************************

function fMat44_OrthoNormalize( a)

    local M = ffi.new("fMat44")
    local Z = ffi.new("fVector3")

    local X = ffi.new("fVector3", {a.m00, a.m10, a.m20} )
    local Y = ffi.new("fVector3", {a.m01, a.m11, a.m21} )

    X = fVector3_Normalize(X)
    Z = fVector3_Cross(X, Y)
    Y = fVector3_Cross(Z, X)

    M.m00 = X.x
    M.m10 = X.y
    M.m20 = X.z
    M.m30 = 0.0

    M.m01 = Y.x
    M.m11 = Y.y
    M.m21 = Y.z
    M.m31 = 0.0

    M.m02 = Z.x
    M.m12 = Z.y
    M.m22 = Z.z
    M.m32 = 0.0

    M.m03 = 0
    M.m13 = 0
    M.m23 = 0
    M.m33 = 1

    return M
end

-- //********************************************************************************************************************
