C
C    rho2xsf,  a script to transform 3-dim grid function
C             (i.e. LDOS, RHO, DRHO, etc.) written in SIESTA by subr. iorho
C             into an arbitrarily chosen grid for XCrysden,
C             using linear 4-point interpolation 
C
C   !!! --------------------  IMPORTANT  ---------------------- !!!
C   compile this code with the same compiler switches as Siesta,
C         in what regards using single/double precision,
C       otherwise reading the data from unformatted files 
C              written by iorho.F  might be spoiled.  
C                Don't say you haven't been warned.
C                                !!!
C
C             Written by Andrei Postnikov, Jul 2005   Vers_0.1
C             apostnik@uos.de
C
      program rho2xsf
      implicit none
      integer ii1,ii2,io1,is1
      parameter (ii1=11,ii2=12,io1=14,is1=13)
      integer mesh0(3),mesh1(3),ip,nspin,is,ii,jj,n1,n2,n3,
     .        iat,nat,ityp,nz,ix,iy,iz,ind,mn,ncount,
     .        ixmax,iymax,izmax,ixmin,iymin,izmin,ialloc,
     .        ishift,jshift,kshift,n1div,n2div,n3div,i1,i2,i3
      integer limit,maxa,maxo,maxuo,maxnh,maxna,il,ia,nrela(3),idim
      parameter (limit=5)  !  tried translations along each lattice vector
      character inpfil*60,outfil*60,syslab*30,suffix*6,
     .          unitlab*1,labunit*9
      logical unitb,hit,charge,waves
      double precision b2ang,cc_bohr(3,3),cc_ang(3,3),cc_inv(3,3),
     .                 coord(3),coort(3),obox(3),rbox(3,3),rinv(3,3),
     .                 cell(3,3),dum,rmaxo,rela,modu,rmesh(3),drela(3)
      parameter (b2ang=0.529177)   !  Bohr to Angstroem
      real, allocatable :: func(:) !  NB! single precision, as in iorho.F
      real   fintp,fmax,fmin       !  NB! single precision, as in iorho.F
      external hit,inver3,intpl04
C
C     string manipulation functions in Fortran used below:
C     len_trim(string): returns the length of string 
C                       without trailing blank characters,
C     char(integer)   : returns the character in the specified position
C                       of computer's ASCII table, i.e. char(49)=1
      
      write (6,701)
  701 format(" Specify  SystemLabel (or 'siesta' if none): ",$)
      read (5,*) syslab
      inpfil = syslab(1:len_trim(syslab))//'.XV'
      open (ii1,file=inpfil,form='formatted',status='old',err=801)
      write (6,*) 'Found and opened: ',inpfil
      outfil = syslab(1:len_trim(syslab))//'.XSF'
      open (io1,file=outfil,form='formatted',status='new',err=802)
      write (6,*) 'Opened as new:    ',outfil
C --  read in translation vectors, convert into Ang:
      do ii=1,3
        read  (ii1,*,end=803,err=803)  (cc_bohr(jj,ii),jj=1,3)
      enddo
      cc_ang = cc_bohr*b2ang
      call inver3(cc_ang,cc_inv)
      call makebox(obox,rbox,rinv)

C --- write crystal structure data.
C     write selected atoms first into a scratch file (ios), for the case
C     there are zero. Then the label 'ATOMS' with no  atoms following
C     will crash XCrySDen.
      open (is1, form='formatted',status='scratch')
      read  (ii1,*,end=804,err=804)  nat
      ncount = 0
      do iat=1,nat
        read (ii1,*,end=805,err=805) ityp, nz, (coord(ii),ii=1,3)
