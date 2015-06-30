! 
! This file is part of the SIESTA package.
!
! Copyright (c) Fundacion General Universidad Autonoma de Madrid:
! E.Artacho, J.Gale, A.Garcia, J.Junquera, P.Ordejon, D.Sanchez-Portal
! and J.M.Soler, 1996- .
! 
! Use of this software constitutes agreement with the full conditions
! given in the SIESTA license, as signed by all legitimate users.
!
      subroutine iofa( na, fa , has_constr )
c *******************************************************************
c Writes forces in eV/Ang
c Emilio Artacho, Feb. 1999
c Nick Papior, Jun 2015
c ********** INPUT **************************************************
c integer na           : Number atoms
c real*8  fa(3,na)     : Forces on the atoms
c logical has_constr   : whether the forces are constrained or not
c *******************************************************************

      use files,     only : slabel, label_length
      use precision, only : dp
      use units,     only : Ang, eV

      implicit          none

      integer,  intent(in) :: na
      real(dp), intent(in) :: fa(3,na)
      logical,  intent(in) :: has_constr

      external          io_assign, io_close

c Internal 
      character(len=label_length+4) :: fname
      integer                       :: ia, iu, ix
c -------------------------------------------------------------------

      if ( has_constr ) then
         fname = trim(slabel) // '.FAC'
      else
         fname = trim(slabel) // '.FA'
      end if

      call io_assign( iu )
      open( iu, file=fname, form='formatted', status='unknown',
     $      position='rewind')      

      write(iu,'(i6)') na
      write(iu,'(i6,3f12.6)') (ia, (fa(ix,ia)*Ang/eV,ix=1,3), ia=1,na)

      call io_close( iu )

      end
