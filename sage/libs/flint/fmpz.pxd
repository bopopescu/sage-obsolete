# This file was (manually) generated from FLINT's fmpz.h.
#*****************************************************************************
#        Copyright (C) 2009 William Hart
#
#  Distributed under the terms of the GNU General Public License (GPL)
#  as published by the Free Software Foundation; either version 2 of
#  the License, or (at your option) any later version.
#                  http://www.gnu.org/licenses/
#*****************************************************************************
include "../ntl/decl.pxi"

from sage.libs.flint.nmod_poly cimport *
from sage.libs.flint.flint cimport *

cdef extern from "flint/fmpz.h":
    ctypedef long fmpz
    ctypedef long * fmpz_t
    ctypedef void * mpz_t

    ctypedef struct fmpz_comb_struct:
        mp_limb_t * primes
        long num_primes
        long n
        fmpz ** comb
        fmpz ** res
        nmod_t * mod

    ctypedef void* fmpz_comb_t

    ctypedef struct fmpz_comb_temp_struct:
        mp_limb_t * primes
        long num_primes
        long n
        fmpz ** comb
        fmpz ** res
        nmod_t * mod

    ctypedef void* fmpz_comb_temp_t

    void _fmpz_clear_mpz(fmpz f)
    void _fmpz_cleanup_mpz_content()
    void _fmpz_cleanup()
    void _fmpz_demote(fmpz_t f)
    void _fmpz_demote_val(fmpz_t f)
    void _fmpz_init_readonly_mpz(fmpz_t f, mpz_t z)
    void _fmpz_clear_readonly_mpz(mpz_t)
    void fmpz_init(fmpz_t f)
    void fmpz_init2(fmpz_t f, unsigned long limbs)
    void fmpz_init_set(fmpz_t f, fmpz_t g)
    void fmpz_init_set_ui(fmpz_t f, unsigned long g)
    void fmpz_clear(fmpz_t f)
    void fmpz_randbits(fmpz_t f, flint_rand_t state, mp_bitcnt_t bits)
    void fmpz_randm(fmpz_t f, flint_rand_t state, fmpz_t m)
    void fmpz_randtest(fmpz_t f, flint_rand_t state, mp_bitcnt_t bits)
    void fmpz_randtest_unsigned(fmpz_t f, flint_rand_t state, mp_bitcnt_t bits)
    void fmpz_randtest_not_zero(fmpz_t f, flint_rand_t state, mp_bitcnt_t bits)
    void fmpz_randtest_mod(fmpz_t f, flint_rand_t state, fmpz_t m)
    void fmpz_randtest_mod_signed(fmpz_t f, flint_rand_t state, fmpz_t m)
    long fmpz_get_si(fmpz_t f)
    unsigned long fmpz_get_ui(fmpz_t f)
    void fmpz_set_si(fmpz_t f, long val)
    void fmpz_set_ui(fmpz_t f, unsigned long val)
    void fmpz_get_mpz(mpz_t x, fmpz_t f)
    void fmpz_set_mpz(fmpz_t f, mpz_t x)
    double fmpz_get_d(fmpz_t f)
    void fmpz_set_d(fmpz_t f, double c)
    int fmpz_set_str(fmpz_t f, char * str, int b)
    void flint_mpz_init_set_readonly(mpz_t z, fmpz_t f)
    void flint_mpz_clear_readonly(mpz_t z)
    void fmpz_init_set_readonly(fmpz_t f, mpz_t z)
    void fmpz_clear_readonly(fmpz_t f)
    int fmpz_abs_fits_ui(fmpz_t f)
    int fmpz_fits_si(fmpz_t f)
    void fmpz_zero(fmpz_t f)
    void fmpz_one(fmpz_t f)
    int fmpz_is_zero(fmpz_t f)
    int fmpz_is_one(fmpz_t f)
    int fmpz_is_pm1(fmpz_t f)
    void fmpz_set(fmpz_t f, fmpz_t g)
    int fmpz_equal(fmpz_t f, fmpz_t g)
    int fmpz_read(fmpz_t f)
    int fmpz_fread(FILE * file, fmpz_t f)
    int fmpz_print(fmpz_t x)
    int fmpz_fprint(FILE * file, fmpz_t x)
    size_t fmpz_sizeinbase(fmpz_t f, int b)
    char * fmpz_get_str(char * str, int b, fmpz_t f)
    void fmpz_swap(fmpz_t f, fmpz_t g)
    int fmpz_cmp(fmpz_t f, fmpz_t g)
    int fmpz_cmp_ui(fmpz_t f, unsigned long g)
    int fmpz_cmp_si(fmpz_t f, long g)
    int fmpz_cmpabs(fmpz_t f, fmpz_t g)
    int fmpz_is_even(fmpz_t f)
    int fmpz_is_odd(fmpz_t f)
    mp_size_t fmpz_size(fmpz_t f)
    int fmpz_sgn(fmpz_t f)
    mp_bitcnt_t fmpz_bits(fmpz_t f)
    mp_bitcnt_t fmpz_val2(fmpz_t x)
    void fmpz_neg(fmpz_t f1, fmpz_t f2)
    void fmpz_abs(fmpz_t f1, fmpz_t f2)
    void fmpz_add(fmpz_t f, fmpz_t g, fmpz_t h)
    void fmpz_sub(fmpz_t f, fmpz_t g, fmpz_t h)
    void fmpz_mul_ui(fmpz_t f, fmpz_t g, unsigned long x)
    void fmpz_mul_si(fmpz_t f, fmpz_t g, long x)
    void fmpz_mul(fmpz_t f, fmpz_t g, fmpz_t h)
    void fmpz_mul_2exp(fmpz_t f, fmpz_t g, unsigned long exp)
    void fmpz_add_ui(fmpz_t f, fmpz_t g, unsigned long x)
    void fmpz_sub_ui(fmpz_t f, fmpz_t g, unsigned long x)
    void fmpz_addmul_ui(fmpz_t f, fmpz_t g, unsigned long x)
    void fmpz_submul_ui(fmpz_t f, fmpz_t g, unsigned long x)
    void fmpz_addmul(fmpz_t f, fmpz_t g, fmpz_t h)
    void fmpz_submul(fmpz_t f, fmpz_t g, fmpz_t h)
    void fmpz_pow_ui(fmpz_t f, fmpz_t g, unsigned long exp)
    void fmpz_powm_ui(fmpz_t f, fmpz_t g, unsigned long exp, fmpz_t m)
    void fmpz_powm(fmpz_t f, fmpz_t g, fmpz_t e, fmpz_t m)
    void fmpz_setbit(fmpz_t f, unsigned long i)
    int fmpz_tstbit(fmpz_t f, unsigned long i)
    void fmpz_clrbit(fmpz_t f, unsigned long i)
    void fmpz_complement(fmpz_t r, fmpz_t f)
    void fmpz_combit(fmpz_t f, unsigned long i)
    void fmpz_and(fmpz_t r, fmpz_t a, fmpz_t b)
    void fmpz_or(fmpz_t r, fmpz_t a, fmpz_t b)
    void fmpz_xor(fmpz_t r, fmpz_t a, fmpz_t b)
    mp_bitcnt_t fmpz_popcnt(fmpz_t c)
    double fmpz_dlog(fmpz_t x)
    long fmpz_flog(fmpz_t x, fmpz_t b)
    long fmpz_flog_ui(fmpz_t x, unsigned long b)
    long fmpz_clog(fmpz_t x, fmpz_t b)
    long fmpz_clog_ui(fmpz_t x, unsigned long b)
    int fmpz_sqrtmod(fmpz_t b, fmpz_t a, fmpz_t p)
    void fmpz_sqrt(fmpz_t f, fmpz_t g)
    int fmpz_is_square(fmpz_t f)
    void fmpz_root(fmpz_t r, fmpz_t f, long n)
    void fmpz_sqrtrem(fmpz_t f, fmpz_t r, fmpz_t g)
    unsigned long fmpz_fdiv_ui(fmpz_t g, unsigned long h)
    unsigned long fmpz_mod_ui(fmpz_t f, fmpz_t g, unsigned long h)
    void fmpz_mod(fmpz_t f, fmpz_t g, fmpz_t h)
    void fmpz_gcd(fmpz_t f, fmpz_t g, fmpz_t h)
    void fmpz_lcm(fmpz_t f, fmpz_t g, fmpz_t h)
    void fmpz_gcdinv(fmpz_t d, fmpz_t a, fmpz_t f, fmpz_t g)
    int fmpz_invmod(fmpz_t f, fmpz_t g, fmpz_t h)
    long _fmpz_remove(fmpz_t x, fmpz_t f, double finv)
    long fmpz_remove(fmpz_t rop, fmpz_t op, fmpz_t f)
    void fmpz_divexact(fmpz_t f, fmpz_t g, fmpz_t h)
    void fmpz_divexact_si(fmpz_t f, fmpz_t g, long h)
    void fmpz_divexact_ui(fmpz_t f, fmpz_t g, unsigned long h)
    int fmpz_divisible(fmpz_t f, fmpz_t g)
    int fmpz_divisible_si(fmpz_t f, long g)
    void fmpz_cdiv_q(fmpz_t f, fmpz_t g, fmpz_t h)
    void fmpz_cdiv_q_si(fmpz_t f, fmpz_t g, long h)
    void fmpz_cdiv_q_ui(fmpz_t f, fmpz_t g, unsigned long h)
    void fmpz_cdiv_q_2exp(fmpz_t f, fmpz_t g, unsigned long exp)
    void fmpz_fdiv_qr(fmpz_t f, fmpz_t s, fmpz_t g, fmpz_t h)
    void fmpz_fdiv_q(fmpz_t f, fmpz_t g, fmpz_t h)
    void fmpz_fdiv_r(fmpz_t f, fmpz_t g, fmpz_t h)
    void fmpz_fdiv_q_ui(fmpz_t f, fmpz_t g, unsigned long h)
    void fmpz_fdiv_q_si(fmpz_t f, fmpz_t g, long h)
    void fmpz_fdiv_q_2exp(fmpz_t f, fmpz_t g, unsigned long exp)
    void fmpz_fdiv_r_2exp(fmpz_t f, fmpz_t g, unsigned long exp)
    void fmpz_tdiv_q(fmpz_t f, fmpz_t g, fmpz_t h)
    void fmpz_tdiv_q_ui(fmpz_t f, fmpz_t g, unsigned long h)
    void fmpz_tdiv_q_si(fmpz_t f, fmpz_t g, long h)
    unsigned long fmpz_tdiv_ui(fmpz_t g, unsigned long h)
    void fmpz_tdiv_q_2exp(fmpz_t f, fmpz_t g, unsigned long exp)
    double fmpz_get_d_2exp(long * exp, fmpz_t f)
    void fmpz_mul2_uiui(fmpz_t f, fmpz_t g, unsigned long h1, unsigned long h2)
    void fmpz_divexact2_uiui(fmpz_t f, fmpz_t g, unsigned long h1, unsigned long h2)
    void fmpz_mul_tdiv_q_2exp(fmpz_t f, fmpz_t g, fmpz_t h, unsigned long exp)
    void fmpz_mul_si_tdiv_q_2exp(fmpz_t f, fmpz_t g, long x, unsigned long exp)
    void fmpz_fac_ui(fmpz_t f, unsigned long n)
    void fmpz_fib_ui(fmpz_t f, unsigned long n)
    void fmpz_bin_uiui(fmpz_t res, unsigned long n, unsigned long k)
    void _fmpz_rfac_ui(fmpz_t r, fmpz_t x, unsigned long a, unsigned long b)
    void fmpz_rfac_ui(fmpz_t r, fmpz_t x, unsigned long n)
    void fmpz_rfac_uiui(fmpz_t r, unsigned long x, unsigned long n)
    int fmpz_bit_pack(mp_ptr arr, mp_bitcnt_t shift, mp_bitcnt_t bits, fmpz_t coeff, int negate, int borrow)
    int fmpz_bit_unpack(fmpz_t coeff, mp_srcptr arr, mp_bitcnt_t shift, mp_bitcnt_t bits, int negate, int borrow)
    void fmpz_bit_unpack_unsigned(fmpz_t coeff, mp_srcptr arr, mp_bitcnt_t shift, mp_bitcnt_t bits)
    void _fmpz_CRT_ui_precomp(fmpz_t out, fmpz_t r1, fmpz_t m1, unsigned long r2, unsigned long m2, mp_limb_t m2inv, fmpz_t m1m2, mp_limb_t c, int sign)
    void fmpz_CRT_ui(fmpz_t out, fmpz_t r1, fmpz_t m1, unsigned long r2, unsigned long m2, int sign)
    void fmpz_comb_temp_init(fmpz_comb_temp_t temp, fmpz_comb_t comb)
    void fmpz_comb_temp_clear(fmpz_comb_temp_t temp)
    void fmpz_comb_init(fmpz_comb_t comb, mp_limb_t * primes, long num_primes)
    void fmpz_comb_clear(fmpz_comb_t comb)
    void fmpz_multi_mod_ui(mp_limb_t * out, fmpz_t in_, fmpz_comb_t comb, fmpz_comb_temp_t temp)
    void fmpz_multi_CRT_ui(fmpz_t output, mp_limb_t * residues, fmpz_comb_t comb, fmpz_comb_temp_t temp, int sign)
    void fmpz_set_ui_smod(fmpz_t f, mp_limb_t x, mp_limb_t m)
    mp_limb_t fmpz_abs_ubound_ui_2exp(long * exp, fmpz_t x, int bits)
    mp_limb_t fmpz_abs_lbound_ui_2exp(long * exp, fmpz_t x, int bits)
