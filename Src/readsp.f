      subroutine readsp(q, spiral)
C *********************************************************************
C Subroutine to read the data for the SIESTA program
C
C     It uses the FDF (Flexible Data Fromat) package 
C     of J.M.Soler and A.Garcia
C
C Writen by J. Ferrer. June 2002
C **************************** OUTPUT *********************************
C real*8 q(3)              : Pitch wave vector for spiral configuration
C logical spiral           : True = Spiral arrangement of spins
C **********************************************************************

C
C  Modules
C
      use precision
      use fdf

      implicit none

      double precision
     .  q(3)

      logical
     .  spiral

      external
     .  redcel

C  Internal variables .................................................

      character
     .  lattice*30

      integer 
     .  iu, mscell(3,3)

      double precision
     .  pi, alat, ucell(3,3), scell(3,3), rcell(3,3)


C Read lattice constant and unit cell vectors .........................

      call redcel(alat, ucell, scell, mscell)
C...

C Spiral arrangement for spins ........................................
      pi = 2.d0 * asin(1.d0)
      if ( fdf_block('SpinSpiral',iu) ) then
         spiral = .true.
         read(iu,*) lattice
         read(iu,*) q(1), q(2), q(3)
         if ( lattice .eq. 'Cubic')  then
            q(1) = pi * q(1) / alat
            q(2) = pi * q(2) / alat
            q(3) = pi * q(3) / alat
         else if ( lattice .eq. 'ReciprocalLatticeVectors' ) then
            call reclat( ucell, rcell, 1 )
            q(1) = rcell(1,1)*q(1) + rcell(1,2)*q(2) + rcell(1,3)*q(3)
            q(2) = rcell(2,1)*q(1) + rcell(2,2)*q(2) + rcell(2,3)*q(3)
            q(3) = rcell(3,1)*q(1) + rcell(3,2)*q(2) + rcell(3,3)*q(3)
         else
            write(6,*) 'redata: ERROR: ReciprocalCoordinates must be
     .      ''Cubic'' or ''ReciprocalLatticeVectors'' '
            stop 'redata: ERROR: ReciprocalCoordinates for Spiral '
         endif
      else
         spiral = .false.
         q(1) = 0.d0
         q(2) = 0.d0
         q(3) = 0.d0
         lattice = 'unpolarized or collinear spins'
      endif

c     write(6,*) 'redata: Basis for vector q:    ', lattice
c     write(6,'(a,4(f9.2,3x))')
c    .  'redata: q(3)    ', q(1), q(2), q(3)

C...

      return
      end