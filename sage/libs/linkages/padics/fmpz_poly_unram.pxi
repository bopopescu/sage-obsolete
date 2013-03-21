"""
This linkage file implements the API for unramified extensions of the padics
using FLINT's fmpz_poly_t.

AUTHORS:

- David Roe, Julian Rueth (2013-03-21) -- initial version

"""
#*****************************************************************************
#       Copyright (C) 2013 David Roe <roed.math@gmail.com>
#                          Julian Rueth <julian.rueth@fsfe.org>
#
#  Distributed under the terms of the GNU General Public License (GPL)
#  as published by the Free Software Foundation; either version 2 of
#  the License, or (at your option) any later version.
#                  http://www.gnu.org/licenses/
#*****************************************************************************

include "../../../ext/stdsage.pxi"
include "../../../ext/interrupt.pxi"
include "../../../ext/python_list.pxi"

from sage.rings.padics.common_conversion cimport cconv_mpz_t_out_shared, cconv_mpz_t_shared, cconv_mpq_t_out_shared, cconv_mpq_t_shared, cconv_shared

from sage.rings.integer cimport Integer
from sage.rings.rational cimport Rational
from sage.rings.padics.padic_generic_element cimport pAdicGenericElement
import sage.rings.finite_rings.integer_mod

from sage.libs.flint.fmpz cimport *
from sage.libs.flint.fmpz_poly cimport *

cdef inline int cconstruct(celement value, PowComputer_ prime_pow) except -1:
    """
    Construct a new element.

    INPUT:

    - ``unit`` -- an ``celement`` to be initialized.
    - ``prime_pow`` -- the PowComputer for the ring.
    """
    fmpz_poly_init(value)

cdef inline int cdestruct(celement value, PowComputer_ prime_pow) except -1:
    """
    Deallocate an element.

    INPUT:

    - ``unit`` -- an ``celement`` to be cleared.
    - ``prime_pow`` -- the PowComputer for the ring.
    """
    fmpz_poly_clear(value)

cdef inline int ccmp(celement a, celement b, long prec, bint reduce_a, bint reduce_b, PowComputer_ prime_pow) except -2:
    """
    Comparison of two elements.

    INPUT:

    - ``a`` -- an ``celement``.
    - ``b`` -- an ``celement``.
    - ``prec`` -- a long, the precision of the comparison.
    - ``reduce_a`` -- a bint, whether ``a`` needs to be reduced.
    - ``reduce_b`` -- a bint, whether ``b`` needs to be reduced.
    - ``prime_pow`` -- the PowComputer for the ring.

    OUPUT:

    - If neither ``a`` nor ``b`` needs to be reduced, returns
      -1 (if `a < b`), 0 (if `a == b`) or 1 (if `a > b`)

    - If at least one needs to be reduced, returns
      0 (if ``a == b mod p^prec``) or 1 (otherwise)
    """
    csub(prime_pow.poly_ccmp, a, b, prec, prime_pow)
    creduce(prime_pow.poly_ccmp, prime_pow.poly_ccmp, prec, prime_pow)

    if reduce_a or reduce_b:
        return not ciszero(prime_pow.poly_ccmp, prime_pow)

    if prec == 0:
        return 0

    if ciszero(prime_pow.poly_ccmp, prime_pow): return 0

    cdef long da = fmpz_poly_degree(a)
    cdef long db = fmpz_poly_degree(b)
    if da < db: return -1
    elif da > db: return 1

    cdef long cmp
    cdef long i
    for i from 0 <= i <= da:
        fmpz_poly_get_coeff_fmpz(prime_pow.fmpz_ccmp, prime_pow.poly_ccmp, i)
        cmp = fmpz_cmp_si(prime_pow.fmpz_ccmp, 0)
        if cmp < 0: return -1
        elif cmp > 0: return 1
    assert False

cdef inline int cneg(celement out, celement a, long prec, PowComputer_ prime_pow) except -1:
    """
    Negation

    Note that no reduction is performed.

    INPUT:

    - ``out`` -- an ``celement`` to store the negation.
    - ``a`` -- an ``celement`` to be negated.
    - ``prec`` -- a long, the precision: ignored.
    - ``prime_pow`` -- the PowComputer for the ring.
    """
    fmpz_poly_neg(out, a)

cdef inline int cadd(celement out, celement a, celement b, long prec, PowComputer_ prime_pow) except -1:
    """
    Addition

    Note that no reduction is performed.

    INPUT:

    - ``out`` -- an ``celement`` to store the sum.
    - ``a`` -- an ``celement``, the first summand.
    - ``b`` -- an ``celement``, the second summand.
    - ``prec`` -- a long, the precision: ignored.
    - ``prime_pow`` -- the PowComputer for the ring.
    """
    fmpz_poly_add(out, a, b)

