MODULE MeshModule

  USE KindModule, ONLY: &
    DP, Zero, Half, One, Two
  USE QuadratureModule, ONLY: &
    GetQuadrature
  USE UnitsModule, ONLY: &
    UnitsDisplay

  IMPLICIT NONE
  PRIVATE

  TYPE, PUBLIC :: MeshType
    REAL(DP)                            :: Length
    REAL(DP), DIMENSION(:), ALLOCATABLE :: Center
    REAL(DP), DIMENSION(:), ALLOCATABLE :: Width
    REAL(DP), DIMENSION(:), ALLOCATABLE :: Nodes
  END type MeshType

  TYPE(MeshType), DIMENSION(3), PUBLIC :: MeshX ! Spatial  Mesh
  TYPE(MeshType),               PUBLIC :: MeshE ! Spectral Mesh

  PUBLIC :: CreateMesh
  PUBLIC :: CreateMesh_Custom
  PUBLIC :: CreateMesh_PiecewiseUniform
  PUBLIC :: DestroyMesh
  PUBLIC :: NodeCoordinate

  INTERFACE NodeCoordinate
    MODULE PROCEDURE NodeCoordinate_INT
    MODULE PROCEDURE NodeCoordinate_DBL
  END INTERFACE NodeCoordinate

CONTAINS


  SUBROUTINE CreateMesh( Mesh, N, nN, SW, xL, xR, ZoomOption, iOS_Option )

    TYPE(MeshType)                 :: Mesh
    INTEGER,  INTENT(inout)        :: N
    INTEGER,  INTENT(in)           :: nN, SW
    REAL(DP), INTENT(in)           :: xL, xR
    REAL(DP), INTENT(in), OPTIONAL :: ZoomOption
    INTEGER,  INTENT(in), OPTIONAL :: iOS_Option

    REAL(DP) :: Zoom
    REAL(DP) :: xQ(nN), wQ(nN)
    INTEGER  :: iOS

    INTEGER  :: nGrids, i
    REAL(DP), ALLOCATABLE :: xRef(:), xRef_Flipped(:)

#ifdef THORNADO_USE_AMREX
    LOGICAL :: UseCustomMesh = .FALSE.
#else
    LOGICAL :: UseCustomMesh = .TRUE.
#endif

    iOS = 0
    IF( PRESENT( iOS_Option ) ) &
      iOS = iOS_Option

    IF( PRESENT( ZoomOption ) )THEN
      Zoom = ZoomOption
    ELSE
      Zoom = 1.0_DP
    END IF

    IF( .NOT. UseCustomMesh )THEN

      Mesh % Length = xR - xL

      ALLOCATE( Mesh % Center(1-SW-iOS:N+SW-iOS) )
      ALLOCATE( Mesh % Width (1-SW-iOS:N+SW-iOS) )

      IF( Zoom > 1.0_DP )THEN

        CALL CreateMesh_Geometric &
               ( N, SW, xL, xR, Mesh % Center, Mesh % Width, Zoom )

      ELSE

        CALL CreateMesh_Equidistant &
               ( N, SW, xL, xR, Mesh % Center, Mesh % Width, iOS )

      END IF

      CALL GetQuadrature( nN, xQ, wQ )

      ALLOCATE( Mesh % Nodes(1:nN) )
      Mesh % Nodes = xQ

! Requires deep copy (not supported on all compilers)
#if defined(THORNADO_OMP_OL)
      !$OMP TARGET ENTER DATA &
      !$OMP MAP( to: Mesh % Center, Mesh % Width, Mesh % Nodes )
#elif defined(THORNADO_OACC)
      !$ACC ENTER DATA &
      !$ACC COPYIN( Mesh % Center, Mesh % Width, Mesh % Nodes )
#endif

    ELSE

      IF( N .GT. 1 )THEN

        ! --- Yahil Collapse ---
        nGrids = 10

        ALLOCATE( xRef        (nGrids-1) )
        ALLOCATE( xRef_Flipped(nGrids-1) )

        xRef = [ 5.0000e+4_DP, 2.50000e+4_DP, 1.250000e+4_DP  , &
                 6.2500e+3_DP, 3.12500e+3_DP, 1.562500e+3_DP, &
                 7.8125e+2_DP, 3.90625e+2_DP, 1.953125e+2_DP ]

