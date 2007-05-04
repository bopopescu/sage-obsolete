"""
Abstract base class for rings

AUTHORS:
    -- David Harvey (2006-10-16): changed CommutativeAlgebra to derive from
    CommutativeRing instead of from Algebra
"""

#*****************************************************************************
#       Copyright (C) 2005,2007 William Stein <wstein@gmail.com>
#
#  Distributed under the terms of the GNU General Public License (GPL)
#
#    This code is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    General Public License for more details.
#
#  The full text of the GPL is available at:
#
#                  http://www.gnu.org/licenses/
#*****************************************************************************

include "../ext/stdsage.pxi"
include "../ext/python_bool.pxi"

from sage.structure.parent_gens cimport ParentWithGens
from random import randint, randrange

cdef class Ring(ParentWithGens):
    """
    Generic ring class.
    """
    def __init__(self):
        pass
    
    def __call__(self, x):
        """
        Coerce x into the ring.
        """
        raise NotImplementedError

    def __iter__(self):
        raise NotImplementedError, "object does not support iteration"

    def __len__(self):
        if self.is_finite():
            return self.cardinality()
        raise TypeError, 'len() of unsized object'
 
    def __getitem__(self, x):
        """
        Create a polynomial or power series ring over self and inject
        the variables into the global module scope.

        EXAMPLES:
        We create several polynomial rings.
            sage: ZZ['x']
            Univariate Polynomial Ring in x over Integer Ring
            sage: QQ['x']
            Univariate Polynomial Ring in x over Rational Field
            sage: GF(17)['abc']
            Univariate Polynomial Ring in abc over Finite Field of size 17
            sage: GF(17)['a,b,c']
            Polynomial Ring in a, b, c over Finite Field of size 17

        We can also create power series rings (in one variable) by
        using double brackets:
            sage: QQ[['t']]
            Power Series Ring in t over Rational Field
            sage: ZZ[['W']]
            Power Series Ring in W over Integer Ring

        Use \code{Frac} (for fraction field) to obtain a Laurent series ring:
            sage: Frac(QQ[['t']])
            Laurent Series Ring in t over Rational Field
        
        """

        from sage.rings.polynomial.polynomial_element import is_Polynomial
        if is_Polynomial(x):
            x = str(x)


        if not isinstance(x, list):
            from sage.rings.polynomial.polynomial_ring import PolynomialRing
            P = PolynomialRing(self, x)
            return P

        P = None
        if isinstance(x, list):
            if len(x) != 1:
                raise NotImplementedError, "Power series rings only implemented in 1 variable"
            x = (str(x[0]), )
            from sage.rings.power_series_ring import PowerSeriesRing
            P = PowerSeriesRing

        elif isinstance(x, (tuple, str)):
            from sage.rings.polynomial.polynomial_ring import PolynomialRing
            P = PolynomialRing
            if isinstance(x, tuple):
                y = []
                for w in x:
                    y.append(str(w))
                x = tuple(y)
                
        else:
            from sage.rings.polynomial.polynomial_ring import PolynomialRing
            P = PolynomialRing
            x = (str(x),)

        if P is None:
            raise NotImplementedError
        
        if isinstance(x, tuple):
            v = x
        else:
            v = x.split(',')

        if len(v) > 1:
            R = P(self, len(v), names=v)
        else:
            R = P(self, x)

        return R

    def __xor__(self, n):
        raise RuntimeError, "Use ** for exponentiation, not '^', which means xor\n"+\
              "in Python, and has the wrong precedence."

    cdef _an_element_c_impl(self):  # override this in SageX
        return self.zero_element()
    
    def base_extend(self, R):
        """
        EXAMPLES:
            sage: QQ.base_extend(GF(7))
            Traceback (most recent call last):
            ...
            TypeError: no base extension defined
            sage: ZZ.base_extend(GF(7))
            Finite Field of size 7
        """
        if R.has_coerce_map_from(self):
            return R
        raise TypeError, 'no base extension defined'

    def category(self):
        """
        Return the category to which this ring belongs.

        EXAMPLES:
            sage: QQ['x,y'].category()
            Category of rings
        """
        from sage.categories.all import Rings
        return Rings()

    def ideal(self, x, coerce=True):
        """
        Return the ideal defined by x, i.e., generated by x.

        EXAMPLES:
            sage: R.<x,y> = QQ[]
            sage: R.ideal((x,y))
            Ideal (x, y) of Polynomial Ring in x, y over Rational Field
            sage: R.ideal(x+y^2)
            Ideal (y^2 + x) of Polynomial Ring in x, y over Rational Field
            sage: R.ideal([x^3,y^3+x^3])
            Ideal (x^3, y^3 + x^3) of Polynomial Ring in x, y over Rational Field
        """
        C = self._ideal_class_()
        return C(self, x, coerce=coerce)

    def __mul__(self, x):
        """
        Return the ideal x*R generated by x, where x is either an element
        or tuple or list of elements.

        EXAMPLES:
            sage: R.<x,y,z> = GF(7)[]
            sage: (x+y)*R
            Ideal (y + x) of Polynomial Ring in x, y, z over Finite Field of size 7
            sage: (x+y,z+y^3)*R
            Ideal (y + x, z + y^3) of Polynomial Ring in x, y, z over Finite Field of size 7
        """
        if isinstance(self, Ring):
            return self.ideal(x)
        else:
            return x.ideal(self)    # switched because this is Pyrex / extension class

    def _r_action(self, x):
        return self.ideal(x)

    def _ideal_class_(self):
        import sage.rings.ideal
        return sage.rings.ideal.Ideal

    def principal_ideal(self, gen, coerce=True):
        """
        Return the principal ideal generated by gen.

        EXAMPLES:
            sage: R.<x,y> = ZZ[]
            sage: R.principal_ideal(x+2*y)
            Ideal (2*y + x) of Polynomial Ring in x, y over Integer Ring
        """
        return self.ideal([gen], coerce=coerce)

    def unit_ideal(self):
        """
        Return the unit ideal of this ring.

        EXAMPLES:
            sage: Zp(7).unit_ideal()
            Principal ideal (1 + O(7^20)) of 7-adic Ring with capped relative precision 20
        """
        if self._unit_ideal is None:
            I = Ring.ideal(self, [self(1)], coerce=False)
            self._unit_ideal = I
            return I
        return self._unit_ideal

    def zero_ideal(self):
        """
        Return the zero ideal of this ring (cached).

        EXAMPLES:
            sage: ZZ.zero_ideal()
            Principal ideal (0) of Integer Ring
            sage: QQ.zero_ideal()
            Principal ideal (0) of Rational Field
            sage: QQ['x'].zero_ideal()
            Principal ideal (0) of Univariate Polynomial Ring in x over Rational Field

        The result is cached:
            sage: ZZ.zero_ideal() is ZZ.zero_ideal()
            True
        """
        if self._zero_ideal is None:
            I = Ring.ideal(self, [self(0)], coerce=False)
            self._zero_ideal = I
            return I
        return self._zero_ideal

    def zero_element(self):
        """
        Return the zero element of this ring (cached).

        EXAMPLES:
            sage: ZZ.zero_element()
            0
            sage: QQ.zero_element()
            0
            sage: QQ['x'].zero_element()
            0

        The result is cached:
            sage: ZZ.zero_element() is ZZ.zero_element()
            True
        """
        if self._zero_element is None:
            x = self(0)
            self._zero_element = x
            return x
        return self._zero_element

    def is_atomic_repr(self):
        """
        True if the elements have atomic string representations, in the sense
        that they print if they print at s, then -s means the negative of s.
        For example, integers are atomic but polynomials are not.

        EXAMPLES:
            sage: Zp(7).is_atomic_repr()
            False
            sage: QQ.is_atomic_repr()
            True
            sage: CDF.is_atomic_repr()
            False
        """
        return False

    def is_commutative(self):
        """
        Return True if this ring is commutative.

        EXAMPLES:
            sage: QQ.is_commutative()
            True
            sage: QQ['x,y,z'].is_commutative()
            True
            sage: Q.<i,j,k> = QuaternionAlgebra(QQ, -1,-1)
            sage: Q.is_commutative()
            False
        """
        raise NotImplementedError

    def is_field(self):
        """
        Return True if this ring is a field.

        EXAMPLES:
            sage: QQ.is_field()
            True
            sage: GF(9,'a').is_field()
            True
            sage: ZZ.is_field()
            False
            sage: QQ['x'].is_field()
            False
            sage: Frac(QQ['x']).is_field()
            True
        """
        raise NotImplementedError

    def is_exact(self):
        """
        Return True if elements of this ring are represented exactly, i.e.,
        there is no precision loss when doing arithmetic.

        NOTE: This defaults to true, so even if it does return True you have
        no guarantee (unless the ring has properly overloaded this).

        EXAMPLES:
            sage: QQ.is_exact()
            True
            sage: ZZ.is_exact()
            True
            sage: Qp(7).is_exact()
            False
            sage: Zp(7, type='capped-abs').is_exact()
            False
        """
        return True

    def is_subring(self, other):
        """
        Return True if the canonical map from self to other is injective.

        Raises a NotImplementedError if not known. 

        EXAMPLES:
            sage: ZZ.is_subring(QQ)
            True
            sage: ZZ.is_subring(GF(19))
            False
        """
        try:
            return self.Hom(other).natural_map().is_injective()
        except TypeError:
            return False

    def is_prime_field(self):
        r"""
        Return True if this ring is one of the prime fields $\Q$
        or $\F_p$.

        EXAMPLES:
            sage: QQ.is_prime_field()
            True
            sage: GF(3).is_prime_field()
            True
            sage: GF(9,'a').is_prime_field()
            False
            sage: ZZ.is_prime_field()
            False
            sage: QQ['x'].is_prime_field()
            False
            sage: Qp(19).is_prime_field()
            False
        """
        return False
        
    def is_finite(self):
        """
        Return True if this ring is finite.

        EXAMPLES:
            sage: QQ.is_finite()
            False
            sage: GF(2^10,'a').is_finite()
            True
            sage: R.<x> = GF(7)[]
            sage: R.is_finite()
            False
            sage: S.<y> = R.quo(x^2+1)
            sage: S.is_finite()
            True        
        """
        raise NotImplementedError

    def is_integral_domain(self):
        """
        Return True if this ring is an integral domain.

        EXAMPLES:
            sage: QQ.is_integral_domain()
            True
            sage: ZZ.is_integral_domain()
            True
            sage: ZZ['x,y,z'].is_integral_domain()
            True
            sage: Integers(8).is_integral_domain()
            False
            sage: Zp(7).is_integral_domain()
            True
            sage: Qp(7).is_integral_domain()
            True
        """
        return NotImplementedError

    def is_ring(self):
        """
        Return True since self is a ring.

        EXAMPLES:
            sage: QQ.is_ring()
            True
        """
        return True

    def is_noetherian(self):
        """
        Return True if this ring is Noetherian.

        EXAMPLES:
            sage: QQ.is_noetherian()
            True
            sage: ZZ.is_noetherian()
            True
        """
        raise NotImplementedError

    def characteristic(self):
        """
        Return the characteristic of this ring.

        EXAMPLES:
            sage: QQ.characteristic()
            0
            sage: GF(19).characteristic()
            19
            sage: Integers(8).characteristic()
            8
            sage: Zp(5).characteristic()
            0
        """
        raise NotImplementedError

    def order(self):
        """
        The number of elements of self.

        EXAMPLES:
            sage: GF(19).order()
            19
            sage: QQ.order()
            +Infinity
        """
        raise NotImplementedError
    
    def __hash__(self):
        """
        EXAMPLES:
            sage: hash(QQ)
            -11115808
            sage: hash(ZZ)
            554590422
        """
        return hash(self.__repr__())

    def zeta(self, n=2, all=False):
        """
        Return an n-th root of unity in self if there is one,
        or raise an ArithmeticError otherwise.

        INPUT:
            n -- positive integer
            all -- bool, default: False.  If True, return a list
                   of all n-th roots of 1)
        OUTPUT:
            -- element of self of finite order

        EXAMPLES:
            sage: QQ.zeta()
            -1
            sage: QQ.zeta(1)
            1
            sage: CyclotomicField(6).zeta()
            zeta6
            sage: CyclotomicField(3).zeta()
            zeta3
            sage: CyclotomicField(3).zeta().multiplicative_order()
            3
            sage: a = GF(7).zeta(); a
            3
            sage: a.multiplicative_order()
            6
            sage: a = GF(49,'z').zeta(); a
            z
            sage: a.multiplicative_order()
            48
            sage: a = GF(49,'z').zeta(2); a
            6
            sage: a.multiplicative_order()
            2
            sage: QQ.zeta(3)
            Traceback (most recent call last):
            ...
            ValueError: no n-th root of unity in rational field
            sage: Zp(7, prec=8).zeta()
            3 + 4*7 + 6*7^2 + 3*7^3 + 2*7^5 + 6*7^6 + 2*7^7 + O(7^8)
        """
        if n == 2:
            if all:
                return [self(-1)]
            else:
                return self(-1)
        elif n == 1:
            if all:
                return [self(1)]
            else:
                return self(1)
        else:
            f = self['x'].cyclotomic_polynomial(n)
            if all:
                return [-P[0] for P, e in f.factor() if P.degree() == 1]
            for P, e in f.factor():
                if P.degree() == 1:
                    return -P[0]
            raise ArithmeticError, "no %s-th root of unity in self"%n

    def zeta_order(self):
        """
        Return the order of the distinguished root of unity in self.
        
        EXAMPLES:
            sage: CyclotomicField(19).zeta_order()
            19
            sage: GF(19).zeta_order()
            18
            sage: GF(5^3,'a').zeta_order()
            124
            sage: Zp(7, prec=8).zeta_order()
            6
        """
        return self.zeta().multiplicative_order()

    def random_element(self, bound=2):
        """
        Return a random integer coerced into this ring, where the
        integer is chosen uniformly from the interval [-bound,bound].

        INPUT:
            bound -- integer (default: 2)

            
        ALGORITHM:
             -- uses numpy's randint.

        EXAMPLES:
            sage: [QQ['x,y'].random_element() for _ in range(5)]
            [-2, -2, 0, -1, -1]
        """
        return self(randint(-bound,bound))        


