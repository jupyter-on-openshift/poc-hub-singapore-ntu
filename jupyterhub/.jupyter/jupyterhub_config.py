import os
import string
import escapism

# Enable JupyterLab interface.

c.JupyterHub.environment = dict(JUPYTER_ENABLE_LAB='true')

# Setup location for customised template files.

c.JupyterHub.template_paths = ['/opt/app-root/src/templates']

# Setup configuration for authenticating using LDAP. In this case we
# need to deal with separate LDAP servers based on the domain name so
# we need to provide a custom authenticator which can delegate to the
# respective LDAP authenticator instance for the domain.

from ldapauthenticator import LDAPAuthenticator

c.LDAPAuthenticator.use_ssl = True
c.LDAPAuthenticator.lookup_dn = True
c.LDAPAuthenticator.lookup_dn_search_filter = '({login_attr}={login})'
c.LDAPAuthenticator.escape_userdn = False
c.LDAPAuthenticator.valid_username_regex = '^[A-Za-z0-9\\\._-]{7,}$'
c.LDAPAuthenticator.user_attribute = 'sAMAccountName'
c.LDAPAuthenticator.lookup_dn_user_dn_attribute = 'sAMAccountName'
c.LDAPAuthenticator.escape_userdn = False

c.LDAPAuthenticator.lookup_dn_search_user = os.environ['LDAP_SEARCH_USER']
c.LDAPAuthenticator.lookup_dn_search_password = os.environ['LDAP_SEARCH_PASSWORD']

student_authenticator = LDAPAuthenticator()
student_authenticator.server_address = 'student.main.ntu.edu.sg'
student_authenticator.bind_dn_template = ['student\\{username}']
student_authenticator.user_search_base = 'DC=student,DC=main,DC=ntu,DC=edu,DC=sg'

staff_authenticator = LDAPAuthenticator()
staff_authenticator.server_address = 'staff.main.ntu.edu.sg'
staff_authenticator.bind_dn_template = ['staff\\{username}']
staff_authenticator.user_search_base = 'DC=staff,DC=main,DC=ntu,DC=edu,DC=sg'

assoc_authenticator = LDAPAuthenticator()
assoc_authenticator.server_address = 'assoc.main.ntu.edu.sg'
assoc_authenticator.bind_dn_template = ['assoc\\{username}']
assoc_authenticator.user_search_base = 'DC=assoc,DC=main,DC=ntu,DC=edu,DC=sg'

from jupyterhub.auth import Authenticator

class MultiLDAPAuthenticator(Authenticator):

    def authenticate(self, handler, data):
        domain = data['domain'].lower()

        if domain == 'student':
            return student_authenticator.authenticate(handler, data)
        elif domain == 'staff':
            return staff_authenticator.authenticate(handler, data)
        elif domain == 'assoc':
            return assoc_authenticator.authenticate(handler, data)

        self.log.warn('domain:%s Unknown authentication domain name', domain)
        return None

c.JupyterHub.authenticator_class = MultiLDAPAuthenticator

if os.path.exists('/opt/app-root/configs/admin_users.txt'):
    with open('/opt/app-root/configs/admin_users.txt') as fp:
        content = fp.read().strip()
        if content:
            c.Authenticator.admin_users = set(content.split())

if os.path.exists('/opt/app-root/configs/user_whitelist.txt'):
    with open('/opt/app-root/configs/user_whitelist.txt') as fp:
        content = fp.read().strip()
        if content:
            c.Authenticator.whitelist = set(content.split())

# Provide persistent storage for users notebooks. We share one
# persistent volume for all users, mounting just their subdirectory into
# their pod. The persistent volume type needs to be ReadWriteMany so it
# can be mounted on multiple nodes as can't control where pods for a
# user may land. Because it is a shared volume, there are no quota
# restrictions which prevent a specific user filling up the entire
# persistent volume.

c.KubeSpawner.user_storage_pvc_ensure = False
c.KubeSpawner.pvc_name_template = '%s-notebooks' % c.KubeSpawner.hub_connect_ip

c.KubeSpawner.volumes = [
    {
        'name': 'notebooks',
        'persistentVolumeClaim': {
            'claimName': c.KubeSpawner.pvc_name_template
        }
    }
]

volume_mounts_user = [
    {
        'name': 'notebooks',
        'mountPath': '/opt/app-root/src',
        'subPath': '{username}'
    }
]

volume_mounts_admin = [
    {
        'name': 'notebooks',
        'mountPath': '/opt/app-root/src/users'
    }
]

def interpolate_properties(spawner, template):
    safe_chars = set(string.ascii_lowercase + string.digits)
    username = escapism.escape(spawner.user.name, safe=safe_chars,
            escape_char='-').lower()

    return template.format(
        userid=spawner.user.id,
        username=username
        )

def expand_strings(spawner, src):
    if isinstance(src, list):
        return [expand_strings(spawner, i) for i in src]
    elif isinstance(src, dict):
        return {k: expand_strings(spawner, v) for k, v in src.items()}
    elif isinstance(src, str):
        return interpolate_properties(spawner, src)
    else:
        return src

def modify_pod_hook(spawner, pod):
    if spawner.user.admin:
        volume_mounts = volume_mounts_admin
        workspace = interpolate_properties(spawner, 'users/{username}/workspace')
    else:
        volume_mounts = volume_mounts_user
        workspace = 'workspace'

    try:
        os.mkdir(interpolate_properties(spawner, '/opt/app-root/notebooks/{username}'))

    except IOError:
        pass

    pod.spec.containers[0].env.append(dict(name='JUPYTER_MASTER_FILES',
            value='/opt/app-root/master'))
    pod.spec.containers[0].env.append(dict(name='JUPYTER_WORKSPACE_NAME',
            value=workspace))

    pod.spec.containers[0].volume_mounts.extend(
            expand_strings(spawner, volume_mounts))

    return pod

c.KubeSpawner.modify_pod_hook = modify_pod_hook

# Setup culling of idle notebooks if timeout parameter is supplied.

idle_timeout = os.environ.get('JUPYTERHUB_IDLE_TIMEOUT')

if idle_timeout and int(idle_timeout):
    c.JupyterHub.services = [
        {
            'name': 'cull-idle',
            'admin': True,
            'command': ['cull-idle-servers', '--timeout=%s' % idle_timeout],
        }
    ]
