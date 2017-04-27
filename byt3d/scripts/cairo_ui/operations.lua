-----------------------------------------------------------------------------------------------------------

local operations = {}

-----------------------------------------------------------------------------------------------------------
-- Set the clipping region

function operations:ClipRegion(x1, y1, x2, y2)

	cr.cairo_rectangle(self.ctx, x1, y1, x2, y2)
	cr.cairo_clip(self.ctx)
end

------------------------------------------------------------------------------------------------------------
-- Reset the clipping region

function operations:ClipReset()

	cr.cairo_reset_clip(self.ctx)
end

------------------------------------------------------------------------------------------------------------
-- Push the current state (saves it)

function operations:PushState(scalex, scaley)

	cr.cairo_save(self.ctx)
end

------------------------------------------------------------------------------------------------------------
-- Pop the previous state (restores it)

function operations:PopState()

	cr.cairo_restore(self.ctx)
end

------------------------------------------------------------------------------------------------------------

function operations:Scale(scalex, scaley)
	cr.cairo_scale(self.ctx, scalex, scaley)
end

------------------------------------------------------------------------------------------------------------

function operations:Translate(transx, transy)
	cr.cairo_translate(self.ctx, transx, transy)
end

------------------------------------------------------------------------------------------------------------

function operations:Rotate(angle)
	cr.cairo_rotate(self.ctx, angle)
end

------------------------------------------------------------------------------------------------------------

return operations

------------------------------------------------------------------------------------------------------------
