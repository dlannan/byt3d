--
-- Created by David Lannan
-- User: grover
-- Date: 4/05/13
-- Time: 4:16 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--



------------------------------------------------------------------------------------------------------------
-- // void* fAssertPointerFL(const void* p, const char* msg, const char* file, const int line);


------------------------------------------------------------------------------------------------------------
function fAssert(a)

    if ( (a) == false) then

        io.write("Assert fail", debug.traceback(), "\n")
        exit(-1)
    end
end

------------------------------------------------------------------------------------------------------------

function fAssertFL(a)

    if ( (a) == false) then
        local info = debug.getinfo(2)
        io.write("Assert fail ", info.what, info.source, "\n")
        exit(-1)
    end
end

------------------------------------------------------------------------------------------------------------

function ftrace( fmat, ... )

    local output = string.format( fmat, ...  )
    io.write( output )
end

------------------------------------------------------------------------------------------------------------
