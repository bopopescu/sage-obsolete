include "../../ext/cdefs.pxi"
include "../../ext/interrupt.pxi"
include "../../libs/flint/fmpz.pxi"
include "../../libs/flint/fmpz_poly.pxi"
include "../../libs/flint/fmpz_vec.pxi"
include "../../libs/flint/padic.pxi"

#from sage.libs.flint.ntl_interface cimport *
from sage.rings.padics.pow_computer cimport PowComputer_class

cdef class PowComputer_flint(PowComputer_class):
    cdef padic_ctx_t ctx
    cdef fmpz_t fprime
    cdef fmpz_t ftmp
    cdef fmpz_t ftmp2
    cdef mpz_t top_power

    cdef fmpz_t* pow_fmpz_t_tmp(self, unsigned long n)
    cdef unsigned long capdiv(self, unsigned long n)

cdef class PowComputer_flint_1step(PowComputer_flint):
    cdef fmpz_poly_t modulus
    cdef fmpz_poly_t tmp_poly
    cdef fmpz_poly_t* _moduli
    cdef fmpz_poly_t* get_modulus(self, unsigned long n)
    cdef fmpz_poly_t* get_modulus_capdiv(self, unsigned long n)

cdef class PowComputer_flint_unram(PowComputer_flint_1step):
    pass

cdef class PowComputer_flint_eis(PowComputer_flint_1step):
    pass
