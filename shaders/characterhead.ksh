   characterhead      MatrixP                                                                                MatrixV                                                                                MatrixW                                                                                SAMPLER    +         UI_LIGHTPARAMS                                COLOUR_XFORM                                                                                characterhead.vs�  uniform mat4 MatrixP;
uniform mat4 MatrixV;
uniform mat4 MatrixW;
uniform vec4 TIMEPARAMS;
uniform vec3 FLOAT_PARAMS;

attribute vec4 POS2D_UV;                  // x, y, u + samplerIndex * 2, v

varying vec3 PS_TEXCOORD;
varying vec3 PS_POSITION;
varying vec3 PS_POS;

void main()
{
    vec3 POSITION = vec3(POS2D_UV.xy, 0);
	// Take the samplerIndex out of the U.
    float samplerIndex = floor(POS2D_UV.z/2.0);
    vec3 TEXCOORD0 = vec3(POS2D_UV.z - 2.0*samplerIndex, POS2D_UV.w, samplerIndex);

	vec3 object_pos = POSITION.xyz;
	vec4 world_pos = MatrixW * vec4( object_pos, 1.0 );

	mat4 mtxPV = MatrixP * MatrixV;
	gl_Position = mtxPV * world_pos;

	PS_TEXCOORD = TEXCOORD0;
	PS_POSITION = POSITION;
	PS_POS = world_pos.xyz;

}
    characterhead.ps.  #if defined( GL_ES )
precision mediump float;
#endif

#if defined( TRIPLE_ATLAS )
	#define SAMPLER_COUNT 6
#elif defined( UI_CC )
	#define SAMPLER_COUNT 5
#elif defined( UI_HOLO )
	#define SAMPLER_COUNT 3
#else
	#define SAMPLER_COUNT 2
#endif

uniform sampler2D SAMPLER[SAMPLER_COUNT];

uniform vec4 UI_LIGHTPARAMS;

varying vec3 PS_TEXCOORD;
varying vec3 PS_POSITION;
varying vec3 PS_POS;

uniform mat4 COLOUR_XFORM;

void main()
{
    vec4 colour;
    
#if defined( TRIPLE_ATLAS )
    if( PS_TEXCOORD.z < 0.5 )
    {
        colour.rgba = texture2D( SAMPLER[0], PS_TEXCOORD.xy );
    }
    else if( PS_TEXCOORD.z < 1.5 )
    {
        colour.rgba = texture2D( SAMPLER[1], PS_TEXCOORD.xy );
    }
    else
    {
        colour.rgba = texture2D( SAMPLER[5], PS_TEXCOORD.xy );
    }
#else
    if( PS_TEXCOORD.z < 1.5 )
    {
        if( PS_TEXCOORD.z < 0.5 )
		{
			colour.rgba = texture2D( SAMPLER[0], PS_TEXCOORD.xy );
		}
		else
		{
            colour.rgba = texture2D( SAMPLER[1], PS_TEXCOORD.xy );
        }
    }
#endif
	float dist = distance(UI_LIGHTPARAMS.xy, gl_FragCoord.xy);
	if (dist > UI_LIGHTPARAMS.z * UI_LIGHTPARAMS.w) {
		discard;
	}
	colour = colour.rgba * COLOUR_XFORM;
	colour.rgb = min(colour.rgb, colour.a);
	
	gl_FragColor = colour.rgba;

}                          