cdef class CommutativeRing(Ring):
    """
    Generic commutative ring.
    """
    def fraction_field(self):
        """
        Return the fraction field of self.

        EXAMPLES:
            sage: R = Integers(389)['x,y']
            sage: Frac(R)
            Fraction Field of Polynomial Ring in x, y over Ring of integers modulo 389
            sage: R.fraction_field()
            Fraction Field of Polynomial Ring in x, y over Ring of integers modulo 389            
        """
        if not self.is_integral_domain():
            raise TypeError, "self must be an integral domain."
        if self.__fraction_field is not None:
            return self.__fraction_field
        else:
            import sage.rings.fraction_field
            K = sage.rings.fraction_field.FractionField_generic(self)
            self.__fraction_field = K
            K._assign_names(self.variable_names())
        return self.__fraction_field

    def __pow__(self, n, _):
        """
        Return the free module of rank $n$ over this ring.

        EXAMPLES:
            sage: QQ^5
            Vector space of dimension 5 over Rational Field
            sage: Integers(20)^1000
            Ambient free module of rank 1000 over Ring of integers modulo 20
        """
        import sage.modules.all 
        return sage.modules.all.FreeModule(self, n)
    
    def is_commutative(self):
        """
        Return True, since this ring is commutative.

        EXAMPLES:
            sage: QQ.is_commutative()
            True
            sage: ZpCA(7).is_commutative()
            True
            sage: A = QuaternionAlgebra(QQ, -1, -3, names=('i','j','k')); A
            Quaternion algebra with generators (i, j, k) over Rational Field
            sage: A.is_commutative()
            False
        """
        return True
    
    def krull_dimension(self):
        """
        Return the Krull dimension if this commutative ring.

        The Krull dimension is the length of the longest ascending chain
        of prime ideals.

        EXAMPLES:
        """
        raise NotImplementedError

    def ideal_monoid(self):
        """
        Return the monoid of ideals of this ring.

        EXAMPLES:
        """
        if self.__ideal_monoid is not None:
            return self.__ideal_monoid
        else:
            from sage.rings.ideal_monoid import IdealMonoid
            M = IdealMonoid(self)
            #try:
            self.__ideal_monoid = M
            #except AttributeError:   # for pyrex classes
            #    pass
            return M

    def quotient(self, I, names=None):
        """
        Create the quotient of R by the ideal I.

        INPUT:
            R -- a commutative ring
            I -- an ideal of R
            names -- (optional) names of the generators of the quotient (if there are multiple generators,
                     you can specify a single character string and the generators are named
                     in sequence starting with 0).

        EXAMPLES:
            sage: R.<x> = PolynomialRing(ZZ)
            sage: I = R.ideal([4 + 3*x + x^2, 1 + x^2])
            sage: S = R.quotient(I, 'a')
            sage: S.gens()
            (a,)

            sage: R.<x,y> = PolynomialRing(QQ,2)
            sage: S.<a,b> = R.quotient((x^2, y))
            sage: S
            Quotient of Polynomial Ring in x, y over Rational Field by the ideal (x^2, y)
            sage: S.gens()
            (a, 0)
            sage: a == b
            False
        """
        import sage.rings.quotient_ring
        return sage.rings.quotient_ring.QuotientRing(self, I, names=names)

    def quo(self, I, names=None):
        """
        Create the quotient of R by the ideal I.

        This is a synonym for self.quotient(...)

        INPUT:
            R -- a commutative ring
            I -- an ideal of R

        EXAMPLES:
            sage: R.<x,y> = PolynomialRing(QQ,2)
            sage: S.<a,b> = R.quo((x^2, y))
            sage: S
            Quotient of Polynomial Ring in x, y over Rational Field by the ideal (x^2, y)
            sage: S.gens()
            (a, 0)
            sage: a == b
            False
        """
        return self.quotient(I, names=names)

    def __div__(self, I):
        """
        Dividing one ring by another is not supported because there is
        no good way to specify generator names.
        
        EXAMPLES:
        """
        raise TypeError, "Use self.quo(I) or self.quotient(I) to construct the quotient ring."
        #return self.quotient(I, names=None)

    def quotient_ring(self, I, names=None):
        """
        Return the quotient of self by the ideal I of self.
        (Synonym for self.quotient(I).)

        EXAMPLES:
        """
        return self.quotient(I, names)
    

