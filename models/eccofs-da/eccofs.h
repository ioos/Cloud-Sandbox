/*
** git $Id
*******************************************************************************
** Copyright (c) 2002-2026 The ROMS Group                                    **
**   Licensed under a MIT/X style license                                    **
**   See License_ROMS.md                                                     **
*******************************************************************************
**
** East Coast Community Ocean Forecast System
**
** Application flag:   ECCOFS
** Input script:       roms_nl_eccofs.in   ! not yet created
**                     roms_da_eccofs.in   ! not yet created
**
*/

/* Basic physics options */

#define UV_ADV
#define UV_COR
#define UV_VIS2
#define MIX_S_UV
#define TS_DIF2
#define MIX_GEO_TS
#define SOLVE3D
#define SALINITY
#define NONLIN_EOS

#define ATM_PRESS
#define PRESS_COMPENSATE

/* Basic numerics options */

#define UV_U3HADVECTION
#define UV_C4VADVECTION
#define DJ_GRADPS
#define CURVGRID
#define MASKING
#define WTYPE_GRID

/* Surface and bottom boundary conditions */

#define UV_QDRAG
#define GLS_MIXING
#define BULK_FLUXES

#define CRAIG_BANNER
#define CHARNOK
#define LIMIT_STFLX_COOLING
#define WIND_MINUS_CURRENT

#ifdef BULK_FLUXES
# define COOL_SKIN
# undef  LONGWAVE
# define LONGWAVE_OUT
# define EMINUSP
# undef  SRELAXATION
# undef  QCORRECTION
#endif
#define SOLAR_SOURCE
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

#define SSH_TIDES
#define UV_TIDES
#define TIDE_GENERATING_FORCES

#ifdef SSH_TIDES
# undef RAMP_TIDES
# define ADD_FSOBC
#endif
#ifdef UV_TIDES
# define ADD_M2OBC
#endif

/*
**  Common options to all 4DVAR algorithms.
*/

#define PRIOR_BULK_FLUXES
#define FORWARD_FLUXES
#define FORWARD_WRITE
#define VCONVOLUTION
#define IMPLICIT_VCONV
#define FORWARD_READ
#define FORWARD_MIXING

/*
**  I/O files.
*/

#define NO_LBC_ATT
#undef  STATIONS

