MODULE TimersModule_AMReX_Euler

  USE, INTRINSIC :: ISO_FORTRAN_ENV, ONLY: &
    I8=>INT64

  USE amrex_fort_module, ONLY: &
    amrex_real
  USE amrex_parallel_module, ONLY: &
    amrex_parallel_ioprocessor

  IMPLICIT NONE
  PRIVATE

  LOGICAL,  PUBLIC :: TimeIt_AMReX_Euler = .FALSE.

  REAL(amrex_real), PUBLIC :: Timer_AMReX_Euler_Program

  ! --- fmain ---
  REAL(amrex_real), PUBLIC :: Timer_AMReX_Euler_Initialize
  REAL(amrex_real), PUBLIC :: Timer_AMReX_Euler_MPI_Barrier
  REAL(amrex_real), PUBLIC :: Timer_AMReX_ComputeTimeStep_Euler
  REAL(amrex_real), PUBLIC :: Timer_AMReX_Euler_UpdateFluid
  REAL(amrex_real), PUBLIC :: Timer_AMReX_Euler_InputOutput
  REAL(amrex_real), PUBLIC :: Timer_AMReX_Euler_Finalize

  ! --- AMReX-specific ---
  REAL(amrex_real), PUBLIC :: Timer_AMReX_Euler_DataTransfer
  REAL(amrex_real), PUBLIC :: Timer_AMReX_Euler_InteriorBC
  REAL(amrex_real), PUBLIC :: Timer_AMReX_Euler_CopyMultiFab
  REAL(amrex_real), PUBLIC :: Timer_AMReX_Euler_ConstructEdgeMap
  REAL(amrex_real), PUBLIC :: Timer_AMReX_Euler_GetBC

  CHARACTER(24) :: OutputFMT = '(7x,A,ES13.6E3,A,F6.3,A)'

  PUBLIC :: InitializeTimers_AMReX_Euler
  PUBLIC :: FinalizeTimers_AMReX_Euler
  PUBLIC :: TimersStart_AMReX_Euler
  PUBLIC :: TimersStop_AMReX_Euler
  PUBLIC :: TimersWtime_AMReX


