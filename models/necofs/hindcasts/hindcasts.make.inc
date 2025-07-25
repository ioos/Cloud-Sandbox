#/===========================================================================/
# Copyright (c) 2007, The University of Massachusetts Dartmouth 
# Produced at the School of Marine Science & Technology 
# Marine Ecosystem Dynamics Modeling group
# All rights reserved.
#
# FVCOM has been developed by the joint UMASSD-WHOI research team. For 
# details of authorship and attribution of credit please see the FVCOM
# technical manual or contact the MEDM group.
#
# 
# This file is part of FVCOM. For details, see http://fvcom.smast.umassd.edu 
# The full copyright notice is contained in the file COPYRIGHT located in the 
# root directory of the FVCOM code. This original header must be maintained
# in all distributed versions.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR  IMPLIED WARRANTIES, INCLUDING,  BUT NOT  LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND  FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  
#
#/---------------------------------------------------------------------------/
# CVS VERSION INFORMATION
# $Id$
# $Name$
# $Revision$
#/===========================================================================/

#==========================================================================
#
#    WELCOME TO FVCOM
#
#    TO BUILD FVCOM, PLEASE SET THE FOLLOWING IN THIS FILE:
#        TOPDIR - the directory this make.inc file is in
#        LIBDIR - the directroy where libraries are installed
#        INCIDR - the directroy where include files are installed 
#
#        CHOOSE YOUR MODEL OPTIONAS - The Def Flags!
#
#        CHOOSE A COMPILER FROM THE LIST OR CREATE YOUR OWN
#
#    You can also use the makefile to build and install some of the libraries
#    used by fvcom. Set the INSTALLDIR and choose the 'LOCAL INSTALL' option
#    below. Select an non-mpi compiler from the list and run 'make libs_ext'
#
#    Good Luck!
#
#========== TOPDIR ========================================================
# TOPDIR is the directory in which this make file and the fvcom source reside

#TOPDIR        = /save/$(USER)/necofs/NECOFS_v2.4/hindcast/FVCOMv4.4.8/src
TOPDIR        = $(MODEL_DIR)/src

#EXAMPLE
# TOPDIR = /home/user/cchen/FVCOM_source
# TOPDIR must be set!
#========== INSTALLDIR =====================================================
# INSTALLDIR is the directory where you wish to install external libraries
# The default is in the $(TOPDIR)/libs/install, but you can choose...
#            INSTALLDIR    = $(TOPDIR)/libs/install
#===========================================================================
# PREPROCESSOR OPTIONS FOR CPP
#            DEF_FLAGS     = -P -C -traditional 
            DEF_FLAGS     = -P -traditional 
#===========================================================================
#
####################### MEDM ENVIRONMENT #####################################
# Use the environmental variables, LIBPATH and INCLUDEPATH, set by MODULE 
# to find the packages used by this build.
colon=:
empty=
dashI= $(empty) -I
dashL= $(empty) -L
# ### UNCOMMENT HERE!
#             LIBDIR       =  -L$(subst $(colon),$(dashL),$(LIBPATH))
#             INCDIR       =  -I$(subst $(colon),$(dashI),$(INCLUDEPATH))

###########################################################################

# LOCAL INSTAL
#             LIBDIR       =  -L$(INSTALLDIR)/lib
#             INCDIR       =  -I$(INSTALLDIR)/include


#--------------------------------------------------------------------------
#	STANDARD LIBRARIES FOR DATA AND TIME IN fVCOM:
#
            DTLIBS      = -L$(TOPDIR)/libs/julian -ljulian
            DTINCS      = -I$(TOPDIR)/libs/julian
