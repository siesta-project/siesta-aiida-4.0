SIESTA_ARCH=cscs-cray
#
# For Cray XT-3 at CSCS
# It uses pgf90 V6 (f95 !) as a backend
#
FC=ftn -target=catamount
FPP=linux-pgf90 -F
FC_ASIS=$(FC)
#
FFLAGS= -fast
FFLAGS_DEBUG= -g -O0
RANLIB=echo
COMP_LIBS=dc_lapack.a
#
NETCDF_LIBS=         #  /usr/local/netcdf-3.5/lib/pgi/libnetcdf.a
NETCDF_INTERFACE=    #  libnetcdf_f90.a
DEFS_CDF=            #  -DCDF
#
MPI_LIBS=
MPI_INTERFACE=
MPI_INCLUDE=
DEFS_MPI=
#
LIBS= 
SYS=nag
DEFS= $(DEFS_CDF) $(DEFS_MPI)
#
#
# Important 
# Compile atom.f and electrostatic.f without optimization.
#
atom.o:
	$(FC) -c $(FFLAGS_DEBUG) atom.f
electrostatic.o:
	$(FC) -c $(FFLAGS_DEBUG) electrostatic.f
#
.F.o:
	$(FPP) $(DEFS) $<  ; mv $*.f aux_$*.f
	$(FC) -c $(FFLAGS) $(INCFLAGS)  $(DEFS) -o $*.o aux_$*.f
	rm -f aux_$*.f
.f.o:
	$(FC) -c $(FFLAGS) $(INCFLAGS)   $<
.F90.o:
	$(FPP) $(DEFS) $<  ; mv $*.f aux_$*.f90
	$(FC) -c $(FFLAGS) $(INCFLAGS)  $(DEFS) -o $*.o aux_$*.f90
	rm -f aux_$*.f90
.f90.o:
	$(FC) -c $(FFLAGS) $(INCFLAGS)   $<
#