cdef inline bint creduce(celement out, celement a, long prec, PowComputer_ prime_pow) except -1:
    """
    Reduce modulo a power of the maximal ideal.

    INPUT:

    - ``out`` -- an ``celement`` to store the reduction.
    - ``a`` -- the element to be reduced.
    - ``prec`` -- a long, the precision to reduce modulo.
    - ``prime_pow`` -- the PowComputer for the ring.

    OUTPUT:

    - returns True if the reduction is zero; False otherwise.
    """
    sig_on()
    fmpz_poly_rem(out, a, prime_pow.get_modulus(prec)[0])
    fmpz_poly_scalar_mod_fmpz(out, out, prime_pow.pow_fmpz_t_tmp(prec)[0])
    sig_off()
    return ciszero(out, prime_pow)

cdef inline bint creduce_small(celement out, celement a, long prec, PowComputer_ prime_pow) except -1:
    """
    Reduce modulo a power of the maximal ideal.

    This function assumes that at most one addition/subtraction has
    happened on reduced inputs.  For integral inputs this translates
    to the assumption that `-p^prec < a < 2p^prec`.

    INPUT:

    - ``out`` -- an ``celement`` to store the reduction.
    - ``a`` -- the element to be reduced.
    - ``prec`` -- a long, the precision to reduce modulo.
    - ``prime_pow`` -- the PowComputer for the ring.

    OUTPUT:

    - returns True if the reduction is zero; False otherwise.
    """
    return creduce(out, a, prec, prime_pow)

cdef inline long cremove(celement out, celement a, long prec, PowComputer_ prime_pow) except -1:
    """
    Extract the maximum power of the uniformizer dividing this element.

    INPUT:

    - ``out`` -- an ``celement`` to store the unit.
    - ``a`` -- the element whose valuation and unit are desired.
    - ``prec`` -- a long, used if `a = 0`.
    - ``prime_pow`` -- the PowComputer for the ring.

    OUTPUT:

    - if `a = 0`, returns prec (the value of ``out`` is undefined).
      Otherwise, returns the number of times `p` divides `a`.
    """
    if ciszero(a, prime_pow):
        return prec
    cdef long ret = cvaluation(a, prec, prime_pow)
    if ret:
        sig_on()
        fmpz_poly_scalar_divexact_fmpz(out, a, (<PowComputer_flint_unram>prime_pow).pow_fmpz_t_tmp(ret)[0])
        sig_off()
    else:
        fmpz_poly_set(out, a)
    return ret

cdef inline long cvaluation(celement a, long prec, PowComputer_ prime_pow) except -1:
    """
    Returns the maximum power of the uniformizer dividing this
    element.

    This function differs from :meth:`cremove` in that the unit is
    discarded.

    INPUT:

    - ``a`` -- the element whose valuation is desired.
    - ``prec`` -- a long, used if `a = 0`.
    - ``prime_pow`` -- the PowComputer for the ring.

    OUTPUT:

    - if `a = 0`, returns prec.  Otherwise, returns the number of
      times p divides a.
    """
    if ciszero(a, prime_pow):
        return prec
    cdef long ret = maxordp
    cdef long val
    cdef long i
    for i from 0 <= i <= fmpz_poly_degree(a):
        fmpz_poly_get_coeff_fmpz(prime_pow.fmpz_cval, a, i)
        if fmpz_is_zero(prime_pow.fmpz_cval):
            continue
        val = fmpz_remove(prime_pow.fmpz_cval, prime_pow.fmpz_cval, prime_pow.fprime)
        if val < ret: ret = val
    return ret

cdef inline bint cisunit(celement a, PowComputer_ prime_pow) except -1:
    """
    Returns whether this element has valuation zero.

    INPUT:

    - ``a`` -- the element to test.
    - ``prime_pow`` -- the PowComputer for the ring.

    OUTPUT:

    - returns True if `a` has valuation 0, and False otherwise.
    """
    fmpz_poly_scalar_mod_fmpz(prime_pow.poly_cisunit, a, prime_pow.fprime)
    return not ciszero(prime_pow.poly_cisunit, prime_pow)