#
#--------------------------------------------------------------------------
#        NETCDF OUTPUT      NETCDF IS NOW REQUIRED TO COMPILE FVCOM
#                           DUMP OUTPUT INTO NETCDF FILES (yes/no)
#                           REQUIRES SYSTEM DEPENDENT NETCDF LIBRARIES
#                           COMPILED WITH SAME F90 COMPILER
#                           SET PATH TO LIBRARIES WITH IOLIBS      
#                           SET PATH TO INCLUDE FILES (netcdf.mod) WITH IOINCS
#--------------------------------------------------------------------------
#            FLAG_USE_NETCDF4     = -DUSE_NETCDF4
#            FLAG_USE_COMPRESSION = -DUSE_COMPRESSION
#             IOLIBS       =  -lnetcdff -lnetcdf #-lhdf5_hl -lhdf5 -lz -lcurl -lm
#             IOINCS       =  #-I/hosts/mao/usr/medm/install/netcdf/3.6.3/em64t/include
             IOLIBS       =  -L$(NETCDF)/lib -lnetcdff
             IOINCS       =  -I${NETCDF}/include
#--------------------------------------------------------------------------
#     PETSC 
#       PETSC IS REQUIRED IF ANY OF THE FOLLOWING FLAGS IS TURNED ON:
#            FLAG_7  = -DDATA_ASSIM
#            FLAG_9  = -DSEMI_IMPLICIT
#            FLAG_23 = -DRRKF
#            FLAG_23 = -DENKF
#            FLAG_30 = -DNH
#            FLAG_37 = -DWAVE_OFFLINE
#       UNCOMMENT THE RIGHT PETSC FLAG BELOW ON VERSION:
#       FOR VERSION 2.0   TO 2.3.2
#            FLAG_41 = -DPETSC_A
##PT            include ${PETSC_DIR}/bmake/common/variables
#
#       FOR VERSION 2.3.3
##PT            FLAG_41 = -DPETSC_B
##PT            include ${PETSC_DIR}/bmake/common/variables
#
#       FOR VERSION 3.18.5 and higher
            FLAG_41 = -DPETSC_C
            include ${PETSC_DIR}/lib/petsc/conf/variables

#==========================================================================
#  BEGIN USER DEFINITION SECTION
#==========================================================================
#        SELECT MODEL OPTIONS
#          SELECT FROM THE FOLLOWING OPTIONS BEFORE COMPILING CODE
#          SELECT/UNSELECT BY COMMENTING/UNCOMMENTING LINE (#)
#          CODE MUST BE CLEANED (with "make clean") AND
#          RECOMPILED IF NEW SET OF OPTIONS IS DESIRED
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
#        PRECISION          DEFAULT PRECISION: SINGLE                     
#                           UNCOMMENT TO SELECT DOUBLE PRECISION
#--------------------------------------------------------------------------

#            FLAG_1 =  -DDOUBLE_PRECISION 

#        SINGLE PRECISION OUTPUT FOR VISIT
#            FLAG_1 =  -DDOUBLE_PRECISION -DSINGLE_OUTPUT

#--------------------------------------------------------------------------
#        SPHERICAL          SELECT SPHERICAL COORDINATES FOR INTEGRATION
#                           DEFAULT: CARTESIAN
#                           UNCOMMENT TO SELECT SPHERICAL COORDINATES
#--------------------------------------------------------------------------

#            FLAG_2 = -DSPHERICAL

#--------------------------------------------------------------------------
#        FLOODYING/DRYING   INCLUDE WET/DRY TREATMENT OF DOMAIN
#                           CAN BE ACTIVATED/DEACTIVATED AT RUN TIME WITH
#                           INPUT FILE CONTROL.  (SEE exa_run.dat) FILE
#                           DEFAULT: NO FLOODYING/DRYING INCLUDED
#                           UNCOMMENT TO INCLUDE FLOODYING/DRYING
#--------------------------------------------------------------------------

             FLAG_3 = -DWET_DRY

#--------------------------------------------------------------------------
#        MULTI_PROCESSOR    INCLUDES PARALLELIZATION WITH MPI
#                           REQUIRES LINKING MPI LIBRARIES OR COMPILING
#                           WITH A PRELINKED SCRIPT (mpif90/mpf90/etc)
#                           DEFAULT: NO PARALLEL CAPABILITY
#                           UNCOMMENT TO INCLUDE MPI PARALLEL CAPABILITY
#--------------------------------------------------------------------------

             FLAG_4 = -DMULTIPROCESSOR
