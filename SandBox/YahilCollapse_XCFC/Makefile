THORNADO_DIR ?= ../../../
include $(THORNADO_DIR)/Build/Makefile_Build
include $(THORNADO_DIR)/Build/Makefile_Thornado_Dependencies

POSEIDON_DIR ?= $(HOME)/poseidon
include $(POSEIDON_DIR)/Build/Make.Poseidon_Native

#DEFINES += -DTHORNADO_DEBUG

.DEFAULT_GOAL := all

all: ApplicationDriver

ApplicationDriver: \
	$(POSEIDON_o) \
	$(thornado) \
	InitializationModule_Relativistic.o \
	TimeSteppingModule_SSPRK.o \
	ApplicationDriver.o
	$(FLINKER) $(FLAGS) -o ApplicationDriver_$(MACHINE) \
	$(POSEIDON_o) \
	$(thornado) \
	InitializationModule_Relativistic.o \
	TimeSteppingModule_SSPRK.o \
	ApplicationDriver.o \
	$(LIBRARIES)

clean:
	rm -f *.o *.mod *.ld

clobber: clean
	rm -f  ApplicationDriver_$(MACHINE)
	rm -rf ApplicationDriver_$(MACHINE).dSYM

InitializationModule_Relativistic.o: \
  KindModule.o \
  UtilitiesModule.o \
  ProgramHeaderModule.o \
  ReferenceElementModuleX.o \
  MeshModule.o \
  UnitsModule.o \
  GeometryFieldsModule.o \
  FluidFieldsModule.o \
  EquationOfStateModule_IDEAL.o \
  Euler_UtilitiesModule_Relativistic.o \
  InitializationModule_Relativistic.f90

TimeSteppingModule_SSPRK.o: \
  KindModule.o \
  ProgramHeaderModule.o \
  GeometryFieldsModule.o \
  FluidFieldsModule.o \
  XCFC_UtilitiesModule.o \
  GravitySolutionModule_XCFC.o \
  Euler_XCFC_UtilitiesModule.o \
  Euler_SlopeLimiterModule_Relativistic_IDEAL.o \
  Euler_PositivityLimiterModule_Relativistic_IDEAL.o \
  Euler_dgDiscretizationModule.o \
  Euler_TallyModule_Relativistic.o \
  TimersModule_Euler.o \
  TimeSteppingModule_SSPRK.f90

ApplicationDriver.o: \
  KindModule.o \
  ProgramHeaderModule.o \
  ProgramInitializationModule.o \
  ReferenceElementModuleX.o \
  ReferenceElementModuleX_Lagrange.o \
  UnitsModule.o \
  EquationOfStateModule.o \
  GeometryFieldsModule.o \
  FluidFieldsModule.o \
  GravitySolutionModule_XCFC.o \
  Euler_UtilitiesModule_Relativistic.o \
  Euler_SlopeLimiterModule_Relativistic_IDEAL.o \
  Euler_PositivityLimiterModule_Relativistic_IDEAL.o \
  Euler_dgDiscretizationModule.o \
  Euler_TallyModule_Relativistic.o \
  Euler_XCFC_UtilitiesModule.o \
  InitializationModule_Relativistic.o \
  TimeSteppingModule_SSPRK.o \
  InputOutputModuleHDF.o \
  TimersModule_Euler.o \
  ApplicationDriver.f90

