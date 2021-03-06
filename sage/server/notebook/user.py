# This file is part of the OLD Sage notebook and is NOT actively developed,
# maintained, or supported.  As of Sage v4.1.2, all notebook development has
# moved to the separate Sage Notebook project:
#
# http://nb.sagemath.org/
#
# The new notebook is installed in Sage as an spkg (e.g., sagenb-0.3.spkg).
#
# Please visit the project's home page for more information, including directions on
# obtaining the latest source code.  For notebook-related development and support,
# please consult the sage-notebook discussion group:
#
# http://groups.google.com/group/sage-notebook

import copy
import crypt
import cPickle
import os

SALT = 'aa'

import user_conf

class User:
    def __init__(self, username, password='', email='', account_type='admin'):
        self.__username = username
        self.__password = crypt.crypt(password, SALT)
        self.__email = email
        self.__email_confirmed = False
        if not account_type in ['admin', 'user', 'guest']:
            raise ValueError, "account type must be one of admin, user, or guest"
        self.__account_type = account_type
        self.__conf = user_conf.UserConfiguration()
        self.__temporary_password = ''
        self.__is_suspended = False

    def __getstate__(self):
        d = copy.copy(self.__dict__)

        # Some old worksheets have this attribute, which we do *not* want to save.
        if d.has_key('history'):
            try:
                self.save_history()
                del d['history']
            except Exception, msg:
                print msg
                print "Unable to dump history of user %s to disk yet."%self.__username
        return d

    def history_list(self):
        try:
            return self.history
        except AttributeError:
            import twist   # late import
            if twist.notebook is None: return []       
            history_file = "%s/worksheets/%s/history.sobj"%(twist.notebook.directory(), self.__username)
            if os.path.exists(history_file):
                try:
                    self.history = cPickle.load(open(history_file))
                except StandardError:
                    print "Error loading history for user %s"%self.__username
                    self.history = []
            else:
                self.history = []
            return self.history    

    def save_history(self):
        if not hasattr(self, 'history'):
            return
        import twist   # late import
        if twist.notebook is None: return
        history_file = "%s/worksheets/%s/history.sobj"%(twist.notebook.directory(), self.__username)
        try:
            #print "Dumping %s history to '%s'"%(self.__username, history_file)
            his = cPickle.dumps(self.history)
        except AttributeError:
            his = cPickle.dumps([])
        open(history_file,'w').write(his)

    def username(self):
        """
        EXAMPLES::

            sage: from sage.server.notebook.user import User
            sage: User('andrew', 'tEir&tiwk!', 'andrew@matrixstuff.com', 'user').username()
            'andrew'
            sage: User('sarah', 'Miaasc!', 'sarah@ellipticcurves.org', 'user').username()
            'sarah'
            sage: User('bob', 'Aisfa!!', 'bob@sagemath.net', 'admin').username()
            'bob'
        """
        return self.__username

    def __repr__(self):
        return self.__username

    def conf(self):
        """
        EXAMPLES::

            sage: from sage.server.notebook.user import User
            sage: config = User('bob', 'Aisfa!!', 'bob@sagemath.net', 'admin').conf(); config
            Configuration: {}
            sage: config['max_history_length']
            1000
            sage: config['default_system']
            'sage'
            sage: config['autosave_interval']
            3600
            sage: config['default_pretty_print']
            False
        """
        return self.__conf

    def __getitem__(self, *args):
        return self.__conf.__getitem__(*args)

    def __setitem__(self, *args):
        self.__conf.__setitem__(*args)

    def password(self):
        """
        EXAMPLES::

            sage: from sage.server.notebook.user import User
            sage: user = User('bob', 'Aisfa!!', 'bob@sagemath.net', 'admin')
            sage: user.password()
            'aamxw5LCYcWY.'
        """
        return self.__password

    def set_password(self, password):
        """
        EXAMPLES::

            sage: from sage.server.notebook.user import User
            sage: user = User('bob', 'Aisfa!!', 'bob@sagemath.net', 'admin')
            sage: old = user.password()
            sage: user.set_password('Crrc!')
            sage: old != user.password()
            True
        """
        if password == '':
            self.__password = 'x'   # won't get as a password -- i.e., this account is closed.
        else:
            self.__password = crypt.crypt(password, SALT)
            self.__temporary_password = ''

    def set_hashed_password(self, password):
        """
        EXAMPLES::

            sage: from sage.server.notebook.user import User
            sage: user = User('bob', 'Aisfa!!', 'bob@sagemath.net', 'admin')
            sage: user.set_hashed_password('Crrc!')
            sage: user.password()
            'Crrc!'
        """
        self.__password = password
        self.__temporary_password = ''

    def get_email(self):
        """
        EXAMPLES::

            sage: from sage.server.notebook.user import User
            sage: user = User('bob', 'Aisfa!!', 'bob@sagemath.net', 'admin')
            sage: user.get_email()
            'bob@sagemath.net'
        """
        return self.__email

    def set_email(self, email):
        """
        EXAMPLES::

            sage: from sage.server.notebook.user import User
            sage: user = User('bob', 'Aisfa!!', 'bob@sagemath.net', 'admin')
            sage: user.get_email()
            'bob@sagemath.net'
            sage: user.set_email('bob@gmail.gov')
            sage: user.get_email()
            'bob@gmail.gov'
        """
        self.__email = email
        
    def set_email_confirmation(self, value):
        """
        EXAMPLES::

            sage: from sage.server.notebook.user import User
            sage: user = User('bob', 'Aisfa!!', 'bob@sagemath.net', 'admin')
            sage: user.is_email_confirmed()
            False
            sage: user.set_email_confirmation(True)
            sage: user.is_email_confirmed()
            True
            sage: user.set_email_confirmation(False)
            sage: user.is_email_confirmed()
            False
        """
        value = bool(value)
        self.__email_confirmed = value
        
    def is_email_confirmed(self):
        """
        EXAMPLES::

            sage: from sage.server.notebook.user import User
            sage: user = User('bob', 'Aisfa!!', 'bob@sagemath.net', 'admin')
            sage: user.is_email_confirmed()
            False
        """
        try:
            return self.__email_confirmed
        except AttributeError:
            self.__email_confirmed = False
            return False

    def password_is(self, password):
        """
        EXAMPLES::

            sage: from sage.server.notebook.user import User
            sage: user = User('bob', 'Aisfa!!', 'bob@sagemath.net', 'admin')
            sage: user.password_is('ecc')
            False
            sage: user.password_is('Aisfa!!')
            True
        """
        if self.__username == "pub":
            return False
        return self.__password == crypt.crypt(password, SALT)

    def account_type(self):
        """
        EXAMPLES::

            sage: from sage.server.notebook.user import User
            sage: User('A', account_type='admin').account_type()
            'admin'
            sage: User('B', account_type='user').account_type()
            'user'
            sage: User('C', account_type='guest').account_type()
            'guest'
        """
        if self.__username == 'admin':
            return 'admin'
        return self.__account_type
    
    def is_admin(self):
        """
        EXAMPLES::

            sage: from sage.server.notebook.user import User
            sage: User('A', account_type='admin').is_admin()
            True
            sage: User('B', account_type='user').is_admin()
            False
        """
        return self.__account_type == 'admin'

    def is_guest(self):
        """
        EXAMPLES::

            sage: from sage.server.notebook.user import User
            sage: User('A', account_type='guest').is_guest()
            True
            sage: User('B', account_type='user').is_guest()
            False
        """
        return self.__account_type == 'guest'
        
    def is_suspended(self):
        """
        EXAMPLES::

            sage: from sage.server.notebook.user import User
            sage: user = User('bob', 'Aisfa!!', 'bob@sagemath.net', 'admin')
            sage: user.is_suspended()
            False
        """
        try:
            return self.__is_suspended
        except AttributeError:
            return False
        
    def set_suspension(self):
        """
        EXAMPLES::

            sage: from sage.server.notebook.user import User
            sage: user = User('bob', 'Aisfa!!', 'bob@sagemath.net', 'admin')
            sage: user.is_suspended()
            False
            sage: user.set_suspension()
            sage: user.is_suspended()
            True
            sage: user.set_suspension()
            sage: user.is_suspended()
            False
        """
        try:
            self.__is_suspended = False if self.__is_suspended else True
        except AttributeError:
            self.__is_suspended = True