C       try displacements along lattice vectors to check whether
C       atoms fall into the given grid box. Hopefully [-limit,limit]
C       would be enough... 
        do ishift=-limit,limit   
        do jshift=-limit,limit   
        do kshift=-limit,limit   
          do jj=1,3
            coort(jj) = b2ang*coord(jj) + 
     +                  ishift*cc_ang(jj,1) +  
     +                  jshift*cc_ang(jj,2) +  
     +                  kshift*cc_ang(jj,3)   
          enddo
          if (hit(coort,obox,rinv)) then
            ncount = ncount + 1
            write (is1,201) nz, (coort(jj),jj=1,3)
          endif
        enddo
        enddo
        enddo
      enddo
      write (6,*) ' The box contains ',ncount,' atoms.'
      if (ncount.gt.0) then
        write (io1,'(a5)') 'ATOMS'
        rewind (is1)
        do iat = 1,ncount
          read  (is1,201) nz, (coort(jj),jj=1,3)
          write (io1,201) nz, (coort(jj),jj=1,3)
        enddo
      else
        write (6,*) ' This is OK, just be warned that your XSF file',
     .              ' will have no ATOMS secton!'
      endif 
      close (is1)
      close (ii1)
C --- finished with .XV
      write (6,704) 
  704 format (" Now define the grid. If you want it two-dimensional,",/
     .   " give 1 as number of grid points along one spanning vector.") 
  102 write (6,705) 
  705 format (" Enter number of grid points along three vectors: ",$)
      read (5,*) n1,n2,n3
      if (n1.le.0.or.n2.le.0.or.n3.le.0) then
        write (6,*) ' Numbers must be positive, try again.'
        goto 102
      endif
      idim = 3    !   dimensionalty of output grid
      if (n1.eq.1) idim = idim - 1
      if (n2.eq.1) idim = idim - 1
      if (n3.eq.1) idim = idim - 1

C --- Look for grid data files to include:
  103 write (6,706)
  706 format (' Add grid property (LDOS, RHO, ...;',
     .        ' or BYE if none): ',$)
      read (5,*) suffix
      inpfil = syslab(1:len_trim(syslab))//
     .      '.'//suffix(1:len_trim(suffix))
      open (ii2,file=inpfil,form='unformatted',status='old',err=806)
      write (6,*) 'Found and opened: ',inpfil(1:len_trim(inpfil))
      read (ii2,err=807) cell
      read (ii2,err=808) mesh0, nspin
      allocate (func(1:mesh0(1)*mesh0(2)*mesh0(3)),STAT=ialloc)
      if (ialloc.ne.0) then
        write (6,*) ' Fails to allocate space for ',
     .                mesh0(1)*mesh0(2)*mesh0(3),' grid points.'
        stop
      endif 
      write (6,*) 'mesh0 = (',mesh0,'),   nspin=',nspin
      write (io1,"('BEGIN_BLOCK_DATAGRID_',i1,'D')") idim
      write (io1,*) 'DATA_from:'//inpfil(1:len_trim(inpfil))
      do is=1,nspin
        fmax= -9.999E+10
        fmin=  9.999E+10
        write (io1,*) 'BEGIN_DATAGRID_'//char(48+idim)//'D_'//
     .        suffix(1:len_trim(suffix))//':spin_'//char(48+is)
        if (n1.ne.1) write (io1,'(i6,$)') n1
        if (n2.ne.1) write (io1,'(i6,$)') n2
        if (n3.ne.1) write (io1,'(i6,$)') n3
        write (io1,'()') 
        write (io1,'(1p,3e15.7)') (obox(ii),ii=1,3)
        if (n1.ne.1) write (io1,'(1p,3e15.7)') (rbox(ii,1),ii=1,3)
        if (n2.ne.1) write (io1,'(1p,3e15.7)') (rbox(ii,2),ii=1,3)
        if (n3.ne.1) write (io1,'(1p,3e15.7)') (rbox(ii,3),ii=1,3)
        
        ind=0                        
        do iz=1,mesh0(3)
          do iy=1,mesh0(2)
            read (ii2,err=809,end=810) (func(ind+ix),ix=1,mesh0(1))
            ind = ind + mesh0(1)
          enddo
        enddo

