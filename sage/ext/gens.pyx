r"""
Base class for objects with generators

Many objects in SAGE are equipped with generators, which are special
elements of the object.  For example, the polynomial ring $\Z[x,y,z]$
is generated by $x$, $y$, and $z$.  In SAGE the $i$th generator of an
object \code{X} is obtained using the notation \code{X.gen(i)}.  From
the SAGE interactive prompt, the shorthand notation \code{X.i} is also
allowed.

A class that derives from Generators \emph{must} define a gen(i)
function.

The \code{gens} function returns a tuple of all generators, the
\code{ngens} function returns the number of generators, and the
\code{assign_names}, \code{name} and \code{names} functions allow one
to change or obtain the way generators are printed. (They \emph{only}
affect printing!)

The following examples illustrate these functions in the context of
multivariate polynomial rings and free modules.

EXAMPLES:
    sage: R = MPolynomialRing(IntegerRing(), 3)
    sage: R.ngens()
    3
    sage: R.gen(0)
    x0
    sage: R.gens()
    (x0, x1, x2)
    sage: R.variable_names()
    ('x0', 'x1', 'x2')
    sage: R.assign_names(['a', 'b', 'c'])
    sage: R
    Polynomial Ring in a, b, c over Integer Ring

This example illustrates generators for a free module over $\Z$.

    sage: M = FreeModule(IntegerRing(), 4)
    sage: M
    Ambient free module of rank 4 over the principal ideal domain Integer Ring
    sage: M.ngens()
    4
    sage: M.gen(0)
    (1, 0, 0, 0)
    sage: M.gens()
    ((1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 1, 0), (0, 0, 0, 1))

The names of the generators of a free module aren't really used anywhere,
but they are still defined:

    sage: M.variable_names()   
    ('x0', 'x1', 'x2', 'x3')
"""

#*****************************************************************************
#       Copyright (C) 2005 William Stein <wstein@gmail.com>
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

import sage.misc.defaults
import gens_py

# Classes that derive from Generators must define
# gen(i) and ngens() functions.  It is also good
# if they define gens() to return all gens, but this
# is not necessary.

