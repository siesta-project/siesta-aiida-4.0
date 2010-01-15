      module m_recipes
!**********************************************************************
!    This file contains routines adapted from 'Numerical Recipes, 
!    The Art of Scientific Computing' by W.H. Press, S.A. Teukolsky, 
!    W.T. Veterling and B.P. Flannery, Cambridge U.P. 1987 and 1992.
!**********************************************************************

! Used module procedures and types
      use sys,       only: die  ! Termination routine
      use precision, only: dp   ! Double precision real kind

      implicit none

! Public procedures provided by this module
      public :: derf    ! Error function
      public :: derfc   ! Complementary error function
      public :: four1   ! 1-D fast Fourier transform
      public :: polint  ! Polynomial interpolation
      public :: spline  ! Set up spline interpolation
      public :: splint  ! Perform spline interpolation
      public :: sort    ! Sort an array by heapsort method
      public :: tqli    ! With tred2, diagonalizes a real matrix
      public :: tred2   ! Reduction of a real matrix to tridiagonal form

      private ! Nothing is declared public below this point

      contains

      SUBROUTINE FOUR1(DATA,NN,ISIGN)
!**********************************************************************
! Discrete Fourier transform. Modified and converted to double 
! precision from same routine in Numerical Recipes.
!**********************************************************************
! Input:
!   complex*16 DATA(NN) : Function to be Fourier transformed
!   integer    NN       : Number of points. Must be a power of 2
!   integer    ISIGN    : ISIG=+1/-1 => Direct/inverse transform
! Output:
!   complex*16 DATA(NN) : The direct Fourier transform (ISIG=+1), or
!                         NN times the inverse Fourier transf (ISIG=-1)
!**********************************************************************
      IMPLICIT NONE
      INTEGER  :: NN, ISIGN
      REAL(dp) :: DATA(2*NN)

      INTEGER  :: I, ISTEP, J, M, MMAX, N
      REAL(dp) :: TEMPI, TEMPR, THETA, WI, WPI, WPR, WR, WTEMP
      REAL(dp), PARAMETER :: TWOPI=6.28318530717959D0,
     .  HALF=0.5D0, ONE=1.D0, TWO=2.D0, ZERO=0.D0

      N=2*NN
      J=1
      DO I=1,N,2
        IF(J.GT.I)THEN
          TEMPR=DATA(J)
          TEMPI=DATA(J+1)
          DATA(J)=DATA(I)
          DATA(J+1)=DATA(I+1)
          DATA(I)=TEMPR
          DATA(I+1)=TEMPI
        ENDIF
        M=N/2
        DO ! until following condition is met
          IF ((M.LT.2).OR.(J.LE.M)) EXIT
          J=J-M
          M=M/2
        END DO
        J=J+M
      END DO ! I
      MMAX=2
      DO ! until following condition is met
        IF (N.LE.MMAX) EXIT
        ISTEP=2*MMAX
        THETA=TWOPI/(ISIGN*MMAX)
        WPR=(-TWO)*SIN(HALF*THETA)**2
        WPI=SIN(THETA)
        WR=ONE
        WI=ZERO
        DO M=1,MMAX,2
          DO I=M,N,ISTEP
            J=I+MMAX
            TEMPR=WR*DATA(J)-WI*DATA(J+1)
            TEMPI=WR*DATA(J+1)+WI*DATA(J)
            DATA(J)=DATA(I)-TEMPR
            DATA(J+1)=DATA(I+1)-TEMPI
            DATA(I)=DATA(I)+TEMPR
            DATA(I+1)=DATA(I+1)+TEMPI
          END DO ! I
          WTEMP=WR
          WR=WR*WPR-WI*WPI+WR
          WI=WI*WPR+WTEMP*WPI+WI
        END DO ! M
        MMAX=ISTEP
      END DO ! until (N.LE.MMAX)

      END SUBROUTINE FOUR1



      SUBROUTINE POLINT(XA,YA,N,X,Y,DY) 
