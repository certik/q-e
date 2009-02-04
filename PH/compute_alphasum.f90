!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine compute_alphasum
  !-----------------------------------------------------------------------
  !
  !   This routine computes the alphasum term which is used to compute the
  !   change of the charge due to the displacement of the augmentation
  !   term. (See Eq. 29)
  !   It implements Eq.13 of the notes.
  !
  !
#include "f_defs.h"

  USE kinds, only : DP
  USE ions_base, ONLY : nat, ityp, ntyp => nsp
  USE lsda_mod,   ONLY : current_spin, isk, lsda
  USE wvfct,      ONLY : nbnd, wg
  USE noncollin_module, ONLY : noncolin, npol
  USE uspp, ONLY: okvan
  USE uspp_param, ONLY: upf, nh 

  USE phus,       ONLY : alphasum, alphasum_nc, becp1, becp1_nc, alphap, &
                         alphap_nc
  USE qpoint,     ONLY : nksq
  USE control_ph, ONLY : nbnd_occ, lgamma

  implicit none

  integer :: ik, ikk, ikq, ijkb0, ijh, ikb, jkb, ih, jh, na, nt, &
       ipol, ibnd, is1, is2
  ! counter on k points
  ! counters on beta functions
  ! counters on beta functions
  ! counters for atoms
  ! counter on polarizations
  ! counter on bands

  real(DP) :: wgg1
  ! auxiliary weight


  if (.not.okvan) return

  alphasum  = 0.d0
  IF (noncolin) alphasum_nc=(0.d0,0.d0)
  do ik = 1, nksq
     if (lgamma) then
        ikk = ik
        ikq = ik
     else
        ikk = 2 * ik - 1
        ikq = ikk + 1
     endif
     if (lsda) current_spin = isk (ikk)
     ijkb0 = 0
     do nt = 1, ntyp
        if (upf(nt)%tvanp ) then
           do na = 1, nat
              if (ityp (na) == nt) then
                 ijh = 0
                 do ih = 1, nh (nt)
                    ikb = ijkb0 + ih
                    ijh = ijh + 1
                    do ibnd = 1, nbnd_occ (ikk)
                       wgg1 = wg (ibnd, ikk)
                       do ipol = 1, 3
                          IF (noncolin) THEN
                             DO is1=1,npol
                                DO is2=1,npol
                                   alphasum_nc(ijh,ipol,na,is1,is2) =         &
                                      alphasum_nc(ijh,ipol,na,is1,is2)+wgg1*  &
                                      (CONJG(alphap_nc(ikb,is1,ibnd,ipol,ik))*&
                                             becp1_nc(ikb,is2,ibnd,ik) +      &
                                       CONJG(becp1_nc(ikb,is1,ibnd,ik))*      &
                                             alphap_nc(ikb,is2,ibnd,ipol,ik))
                                END DO
                             END DO
                          ELSE
                             alphasum(ijh,ipol,na,current_spin) = &
                               alphasum(ijh,ipol,na,current_spin) + 2.d0*wgg1*&
                                DBLE (CONJG(alphap (ikb,ibnd,ipol,ik) ) * &
                               becp1  (ikb,ibnd,ik) )
                          END IF
                       enddo
                    enddo
                    do jh = ih+1, nh (nt)
                       jkb = ijkb0 + jh
                       ijh = ijh + 1
                       do ibnd = 1, nbnd
                          wgg1 = wg (ibnd, ikk)
                          do ipol = 1, 3
                             IF (noncolin) THEN
                                DO is1=1,npol
                                   DO is2=1,npol
                                      alphasum_nc(ijh,ipol,na,is1,is2) =     &
                                         alphasum_nc(ijh,ipol,na,is1,is2)    &
                                            +wgg1*  &
                                      (CONJG(alphap_nc(ikb,is1,ibnd,ipol,ik))* &
                                              becp1_nc(jkb,is2,ibnd,ik)+      &
                                       CONJG(becp1_nc(ikb,is1,ibnd,ik))*      &
                                             alphap_nc(jkb,is2,ibnd,ipol,ik) ) 
                                   END DO
                                END DO
                             ELSE
                                  alphasum(ijh,ipol,na,current_spin) = &
                                    alphasum(ijh,ipol,na,current_spin) + &
                                    2.d0 * wgg1 * &
                                      DBLE (CONJG(alphap(ikb,ibnd,ipol,ik) )*&
                                     becp1 (jkb,ibnd,ik)         + &
                                     CONJG( becp1 (ikb,ibnd,ik) ) *       &
                                     alphap (jkb,ibnd,ipol,ik) )
                             END IF
                          enddo
                       enddo
                    enddo
                 enddo
                 ijkb0 = ijkb0 + nh (nt)
              endif
           enddo
        else
           do na = 1, nat
              if (ityp (na) == nt) ijkb0 = ijkb0 + nh (nt)
           enddo
        endif
     enddo
  enddo

  IF (noncolin.and.okvan) THEN
     DO nt = 1, ntyp
        IF ( upf(nt)%tvanp ) THEN
           DO na = 1, nat
              IF (ityp(na)==nt) THEN
                 IF (upf(nt)%has_so) THEN
                    CALL transform_alphasum_so(alphasum_nc,na)
                 ELSE
                    CALL transform_alphasum_nc(alphasum_nc,na)
                 END IF
              END IF
           END DO
        END IF
     END DO
  END IF

  !      do na=1,nat
  !         nt=ityp(na)
  !         do ijh=1,nh(nt)*(nh(nt)+1)/2
  !            do ipol=1,3
  !               WRITE( stdout,'(3i5,f20.10)') na, ijh, ipol,
  !     +                              alphasum(ijh,ipol,na,1)
  !            enddo
  !         enddo
  !      enddo
  !      call stop_ph(.true.)
  return
end subroutine compute_alphasum