C ---   loop over mesh points
C       avoid division by zero if only 1 point is selected: 
        n1div=max(n1-1,1)  !  if (n1.eq.1) n1div=1 else n1div=n1-1
        n2div=max(n2-1,1)
        n3div=max(n3-1,1)
        ind = 0
        do i3=1,n3
          do i2=1,n2
            do i1=1,n1
              ind = ind+1
              do ii=1,3
                rmesh(ii) = obox(ii) + 
     +                      rbox(ii,1)*(i1-1)/n1div +
     +                      rbox(ii,2)*(i2-1)/n2div +
     +                      rbox(ii,3)*(i3-1)/n3div
              enddo
C ---         rmesh(1..3) are absolute Cartesian coordinates
C             of the mesh point (i1,i2,i3) in Angstroem
C             Find its relative coordinates on the unit cell grid:
              do ii=1,3
                rela = 0.0
                do jj=1,3
                  rela = rela + cc_inv(ii,jj)*rmesh(jj)
                enddo
C               take modulo to make sure that it falls within [0,1]:
                modu = modulo( rela*mesh0(ii), float(mesh0(ii)) )
                nrela(ii) = floor(modu) + 1
                drela(ii) = modu - nrela(ii) + 1
              enddo
C ---         mesh point rmesh(1..3) falls within the grid microcell
C             originating at the grid point nrela(1..3),
C             its relative coordinates within this microcell are drela(1..3)
C             Select neighboring grid points and make the interpolation:
              call intpl04 (func(1),fintp,
     .                      mesh0(1),mesh0(2),mesh0(3),nrela,drela)
              if (fintp.gt.fmax) then
                fmax = fintp
                ixmax = i1
                iymax = i2
                izmax = i3
              endif
              if (fintp.lt.fmin) then
                fmin = fintp
                ixmin = i1
                iymin = i2
                izmin = i3
              endif
              write (io1,'(1p,e13.5,$)') fintp      ! write without linebreak
              if (mod(ind,6).eq.0) write (io1,'()') ! linebreak after 6 numbers
            enddo    !  do i1 =
          enddo    !  do i2 =
        enddo    !  do i3 =
        write (io1,'()')  ! linebreak after all numbers
        write (io1,"(' END_DATAGRID_',i1,'D')") idim
        write (6,206) is,'max',fmax,ixmax,iymax,izmax
        write (6,206) is,'min',fmin,ixmin,iymin,izmin
      enddo  ! do is=1,nspin
      deallocate (func)
      write (io1,"('END_BLOCK_DATAGRID_',i1,'D')") idim
      close (ii2)
      goto 103                                                                  

  201 format (i4,3f20.8)
  203 format (3i6)
  204 format (3f12.7)
  205 format (1p,6e13.6)
C 205 format (1p,8e10.3)
  206 format (' For is=',i1,': ',a3,'. grid value =',1p,e12.5,
     .        ' at ix,iy,iz=',3i4)

  801 write (6,*) ' Error opening file ',
     .            inpfil(1:len_trim(inpfil)),' as old formatted'
      stop
  802 write (6,*) ' Error opening file ',
     .            outfil(1:len_trim(outfil)),' as new formatted'
      stop
  803 write (6,*) ' End/Error reading XV for cell vector ',ii
      stop
  804 write (6,*) ' End/Error reading XV for number of atoms line'
      stop
  805 write (6,*) ' End/Error reading XV for atom number ',iat
      stop
  806 write (6,*) ' A wild guess! There is no file ',
     .              inpfil(1:len_trim(inpfil)),'; close XSF and quit.'
      close (io1)
      stop
  807 write (6,*) ' Error reading cell vectors'
      stop
  808 write (6,*) ' Error reading n1,n2,n3,nspin '
      stop
  809 write (6,*) ' Error reading function values on the grid'
      stop
  810 write (6,*) ' Unexpected end of data for iy=',iy,
     .            ' iz=',iz,'  is=',is
      stop
  811 write (6,*) ' Error opening file ',
     .            outfil(1:len_trim(outfil)),' as new unformatted'
      stop
      end