cdef inline int cshift(celement out, celement a, long n, long prec, PowComputer_ prime_pow, bint reduce_afterward) except -1:
    """
    Mulitplies by a power of the uniformizer.

    INPUT:

    - ``out`` -- an ``celement`` to store the result.  If `n >= 0`
      then out will be set to `a * p^n`.
      If `n < 0`, out will be set to `a // p^-n`.
    - ``a`` -- the element to shift.
    - ``n`` -- long, the amount to shift by.
    - ``prec`` -- long, a precision modulo which to reduce.
    - ``prime_pow`` -- the PowComputer for the ring.
    - ``reduce_afterward`` -- whether to reduce afterward.
    """
    if n > 0:
        fmpz_poly_scalar_mul_fmpz(out, a, prime_pow.pow_fmpz_t_tmp(n)[0])
    elif n < 0:
        sig_on()
        fmpz_poly_scalar_fdiv_fmpz(out, a, prime_pow.pow_fmpz_t_tmp(-n)[0])
        sig_off()
    else:
        fmpz_poly_set(out, a)
    if reduce_afterward:
        creduce(out, out, prec, prime_pow)

cdef inline int cshift_notrunc(celement out, celement a, long n, long prec, PowComputer_ prime_pow) except -1:
    """
    Mulitplies by a power of the uniformizer, assuming that the
    valuation of a is at least -n.

    INPUT:

    - ``out`` -- an ``celement`` to store the result.  If `n >= 0`
      then out will be set to `a * p^n`.
      If `n < 0`, out will be set to `a // p^-n`.
    - ``a`` -- the element to shift.  Assumes that the valuation of a
      is at least -n.
    - ``n`` -- long, the amount to shift by.
    - ``prec`` -- long, a precision modulo which to reduce.
    - ``prime_pow`` -- the PowComputer for the ring.
    """
    if n > 0:
        fmpz_poly_scalar_mul_fmpz(out, a, prime_pow.pow_fmpz_t_tmp(n)[0])
    elif n < 0:
        sig_on()
        fmpz_poly_scalar_divexact_fmpz(out, a, prime_pow.pow_fmpz_t_tmp(-n)[0])
        sig_off()
    else:
        fmpz_poly_set(out, a)

cdef inline int csub(celement out, celement a, celement b, long prec, PowComputer_ prime_pow) except -1:
    """
    Subtraction.

    Note that no reduction is performed.

    INPUT:

    - ``out`` -- an ``celement`` to store the difference.
    - ``a`` -- an ``celement``, the first input.
    - ``b`` -- an ``celement``, the second input.
    - ``prec`` -- a long, the precision: ignored.
    - ``prime_pow`` -- the PowComputer for the ring.
    """
    fmpz_poly_sub(out, a, b)

cdef inline int cinvert(celement out, celement a, long prec, PowComputer_ prime_pow) except -1:
    """
    Inversion

    The result will be reduced modulo p^prec.

    INPUT:

    - ``out`` -- an ``celement`` to store the inverse.
    - ``a`` -- an ``celement``, the element to be inverted.
    - ``prec`` -- a long, the precision.
    - ``prime_pow`` -- the PowComputer for the ring.
    """
    sig_on()
    fmpz_poly_set(prime_pow.poly_cinv, prime_pow.get_modulus(prec)[0])
    fmpz_poly_primitive_part(prime_pow.poly_cinv, prime_pow.poly_cinv)

    fmpz_poly_content(prime_pow.fmpz_cinv, a)
    fmpz_poly_scalar_divexact_fmpz(out, a, prime_pow.fmpz_cinv)

    fmpz_poly_xgcd(prime_pow.fmpz_cinv2, out, prime_pow.poly_cinv2, out, prime_pow.poly_cinv)
    if fmpz_is_zero(prime_pow.tfmpz): raise ValueError("polynomials are not coprime")

    fmpz_mul(prime_pow.fmpz_cinv2, prime_pow.fmpz_cinv, prime_pow.fmpz_cinv2)
    if not fmpz_invmod(prime_pow.fmpz_cinv2, prime_pow.fmpz_cinv2, prime_pow.pow_fmpz_t_tmp(prec)[0]): raise ValueError("content or xgcd is not a unit")
    fmpz_poly_scalar_mul_fmpz(out, out, prime_pow.fmpz_cinv2)

    creduce(out, out, prec, prime_pow)
    sig_off()

cdef inline int cmul(celement out, celement a, celement b, long prec, PowComputer_ prime_pow) except -1:
    """
    Multiplication.

    Note that no reduction is performed.

    INPUT:

    - ``out`` -- an ``celement`` to store the product.
    - ``a`` -- an ``celement``, the first input.
    - ``b`` -- an ``celement``, the second input.
    - ``prec`` -- a long, the precision: ignored.
    - ``prime_pow`` -- the PowComputer for the ring.
    """
    fmpz_poly_mul(out, a, b)

