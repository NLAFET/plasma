/**
 *
 * @file
 *
 *  PLASMA is a software package provided by:
 *  University of Tennessee, US,
 *  University of Manchester, UK.
 *
 **/
#ifndef ICL_PLASMA_TYPES_H
#define ICL_PLASMA_TYPES_H

#include <complex.h>

#ifdef __cplusplus
extern "C" {
#endif

/******************************************************************************/
#ifdef PLASMA_WITH_MKL
#define lapack_complex_float plasma_complex32_t
#define lapack_complex_double plasma_complex64_t
#endif

/***************************************************************************//**
 *
 *  Some CBLAS routines take scalars by value in real arithmetic
 *  and by pointer in complex arithmetic.
 *  In precision generation, CBLAS_SADDR is removed from real arithmetic files.
 *
 **/
#ifndef CBLAS_SADDR
#define CBLAS_SADDR(var) &(var)
#endif

/******************************************************************************/
enum {
    PlasmaByte          = 0,
    PlasmaInteger       = 1,
    PlasmaRealFloat     = 2,
    PlasmaRealDouble    = 3,
    PlasmaComplexFloat  = 4,
    PlasmaComplexDouble = 5
};

/***************************************************************************//**
 *
 *  PLASMA constants - CBLAS & LAPACK.
 *  The naming and numbering is consistent with:
 *
 *    - CBLAS - http://www.netlib.org/blas/blast-forum/cblas.tgz,
 *    - LAPACKE - http://www.netlib.org/lapack/lapwrapc/.
 *
 *  During precision generation, Plasma_ConjTrans is conveted to PlasmaTrans,
 *  while PlasmaConjTrans is preserved.
 *
 **/
enum {
    PlasmaInvalid       = -1,

    PlasmaNoTrans       = 111,
    PlasmaTrans         = 112,
    PlasmaConjTrans     = 113,
    Plasma_ConjTrans    = PlasmaConjTrans,

    PlasmaUpper         = 121,
    PlasmaLower         = 122,
    PlasmaGeneral       = 123,
    PlasmaGeneralBand   = 124,

    PlasmaNonUnit       = 131,
    PlasmaUnit          = 132,

    PlasmaLeft          = 141,
    PlasmaRight         = 142,

    PlasmaOneNorm       = 171,
    PlasmaRealOneNorm   = 172,
    PlasmaTwoNorm       = 173,
    PlasmaFrobeniusNorm = 174,
    PlasmaInfNorm       = 175,
    PlasmaRealInfNorm   = 176,
    PlasmaMaxNorm       = 177,
    PlasmaRealMaxNorm   = 178,

    PlasmaForward       = 391,
    PlasmaBackward      = 392,

    PlasmaColumnwise    = 401,
    PlasmaRowwise       = 402,

    PlasmaW             = 501,
    PlasmaA2            = 502
};

enum {
    PlasmaSuccess = 0,
    PlasmaErrorNotInitialized,
    PlasmaErrorNotSupported,
    PlasmaErrorIllegalValue,
    PlasmaErrorOutOfMemory,
    PlasmaErrorNullParameter,
    PlasmaErrorInternal,
    PlasmaErrorSequence,
    PlasmaErrorComponent,
    PlasmaErrorEnvironment
};

enum {
    PlasmaInplace,
    PlasmaOutplace
};

enum {
    PlasmaFlatHouseholder,
    PlasmaTreeHouseholder
};

enum {
    PlasmaDisabled = 0,
    PlasmaEnabled = 1
};

enum {
    PlasmaTuning,
    PlasmaNb,
    PlasmaIb,
    PlasmaInplaceOutplace,
    PlasmaNumPanelThreads,
    PlasmaHouseholderMode
};

/******************************************************************************/
typedef int plasma_enum_t;

typedef float  _Complex plasma_complex32_t;
typedef double _Complex plasma_complex64_t;

/******************************************************************************/
plasma_enum_t plasma_diag_const(char lapack_char);
plasma_enum_t plasma_direct_const(char lapack_char);
plasma_enum_t plasma_norm_const(char lapack_char);
plasma_enum_t plasma_side_const(char lapack_char);
plasma_enum_t plasma_storev_const(char lapack_char);
plasma_enum_t plasma_trans_const(char lapack_char);
plasma_enum_t plasma_uplo_const(char lapack_char);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif // ICL_PLASMA_TYPES_H
