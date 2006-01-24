C $Id: volcel.f,v 1.1 2003/06/20 15:57:23 javier Exp $

      DOUBLE PRECISION FUNCTION VOLCEL( C )

C  CALCULATES THE VOLUME OF THE UNIT CELL

      DOUBLE PRECISION C(3,3)
      VOLCEL = ( C(2,1)*C(3,2) - C(3,1)*C(2,2) ) * C(1,3) +
     .         ( C(3,1)*C(1,2) - C(1,1)*C(3,2) ) * C(2,3) +
     .         ( C(1,1)*C(2,2) - C(2,1)*C(1,2) ) * C(3,3)
      VOLCEL = ABS( VOLCEL )
      END