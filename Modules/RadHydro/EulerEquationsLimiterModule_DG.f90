MODULE EulerEquationsLimiterModule_DG

  USE KindModule, ONLY: &
    DP
  USE ProgramHeaderModule, ONLY: &
    nX, nNodesX, nDOFX
  USE UtilitiesModule, ONLY: &
    NodeNumberX, &
    MinModB, &
    GetRoots_Quadratic
  USE PolynomialBasisModule_Lagrange, ONLY: &
    L_X1, L_X2, L_X3
  USE PolynomialBasisModule_Legendre, ONLY: &
    evalPX
  USE PolynomialBasisMappingModule, ONLY: &
    MapNodalToModal_Fluid, &
    MapModalToNodal_Fluid
  USE MeshModule, ONLY: &
    MeshX
  USE FluidFieldsModule, ONLY: &
    uCF, iCF_D, iCF_S1, iCF_S2, iCF_S3, iCF_E, nCF, &
    uPF, iPF_D, iPF_V1, iPF_V2, iPF_V3, iPF_E, nPF, &
    iAF_P, iAF_Cs, nAF
  USE EquationOfStateModule, ONLY: &
    Auxiliary_Fluid
  USE EulerEquationsUtilitiesModule, ONLY: &
    Primitive, &
    ComputeEigenvectors_L, &
    ComputeEigenvectors_R

  IMPLICIT NONE
  PRIVATE

  LOGICAL,  PARAMETER                   :: Debug = .FALSE.
  LOGICAL,  PARAMETER                   :: Componentwise = .FALSE.
  LOGICAL                               :: ApplyPositivityLimiter
  INTEGER                               :: nPoints
  REAL(DP)                              :: BetaTVB
  REAL(DP)                              :: BetaTVD
  REAL(DP), PARAMETER                   :: Tol_TVD = 1.0d-2
  REAL(DP), PARAMETER                   :: Tol_D = 1.0d-12
  REAL(DP), PARAMETER                   :: Tol_E = 1.0d-12
  REAL(DP), DIMENSION(:),   ALLOCATABLE :: Points_X1
  REAL(DP), DIMENSION(:),   ALLOCATABLE :: Points_X2
  REAL(DP), DIMENSION(:),   ALLOCATABLE :: Points_X3
  REAL(DP), DIMENSION(:,:), ALLOCATABLE :: uCF_P, uPF_P, uAF_P
  REAL(DP), DIMENSION(:,:), ALLOCATABLE :: uCF_M
  REAL(DP), DIMENSION(:,:), ALLOCATABLE :: Lagrange

  PUBLIC :: InitializeLimiters_Euler_DG
  PUBLIC :: ApplySlopeLimiter_Euler_DG
  PUBLIC :: ApplyPositivityLimiter_Euler_DG