!        ! --- Adiabatic Collapse ---
!        nGrids = 7
!
!        ALLOCATE( xRef        (nGrids-1) )
!        ALLOCATE( xRef_Flipped(nGrids-1) )
!        xRef = [ 4.0e3_DP, 2.0e3_DP, 1.0e3_DP, 5.0e2_DP, 1.0e2_DP, 5.0e1_DP ]

!        ! --- Standing Accretion Shock (Rs = 60 km)---
!        nGrids = 5
!
!        ALLOCATE( xRef        (nGrids-1) )
!        ALLOCATE( xRef_Flipped(nGrids-1) )
!
!        xRef = [ 6.5e1_DP, 6.0e1_DP, 4.0e1_DP, 3.0e1_DP ]

        xRef = xRef * UnitsDisplay % LengthX1Unit

        DO i = 1, nGrids-1

          xRef_Flipped(i) = xRef(nGrids-i)

        END DO

        CALL CreateMesh_PiecewiseUniform &
               ( Mesh, N, nN, SW, xL, xR, nGrids, xRef_Flipped, &
                 Verbose_Option = .TRUE. )

        DEALLOCATE( xRef_Flipped )
        DEALLOCATE( xRef         )

      ELSE ! N .LE. 1

        Mesh % Length = xR - xL

        ALLOCATE( Mesh % Center(1-SW-iOS:N+SW-iOS) )
        ALLOCATE( Mesh % Width (1-SW-iOS:N+SW-iOS) )

        IF( Zoom > 1.0_DP )THEN

          CALL CreateMesh_Geometric &
                 ( N, SW, xL, xR, Mesh % Center, Mesh % Width, Zoom )

        ELSE

          CALL CreateMesh_Equidistant &
                 ( N, SW, xL, xR, Mesh % Center, Mesh % Width, iOS )

        END IF

        CALL GetQuadrature( nN, xQ, wQ )

        ALLOCATE( Mesh % Nodes(1:nN) )
        Mesh % Nodes = xQ

! Requires deep copy (not supported on all compilers)
#if defined(THORNADO_OMP_OL)
        !$OMP TARGET ENTER DATA &
        !$OMP MAP( to: Mesh % Center, Mesh % Width, Mesh % Nodes )
#elif defined(THORNADO_OACC)
        !$ACC ENTER DATA &
        !$ACC COPYIN( Mesh % Center, Mesh % Width, Mesh % Nodes )
