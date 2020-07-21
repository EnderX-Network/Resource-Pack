#include "ShaderConstants.fxh"
#include "util.fxh"

struct PS_Input
{
    float4 position : SV_Position;
    float2 uv : TEXCOORD_0_FB_MSAA; 
    float4 vpos : Sun_View;
	float3 pos : Pos_;
};

struct PS_Output
{
    float4 color : SV_Target;
};

// --- Pio Shader Vanilla
float noise(float t)
{
	return frac(cos(t) * 3800.);
}

float3 lensflare(float2 u, float2 pos)
{
	float2 main = u-pos;
	float2 uvd = u * length(u);

	float ang = atan2( main.y, main.x );
	float dist = length(u);
	dist = pow( dist, .01);
	float n = noise( 0. );

	float f0 = (1.0/(length(u-12.)*16.0+1.0)) * 2.;

	f0 = f0*(sin((n*2.0)*12.0)*.1+dist*.1+.8);

	float f2 = max(1.0/(1.0+32.0*pow(length(uvd+0.8*pos),2.0)),.0)*00.25;
	float f22 = max(1.0/(1.0+32.0*pow(length(uvd+0.85*pos),2.0)),.0)*00.23;
	float f23 = max(1.0/(1.0+32.0*pow(length(uvd+0.9*pos),2.0)),.0)*00.21;

	float2 uvx = lerp(u,uvd,-0.5);

	float f4 = max(0.01-pow(length(uvx+0.45*pos),2.4),.0)*6.0;
	float f42 = max(0.01-pow(length(uvx+0.5*pos),2.4),.0)*5.0;
	float f43 = max(0.01-pow(length(uvx+0.55*pos),2.4),.0)*3.0;

	uvx = lerp(u,uvd,-.4);

	float f5 = max(0.01-pow(length(uvx+0.3*pos),5.5),.0)*2.0;
	float f52 = max(0.01-pow(length(uvx+0.5*pos),5.5),.0)*2.0;
	float f53 = max(0.01-pow(length(uvx+0.7*pos),5.5),.0)*2.0;

	uvx = lerp(u,uvd,-0.5);

	float f6 = max(0.01-pow(length(uvx+0.1*pos),1.6),.0)*6.0;
	float f62 = max(0.01-pow(length(uvx+0.125*pos),1.6),.0)*3.0;
	float f63 = max(0.01-pow(length(uvx+0.15*pos),1.6),.0)*5.0;

	float3 c = float3( 0.0, 0.0, 0.0 );
	c.r += f2 + f4 + f5 + f6; 
	c.g += f22 + f42 + f52 + f62; 
	c.b += f23 + f43 + f53 + f63;
	c += float3( f0, f0, f0 );

	return c;
}

float3 cc( float3 color, float factor, float factor2) // color modifier
{
	float w = color.x + color.y + color.z;
	return lerp( color, float3( w, w, w ) * factor, w * factor2 );
}
// ----------------------

ROOT_SIGNATURE
void main(in PS_Input PSInput, out PS_Output PSOutput)
{
#if !defined(TEXEL_AA) || !defined(TEXEL_AA_FEATURE) || (VERSION < 0xa000 /*D3D_FEATURE_LEVEL_10_0*/) 
	float4 diffuse = TEXTURE_0.Sample(TextureSampler0, frac( PSInput.uv * 3.0 ) );
#else
	float4 diffuse = texture2D_AA(TEXTURE_0, TextureSampler0, frac( PSInput.uv * 3.0 ) );
#endif

#ifdef ALPHA_TEST
    if( diffuse.a < 0.5 )
    {
        discard;
    }
#endif

float lp = length( PSInput.pos );
float4 fc = FOG_COLOR;
float hujan = (1.0-pow(FOG_CONTROL.y,11.0));
float sore = pow(max(min(1.0-fc.b*1.2,1.0),0.0),0.5);

float area = ( 1.0 -pow( lp, 0.3 ) );
diffuse = ( area >= 0.7 ) ? diffuse : float4( area - 0.3, area - 0.3, area - 0.3, area - 0.3 );

fc.rgb = max(fc.rgb, float3( 0.4, 0.4, 0.4 ) );
fc.a *= 1. -hujan;
diffuse.a = min(fc.a, .5);
float2 u = -PSInput.vpos.xz * .1;
float3 c = float3( 1.4, 1.2, 1. ) * lensflare( PSInput.pos.xz * 7.5, u ) * 1.5;
c = cc(c,.5,.1);
diffuse.rgb += ( c );

#ifdef IGNORE_CURRENTCOLOR
    PSOutput.color = diffuse;
#else
    PSOutput.color = CURRENT_COLOR * diffuse;
#endif

#ifdef WINDOWSMR_MAGICALPHA
    // Set the magic MR value alpha value so that this content pops over layers
    PSOutput.color.a = 133.0f / 255.0f;
#endif
}