cdef class Generators(sage_object.SageObject):
    # Derived class *must* define ngens method.
    def ngens(self):
        raise NotImplementedError, "Number of generators not known."

    # Derived class *must* define gen method.
    def gen(self, i=0):
        raise NotImplementedError, "i-th generator not known."
            
    def __getitem__(self, n):
        return self.list()[int(n)]

    def __getslice__(self, n, m):
        return self.list()[int(n):int(m)]

    def __len__(self):
        return len(self.list())

    def list(self):
        """
        Return a list of all elements in this object, if possible (the
        object must define an iterator).
        """
        if self.__list != None:
            return self.__list
        else:
            self.__list = list(self.__iter__())
        return self.__list

    def objgens(self, names=None):
        """
        Return self and the generators of self as a tuple, possibly re-assigning
        the names of self.

        INPUT:
            names -- tuple or string

        OUTPUT:
            self  -- this object
            tuple -- self.gens()
        
        EXAMPLES:
            sage: R, x = MPolynomialRing(QQ,3).objgens()
            sage: R
            Polynomial Ring in x0, x1, x2 over Rational Field
            sage: x
            (x0, x1, x2)
            sage: R, (a,b,c) = R.objgens('abc')
            sage: a^2 + b^2 + c^2
            c^2 + b^2 + a^2
        """
        if not names is None:
            self.assign_names(names)
        return self, self.gens()

    def objgen(self, names=None):
        """
        Return self and the generator of self, possibly re-assigning
        the name of this generator.

        INPUT:
            names -- tuple or string

        OUTPUT:
            self  -- this object
            an object -- self.gen()
        
        EXAMPLES:
            sage: R, x = PolynomialRing(QQ).objgen()
            sage: R
            Univariate Polynomial Ring in x over Rational Field
            sage: x
            x
            sage: S, a = (R/(x^2+1)).objgen('a')
            sage: S
            Univariate Quotient Polynomial Ring in a over Rational Field with modulus x^2 + 1
        """
        if not names is None:
            self.assign_names(names)
        return self, self.gen()

    def gens(self):
       """
       Return a tuple whose entries are the generators for this
       object, in order.
       """
       cdef int i, n
       if self.__gens != None:
           return self.__gens
       else:
           v = []
           n = self.ngens()
           for i from 0 <= i < n:
               v.append(self.gen(i))
           self.__gens = tuple(v)
           return self.__gens

    def gens_dict(self):
        r"""
        Return a dictionary whose entries are \code{var_name:variable}.
        """
        if self.__gens_dict != None:
            return self.__gens_dict
        else:
            v = {}
            for x in self.gens():
                v[str(x)] = x
            self.__gens_dict = v
            return v
            
    def __certify_names(self, names):
        v = []
        for N in names:
            if not isinstance(N, str):
                raise TypeError, "variable name must be a string but %s isn't"%N
            N = N.strip()
            if len(N) == 0:
                raise ValueError, "variable name must be nonempty"
            if not N.isalnum():
                raise ValueError, "variable names must be alphanumeric, but one is '%s' which is not."%N
            v.append(N)
        return tuple(v)
    
    def assign_names(self, names=None):
        if names is None: return
        if isinstance(names, str) and names.find(',') != -1:
            names = names.split(',')
        if isinstance(names, str) and self.ngens() > 1 and len(names) == self.ngens():
            names = tuple(names)
        if isinstance(names, str):
            name = names
            names = sage.misc.defaults.variable_names(self.ngens(), name)
            names = self.__certify_names(names)
            latex_names = sage.misc.defaults.latex_variable_names(self.ngens(), name)
        else:
            names = self.__certify_names(names)
            if not isinstance(names, (list, tuple)):
                raise TypeError, "names must be a list or tuple of strings"
            for x in names:
                if not isinstance(x,str):
                    raise TypeError, "names must consist of strings"
            if len(names) != self.ngens():
                raise IndexError, "the number of names must equal the number of generators"
            latex_names = names
        self.__names = tuple(names)
        self.__latex_names = tuple(latex_names)

    def _names_from_obj(self, X):
        if self.__names != None and self.__latex_names != None:
            old = (self.__names, self.__latex_names)
        else:
            old = None
        if X is None:
            self.__names = None
            self.__latex_names = None
            return old
        if not isinstance(X, tuple):
            if X.__names!=None and X.__latex_names!=None:
                X = (X.__names, X.__latex_names)
            else:
                return old
        (self.__names, self.__latex_names) =  X        
        return old

    def variable_names(self):
        if self.__names!=None:
            return self.__names
        else:
            self.__names = sage.misc.defaults.variable_names(self.ngens())
            return self.__names

    def latex_variable_names(self):
        if self.__latex_names != None:
            return self.__latex_names
        else:
            self.__latex_names = sage.misc.defaults.latex_variable_names(self.ngens())
            return self.__latex_names
        
    def variable_name(self):
        return self.variable_names()[0]

    def latex_name(self):
        return self.variable_name()

    def __getstate__(self):
        d = []
        try:
            d = list(self.__dict__.copy().iteritems()) # so we can add elements
        except AttributeError:
            pass
        d = dict(d)
        d['__gens'] = self.__gens
        d['__gens_dict'] = self.__gens_dict
        d['__list'] = self.__list
        d['__names'] = self.__names
        d['__latex_names'] = self.__latex_names
        try:
            d['__generator_orders'] = self.__generator_orders
        except AttributeError:
            pass
        
        return d

    def __setstate__(self,d):
        try:
            self.__dict__ = d
            self.__generator_orders = d['__generator_orders']
        except (AttributeError,KeyError):
            pass
        self.__gens = d['__gens']
        self.__gens_dict = d['__gens_dict']
        self.__list = d['__list']
        self.__names = d['__names']
        self.__latex_names = d['__latex_names']
        

    #################################################################################
    # Morphisms of objects with generators
    #################################################################################

    def _is_valid_homomorphism_(self, codomain, im_gens):
        r"""
        Return True if \code{im_gens} defines a valid homomorphism
        from self to codomain; otherwise return False.

        If determining whether or not a homomorphism is valid has not
        been implemented for this ring, then a NotImplementedError exception
        is raised.
        """
        raise NotImplementedError, "Verification of correctness of homomorphisms from %s not yet implmented."%self

    def hom(self, im_gens, codomain=None, check=True):
        r"""
        Return the unique homomorphism from self to codomain that
        sends \code{self.gens()} to the entries of \code{im_gens}.
        Raises a TypeError if there is no such homomorphism.

        INPUT:
            im_gens -- the images in the codomain of the generators of
                       this object under the homomorphism
            codomain -- the codomain of the homomorphism
            check -- whether to verify that the images of generators extend
                     to define a map (using only canonical coercisions).

        OUTPUT:
            a homomorphism self --> codomain

        \note{As a shortcut, one can also give an object X instead of
        \code{im_gens}, in which case return the (if it exists)
        natural map to X.}

        EXAMPLE: Polynomial Ring
        We first illustrate construction of a few homomorphisms
        involving a polynomial ring.
        
            sage: R, x = PolynomialRing(ZZ).objgen()
            sage: f = R.hom([5], QQ)
            sage: f(x^2 - 19)
            6

            sage: R, x = PolynomialRing(QQ).objgen()
            sage: f = R.hom([5], GF(7))
            Traceback (most recent call last):
            ...
            TypeError: images do not define a valid homomorphism

            sage: R, x = PolynomialRing(GF(7)).objgen()
            sage: f = R.hom([3], GF(49))
            sage: f
            Ring morphism:
              From: Univariate Polynomial Ring in x over Finite Field of size 7
              To:   Finite Field in a of size 7^2
              Defn: x |--> 3
            sage: f(x+6)
            2
            sage: f(x^2+1)
            3

        EXAMPLE: Natural morphism
            sage: f = ZZ.hom(GF(5))
            sage: f(7)
            2
            sage: f
            Coercion morphism:
              From: Integer Ring
              To:   Finite Field of size 5

        There might not be a natural morphism, in which case a TypeError exception is raised. 
            sage: QQ.hom(ZZ)
            Traceback (most recent call last):
            ...
            TypeError: Natural coercion morphism from Rational Field to Integer Ring not defined.
        """
        if not isinstance(im_gens, (tuple, list)):
            return self.Hom(im_gens).natural_map()
        if codomain is None:
            from sage.structure.all import Sequence
            im_gens = Sequence(im_gens)
            codomain = im_gens.universe()
        return self.Hom(codomain)(im_gens, check=check)


cdef class MultiplicativeAbelianGenerators(Generators):
    def generator_orders(self):
        if self.__generator_orders != None:
            return self.__generator_orders
        else:
            g = []
            for x in self.gens():
                g.append(x.multiplicative_order())
            self.__generator_orders = g
            return g

    def __iter__(self):
        """
        Return an iterator over the elements in this object.
        """
        return gens_py.multiplicative_iterator(self)

        
    
cdef class AdditiveAbelianGenerators(Generators):
    def generator_orders(self):
        if self.__generator_orders != None:
            return self.__generator_orders
        else:
            g = []
            for x in self.gens():
                g.append(x.additive_order())
            self.__generator_orders = g
            return g

    def __iter__(self):
        """
        Return an iterator over the elements in this object.
        """
        return gens_py.abelian_iterator(self)