#         If using METIS 5 or above, uncomment FLAG_411 and read the file readme_metis in folder METIS_readme for detail

         FLAG_411 = -DMETIS_5

#        If FLAG_411 is defined, uncomment path below	     
#             PARLIB = 
#             PARTINCS = -I/usr/local/install/metis/5.1.0/intel/19/include
#             PARTLIBS = -L/usr/local/install/metis/5.1.0/intel/19/lib -lmetis
         PARLIB =
         PARTINCS =
         PARTLIBS =

#        If FLAG_411 is not defined, uncomment path below
#             PARLIB = -lmetis  #-L/usr/local/lib -lmetis
#             PARTINCS =
#             PARTLIBS =

#--------------------------------------------------------------------------
#        WATER_QUALITY      INCLUDE EPA WATER QUALITY MOD
#                           CAN BE ACTIVATED/DEACTIVATED AT RUN TIME WITH
#                           VARIABLE WQM_ON IN INPUT FILE
#                           DEFAULT: NO WATER QUALITY MODEL
#                           UNCOMMENT TO INCLUDE WATER QUALITY MODEL
#--------------------------------------------------------------------------

#             FLAG_5 = -DWATER_QUALITY

#--------------------------------------------------------------------------
#        PROJECTION         A Fortran90 wrapper for the Cartographic projection
#                           Software, proj4. 
#                           Proj can be obtained from:
#                           http://www.remotesensing.org/proj/
#                           Thanks to: USGS
#
#                           The Proj fortran bindings can be obtained from:
#                           http://forge.nesc.ac.uk/projects/glimmer/
#                           Thanks to: Magnus Hagdorn (Magnus.Hagdorn@ed.ac.uk)
#
#                           !! NOTE THAT THE PROJ 4 LIBRARY MUST BE IN YOUR
#                           LD_LIBRARY_PATH FOR DYNAMIC LOADING!!
#
#--------------------------------------------------------------------------

#             FLAG_6 = -DPROJ

#             PROJLIBS       = -lfproj4 -lproj -lm
#             PROJINCS       =


#--------------------------------------------------------------------------
#        DATA_ASSIMILATION  INCLUDE NUDGING BASED DATA ASSIMILATION FOR
#                           CURRENT/TEMP/SALINITY/SST
#                           CAN BE ACTIVATED/DEACTIVATED AT RUN TIME WITH 
#                           INPUT FILE CONTROL.  (SEE exa_run.dat) FILE 
#                           DEFAULT: NO DATA ASSIMILATION INCLUDED 
#                           UNCOMMENT TO INCLUDE DATA ASSIMILATION 
#--------------------------------------------------------------------------

             FLAG_7 = -DDATA_ASSIM

##PT This is specified previously in this file
##PT      include ${PETSC_DIR}/bmake/common/variables

#             OILIB  = -lmkl_lapack -lmkl_em64t -lguide -lpthread
#             OILIB  = -L/usr/local/share/Intel-Compilers/mkl/lib/em64t -lmkl_lapack -lmkl_em64t -lguide -lpthread

# For Build on em64t computer (Guppy) 
#             LIBDIR = $(LIBDIR) -L/usr/local/lib64
# For Build on Cluster (Typhoeus and Hydra)
#             LIBDIR = $(LIBDIR) -L/usr/local/lib/em64t
# For i386 computers at SMAST (salmon and minke)
#   NO NEED TO ADD ANYTHING LIBS ARE IN THE DEFAULT PATH

#--------------------------------------------------------------------------
#        IN UPWIND LEAST SQUARE SCHEME:
#        LIMITED_NO: NO LIMITATION
#        LIMITED_1 : FIRST ORDER LIMITATION
#        LIMITED_2 : SECOND ORDER LIMITATION(  )
#   !!!!!! ONLY ONE OF THE FLAGS BELOW CAN BE AND MUST BE CHOSEN
#--------------------------------------------------------------------------

