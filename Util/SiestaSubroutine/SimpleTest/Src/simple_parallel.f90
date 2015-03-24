program simple

! A very simple driver for Siesta-as-subroutine (or siesta-as-server)
! This version launches a parallel version of siesta and communicates
! with it through unix pipes. It must be compiled with fsiesta_pipes.F90

  use fsiesta

  implicit none
  integer,parameter:: dp = kind(1.d0)

  integer,parameter :: na = 3
  integer :: ia
  real(dp):: e, fa(3,na), xa(3,na)

  data xa / 0.0, 0.0, 0.0, &
            0.7, 0.7, 0.0, &
           -0.7, 0.7, 0.0 /

! Set physical units
  call siesta_units( 'Ang', 'eV' )

! Launch a siesta process using two MPI processes
  call siesta_launch( 'h2o', nnodes=2, localhost=.true. )
  print*, 'siesta launched'

! Find forces
  call siesta_forces( 'h2o', na, xa, energy=e, fa=fa )
  print'(a,/,(3f12.6,3x,3f12.6))', 'xa, fa =', (xa(:,ia),fa(:,ia),ia=1,na)

! Find forces for another geometry
  xa(1,1) = 0.1
  call siesta_forces( 'h2o', na, xa, energy=e, fa=fa )
  print'(a,/,(3f12.6,3x,3f12.6))', 'xa, fa =', (xa(:,ia),fa(:,ia),ia=1,na)

! Quit siesta process
  call siesta_quit( 'h2o' )

end program simple

