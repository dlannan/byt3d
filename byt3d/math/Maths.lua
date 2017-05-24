--
-- Created by David Lannan
-- User: grover
-- Date: 12/04/13
-- Time: 8:00 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--
------------------------------------------------------------------------------------------------------------

function MergeBounds(tmin, tmax, Min, Max, Ctr)

    if tmin[1] < Min[1] then Min[1] = tmin[1] end
    if tmin[2] < Min[2] then Min[2] = tmin[2] end
    if tmin[3] < Min[3] then Min[3] = tmin[3] end

    if tmax[1] > Max[1] then Max[1] = tmax[1] end
    if tmax[2] > Max[2] then Max[2] = tmax[2] end
    if tmax[3] > Max[3] then Max[3] = tmax[3] end

    Ctr[1] = ( Max[1]-Min[1] ) / 2.0 + Min[1]
    Ctr[2] = ( Max[2]-Min[2] ) / 2.0 + Min[2]
    Ctr[3] = ( Max[3]-Min[3] ) / 2.0 + Min[3]

    return Min, Max, Ctr
end

------------------------------------------------------------------------------------------------------------