#            FLAG_8 =  -DLIMITED_NO
            FLAG_8 =  -DLIMITED_1
#            FLAG_8 =  -DLIMITED_2

#--------------------------------------------------------------------------
#  Semi-Implicit time stepping method
#--------------------------------------------------------------------------

             FLAG_9 = -DSEMI_IMPLICIT


#---------------------------------------------------------------------------
#       SOLID BOUNDARY     IF GCN, NO GHOST CELL
#                          IF GCY1, GHOST CELL IS SYMMETRIC RELATIVE TO BOUNDARY
#                          CELL EDGE
#                          IF GCY2, GHOST CELL IS SYMMETRIC RELATIVE TO MIDDLE
#                          POINT OF THE BOUNDARY CELL EDGE
#   !!!!!! ONLY ONE OF THE FLAGS BELOW CAN BE AND MUST BE CHOSEN
#---------------------------------------------------------------------------

             FLAG_10  = -DGCN
#             FLAG_10  = -DGCY1
#             FLAG_10 = -DGCY2

#--------------------------------------------------------------------------
#        TURBULENCE MODEL   USE GOTM TURBULENCE MODEL INSTEAD OF THE ORIGINAL
#                           FVCOM MELLOR-YAMADA 2.5 IMPLEMENTATION
#                           UNCOMMENT TO USE GOTM TURBULENCE MODEL
#        NOTE: You Must Build GOTM 4.x, GOTM 3.x used a different 
#              do_turbulence interface and will not work.
#--------------------------------------------------------------------------

#            FLAG_11 = -DGOTM
#            GOTMLIB       = -L../GOTM_source -lturbulence -lutil #-lmeanflow
#            GOTMINCS      = -I../GOTM_source  

#--------------------------------------------------------------------------
#       EQUILIBRIUM TIDE
#--------------------------------------------------------------------------

#            FLAG_12 = -DEQUI_TIDE

#--------------------------------------------------------------------------
#       ATMOSPHERIC TIDE
#--------------------------------------------------------------------------

#            FLAG_13 = -DATMO_TIDE

#--------------------------------------------------------------------------
#       RIVER DISTRIBUTION OPTION:
#       THE STANDARD NAME LIST USES A CHARACTER STRING TO SET A FUNCION
#       DISTROBUTION. YOU CAN OPTIONALLY SPECIFY TO USE THE OLD STYLE, 
#       FLOATING POINT DISTROBUTION HERE. USE THIS WHEN CONVERTING OLD-STYLE
#       RIVER INPUT FILES!
#--------------------------------------------------------------------------

            FLAG_14 = -DRIVER_FLOAT

#--------------------------------------------------------------------------
#        The TVD (total variational diminishing) option for FVCOM was developed by 
#        Akvaplan-niva (Håvard Espenes and Ole Anders Nøst) in 2018 (see mod_tvd.F).
#        Preliminary results suggest that TVD advection achieves less numerical
#        diffusion and better shape preserving properties than the standard scheme. 
#--------------------------------------------------------------------------

            FLAG_44 = -DTVD

#--------------------------------------------------------------------------
#        Using A fully multidimensional positive definite advection
#        transport algorithm with small implicit diffusion. 
#        Based on Smolarkiewicz, P. K; Journal of Computational
#        Physics, 54, 325-362, 1984
#--------------------------------------------------------------------------

            FLAG_15 = -DMPDATA

#--------------------------------------------------------------------------
#         Run Two-D Barotropic Mode Only
#--------------------------------------------------------------------------

#             FLAG_16 = -DTWO_D_MODEL

#--------------------------------------------------------------------------
#         Output 2-D Momentum Balance Checking
#--------------------------------------------------------------------------

#            FLAG_17 = -DBALANCE_2D  

#--------------------------------------------------------------------------
#           OPEN BOUNDARY FORCING TYPE 
#           DEFAULT: OPEN BOUNDARY NODE WATER ELEVATION FORCING
#           UNCOMMENT TO SELECT BOTH OPEN BOUNDARY NODE WATER ELEVATION
#           FORCING AND OPEN BOUNDARY VOLUME TRANSPORT FORCING 
#---------------------------------------------------------------------------