cdef inline int cdivunit(celement out, celement a, celement b, long prec, PowComputer_ prime_pow) except -1:
    """
    Division.

    The inversion is perfomed modulo p^prec.  Note that no reduction
    is performed after the product.

    INPUT:

    - ``out`` -- an ``celement`` to store the quotient.
    - ``a`` -- an ``celement``, the first input.
    - ``b`` -- an ``celement``, the second input.
    - ``prec`` -- a long, the precision.
    - ``prime_pow`` -- the PowComputer for the ring.
    """
    cinvert(out, b, prec, prime_pow)
    cmul(out, a, b, prec, prime_pow)

cdef inline int csetone(celement out, PowComputer_ prime_pow) except -1:
    """
    Sets to 1.

    INPUT:

    - ``out`` -- the ``celement`` in which to store 1.
    - ``prime_pow`` -- the PowComputer for the ring.
    """
    fmpz_poly_set_ui(out, 1)

cdef inline int csetzero(celement out, PowComputer_ prime_pow) except -1:
    """
    Sets to 0.

    INPUT:

    - ``out`` -- the ``celement`` in which to store 0.
    - ``prime_pow`` -- the PowComputer for the ring.
    """
    fmpz_poly_set_ui(out, 0)

cdef inline bint cisone(celement a, PowComputer_ prime_pow) except -1:
    """
    Returns whether this element is equal to 1.

    INPUT:

    - ``a`` -- the element to test.
    - ``prime_pow`` -- the PowComputer for the ring.

    OUTPUT:

    - returns True if `a = 1`, and False otherwise.
    """
    return fmpz_poly_is_one(a)

cdef inline bint ciszero(celement a, PowComputer_ prime_pow) except -1:
    """
    Returns whether this element is equal to 0.

    INPUT:

    - ``a`` -- the element to test.
    - ``prime_pow`` -- the PowComputer for the ring.

    OUTPUT:

    - returns True if `a = 0`, and False otherwise.
    """
    return fmpz_poly_is_zero(a)

cdef inline int cpow(celement out, celement a, mpz_t n, long prec, PowComputer_ prime_pow) except -1:
    """
    Exponentiation.

    INPUT:

    - ``out`` -- the ``celement`` in which to store the result.
    - ``a`` -- the base.
    - ``n`` -- an ``mpz_t``, the exponent.
    - ``prec`` -- a long, the working absolute precision.
    - ``prime_pow`` -- the PowComputer for the ring.
    """
    if mpz_sgn(n) < 0:
        raise NotImplementedError("negative exponent")
    elif mpz_sgn(n) == 0:
        csetone(out, prime_pow)
    elif mpz_even_p(n):
        mpz_divexact_ui(prime_pow.mpz_cpow, n, 2)
        cpow(out, a, prime_pow.mpz_cpow, prec, prime_pow)
        fmpz_poly_sqr(out, out)
    else:
        mpz_sub_ui(prime_pow.mpz_cpow, n, 1)
        cpow(out, a, prime_pow.mpz_cpow, prec, prime_pow)
        fmpz_poly_mul(out, out, a)

    creduce(out, out, prec, prime_pow)

cdef inline int ccopy(celement out, celement a, PowComputer_ prime_pow) except -1:
    """
    Copying.

    INPUT:

    - ``out`` -- the ``celement`` to store the result.
    - ``a`` -- the element to copy.
    - ``prime_pow`` -- the PowComputer for the ring.
    """
    fmpz_poly_set(out, a)

cdef inline cpickle(celement a, PowComputer_ prime_pow):
    """
    Serialization into objects that Sage knows how to pickle.

    INPUT:

    - ``a`` the element to pickle.
    - ``prime_pow`` the PowComputer for the ring.

    OUTPUT:

    - a serializable object storing ``a``.
    """
    return fmpz_poly_get_str(a).decode("UTF-8")

cdef inline int cunpickle(celement out, x, PowComputer_ prime_pow) except -1:
    """
    Reconstruction from the output of meth:`cpickle`.

    INPUT:

    - ``out`` -- the ``celement`` in which to store the result.
    - ``x`` -- the result of `meth`:cpickle.
    - ``prime_pow`` -- the PowComputer for the ring.
    """
    byte_string = x.encode("UTF-8")
    cdef char* c_str = byte_string
    fmpz_poly_set_str(out, c_str)

