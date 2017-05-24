--
-- Created by David Lannan - copyright 2013
-- Developed for the Byt3D project. byt3d.codeplex.com
-- User: dlannan
-- Date: 30/04/13
-- Time: 10:36 PM
--

------------------------------------------------------------------------------------------------------------

post_bloom_shader_frag = [[

precision highp float;

    uniform sampler2D   s_tex0;
	varying vec2 		v_texCoord0;

void main()
{
    vec4 sum = vec4(0);
    vec2 texcoord = v_texCoord0;
    int j;
    int i;

    for( i= -4 ;i < 4; i++)
    {
        for (j = -3; j < 3; j++)
        {
            sum += texture2D(s_tex0, texcoord + vec2(j, i)*0.004) * 0.25;
        }
    }
    if (texture2D(s_tex0, texcoord).r < 0.3)
    {
        gl_FragColor = sum*sum*0.012 + texture2D(s_tex0, texcoord);
    }
    else
    {
        if (texture2D(s_tex0, texcoord).r < 0.5)
        {
            gl_FragColor = sum*sum*0.009 + texture2D(s_tex0, texcoord);
        }
        else
        {
            gl_FragColor = sum*sum*0.0075 + texture2D(s_tex0, texcoord);
        }
    }
}
]]

------------------------------------------------------------------------------------------------------------