#            FLAG_18 = -DMEAN_FLOW

#--------------------------------------------------------------------------
#           OUTPUT TIDAL INFORMATION AT NTIDENODE and NTIDECELL
#           FOR MEANFLOW CALCULATION.
#---------------------------------------------------------------------------

#            FLAG_19 = -DTIDE_OUTPUT

#--------------------------------------------------------------------------
#           dye release      
#---------------------------------------------------------------------------

#            FLAG_20 = -DDYE_RELEASE  

#--------------------------------------------------------------------------
#        SUSPENDED SEDIMENT MODEL:   UNCOMMENT TO INCLUDE MODEL
# ORIG : the sediment transport model developed by Geoffey Cowles in v3.1-v3.2
# CSTMS: Community Sediment Transport Modeling System with cohesive model
# DELFT: Sediment modeling system as Delft Flow (not included)
#
# note: only one model should be chosen for modeling.
#
#  Utilities:
#    OFFLINE_SEDIMENT : run sediment with offline hydrodynamic forcing
#    FLUID_MUD : activate the 2-D fluid mud at bed-water interface
#--------------------------------------------------------------------------

#            FLAG_21 =  -DSEDIMENT
#            FLAG_211 = -DORIG_SED
#            FLAG_211 = -DCSTMS_SED
#
#            FLAG_22 =  -DOFFLINE_SEDIMENT
#            FLAG_43 =  -DFLUID_MUD
#
#--------------------------------------------------------------------------
#         KALMAN FILTERS
#--------------------------------------------------------------------------

#              FLAG_23 = -DRRKF
#              FLAG_23 = -DENKF
#              KFLIB  = -lmkl_lapack -lmkl_em64t -lguide -llapack -lblas 

# For Build on em64t computer (Guppy) 
#             LIBDIR = $(LIBDIR) -L/usr/local/lib64
# For Build on Cluster (Typhoeus and Hydra)
#             LIBDIR = $(LIBDIR) -L/usr/local/lib/em64t
# For i386 computers at SMAST (salmon and minke)
#   NO NEED TO ADD ANYTHING LIBS ARE IN THE DEFAULT PATH

#--------------------------------------------------------------------------
#         Run One-D Mode with Biological Model
#--------------------------------------------------------------------------

#             FLAG_24 = -DONE_D_MODEL

#--------------------------------------------------------------------------
#       GENERAL BIOLOGICAL MODEL:    UNCOMMENT TO INCLUDE MODEL
#-------------------------------------------------------------------------- 
#            FLAG_25  = -DBioGen
#            FLAG_251 = -DOFFLINE_BIOLOGY
#            BIOLIB   = -L$(TOPDIR)/BIO_source -lbiomodule
#            BIOINCS  = -I$(TOPDIR)/BIO_source


#--------------------------------------------------------------------------
#         Dynamic/Thermodynamic Ice                     
#--------------------------------------------------------------------------

# NOTE: Must use -DSPHERICAL  and -DHEAT_FLUX ----- this note only for old version v2.7
#            FLAG_26 = -DICE  
#       ICE_EMBEDDING must with SEMI_IMPLICIT
#            FLAG_261 = -DICE_EMBEDDING  
#       ICE_FRESHWATER
#       This flag adjusts the ice code to work for freshwater systems (Great Lakes) 
#            FLAG_262 = -DICE_FRESHWATER  

#--------------------------------------------------------------------------
#         CALCULATE THE NET HEAT FLUX IN MODEL (TWO CHOICES):
#         (IN CHOICE 1, THERE ARE OPTIONS FOR OCEAN WATER OR FRESH WATER)
#         1. CALCULATE THE NET HEAT FLUX USING COARE26Z OR COARE40VN
#         2. CALCULATE THE NET HEAT FLUX USING SOLAR HEATING MODULE                          
#--------------------------------------------------------------------------