cdef inline long chash(celement a, long ordp, long prec, PowComputer_ prime_pow) except -1:
    """
    Hashing.

    INPUT:

    - ``a`` -- an ``celement`` storing the underlying element to hash.
    - ``ordp`` -- a long storing the valuation.
    - ``prec`` -- a long storing the precision.
    - ``prime_pow`` -- a PowComputer for the ring.
    """
    if ciszero(a, prime_pow):
        return 0

    cdef Integer h = PY_NEW(Integer)
    fmpz_poly_get_coeff_mpz(h.value, a, 0)
    return hash(h)

cdef clist(celement a, long prec, bint pos, PowComputer_ prime_pow):
    """
    Returns a list of digits in the series expansion.

    This function is used in printing, and expresses ``a`` as a series
    in the standard uniformizer ``p``.  Note that for extension
    elements, "digits" could be lists themselves.

    INPUT:

    - ``a`` -- an ``celement`` giving the underlying `p`-adic element.
    - ``prec`` -- a precision giving the number of digits desired.
    - ``pos`` -- if True then representatives in 0..(p-1) are used;
                 otherwise the range (-p/2..p/2) is used.
    - ``prime_pow`` -- a PowComputer for the ring.

    OUTPUT:

    - A list of p-adic digits `[a_0, a_1, \ldots]` so that `a = a_0 + a_1*p + \cdots` modulo `p^{prec}`.
    """

    ret = []
    cdef Integer digit
    cdef long i,j
    for i from 0 <= i <= fmpz_poly_degree(a):
        fmpz_poly_get_coeff_fmpz(prime_pow.fmpz_clist, a, i)
        j = 0
        while True:
            if fmpz_is_zero(prime_pow.fmpz_clist): break
            digit = PY_NEW(Integer)
            fmpz_fdiv_qr(prime_pow.fmpz_clist, prime_pow.fmpz_clist2, prime_pow.fmpz_clist, prime_pow.fprime)
            if not fmpz_is_zero(prime_pow.fmpz_clist2):
                while len(ret) <= j: ret.append([])
                while len(ret[j]) <= i: ret[j].append(0)
                fmpz_get_mpz(digit.value, prime_pow.fmpz_clist2)
                ret[j][i] =digit
            j += 1
    return ret

# The element is filled in for zero in the output of clist if necessary.
_list_zero = []

cdef int cteichmuller(celement out, celement value, long prec, PowComputer_ prime_pow) except -1:
    """
    Teichmuller lifting.

    INPUT:

    - ``out`` -- an ``celement`` which is set to a `q-1` root of unity
                 congruent to `value` mod `\pi`; or 0 if `a \equiv 0
                 \pmod{\pi}`.
    - ``value`` -- an ``celement``, the element mod `\pi` to lift.
    - ``prec`` -- a long, the precision to which to lift.
    - ``prime_pow`` -- the Powcomputer of the ring.

    ALGORITHM:

    We use Hensel lifting to solve the equation `f(T)=T^q-T`. Instead of
    dividing by the derivative of `f`, we divide by `( q - 1 )` whose first
    digits coincide with `f'`. This does probably not yield quadratic
    convergence but taking inverses would be much more expansive than what is
    done here.

    """
    fmpz_poly_set(out, value)

    if prec == 0:
        return 0

    # fmpz_ctm = 1 / (1 - q) (mod p^prec)
    fmpz_set_ui(prime_pow.fmpz_ctm, 1)
    fmpz_sub(prime_pow.fmpz_ctm, prime_pow.fmpz_ctm, prime_pow.q)
    fmpz_invmod(prime_pow.fmpz_ctm, prime_pow.fmpz_ctm, prime_pow.pow_fmpz_t_tmp(prec)[0])
    while True:
        # poly_ctm = out + fmpz_ctm*(out^q - out)
        fmpz_get_mpz(prime_pow.mpz_ctm, prime_pow.q)
        cpow(prime_pow.poly_ctm, out, prime_pow.mpz_ctm, prec, prime_pow)
        csub(prime_pow.poly_ctm, prime_pow.poly_ctm, out, prec, prime_pow)
        fmpz_poly_scalar_mul_fmpz(prime_pow.poly_ctm, prime_pow.poly_ctm, prime_pow.fmpz_ctm)
        cadd(prime_pow.poly_ctm, prime_pow.poly_ctm, out, prec, prime_pow)
        creduce(prime_pow.poly_ctm, prime_pow.poly_ctm, prec, prime_pow)
        # break if out == poly_ctm
        if ccmp(prime_pow.poly_ctm, out, prec, False, False, prime_pow) == 0:
            return 0
        # out = poly_ctm
        fmpz_poly_set(out, prime_pow.poly_ctm)

