MODULE BoundaryConditionsModule_Beta

  USE KindModule, ONLY: &
    DP
  USE MeshModule, ONLY: &
    MeshX, NodeCoordinate
  USE ReferenceElementModuleX, ONLY: &
    NodeNumberTableX, WeightsX_q
  USE ProgramHeaderModule, ONLY: &
    bcX, swX, nDOFX, nNodesX
  USE UtilitiesModule, ONLY: &
    NodeNumberX
  USE FluidFieldsModule, ONLY: &
    nCF, iCF_D, iCF_S1, iCF_S2, iCF_S3, iCF_E

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: ApplyBoundaryConditions_Fluid

CONTAINS


  SUBROUTINE ApplyBoundaryConditions_Fluid &
               ( iX_B0, iX_E0, iX_B1, iX_E1, U )

    INTEGER,  INTENT(in)    :: &
      iX_B0(3), iX_E0(3), iX_B1(3), iX_E1(3)
    REAL(DP), INTENT(inout) :: &
      U(1:,iX_B1(1):,iX_B1(2):,iX_B1(3):,1:)

    CALL ApplyBC_Fluid_X1 &
           ( iX_B0, iX_E0, iX_B1, iX_E1, U )

    CALL ApplyBC_Fluid_X2 &
           ( iX_B0, iX_E0, iX_B1, iX_E1, U )

    CALL ApplyBC_Fluid_X3 &
           ( iX_B0, iX_E0, iX_B1, iX_E1, U )

  END SUBROUTINE ApplyBoundaryConditions_Fluid


  SUBROUTINE ApplyBC_Fluid_X1( iX_B0, iX_E0, iX_B1, iX_E1, U )

    INTEGER,  INTENT(in)    :: &
      iX_B0(3), iX_E0(3), iX_B1(3), iX_E1(3)
    REAL(DP), INTENT(inout) :: &
      U(1:,iX_B1(1):,iX_B1(2):,iX_B1(3):,1:)

    INTEGER :: iCF, iX1, iX2, iX3, iNode, iNodeX1
    REAL(DP) :: D_0, E_0, R_0, R_q 

    SELECT CASE ( bcX(1) )

    CASE ( 0 ) ! No Boundary Condition

    CASE ( 1 ) ! Periodic

      DO iCF = 1, nCF
        DO iX3 = iX_B0(3), iX_E0(3)
          DO iX2 = iX_B0(2), iX_E0(2)
            DO iX1 = 1, swX(1)

              ! --- Inner Boundary ---

              U(:,iX_B0(1)-iX1,iX2,iX3,iCF) &
                = U(:,iX_E0(1)-(iX1-1),iX2,iX3,iCF)

              ! --- Outer Boundary ---

              U(:,iX_E0(1)+iX1,iX2,iX3,iCF) &
                = U(:,iX_B0(1)+(iX1-1),iX2,iX3,iCF)

            END DO
          END DO
        END DO
      END DO

    CASE ( 2 ) ! Homogeneous

      DO iCF = 1, nCF
        DO iX3 = iX_B0(3), iX_E0(3)
          DO iX2 = iX_B0(2), iX_E0(2)
            DO iX1 = 1, swX(1)

              ! --- Inner Boundary ---

              U(:,iX_B0(1)-iX1,iX2,iX3,iCF) &
                = U(:,iX_B0(1),iX2,iX3,iCF)

              ! --- Outer Boundary ---

              U(:,iX_E0(1)+iX1,iX2,iX3,iCF) &
                = U(:,iX_E0(1),iX2,iX3,iCF)

            END DO
          END DO
        END DO
      END DO
    
    CASE ( 11 ) ! Custom BCs for Accretion Problem

      R_0 = MeshX(1) % Center(1) 

      DO iX3 = iX_B0(3), iX_E0(3)
        DO iX2 = iX_B0(2), iX_E0(2)
          
          D_0 = DOT_PRODUCT( WeightsX_q(:), U(:,1,iX2,iX3,iCF_D) )
          E_0 = DOT_PRODUCT( WeightsX_q(:), U(:,1,iX2,iX3,iCF_E) )
          
          DO iX1 = 1, swX(1)

            ! --- Inner Boundary ---            
        
            DO iNode = 1, nDOFX
             
              iNodeX1 = NodeNumberTableX(1, iNode)

              R_q = NodeCoordinate( MeshX(1), iX1, iNodeX1 )            

              U(iNode,iX_B0(1)-iX1,iX2,iX3,iCF_D) &
                = D_0 * ( R_0 / R_q ) ** 3 
       
              U(iNode,iX_B0(1)-iX1,iX2,iX3,iCF_S1) &
                = 0.0_DP

              U(iNode,iX_B0(1)-iX1,iX2,iX3,iCF_S2) &
                = 0.0_DP
            
              U(iNode,iX_B0(1)-iX1,iX2,iX3,iCF_S3) &
                = 0.0_DP
 
              U(iNode,iX_B0(1)-iX1,iX2,iX3,iCF_E) &
                = E_0 * ( R_0 / R_q ) ** 4 

            END DO
         END DO
       END DO
     END DO 

    CASE DEFAULT

      WRITE(*,*)
      WRITE(*,'(A5,A45,I2.2)') &
        '', 'Invalid Boundary Condition for Fluid X1: ', bcX(1)
      STOP

    END SELECT

  END SUBROUTINE ApplyBC_Fluid_X1


  SUBROUTINE ApplyBC_Fluid_X2( iX_B0, iX_E0, iX_B1, iX_E1, U )

    INTEGER,  INTENT(in)    :: &
      iX_B0(3), iX_E0(3), iX_B1(3), iX_E1(3)
    REAL(DP), INTENT(inout) :: &
      U(1:,iX_B1(1):,iX_B1(2):,iX_B1(3):,1:)

    INTEGER :: iCF, iX1, iX2, iX3
    INTEGER :: iNodeX, iNodeX1, iNodeX2, iNodeX3, jNodeX, jNodeX2

    SELECT CASE ( bcX(2) )

    CASE ( 0 ) ! No Boundary Condition

    CASE ( 1 ) ! Periodic

      DO iCF = 1, nCF
        DO iX3 = iX_B0(3), iX_E0(3)
          DO iX2 = 1, swX(2)
            DO iX1 = iX_B0(1), iX_E0(1)

              ! --- Inner Boundary ---

              U(:,iX1,iX_B0(2)-iX2,iX3,iCF) &
                = U(:,iX1,iX_E0(2)-(iX2-1),iX3,iCF)

              ! --- Outer Boundary ---

              U(:,iX1,iX_E0(2)+iX2,iX3,iCF) &
                = U(:,iX1,iX_B0(2)+(iX2-1),iX3,iCF)

            END DO
          END DO
        END DO
      END DO

    CASE ( 2 ) ! Homogeneous

      DO iCF = 1, nCF
        DO iX3 = iX_B0(3), iX_E0(3)
          DO iX2 = 1, swX(2)
            DO iX1 = iX_B0(1), iX_E0(1)

              ! --- Inner Boundary ---

              U(:,iX1,iX_B0(2)-iX2,iX3,iCF) &
                = U(:,iX1,iX_B0(2),iX3,iCF)

              ! --- Outer Boundary ---

              U(:,iX1,iX_E0(2)+iX2,iX3,iCF) &
                = U(:,iX1,iX_E0(2),iX3,iCF)

            END DO
          END DO
        END DO
      END DO

    CASE ( 3 ) ! Reflecting

        DO iX3 = iX_B0(3), iX_E0(3)
          DO iX2 = 1, swX(2)
            DO iX1 = iX_B0(1), iX_E0(1)
            
              DO iNodeX3 = 1, nNodesX(3)
                DO iNodeX2 = 1, nNodesX(2)
                  DO iNodeX1 = 1, nNodesX(1)

                    jNodeX2 = ( nNodesX(2) - iNodeX2 ) + 1
                 
                    iNodeX = NodeNumberX( iNodeX1, iNodeX2, iNodeX3 )
                    jNodeX = NodeNumberX( iNodeX1, jNodeX2, iNodeX3 )

                    DO iCF = 1, nCF

                      ! --- Inner boundary ---
                      U(iNodeX,iX1,iX_B0(2)-iX2,iX3,iCF) &
                        = U(jNodeX,iX1,iX_B0(2),iX3,iCF)  
              
                      ! --- Outer boundary ---
                      U(iNodeX,iX1,iX_E0(2)+iX2,iX3,iCF) &
                        = U(jNodeX,iX1,iX_E0(2),iX3,iCF)

                    END DO

                    U(iNodeX,iX1,iX_B0(2)-iX2,iX3,iCF_S2) &
                      = - U(jNodeX,iX1,iX_B0(2),iX3,iCF_S2)

                    U(iNodeX,iX1,iX_E0(2)+iX2,iX3,iCF_S2) &
                      = - U(jNodeX,iX1,iX_E0(2),iX3,iCF_S2)

                  END DO
                END DO
              END DO

            END DO
          END DO
        END DO

    CASE DEFAULT

      WRITE(*,*)
      WRITE(*,'(A5,A45,I2.2)') &
        '', 'Invalid Boundary Condition for Fluid X2: ', bcX(2)
      STOP

    END SELECT

  END SUBROUTINE ApplyBC_Fluid_X2


  SUBROUTINE ApplyBC_Fluid_X3( iX_B0, iX_E0, iX_B1, iX_E1, U )

    INTEGER,  INTENT(in)    :: &
      iX_B0(3), iX_E0(3), iX_B1(3), iX_E1(3)
    REAL(DP), INTENT(inout) :: &
      U(1:,iX_B1(1):,iX_B1(2):,iX_B1(3):,1:)

    INTEGER :: iCF, iX1, iX2, iX3

    SELECT CASE ( bcX(3) )

    CASE ( 0 ) ! No Boundary Condition

    CASE ( 1 ) ! Periodic

      DO iCF = 1, nCF
        DO iX3 = 1, swX(3)
          DO iX2 = iX_B0(2), iX_E0(2)
            DO iX1 = iX_B0(1), iX_E0(1)

              ! --- Inner Boundary ---

              U(:,iX1,iX2,iX_B0(3)-iX3,iCF) &
                = U(:,iX1,iX2,iX_E0(3)-(iX3-1),iCF)

              ! --- Outer Boundary ---

              U(:,iX1,iX2,iX_E0(3)+iX3,iCF) &
                = U(:,iX1,iX2,iX_B0(3)+(iX3-1),iCF)

            END DO
          END DO
        END DO
      END DO

    CASE ( 2 ) ! Homogeneous

      DO iCF = 1, nCF
        DO iX3 = 1, swX(3)
          DO iX2 = iX_B0(2), iX_E0(2)
            DO iX1 = iX_B0(1), iX_E0(1)

              ! --- Inner Boundary ---

              U(:,iX1,iX2,iX_B0(3)-iX3,iCF) &
                = U(:,iX1,iX2,iX_B0(3),iCF)

              ! --- Outer Boundary ---

              U(:,iX1,iX2,iX_E0(3)+iX3,iCF) &
                = U(:,iX1,iX2,iX_E0(3),iCF)

            END DO
          END DO
        END DO
      END DO

    CASE DEFAULT

      WRITE(*,*)
      WRITE(*,'(A5,A45,I2.2)') &
        '', 'Invalid Boundary Condition for Fluid X3: ', bcX(3)
      STOP

    END SELECT

  END SUBROUTINE ApplyBC_Fluid_X3


END MODULE BoundaryConditionsModule_Beta