cdef class IntegralDomain(CommutativeRing):
    """
    Generic integral domain class.
    """
    def is_integral_domain(self):
        """
        Return True, since this ring is an integral domain.

        EXAMPLES:
        """
        return True
    
    def is_field(self):
        """
        Return True if this ring is a field.

        EXAMPLES:        
        """
        if self.is_finite():
            return True
        raise NotImplementedError, "unable to determine whether or not is a field."

cdef class NoetherianRing(CommutativeRing):
    """
    Generic Noetherian ring class.

    A Noetherian ring is a commutative ring in which every ideal is
    finitely generated.
    """
    def is_noetherian(self):
        """
        Return True since this ring is Noetherian.

        EXAMPLES:        
        """
        return True

cdef class DedekindDomain(IntegralDomain):
    """
    Generic Dedekind domain class.

    A Dedekind domain is a Noetherian integral domain of Krull
    dimension one that is integrally closed in its field of fractions.
    """
    def krull_dimension(self):
        """
        Return 1 since Dedekind domains have Krull dimension 1.

        EXAMPLES:        
        """
        return 1

    def is_integrally_closed(self):
        """
        Return True since Dedekind domains are integrally closed.
        
        EXAMPLES:        
        """
        return True

    def integral_closure(self):
        """
        Return self since Dedekind domains are integrally closed.

        EXAMPLES:        
        """
        return self

    def is_noetherian(self):
        """
        Return True since Dedekind domains are noetherian.

        EXAMPLES:        
        """
        return True
    

