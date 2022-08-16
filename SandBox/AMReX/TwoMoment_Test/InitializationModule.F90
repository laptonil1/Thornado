MODULE InitializationModule

  USE ISO_C_BINDING

  ! --- AMReX Modules ---

  USE amrex_init_module, ONLY: &
    amrex_init
  USE amrex_fort_module, ONLY: &
    amrex_spacedim
  USE amrex_parmparse_module, ONLY: &
    amrex_parmparse, &
    amrex_parmparse_build, &
    amrex_parmparse_destroy
  USE amrex_amrcore_module, ONLY: &
    amrex_amrcore_init, &
    amrex_init_virtual_functions, &
    amrex_init_from_scratch, &
    amrex_ref_ratio, &
    amrex_get_numlevels, &
    amrex_geom
  USE amrex_boxarray_module, ONLY: &
    amrex_boxarray
  USE amrex_distromap_module, ONLY: &
    amrex_distromap
  USE amrex_multifab_module, ONLY: &
    amrex_mfiter, &
    amrex_mfiter_build, &
    amrex_mfiter_destroy, &
    amrex_multifab, &
    amrex_multifab_build, &
    amrex_multifab_destroy
  USE amrex_box_module, ONLY: &
    amrex_box
  USE amrex_parallel_module, ONLY: &
    amrex_parallel_ioprocessor
  USE amrex_fluxregister_module, ONLY: &
    amrex_fluxregister_build, &
    amrex_fluxregister_destroy
  USE amrex_tagbox_module, ONLY: &
    amrex_tagboxarray
  USE amrex_bc_types_module, ONLY: &
    amrex_bc_foextrap, &
    amrex_bc_bogus

  ! --- thornado Modules ---

  USE ProgramHeaderModule, ONLY: &
    nDOFX, &
    nDOFZ, &
    iE_B0, &
    iE_E0, &
    iE_B1, &
    iE_E1, &
    iZ_B0, &
    iZ_E0, &
    iZ_B1, &
    iZ_E1, &
    nNodesX, &
    nNodesE, &
    DescribeProgramHeaderX
  USE PolynomialBasisModule_Lagrange, ONLY: &
    InitializePolynomialBasis_Lagrange
  USE PolynomialBasisModule_Legendre, ONLY: &
    InitializePolynomialBasis_Legendre
  USE PolynomialBasisModuleX_Lagrange, ONLY: &
    InitializePolynomialBasisX_Lagrange
  USE PolynomialBasisModuleX_Legendre, ONLY: &
    InitializePolynomialBasisX_Legendre
  USE PolynomialBasisMappingModule, ONLY: &
    InitializePolynomialBasisMapping
  USE ReferenceElementModuleZ, ONLY: &
    nDOFZ_Z2
  USE ReferenceElementModule, ONLY: &
    InitializeReferenceElement
  USE ReferenceElementModule_Lagrange, ONLY: &
    InitializeReferenceElement_Lagrange
  USE ReferenceElementModuleX, ONLY: &
    InitializeReferenceElementX, &
    nDOFX_X1
  USE ReferenceElementModuleX_Lagrange, ONLY: &
    InitializeReferenceElementX_Lagrange
  USE ReferenceElementModuleE, ONLY: &
    InitializeReferenceElementE
  USE ReferenceElementModuleE_Lagrange, ONLY: &
    InitializeReferenceElementE_Lagrange
  USE UnitsModule, ONLY: &
    DescribeUnitsDisplay
  USE MeshModule, ONLY: &
    MeshX, &
    MeshE, &
    CreateMesh
  USE GeometryFieldsModule, ONLY: &
    nGF, &
    CoordinateSystem, &
    DescribeGeometryFields, &
    SetUnitsGeometryFields
  USE GeometryFieldsModuleE, ONLY: &
    CreateGeometryFieldsE, &
    uGE
  USE GeometryComputationModuleE, ONLY: &
    ComputeGeometryE
  USE FluidFieldsModule, ONLY: &
    nCF, &
    nPF, &
    nAF, &
    nDF, &
    DescribeFluidFields_Primitive, &
    DescribeFluidFields_Conserved, &
    DescribeFluidFields_Auxiliary, &
    DescribeFluidFields_Diagnostic, &
    SetUnitsFluidFields
  USE RadiationFieldsModule, ONLY: &
    nCR, &
    nPR, &
    DescribeRadiationFields_Primitive, &
    DescribeRadiationFields_Conserved, &
    SetUnitsRadiationFields
  USE EquationOfStateModule, ONLY: &
    InitializeEquationOfState
  USE TwoMoment_OpacityModule_Relativistic, ONLY: &
    CreateOpacities, &
    SetOpacities
  USE OpacityModule_Table, ONLY:   &
    InitializeOpacities_TABLE
  USE TwoMoment_SlopeLimiterModule_Relativistic, ONLY: &
    InitializeSlopeLimiter_TwoMoment
  USE TwoMoment_PositivityLimiterModule_Relativistic, ONLY: &
    InitializePositivityLimiter_TwoMoment
  USE TwoMoment_ClosureModule, ONLY: &
    InitializeClosure_TwoMoment
  USE TwoMoment_TimersModule_Relativistic, ONLY: &
    InitializeTimers

  ! --- Local Modules ---

  USE MF_KindModule, ONLY: &
    DP, &
    Zero, &
    One
  USE MF_FieldsModule_Geometry, ONLY: &
    CreateFields_Geometry_MF, &
    MF_uGF
  USE MF_FieldsModule_Euler, ONLY: &
    CreateFields_Euler_MF, &
    MF_uCF, &
    MF_uPF, &
    MF_uAF, &
    MF_uDF, &
    FluxRegister_Euler
  USE MF_FieldsModule_TwoMoment, ONLY: &
    CreateFields_TwoMoment_MF, &
    MF_uCR, &
    MF_uPR, &
    FluxRegister_TwoMoment
  USE MF_Euler_UtilitiesModule, ONLY: &
    ComputeFromConserved_Euler_MF
  USE MF_MeshModule, ONLY: &
    CreateMesh_MF, &
    DestroyMesh_MF
  USE MF_Euler_TallyModule, ONLY: &
    InitializeTally_Euler_MF, &
    ComputeTally_Euler_MF
  USE MF_TwoMoment_TallyModule, ONLY: &
    MF_InitializeTally_TwoMoment, &
    MF_ComputeTally_TwoMoment
  USE MF_TwoMoment_TimeSteppingModule_Relativistic,  ONLY: &
    MF_InitializeField_IMEX_RK
  USE MF_TwoMoment_UtilitiesModule, ONLY: &
    MF_ComputeFromConserved
  USE FillPatchModule, ONLY: &
    FillPatch, &
    FillCoarsePatch
  USE InputParsingModule, ONLY: &
    nX, &
    UseSlopeLimiter, &
    BetaTVD, &
    UsePositivityLimiter, &
    Min_1, &
    Min_2, &
    InitializeParameters, &
    nLevels, &
    nMaxLevels, &
    swX, &
    swE, &
    zoomE, &
    StepNo, &
    iRestart, &
    dt, &
    t_old, &
    t_new, &
    t_wrt, &
    t_chk, &
    dt_wrt, &
    dt_chk, &
    UseTiling, &
    UseFluxCorrection_Euler, &
    UseFluxCorrection_TwoMoment, &
    MaxGridSizeX, &
    BlockingFactor, &
    xL, &
    xR, &
    eL, &
    eR, &
    EquationOfState, &
    Gamma_IDEAL, &
    EosTableName, &
    lo_bc, &
    hi_bc, &
    ProgramName, &
    TagCriteria, &
    nRefinementBuffer, &
    UseAMR, &
    nE, &
    nSpecies, &
    Scheme, &
    OpacityTableName_AbEm, &
    OpacityTableName_Iso, &
    OpacityTableName_NES, &
    OpacityTableName_Pair, &
    DescribeProgramHeader_AMReX
  USE InputOutputModuleAMReX, ONLY: &
    WriteFieldsAMReX_PlotFile, &
    ReadCheckpointFile
  USE AverageDownModule, ONLY: &
    AverageDown

  use inputparsingmodule, only: &
          r0,e0,mu0,kt,d_0,chi,sigma

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: InitializeProgram

