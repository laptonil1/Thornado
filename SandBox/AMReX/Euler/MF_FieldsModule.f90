MODULE MF_FieldsModule

  ! --- AMReX Modules ---

  USE amrex_multifab_module, ONLY: &
    amrex_multifab, &
    amrex_multifab_destroy
  USE amrex_fluxregister_module, ONLY: &
    amrex_fluxregister, &
    amrex_fluxregister_destroy
  USE amrex_amrcore_module, ONLY: &
    amrex_max_level

  ! --- thornado Modules ---

  USE FluidFieldsModule, ONLY: &
    nCF

  ! --- Local Modules ---

  USE MF_KindModule, ONLY: &
    DP

  IMPLICIT NONE
  PRIVATE

  ! --- Geometry Fields ---

  TYPE(amrex_multifab), ALLOCATABLE, PUBLIC :: MF_uGF(:)

  ! --- Conserved Fluid Fields ---

  TYPE(amrex_multifab), ALLOCATABLE, PUBLIC :: MF_uCF(:)

  ! --- Primitive Fluid Fields ---

  TYPE(amrex_multifab), ALLOCATABLE, PUBLIC :: MF_uPF(:)

  ! --- Auxiliary Fluid Fields ---

  TYPE(amrex_multifab), ALLOCATABLE, PUBLIC :: MF_uAF(:)

  ! --- Diagnostic Fluid Fields ---

  TYPE(amrex_multifab), ALLOCATABLE, PUBLIC :: MF_uDF(:)

  TYPE(amrex_fluxregister), ALLOCATABLE, PUBLIC :: FluxRegister(:)

  REAL(DP), ALLOCATABLE, PUBLIC :: MF_OffGridFlux_Euler(:,:)

  PUBLIC :: CreateFields_MF
  PUBLIC :: DestroyFields_MF


CONTAINS


  SUBROUTINE CreateFields_MF

    ALLOCATE( MF_uGF(0:amrex_max_level) )
    ALLOCATE( MF_uCF(0:amrex_max_level) )
    ALLOCATE( MF_uPF(0:amrex_max_level) )
    ALLOCATE( MF_uAF(0:amrex_max_level) )
    ALLOCATE( MF_uDF(0:amrex_max_level) )

    ALLOCATE( FluxRegister(0:amrex_max_level) )

    ALLOCATE( MF_OffGridFlux_Euler(0:amrex_max_level,1:nCF) )

  END SUBROUTINE CreateFields_MF


  SUBROUTINE DestroyFields_MF

    INTEGER :: iLevel

    DEALLOCATE( MF_OffGridFlux_Euler )

    DO iLevel = 0, amrex_max_level

      CALL amrex_fluxregister_destroy( FluxRegister(iLevel) )

      CALL amrex_multifab_destroy( MF_uDF(iLevel) )
      CALL amrex_multifab_destroy( MF_uAF(iLevel) )
      CALL amrex_multifab_destroy( MF_uPF(iLevel) )
      CALL amrex_multifab_destroy( MF_uCF(iLevel) )
      CALL amrex_multifab_destroy( MF_uGF(iLevel) )

    END DO

    DEALLOCATE( FluxRegister )

    DEALLOCATE( MF_uDF )
    DEALLOCATE( MF_uAF )
    DEALLOCATE( MF_uPF )
    DEALLOCATE( MF_uCF )
    DEALLOCATE( MF_uGF )

  END SUBROUTINE DestroyFields_MF


END MODULE MF_FieldsModule
