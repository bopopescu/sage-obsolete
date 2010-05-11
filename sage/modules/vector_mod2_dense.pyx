"""
Vectors with elements in GF(2).

AUTHOR:

- Martin Albrecht (2009-12): initial implementation

EXAMPLES::

    sage: VS = GF(2)^3
    sage: e = VS.random_element(); e
    (1, 0, 0)
    sage: f = VS.random_element(); f
    (0, 1, 1)
    sage: e + f
    (1, 1, 1)
"""

##############################################################################
#       Copyright (C) 2009 Martin Albrecht <M.R.Albrecht@rhul.ac.uk>
#  Distributed under the terms of the GNU General Public License (GPL)
#  The full text of the GPL is available at:
#                  http://www.gnu.org/licenses/
##############################################################################

include '../ext/interrupt.pxi'
include '../ext/stdsage.pxi'

from sage.rings.finite_rings.integer_mod cimport IntegerMod_int, IntegerMod_abstract
from sage.rings.integer cimport Integer

from sage.structure.element cimport Element, ModuleElement, RingElement, Vector

cimport free_module_element
from free_module_element import vector

from sage.libs.m4ri cimport *

cdef class Vector_mod2_dense(free_module_element.FreeModuleElement):
    cdef _new_c(self):
        """
        EXAMPLE::

            sage: VS = VectorSpace(GF(2),3)
            sage: VS([0,0,1])
            (0, 0, 1)
            sage: type(_)
            <type 'sage.modules.vector_mod2_dense.Vector_mod2_dense'>
        """
        cdef Vector_mod2_dense y
        y = PY_NEW(Vector_mod2_dense)
        y._init(self._degree, self._parent)
        return y

    cdef bint is_dense_c(self):
        """
        EXAMPLE::

            sage: VS = VectorSpace(GF(2),3)
            sage: VS([0,0,1]).is_dense()
            True
        """
        return 1
    
    cdef bint is_sparse_c(self):
        """
        EXAMPLE::

            sage: VS = VectorSpace(GF(2),3)
            sage: VS([0,0,1]).is_sparse()
            False
        """
        return 0

    def __copy__(self):
        """
        EXAMPLE::

            sage: VS = VectorSpace(GF(2),10^4)
            sage: v = VS.random_element()
            sage: w = copy(v) 
            sage: w == v
            True
            sage: v[:10]
            (1, 0, 0, 0, 1, 1, 1, 0, 0, 1)
            sage: w[:10]
            (1, 0, 0, 0, 1, 1, 1, 0, 0, 1)
        """
        cdef Vector_mod2_dense y = self._new_c()
        if self._degree:
            mzd_copy(y._entries, self._entries)
        return y

    cdef _init(self, Py_ssize_t degree, parent):
        """
        EXAMPLE::

            sage: VS = VectorSpace(GF(2),3)
            sage: VS([0,0,1])
            (0, 0, 1)
            sage: type(_)
            <type 'sage.modules.vector_mod2_dense.Vector_mod2_dense'>
        """
        self._degree = degree
        self._parent = parent
        self._base_ring = parent.base_ring()
        self._entries = mzd_init(1, degree)
        if self._entries == NULL:
            raise MemoryError("Allocation of Vector_mod2_dense failed.")
        
    def __cinit__(self, parent=None, x=None, coerce=True, copy=True):
        """
        EXAMPLE::

            sage: VS = VectorSpace(GF(2),3)
            sage: VS((0,0,1/3))
            (0, 0, 1)
            sage: type(_)
            <type 'sage.modules.vector_mod2_dense.Vector_mod2_dense'>
        """
        self._entries = NULL
        self._is_mutable = 1
        if not parent is None:
            self._init(parent.degree(), parent)

    def __init__(self, parent, x, coerce=True, copy=True):
        """
        EXAMPLE::

            sage: VS = VectorSpace(GF(2),3)
            sage: VS((0,0,1/3))
            (0, 0, 1)
            sage: type(_)
            <type 'sage.modules.vector_mod2_dense.Vector_mod2_dense'>
            sage: VS((0,0,int(3)))
            (0, 0, 1)
            sage: VS((0,0,3))
            (0, 0, 1)
            sage: VS((0,0,GF(2)(1)))
            (0, 0, 1)

        TESTS:

        Check that ticket #8601 is fixed::

            sage: VS = VectorSpace(GF(2), 3)
            sage: VS((-1,-2,-3))
            (1, 0, 1)
            sage: V = VectorSpace(GF(2), 2)
            sage: V([1,3])
            (1, 1)
            sage: V([1,-3])
            (1, 1)
        """
        cdef Py_ssize_t i
        cdef int xi
        if isinstance(x, (list, tuple)):
            if len(x) != self._degree:
                raise TypeError("x must be a list of the right length")
            for i from 0 <= i < self._degree:
                if PY_TYPE_CHECK(x[i],IntegerMod_int) or PY_TYPE_CHECK(x[i],int) or PY_TYPE_CHECK(x[i],Integer):
                    xi = x[i]
                    # the if/else statement is because in some compilers, (-1)%2 is -1
                    mzd_write_bit(self._entries, 0, i, 0 if xi%2==0 else 1)
                else:
                    mzd_write_bit(self._entries, 0, i, x[i]%2)
            return
        if x != 0:
            raise TypeError("can't initialize vector from nonzero non-list")
        else:
            for i from 0 <= i < self._degree:
                mzd_set_ui(self._entries, 0)
                
    def __dealloc__(self):
        """
        EXAMPLE::

        sage: VS = VectorSpace(GF(2),10^3)
        sage: import gc
        sage: for i in range(10):
        ...      v = VS.random_element()
        ...      del v
        ...      _ = gc.collect()
        """
        if self._entries:
            mzd_free(self._entries)

    cdef int _cmp_c_impl(left, Element right) except -2:
        """
        EXAMPLES::
            sage: v = vector(GF(2), [0,0,0,0])
            sage: v == 0
            True
            sage: v == 1
            False
            sage: v == v
            True
            sage: w = vector(GF(2), [1,0,0,0])
            sage: w < v
            False
            sage: w > v
            True
        """
        if left._degree == 0:
            return 0
        return mzd_cmp(left._entries, (<Vector_mod2_dense>right)._entries)

    def __len__(self):
        """
        EXAMPLES::

            sage: len(vector(GF(2),[0,0,1,1,1]))
            5
        """
        return self._degree

    def __setitem__(self, Py_ssize_t i, x):
        """
        EXAMPLES::

            sage: VS = VectorSpace(GF(2),4)
            sage: v = VS.random_element(); v
            (1, 0, 0, 0)
            sage: v[0] = 0; v
            (0, 0, 0, 0)
            sage: v[4] = 0
            Traceback (most recent call last):
            ...
            IndexError: Index '4' out of bound.
        """
        if not self._is_mutable:
            raise ValueError("vector is immutable; please change a copy instead (use copy())")
        cdef IntegerMod_int n
        n = self.base_ring()(x)
        if i < 0 or i >= self._degree:
            raise IndexError("Index '%s' out of bound."%(i))
        else:
            mzd_write_bit(self._entries, 0, i, n)
            
    def __getitem__(self, Py_ssize_t i):
        """
        Return the ith entry of self.

        EXAMPLES::

            sage: v = vector(GF(2), [1,2,3]); v
            (1, 0, 1)
            sage: v[0]
            1
            sage: v[2]
            1
            sage: v[-2]
            0
            sage: v[5]
            Traceback (most recent call last):
            ...
            IndexError: index '5' out of range

            sage: v[-5]
            Traceback (most recent call last):
            ...
            IndexError: index '-2' out of range
        """
        if i < 0:
            i += self._degree
            
        if i < 0 or i >= self._degree:
            raise IndexError("index '%s' out of range"%(i,))

        return self._base_ring(mzd_read_bit(self._entries, 0, i))

    def __reduce__(self):
        """
        EXAMPLE::

            sage: VS = VectorSpace(GF(2),10^4)
            sage: e = VS.random_element()
            sage: loads(dumps(e)) == e
            True
        """
        return unpickle_v0, (self._parent, self.list(), self._degree, self._is_mutable)

    cpdef ModuleElement _add_(self, ModuleElement right):
        """
        EXAMPLE::

            sage: VS = VectorSpace(GF(2),10)
            sage: e = VS([0,0,1,1,0,0,1,1,0,0])
            sage: f = VS([0,1,0,1,0,1,0,1,0,1])
            sage: e + f #indirect doctest
            (0, 1, 1, 0, 0, 1, 1, 0, 0, 1)
        """
        cdef Vector_mod2_dense z = self._new_c()
        if self._degree:
            mzd_add(z._entries, self._entries, (<Vector_mod2_dense>right)._entries)
        return z

    cpdef ModuleElement _sub_(self, ModuleElement right):
        """
        EXAMPLE::

            sage: VS = VectorSpace(GF(2),10)
            sage: e = VS([0,0,1,1,0,0,1,1,0,0])
            sage: f = VS([0,1,0,1,0,1,0,1,0,1])
            sage: e - f #indirect doctest
            (0, 1, 1, 0, 0, 1, 1, 0, 0, 1)
        """
        cdef Vector_mod2_dense z = self._new_c()
        if self._degree:
            mzd_add(z._entries, self._entries, (<Vector_mod2_dense>right)._entries)
        return z

    cpdef Element _dot_product_(self, Vector right):
        """
        EXAMPLES::
           sage: VS = VectorSpace(GF(2),3)
           sage: v = VS([1,1,1]); w = VS([0,0,0])
           sage: v * w, w * v #indirect doctest
           (0, 0)
           sage: v = VS([1,1,1]); w = VS([0,1,0])
           sage: v * w, w * v
           (1, 1)
           sage: v = VS([1,1,1]); w = VS([0,1,1])
           sage: v * w, w * v
           (0, 0)
           sage: v = VS([1,1,1]); w = VS([1,1,1])
           sage: v * w, w * v
           (1, 1)

           sage: VS = VectorSpace(GF(2),10^4)
           sage: v = VS(0); w = VS(0)
           sage: v[1337] = 1; w[1337] = 1
           sage: v * w, w * v
           (1, 1)
           sage: v[9881] = 1; w[9881] = 1
           sage: v * w, w * v
           (0, 0)
           sage: v[5172] = 1; w[6178] = 1
           sage: v * w, w * v
           (0, 0)
        """
        cdef Py_ssize_t i
        cdef IntegerMod_int n
        cdef Vector_mod2_dense r = right
        cdef m4ri_word tmp = 0
        n =  IntegerMod_int.__new__(IntegerMod_int)
        IntegerMod_abstract.__init__(n, self.base_ring())
        n.ivalue = 0
        
        for i from 0 <= i < self._entries.width:
            tmp ^= self._entries.rows[0][i] & r._entries.rows[0][i]

        for i in range(64):
            n.ivalue ^= <int>(tmp & 1)
            tmp = tmp >> 1
        
        return n

    cpdef Vector _pairwise_product_(self, Vector right):
        """
        EXAMPLE::

            sage: VS = VectorSpace(GF(2),10)
            sage: e = VS.random_element(); e
            (1, 0, 0, 0, 1, 1, 1, 0, 0, 1)
            sage: f = VS.random_element(); f
            (1, 1, 0, 1, 1, 1, 0, 0, 0, 1)
            sage: e.pairwise_product(f) #indirect doctest
            (1, 0, 0, 0, 1, 1, 0, 0, 0, 1)
        """
        cdef Vector_mod2_dense z, r
        r = right
        z = self._new_c()
        cdef Py_ssize_t i
        for i from 0 <= i < self._entries.width:
            z._entries.rows[0][i] = (self._entries.rows[0][i] & r._entries.rows[0][i])
        return z
        
    cpdef ModuleElement _rmul_(self, RingElement left):
        """
        EXAMPLE::

            sage: VS = VectorSpace(GF(2),10)
            sage: e = VS.random_element(); e
            (1, 0, 0, 0, 1, 1, 1, 0, 0, 1)
            sage: 0 * e
            (0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            sage: 1 * e
            (1, 0, 0, 0, 1, 1, 1, 0, 0, 1)
            sage: 2 * e #indirect doctest
            (0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        """
        cdef IntegerMod_int a
        
        if left:
            return self.__copy__()
        else:
            return self._new_c()


    cpdef ModuleElement _lmul_(self, RingElement right):
        """
        EXAMPLE::

            sage: VS = VectorSpace(GF(2),10)
            sage: e = VS.random_element(); e
            (1, 0, 0, 0, 1, 1, 1, 0, 0, 1)
            sage: e * 0 #indirect doctest
            (0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            sage: e * 1
            (1, 0, 0, 0, 1, 1, 1, 0, 0, 1)
            sage: e * 2
            (0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        """
        return self._rmul_(right)

    cpdef ModuleElement _neg_(self):
        """
        EXAMPLE::

            sage: VS = VectorSpace(GF(2),10)
            sage: e = VS.random_element()
            sage: -e == e
            True
        """
        return self.__copy__()

    def n(self, *args, **kwargs):
        """
        Returns a numerical approximation of ``self`` by calling the
        :meth:`n()` method on all of its entries.

        EXAMPLES::

            sage: v = vector(GF(2), [1,2,3])
            sage: v.n()
            (1.00000000000000, 0.000000000000000, 1.00000000000000)
            sage: _.parent()
            Vector space of dimension 3 over Real Field with 53 bits of precision
            sage: v.n(prec=75)
            (1.000000000000000000000, 0.0000000000000000000000, 1.000000000000000000000)
            sage: _.parent()
            Vector space of dimension 3 over Real Field with 75 bits of precision
        """
        return vector( [e.n(*args, **kwargs) for e in self] )

    def list(self, copy=True):
        """
        Return a list of entries in ``self``.

        INPUT:

        - ``copy`` - always ``True

        EXAMPLE::

            sage: VS = VectorSpace(GF(2),10)
            sage: e = VS.random_element(); e
            (1, 0, 0, 0, 1, 1, 1, 0, 0, 1)
            sage: e.list()
            [1, 0, 0, 0, 1, 1, 1, 0, 0, 1]
        """
        cdef Py_ssize_t d = self._degree
        cdef Py_ssize_t i
        cdef list v = [0]*d
        K = self.base_ring()
        z = K.zero_element()
        o = K.one_element()
        cdef list switch = [z,o]
        for i in range(d):
            v[i] = switch[mzd_read_bit(self._entries, 0, i)]
        return v

def unpickle_v0(parent, entries, degree, is_mutable):
    """
    EXAMPLE::

        sage: from sage.modules.vector_mod2_dense import unpickle_v0
        sage: VS = VectorSpace(GF(2),10)
        sage: unpickle_v0(VS, [0,1,2,3,4,5,6,7,8,9], 10, 0)
        (0, 1, 0, 1, 0, 1, 0, 1, 0, 1)
    """
    # If you think you want to change this function, don't.
    cdef Vector_mod2_dense v
    v = PY_NEW(Vector_mod2_dense)
    v._init(degree, parent)
    cdef int xi

    for i from 0 <= i < degree:
        if PY_TYPE_CHECK(entries[i],IntegerMod_int) or PY_TYPE_CHECK(entries[i],int) or PY_TYPE_CHECK(entries[i],Integer):
            xi = entries[i]
            mzd_write_bit(v._entries, 0, i, xi%2)
        else:
            mzd_write_bit(v._entries, 0, i, entries[i]%2)
    v._is_mutable = int(is_mutable)
    return v

