r"""
Common graphs and digraphs generators (Cython)

AUTHORS:

- David Coudert (2012)
"""


################################################################################
#           Copyright (C) 2012 David Coudert <david.coudert@inria.fr>
#
# Distributed  under  the  terms  of  the  GNU  General  Public  License (GPL)
#                         http://www.gnu.org/licenses/
################################################################################

from sage.misc.randstate cimport random
from sage.functions.log import ln

def RandomGNP(n, p, directed = False, loops = False, fast = False):
    r"""
    Returns a random graph or a digraph on `n` nodes. Each edge is inserted
    independently with probability `p`.

    INPUTS:

    - ``n`` -- number of nodes of the digraph

    - ``p`` -- probability of an edge

    - ``directed`` -- is a boolean indicating whether the random graph is
      directed or undirected (default).

    - ``loops`` -- is a boolean set to True if the random digraph may have
      loops, and False (default) otherwise. This value is used only when
      ``directed == True``.

    - ``fast`` -- boolean set to True to use the algorithm with time
      complexity in `O(n+m)` proposed in [3]_. It is designed for generating
      large sparse digraphs, and faster than other methods only faster for
      *LARGE* instances (try it to know whether it is useful for you).

    REFERENCES:

    .. [1] P. Erdos and A. Renyi. On Random Graphs, Publ.  Math. 6, 290 (1959).

    .. [2] E. N. Gilbert. Random Graphs, Ann. Math.  Stat., 30, 1141 (1959).

    .. [3] V. Batagelj and U. Brandes. Efficient generation of large
           random networks. Phys. Rev. E, 71, 036113, 2005.

    EXAMPLE::

        sage: from sage.graphs.graph_generators_pyx import RandomGNP
        sage: set_random_seed(0)
        sage: D = RandomGNP(10, .2, directed = True)
        sage: D.num_verts()
        10
        sage: D.edges(labels=False)
        [(0, 2), (0, 5), (1, 5), (1, 7), (4, 1), (4, 2), (4, 9), (5, 0), (5, 2), (5, 3), (5, 7), (6, 5), (7, 1), (8, 2), (8, 6), (9, 4)]

    TESTS::

        sage: abs(mean([RandomGNP(200,.2).density() for i in range(30)])-.2) < .001
        True
        sage: abs(mean([RandomGNP(150,.2, fast = True).density() for i in range(30)])-.2) < .001
        True
        sage: RandomGNP(150,.2, loops = True)
        Traceback (most recent call last):
        ...
        ValueError: The 'loops' argument can be set to True only when 'directed' is False.
    """
    from sage.graphs.graph import Graph, DiGraph
    
    cdef int i, j

    # according the sage.misc.randstate.pyx documentation, random
    # integers are on 31 bits. We thus set the pivot value to p*2^31
    cdef float RAND_MAX_f = (1<<31)*1.0
    cdef int pp = int(round(p*(1<<31)))

    if directed:
        G = DiGraph(loops = loops)
    else:
        G = Graph()
        if loops:
            raise ValueError("The 'loops' argument can be set to True only when 'directed' is False.")
    G.name('Random'+('Directed' if directed else '')+'GNP(%s,%s)'%(n,p))

    G.add_vertices(range(n))

    if fast:
        # Algorithm proposed in [3]_
        i = 1
        j = -1
        logp = ln(1-p)
        
        while i < n:
            logr = ln( 1 - random()/RAND_MAX_f )
            j += 1+int(logr/logp)
            while j >= n and i < n:
                j -= (n if directed else i)
                i += 1
                if directed and not loops and i == j:
                    # small shift to avoid loops
                    j += 1
            if i < n:
                G.add_edge(i,j)

    else:
        # Standard random GNP generator for Graph and DiGraph
        for 0 <= i < n:
            for (0 if directed else i+1) <= j < n:
                if random() < pp:
                    G.add_edge(i,j)

    return G
