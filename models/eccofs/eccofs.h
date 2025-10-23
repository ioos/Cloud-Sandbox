/*
** svn $Id
*******************************************************************************
** Copyright (c) 2002-2007 The ROMS/TOMS Group                               **
**   Licensed under a MIT/X style license                                    **
**   See License_ROMS.txt                                                    **
*******************************************************************************
**
** Experimental System for Predicting Shelf and Slope Optics (ONR MAB MURI)
**
** Application flag:   DOPPIO
** Input script:       ocean_doppio.in     ! not yet created
**
** This header file has been adapted from espresso.h, found at
** /home/julia/ROMS/espresso/RealTime/Compile/fwd/espresso.h
*/

#define NLM_DRIVER

/* Basic physics options */
#define UV_ADV
#define UV_COR
#define UV_VIS2
#define MIX_S_UV                       /* momentum mixing on s-surfaces */
#define TS_DIF2
#define MIX_GEO_TS              /* tracer mixing on constant z surfaces */
#undef  MIX_ISO_TS                 /* tracer mixing on density surfaces */
#undef  SPONGE
#define SOLVE3D
#define SALINITY
#define NONLIN_EOS
#define CRAIG_BANNER
#define CHARNOK
#define WIND_MINUS_CURRENT

#define ATM_PRESS
#define PRESS_COMPENSATE

#define GRID_EXTRACT

/* Additional physics and related options */
#undef  FLOATS 
/*
#define UV_PSOURCE        
#define TS_PSOURCE        
*/
#undef  BIO_FASHAM
#undef  BIO_LIMADONEY

/* #define T_PASSIVE                         temporary dye sanity check */
/* #define ANA_SPFLUX             passive tracer flux @ surface */

/* Basic numerics options */
#define UV_U3HADVECTION
#define UV_C4VADVECTION
#define DJ_GRADPS
#undef SPLINES_VDIFF
#undef SPLINES_VVISC
#undef RI_SPLINES
#define CURVGRID
#define MASKING

/* Outputs */
#undef OUT_DOUBLE
#ifdef  NLM_DRIVER
# define AVERAGES
# define AVERAGES_FLUXES
# define AVERAGES_AKV           /* save for offline 1D bio model testing */  
# define AVERAGES_AKT           /* save for offline 1D bio model testing */  
# define AVERAGES_AKS 
# undef  DIAGNOSTICS_TS  /* for shelf-wide temp/salt budget calculations */
# undef  DIAGNOSTICS_UV  /* for shelf-wide momentum  budget calculations */
#endif
/* The following options are appropriate for NENA when run with 
   (1) HYCOM initial and open boundary data 
   (2) NCEP daily average surface marine atmospheric forcing data
   (3) tides */

/* Surface and bottom boundary conditions */
#define UV_QDRAG
#ifdef  NLM_DRIVER
#define BULK_FLUXES    /*  this is not permanent */
#undef  NL_BULK_FLUXES
# define GLS_MIXING
# undef  LMD_MIXING
# undef  MY25_MIXING
#else
# define ANA_SSFLUX
#endif

#undef ANA_NUDGCOEF

#ifdef   BULK_FLUXES
# define  EMINUSP     /* evap from latent heat and combine with NCEP rain */
# undef DIURNAL_SRFLUX
# undef  LONGWAVE                      /* undef forces read net longwave */
# define  LONGWAVE_OUT /* define to read downward longwave, compute outgoing */
# undef  ANA_CLOUD
# undef  ANA_RAIN      /* with eminusp option forces read NCEP rain data */
# undef  SRELAXATION
# undef  QCORRECTION
# undef  ANA_WINDS
#endif
#define SOLAR_SOURCE   /* solar shortwave distributed over water column */
#define ANA_BSFLUX
#define ANA_BTFLUX


/* Vertical subgridscale turbulence closure */
#ifdef MY25_MIXING
# define N2S2_HORAVG
# define KANTHA_CLAYSON
#endif
#ifdef GLS_MIXING
# define KANTHA_CLAYSON
# undef  CANUTO_A
# define N2S2_HORAVG
#endif

/* Open boundary condition settings */
#ifdef  NLM_DRIVER
#define SSH_TIDES       /* Activated tides for initial, simple case */
#define UV_TIDES        /* Reactivated when tidal data acquired     */
#define TIDE_GENERATING_FORCES
#endif


#ifdef SSH_TIDES
# undef RAMP_TIDES
# define ADD_FSOBC         /* Tide data is added to OBC from HYCOM */
#endif
#ifdef UV_TIDES
# define ADD_M2OBC         /* Tide data is added to OBC from HYCOM */
#endif
/*
#ifdef NLM_DRIVER
#else
# define SOUTH_M3CLAMPED
# define SOUTH_TCLAMPED
# define EAST_M3CLAMPED
# define EAST_TCLAMPED
# define WEST_M3CLAMPED
# define WEST_TCLAMPED
#endif
*/
#undef STATIONS

/* Biology and geochemistry */
#ifdef BIO_LIMADONEY
# define DENITRIFICATION
# define BIO_SEDIMENT
# undef  RIVER_BIOLOGY      /* Deactivate rivers for initial, simple case */
# define ANA_SPFLUX
# define ANA_BPFLUX
#endif

#undef FORWARD_WRITE
#ifdef OPT_OBSERVATIONS
# define VCONVOLUTION
# define IMPLICIT_VCONV
# define FORWARD_READ
# define FORWARD_MIXING
# undef  FORWARD_WRITE
#endif
#undef  FULL_GRID

#undef AVERAGES_DETIDE

#define NO_LBC_ATT
#define DEFLATE
#define HDF5