cdef class PrincipalIdealDomain(IntegralDomain):
    """
    Generic principal ideal domain.
    """
    def class_group(self):
        """
        Return the trivial group, since the class group of a PID is trivial.

        EXAMPLES:
            sage: QQ.class_group()
            Trivial Abelian Group
        """
        from sage.groups.abelian_gps.abelian_group import AbelianGroup
        return AbelianGroup([])

    def gcd(self, x, y, coerce=True):
        """
        Return the greatest common divisor of x and y, as elements
        of self.

        EXAMPLES:        
        """
        if coerce:
            x = self(x)
            y = self(y)
        return x.gcd(y)
    

cdef class EuclideanDomain(PrincipalIdealDomain):
    """
    Generic Euclidean domain class.
    """
    def parameter(self):
        """
        Return an element of degree 1.

        EXAMPLES:        
        """
        raise NotImplementedError
        
def is_Field(x):
    """
    Return True if x is a field.

    EXAMPLES:
        sage: is_Field(QQ)
        True
        sage: is_Field(ZZ)
        False
        sage: is_Field(pAdicField(2))
        True
        sage: is_Field(5)
        False
    """
    return bool(isinstance(x, Field) or (hasattr(x, 'is_field') and x.is_field()))

cdef class Field(PrincipalIdealDomain):
    """
    Generic field
    """
    def category(self):
        """
        Return the category of this field, which is the category
        of fields.

        EXAMPLES:
        """
        from sage.categories.all import Fields
        return Fields()
        
    def fraction_field(self):
        """
        Return the fraction field of self.

        EXAMPLES:
        """
        return self

    def divides(self, x, y, coerce=True):
        """
        Return True if x divides y in this field (usually True in a
        field!).  If coerce is True (the default), first coerce x and
        y into self.

        EXAMPLES:
        """
        if coerce:
            x = self(x)
            y = self(y)
        if x.is_zero():
            return y.is_zero()
        return True

    def ideal(self, gens):
        """
        Return the ideal generated by gens.

        EXAMPLES:
        """
        if not isinstance(gens, (list, tuple)):
            gens = [gens]
        for x in gens:
            if not self(x).is_zero():
                return self.unit_ideal()
        return self.zero_ideal()

    def integral_closure(self):
        """
        Return this field, since fields are integrally closed in their
        fraction field.

        EXAMPLES:
        
        """
        return self

    def is_field(self):
        """
        Return True since this is a field.
        """
        return True

    def is_integrally_closed(self):
        """
        Return True since fields are integrally closed in their
        fraction field.

        EXAMPLES:
        
        """
        return True

    def is_noetherian(self):
        """
        Return True since fields are noetherian rings.

        EXAMPLES:
        
        """
        return True

    def krull_dimension(self):
        """
        Return the Krull dimension of this field, which is 0.

        EXAMPLES:
        
        """
        return 0

    def prime_subfield(self):
        """
        Return the prime subfield of self.

        EXAMPLES:
            sage: k = GF(9, 'a')
            sage: k.prime_subfield()
            Finite Field of size 3
        """
        if self.characteristic() == 0:
            import sage.rings.rational_field
            return sage.rings.rational_field.RationalField()
        else:
            import sage.rings.finite_field
            return sage.rings.finite_field.FiniteField(self.characteristic())

