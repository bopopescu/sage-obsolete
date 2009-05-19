###############################################################################
#   SAGE: Open Source Mathematical Software
#       Copyright (C) 2008 William Stein <wstein@gmail.com>
#       Copyright (C) 2008 Burcin Erocal <burcin@erocal.org>
#  Distributed under the terms of the GNU General Public License (GPL),
#  version 2 or any later version.  The full text of the GPL is available at:
#                  http://www.gnu.org/licenses/
###############################################################################

include "../ext/stdsage.pxi"
include "../ext/cdefs.pxi"

#################################################################
# Initialize the library
#################################################################

#initialize_ginac()

from sage.rings.integer cimport Integer
from sage.rings.real_mpfr import RealNumber

from expression cimport Expression, new_Expression_from_GEx

from sage.structure.element import RingElement

cdef class NSymbolicRing(Ring):
    """
    Symbolic Ring, parent object for all symbolic expressions.
    """
    def __init__(self):
        """
        Initialize the New Symbolic Ring.

        EXAMPLES:
            sage: sage.symbolic.ring.NSymbolicRing()
            New Symbolic Ring
        """

    def _repr_(self):
        """
        Return a string representation of self.

        EXAMPLES:
            sage: from sage.symbolic.ring import NSR
            sage: NSR._repr_()
            'New Symbolic Ring'
        """
        return "New Symbolic Ring"

    cdef _coerce_c_impl(self, other):
        """
        
        EXAMPLES::

            sage: from sage.symbolic.ring import NSR
            sage: NSR._coerce_(int(5))
            5
            sage: NSR._coerce_(5)
            5
            sage: NSR._coerce_(float(5))
            5.0
            sage: NSR._coerce_(5.0)
            5.00000000000000

        An interval arithmetic number::

            sage: NSR._coerce_(RIF(pi))
            3.141592653589794?

        A number modulo 7::

            sage: a = NSR._coerce_(Mod(3,7)); a
            3
            sage: a^2
            2

        TESTS::

            sage: si = NSR.coerce(I)
            sage: si^2
            -1
            sage: bool(si == CC.0)
            True
        """
        from sage.functions.constants import pi, catalan, euler_gamma, I
        from sage.rings.infinity import infinity, minus_infinity, \
                unsigned_infinity
        cdef GEx exp

        if isinstance(other, int):
            GEx_construct_long(&exp, other)
        elif isinstance(other, float):
            GEx_construct_double(&exp, other)
        elif isinstance(other, (Integer, long, complex)):
            GEx_construct_pyobject(exp, other)
        elif isinstance(other, RealNumber):
            GEx_construct_pyobject(exp, other)
        elif other is I:
            return new_Expression_from_GEx(g_I)
        elif other is pi:
            return new_Expression_from_GEx(g_Pi)
        elif other is catalan:
            return new_Expression_from_GEx(g_Catalan)
        elif other is euler_gamma:
            return new_Expression_from_GEx(g_Euler)
        elif other is infinity:
            return new_Expression_from_GEx(g_Infinity)
        elif other is minus_infinity:
            return new_Expression_from_GEx(g_mInfinity)
        elif other is unsigned_infinity:
            return new_Expression_from_GEx(g_UnsignedInfinity)
        elif isinstance(other, RingElement):
            GEx_construct_pyobject(exp, other)
        else:
            raise TypeError
        return new_Expression_from_GEx(exp)

    def __call__(self, other):
        """
        INPUT:
            other -- python object
            
        EXAMPLES:
            sage: from sage.symbolic.ring import NSR
            sage: NSR(2/5)
            2/5
            sage: NSR.__call__(2/5)
            2/5
            sage: NSR.__call__('foo')
            Traceback (most recent call last):
            ...
            TypeError: conversion not defined
        """
        try:
            return self._coerce_(other)
        except TypeError:
            raise TypeError, "conversion not defined"

    def wild(self, unsigned int n=0):
        """
        Return the n-th wild-card for pattern matching and substitution.

        INPUT:
            n -- a nonnegative integer

        OUTPUT:
            i-th wildcard expression

        EXAMPLES:
            sage: x,y = var('x,y',ns=1); SR = x.parent()
            sage: w0 = SR.wild(0); w1 = SR.wild(1)
            sage: pattern = sin(x)*w0*w1^2; pattern
            $0*$1^2*sin(x)
            sage: f = atan(sin(x)*3*x^2); f
            arctan(3*x^2*sin(x))
            sage: f.has(pattern)
            True
            sage: f.subs(pattern == x^2)
            arctan(x^2)
        """
        return new_Expression_from_GEx(g_wild(n))
    

NSR = NSymbolicRing()

def var(name):
    """
    EXAMPLES:
        sage: from sage.symbolic.ring import var
        sage: var("x y z")
        (x, y, z)
        sage: var("x,y,z")
        (x, y, z)
        sage: var("x , y , z")
        (x, y, z)
        sage: var("z")
        z
    """
    if ',' in name:
        return tuple([new_symbol(s.strip()) for s in name.split(',')])
    if ' ' in name:
        return tuple([new_symbol(s.strip()) for s in name.split(' ')])
    return new_symbol(name)


def new_symbol(name):
    """
    EXAMPLES:
        sage: from sage.symbolic.ring import new_symbol
        sage: new_symbol("asdfasdfasdf")
        asdfasdfasdf
    """
    cdef GSymbol symb = get_symbol(name)
    cdef Expression e
    global NSR
    e = <Expression>PY_NEW(Expression)
    GEx_construct_symbol(&e._gobj, symb)
    e._parent = NSR
    return e