CONTAINS


  SUBROUTINE InitializeLimiters_Euler_DG &
               ( BetaTVB_Option, BetaTVD_Option, ApplyPositivityLimiter_Option )

    REAL(DP), INTENT(in), OPTIONAL :: BetaTVB_Option
    REAL(DP), INTENT(in), OPTIONAL :: BetaTVD_Option
    LOGICAL,  INTENT(in), OPTIONAL :: ApplyPositivityLimiter_Option

    INTEGER :: iNodeX1, iNodeX2, iNodeX3, iPoint, iNodeX
    REAL(DP), DIMENSION(:), ALLOCATABLE :: NodesX1

    ! --- Limiter Parameters ---

    BetaTVB = 50.0_DP
    IF( PRESENT( BetaTVB_Option ) ) &
      BetaTVB = BetaTVB_Option

    BetaTVD = 2.0d0
    IF( PRESENT( BetaTVD_Option ) ) &
      BetaTVD = BetaTVD_Option

    ApplyPositivityLimiter = .TRUE.
    IF( PRESENT( ApplyPositivityLimiter_Option ) ) &
      ApplyPositivityLimiter = ApplyPositivityLimiter_Option

    WRITE(*,*)
    WRITE(*,'(A5,A)') '', 'InitializeLimiters_Euler_DG'
    WRITE(*,*)
    WRITE(*,'(A7,A10,ES8.2E2)') '', 'BetaTVB = ', BetaTVB
    WRITE(*,'(A7,A10,ES8.2E2)') '', 'BetaTVD = ', BetaTVD
    WRITE(*,'(A7,A25,L1)') &
      '', 'ApplyPositivityLimiter = ', ApplyPositivityLimiter
    WRITE(*,*)

    ! --- ---

    ALLOCATE( NodesX1(nNodesX(1)+2) )

    NodesX1 = [ - 0.5_DP, MeshX(1) % Nodes, + 0.5_DP ]

    nPoints = ( nNodesX(1) + 2 ) * nNodesX(2) * nNodesX(3)

    IF( nNodesX(2) > 1 ) &
      nPoints = nPoints + 2 * nNodesX(1) * nNodesX(3)

    IF( nNodesX(3) > 1 ) &
      nPoints = nPoints + 2 * nNodesX(1) * nNodesX(2)

    ALLOCATE( uCF_P(nPoints,nCF), uPF_P(nPoints,nPF), uAF_P(nPoints,nAF) )

    ALLOCATE( uCF_M(nDOFX,nCF) )

    ! --- Coordinates of Points Where Positivity is Required:

    ALLOCATE( Points_X1(nPoints), Points_X2(nPoints), Points_X3(nPoints) )

    iPoint = 0

    DO iNodeX3 = 1, nNodesX(3)
      DO iNodeX2 = 1, nNodesX(2)
        DO iNodeX1 = 1, SIZE( NodesX1 )

          iPoint = iPoint + 1

          Points_X1(iPoint) = NodesX1(iNodeX1)
          Points_X2(iPoint) = MeshX(2) % Nodes(iNodeX2)
          Points_X3(iPoint) = MeshX(3) % Nodes(iNodeX3)

        END DO
      END DO
    END DO

    IF( nNodesX(2) > 1 )THEN

      DO iNodeX3 = 1, nNodesX(3)
        DO iNodeX1 = 1, nNodesX(1)

          iPoint = iPoint + 1

          Points_X1(iPoint) = MeshX(1) % Nodes(iNodeX1)
          Points_X2(iPoint) = - 0.5_DP
          Points_X3(iPoint) = MeshX(3) % Nodes(iNodeX3)

        END DO
      END DO

      DO iNodeX3 = 1, nNodesX(3)
        DO iNodeX1 = 1, nNodesX(1)

          iPoint = iPoint + 1

          Points_X1(iPoint) = MeshX(1) % Nodes(iNodeX1)
          Points_X2(iPoint) = + 0.5_DP
          Points_X3(iPoint) = MeshX(3) % Nodes(iNodeX3)

        END DO
      END DO

    END IF

    IF( nNodesX(3) > 1 )THEN

      DO iNodeX2 = 1, nNodesX(2)
        DO iNodeX1 = 1, nNodesX(1)

          iPoint = iPoint + 1

          Points_X1(iPoint) = MeshX(1) % Nodes(iNodeX1)
          Points_X2(iPoint) = MeshX(2) % Nodes(iNodeX2)
          Points_X3(iPoint) = - 0.5_DP

        END DO
      END DO

      DO iNodeX2 = 1, nNodesX(2)
        DO iNodeX1 = 1, nNodesX(1)

          iPoint = iPoint + 1

          Points_X1(iPoint) = MeshX(1) % Nodes(iNodeX1)
          Points_X2(iPoint) = MeshX(1) % Nodes(iNodeX1)
          Points_X3(iPoint) = + 0.5_DP

        END DO
      END DO

    END IF

    DEALLOCATE( NodesX1 )

    ALLOCATE( Lagrange(nDOFX,nPoints) )

    DO iNodeX3 = 1, nNodesX(3)
      DO iNodeX2 = 1, nNodesX(2)
        DO iNodeX1 = 1, nNodesX(1)

          iNodeX = NodeNumberX( iNodeX1, iNodeX2, iNodeX3 )

          DO iPoint = 1, nPoints

            Lagrange(iNodeX,iPoint) &
              = L_X1(iNodeX1) % P( Points_X1(iPoint) ) &
                  * L_X2(iNodeX2) % P( Points_X2(iPoint) ) &
                      * L_X3(iNodeX3) % P( Points_X3(iPoint) )

          END DO

        END DO
      END DO
    END DO

  END SUBROUTINE InitializeLimiters_Euler_DG


  SUBROUTINE ApplySlopeLimiter_Euler_DG

    LOGICAL :: LimitPolynomial
    INTEGER :: iX1, iX2, iX3, iCF, i
    REAL(DP), DIMENSION(nCF) :: uCF_A_P, uCF_A_N
    REAL(DP), DIMENSION(nPF) :: uPF_A
    REAL(DP), DIMENSION(nAF) :: uAF_A
    REAL(DP), DIMENSION(nCF,nCF) :: L1, R1
    REAL(DP), DIMENSION(nDOFX,nCF) :: uCF_M_P, uCF_M_N
    REAL(DP), DIMENSION(:,:,:,:), ALLOCATABLE :: uCF_A, uCF_X1, uCF_X1_T

    IF( nDOFX == 1 ) RETURN

    IF( Debug )THEN
      WRITE(*,*)
      WRITE(*,'(A6,A)') '', 'ApplySlopeLimiter_Euler_DG'
      WRITE(*,*)
    END IF

    ALLOCATE &
      ( uCF_A(1:nCF,1:nX(1),1:nX(2),1:nX(3)), &
        uCF_X1  (1:nX(1),1:nX(2),1:nX(3),1:nCF), &
        uCF_X1_T(1:nX(1),1:nX(2),1:nX(3),1:nCF) )

    ASSOCIATE( dX1 => MeshX(1) % Width(1:nX(1)) )

    DO iX3 = 1, nX(3)
      DO iX2 = 1, nX(2)
        DO iX1 = 1, nX(1)

          ! --- Limiting Using Modal Representation ---

          DO iCF = 1, nCF

            CALL MapNodalToModal_Fluid &
                   ( uCF(:,iX1-1,iX2,iX3,iCF), uCF_M_P(:,iCF) )
            CALL MapNodalToModal_Fluid &
                   ( uCF(:,iX1,  iX2,iX3,iCF), uCF_M  (:,iCF) )
            CALL MapNodalToModal_Fluid &
                   ( uCF(:,iX1+1,iX2,iX3,iCF), uCF_M_N(:,iCF) )

          END DO

          ! --- Cell-Averaged Quantities ---

          uCF_A(1:nCF,iX1,iX2,iX3) = uCF_M  (1,1:nCF)
          uCF_A_P(1:nCF)           = uCF_M_P(1,1:nCF)
          uCF_A_N(1:nCF)           = uCF_M_N(1,1:nCF)

          uPF_A(1:nPF) = Primitive      ( uCF_A(1:nCF,iX1,iX2,iX3) )
          uAF_A(1:nAF) = Auxiliary_Fluid( uPF_A(1:nPF) )

          ! --- Slope From Modal Representation ---

          CALL ComputeEigenvectors_L &
                 ( uPF_A(iPF_V1), uPF_A(iPF_V2), uPF_A(iPF_V3), &
                   uPF_A(iPF_E ), uAF_A(iAF_P ), uAF_A(iAF_Cs), &
                   L1, Componentwise )

          uCF_X1(iX1,iX2,iX3,1:nCF) &
            = MATMUL( L1, uCF_M(2,1:nCF) ) ! X1-Dimension

          uCF_X1_T(iX1,iX2,iX2,1:nCF) &
            = MinModB &
                ( uCF_X1(iX1,iX2,iX3,1:nCF), &
                  BetaTVD * MATMUL( L1,(uCF_A(1:nCF,iX1,iX2,iX3)-uCF_A_P) ), &
                  BetaTVD * MATMUL( L1,(uCF_A_N-uCF_A(1:nCF,iX1,iX2,iX3)) ), &
                  dX1(iX1), BetaTVB )