cdef int cconv(celement out, x, long prec, long valshift, PowComputer_ prime_pow) except -2:
    """
    Conversion from other Sage types.

    INPUT:

    - ``out`` -- an ``celement`` to store the output.

    - ``x`` -- a Sage element that can be converted to a `p`-adic element.

    - ``prec`` -- a long, giving the precision desired: absolute if
                  `valshift = 0`, relative if `valshift != 0`.

    - ``valshift`` -- the power of the uniformizer to divide by before
      storing the result in ``out``.

    - ``prime_pow`` -- a PowComputer for the ring.
    """
    cdef long i
    cdef long degree

    if PyList_Check(x):
        for i from 0 <= i < len(x):
            cconv(prime_pow.poly_cconv, x[i], prec, valshift, prime_pow)
            degree = fmpz_poly_degree(prime_pow.poly_cconv)
            if degree == -1: continue
            elif degree == 0:
                fmpz_poly_get_coeff_fmpz(prime_pow.fmpz_cconv, prime_pow.poly_cconv, 0)
                fmpz_poly_set_coeff_fmpz(out, i, prime_pow.fmpz_cconv)
            else:
                raise ValueError
        creduce(out, out, prec, prime_pow)
    else:
        cconv_shared(prime_pow.mpz_cconv, x, prec, valshift, prime_pow)
        fmpz_poly_set_mpz(out, prime_pow.mpz_cconv)

cdef inline long cconv_mpq_t(celement out, celement x, long prec, bint absolute, PowComputer_ prime_pow) except? -10000:
    """
    A fast pathway for conversion of rationals that doesn't require
    precomputation of the valuation.

    INPUT:

    - ``out`` -- an ``celement`` to store the output.
    - ``x`` -- an ``mpq_t`` giving the integer to be converted.
    - ``prec`` -- a long, giving the precision desired: absolute or
      relative depending on the ``absolute`` input.
    - ``absolute`` -- if False then extracts the valuation and returns
                      it, storing the unit in ``out``; if True then
                      just reduces ``x`` modulo the precision.
    - ``prime_pow`` -- a PowComputer for the ring.

    OUTPUT:

    - If ``absolute`` is False then returns the valuation that was
      extracted (``maxordp`` when `x = 0`).
    """
    cconv_mpq_t_shared(prime_pow.mpz_cconv, x, prec, absolute, prime_pow)
    fmpz_poly_set_mpz(out, prime_pow.mpz_cconv)

cdef inline int cconv_mpq_t_out(mpq_t out, celement x, long valshift, long prec, PowComputer_ prime_pow) except -1:
    """
    Converts the underlying `p`-adic element into a rational

    - ``out`` -- gives a rational approximating the input.  Currently uses rational reconstruction but
                 may change in the future to use a more naive method
    - ``x`` -- an ``celement`` giving the underlying `p`-adic element
    - ``valshift`` -- a long giving the power of `p` to shift `x` by
    -` ``prec`` -- a long, the precision of ``x``, used in rational reconstruction
    - ``prime_pow`` -- a PowComputer for the ring
    """
    cdef long degree = fmpz_poly_degree(x)
    if degree > 0:
        raise ValueError
    elif degree == -1:
        mpz_set_ui(prime_pow.mpz_cconv, 0)
    else:
        fmpz_poly_get_coeff_mpz(prime_pow.mpz_cconv, x, 0)

    cconv_mpq_t_out_shared(out, prime_pow.mpz_cconv, valshift, prec, prime_pow)

cdef inline long cconv_mpz_t(celement out, mpz_t x, long prec, bint absolute, PowComputer_ prime_pow) except -2:
    """
    A fast pathway for conversion of integers that doesn't require
    precomputation of the valuation.

    INPUT:

    - ``out`` -- an ``celement`` to store the output.
    - ``x`` -- an ``mpz_t`` giving the integer to be converted.
    - ``prec`` -- a long, giving the precision desired: absolute or
                  relative depending on the ``absolute`` input.
    - ``absolute`` -- if False then extracts the valuation and returns
                      it, storing the unit in ``out``; if True then
                      just reduces ``x`` modulo the precision.
    - ``prime_pow`` -- a PowComputer for the ring.

    OUTPUT:

    - If ``absolute`` is False then returns the valuation that was
      extracted (``maxordp`` when `x = 0`).
    """
    cconv_mpz_t_shared(prime_pow.mpz_cconv, x, prec, absolute, prime_pow)
    fmpz_poly_set_mpz(out, prime_pow.mpz_cconv)