!*****************************************************************
! Polinomic interpolation. Modified and adapted to double 
! precision from same routine of Numerical Recipes.
! D. Sanchez-Portal, Oct. 1996
!*****************************************************************
! Input:
!   real*8  XA(N) : x values of the function y(x) to interpolate
!   real*8  YA(N) : y values of the function y(x) to interpolate
!   integer N     : Number of data points
!   real*8  X     : x value at which the interpolation is desired
! Output:
!   real*8  Y     : interpolated value of y(x) at X
!   real*8  DY    : accuracy estimate
!*****************************************************************

      IMPLICIT NONE
      INTEGER  :: N
      REAL(dp) :: XA(N),YA(N), X, Y, DY

      INTEGER  :: I, M, NS
      REAL(dp) :: C(N), D(N), DEN, DIF, DIFT, HO, HP, W
      REAL(dp), PARAMETER :: ZERO=0.D0

      NS=1
      DIF=ABS(X-XA(1))
      DO I=1,N 
        DIFT=ABS(X-XA(I))
        IF (DIFT.LT.DIF) THEN
          NS=I
          DIF=DIFT
        ENDIF
        C(I)=YA(I)
        D(I)=YA(I)
      END DO ! I
      Y=YA(NS)
      NS=NS-1
      DO M=1,N-1
        DO I=1,N-M
          HO=XA(I)-X
          HP=XA(I+M)-X
          W=C(I+1)-D(I)
          DEN=HO-HP
          IF (DEN.EQ.ZERO) call die('polint: ERROR. Two XAs are equal')
          DEN=W/DEN
          D(I)=HP*DEN
          C(I)=HO*DEN
        END DO ! I
        IF (2*NS.LT.N-M) THEN
          DY=C(NS+1)
        ELSE
          DY=D(NS)
          NS=NS-1
        ENDIF
        Y=Y+DY
      END DO ! M

      END SUBROUTINE POLINT



      SUBROUTINE SPLINE(DX,Y,N,YP1,YPN,Y2) 
!*********************************************************** 
! Cubic Spline Interpolation. Adapted from Numerical Recipes 
! routine of same name for a uniform grid and double precision
! D. Sanchez-Portal, Oct. 1996.
! Input:
!   real*8  DX   : x interval between data points
!   real*8  Y(N) : value of y(x) at data points
!   integer N    : number of data points
!   real*8  YP1  : value of dy/dx at X1 (first point)
!   real*8  YPN  : value of dy/dx at XN (last point)
! Output:
!   real*8  Y2(N): array to be used by routine SPLINT
! Behavior:
! - If YP1 or YPN are larger than 1E30, the natural spline
!   condition (d2y/dx2=0) at the corresponding edge point.
!************************************************************

      IMPLICIT NONE
      INTEGER  :: N
      REAL(dp) :: DX, Y(N), YP1, YPN, Y2(N)

      INTEGER  :: I, K
      REAL(dp) :: QN, P, SIG, U(N), UN
      REAL(dp), PARAMETER :: YPMAX=0.99D30, 
     .  HALF=0.5D0, ONE=1.D0, THREE=3.D0, TWO=2.D0, ZERO=0.D0
    
      IF (YP1.GT.YPMAX) THEN
        Y2(1)=ZERO
        U(1)=ZERO
      ELSE
        Y2(1)=-HALF
        U(1)=(THREE/DX)*((Y(2)-Y(1))/DX-YP1)
      ENDIF
      DO I=2,N-1
        SIG=HALF
        P=SIG*Y2(I-1)+TWO
        Y2(I)=(SIG-ONE)/P
        U(I)=(THREE*( Y(I+1)+Y(I-1)-TWO*Y(I) )/(DX*DX)
     .       -SIG*U(I-1))/P
      END DO ! I
      IF (YPN.GT.YPMAX) THEN
        QN=ZERO
        UN=ZERO
      ELSE
        QN=HALF
        UN=(THREE/DX)*(YPN-(Y(N)-Y(N-1))/DX)
      ENDIF
      Y2(N)=(UN-QN*U(N-1))/(QN*Y2(N-1)+ONE)
      DO K=N-1,1,-1
        Y2(K)=Y2(K)*Y2(K+1)+U(K)
      END DO ! K

      END SUBROUTINE SPLINE



      SUBROUTINE SPLINT(DX,YA,Y2A,N,X,Y,DYDX) 
!***************************************************************
! Cubic Spline Interpolation. Adapted from Numerical Recipes 
! routine of same name for a uniform grid, double precision,
! and to return the function derivative in addition to its value
! D. Sanchez-Portal, Oct. 1996.
! Input:
!   real*8  DX    : x interval between data points
!   real*8  YA(N) : value of y(x) at data points
!   real*8  Y2A(N): array returned by routine SPLINE
!   integer N     : number of data points
!   real*8  X     : point at which interpolation is desired
!   real*8  Y     : interpolated value of y(x) at point X
!   real*8  DYDX  : interpolated value of dy/dx at point X
!***************************************************************

      IMPLICIT NONE
      INTEGER  :: N
      REAL(dp) :: DX, YA(N), Y2A(N), X, Y, DYDX

      INTEGER  :: NHI, NLO
      REAL(dp) :: A, B
      REAL(dp), PARAMETER ::
     .    ONE=1.D0, THREE=3.D0, SIX=6.D0, ZERO=0.D0

      IF (DX.EQ.ZERO) call die('splint: ERROR: DX=0')
      NLO=INT(X/DX)+1
      NHI=NLO+1
      IF (NLO<1 .OR. NHI>N) call die('splint: ERROR: X out of range')
      A=NHI-X/DX-1
      B=ONE-A
      Y=A*YA(NLO)+B*YA(NHI)+
     .  ((A**3-A)*Y2A(NLO)+(B**3-B)*Y2A(NHI))*(DX**2)/SIX
      DYDX=(YA(NHI)-YA(NLO))/DX+
     .     (-((THREE*(A**2)-ONE)*Y2A(NLO))+
     .     (THREE*(B**2)-ONE)*Y2A(NHI))*DX/SIX

      END SUBROUTINE SPLINT


      REAL(dp) function derfc(X)
      REAL(dp), intent(in) :: x

