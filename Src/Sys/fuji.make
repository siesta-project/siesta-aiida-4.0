#
FC=fuji90
FC_ASIS=$(FC)
#
FFLAGS= -O -f 2006 -f 2004
FFLAGS_DEBUG= -g -O0 -f 2006 -f 2004 #-Hsu -ARy2
LIBS=  -llapack -lblas -lg2c
SYS=bsd
DEFS=
MPILIB=
MPI_INCLUDE=/usr/local/include
#
.F.o:
	$(FC) -c $(FFLAGS)  $(DEFS) $<
.f.o:
	$(FC) -c $(FFLAGS)   $<
.F90.o:
	$(FC) -c $(FFLAGS)  $(DEFS) $<
.f90.o:
	$(FC) -c $(FFLAGS)   $<
#