#endif

      END IF ! N .GT. 1

    END IF ! UseCustomMesh

  END SUBROUTINE CreateMesh


  SUBROUTINE CreateMesh_Equidistant( N, SW, xL, xR, Center, Width, iOS )

    INTEGER,                                INTENT(in)    :: N, SW, iOS
    REAL(DP),                               INTENT(in)    :: xL, xR
    REAL(DP), DIMENSION(1-SW-iOS:N+SW-iOS), INTENT(inout) :: Center, Width

    INTEGER :: i

    Width(:) = ( xR - xL ) / REAL( N )

    Center(1-iOS) = xL + 0.5_DP * Width(1-iOS)
    DO i = 2 - iOS, N - iOS
      Center(i) = Center(i-1) + Width(i-1)
    END DO

    DO i = 0 - iOS, 1 - SW - iOS, - 1
      Center(i) = Center(i+1) - Width(i+1)
    END DO

    DO i = N + 1 - iOS, N + SW - iOS
      Center(i) = Center(i-1) + Width(i-1)
    END DO

  END SUBROUTINE CreateMesh_Equidistant


  SUBROUTINE CreateMesh_Geometric( N, SW, xL, xR, Center, Width, Zoom )

    INTEGER,                        INTENT(in)    :: N, SW
    REAL(DP),                       INTENT(in)    :: xL, xR, Zoom
    REAL(DP), DIMENSION(1-SW:N+SW), INTENT(inout) :: Center, Width

    INTEGER :: i

    Width (1) = ( xR - xL ) * ( Zoom - 1.0_DP ) / ( Zoom**N - 1.0_DP )
    Center(1) = xL + 0.5_DP * Width(1)
    DO i = 2, N
      Width (i) = Width(i-1) * Zoom
      Center(i) = xL + SUM( Width(1:i-1) ) + 0.5_DP * Width(i)
    END DO

    DO i = 0, 1 - SW, - 1
      Width (i) = Width(1)
      Center(i) = xL - SUM( Width(i+1:1-SW) ) - 0.5_DP * Width(i)
    END DO

    DO i = N + 1, N + SW
      Width (i) = Width(N)
      Center(i) = xL + SUM( Width(1:i-1) ) + 0.5_DP * Width(i)
    END DO

  END SUBROUTINE CreateMesh_Geometric


  SUBROUTINE CreateMesh_Custom &
    ( Mesh, N, nN, SW, xL, xR, nEQ, dxEQ, Verbose_Option )

    TYPE(MeshType)       :: Mesh
    INTEGER , INTENT(in) :: N, nN, SW
    REAL(DP), INTENT(in) :: xL, xR
    INTEGER , INTENT(in) :: nEQ
    REAL(DP), INTENT(in) :: dxEQ
    LOGICAL , INTENT(in), OPTIONAL :: Verbose_Option

    LOGICAL  :: Verbose
    INTEGER  :: i
    REAL(DP) :: xEQ, Zoom
    REAL(DP) :: x_a, x_b, x_c
    REAL(DP) :: f_a, f_b, f_c
    REAL(DP) :: x_ab
    REAL(DP) :: xQ(nN), wQ(nN)

    IF( PRESENT( Verbose_Option ) )THEN
      Verbose = Verbose_Option
    ELSE
      Verbose = .FALSE.
    END IF

    Mesh % Length = xR - xL

    IF( .NOT. ALLOCATED( Mesh % Center ) ) &
      ALLOCATE( Mesh % Center(1-SW:N+SW) )

    IF( .NOT. ALLOCATED( Mesh % Width  ) ) &
      ALLOCATE( Mesh % Width (1-SW:N+SW) )

    ! --- nEQ First Elements Equidistant ---

    DO i = 1, MIN( nEQ, N )
      Mesh % Width(i) = dxEQ
    END DO

    Mesh % Center(1) = xL + 0.5_DP * Mesh % Width(1)
    DO i = 2, MIN( nEQ, N )
      Mesh % Center(i) = Mesh % Center(i-1) + Mesh % Width(i-1)
    END DO

    ! --- Geometrically Progressing Grid from xEQ to xR ---

    IF( N > nEQ )THEN

      xEQ = xL + SUM( Mesh % Width(1:nEQ) )

      ! --- Find Zoom Factor with Bisection ---

      x_a = One + SQRT( EPSILON( One ) )
      f_a = (x_a**(N-nEQ)-One)*x_a/(x_a-One)-(xR-xEQ)/Mesh%Width(nEQ)

      x_b = x_a
      f_b = f_a
      DO WHILE ( f_b * f_a >= Zero )

        x_b = 1.001_DP * x_b
        f_b = (x_b**(N-nEQ)-One)*x_b/(x_b-One)-(xR-xEQ)/Mesh%Width(nEQ)

      END DO

      x_ab = x_b - x_a
      DO WHILE ( x_ab .GT. EPSILON( One ) )
        x_ab = Half * x_ab
        x_c  = x_a  + x_ab
        f_c  = (x_c**(N-nEQ)-One)*x_c/(x_c-One)-(xR-xEQ)/Mesh%Width(nEQ)
        IF( f_a * f_c < Zero )THEN
          x_b = x_c
          f_b = f_c
        ELSE
          x_a = x_c
          f_a = f_c
        END IF
      END DO

      Zoom = x_a

      DO i = nEQ + 1, N

        Mesh % Width (i) &
          = Zoom * Mesh % Width(i-1)
        Mesh % Center(i) &
          = xL + SUM( Mesh % Width(1:i-1) ) + Half * Mesh % Width(i)

      END DO

    END IF

    DO i = 0, 1 - SW, - 1
      Mesh % Width (i) &
        = Mesh % Width(1)
      Mesh % Center(i) &
        = xL - SUM( Mesh % Width(i+1:1-SW) ) - Half * Mesh % Width(i)
    END DO

    DO i = N + 1, N + SW
      Mesh % Width (i) &
        = Mesh % Width(N)
      Mesh % Center(i) &
        = xL + SUM( Mesh % Width(1:i-1) ) + Half * Mesh % Width(i)
    END DO

    CALL GetQuadrature( nN, xQ, wQ )

    IF( .NOT. ALLOCATED( Mesh % Nodes ) ) &
      ALLOCATE( Mesh % Nodes(1:nN) )

    Mesh % Nodes = xQ

    IF( Verbose )THEN

      WRITE(*,*)
      WRITE(*,'(A5,A)') '', 'CreateMesh_Custom'
      WRITE(*,*)
      WRITE(*,'(A7,A13,ES9.2E2,A3,ES9.2E2)') &
      '', 'MIN/MAX dx = ', &
      MINVAL( Mesh % Width(1:N) ), &
      ' / ', &
      MAXVAL( Mesh % Width(1:N) )
      WRITE(*,*)

    END IF