CONTAINS


  SUBROUTINE InitializeProgram

    CALL amrex_init()

    CALL amrex_amrcore_init()

    CALL InitializeTimers

    CALL InitializeParameters

    IF( amrex_parallel_ioprocessor() )THEN

      CALL DescribeUnitsDisplay
      CALL DescribeProgramHeaderX

    END IF

    CALL CreateFields_Geometry_MF
    CALL CreateFields_Euler_MF
    CALL CreateFields_TwoMoment_MF

    ALLOCATE( lo_bc(1:amrex_spacedim,1) )
    ALLOCATE( hi_bc(1:amrex_spacedim,1) )

    lo_bc = amrex_bc_bogus
    hi_bc = amrex_bc_bogus

    CALL InitializePolynomialBasisX_Lagrange
    CALL InitializePolynomialBasisX_Legendre

    CALL InitializePolynomialBasis_Lagrange
    CALL InitializePolynomialBasis_Legendre

    CALL CreateMesh_MF( 0, MeshX )

    CALL CreateMesh &
           ( MeshE, nE, nNodesE, swE, eL, eR, zoomOption = zoomE )

    CALL InitializePolynomialBasisMapping &
           ( MeshE % Nodes, &
             MeshX(1) % Nodes, MeshX(2) % Nodes, MeshX(3) % Nodes )

    CALL DestroyMesh_MF( MeshX )

    ! --- Ordering of calls is important here ---
    CALL InitializeReferenceElementX
    CALL InitializeReferenceElementX_Lagrange

    CALL InitializeReferenceElementE
    CALL InitializeReferenceElementE_Lagrange

    CALL InitializeReferenceElement
    CALL InitializeReferenceElement_Lagrange

    CALL SetUnitsGeometryFields

    CALL DescribeFluidFields_Conserved ( amrex_parallel_ioprocessor() )

    CALL DescribeFluidFields_Primitive ( amrex_parallel_ioprocessor() )

    CALL DescribeFluidFields_Auxiliary ( amrex_parallel_ioprocessor() )

    CALL DescribeFluidFields_Diagnostic( amrex_parallel_ioprocessor() )

    CALL SetUnitsFluidFields( TRIM( CoordinateSystem ), &
                              Verbose_Option = amrex_parallel_ioprocessor() )

    CALL DescribeRadiationFields_Conserved( amrex_parallel_ioprocessor() )

    CALL DescribeRadiationFields_Primitive( amrex_parallel_ioprocessor() )

    CALL SetUnitsRadiationFields

    CALL CreateGeometryFieldsE &
           ( nE, swE, Verbose_Option = amrex_parallel_ioprocessor() )

    CALL ComputeGeometryE &
           ( iE_B0, iE_E0, iE_B1, iE_E1, uGE )

    IF( TRIM( EquationOfState ) .EQ. 'TABLE' )THEN

      CALL InitializeEquationOfState &
             ( EquationOfState_Option = EquationOfState, &
               EquationOfStateTableName_Option = EosTableName, &
               Verbose_Option = amrex_parallel_ioprocessor() )

      CALL InitializeOpacities_TABLE &
             ( OpacityTableName_EmAb_Option = OpacityTableName_AbEm, &
               OpacityTableName_Iso_Option  = OpacityTableName_Iso,  &
               OpacityTableName_NES_Option  = OpacityTableName_NES,  &
               OpacityTableName_Pair_Option = OpacityTableName_Pair, &
               EquationOfStateTableName_Option = EosTableName, &
               Verbose_Option = amrex_parallel_ioprocessor())

    ELSE

      CALL InitializeEquationOfState &
               ( EquationOfState_Option = EquationOfState, &
                 Gamma_IDEAL_Option = Gamma_IDEAL, &
                 Verbose_Option = amrex_parallel_ioprocessor() )

      CALL CreateOpacities &
             ( nX, [ 1, 1, 1 ], nE, 1, &
               Verbose_Option = amrex_parallel_ioprocessor() )

      CALL SetOpacities &
             ( iZ_B0, iZ_E0, iZ_B1, iZ_E1, D_0, Chi, Sigma, kT, E0, mu0, R0, &
               Verbose_Option = amrex_parallel_ioprocessor()  )

    END IF

    CALL InitializeClosure_TwoMoment

    CALL InitializePositivityLimiter_TwoMoment &
         ( Min_1_Option = Min_1, &
           Min_2_Option = Min_2, &
           UsePositivityLimiter_Option &
             = UsePositivityLimiter, &
           Verbose_Option = amrex_parallel_ioprocessor() )

    CALL InitializeSlopeLimiter_TwoMoment &
           ( BetaTVD_Option &
               = BetaTVD, &
             UseSlopeLimiter_Option &
               = UseSlopeLimiter, &
             Verbose_Option &
               = amrex_parallel_ioprocessor()  )

    CALL InitializeTally_Euler_MF

    CALL MF_InitializeTally_TwoMoment

    CALL amrex_init_virtual_functions &
           ( MakeNewLevelFromScratch, &
             MakeNewLevelFromCoarse, &
             RemakeLevel, &
             ClearLevel, &
             ErrorEstimate )

    ALLOCATE( StepNo(0:nMaxLevels-1) )
    ALLOCATE( dt    (0:nMaxLevels-1) )
    ALLOCATE( t_old (0:nMaxLevels-1) )
    ALLOCATE( t_new (0:nMaxLevels-1) )

    StepNo = 0
    dt     = 0.0_DP
    t_new  = 0.0_DP

    IF( iRestart .LT. 0 )THEN

      CALL amrex_init_from_scratch( 0.0_DP )
      nLevels = amrex_get_numlevels()

