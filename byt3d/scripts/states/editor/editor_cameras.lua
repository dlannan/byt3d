--
-- Created by David Lannan
-- User: grover
-- Date: 5/03/13
-- Time: 7:55 PM
-- Copyright 2013  Developed for use with the byt3d engine.
--
------------------------------------------------------------------------------------------------------------

local CamEditor =
{
    omx     = 0.0,
    omy     = 0.0,
    campos  = { 0.0, 0.0, 0.0 }        -- Current camera position
}

------------------------------------------------------------------------------------------------------------

function ChangeCamera(callerobj)

    local level = gLevels["Default"].level
    level:ChangeCamera(callerobj.name)
    Gcairo.exploderStates[" Cameras"].state = 4
end

------------------------------------------------------------------------------------------------------------

function CamEditor:CameraList(level)

    -- A Window for selection of the camera to use (should break into seperate state)
    local content = Gcairo:List("camera_list", 0, 10, 180, 140)
    local tcolor = { r=1.0, b=1.0, g=1.0, a=1.0 }
    local nodes = {
    }

    for k,v in pairs(level.cameras) do

        local nline1 = { name="space1", size=6 }
        local nline2 = {
            { name="space1", size=4 },
            { name="test2", ntype=CAIRO_TYPE.IMAGE, image=level.icons.select, size=14, color=tcolor },
            { name="space1", size=4 },
            { name=k, ntype=CAIRO_TYPE.TEXT, size=14, callback=ChangeCamera }
        }
        if byt3dRender.currentCamera ~= v then nline2[2] = { name="space1", size=14 } end
        local nline2ref = { name="line2", ntype=CAIRO_TYPE.HLINE, size=14, nodes = nline2 }
        table.insert(nodes, nline1)
        table.insert(nodes, nline2ref )
    end

    --	nodes[11] = { name="space2", size=10 }
    --	nodes[12] = { name="Another Line", ntype=CAIRO_TYPE.TEXT, size=10 }
    content.nodes = nodes
    Gcairo.style.button_color = CAIRO_STYLE.METRO.SEAGREEN

    -- Render a slideOut object on left side of screen
    -- Gcairo:SlideOut(" Cameras",  CAIRO_UI.LEFT, 140, 20, 0, content)
    Gcairo:Exploder(" Cameras", level.icons.camera, CAIRO_UI.BOTTOM, 210, 3, 20, 20, 0, content)
end

------------------------------------------------------------------------------------------------------------

function CamEditor:CameraFreeController(mxi, myi, buttons)

    local cam = byt3dRender.currentCamera

    if buttons[3] == true then
        -- Free Camera rotate
        cam.heading = cam.heading + (mxi - self.omx) * 0.5
        cam.pitch = cam.pitch + (myi - self.omy) * 0.5

        local tbl = gSdisp.wm.KeyDown
        for k, v in pairs(tbl) do
            if v.scancode == sdl.SDL_SCANCODE_S then
                cam.speed = -2.0
            end
            if v.scancode == sdl.SDL_SCANCODE_W then
                cam.speed = 2.0
            end
        end
        if #tbl == 0 then
            cam.speed = cam.speed * 0.9
        end
    else
        cam.speed = cam.speed * 0.9
    end

    self.omx = mxi
    self.omy = myi
end

------------------------------------------------------------------------------------------------------------

function CamEditor:CameraUpdate()

    -- No need to move, if there is no speed!
    if math.abs(byt3dRender.currentCamera.speed) > 0.5 then

        local tm = byt3dRender.currentCamera.node.transform.m
        -- level.spheres["Model1"].node.transform:Position( tm[13], tm[14], tm[15] )
        local vec = { tm[3], tm[7], tm[11], 0.0 }
        local dir = VecNormalize( vec )

        -- Apply Speed
        byt3dRender.currentCamera.eye[1] = byt3dRender.currentCamera.eye[1] + dir[1] * byt3dRender.currentCamera.speed
        byt3dRender.currentCamera.eye[2] = byt3dRender.currentCamera.eye[2] + dir[2] * byt3dRender.currentCamera.speed
        byt3dRender.currentCamera.eye[3] = byt3dRender.currentCamera.eye[3] + dir[3] * byt3dRender.currentCamera.speed
    end

    byt3dRender.currentCamera:UpdateFromEye()
end

------------------------------------------------------------------------------------------------------------

return CamEditor

------------------------------------------------------------------------------------------------------------