cdef class FiniteFieldIterator:
    cdef object iter
    cdef FiniteField parent

    def __init__(self,FiniteField parent):
        self.parent = parent
        self.iter =iter(self.parent.vector_space())

    def __next__(self):
        return self.parent(self.iter.next())

cdef class FiniteField(Field):
    """
    """
    
    def __init__(self):
        """
        EXAMPLES:
            sage: K = GF(7); K
            Finite Field of size 7
            sage: loads(K.dumps()) == K
            True
            sage: GF(7^10, 'a')
            Finite Field in a of size 7^10
            sage: K = GF(7^10, 'a'); K
            Finite Field in a of size 7^10
            sage: loads(K.dumps()) == K
            True
        """
        raise NotImplementedError
        
    def _latex_(self):
        r"""
        EXAMPLES:
            sage: latex(GF(81, 'a'))
            \mathbf{F}_{3^{4}}
            sage: latex(GF(3))
            \mathbf{F}_{3}
        """
        if self.degree() > 1:
            e = "^{%s}"%self.degree()
        else:
            e = ""
        return "\\mathbf{F}_{%s%s}"%(self.characteristic(), e)

    def _gap_init_(self):
        return 'GF(%s)'%self.order()

    def _magma_init_(self):
        return 'GF(%s)'%self.order()
    
    def __cmp__(self, other):
        """
        Compares this finite field with other.

        WARNING: The notation of equality of finite fields in SAGE is
        currently not stable, i.e., it may change in a future version.
        
        EXAMPLES:
            sage: FiniteField(3**2, 'c') == FiniteField(3**3, 'c')
            False
            sage: FiniteField(3**2, 'c') == FiniteField(3**2, 'c')
            True

        The variable name is (currently) relevant for comparison of finite fields:
            sage: FiniteField(3**2, 'c') == FiniteField(3**2, 'd')
            False
        """
        if self is other: return 0
        if not isinstance(other, FiniteField):
            return -1
        c = cmp(self.characteristic(), other.characteristic())
        if c:
            return c
        c = cmp(self.order(), other.order())
        if c:
            return c
        c = cmp(self.order(), other.order())
        if c:
            return c
        if self.degree() == 1:
            return 0
        return cmp(self.polynomial('x'), other.polynomial('x'))

