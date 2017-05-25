!>
!> @file
!>
!>  PLASMA is a software package provided by:
!>  University of Tennessee, US,
!>  University of Manchester, UK.
!>
!> @precisions normal z -> s d c
!>
program test_zgeqrf_omp
    use, intrinsic :: iso_fortran_env

    use plasma
    implicit none

    integer, parameter :: sp = REAL32
    integer, parameter :: dp = REAL64

    ! set working precision, this value is rewritten for different precisions
    integer, parameter :: wp = dp

    ! matrices
    complex(wp), allocatable :: A(:,:)
    complex(wp), allocatable :: Aref(:,:)

    ! matrix descriptor for storing coefficients of the Householder reflectors
    ! generalization of TAU array known from LAPACK
    type(plasma_desc_t) :: descT

    ! descriptor for A
    type(plasma_desc_t) :: descA

    ! matrices for checking correctness
    complex(wp), allocatable :: Q(:,:)
    complex(wp), allocatable :: Id(:,:)
    complex(wp), allocatable :: R(:,:)

    ! dimensions
    integer :: m
    integer :: n
    integer :: lda
    integer :: nb
    integer :: ib
    logical :: tree_householder
    logical :: use_tuning

    real(wp) :: tol

    ! auxiliary variables
    integer :: ldq
    integer :: info
    integer :: minmn

    complex(wp), parameter :: zone  =  1.0
    complex(wp), parameter :: zmone = -1.0
    complex(wp), parameter :: zzero =  0.0
    integer :: seed(4) = [0, 0, 0, 1]

    real(wp) :: normA
    real(wp) :: ortho
    real(wp) :: error

    real(wp), allocatable :: work(:)
    real(wp) :: zlange, zlanhe, dlamch

    integer :: householder_mode
    integer :: householder_mode_check
    integer :: tuning_mode

    type(plasma_context_t), pointer :: plasma_context
    integer(kind=c_size_t) :: lworkspace
    type(plasma_workspace_t) :: workspace
    type(plasma_sequence_t), pointer :: plasma_sequence
    type(plasma_request_t) :: plasma_request

    integer :: plasma_status

    ! Set parameters.
    m    = 2000 ! number of rows
    n    = 500  ! number of columns

    nb   = 256  ! tile size (square tiles)
    ib   = 64   ! inner blocking size within a tile

    ! Should tree reduction be used? This is good for tall and skinny matrices.
    tree_householder = .true. 

    ! Should tuning be used?
    ! If it is on, the tests below reset the nb and ib values and then fail.
    use_tuning = .false. 

    ! tolerance for the correctness check
    tol = 50.0 * dlamch('E')

    ! Initialize arrays.
    lda  = m    ! leading dimension of A
    allocate(A(lda, n), Aref(lda, n))
    call zlarnv(1, seed, lda*n, A)
    Aref = A

    write(*,'(a, i6, a, i6)') " Testing asynchronous QR factorization of a matrix ", m, " x ", n
    write(*,'(a, i6)')        "  tile size:        ", nb
    write(*,'(a, i6)')        "  inner block size: ", ib
    if (tree_householder) then
        write(*,'(a, i6)')    "  Using tree-based Householder reduction. "
    else
        write(*,'(a, i6)')    "  Using flat-tree Householder reduction. "
    end if
    if (use_tuning) then
        write(*,'(a, i6)')    "  Tuning enabled. "
    else
        write(*,'(a, i6)')    "  Tuning disabled. "
    end if

    !==============================================
    ! Initialize PLASMA.
    !==============================================
    call plasma_init(info)
    call check_error('plasma_init()', info)

    !==============================================
    ! Set PLASMA parameters.
    !==============================================
    ! set tile size
    call plasma_set(PlasmaNb, nb, info)
    call check_error('plasma_set()', info)

    ! set inner blocking size
    call plasma_set(PlasmaIb, ib, info)
    call check_error('plasma_set()', info)

    ! set Householder mode
    if (tree_householder) then
        householder_mode = PlasmaTreeHouseholder
    else
        householder_mode = PlasmaFlatHouseholder
    end if
    call plasma_set(PlasmaHouseholderMode, householder_mode, info)
    call check_error('plasma_set()', info)

    call plasma_get(PlasmaHouseholderMode, householder_mode_check, info)
    if (householder_mode_check /= householder_mode) then
        write(*,'(a, i2, a, i2)') &
            "Something is wrong - Householder mode not set correctly:", &
            householder_mode_check, " not the same as ", householder_mode
    end if

    ! set tuning
    if (use_tuning) then
        tuning_mode = PlasmaEnabled
    else
        tuning_mode = PlasmaDisabled
    end if
    call plasma_set(PlasmaTuning, tuning_mode, info)
    call check_error('plasma_set()', info)

    ! get PLASMA context
    call plasma_context_self(plasma_context)
    call check_error('plasma_context_self()', info)

    ! set tuning
    if (tuning_mode == PlasmaEnabled) then
        call plasma_tune_geqrf(plasma_context, PlasmaComplexDouble, m, n)
        call check_error('plasma_tune_geqrf()', info)
    end if

    ! create descriptor for A
    call plasma_desc_general_create(PlasmaComplexDouble, nb, nb, &
                                    m, n, 0, 0, m, n, descA, info)
    call check_error('plasma_desc_general_create()', info)

    ! create descriptor for T
    call plasma_descT_create(descA, ib, householder_mode, descT, info)
    call check_error('plasma_descT_create()', info)

    ! Allocate workspace.
    lworkspace = nb + ib*nb;  ! geqrt: tau + work
    call plasma_workspace_create(workspace, lworkspace, PlasmaComplexDouble, info)
    call check_error('plasma_workspace_create()', info)

    ! Create sequence.
    call plasma_sequence_create(plasma_sequence, info)
    call check_error('plasma_sequence_create()', info)

    !==============================================
    ! Call QR factorization for A.
    !==============================================
    ! asynchronous block
    !$omp parallel
    !$omp master
        ! Translate to tile layout.
        call plasma_omp_zge2desc(A, lda, descA, plasma_sequence, &
                                 plasma_request)

        ! Call the tile async function.
        call plasma_omp_zgeqrf(descA, descT, workspace, plasma_sequence, &
                               plasma_request)

        ! Translate back to LAPACK layout.
        call plasma_omp_zdesc2ge(descA, A, lda, plasma_sequence, &
                                 plasma_request)
    !$omp end master
    !$omp end parallel
    ! implicit synchronization

    plasma_status = plasma_sequence%status
    print *, "PLASMA status after the OMP block: ", plasma_status
    call plasma_sequence_destroy(plasma_sequence, info)
    call check_error('plasma_sequence_destroy()', info)

    call plasma_workspace_destroy(workspace, info)
    call check_error('plasma_workspace_destroy()', info)

    ! Free matrix A in tile layout.
    call plasma_desc_destroy(descA, info)
    call check_error('plasma_desc_destroy()', info)

    ! Test results by checking orthogonality of Q and precision of Q*R.
    ! Allocate space for Q.
    minmn = min(m, n)
    ldq = m
    allocate(Q(ldq, minmn))

    !==================================================================
    ! Build Q.
    !==================================================================
    call plasma_zungqr(m, minmn, minmn, A, lda, descT, Q, ldq, info)
    call check_error('plasma_zungqr()', info)

    ! Build the identity matrix.
    allocate(Id(minmn, minmn))
    call zlaset('g', minmn, minmn, zzero, zone, Id, minmn)

    ! Perform Id - Q^H * Q
    call zherk('Upper', 'Conjugate transpose', minmn, m, &
               zmone, Q, ldq, zone, Id, minmn)

    ! |Id - Q^H * Q|_oo
    allocate(work(m))
    ortho = zlanhe('I', 'u', minmn, Id, minmn, work)
    print *, 'ortho', ortho

    ! normalize the result
    ! |Id - Q^H * Q|_oo / n
    ortho = ortho / minmn

    deallocate(Q)
    deallocate(Id)

    ! Check the accuracy of A - Q * R
    ! Extract the R factor.
    allocate(R(m,n))
    R = 0.0
    call zlacpy('u', m, n, A, lda, R, m)

    !==================================================================
    ! Compute Q * R.
    !==================================================================
    call plasma_zunmqr(PlasmaLeft, PlasmaNoTrans, m, n, minmn, A, lda, descT, &
                       R, m, info)
    call check_error('plasma_zunmqr()', info)

    ! Compute the difference.
    ! R = A - Q*R
    R = Aref(1:m,:) - R

    ! |A|_oo
    normA = zlange('I', m, n, Aref, lda, work)

    ! |A - Q*R|_oo
    error = zlange('I', m, n, R, m, work)

    ! normalize the result
    ! |A-QR|_oo / (|A|_oo * n)
    error = error / (normA * n)

    ! print output of the check
    write(*,'(a, e13.6)') &
        "  Orthogonality of Q, measured as |Id - Q^H * Q|_oo / n: ", ortho
    write(*,'(a, e13.6)') &
        "  Error of factorization, measured as |A-Q*R|_oo / (|A|_oo * n): ", error
    if (error < tol .and. ortho < tol) then
        write(*,'(a)') "  The result is CORRECT."
    else
        write(*,'(a)') "  The result is WRONG!"
    end if
    write(*,'(a)') ""

    deallocate(work)
    deallocate(R)

    !==============================================
    ! Deallocate matrix in descriptor.
    !==============================================
    call plasma_desc_destroy(descT, info)
    call check_error('plasma_desc_destroy()', info)

    !==============================================
    ! Finalize PLASMA.
    !==============================================
    call plasma_finalize(info)
    call check_error('plasma_finalize()', info)


    deallocate(A)
    deallocate(Aref)

contains

    subroutine check_error(routine_name, code)
        use plasma
        implicit none
        character(len=*) :: routine_name
        integer :: code

        if (code /= PlasmaSuccess) then
            write(*,'(a, i2, a, a)') "Error ", code, "in a call to ", &
                trim(routine_name) 
        end if
    end subroutine

end program test_zgeqrf_omp