#            FLAG_27 = -DHEATING_CALCULATED  
#            FLAG_27 = -DHEATING_SOLAR  

#--------------------------------------------------------------------------
#         AIR_PRESSURE FROM SURFACE FORCING                           
#--------------------------------------------------------------------------

            FLAG_28 = -DAIR_PRESSURE  

#--------------------------------------------------------------------------
# Visit online simulation mode
#--------------------------------------------------------------------------  

#            FLAG_29 = -DVISIT

#      VISITLIB     = -lm -ldl -lsimf -lsim -lpthread
#      VISITLIBPATH = $(LIBDIR)
#      VISITINCPATH = $(INCDIR)


# USE DEVELOPER INSTALL VISIT
#      VISITLIBPATH = 
#      VISITLIB     =  -lm -ldl -lsimf -lsim -lpthread
#      VISITINC     = 

#--------------------------------------------------------------------------
#        NON-HYDROSTATIC MODEL:
#--------------------------------------------------------------------------

#             FLAG_30 =  -DNH

#--------------------------------------------------------------------------
#        PARTICLE TRACKING
#--------------------------------------------------------------------------

#             FLAG_31 =  -DLAG_PARTICLE

#--------------------------------------------------------------------------
#        WAVE-CURRENT INTERACTION
#--------------------------------------------------------------------------
#             FLAG_32 =  -DWAVE_CURRENT_INTERACTION
#             FLAG_33 =  -DPLBC
#           NOTE! THis option is for wave code          
#             FLAG_34 =  -DEXPLICIT
#           WAVE ONLY
#             FLAG_35 = -DWAVE_ONLY
# Svendsen Roller contribution
#             FLAG_36 = -DWAVE_ROLLER
#             FLAG_37 = -DWAVE_OFFLINE
#--------------------------------------------------------------------------
#        THIN-DAM MODEL
#--------------------------------------------------------------------------
#             FLAG_38 = -DTHIN_DAM

#--------------------------------------------------------------------------
#        PWP MIXED LAYER MODEL:
#--------------------------------------------------------------------------

#            FLAG_39 =  -DPWP

#--------------------------------------------------------------------------
#        VERTICAL ADVECTION LIMITER:
#        FOR S-COORDINATES, DON'T USE THIS FLAG
#--------------------------------------------------------------------------

#           FLAG_40 =  -DLIMITER_VER_ADV
#--------------------------------------------------------------------------
#        SPECIAL PARTITION
#        This flag can make sure the identical repeat run for same amount of CPUs
#        (there should be no opt = -O3 when compilation)
#--------------------------------------------------------------------------
#             FLAG_42 = -DPARTITION_SPECIAL

#--------------------------------------------------------------------------
#        DEVELOPMENT FLAGS
#            FOR BETA WORK ONLY 
#--------------------------------------------------------------------------

#             FLAG_101 = -DDEVELOP1
#             FLAG_102 = -DDEVELOP2
#             FLAG_103 = -DDEVELOP3
#             FLAG_104 = -DDEVELOP4
#             FLAG_105 = -DDEVELOP5

#--------------------------------------------------------------------------
#    PARALLEL OUTPUT
#       FOR A PARALLEL NETCDF VERSION -- improved by Jingkun Chen @ SYSU CHINA
#--------------------------------------------------------------------------

#             FLAG_80 = -DPIO

#--------------------------------------------------------------------------
#        SELECT COMPILER/PLATFORM SPECIFIC DEFINITIONS
#          SELECT FROM THE FOLLOWING PLATFORMS OR USE "OTHER" TO DEFINE
#          THE FOLLOWING VARIABLES:
#          CPP:  PATH TO C PREPROCESSOR 
#           FC:  PATH TO FORTRAN COMPILER (OR MPI COMPILE SCRIPT)
#          OPT:  COMPILER OPTIONS
#       MPILIB:  PATH TO MPI LIBRARIES (IF NOT LINKED THROUGH COMPILE SCRIPT)
#--------------------------------------------------------------------------