C  COMPLEMENTARY ERROR FUNCTION FROM "NUMERICAL RECIPES"
C  NOTE: SINGLE PRECISION ACCURACY

      REAL(dp) :: z, t

      Z = ABS(X)
      T = 1.0d0/(1.0d0 + 0.5d0*Z)
      DERFC=T*EXP(-(Z*Z)-1.26551223D0+T*(1.00002368D0+T*(0.37409196D0+
     .      T*(0.09678418D0+T*(-0.18628806D0+
     .      T*(0.27886807D0+T*(-1.13520398D0+
     .      T*(1.48851587D0+T*(-0.82215223D0+T*.17087277D0)))))))))
      if (X.LT.0.D0) DERFC=2.D0-DERFC

      end function derfc


      REAL(dp) function derf(X)
      REAL(dp), intent(in) :: x

C  ERROR FUNCTION FROM "NUMERICAL RECIPES"
C  NOTE: SINGLE PRECISION ACCURACY

      REAL(dp) :: z, t

      Z = ABS(X)
      T = 1.0d0/(1.0d0 + 0.5d0*Z)
      DERF= T*EXP(-(Z*Z)-1.26551223D0+T*(1.00002368D0+T*(0.37409196D0+
     .      T*(0.09678418D0+T*(-0.18628806D0+
     .      T*(0.27886807D0+T*(-1.13520398D0+
     .      T*(1.48851587D0+T*(-0.82215223D0+T*.17087277D0)))))))))
      if (X.LT.0.D0) DERF=2.D0-DERF

      derf = 1.0d0 - derf
      end function derf

c
      subroutine sort(n,arrin,indx)
c     sorts an array by the heapsort method
c     w. h. preuss et al. numerical recipes  (called indexx there)
C     .. Scalar Arguments ..
      integer n
C     ..
C     .. Array Arguments ..
      real(dp) arrin(n)
      integer indx(n)
C     ..
C     .. Local Scalars ..
      real(dp) q
      integer i, indxt, ir, j, l
C     ..

      if (n < 2) call die("Sort called for n<2")
      do 10 j = 1, n
         indx(j) = j
 10       continue
      l = n/2 + 1
      ir = n
 20    continue
      if (l .gt. 1) then
         l = l - 1
         indxt = indx(l)
         q = arrin(indxt)
      else
         indxt = indx(ir)
         q = arrin(indxt)
         indx(ir) = indx(1)
         ir = ir - 1
         if (ir .eq. 1) then
            indx(1) = indxt
c
            return
c
         end if
      end if
      i = l
      j = l + l
 30    continue
      if (j .le. ir) then
         if (j .lt. ir) then
            if (arrin(indx(j)) .lt. arrin(indx(j+1))) j = j + 1
         end if
         if (q .lt. arrin(indx(j))) then
            indx(i) = indx(j)
            i = j
            j = j + j
         else
            j = ir + 1
         end if
c
         go to 30
c
      end if
      indx(i) = indxt
c
      go to 20
c
      end subroutine sort

      SUBROUTINE TQLI(D,E,N,NP,Z)

! IN COMBINATION WITH TRED2 FINDS EIGENVALUES AND EIGENVECTORS OF
! A REAL SYMMETRIC MATRIX. REF: W.H.PRESS ET AL. NUMERICAL RECIPES.

      implicit none

      integer, intent(in)   :: N        ! True matrix dimension
      integer, intent(in)   :: NP       ! Physical size of arrays
      real(dp),intent(inout):: D(NP)    ! Vector prepared by tred2
      real(dp),intent(inout):: E(NP)    ! Input: vector prepared by tred2
                                        ! Output: eigenvalues
      real(dp),intent(out)  :: Z(NP,NP) ! Eigenvectors, in columns
      
      real(dp) :: zero, one, two
      PARAMETER (ZERO=0.0_dp,ONE=1.0_dp,TWO=2.0_dp)

      integer  :: iter, i, k, l, m
      real(dp) :: dd, g, r, s, c, p, f, b

      IF (N.GT.1) THEN
        DO 11 I=2,N
          E(I-1)=E(I)
11      CONTINUE
        E(N)=ZERO
        DO 15 L=1,N
          ITER=0