CONTAINS


  SUBROUTINE InitializeTimers_AMReX_Euler

    IF( .NOT. TimeIt_AMReX_Euler ) RETURN

    Timer_AMReX_Euler_Program          = 0.0_amrex_real

    Timer_AMReX_Euler_Initialize       = 0.0_amrex_real
    Timer_AMReX_Euler_MPI_Barrier      = 0.0_amrex_real
    Timer_AMReX_ComputeTimeStep_Euler  = 0.0_amrex_real
    Timer_AMReX_Euler_UpdateFluid      = 0.0_amrex_real
    Timer_AMReX_Euler_InputOutput      = 0.0_amrex_real
    Timer_AMReX_Euler_Finalize         = 0.0_amrex_real

    Timer_AMReX_Euler_DataTransfer     = 0.0_amrex_real
    Timer_AMReX_Euler_InteriorBC       = 0.0_amrex_real
    Timer_AMReX_Euler_CopyMultiFab     = 0.0_amrex_real
    Timer_AMReX_Euler_ConstructEdgeMap = 0.0_amrex_real
    Timer_AMReX_Euler_GetBC            = 0.0_amrex_real

    CALL TimersStart_AMReX_Euler( Timer_AMReX_Euler_Program )

    RETURN
  END SUBROUTINE InitializeTimers_AMReX_Euler


  SUBROUTINE FinalizeTimers_AMReX_Euler

    REAL(amrex_real) :: TotalTime

    IF( .NOT. TimeIt_AMReX_Euler ) RETURN

    CALL TimersStop_AMReX_Euler( Timer_AMReX_Euler_Program )

    TotalTime = 0.0_amrex_real

    IF( amrex_parallel_ioprocessor() )THEN

      WRITE(*,*)
      WRITE(*,'(5x,A)') 'Timers (AMReX-Euler) Summary'
      WRITE(*,'(5x,A)') '----------------------------'
      WRITE(*,*)

      WRITE(*,'(7x,A,ES13.6E3,A)') &
        'TotalRunTime = ', Timer_AMReX_Euler_Program, ' s'
      WRITE(*,*)

      WRITE(*,'(5x,A)') '  fmain'
      WRITE(*,'(5x,A)') '  -----'
      WRITE(*,*)

      WRITE(*,OutputFMT) &
        '  Initialize:        ', &
        Timer_AMReX_Euler_Initialize, ' s = ', &
        100.0_amrex_real &
          * Timer_AMReX_Euler_Initialize / Timer_AMReX_Euler_Program, ' %'
      TotalTime = TotalTime + Timer_AMReX_Euler_Initialize

      WRITE(*,OutputFMT) &
        '  MPI_Barrier:       ', &
        Timer_AMReX_Euler_MPI_Barrier, ' s = ', &
        100.0_amrex_real &
          * Timer_AMReX_Euler_MPI_Barrier / Timer_AMReX_Euler_Program, ' %'
      TotalTime = TotalTime + Timer_AMReX_Euler_MPI_Barrier

      WRITE(*,OutputFMT) &
        '  Compute Time-Step: ', &
        Timer_AMReX_ComputeTimeStep_Euler, ' s = ', &
        100.0_amrex_real &
          * Timer_AMReX_ComputeTimeStep_Euler / Timer_AMReX_Euler_Program, ' %'
      TotalTime = TotalTime + Timer_AMReX_ComputeTimeStep_Euler

      WRITE(*,OutputFMT) &
        '  Update Fluid:      ', &
        Timer_AMReX_Euler_UpdateFluid , ' s = ', &
        100.0_amrex_real &
          * Timer_AMReX_Euler_UpdateFluid / Timer_AMReX_Euler_Program, ' %'
      TotalTime = TotalTime + Timer_AMReX_Euler_UpdateFluid

      WRITE(*,OutputFMT) &
        '  Input/Output:      ', &
        Timer_AMReX_Euler_InputOutput , ' s = ', &
        100.0_amrex_real &
          * Timer_AMReX_Euler_InputOutput / Timer_AMReX_Euler_Program, ' %'
      TotalTime = TotalTime + Timer_AMReX_Euler_InputOutput

      WRITE(*,OutputFMT) &
        '  Finalize:          ', &
        Timer_AMReX_Euler_Finalize, ' s = ', &
        100.0_amrex_real &
          * Timer_AMReX_Euler_Finalize / Timer_AMReX_Euler_Program, ' %'
      TotalTime = TotalTime + Timer_AMReX_Euler_Finalize

      WRITE(*,*)
      WRITE(*,'(7x,A,ES13.6E3,A)') &
        '  Timers = ', TotalTime, ' s'
      WRITE(*,*)
      WRITE(*,'(7x,A,F7.3,A)') &
        '  Timers / TotalRunTime = ', &
        100.0_amrex_real &
        * TotalTime / Timer_AMReX_Euler_Program, ' %'

      WRITE(*,*)
      WRITE(*,'(7x,A)') 'AMReX-specific'
      WRITE(*,'(7x,A)') '--------------'
      WRITE(*,*)
      TotalTime = 0.0_amrex_real

      WRITE(*,OutputFMT) &
        '  Data Transfer:                ', &
        Timer_AMReX_Euler_DataTransfer, ' s = ', &
        100.0_amrex_real &
          * Timer_AMReX_Euler_DataTransfer / Timer_AMReX_Euler_Program, ' %'
        TotalTime = TotalTime + Timer_AMReX_Euler_DataTransfer

      WRITE(*,OutputFMT) &
        '  Interior Boundary Conditions: ', &
        Timer_AMReX_Euler_InteriorBC, ' s = ', &
        100.0_amrex_real &
          * Timer_AMReX_Euler_InteriorBC / Timer_AMReX_Euler_Program, ' %'
        TotalTime = TotalTime + Timer_AMReX_Euler_InteriorBC

      WRITE(*,OutputFMT) &
        '  Copy MultiFab:                ', &
        Timer_AMReX_Euler_CopyMultiFab, ' s = ', &
        100.0_amrex_real &
          * Timer_AMReX_Euler_CopyMultiFab / Timer_AMReX_Euler_Program, ' %'
        TotalTime = TotalTime + Timer_AMReX_Euler_CopyMultiFab

      WRITE(*,OutputFMT) &
        '  Construct Edge-Map:           ', &
        Timer_AMReX_Euler_ConstructEdgeMap, ' s = ', &
        100.0_amrex_real &
          * Timer_AMReX_Euler_ConstructEdgeMap / Timer_AMReX_Euler_Program, ' %'
        TotalTime = TotalTime + Timer_AMReX_Euler_ConstructEdgeMap

      WRITE(*,OutputFMT) &
        '  Get BC:                       ', &
        Timer_AMReX_Euler_GetBC, ' s = ', &
        100.0_amrex_real &
          * Timer_AMReX_Euler_GetBC / Timer_AMReX_Euler_Program, ' %'
        TotalTime = TotalTime + Timer_AMReX_Euler_GetBC

      WRITE(*,*)
      WRITE(*,'(7x,A,ES13.6E3,A)') &
        '  Timers-AMReX = ', TotalTime, ' s'
      WRITE(*,*)
      WRITE(*,'(7x,A,F6.3,A)') &
        '  Timers-AMReX / TotalRunTime = ', &
        100.0_amrex_real &
          * TotalTime / Timer_AMReX_Euler_Program, ' %'

    END IF

    RETURN
  END SUBROUTINE FinalizeTimers_AMReX_Euler


  SUBROUTINE TimersStart_AMReX_Euler( Timer )

    REAL(amrex_real), INTENT(inout) :: Timer

    IF( .NOT. TimeIt_AMReX_Euler ) RETURN

    Timer = Timer - TimersWtime_AMReX()

    RETURN
  END SUBROUTINE TimersStart_AMReX_Euler


  SUBROUTINE TimersStop_AMReX_Euler( Timer )

    REAL(amrex_real), INTENT(inout) :: Timer

    IF( .NOT. TimeIt_AMReX_Euler ) RETURN

    Timer = Timer + TimersWtime_AMReX()

    RETURN
  END SUBROUTINE TimersStop_AMReX_Euler


  REAL(amrex_real) FUNCTION TimersWtime_AMReX()

    INTEGER(I8) :: clock_read
    INTEGER(I8) :: clock_rate
    INTEGER(I8) :: clock_max

    IF( .NOT. TimeIt_AMReX_Euler ) RETURN

    CALL SYSTEM_CLOCK( clock_read, clock_rate, clock_max )
    TimersWtime_AMReX = REAL( clock_read, amrex_real ) &
                          / REAL( clock_rate, amrex_real )

    RETURN
  END FUNCTION TimersWtime_AMReX


END MODULE TimersModule_AMReX_Euler
