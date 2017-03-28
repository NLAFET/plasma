/**
 *
 * @file
 *
 *  PLASMA is a software package provided by:
 *  University of Tennessee, US,
 *  University of Manchester, UK.
 *
 **/
#ifndef ICL_PLASMA_WORKSPACE_H
#define ICL_PLASMA_WORKSPACE_H

#include "plasma_types.h"

#include <stdlib.h>
#include <assert.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    void **spaces;      ///< array of nthread pointers to workspaces
    size_t lwork;       ///< length in elements of workspace on each core
    int nthread;        ///< number of threads
    plasma_enum_t dtyp; ///< precision of the workspace
} plasma_workspace_t;

/******************************************************************************/
int plasma_workspace_create(plasma_workspace_t *work, size_t lwork,
                           plasma_enum_t dtyp);

int plasma_workspace_destroy(plasma_workspace_t *work);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif // ICL_PLASMA_WORKSPACE_H
