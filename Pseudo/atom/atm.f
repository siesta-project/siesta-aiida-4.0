c
      program atm
c
      implicit none
c
      include 'radial.h'
      include 'orbital.h'
      include 'param.h'
      include 'charge.h'
      include 'elecpot.h'
      include 'energy.h'
c
C     .. Parameters ..
      double precision tol
      parameter (tol=1.D-8)
      double precision zero, one
      parameter (zero=0.D0,one=1.D0)
C     ..
C     .. Local Scalars ..
      double precision aa, dv, dvmax, t1, t2, xmixo, zsold
      integer i, icon2, iconv, iiter, iter, 
     &        itsm, maxit, nconf
      character icold*2, naold*2
      character pot_id*40, headline*79
C     ..
C     .. Local Arrays ..
      double precision econf(100)
C     ..
C     .. Arrays in Common ..
      double precision vn1d(nrmax), 
     &                 vn11d(nrmax), vn2d(nrmax), vn22d(nrmax),
     &                 vn1u(nrmax), vn11u(nrmax), vn2u(nrmax),
     &                 vn22u(nrmax), wk1(nrmax), wk2(nrmax)
C     ..
      common /mixer/ vn1d, vn11d, vn2d, vn22d,
     &               vn1u, vn11u, vn2u, vn22u,
     &               wk1, wk2
c
C     .. External Subroutines ..
      external hsc, ker, tm2
      double precision second
      external dmixp, dsolv1, dsolv2, etotal, ext, input,
     &         prdiff, pseudo, velect, vionic, second, denplot
C     ..
C     .. Intrinsic Functions ..
      intrinsic abs, exp, log, sqrt
C     ..
c
c  Initialize the timer.
c
      t1 = second()
c
c  Startup values for doing multiple input data sets.
c
      naold = '  '
      icold = '  '
      zsold = zero
      nconf = 0
      nr = nrmax
c
c      open files
c
      open(unit=5,file='INP',status='old',form='formatted')
      open(unit=6,file='OUT',status='unknown',form='formatted')
c
c   Print version
c
      call prversion
c
c   Process directives
c
      call check_directives(5)
c
c   Start of loop over configuration.
c
      job = 0
   10 continue
      norb = norbmx
c
c   Read the input data.
c
      Call Input
c
c  Stop - no more data in input file,
c  Find time taken for total calculation.
c
      if (job .lt. 0) then
         t2 = second()
         write(6,9000) t2 - t1
 9000    format(//' The total time for the calculation is ',f12.5,
     &         ' seconds')
         call ext(0)
      end if
c
c  Jump charge density 'set up' and ionic data input if
c  configuration test.
c
      itsm = znuc/9 + 3
      if (zsold .eq. zsh .and. naold .eq. nameat  .and.
     &    (job.lt.1.or.job.gt.4)) then

c        do nothing

      else

         if (job .lt. 4) then

c           Set up the initial charge density.
c           cdd and cdu  =  (4 pi r**2 rho(r))/2

c           The charge density setup (aa) is scaled with
c           an empirical formula that reduces the
c           number of iterations needed for the screening
c           potential convergence.

            aa = sqrt(sqrt(znuc))/2 + one
            do 20 i = 1, nr
               cdd(i) = zel*aa**3*exp(-aa*r(i))*r(i)**2/4
               cdu(i) = cdd(i)
   20       continue

         end if
c
c        set up ionic potentials
c
         call Vionic
c
      end if
c
c   Set up the electronic potential.
c
      call velect(0,0,ispp,zel)
c
      do 30 i = 1, nr
         vid(i) = vod(i)
         viu(i) = vou(i)
   30 continue
c
c   Start the iteration loop for electronic convergence.
c
      iconv = 0
      icon2 = 0
      maxit = 100
c
c    The screening potential mixing parameter is
c    an empirical function of the nuclear charge.
c    Larger atoms require a slower convergence
c    then smaller atoms.
c
      xmixo = one/log(znuc+7*one)
c
      do 50 iter = 1, maxit
c
         if (iter .eq. maxit) iconv = 1
