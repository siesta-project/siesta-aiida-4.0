      module m_projected_DOS
      private
      public :: projected_DOS

      CONTAINS
      
      subroutine projected_DOS()
      use precision
      use sparse_matrices
      USE siesta_options
      use atomlist, only: indxuo, no_s, no_u, no_l
      use fdf, only : fdf_block, fdf_convfac
      use sys, only: die
      use m_mpi_utils, only : broadcast
      use Kpoint_grid
      use parallel, only: IOnode
      use parse
      use m_eo
      use m_spin,   only: nspin
      use m_gamma
      implicit none

      type(parsed_line), pointer  :: p

      integer  :: iu
      real(dp) :: factor
      integer  :: nhist ! Number of histogram intervals in projected DOS
      real(dp) :: e1    ! Lower bound of energy range
      real(dp) :: e2    ! Upper bound of energy range
      real(dp) :: sigma ! Energy width used to convolute partial DOS
      character(len=150) :: line    ! Data line read

!------------------------------------------------------------------------- BEGIN
! Compute the projected density of states
      if (IOnode) then
        do_pdos = fdf_block('ProjectedDensityOfStates',iu)
        if (isolve.ne.0.and.do_pdos) then
          write(6,*)
     .         'siesta: ERROR: PDOS implemented only with diagon'
          do_pdos = .false.
        endif
      endif
      call broadcast(do_pdos)

      if (do_pdos) then
! Find the desired energy range
        if (IOnode) then
          read(iu,'(a)') line
          p=>digest(line)
          if (nvalues(p).lt.3 .or. nnames(p).ne.1)
     $          call die("Wrong format in PDOS block")
          factor = fdf_convfac( names(p,1), 'Ry' )
          e1 = values(p,1) * factor
          e2 = values(p,2) * factor
          sigma = values(p,3) * factor
          nhist = integers(p,1)
          write(6,'(a)') 'siesta: PDOS info: '
          write(6,'(a,3(f8.2,a),2x,i5)')
     $           'siesta: e1, e2, sigma, nhist: ',
     $           e1/eV,' eV',e2/eV,' eV',sigma/eV,' eV', nhist
        endif

        call broadcast(e1)
        call broadcast(e2)
        call broadcast(sigma)
        call broadcast(nhist)

        call pdos( no_s, nspin, nspin, no_l, maxnh,
     .             no_u, numh, listhptr, listh, H, S,
     .             e1, e2, sigma, nhist,
     .             gamma, xijo, indxuo, nkpnt, kpoint, kweight, eo,
     .             no_u)

      endif                     ! PDOS calc (do_pdos)
!--------------------------------------------------------------------------- END

      end subroutine projected_DOS
      end module m_projected_DOS