! Requires deep copy (not supported on all compilers)
#if   defined( THORNADO_OMP_OL )
    !$OMP TARGET UPDATE TO( Mesh % Center, Mesh % Width, Mesh % Nodes )
#elif defined( THORNADO_OACC   )
    !$ACC UPDATE DEVICE   ( Mesh % Center, Mesh % Width, Mesh % Nodes )
#endif

  END SUBROUTINE CreateMesh_Custom


  SUBROUTINE CreateMesh_PiecewiseUniform &
    ( Mesh, N, nN, SW, xL, xR, nGrids, xRef, Verbose_Option )

    TYPE(MeshType)          :: Mesh
    INTEGER , INTENT(inout) :: N
    INTEGER , INTENT(in)    :: nN, nGrids, SW
    REAL(DP), INTENT(in)    :: xL, xR, xRef(nGrids-1)
    LOGICAL , INTENT(in), OPTIONAL :: Verbose_Option

    INTEGER  :: nX(nGrids), iGrid, iX_G, iX
    REAL(DP) :: dX(nGrids), xLL, xRR, xI(nGrids), xQ(nN), wQ(nN)

    LOGICAL  :: Verbose

    CHARACTER(128) :: FMT

    IF( PRESENT( Verbose_Option ) )THEN
      Verbose = Verbose_Option
    ELSE
      Verbose = .FALSE.
    END IF

    xI(1:nGrids-1) = xRef
    xI(nGrids)     = xR

    Mesh % Length = xR - xL

    ! --- Hard-coded to have finest grid be inner-most grid ---

    dX(1) = Mesh % Length / DBLE( N ) / Two**( nGrids - 1 )

    DO iGrid = 2, nGrids

      dX(iGrid) = Two * dX(iGrid-1)

    END DO

    xRR = xL
    nX  = 0

    DO iGrid = 1, nGrids

      DO WHILE( xRR .LT. xI(iGrid) )

        xRR = xRR + dX(iGrid)

        nX(iGrid) = nX(iGrid) + 1

      END DO ! xRR .LT. xI(iGrid)

    END DO ! iGrid = 1, nGrids

    N = SUM( nX )

    IF( .NOT. ALLOCATED( Mesh % Center ) ) &
      ALLOCATE( Mesh % Center(1-SW:N+SW) )

    IF( .NOT. ALLOCATED( Mesh % Width  ) ) &
      ALLOCATE( Mesh % Width (1-SW:N+SW) )

    Mesh % Center(1-SW) = xL - Half * dX(1)
    Mesh % Width (1-SW) = dX(1)

    xLL = xL

    iX_G = 1-SW
    DO iGrid = 1, nGrids

      DO iX = 1, nX(iGrid)

        iX_G = iX_G + 1

        Mesh % Center(iX_G) = xLL + Half * dX(iGrid)
        Mesh % Width (iX_G) = dX(iGrid)

        xLL = xLL + dX(iGrid)

      END DO ! iX = 1, nX(iGrid)

    END DO ! iGrid = 1, nGrids

    Mesh % Center(N+SW) = xR + Half * dX(nGrids)
    Mesh % Width (N+SW) = dX(nGrids)

    CALL GetQuadrature( nN, xQ, wQ )

    IF( .NOT. ALLOCATED( Mesh % Nodes  ) ) &
      ALLOCATE( Mesh % Nodes(1:nN) )

    Mesh % Nodes = xQ

    IF( Verbose )THEN

      WRITE(FMT,'(A,I2.2,A)') '(', nGrids-1, 'ES11.3E3)'
      WRITE(*,*)
      WRITE(*,'(A5,A)') '', 'CreateMesh_PiecewiseUniform'
      WRITE(*,'(A5,A)') '', '---------------------------'
      WRITE(*,*)
      WRITE(*,'(A7,A20,I2.2)') &
      '', 'nGrids = ', nGrids
      WRITE(*,'(A7,A20,I8.8)') &
      '', 'nLeafElements = ', N
      WRITE(*,'(A7,A20,A,A)',ADVANCE='NO') &
      '', 'Interfaces [', TRIM( UnitsDisplay % LengthX1Label ), '] = '
      WRITE(*,TRIM(FMT)) xRef / UnitsDisplay % LengthX1Unit
      WRITE(*,*)

    END IF