1         DO 12 M=L,N-1
            DD=ABS(D(M))+ABS(D(M+1))
            IF (ABS(E(M))+DD.EQ.DD) GO TO 2
12        CONTINUE
          M=N
2         IF(M.NE.L)THEN
            IF(ITER.EQ.30) STOP 'tqli: too many iterations'
            ITER=ITER+1
            G=(D(L+1)-D(L))/(TWO*E(L))
            R=SQRT(G**2+ONE)
            G=D(M)-D(L)+E(L)/(G+SIGN(R,G))
            S=ONE
            C=ONE
            P=ZERO
            DO 14 I=M-1,L,-1
              F=S*E(I)
              B=C*E(I)
              IF(ABS(F).GE.ABS(G))THEN
                C=G/F
                R=SQRT(C**2+ONE)
                E(I+1)=F*R
                S=ONE/R
                C=C*S
              ELSE
                S=F/G
                R=SQRT(S**2+ONE)
                E(I+1)=G*R
                C=ONE/R
                S=S*C
              ENDIF
              G=D(I+1)-P
              R=(D(I)-G)*S+TWO*C*B
              P=S*R
              D(I+1)=G+P
              G=C*R-B
              DO 13 K=1,N
                F=Z(K,I+1)
                Z(K,I+1)=S*Z(K,I)+C*F
                Z(K,I)=C*Z(K,I)-S*F
13            CONTINUE
14          CONTINUE
            D(L)=D(L)-P
            E(L)=G
            E(M)=ZERO
            GO TO 1
          ENDIF
15      CONTINUE
      ENDIF
      RETURN
      END subroutine tqli


      SUBROUTINE TRED2(A,N,NP,D,E)

!HOUSEHOLDER REDUCTION OF A REAL SYMMETRIC MATRIX INTO TRIDIAGONAL FORM
!REF: W.H.PRESS ET AL. NUMERICAL RECIPES. CAMBRIDGE U.P.

      implicit none

      integer, intent(in)   :: N        ! True matrix dimension
      integer, intent(in)   :: NP       ! Physical size of arrays
      real(dp),intent(inout):: A(NP,NP) ! Real symmetric matrix (overwritten)
      real(dp),intent(out)  :: D(NP)    ! Vector to be used by tqli
      real(dp),intent(out)  :: E(NP)    ! Vector to be used by tqli

      real(dp) ::  zero, one
      PARAMETER (ZERO=0.0_dp,ONE=1.0_dp)

      integer  :: l, i, k, j
      real(dp) :: f, g, h, hh, scale

      IF(N.GT.1)THEN
        DO 18 I=N,2,-1
          L=I-1
          H=ZERO
          SCALE=ZERO
          IF(L.GT.1)THEN
            DO 11 K=1,L
              SCALE=SCALE+ABS(A(I,K))
11          CONTINUE
            IF(SCALE.EQ.ZERO)THEN
              E(I)=A(I,L)
            ELSE
              DO 12 K=1,L
                A(I,K)=A(I,K)/SCALE
                H=H+A(I,K)**2
12            CONTINUE
              F=A(I,L)
              G=-SIGN(SQRT(H),F)
              E(I)=SCALE*G
              H=H-F*G
              A(I,L)=F-G
              F=ZERO
              DO 15 J=1,L
                A(J,I)=A(I,J)/H
                G=ZERO
                DO 13 K=1,J
                  G=G+A(J,K)*A(I,K)
13              CONTINUE
                IF(L.GT.J)THEN
                  DO 14 K=J+1,L
                    G=G+A(K,J)*A(I,K)
14                CONTINUE
                ENDIF
                E(J)=G/H
                F=F+E(J)*A(I,J)
15            CONTINUE
              HH=F/(H+H)
              DO 17 J=1,L
                F=A(I,J)
                G=E(J)-HH*F
                E(J)=G
                DO 16 K=1,J
                  A(J,K)=A(J,K)-F*E(K)-G*A(I,K)
16              CONTINUE
17            CONTINUE
            ENDIF
          ELSE
            E(I)=A(I,L)
          ENDIF
          D(I)=H
18      CONTINUE
      ENDIF
      D(1)=ZERO
      E(1)=ZERO
      DO 23 I=1,N
        L=I-1
        IF(D(I).NE.ZERO)THEN
          DO 21 J=1,L
            G=ZERO
            DO 19 K=1,L
              G=G+A(I,K)*A(K,J)
19          CONTINUE
            DO 20 K=1,L
              A(K,J)=A(K,J)-G*A(K,I)
20          CONTINUE
21        CONTINUE
        ENDIF
        D(I)=A(I,I)
        A(I,I)=ONE
        IF(L.GE.1)THEN
          DO 22 J=1,L
            A(I,J)=ZERO
            A(J,I)=ZERO
22        CONTINUE
        ENDIF
23    CONTINUE
      RETURN
      END subroutine tred2

      end module m_recipes