#ifdef GRAVITY_SOLVER_POSEIDON_CFA

      CALL CreateMesh_MF( 0, MeshX )

      CALL InitializeGravitySolver_XCFC_Poseidon_MF

      CALL DestroyMesh_MF( MeshX )

      CALL ComputeFromConserved_Euler_MF &
             ( MF_uGF, MF_uCF, MF_uPF, MF_uAF )

      CALL InitializeMetric_MF( MF_uGF, MF_uCF, MF_uPF, MF_uAF )

#endif

    ELSE

      CALL amrex_init_from_scratch( 0.0_DP )
      ! nLevels read from checkpoint file

      CALL ReadCheckpointFile &
             ( ReadFields_uCF_Option = .TRUE., &
               ReadFields_uCR_Option = .TRUE. )

#ifdef GRAVITY_SOLVER_POSEIDON_CFA

      CALL CreateMesh_MF( 0, MeshX )

      CALL InitializeGravitySolver_XCFC_Poseidon_MF

      CALL DestroyMesh_MF( MeshX )

      CALL ComputeFromConserved_Euler_MF &
             ( MF_uGF, MF_uCF, MF_uPF, MF_uAF )

      CALL InitializeMetric_MF( MF_uGF, MF_uCF, MF_uPF, MF_uAF )