! Requires deep copy (not supported on all compilers)
#if   defined( THORNADO_OMP_OL )
    !$OMP TARGET UPDATE TO( Mesh % Center, Mesh % Width, Mesh % Nodes )
#elif defined( THORNADO_OACC   )
    !$ACC UPDATE DEVICE   ( Mesh % Center, Mesh % Width, Mesh % Nodes )
#endif

  END SUBROUTINE CreateMesh_PiecewiseUniform


  SUBROUTINE DestroyMesh( Mesh )

    TYPE(MeshType) :: Mesh

! Requires deep copy (not supported on all compilers)
#if defined(THORNADO_OMP_OL)
    !$OMP TARGET EXIT DATA &
    !$OMP MAP( release: Mesh % Center, Mesh % Width, Mesh % Nodes)
#elif defined(THORNADO_OACC)
    !$ACC EXIT DATA &
    !$ACC DELETE( Mesh % Center, Mesh % Width, Mesh % Nodes)
#endif

    IF (ALLOCATED( Mesh % Center )) THEN
       DEALLOCATE( Mesh % Center )
    END IF

    IF (ALLOCATED( Mesh % Width  )) THEN
       DEALLOCATE( Mesh % Width  )
    END IF

    IF (ALLOCATED( Mesh % Nodes  )) THEN
       DEALLOCATE( Mesh % Nodes  )
    END IF

  END SUBROUTINE DestroyMesh


  REAL(DP) FUNCTION NodeCoordinate_INT( Mesh, iC, iN )
! Requires deep copy (not supported on all compilers)
!#if defined(THORNADO_OMP_OL)
!    !$OMP DECLARE TARGET
!#elif defined(THORNADO_OACC)
!    !$ACC ROUTINE SEQ
!#endif

    TYPE(MeshType), INTENT(in) :: Mesh
    INTEGER,        INTENT(in) :: iC, iN

    NodeCoordinate_INT &
      = Mesh % Center(iC) + Mesh % Width(iC) * Mesh % Nodes(iN)

    RETURN
  END FUNCTION NodeCoordinate_INT


  REAL(DP) FUNCTION NodeCoordinate_DBL( Center, Width, Node )
#if defined(THORNADO_OMP_OL)
    !$OMP DECLARE TARGET
#elif defined(THORNADO_OACC)
    !$ACC ROUTINE SEQ
#endif

    REAL(DP), INTENT(in) :: Center, Width, Node

    NodeCoordinate_DBL = Center + Width * Node

    RETURN
  END FUNCTION NodeCoordinate_DBL


END MODULE MeshModule
