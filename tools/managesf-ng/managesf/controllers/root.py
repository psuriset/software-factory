from pecan import expose
from pecan import conf
from pecan.rest import RestController
from pecan.secure import secure
from pecan import request, response

from managesf.controllers import gerrit, redmine

import ldap


class ProjectController(RestController):
    @expose()
    def put(self, name, **kwargs):
        #create project
        inp = request.json if request.content_length else {}
        gerrit.init_project(name, inp)
        redmine.init_project(name, inp)

        response.status = 201
        return "Created"

    @expose()
    def delete(self, name):
        #delete project
        gerrit.delete_project(name)
        redmine.delete_project(name)
        return None


class RootController(object):
    @classmethod
    def verify_ldap(cls, username, password):
        l = conf.auth['ldap']
        conn = ldap.initialize(l['host'])
        conn.set_option(ldap.OPT_REFERRALS, 0)
        who = l['dn'] % {'username': username}
        try:
            conn.simple_bind_s(who, password)
        except ldap.INVALID_CREDENTIALS:
            return False
        return True

    @classmethod
    def check_permission(cls):
        if 'Authorization' not in request.headers:
            return False

        auth_hdr = request.headers['Authorization']
        auth_type, auth_code = auth_hdr.split(' ')
        if auth_type.lower() != 'basic':
            return False

        auth_decoded = auth_code.decode('Base64')
        username, password = auth_decoded.split(':')

        request.remote_user = {'username': username,
                               'password': password}
        if conf.auth['type'] == 'ldap':
            return cls.verify_ldap(username, password)
        return True

    project = secure(ProjectController(), 'check_permission')