#endif

    END IF

    CALL AverageDown( MF_uGF, MF_uGF )
    CALL AverageDown( MF_uGF, MF_uCF )

    t_old = t_new
    t_chk = t_new(0) + dt_chk
    t_wrt = t_new(0) + dt_wrt

    CALL MF_InitializeField_IMEX_RK &
           ( Scheme, MF_uGF % BA, MF_uGF % DM, &
             Verbose_Option = amrex_parallel_ioprocessor() )

    CALL DescribeProgramHeader_AMReX

    CALL ComputeFromConserved_Euler_MF &
           ( MF_uGF, MF_uCF, MF_uPF, MF_uAF )

    CALL MF_ComputeFromConserved &
           ( MF_uGF, MF_uCF, MF_uCR, MF_uPR )

    CALL WriteFieldsAMReX_PlotFile &
           ( t_new(0), StepNo, MF_uGF, &
             MF_uCR_Option = MF_uCR, &
             MF_uPR_Option = MF_uPR )

    CALL ComputeTally_Euler_MF &
           ( t_new, MF_uGF, MF_uCF, &
             SetInitialValues_Option = .TRUE., Verbose_Option = .TRUE. )

    CALL MF_ComputeTally_TwoMoment &
           ( amrex_geom(0), MF_uGF, MF_uCF, MF_uCR, &
             t_new(0), Verbose_Option = .FALSE. )

  END SUBROUTINE InitializeProgram


  SUBROUTINE MakeNewLevelFromScratch( iLevel, Time, pBA, pDM ) BIND(c)

    USE MF_GeometryModule, ONLY: &
      ComputeGeometryX_MF

    USE MF_InitializationModule, ONLY: &
      InitializeFields_MF

    INTEGER,     INTENT(in), VALUE :: iLevel
    REAL(DP),    INTENT(in), VALUE :: Time
    TYPE(c_ptr), INTENT(in), VALUE :: pBA, pDM

    TYPE(amrex_boxarray)  :: BA
    TYPE(amrex_distromap) :: DM

    BA = pBA
    DM = pDM

    t_new(iLevel) = Time
    t_old(iLevel) = Time - 1.0e200_DP

    CALL ClearLevel( iLevel )

    CALL amrex_multifab_build( MF_uGF(iLevel), BA, DM, nDOFX * nGF, swX )
    CALL MF_uGF(iLevel) % SetVal( Zero )

    CALL amrex_multifab_build( MF_uCF(iLevel), BA, DM, nDOFX * nCF, swX )
    CALL MF_uCF(iLevel) % SetVal( Zero )

    CALL amrex_multifab_build( MF_uPF(iLevel), BA, DM, nDOFX * nPF, swX )
    CALL MF_uPF(iLevel) % SetVal( Zero )

    CALL amrex_multifab_build( MF_uAF(iLevel), BA, DM, nDOFX * nAF, swX )
    CALL MF_uAF(iLevel) % SetVal( Zero )

    CALL amrex_multifab_build( MF_uDF(iLevel), BA, DM, nDOFX * nDF, swX )
    CALL MF_uDF(iLevel) % SetVal( Zero )

    CALL amrex_multifab_build &
           ( MF_uCR(iLevel), BA, DM, &
             nDOFZ * nCR * ( iZ_E0( 1 ) - iZ_B0( 1 ) + 1 ) * nSpecies, swX )
    CALL MF_uCR(iLevel) % SetVal( Zero )

    CALL amrex_multifab_build &
           ( MF_uPR(iLevel), BA, DM, &
             nDOFZ * nPR * ( iZ_E0( 1 ) - iZ_B0( 1 ) + 1 ) * nSpecies, swX )
    CALL MF_uPR(iLevel) % SetVal( Zero )

    ! Assume nDOFZ_Z3 = nDOFZ_Z4 = nDOFZ_Z2
    IF( iLevel .GT. 0 .AND. UseFluxCorrection_TwoMoment ) &
      CALL amrex_fluxregister_build &
             ( FluxRegister_TwoMoment(iLevel), BA, DM, &
               amrex_ref_ratio(iLevel-1), iLevel, nDOFZ_Z2*nCR*nE*nSpecies )

    CALL CreateMesh_MF( iLevel, MeshX )

    CALL ComputeGeometryX_MF( MF_uGF(iLevel) )

    CALL InitializeFields_MF &
           ( iLevel, MF_uGF(iLevel), MF_uCR(iLevel), MF_uCF(iLevel) )

    CALL FillPatch( iLevel, t_new(iLevel), MF_uGF, MF_uGF )
    CALL FillPatch( iLevel, t_new(iLevel), MF_uGF, MF_uCF )
    CALL FillPatch( iLevel, t_new(iLevel), MF_uGF, MF_uCR )

    CALL DestroyMesh_MF( MeshX )

  END SUBROUTINE MakeNewLevelFromScratch


  SUBROUTINE MakeNewLevelFromCoarse( iLevel, Time, pBA, pDM ) BIND(c)

    INTEGER,     INTENT(in), VALUE :: iLevel
    REAL(DP),    INTENT(in), VALUE :: Time
    TYPE(c_ptr), INTENT(in), VALUE :: pBA, pDM

    TYPE(amrex_boxarray)  :: BA
    TYPE(amrex_distromap) :: DM

    BA = pBA
    DM = pDM

    CALL ClearLevel( iLevel )

    t_new( iLevel ) = Time
    t_old( iLevel ) = Time - 1.0e200_DP

    CALL amrex_multifab_build( MF_uGF(iLevel), BA, DM, nDOFX * nGF, swX )
    CALL amrex_multifab_build( MF_uCF(iLevel), BA, DM, nDOFX * nCF, swX )
    CALL amrex_multifab_build( MF_uPF(iLevel), BA, DM, nDOFX * nPF, swX )
    CALL amrex_multifab_build( MF_uAF(iLevel), BA, DM, nDOFX * nAF, swX )
    CALL amrex_multifab_build( MF_uDF(iLevel), BA, DM, nDOFX * nDF, swX )
    CALL amrex_multifab_build &
           ( MF_uCR(iLevel), BA, DM, nDOFZ * nCR * nE * nSpecies, swX )
    CALL amrex_multifab_build &
           ( MF_uPR(iLevel), BA, DM, nDOFZ * nPR * nE * nSpecies, swX )

    IF( iLevel .GT. 0 .AND. UseFluxCorrection_Euler ) &
      CALL amrex_fluxregister_build &
             ( FluxRegister_TwoMoment(iLevel), BA, DM, &
               amrex_ref_ratio(iLevel-1), &
               iLevel, nDOFZ_Z2 * nCR * nE * nSpecies )

    CALL FillCoarsePatch( iLevel, Time, MF_uGF, MF_uGF )
    CALL FillCoarsePatch( iLevel, Time, MF_uGF, MF_uCF )
    CALL FillCoarsePatch( iLevel, Time, MF_uGF, MF_uDF )
    CALL FillCoarsePatch( iLevel, Time, MF_uGF, MF_uCR )

  END SUBROUTINE MakeNewLevelFromCoarse


  SUBROUTINE ClearLevel( iLevel ) BIND(c)

    INTEGER, INTENT(in), VALUE :: iLevel

    CALL amrex_multifab_destroy( MF_uPR(iLevel) )
    CALL amrex_multifab_destroy( MF_uCR(iLevel) )
    CALL amrex_multifab_destroy( MF_uDF(iLevel) )
    CALL amrex_multifab_destroy( MF_uAF(iLevel) )
    CALL amrex_multifab_destroy( MF_uPF(iLevel) )
    CALL amrex_multifab_destroy( MF_uCF(iLevel) )
    CALL amrex_multifab_destroy( MF_uGF(iLevel) )

    IF( iLevel .GT. 0 .AND. UseFluxCorrection_TwoMoment ) &
      CALL amrex_fluxregister_destroy( FluxRegister_TwoMoment(iLevel) )

  END SUBROUTINE ClearLevel


  SUBROUTINE RemakeLevel( iLevel, Time, pBA, pDM ) BIND(c)

    INTEGER,     INTENT(in), VALUE :: iLevel
    REAL(DP),    INTENT(in), VALUE :: Time
    TYPE(c_ptr), INTENT(in), VALUE :: pBA, pDM

    TYPE(amrex_boxarray)  :: BA
    TYPE(amrex_distromap) :: DM
    TYPE(amrex_multifab)  :: MF_uGF_tmp, MF_uCF_tmp, MF_uPF_tmp, &
                             MF_uAF_tmp, MF_uDF_tmp, MF_uCR_tmp, MF_uPR_tmp

    BA = pBA
    DM = pDM

    CALL amrex_multifab_build( MF_uGF_tmp, BA, DM, nDOFX * nGF, swX )
    CALL amrex_multifab_build( MF_uCF_tmp, BA, DM, nDOFX * nCF, swX )
    CALL amrex_multifab_build( MF_uPF_tmp, BA, DM, nDOFX * nPF, swX )
    CALL amrex_multifab_build( MF_uAF_tmp, BA, DM, nDOFX * nAF, swX )
    CALL amrex_multifab_build( MF_uDF_tmp, BA, DM, nDOFX * nDF, swX )
    CALL amrex_multifab_build &
           ( MF_uCR_tmp, BA, DM, nDOFZ * nCR * nE * nSpecies, swX )
    CALL amrex_multifab_build &
           ( MF_uPR_tmp, BA, DM, nDOFZ * nPR * nE * nSpecies, swX )

    CALL FillPatch( iLevel, Time, MF_uGF, MF_uGF, MF_uGF_tmp )
    CALL FillPatch( iLevel, Time, MF_uGF, MF_uCF, MF_uCF_tmp )
    CALL FillPatch( iLevel, Time, MF_uGF, MF_uDF, MF_uDF_tmp )
    CALL FillPatch( iLevel, Time, MF_uGF, MF_uCR, MF_uCR_tmp )

    CALL ClearLevel( iLevel )

    CALL amrex_multifab_build( MF_uGF(iLevel), BA, DM, nDOFX * nGF, swX )
    CALL amrex_multifab_build( MF_uCF(iLevel), BA, DM, nDOFX * nCF, swX )
    CALL amrex_multifab_build( MF_uPF(iLevel), BA, DM, nDOFX * nPF, swX )
    CALL amrex_multifab_build( MF_uAF(iLevel), BA, DM, nDOFX * nAF, swX )
    CALL amrex_multifab_build( MF_uDF(iLevel), BA, DM, nDOFX * nDF, swX )
    CALL amrex_multifab_build &
           ( MF_uCR(iLevel), BA, DM, nDOFZ * nCR * nE * nSpecies, swX )
    CALL amrex_multifab_build &
           ( MF_uPR(iLevel), BA, DM, nDOFZ * nPR * nE * nSpecies, swX )

    IF( iLevel .GT. 0 .AND. UseFluxCorrection_TwoMoment ) &
      CALL amrex_fluxregister_build &
             ( FluxRegister_TwoMoment(iLevel), BA, DM, &
               amrex_ref_ratio(iLevel-1), &
               iLevel, nDOFZ_Z2 * nCR * nE * nSpecies )

    CALL MF_uGF(iLevel) % COPY( MF_uGF_tmp, 1, 1, nDOFX * nGF, swX )
    CALL MF_uCF(iLevel) % COPY( MF_uCF_tmp, 1, 1, nDOFX * nCF, swX )
    CALL MF_uDF(iLevel) % COPY( MF_uDF_tmp, 1, 1, nDOFX * nDF, swX )
    CALL MF_uCF(iLevel) % COPY &
           ( MF_uCR_tmp, 1, 1, nDOFZ * nCR * nE * nSpecies, swX )

    CALL amrex_multifab_destroy( MF_uPR_tmp )
    CALL amrex_multifab_destroy( MF_uCR_tmp )
    CALL amrex_multifab_destroy( MF_uDF_tmp )
    CALL amrex_multifab_destroy( MF_uAF_tmp )
    CALL amrex_multifab_destroy( MF_uPF_tmp )
    CALL amrex_multifab_destroy( MF_uCF_tmp )
    CALL amrex_multifab_destroy( MF_uGF_tmp )

  END SUBROUTINE RemakeLevel


  SUBROUTINE ErrorEstimate( iLevel, cp, Time, SetTag, ClearTag ) BIND(c)