!!$          IF( Debug )THEN
!!$
!!$            PRINT*
!!$            PRINT*, ""
!!$            PRINT*
!!$
!!$          END IF

        END DO
      END DO
    END DO

    END ASSOCIATE ! dX1, etc. 

    DO iX3 = 1, nX(3)
      DO iX2 = 1, nX(2)
        DO iX1 = 1, nX(1)

          LimitPolynomial = .FALSE.
          LimitPolynomial &
            = ANY( ABS( uCF_X1(iX1,iX2,iX3,1:nCF) &
                        - uCF_X1_T(iX1,iX2,iX3,1:nCF) ) &
                   > Tol_TVD * ABS( uCF_A(1:nCF,iX1,iX2,iX3) ) )

          IF( LimitPolynomial )THEN

            IF( Debug )THEN

              PRINT*
              PRINT*, "iX1, iX2, iX3 = ", iX1, iX2, iX3
              PRINT*, "  uCF_X1    = ", uCF_X1(iX1,iX2,iX3,1:nCF)
              PRINT*, "  uCF_X1_T  = ", uCF_X1_T(iX1,iX2,iX3,1:nCF)
              PRINT*, "  Tol*uCF_A = ", Tol_TVD * uCF_A(1:nCF,iX1,iX2,iX3)
              PRINT*

            END IF

            DO iCF = 1, nCF

              CALL MapNodalToModal_Fluid &
                     ( uCF(:,iX1,iX2,iX3,iCF), uCF_M(:,iCF) )

            END DO

            ! --- Cell-Averaged Quantities ---

            uPF_A(1:nPF) = Primitive      ( uCF_A(1:nCF,iX1,iX2,iX3) )
            uAF_A(1:nAF) = Auxiliary_Fluid( uPF_A(1:nPF) )

            ! --- Back to Conserved Variables ---

            CALL ComputeEigenvectors_R &
                   ( uPF_A(iPF_V1), uPF_A(iPF_V2), uPF_A(iPF_V3), &
                     uPF_A(iPF_E ), uAF_A(iAF_P ), uAF_A(iAF_Cs), &
                     R1, Componentwise )

            uCF_M(:,1:nCF) = 0.0_DP
            uCF_M(1,1:nCF) & ! -- Cell-Average
              = uCF_A(1:nCF,iX1,iX2,iX3)
            uCF_M(2,1:nCF) & ! -- Slope X1-Direction
              = MATMUL( R1, uCF_X1_T(iX1,iX2,iX3,1:nCF) )

            ! --- Back to Nodal Representation ---

            DO iCF = 1, nCF

              CALL MapModalToNodal_Fluid &
                     ( uCF(:,iX1,iX2,iX3,iCF), uCF_M(:,iCF) )

            END DO

          END IF

        END DO
      END DO
    END DO

    DEALLOCATE( uCF_A, uCF_X1, uCF_X1_T )

  END SUBROUTINE ApplySlopeLimiter_Euler_DG


  SUBROUTINE ApplyPositivityLimiter_Euler_DG

    INTEGER  :: iX1, iX2, iX3
    INTEGER  :: iPoint, iCF, iNode
    REAL(DP) :: Theta, dD, dS1, dS2, dS3, dE
    REAL(DP) :: delta, a, b, c, r1, r2
    REAL(DP), DIMENSION(1:nPF) :: uPF_A

    IF( nDOFX == 1 ) RETURN

    IF( .NOT. ApplyPositivityLimiter ) RETURN

    DO iX3 = 1, nX(3)
      DO iX2 = 1, nX(2)
        DO iX1 = 1, nX(1)

          DO iPoint = 1, nPoints
            DO iCF = 1, nCF

              uCF_P(iPoint,iCF) &
                = DOT_PRODUCT &
                    ( uCF(:,iX1,iX2,iX3,iCF), Lagrange(:,iPoint) )

            END DO

            uPF_P(iPoint,:) = Primitive( uCF_P(iPoint,:) )

          END DO

          IF( ANY( uPF_P(:,iPF_D) < Tol_D ) &
                .OR. ANY( uPF_P(:,iPF_E) < Tol_E ) )THEN

            ! --- Limiting Using Modal Representation ---

            DO iCF = 1, nCF

              CALL MapNodalToModal_Fluid &
                     ( uCF(:,iX1,iX2,iX3,iCF), uCF_M(:,iCF) )

            END DO

            ! --- Ensure Positive Mass Density ---

            Theta = 1.0_DP
            DO iPoint = 1, nPoints
              IF( uCF_P(iPoint,iCF_D) < Tol_D ) &
                Theta &
                  = MIN( Theta, &
                         ( Tol_D - uCF_M(1,iCF_D) ) &
                           / ( uCF_P(iPoint,iCF_D) - uCF_M(1,iCF_D) ) )
            END DO

            IF( Theta < 1.0_DP )THEN

              IF( Debug )THEN
                PRINT*
                PRINT*, "iX1,iX2,iX3 = ", iX1, iX2, iX3
                PRINT*, "Theta_1 = ", Theta
                PRINT*, " D_K = ", uCF_M(1,iCF_D)
                PRINT*, " D_p = ", uCF_P(:,iCF_D)
                PRINT*
              END IF

              uCF_M(2:nDOFX,iCF_D) &
                = Theta * uCF_M(2:nDOFX,iCF_D)

              DO iPoint = 1, nPoints
                DO iCF = 1, nCF
                  uCF_P(iPoint,iCF) &
                    = evalPX( uCF_M(:,iCF), Points_X1(iPoint), &
                              Points_X2(iPoint), Points_X3(iPoint) )
                END DO

                uPF_P(iPoint,:) = Primitive( uCF_P(iPoint,:) )

              END DO

            END IF

            ! --- Ensure Positive Energy Density ---

            IF( ANY( uPF_P(:,iPF_E) < Tol_E ) )THEN

              delta = MAX( Tol_E / uCF_M(1,iCF_E), Tol_E )

              Theta = 1.0_DP
              DO iPoint = 1, nPoints

                dD  = uCF_P(iPoint,iCF_D)  - uCF_M(1,iCF_D)
                dS1 = uCF_P(iPoint,iCF_S1) - uCF_M(1,iCF_S1)
                dS2 = uCF_P(iPoint,iCF_S2) - uCF_M(1,iCF_S2)
                dS3 = uCF_P(iPoint,iCF_S3) - uCF_M(1,iCF_S3)
                dE  = uCF_P(iPoint,iCF_E)  - uCF_M(1,iCF_E)

                a = dD * dE - 0.5_DP * ( dS1**2 + dS2**2 + dS3**3 )
                b = dE * uCF_M(1,iCF_D) &
                      + dD * uCF_M(1,iCF_E) * ( 1.0_DP - delta ) &
                      - ( dS1 * uCF_M(1,iCF_S1) + dS2 * uCF_M(1,iCF_S2) &
                            + dS3 * uCF_M(1,iCF_S3) )
                c = uCF_M(1,iCF_D) * uCF_M(1,iCF_E) * ( 1.0_DP - delta ) &
                      - 0.5_DP * ( uCF_M(1,iCF_S1)**2 + uCF_M(1,iCF_S2)**2 &
                                     + uCF_M(1,iCF_S3)**2 )

                CALL GetRoots_Quadratic( a, b, c, r1, r2 )

                IF( r1 < 0.0_DP .AND. r2 < 0.0_DP )THEN
                  Theta = 0.0_DP
                ELSE
                  IF( r1 > 0.0_DP ) Theta = MIN( r1, Theta )
                  IF( r2 > 0.0_DP ) Theta = MIN( r2, Theta )
                END IF

              END DO

              IF( Theta < 1.0_DP )THEN

                IF( Debug )THEN
                  PRINT*
                  PRINT*, "iX1,iX2,iX3 = ", iX1, iX2, iX3
                  PRINT*, "Theta_2 = ", Theta
                  PRINT*
                END IF

                DO iCF = 1, nCF
                  uCF_M(2:nDOFX,iCF) &
                    = Theta * uCF_M(2:nDOFX,iCF)
                END DO

              END IF

            END IF

            ! --- Back to Nodal Representation ---

            DO iCF = 1, nCF

              CALL MapModalToNodal_Fluid &
                     ( uCF(:,iX1,iX2,iX3,iCF), uCF_M(:,iCF) )

            END DO

            uPF_A(1:nPF) = Primitive( uCF_M(1,1:nCF) )

            DO iPoint = 1, nPoints
              DO iCF = 1, nCF

                uCF_P(iPoint,iCF) &
                  = DOT_PRODUCT &
                      ( uCF(:,iX1,iX2,iX3,iCF), Lagrange(:,iPoint) )

              END DO

              uPF_P(iPoint,:) = Primitive( uCF_P(iPoint,:) )

            END DO

            IF( ANY( uPF_P(:,iPF_D) <= 0.0_DP ) &
                  .OR. ANY( uPF_P(:,iPF_E) <= 0.0_DP ) )THEN

              PRINT*
              PRINT*, "Problem with Positivity Limiter!"
              PRINT*, "  iX1, iX2, iX3 = ", iX1, iX2, iX3
              PRINT*, "  Theta = ", Theta
              PRINT*
              PRINT*, "  Conserved Fields (Nodal):"
              PRINT*, "  D_N  = ", uCF_P(:,iCF_D)
              PRINT*, "  S1_N = ", uCF_P(:,iCF_S1)
              PRINT*, "  S2_N = ", uCF_P(:,iCF_S2)
              PRINT*, "  S3_N = ", uCF_P(:,iCF_S3)
              PRINT*, "  E_N  = ", uCF_P(:,iCF_E)
              PRINT*
              PRINT*, "  Primitive Fields (Nodal):"
              PRINT*, "  D_N  = ", uPF_P(:,iPF_D)
              PRINT*, "  V1_N = ", uPF_P(:,iPF_V1)
              PRINT*, "  V2_N = ", uPF_P(:,iPF_V2)
              PRINT*, "  V3_N = ", uPF_P(:,iPF_V3)
              PRINT*, "  E_N  = ", uPF_P(:,iPF_E)
              PRINT*
              PRINT*, "  Cell-Averages (Conserved):"
              PRINT*, "  D_A  = ", uCF_M(1,iCF_D)
              PRINT*, "  S1_A = ", uCF_M(1,iCF_S1)
              PRINT*, "  S2_A = ", uCF_M(1,iCF_S2)
              PRINT*, "  S3_A = ", uCF_M(1,iCF_S3)
              PRINT*, "  E_A  = ", uCF_M(1,iCF_E)
              PRINT*
              PRINT*, "  Cell-Averages (Primitive):"
              PRINT*, "  D_A  = ", uPF_A(iPF_D)
              PRINT*, "  V1_A = ", uPF_A(iPF_V1)
              PRINT*, "  V2_A = ", uPF_A(iPF_V2)
              PRINT*, "  V3_A = ", uPF_A(iPF_V3)
              PRINT*, "  E_A  = ", uPF_A(iPF_E)
              PRINT*

              STOP

            END IF

          END IF

        END DO
      END DO
    END DO

  END SUBROUTINE ApplyPositivityLimiter_Euler_DG


END MODULE EulerEquationsLimiterModule_DG
