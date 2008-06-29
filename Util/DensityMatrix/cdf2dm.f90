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
program cdf2dm

!
! Converts a  netCDF DM file to DM format
!
! Usage: cdf2dm
!
!        The input file must be named "DM.nc" (a symbolic link would do)
!        The output file is called "DM"
!
use netcdf

implicit none

integer, parameter  :: dp = selected_real_kind(14,100)

integer ncid, norbs_id, nspin_id, nnzs_id, scf_step_id
integer no_s_id, indxuo_id
integer numd_id, row_pointer_id, column_id, dm_id

integer   ::    norbs  ! Number of atomic orbitals
integer   ::    no_s   ! Number of orbitals in interaction supercell
integer   ::    nnzs   ! Total number of orbital interactions
integer   ::    nspin  ! Number of spins 

integer   ::    iog, ios, ispin, j, iostat, nsteps

integer, dimension(:), allocatable  :: numd
integer, dimension(:), allocatable  :: row_pointer 
integer, dimension(:), allocatable  :: column
integer, dimension(:), allocatable  :: indxuo
real(dp), dimension(:,:), allocatable :: dm

!-----------------------------------------------------

open(unit=1,file="DM",form="unformatted",status="unknown",action="write", &
            position="rewind",iostat=iostat)
if (iostat /= 0) then
  print *, "File DM cannot be opened"
  STOP
endif


call check( nf90_open('DM.nc',NF90_NOWRITE,ncid))
       call check( nf90_inq_dimid(ncid,'nspin',nspin_id) )
       call check( nf90_inquire_dimension(ncid, dimid=nspin_id, len=nspin) )

       call check( nf90_inq_dimid(ncid,'norbs',norbs_id) )
       call check( nf90_inquire_dimension(ncid, dimid=norbs_id, len=norbs) )
       call check( nf90_inq_dimid(ncid,'no_s',no_s_id) )
       call check( nf90_inquire_dimension(ncid, dimid=no_s_id, len=no_s) )
       call check( nf90_inq_dimid(ncid,'nnzs',nnzs_id) )
       call check( nf90_inquire_dimension(ncid, dimid=nnzs_id, len=nnzs) )
       call check( nf90_inq_dimid(ncid,'scf_step',scf_step_id) )
       call check( nf90_inquire_dimension(ncid, dimid=scf_step_id, len=nsteps) )

       call check( nf90_inq_varid(ncid, "numd", numd_id) )
       call check( nf90_inq_varid(ncid, "row_pointer", row_pointer_id) )
       call check( nf90_inq_varid(ncid, "column", column_id) )
       call check( nf90_inq_varid(ncid, "dm", dm_id) )


write(1) norbs, nspin
allocate(numd(1:norbs),row_pointer(1:norbs))
allocate(column(1:nnzs),dm(1:nnzs,1:nspin))

call check( nf90_get_var(ncid,numd_id,numd(1:norbs),count=(/norbs/)))
write(1) (numd(iog),iog=1,norbs)
!
call check(nf90_get_var(ncid,row_pointer_id,row_pointer,count=(/norbs/)))
call check( nf90_get_var(ncid,column_id,column,count=(/nnzs/)))

do iog = 1, norbs
  write(1) (column(row_pointer(iog)+j),j=1,numd(iog))
enddo

   call check( nf90_get_var(ncid, dm_id, dm(1:nnzs,1:nspin),  & 
                              start = (/1, 1, nsteps /), &
                              count = (/nnzs, nspin, 1 /) ))
!
   do ispin = 1, nspin        
      do iog = 1, norbs
            write(1) (dm(row_pointer(iog)+j,ispin),j=1,numd(iog))
      enddo
   enddo

   close(1)

   deallocate(numd,row_pointer,column,dm)

   call check( nf90_close(ncid))
   print *, "Output in file DM"

CONTAINS

subroutine check(code)
use netcdf, only: nf90_noerr, nf90_strerror
integer, intent(in) :: code
if (code /= nf90_noerr) then
  print *, "netCDF error: " // NF90_STRERROR(code)
  STOP
endif
end subroutine check

end program cdf2dm