cdef inline int cconv_mpz_t_out(mpz_t out, celement x, long valshift, long prec, PowComputer_ prime_pow) except -1:
    """
    Converts the underlying `p`-adic element into an integer if
    possible.

    - ``out`` -- stores the resulting integer as an integer between 0
      and `p^{prec + valshift}`.
    - ``x`` -- an ``celement`` giving the underlying `p`-adic element.
    - ``valshift`` -- a long giving the power of `p` to shift `x` by.
    -` ``prec`` -- a long, the precision of ``x``: currently not used.
    - ``prime_pow`` -- a PowComputer for the ring.
    """
    cdef long degree = fmpz_poly_degree(x)
    if degree > 0:
        raise ValueError
    elif degree == -1:
        mpz_set_ui(prime_pow.mpz_cconv, 0)
    else:
        fmpz_poly_get_coeff_mpz(prime_pow.mpz_cconv, x, 0)

    cconv_mpz_t_out_shared(out, prime_pow.mpz_cconv, valshift, prec, prime_pow)

## Python methods ##

def frobenius(self, arithmetic=True):
    """
    Returns the image of this element under the Frobenius automorphism
    applied to its parent.

    INPUT:

    - ``self`` -- an element of an unramified extension.
    - ``arithmetic`` -- whether to apply the arithmetic Frobenius (acting
      by raising to the `p`-th power on the residue field). If ``False`` is
      provided, the image of geometric Frobenius (raising to the `(1/p)`-th
      power on the residue field) will be returned instead.

    EXAMPLES::

        sage: R.<a> = Zq(5^4,3)
        sage: a.frobenius()
        (a^3 + a^2 + 3*a) + (3*a + 1)*5 + (2*a^3 + 2*a^2 + 2*a)*5^2 + O(5^3)
        sage: f = R.defining_polynomial()
        sage: f(a)
        O(5^3)
        sage: f(a.frobenius())
        O(5^3)
        sage: for i in range(4): a = a.frobenius()
        sage: a
        a + O(5^3)

        sage: K.<a> = Qq(7^3,4)
        sage: b = (a+1)/7
        sage: c = b.frobenius(); c
        (3*a^2 + 5*a + 1)*7^-1 + (6*a^2 + 6*a + 6) + (4*a^2 + 3*a + 4)*7 + (6*a^2 + a + 6)*7^2 + O(7^3)
        sage: c.frobenius().frobenius()
        (a + 1)*7^-1 + O(7^3)

    An error will be raised if the parent of self is a ramified extension::

        sage: K.<a> = Qp(5).extension(x^2 - 5)
        sage: a.frobenius()
        Traceback (most recent call last):
        ...
        NotImplementedError: Frobenius automorphism only implemented for unramified extensions
    """
    R = self.parent()
    if self.is_zero(): return self
    L = self.teichmuller_list()
    ppow = R.uniformizer_pow(self.valuation())
    if arithmetic:
        exp = R.prime()
    else:
        exp = R.prime()**(R.degree()-1)
    ans = ppow * L[0]**exp
    for m in range(1,len(L)):
        ppow = ppow << 1
        ans += ppow * L[m]**exp
    return ans

