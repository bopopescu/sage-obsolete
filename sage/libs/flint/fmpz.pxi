include "../ntl/decl.pxi"

cdef extern from "flint/fmpz.h":

    ctypedef long fmpz
    ctypedef long * fmpz_t
    ctypedef void * mpz_t

    void fmpz_init(fmpz_t x)

    void fmpz_set_ui(fmpz_t res, unsigned long x)
    void fmpz_set_si(fmpz_t res, long x)
    void fmpz_one(fmpz_t f)

    int fmpz_cmp(fmpz_t f, fmpz_t g)
    int fmpz_cmp_si(fmpz_t f, long g)
    int fmpz_sgn(fmpz_t f)

    void fmpz_clear(fmpz_t f)
    void fmpz_print(fmpz_t f)
    int fmpz_is_one(fmpz_t f)

    void fmpz_get_mpz(mpz_t rop, fmpz_t op)
    void fmpz_set_mpz(fmpz_t rop, mpz_t op)

    void fmpz_add_ui(fmpz_t f, fmpz_t g, unsigned long c)

    void fmpz_sub(fmpz_t f, fmpz_t g, fmpz_t h)

    void fmpz_mul(fmpz_t f, fmpz_t g, fmpz_t h)

    void fmpz_mod(fmpz_t f, fmpz_t g, fmpz_t h)
    int fmpz_invmod(fmpz_t f, fmpz_t g, fmpz_t h)
    void fmpz_pow_ui(fmpz_t f, fmpz_t g, unsigned long exp)
    long fmpz_remove(fmpz_t rop, fmpz_t op, fmpz_t f)
    int fmpz_is_zero(fmpz_t f)
    void fmpz_fdiv_qr(fmpz_t f, fmpz_t s, fmpz_t g, fmpz_t h)
