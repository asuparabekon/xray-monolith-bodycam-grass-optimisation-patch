#define SSFX_WIND_ISGRASS

#include "common.h"
#include "check_screenspace.h"

#include "screenspace_mvectors.h"

uniform float4 ssfx_floravariation; // Grass Int, Grass Freq, Foliage Int, Foliage Freq

float4 grass_anim_prev;

float4 benders_prevpos[32]; // Prev Frame
float4 benders_pos[32]; // Current Frame
float4 benders_setup;
#ifndef DT_INST
float4 exdata[61]; // Terrain Normal [xyz] & Grass alpha [w]
#endif
int grass_align;

float4 consts; // {1/quant,1/quant,diffusescale,ambient}
float4 wave; // cx,cy,cz,tm
float4 dir2D; 
#ifdef DT_INST
#include "dt_inst.h"
Buffer<uint4> dt_ex : register(t11); // Terrain Normal [xyz] & Grass alpha [w], one per instance
#else
float4 array[61*4];
#endif

float4 wind;

#ifdef SSFX_WIND
	#include "screenspace_wind.h"
#endif

#if defined(DT_MERGE)
v2p_bumped 	main (uint vid : SV_VertexID, uint iid : SV_InstanceID)
#elif defined(DT_INST)
v2p_bumped 	main (v_detail v, uint iid : SV_InstanceID)
#else
v2p_bumped 	main (v_detail v)
#endif
{
	v2p_bumped 		O;
#ifdef DT_INST
#ifdef DT_MERGE
	uint	n;
	v_detail	v	= dt_vertex(vid, iid, n);
#ifdef	DT_OCC
	n	= dt_idx[n];
#endif
#else
	uint	n	= dt_inst(iid);
#endif
	float4  m0 	= dt_row(n, 0);
	float4  m1 	= dt_row(n, 1);
	float4  m2 	= dt_row(n, 2);
	float4  c0 	= asfloat(dt_rows[n * 4 + 3]);

	float4 data = asfloat(dt_ex[n]);
#else
	// index
	int 	i 	= v.misc.w;
	float4  m0 	= array[i+0];
	float4  m1 	= array[i+1];
	float4  m2 	= array[i+2];
	float4  c0 	= array[i+3];

	float4 data = exdata[i / 4]; // Adjust size ( 61 instead of 61*4 )
#endif

#ifdef	DT_THIN
	float	thin	= dt_thin_scale(float3(m0.w, m1.w, m2.w));
	m0.xyz	*= thin;
	m1.xyz	*= thin;
	m2.xyz	*= thin;
#endif

	// Transform pos to world coords
	float4 P;
 	P.x = dot(m0, v.pos);
 	P.y = dot(m1, v.pos);
 	P.z = dot(m2, v.pos);
	P.w = 1;

	float H = P.y - m1.w; // height of vertex (scaled)

	// Force grass to go up
	P.xz = P.xz - 0.5f * data.xz * H * grass_align;

	float4 P_prev = 0;

#ifndef SSFX_WIND
	float dp = calc_cyclic(dot(P, wave));
	float frac = v.misc.z * consts.x;	// fractional
	float inten = H * dp;
	float2 result = calc_xz_wave(dir2D.xz * inten, frac);
	
	float4 pos = float4(P.x + result.x, P.y, P.z + result.y, 1);
#else
	float3	wind_result = ssfx_wind_grass(P.xyz, H, ssfx_wind_setup(), false);
	float4 pos = float4(P.xyz + wind_result.xyz, 1);

	// Prev Position
	P_prev = float4(P.xyz + ssfx_wind_grass(P.xyz, H, ssfx_wind_setup(), true), 1);
#endif

	// INTERACTIVE GRASS - SSS Update 15.4
	// https://www.moddb.com/mods/stalker-anomaly/addons/screen-space-shaders/
#ifdef SSFX_INTER_GRASS
#if SSFX_INT_GRASS > 0
	for (int b = 0; b < SSFX_INT_GRASS + 1; b++)
	{
		// Direction, Radius & Bending Strength, Distance and Height Limit
		float3 dir = benders_pos[b + 16].xyz;
		float3 rstr = float3(benders_pos[b].w, benders_pos[b + 16].ww);
		bool non_dynamic = rstr.x <= 0 ? true : false;
		float dist = distance(pos.xz, benders_pos[b].xz);

		// Adjustments ( Fix Radius or Dynamic Radius )
		rstr.x = non_dynamic ? benders_setup.x : rstr.x;
 		rstr.yz *= non_dynamic ? benders_setup.yz : 1.0f;

		// Past the radius the bend below is zero and this body adds nothing.
		if (dist >= rstr.x + 0.001f)
			continue;

		float height_limit = 1.0f - saturate(abs(pos.y - benders_pos[b].y) / ( non_dynamic ? 2.0f : rstr.x ));
		height_limit *= H;

		// Strength through distance and bending direction.
		float bend = 1.0f - saturate(dist / (rstr.x + 0.001f));
		float3 bend_dir = normalize(pos.xyz - benders_pos[b].xyz) * bend;
		float3 dir_limit = dir.y >= -1 ? saturate(dot(bend_dir.xyz, dir.xyz) * 5.0f) : 1.0f; // Limit if nedeed

		// Apply direction limit
		bend_dir.xz *= dir_limit.xz;

		// Apply vertex displacement
		pos.xz += bend_dir.xz * 2.0f * rstr.yy * height_limit; 			// Horizontal
		pos.y -= bend * 0.6f * rstr.z * height_limit * dir_limit.y;		// Vertical
	}

	// Prev Frame
	for (int p = 0; p < SSFX_INT_GRASS + 1; p++)
	{
		// Direction, Radius & Bending Strength, Distance and Height Limit
		float3 dir = benders_prevpos[p + 16].xyz;
		float3 rstr = float3(benders_prevpos[p].w, benders_prevpos[p + 16].ww);
		bool non_dynamic = rstr.x <= 0 ? true : false;
		float dist = distance(P_prev.xz, benders_prevpos[p].xz);

		// Adjustments ( Fix Radius or Dynamic Radius )
		rstr.x = non_dynamic ? benders_setup.x : rstr.x;
 		rstr.yz *= non_dynamic ? benders_setup.yz : 1.0f;

		// Past the radius the bend below is zero and this body adds nothing.
		if (dist >= rstr.x + 0.001f)
			continue;

		float height_limit = 1.0f - saturate(abs(P_prev.y - benders_prevpos[p].y) / ( non_dynamic ? 2.0f : rstr.x ));
		height_limit *= H;

		// Strength through distance and bending direction.
		float bend = 1.0f - saturate(dist / (rstr.x + 0.001f));
		float3 bend_dir = normalize(P_prev.xyz - benders_prevpos[p].xyz) * bend;
		float3 dir_limit = dir.y >= -1 ? saturate(dot(bend_dir.xyz, dir.xyz) * 5.0f) : 1.0f; // Limit if nedeed

		// Apply direction limit
		bend_dir.xz *= dir_limit.xz;

		P_prev.xz += bend_dir.xz * 2.0f * rstr.yy * height_limit; 			// Horizontal
		P_prev.y -= bend * 0.6f * rstr.z * height_limit * dir_limit.y;		// Vertical
	}
#endif
#endif

	// FLORA FIXES & IMPROVEMENTS - SSS Update 22
	// https://www.moddb.com/mods/stalker-anomaly/addons/screen-space-shaders/	

	// Use terrain normal [ c0.xyz ]
	float3 N = mul((float3x3)m_WV, data.xyz);

	float3x3 xform = 0;

	// Normal
	xform[0].z = N.x;
	xform[1].z = N.y;
	xform[2].z = N.z;
	
	// Alpha here
	xform[0].x = data.w;

	// Feed this transform to pixel shader
	O.M1 			= xform[0];
	O.M2 			= xform[1];
	O.M3 			= xform[2];

	// Eye-space pos/normal
	float 	hemi 	= clamp(c0.w, 0.05f, 1.0f); // Some spots are bugged ( Full black ), better if we limit the value till a better solution. // Option -> v_hemi(N);
	float3	Pe		= mul		(m_V,  	pos		);
	O.tcdh 			= float4	((v.misc * consts).xyyy);
	O.hpos 			= mul		(m_VP,	pos		);
	O.position		= float4	(Pe, 	hemi	);

	// Values to calc motion vectors
	O.vel_curr = O.hpos;
	O.vel_prev = mul(m_vp_prev, P_prev);

	O.sss_extra = float4(0, 0, hash12(floor((P.xz + m0.xx * 2.0f) * ssfx_floravariation.y)), H);

	// TAA Jitter
	if (H < 0.1f)
		O.hpos.xy = ssfx_taa_jitter(O.hpos);

#ifdef	DT_THIN
	if (thin <= 0)
		O.hpos	= float4(0, 0, -1, 1);
#endif

#if defined(USE_R2_STATIC_SUN) && !defined(USE_LM_HEMI)
	O.tcdh.w		= hemi * c_sun.x + c_sun.y;					// (,,,dir-occlusion)
#endif

	return O;
}
FXVS;
