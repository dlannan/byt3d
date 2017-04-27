------------------------------------------------------------------------------------------------------------

local import_svg = {}

------------------------------------------------------------------------------------------------------------

function import_svg:BuildSvg(svgdata)

	if(type(svgdata) ~= "table") then return end

	-- Get the label and deal with it!!!!
	local label = svgdata["label"]
	local xarg = svgdata["xarg"]

	if xarg ~= nil then
		if(xarg["stroke"]) 	then xarg["stroke"] = ConvertToRGB(xarg["stroke"]) end	
		if(xarg["fill"]) 	then xarg["fill"] 	= ConvertToRGB(xarg["fill"]) end	
		
		if(xarg["d"])		then xarg["d"] 		= ConvertToPath(xarg["d"]) end
	end
		
	for k,v in pairs(svgdata) do
		if k ~= "xarg" then	
			if(type(v) == "table") then 
				svgdata[k] = self:BuildSvg(v) 
			end
		else
			svgdata[k] = xarg
		end
	end	
	
	return svgdata
end

------------------------------------------------------------------------------------------------------------

function import_svg:RenderSvg(svgdata)

	if(type(svgdata) ~= "table") then return end

	-- Get the label and deal with it!!!!
	local label = svgdata["label"]
	local xargs = svgdata["xarg"]
	
	-- TODO: Not really sure what should be done with this. Need it?
--	if(label) == "title" then
--	end
	
	-- TODO: TEXT ALIGNMENT - Need to support this for proper rendering
	if(label) == "text" then
		local fsize 	= tonumber(xargs["font-size"])
		local x 		= tonumber(xargs["x"])
		local y 		= tonumber(xargs["y"])
		local opacity	= tonumber(xargs["opacity"])
		local a 		= 1.0
		if(opacity) then a = opacity end
		
		local sc = xargs["stroke"]
		local str = svgdata[1]
		if(str ~= nil) then self:RenderText( str, x, y, fsize, { r=sc.r, g=sc.g, b=sc.b, a=a } ) end
	end

	-- This is ok, but can make it better.
	if(label) == "ellipse" then

		local swidth 	= tonumber(xargs["stroke-width"])
		local rx 		= tonumber(xargs["rx"])
		local ry 		= tonumber(xargs["ry"])
		local cx 		= tonumber(xargs["cx"])
		local cy 		= tonumber(xargs["cy"])
		local opacity	= tonumber(xargs["opacity"])
		
		local sc = xargs["stroke"]
		local fc = xargs["fill"]

		cr.cairo_save (self.ctx)
		local a 		= 1.0
		if(opacity) then a = opacity end
		cr.cairo_translate(self.ctx, cx, cy)
		cr.cairo_scale(self.ctx, 1.0, ry / rx)

		cr.cairo_arc(self.ctx, 0.0, 0.0, rx, 0.0, 2 * math.pi)
		cr.cairo_set_source_rgba(self.ctx, fc.r, fc.g, fc.b, a)
		cr.cairo_fill_preserve( self.ctx )
		
		cr.cairo_set_source_rgba(self.ctx, sc.r, sc.g, sc.b, a)
		cr.cairo_set_line_width(self.ctx, swidth * ry/rx);			
		cr.cairo_stroke(self.ctx)			
		
		cr.cairo_restore(self.ctx)
	end

	-- Circle fits well with this system
	if(label) == "circle" then

		local sc = xargs["stroke"]
		local fc = xargs["fill"]
	
		local width 	= tonumber(xargs["stroke-width"])
		local cx 		= tonumber(xargs["cx"])
		local cy 		= tonumber(xargs["cy"])
		local r 		= tonumber(xargs["r"])
		local opacity	= tonumber(xargs["opacity"])

		local a 		= 1.0
		if(opacity ~= nil) then a = opacity end
		
		cr.cairo_arc (self.ctx, cx, cy, r, 0, 2 * math.pi)
		cr.cairo_set_source_rgba(self.ctx, fc.r, fc.g, fc.b, a)
		cr.cairo_fill_preserve ( self.ctx )

		cr.cairo_set_source_rgba(self.ctx, sc.r, sc.g, sc.b, a)
		cr.cairo_set_line_width (self.ctx, width);			
		cr.cairo_stroke (self.ctx)			
	end

	if(label) == "path" then
		local sc = xargs["stroke"]
		local fc = xargs["fill"]
		local opacity	= tonumber(xargs["opacity"])

		local swidth 	= tonumber(xargs["stroke-width"])

		if(xargs["d"]) then

			local a 		= 1.0
			if(opacity) then a = opacity end
			local xypoints = xargs["d"]
			cr.cairo_move_to (self.ctx, xypoints[1].x, xypoints[1].y)
			for pts = 2,#xypoints do
				cr.cairo_rel_line_to(self.ctx, xypoints[pts].x, xypoints[pts].y);
			end
			cr.cairo_close_path(self.ctx);
		
			cr.cairo_set_source_rgba(self.ctx, fc.r, fc.g, fc.b, a)
			cr.cairo_fill_preserve( self.ctx )
	
			cr.cairo_set_source_rgba(self.ctx, sc.r, sc.g, sc.b, a)
			cr.cairo_set_line_width (self.ctx, swidth);			
			cr.cairo_stroke (self.ctx)			
		end
	end
	
	-- Standard rect.. all good.
	if(label) == "rect" then
		local sc = xargs["stroke"]
		local fc = xargs["fill"]
		local opacity	= tonumber(xargs["opacity"])
		
		local swidth 	= tonumber(xargs["stroke-width"])
		local width 	= tonumber(xargs["width"])
		local height 	= tonumber(xargs["height"])
		local x 		= tonumber(xargs["x"])
		local y 		= tonumber(xargs["y"])
		
		local a 		= 1.0
		if(opacity) then a = opacity end
	
		cr.cairo_rectangle(self.ctx, x, y, width, height)
		cr.cairo_set_source_rgba(self.ctx, fc.r, fc.g, fc.b, a)
		cr.cairo_fill_preserve( self.ctx )

		cr.cairo_set_source_rgba(self.ctx, sc.r, sc.g, sc.b, a)
		cr.cairo_set_line_width (self.ctx, swidth);			
		cr.cairo_stroke (self.ctx)			
	end		

	for k,v in pairs(svgdata) do
		if k ~= "xarg" then	
			if(type(v) == "table") then 
				self:RenderSvg(v) 
			end
		end
	end	
end

------------------------------------------------------------------------------------------------------------

function import_svg:LoadSvg(filename)

    local xmldata = LoadXml(filename, 1)

	-- Root level should have svg label and xargs containing surface information
    local svgdata = xmldata.svg

	if(xmldata.svg) then
        -- Get the surface sizes, and so forth
		local xargs = svgdata["xarg"]
		local width = tonumber(xargs["width"])
		local height = tonumber(xargs["height"])
		local xmlns = xargs["xmlns"]

		for k,v in pairs(svgdata) do
            local temp = self:BuildSvg(v)
			svgdata[k] = temp
		end
	end

	return svgdata
end

------------------------------------------------------------------------------------------------------------

return import_svg

------------------------------------------------------------------------------------------------------------