#--------------------------------------------------------------------------
#        COMPAQ/ALPHA Definitions
#--------------------------------------------------------------------------
#        COMPILER   = -DCOMPAQ
#        CPP        = /bin/cpp
#        FC         = f90
#        DEBFLGS    =  # -check bounds -check overflow -g 
#        OPT        =  -fast -arch ev6 -fpe1
#--------------------------------------------------------------------------
#  CRAY Definitions         
#--------------------------------------------------------------------------
#         COMPILER = -DCRAY 
#         CPP      = /opt/ctl/bin/cpp
#         FC       = f90
#         DEBFLGS  =  
#         OPT      =
#--------------------------------------------------------------------------
#   Linux/Portland Group Definitions 
#--------------------------------------------------------------------------
#         CPP      = /usr/bin/cpp
#         COMPILER =  
#         FC       = pgf90
#         DEBFLGS  = -Mbounds -g -Mprof=func
#         OPT      = #-fast  -Mvect=assoc,cachesize:512000,sse  
#--------------------------------------------------------------------------
#  Intel Compiler Definitions
#--------------------------------------------------------------------------
#         CPP      = /usr/bin/cpp
#         COMPILER = -DIFORT
#         FC       = ifort
#         CC       = icc
#         CXX      = icc
#         CFLAGS   = -O3
#         DEBFLGS  = #-check all
# Use 'OPT = -O0 -g' for fast compile to test the make 
# Use 'OPT = -xP' for fast run on em64t (Hydra and Guppy)
# Use 'OPT = -xN' for fast run on ia32 (Salmon and Minke)
#         OPT      = -O0 -g  
#         OPT      = -xP 

# Do not set static for use with visit!
#         VISOPT   = -Wl,--export-dynamic
#         LDFLAGS  = $(VISITLIBPATH)
#--------------------------------------------------------------------------
#  Intel/MPI Compiler Definitions (SMAST)      
#--------------------------------------------------------------------------
#         CPP      = /usr/bin/cpp
#         COMPILER = -DIFORT  
#         CC       = mpicc
#         CXX      = mpicxx
#         CFLAGS   = -O3 
#         FC       = mpif90
##         DEBFLGS  = -check all -traceback
## Use 'OPT = -O0 -g'  for fast compile to test the make 
## Use 'OPT = -xP' for fast run on em64t (Hydra and Guppy)
## Use 'OPT = -xN' for fast run on ia32 (Salmon and Minke)
##         OPT      = -O0 -g
##         OPT      = -axN -xN
#         OPT      = -O3
#
# Do not set static for use with visit!
#         VISOPT   = -Wl,--export-dynamic
#         LDFLAGS  =  $(VISITLIBPATH)

#--------------------------------------------------------------------------
#  Intel OneAPI/MPI Compiler Definitions (AWS Cloud Sandbox)
#--------------------------------------------------------------------------
          CPPFLAGS = $(DEF_FLAGS)
          COMPILER = -DIFORT
          FIXEDFLAGS = -nofree
          FC       = $(COMP_F_MPI) -fc=ifort
          CC       = $(COMP_MPCC) -cc=icc
          CPP      = $(COMP_CPP)
          CXX      = $(COMP_CC)
          OPT      = -O3 -g -traceback -fp-model precise -ftz -fast-transcendentals -no-prec-div