def norm(self, base = None):
    """
    Return the absolute or relative norm of this element.

    NOTE!  This is not the `p`-adic absolute value.  This is a
    field theoretic norm down to a ground ring.  If you want the
    `p`-adic absolute value, use the ``abs()`` function instead.

    If ``base`` is given then ``base`` must be a subfield of the
    parent `L` of ``self``, in which case the norm is the relative
    norm from L to ``base``.

    In all other cases, the norm is the absolute norm down to
    `\mathbb{Q}_p` or `\mathbb{Z}_p`.

    EXAMPLES::

        sage: R = ZpCR(5,5)
        sage: S.<x> = R[]
        sage: f = x^5 + 75*x^3 - 15*x^2 +125*x - 5
        sage: W.<w> = R.ext(f)
        sage: ((1+2*w)^5).norm()
        1 + 5^2 + O(5^5)
        sage: ((1+2*w)).norm()^5
        1 + 5^2 + O(5^5)

    TESTS::

        sage: R = ZpCA(5,5)
        sage: S.<x> = ZZ[]
        sage: f = x^5 + 75*x^3 - 15*x^2 +125*x - 5
        sage: W.<w> = R.ext(f)
        sage: ((1+2*w)^5).norm()
        1 + 5^2 + O(5^5)
        sage: ((1+2*w)).norm()^5
        1 + 5^2 + O(5^5)
        sage: R = ZpFM(5,5)
        sage: S.<x> = ZZ[]
        sage: f = x^5 + 75*x^3 - 15*x^2 +125*x - 5
        sage: W.<w> = R.ext(f)
        sage: ((1+2*w)^5).norm()
        1 + 5^2 + O(5^5)
        sage: ((1+2*w)).norm()^5
        1 + 5^2 + O(5^5)

    TESTS:

    Check that #11586 has been resolved::

        sage: R.<x> = QQ[]
        sage: f = x^2 + 3*x + 1
        sage: M.<a> = Qp(7).extension(f)
        sage: M(7).norm()
        7^2 + O(7^22)
        sage: b = 7*a + 35
        sage: b.norm()
        4*7^2 + 7^3 + O(7^22)
        sage: b*b.frobenius()
        4*7^2 + 7^3 + O(7^22)
    """
    if base is not None:
        if base is self.parent():
            return self
        else:
            raise NotImplementedError
    if self._is_exact_zero():
        return self.parent().ground_ring()(0)
    elif self._is_inexact_zero():
        return self.ground_ring(0, self.valuation())
    if self.valuation() == 0:
        return self.parent().ground_ring()(self.matrix_mod_pn().det())
    else:
        if self.parent().e() == 1:
            norm_of_uniformizer = self.parent().ground_ring().uniformizer_pow(self.parent().degree())
        else:
            norm_of_uniformizer = (-1)**self.parent().degree() * self.parent().defining_polynomial()[0]
        return self.parent().ground_ring()(self.unit_part().matrix_mod_pn().det()) * norm_of_uniformizer**self.valuation()

def trace(self, base = None):
    """
    Return the absolute or relative trace of this element.

    If ``base`` is given then ``base`` must be a subfield of the
    parent `L` of ``self``, in which case the norm is the relative
    norm from `L` to ``base``.

    In all other cases, the norm is the absolute norm down to
    `\mathbb{Q}_p` or `\mathbb{Z}_p`.

    EXAMPLES::

        sage: R = ZpCR(5,5)
        sage: S.<x> = R[]
        sage: f = x^5 + 75*x^3 - 15*x^2 +125*x - 5
        sage: W.<w> = R.ext(f)
        sage: a = (2+3*w)^7
        sage: b = (6+w^3)^5
        sage: a.trace()
        3*5 + 2*5^2 + 3*5^3 + 2*5^4 + O(5^5)
        sage: a.trace() + b.trace()
        4*5 + 5^2 + 5^3 + 2*5^4 + O(5^5)
        sage: (a+b).trace()
        4*5 + 5^2 + 5^3 + 2*5^4 + O(5^5)

    TESTS::

        sage: R = ZpCA(5,5)
        sage: S.<x> = ZZ[]
        sage: f = x^5 + 75*x^3 - 15*x^2 +125*x - 5
        sage: W.<w> = R.ext(f)
        sage: a = (2+3*w)^7
        sage: b = (6+w^3)^5
        sage: a.trace()
        3*5 + 2*5^2 + 3*5^3 + 2*5^4 + O(5^5)
        sage: a.trace() + b.trace()
        4*5 + 5^2 + 5^3 + 2*5^4 + O(5^5)
        sage: (a+b).trace()
        4*5 + 5^2 + 5^3 + 2*5^4 + O(5^5)
        sage: R = ZpFM(5,5)
        sage: S.<x> = R[]
        sage: f = x^5 + 75*x^3 - 15*x^2 +125*x - 5
        sage: W.<w> = R.ext(f)
        sage: a = (2+3*w)^7
        sage: b = (6+w^3)^5
        sage: a.trace()
        3*5 + 2*5^2 + 3*5^3 + 2*5^4 + O(5^5)
        sage: a.trace() + b.trace()
        4*5 + 5^2 + 5^3 + 2*5^4 + O(5^5)
        sage: (a+b).trace()
        4*5 + 5^2 + 5^3 + 2*5^4 + O(5^5)
    """
    if base is not None:
        if base is self.parent():
            return self
        else:
            raise NotImplementedError
    if self._is_exact_zero():
        return self.parent().ground_ring()(0)
    elif self._is_inexact_zero():
        return self.ground_ring(0, self.precision_absolute())
    if self.valuation() >= 0:
        return self.parent().ground_ring()(self.matrix_mod_pn().trace())
    else:
        shift = -self.valuation()
        return self.parent().ground_ring()((self * self.parent().prime() ** shift).matrix_mod_pn().trace()) / self.parent().prime()**shift

