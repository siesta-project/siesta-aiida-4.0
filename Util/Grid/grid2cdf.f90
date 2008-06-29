! 
! This file is part of the SIESTA package.
!
! Copyright (c) Fundacion General Universidad Autonoma de Madrid:
! E.Artacho, J.Gale, A.Garcia, J.Junquera, P.Ordejon, D.Sanchez-Portal
! and J.M.Soler, 1996-2006.
! 
! Use of this software constitutes agreement with the full conditions
! given in the SIESTA license, as signed by all legitimate users.
!
program grid2cdf

!
! Converts a Grid (binary) file to netCDF format
!
! Usage: grid2cdf
!
!        The input file must be named "GRIDFUNC" (a symbolic link would do)
!        The output file is called "GridFunc.nc"
!
use netcdf

implicit none

integer, parameter  :: dp = selected_real_kind(14,100)
integer, parameter  :: sp = selected_real_kind(6,20)

integer  :: ncid 
integer  :: xyz_id, step_id, abc_id, spin_id
integer  :: cell_id, n1_id, n2_id, n3_id, gridfunc_id

integer   ::    nspin  ! Number of spins 
integer   ::    mesh(3)

integer   ::   ispin, iostat, ix, iy, iz, iret

real(dp)  ::    cell(3,3)
real(sp), dimension(:), allocatable :: gridfunc

!-----------------------------------------------------

open(unit=1,file="GRIDFUNC",form="unformatted",status="old",action="read", &
            position="rewind",iostat=iostat)
if (iostat /= 0) then
  print *, "File GRIDFUNC cannot be opened"
  STOP
endif

read(1) cell(1:3,1:3)
read(1) mesh(1:3), nspin

allocate(gridfunc(1:mesh(1)))

call check( nf90_create('GridFunc.nc',NF90_CLOBBER,ncid))
       iret = nf90_def_dim(ncid,'xyz',3,xyz_id)
       call check(iret)
       iret = nf90_def_dim(ncid,'abc',3,abc_id)
       call check(iret)
       iret = nf90_def_dim(ncid,'spin',nspin,spin_id)
       call check(iret)
       iret = nf90_def_dim(ncid,'n1',mesh(1),n1_id)
       call check(iret)
       iret = nf90_def_dim(ncid,'n2',mesh(2),n2_id)
       call check(iret)
       iret = nf90_def_dim(ncid,'n3',mesh(3),n3_id)
       call check(iret)

       iret = nf90_def_var(ncid,'cell',nf90_float,(/xyz_id,abc_id/),cell_id)
       call check(iret)
       iret = nf90_put_att(ncid,cell_id,'Description', &
               "Cell vectors in Bohr: xyz, abc")
       call check(iret)

       iret = nf90_def_var(ncid,'gridfunc',nf90_float,(/n1_id,n2_id,n3_id,spin_id/),gridfunc_id)
       call check(iret)
       iret = nf90_put_att(ncid,gridfunc_id,'Description', &
               "Grid function -- ")
       call check(iret)

       iret = nf90_enddef(ncid)
       call check(iret)

!
       iret = nf90_put_var(ncid, cell_id, cell, start = (/1, 1 /), count = (/3, 3/) )
       call check(iret)

       do ispin=1,nspin
          do iz=1,mesh(3)
             do iy=1,mesh(2)
                read(1) (gridfunc(ix),ix=1,mesh(1))
                iret = nf90_put_var(ncid, gridfunc_id, gridfunc(1:mesh(1)), start = (/1, iy, iz, ispin /), &
                                                                            count = (/mesh(1), 1, 1, 1/) )
                call check(iret)
             enddo
          enddo
       enddo

       close(1)
       call check( nf90_close(ncid) )

CONTAINS

subroutine check(code)
use netcdf, only: nf90_noerr, nf90_strerror
integer, intent(in) :: code
if (code /= nf90_noerr) then
  print *, "netCDF error: " // NF90_STRERROR(code)
  STOP
endif
end subroutine check

end program grid2cdf