c
c  compute orbitals
c
         if (icon2 .lt. 2) then
            call dsolv1(1,norb,no)
         else
            call dsolv2(iter,iconv,ispp,1,norb,ncore,no)
         end if
c
c  set up output electronic potential from charge density
c
         call velect(iter,iconv,ispp,zel)
c
c  check for convergence
c
         if (iconv .gt. 0) go to 60
         dvmax = zero
         do 40 i = 1, nr
            dv = (vod(i)-vid(i))/(1.D0+vod(i)+vou(i))
            if (abs(dv) .gt. dvmax) dvmax = abs(dv)
            dv = (vou(i)-viu(i))/(1.D0+vou(i)+vod(i))
            if (abs(dv) .gt. dvmax) dvmax = abs(dv)
   40    continue
         icon2 = icon2 + 1
         if (dvmax .le. tol) iconv = 1
c
c  Mix the input and output electronic potentials.
c
c    The screening potential is initially mixed with a
c    percentage of old and new for itsm iterations.
c    This brings the potential to a stable region
c    after which an Anderson's extrapolation scheme
c    is used.
c
         if (iter .lt. itsm) then
            iiter = 2
         else
            iiter = iter - itsm + 3
         end if
c
        call dmixp(vod,vid,xmixo,iiter,3,nr,wk1,wk2,
     1             vn1d,vn11d,vn2d,vn22d)
        call dmixp(vou,viu,xmixo,iiter,3,nr,wk1,wk2,
     1             vn1u,vn11u,vn2u,vn22u)
c
   50 continue
c
c   End of iteration of electronic convergence loop.
c
      write(6,9010) dvmax, xmixo
 9010 format(/' potential not converged - dvmax =',d10.4,' xmixo =',
     &      f5.3)
      call ext(1)
c
   60 continue
      write(6,9020) icon2
 9020 format(/' Total number of iterations needed for',
     &      ' electron screening potential is ',i2,/)
c
c  Find the total energy.
c
      call etotal(1,norb)
c
c  Plot the charge density.
c
      call denplot
c
c   Compute the logarithmic derivative as a function of energy 
c
      if (logder_radius .gt. 0.d0) call logder(ncore+1,norb,'AE')
c
c   Replace the valence charge density.
c
      if (job .eq. 5) call Vionic
c
c  Pseudopotential generation.
c
      if (job .ge. 1 .and. job .le. 3) then
c
ctwb
        ifcore = job - 1
ctwb
        if (scheme .eq. 0) then 
c HSC
          pot_id = 'Hamann, Schluter, and Chiang'
          write(headline,8000)
 8000     format(' nl    s    eigenvalue',6x,'rc',10x,'cl',9x,
     &           'gamma',7x,'delta')
c
          call Pseudo(pot_id,headline,hsc)
c
        else if (scheme .eq. 1) then
c KER
          pot_id = 'Kerker'                        
          write(headline,8020)
 8020     format(' nl    s    eigenvalue',6x,'rc',
     &             4x,6x,'cdrc',7x,'delta')
c
          call Pseudo(pot_id,headline,ker)
c
        else if (scheme .eq. 6) then
c TM2
          pot_id = 'Troullier-Martins'                        
          write(headline,8040)
 8040     format(' nl    s    eigenvalue',6x,'rc',
     &             10x,'cdrc',7x,'delta')
c
          call Pseudo(pot_id,headline,tm2)
c
        else
              write(6,*) ' Only HSC, KER, TM2 and TM4 supported.'
              stop 'NOFLAV'
c
        end if
c

      end if
c
c  printout difference from first configuration
c
      nconf = nconf + 1
      econf(nconf) = etot(10)
      if (naold .eq. nameat .and. icold .eq. icorr .and.
     &    nconf .ne. 1 .and. (job.lt.1.or.job.gt.3)) then
         call prdiff(nconf,econf)
         write(6,9080) etot(10) - econf(1)
      end if
      write(6,9090)
 9080 format(//' excitation energy         =',f18.8,/)
 9090 format(//60('%'),//)
c
      naold = nameat
      icold = icorr
      zsold = zsh
c
c   End loop of configuration.
c
      go to 10
c
      end