!!$    USE TaggingModule, ONLY: &
!!$      TagElements_Advection1D, &
!!$      TagElements_RiemannProblem1D, &
!!$      TagElements_Advection2D, &
!!$      TagElements_KelvinHelmholtz2D, &
!!$      TagElements_Advection3D, &
!!$      TagElements_uCF
!!$
    INTEGER,                INTENT(in), VALUE :: iLevel
    TYPE(c_ptr),            INTENT(in), VALUE :: cp
    REAL(DP),               INTENT(in), VALUE :: Time
    CHARACTER(KIND=c_char), INTENT(in), VALUE :: SetTag, ClearTag
!!$
!!$    TYPE(amrex_parmparse)   :: PP
!!$    TYPE(amrex_tagboxarray) :: Tag
!!$    TYPE(amrex_mfiter)      :: MFI
!!$    TYPE(amrex_box)         :: BX
!!$    REAL(DP),               CONTIGUOUS, POINTER :: uCF(:,:,:,:)
!!$    CHARACTER(KIND=c_char), CONTIGUOUS, POINTER :: TagArr(:,:,:,:)
!!$
!!$    IF( .NOT. ALLOCATED( TagCriteria ) )THEN
!!$
!!$       CALL amrex_parmparse_build( PP, "amr" )
!!$
!!$         CALL PP % getarr( "TagCriteria", TagCriteria )
!!$
!!$       CALL amrex_parmparse_destroy( PP )
!!$
!!$    END IF
!!$
!!$    Tag = cp
!!$
!!$    CALL CreateMesh_MF( iLevel, MeshX )
!!$
!!$    !$OMP PARALLEL PRIVATE( MFI, BX, uCF, TagArr )
!!$    CALL amrex_mfiter_build( MFI, MF_uCF( iLevel ), Tiling = UseTiling )
!!$
!!$    DO WHILE( MFI % next() )
!!$
!!$      BX = MFI % TileBox()
!!$
!!$      uCF    => MF_uCF( iLevel ) % DataPtr( MFI )
!!$      TagArr => Tag              % DataPtr( MFI )
!!$
!!$      ! TagCriteria(iLevel+1) because iLevel starts at 0 but
!!$      ! TagCriteria starts with 1
!!$
!!$      SELECT CASE( TRIM( ProgramName ) )
!!$
!!$        CASE( 'Advection1D' )
!!$
!!$          CALL TagElements_Advection1D &
!!$                 ( iLevel, BX % lo, BX % hi, LBOUND( uCF ), UBOUND( uCF ), &
!!$                   uCF, TagCriteria(iLevel+1), SetTag, ClearTag, &
!!$                   LBOUND( TagArr ), UBOUND( TagArr ), TagArr )
!!$
!!$        CASE( 'RiemannProblem1D' )
!!$
!!$          CALL TagElements_RiemannProblem1D &
!!$                 ( iLevel, BX % lo, BX % hi, LBOUND( uCF ), UBOUND( uCF ), &
!!$                   uCF, TagCriteria(iLevel+1), SetTag, ClearTag, &
!!$                   LBOUND( TagArr ), UBOUND( TagArr ), TagArr )
!!$
!!$        CASE( 'Advection2D' )
!!$
!!$          CALL TagElements_Advection2D &
!!$                 ( iLevel, BX % lo, BX % hi, LBOUND( uCF ), UBOUND( uCF ), &
!!$                   uCF, TagCriteria(iLevel+1), SetTag, ClearTag, &
!!$                   LBOUND( TagArr ), UBOUND( TagArr ), TagArr )
!!$
!!$        CASE( 'KelvinHelmholtz2D' )
!!$
!!$          CALL TagElements_KelvinHelmholtz2D &
!!$                 ( iLevel, BX % lo, BX % hi, LBOUND( uCF ), UBOUND( uCF ), &
!!$                   uCF, TagCriteria(iLevel+1), SetTag, ClearTag, &
!!$                   LBOUND( TagArr ), UBOUND( TagArr ), TagArr )
!!$
!!$        CASE( 'Advection3D' )
!!$
!!$          CALL TagElements_Advection3D &
!!$                 ( iLevel, BX % lo, BX % hi, LBOUND( uCF ), UBOUND( uCF ), &
!!$                   uCF, TagCriteria(iLevel+1), SetTag, ClearTag, &
!!$                   LBOUND( TagArr ), UBOUND( TagArr ), TagArr )
!!$
!!$        CASE DEFAULT
!!$
!!$          CALL TagElements_uCF &
!!$                 ( iLevel, BX % lo, BX % hi, LBOUND( uCF ), UBOUND( uCF ), &
!!$                   uCF, TagCriteria(iLevel+1), SetTag, ClearTag, &
!!$                   LBOUND( TagArr ), UBOUND( TagArr ), TagArr )
!!$
!!$      END SELECT
!!$
!!$    END DO
!!$
!!$    CALL amrex_mfiter_destroy( MFI )
!!$    !$OMP END PARALLEL
!!$
!!$    CALL DestroyMesh_MF( MeshX )

  END SUBROUTINE ErrorEstimate


END MODULE InitializationModule