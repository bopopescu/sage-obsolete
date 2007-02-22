
include "../ext/cdefs.pxi"

cimport matrix_dense

cdef class Matrix_rational_dense(matrix_dense.Matrix_dense):

    cdef mpq_t tmp
    cdef mpq_t *_entries
    cdef mpq_t ** _matrix
    cdef object __pivots
    
    cdef int mpz_denom(self, mpz_t d) except -1
    cdef int mpz_height(self, mpz_t height) except -1
    cdef int _rescale(self, mpq_t a) except -1

    cdef _pickle_version0(self)
    cdef _unpickle_version0(self, data)    


cdef class MatrixWindow:
    cdef Matrix_rational_dense _matrix
    cdef int _row, _col, _nrows, _ncols
