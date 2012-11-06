from pari_group import PariGroup

from matrix_gps.all import (GL, SL, Sp, SU, GU, SO, GO,
                            MatrixGroup, is_MatrixGroup,
                            is_MatrixGroupElement)
from abelian_gps.all import *

from perm_gps.all import *

from generic import *

from class_function import ClassFunction

from additive_abelian.all import *

from sage.misc.lazy_import import lazy_import

lazy_import('sage.groups.free_group', 'FreeGroup')

import groups_catalog as groups