##     def __getstate__(self):
##         d = []
##         try:
##             d = d + list(self.__dict__.iteritems())
##         except AttributeError:
##             pass
##         d = d + list(Field.__getstate__(self).iteritems())
##         d = dict(d)
##         #d['__multiplicative_generator'] = self.__multiplicative_generator
##         #d['__polynomial_ring'] = self.__polynomial_ring
##         #d['__vector_space'] = self.__vector_space
##         return d

##     def __setstate__(self,d):
##         try:
##             self.__dict__ = d
##         except AttributeError:
##             pass
##         Field.__setstate__(self,d)
##         self.__multiplicative_generator = d['__multiplicative_generator']
##         self.__polynomial_ring = d['__polynomial_ring']
##         self.__vector_space = d['__vector_space']

##     def __getitem__(self, n):
##         """
##         Returns $n$-th element of the field.  The ordering is
##         not randomized (though it could conceivably change from
##         one version of SAGE to another).

##         EXAMPLES:
##             sage: k = GF(8, 'a')
##             sage: k[0]
##             0
##             sage: k[1]
##             1
##             sage: k[7]
##             a^2 + a + 1
##         """
##         if n < 0 or n >= self.order():
##             raise IndexError, "n (=%s) must be between 0 and the order %s of the field."%(\
##                 n, self.order())
##         V = self.vector_space()
##         return self(V[n])

    def __iter__(self):
        return FiniteFieldIterator(self)

    def gen(self):
        raise NotImplementedError

    def zeta_order(self):
        """
        Return the order of the distinguished root of unity in self.

        EXAMPLES:
        """
        return self.order() - 1

    def zeta(self, n=None):
        """
        Returns an element of multiplicative order n in this this
        finite field, if there is one.  Raises a ValueError if there
        is not.

        EXAMPLES:
            sage: k = GF(7)
            sage: k.zeta()
            3
            sage: k.zeta().multiplicative_order()
            6
            sage: k.zeta(3)
            2
            sage: k.zeta(3).multiplicative_order()
            3
            sage: k = GF(49, 'a')
            sage: k.zeta().multiplicative_order()
            48
            sage: k.zeta(6)
            3
        """
        z = self.multiplicative_generator()
        if n is None:
            return z
        else:
            import sage.rings.integer
            n = sage.rings.integer.Integer(n)
            m = z.multiplicative_order()
            if m % n != 0:
                raise ValueError, "No %sth root of unity in self"%n
            return z**(m.__floordiv__(n))

    def multiplicative_generator(self):
        """
        Return a generator for the multiplicative group of this field.
        The generator is not randomized, though it could change from
        one version of SAGE to another.

        EXAMPLES:
            sage: k = GF(997)
            sage: k.multiplicative_generator()
            7
            sage: k = GF(11^3, name='a')
            sage: k.multiplicative_generator()
            a
        """
        from sage.rings.arith import primitive_root
        
        if self.__multiplicative_generator is not None:
            return self.__multiplicative_generator
        else:
            if self.degree() == 1:
                self.__multiplicative_generator = self(primitive_root(self.order()))
                return self.__multiplicative_generator
            n = self.order() - 1
            a = self.gen(0)
            if a.multiplicative_order() == n:
                self.__multiplicative_generator = a
                return a
            for a in self:
                if a == 0:
                    continue
                if a.multiplicative_order() == n:
                    self.__multiplicative_generator = a
                    return a

    def ngens(self):
        """
        The number of generators of the finite field.  Always 1.

        EXAMPLES:
            sage: k = FiniteField(3^4, 'b')
            sage: k.ngens()
            1
        """
        return 1
        
    def is_field(self):
        """
        Returns whether or not the finite field is a field, i.e.,
        always returns True.

        EXAMPLES:
            sage: k.<a> = FiniteField(3^4)
            sage: k.is_field()
            True
        """
        return True

    def is_finite(self):
        """
        Return True since a finite field is finite.

        EXAMPLES:

        """
        return True

    def order(self):
        """
        Return the order of this finite field.

        EXAMPLES:

        """
        raise NotImplementedError
    
    def cardinality(self):
        """
        Return the order of this finite field (same as self.order()).

        EXAMPLES:
        """
        return self.order()
        
    def unit_group_exponent(self):
        """
        The exponent of the unit group of the finite field.  For a
        finite field, this is always the order minus 1.

        EXAMPLES:
            sage: k = GF(2^10, 'a')
            sage: k.order()
            1024
            sage: k.unit_group_exponent()
            1023
        """
        return self.order() - 1
    

    def random_element(self, bound=None):
        """
        A random element of the finite field.

        INPUT:
            bound -- ignored

        EXAMPLES:
            sage.: k = GF(2^10, 'a')
            sage.: k.random_element()
            a^9 + a
        """
        if self.degree() == 1:
            return self(randrange(self.order()))
        v = self.vector_space().random_element()
        return self(v)

    def polynomial(self):
        """
        Return the defining polynomial of this finite field.

        EXAMPLES:
        """
        raise NotImplementedError

    def polynomial_ring(self):
        """
        Returns the polynomial ring over the prime subfield in the
        same variable as this finite field.
        
        EXAMPLES:
            sage: k.<alpha> = FiniteField(3^4)
            sage: k.polynomial_ring()
            Univariate Polynomial Ring in alpha over Finite Field of size 3
        """
        from sage.rings.polynomial.polynomial_ring import PolynomialRing
        from sage.rings.finite_field import GF
        
        if self.__polynomial_ring is not None:
            return self.__polynomial_ring
        else:
            self.__polynomial_ring = PolynomialRing(
                GF(self.characteristic()), self.variable_name())
            return self.__polynomial_ring

    def vector_space(self):
        """
        Return the vector space over the prime subfield isomorphic
        to this finite field as a vector space.
        
        EXAMPLES:
        """
        if self.__vector_space is not None:
            return self.__vector_space
        else:
            import sage.modules.all
            V = sage.modules.all.VectorSpace(self.prime_subfield(),self.degree())
            self.__vector_space = V            
            return V

def is_FiniteField(x):
    return IS_INSTANCE(x, FiniteField)


cdef class Algebra(Ring):
    """
    Generic algebra
    """
    def __init__(self, base_ring, names=None, normalize=True):
        ParentWithGens.__init__(self, base_ring, names=names, normalize=normalize)

    def characteristic(self):
        """
        Return the characteristic of this algebra, which is the same
        as the characteristic of its base ring.

        EXAMPLES:
        
        """
        return self.base_ring().characteristic()
    

cdef class CommutativeAlgebra(CommutativeRing):
    """
    Generic commutative algebra
    """
    def __init__(self, base_ring, names=None, normalize=True):
        if not isinstance(base_ring, CommutativeRing):
            raise TypeError, "base ring must be a commutative ring"
        ParentWithGens.__init__(self, base_ring, names=names, normalize=normalize)

    def is_commutative(self):
        """
        Return True since this algebra is commutative.
        
        EXAMPLES:
        """
        return True


def is_Ring(x):
    """
    Return true if x is a ring.

    EXAMPLES:
        sage: is_Ring(ZZ)
        True
    """
    return bool(isinstance(x, Ring))

    