#--------------------------------------------------------------------------
#  gfortran defs 
#--------------------------------------------------------------------------
#         CPP      = /usr/bin/cpp 
#         COMPILER = -DGFORTRAN
#         FC       = gfortran  -O3 
#         DEBFLGS  = 
#         OPT      = 
#         CLIB     = 
#--------------------------------------------------------------------------
#  absoft / mac os x defs
#--------------------------------------------------------------------------
#         CPP      = /usr/bin/cpp 
#         COMPILER = -DABSOFT  
#         FC       = f90  -O3  -lU77
#         DEBFLGS  = 
#         OPT      = 
#         CLIB     = 
#--------------------------------------------------------------------------
#  IBM/AIX Definitions
#--------------------------------------------------------------------------
#         COMPILER = -DAIX 
#         CPP      = /usr/local/bin/cpp
#         FC       = mpxlf90 -qsuffix=f=f90
#         DEBFLGS  =  # -qcheck -C -g
#         OPT      = -O -qarch=pwr4 -qtune=pwr4  -bmaxdata:0x80000000 -qhot -qmaxmem=8096
#--------------------------------------------------------------------------
#  APPLE OS X/XLF Definitions (G5)
#--------------------------------------------------------------------------
#         COMPILER = -DAIX
#         CPP      = /usr/bin/cpp
#         FC       =  /opt/ibmcmp/xlf/8.1/bin/xlf90 -qsuffix=f=f90
#         DEBFLGS  =  # -qcheck -C -g
#         OPT      = -O5 -qarch=g5 -qtune=g5  -qhot -qmaxmem=8096 -qunroll=yes -Wl,-stack_size,10000000
#--------------------------------------------------------------------------
#  OTHER                   
#--------------------------------------------------------------------------
#         COMPILER =
#         CPP      = 
#         FC       = 
#         DEBFLGS  = 
#         OPT      = 
#==========================================================================
#  END USER DEFINITION SECTION
#==========================================================================
         CPPFLAGS = $(DEF_FLAGS) $(COMPILER)
         FFLAGS = $(DEBFLGS) $(OPT)
         MDEPFLAGS = --cpp --fext=f90 --file=-
         RANLIB = ranlib
         AR = ar rc
#--------------------------------------------------------------------------
#  CAT Preprocessing Flags
#--------------------------------------------------------------------------
           CPPARGS =  $(CPPFLAGS) $(DEF_FLAGS) $(FLAG_1) $(FLAG_2) \
   $(FLAG_3) $(FLAG_4) $(FLAG_5) $(FLAG_6)  \
   $(FLAG_7) $(FLAG_8) $(FLAG_9) $(FLAG_10) \
   $(FLAG_11) $(FLAG_12) $(FLAG_13) $(FLAG_14) \
   $(FLAG_15) $(FLAG_16) $(FLAG_17) $(FLAG_18) \
   $(FLAG_19) $(FLAG_20) $(FLAG_21) $(FLAG_22) \
   $(FLAG_23) $(FLAG_24) $(FLAG_25) $(FLAG_26) \
   $(FLAG_27) $(FLAG_28) $(FLAG_29) $(FLAG_30) \
   $(FLAG_31) $(FLAG_32) $(FLAG_33) $(FLAG_34) \
   $(FLAG_35) $(FLAG_36) $(FLAG_37) $(FLAG_38) \
   $(FLAG_39) $(FLAG_40) $(FLAG_41) $(FLAG_42) \
   $(FLAG_43) $(FLAG_44) $(FLAG_80) $(FLAG_LAM) $(FLAG_411)\
   $(FLAG_101) $(FLAG_102) $(FLAG_103) $(FLAG_104) $(FLAG_105)\
   $(FLAG_211) $(FLAG_212) $(FLAG_213) $(FLAG_251) $(FLAG_261) $(FLAG_262)\
   $(FLAG_USE_NETCDF4) $(FLAG_USE_COMPRESSION)
#--------------------------------------------------------------------------
#  Libraries           
#--------------------------------------------------------------------------

            LIBS  =	$(LIBDIR) $(CLIB) $(PARLIB) $(PARTLIBS) $(IOLIBS)	$(DTLIBS)\
			$(MPILIB) $(GOTMLIB) $(KFLIB) $(BIOLIB)	\
			$(OILIB) $(VISITLIB) $(PROJLIBS) $(PETSC_LIB)

            INCS  = 	$(INCDIR) $(IOINCS) $(GOTMINCS) $(BIOINCS)\
			 $(VISITINCPATH) $(PROJINCS) $(DTINCS) $(PARTINCS)\
			 $(PETSC_FC_INCLUDES)
