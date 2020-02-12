def main(ctx):
  versions = [
    {
      'value': 'latest',
      'qa': 'https://download.owncloud.com/internal/10.3.2/testing/owncloud-enterprise-complete-20191205-qa.tar.bz2',
      'tarball': 'https://download.owncloud.com/internal/10.3.2/owncloud-enterprise-complete-20191205.tar.bz2',
      'tarball_sha': 'b3d880b3d1aec6834527fa3e671cf931c9d3b42150f68071ed29021e724b54f7',
      'php': '7.3',
      'behat_version': '10.3.2',
      'base': 'v19.10',
      'tags': [],
    },

    {
      'value': '10.4.0-rc2',
      'qa': 'https://download.owncloud.com/internal/10.4.0RC2/testing/owncloud-enterprise-complete-10.4.0RC2-qa.tar.bz2',
      'tarball': 'https://download.owncloud.com/internal/10.4.0RC2/testing/owncloud-enterprise-complete-10.4.0RC2.tar.bz2',
      'tarball_sha': '56db118919d14d93dd5de69eee8e6b89f51970fb79df43d02ad5c03ee9ec0270',
      'php': '7.3',
      'base': 'v19.10',
      'tags': [],
    },

    {
      'value': '10.3.2',
      'qa': 'https://download.owncloud.com/internal/10.3.2/testing/owncloud-enterprise-complete-20191205-qa.tar.bz2',
      'tarball': 'https://download.owncloud.com/internal/10.3.2/owncloud-enterprise-complete-20191205.tar.bz2',
      'tarball_sha': 'b3d880b3d1aec6834527fa3e671cf931c9d3b42150f68071ed29021e724b54f7',
      'php': '7.3',
      'base': 'v19.10',
      'tags': ['10.3', '10'],
    },

    {
      'value': '10.2.1',
      'qa': 'https://download.owncloud.com/internal/10.2.1/owncloud-enterprise-complete-20190703-qa.tar.bz2',
      'tarball': 'https://download.owncloud.com/internal/10.2.1/owncloud-enterprise-complete-20190703.tar.bz2',
      'tarball_sha': 'b4b4591af57b5b8ab40299f0abde593371269b9a4bac0eb0aba27cd41e0485ab',
      'php': '7.0',
      'base': 'v18.04',
      'tags': ['10.2'],
    },
  ]

  arches = [
    'amd64',
    'arm32v7',
    'arm64v8',
  ]

  config = {
    'version': None,
    'arch': None,
    'split': 3,
    'downstream': [

    ],
  }

  stages = []

  for version in versions:
    config['version'] = version

    m = manifest(config)
    inner = []

    for arch in arches:
      config['arch'] = arch

      if config['version']['value'] == 'latest':
        config['tag'] = arch
      else:
        config['tag'] = '%s-%s' % (config['version']['value'], arch)

      if config['arch'] == 'amd64':
        config['platform'] = 'amd64'

      if config['arch'] == 'arm64v8':
        config['platform'] = 'arm64'

      if config['arch'] == 'arm32v7':
        config['platform'] = 'arm'

      config['internal'] = '%s-%s' % (ctx.build.commit, config['tag'])

      for d in docker(config):
        m['depends_on'].append(d['name'])
        inner.append(d)

    inner.append(m)
    stages.extend(inner)

  after = downstream(config) + [
    rocketchat(config),
  ]

  for s in stages:
    for a in after:
      a['depends_on'].append(s['name'])

  return stages + after

def docker(config):
  pre = [{
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'prepublish-%s-%s' % (config['arch'], config['version']['value']),
    'platform': {
      'os': 'linux',
      'arch': config['platform'],
    },
    'steps': tarball(config) + prepublish(config) + sleep(config) + trivy(config),
    'depends_on': [],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/pull/**',
      ],
    },
  }]

  post = [{
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'cleanup-%s-%s' % (config['arch'], config['version']['value']),
    'platform': {
      'os': 'linux',
      'arch': config['platform'],
    },
    'clone': {
      'disable': True,
    },
    'steps': cleanup(config),
    'depends_on': [],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/pull/**',
      ],
      'status': [
        'success',
        'failure',
      ],
    },
  }]

  push = [{
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'publish-%s-%s' % (config['arch'], config['version']['value']),
    'platform': {
      'os': 'linux',
      'arch': config['platform'],
    },
    'steps': tarball(config) + publish(config),
    'depends_on': [],
    'trigger': {
      'ref': [
        'refs/heads/master',
      ],
    },
  }]

  test = []

  if config['arch'] == 'amd64':
    for step in list(range(1, config['split'] + 1)):
      config['step'] = step

      test.append({
        'kind': 'pipeline',
        'type': 'docker',
        'name': 'api%d-%s-%s' % (config['step'], config['arch'], config['version']['value']),
        'platform': {
          'os': 'linux',
          'arch': config['platform'],
        },
        'clone': {
          'disable': True,
        },
        'steps': wait(config) + api(config),
        'services': [
          {
            'name': 'server',
            'image': 'registry.drone.owncloud.com/owncloud/enterprise:%s' % config['internal'],
            'pull': 'always',
            'environment': {
              'DEBUG': 'true',
              'OWNCLOUD_APPS_INSTALL': 'https://github.com/owncloud/testing/releases/download/latest/testing.tar.gz',
              'OWNCLOUD_APPS_ENABLE': 'testing',
              'OWNCLOUD_REDIS_HOST': 'redis',
              'OWNCLOUD_DB_TYPE': 'mysql',
              'OWNCLOUD_DB_HOST': 'mysql',
              'OWNCLOUD_DB_USERNAME': 'owncloud',
              'OWNCLOUD_DB_PASSWORD': 'owncloud',
              'OWNCLOUD_DB_NAME': 'owncloud',
            },
          },
          {
            'name': 'mysql',
            'image': 'library/mysql:5.7',
            'pull': 'always',
            'environment': {
              'MYSQL_ROOT_PASSWORD': 'owncloud',
              'MYSQL_USER': 'owncloud',
              'MYSQL_PASSWORD': 'owncloud',
              'MYSQL_DATABASE': 'owncloud',
            },
          },
          {
            'name': 'redis',
            'image': 'library/redis:4.0',
            'pull': 'always',
          },
        ],
        'image_pull_secrets': [
          'registries',
        ],
        'depends_on': [],
        'trigger': {
          'ref': [
            'refs/heads/master',
            'refs/pull/**',
          ],
        },
      })

    for step in list(range(1, config['split'] + 1)):
      config['step'] = step

      test.append({
        'kind': 'pipeline',
        'type': 'docker',
        'name': 'ui%d-%s-%s' % (config['step'], config['arch'], config['version']['value']),
        'platform': {
          'os': 'linux',
          'arch': config['platform'],
        },
        'clone': {
          'disable': True,
        },
        'steps': wait(config) + ui(config),
        'services': [
          {
            'name': 'server',
            'image': 'registry.drone.owncloud.com/owncloud/enterprise:%s' % config['internal'],
            'pull': 'always',
            'environment': {
              'DEBUG': 'true',
              'OWNCLOUD_APPS_INSTALL': 'https://github.com/owncloud/testing/releases/download/latest/testing.tar.gz',
              'OWNCLOUD_APPS_ENABLE': 'testing',
              'OWNCLOUD_REDIS_HOST': 'redis',
              'OWNCLOUD_DB_TYPE': 'mysql',
              'OWNCLOUD_DB_HOST': 'mysql',
              'OWNCLOUD_DB_USERNAME': 'owncloud',
              'OWNCLOUD_DB_PASSWORD': 'owncloud',
              'OWNCLOUD_DB_NAME': 'owncloud',
            },
          },
          {
            'name': 'mysql',
            'image': 'library/mysql:5.7',
            'pull': 'always',
            'environment': {
              'MYSQL_ROOT_PASSWORD': 'owncloud',
              'MYSQL_USER': 'owncloud',
              'MYSQL_PASSWORD': 'owncloud',
              'MYSQL_DATABASE': 'owncloud',
            },
          },
          {
            'name': 'redis',
            'image': 'library/redis:4.0',
            'pull': 'always',
          },
          {
            'name': 'email',
            'image': 'mailhog/mailhog:latest',
            'pull': 'always',
          },
          {
            'name': 'selenium',
            'image': 'selenium/standalone-chrome-debug:3.141.59-oxygen',
            'pull': 'always',
          },
        ],
        'image_pull_secrets': [
          'registries',
        ],
        'depends_on': [],
        'trigger': {
          'ref': [
            'refs/heads/master',
            'refs/pull/**',
          ],
        },
      })
  else:
    test.append({
      'kind': 'pipeline',
      'type': 'docker',
      'name': 'test-%s-%s' % (config['arch'], config['version']['value']),
      'platform': {
        'os': 'linux',
        'arch': config['platform'],
      },
      'clone': {
        'disable': True,
      },
      'steps': wait(config) + tests(config),
      'services': [
        {
          'name': 'server',
          'image': 'registry.drone.owncloud.com/owncloud/enterprise:%s' % config['internal'],
          'pull': 'always',
          'environment': {
            'DEBUG': 'true',
            'OWNCLOUD_APPS_INSTALL': 'https://github.com/owncloud/testing/releases/download/latest/testing.tar.gz',
            'OWNCLOUD_APPS_ENABLE': 'testing',
          },
        },
      ],
      'image_pull_secrets': [
        'registries',
      ],
      'depends_on': [],
      'trigger': {
        'ref': [
          'refs/heads/master',
          'refs/pull/**',
        ],
      },
    })

  for t in test:
    for p in push:
      p['depends_on'].append(t['name'])

    for p in pre:
      t['depends_on'].append(p['name'])

    for p in post:
      p['depends_on'].append(t['name'])

      for x in push:
        p['depends_on'].append(x['name'])

  return pre + test + push + post

def manifest(config):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'manifest-%s' % config['version']['value'],
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'steps': [
      {
        'name': 'generate',
        'image': 'owncloud/ubuntu:latest',
        'pull': 'always',
        'environment': {
          'MANIFEST_VERSION': config['version']['value'],
          'MANIFEST_TAGS': ','.join(config['version']['tags']) if len(config['version']['tags']) > 0 else '-',
        },
        'commands': [
          'gomplate -f %s/manifest.tmpl -o %s/manifest.yml' % (config['version']['base'], config['version']['base']),
        ],
      },
      {
        'name': 'manifest',
        'image': 'plugins/manifest',
        'pull': 'always',
        'settings': {
          'username': {
            'from_secret': 'private_username',
          },
          'password': {
            'from_secret': 'private_password',
          },
          'spec': '%s/manifest.yml' % config['version']['base'],
          'ignore_missing': 'true',
        },
      },
    ],
    'depends_on': [],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
      ],
    },
  }

def downstream(config):
  if len(config['downstream']) == 0:
    return []

  return [{
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'downstream',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'clone': {
      'disable': True,
    },
    'steps': [
      {
        'name': 'notify',
        'image': 'plugins/downstream',
        'pull': 'always',
        'failure': 'ignore',
        'settings': {
          'token': {
            'from_secret': 'drone_token',
          },
          'server': 'https://cloud.drone.io',
          'repositories': config['downstream'],
        },
      },
    ],
    'depends_on': [],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
      ],
    },
  }]

def microbadger(config):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'microbadger',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'clone': {
      'disable': True,
    },
    'steps': [
      {
        'name': 'notify',
        'image': 'plugins/webhook',
        'pull': 'always',
        'failure': 'ignore',
        'settings': {
          'urls': {
            'from_secret': 'microbadger_url',
          },
        },
      },
    ],
    'depends_on': [],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
      ],
    },
  }

def rocketchat(config):
  return {
    'kind': 'pipeline',
    'type': 'docker',
    'name': 'rocketchat',
    'platform': {
      'os': 'linux',
      'arch': 'amd64',
    },
    'clone': {
      'disable': True,
    },
    'steps': [
      {
        'name': 'notify',
        'image': 'plugins/slack',
        'pull': 'always',
        'failure': 'ignore',
        'settings': {
          'webhook': {
            'from_secret': 'public_rocketchat',
          },
          'channel': 'docker',
        },
      },
    ],
    'depends_on': [],
    'trigger': {
      'ref': [
        'refs/heads/master',
        'refs/tags/**',
      ],
      'status': [
        'changed',
        'failure',
      ],
    },
  }

def tarball(config):
  return [{
    'name': 'tarball',
    'image': 'plugins/download',
    'pull': 'always',
    'settings': {
      'username': {
        'from_secret': 'download_username',
      },
      'password': {
        'from_secret': 'download_password',
      },
      'source': config['version']['tarball'],
      'sha256': config['version']['tarball_sha'],
      'destination': '%s/owncloud-enterprise-complete.tar.bz2' % config['version']['base'],
    },
  }]

def prepublish(config):
  return [{
    'name': 'prepublish',
    'image': 'plugins/docker',
    'pull': 'always',
    'settings': {
      'username': {
        'from_secret': 'internal_username',
      },
      'password': {
        'from_secret': 'internal_password',
      },
      'tags': config['internal'],
      'dockerfile': '%s/Dockerfile.%s' % (config['version']['base'], config['arch']),
      'repo': 'registry.drone.owncloud.com/owncloud/enterprise',
      'registry': 'registry.drone.owncloud.com',
      'context': config['version']['base'],
      'purge': False,
    },
  }]

def sleep(config):
  return [{
    'name': 'sleep',
    'image': 'toolhippie/reg:latest',
    'pull': 'always',
    'environment': {
      'DOCKER_USER': {
        'from_secret': 'internal_username',
      },
      'DOCKER_PASSWORD': {
        'from_secret': 'internal_password',
      },
    },
    'commands': [
      'retry -- reg digest --username $DOCKER_USER --password $DOCKER_PASSWORD registry.drone.owncloud.com/owncloud/enterprise:%s' % config['internal'],
    ],
  }]

def trivy(config):
  if config['arch'] != 'amd64':
    return []

  return [
    {
      'name': 'database',
      'image': 'plugins/download',
      'pull': 'always',
      'settings': {
        'source': 'https://download.owncloud.com/internal/trivy.db',
        'destination': 'trivy/db/trivy.db',
        'username': {
          'from_secret': 'download_username',
        },
        'password': {
          'from_secret': 'download_password',
        },
      },
    },
    {
      'name': 'trivy',
      'image': 'toolhippie/trivy:latest',
      'pull': 'always',
      'environment': {
        'TRIVY_AUTH_URL': 'https://registry.drone.owncloud.com',
        'TRIVY_USERNAME': {
          'from_secret': 'internal_username',
        },
        'TRIVY_PASSWORD': {
          'from_secret': 'internal_password',
        },
        'TRIVY_SKIP_UPDATE': True,
        'TRIVY_NO_PROGRESS': True,
        'TRIVY_IGNORE_UNFIXED': True,
        'TRIVY_TIMEOUT': '5m',
        'TRIVY_EXIT_CODE': '1',
        'TRIVY_SEVERITY': 'HIGH,CRITICAL',
        'TRIVY_CACHE_DIR': '/drone/src/trivy'
      },
      'commands': [
        'retry -- trivy registry.drone.owncloud.com/owncloud/enterprise:%s' % config['internal'],
      ],
    },
  ]

def wait(config):
  return [{
    'name': 'wait',
    'image': 'owncloud/ubuntu:latest',
    'pull': 'always',
    'commands': [
      'wait-for-it -t 600 server:8080',
    ],
  }]

def api(config):
  return [{
    'name': 'tarball',
    'image': 'plugins/download',
    'pull': 'always',
    'settings': {
      'username': {
        'from_secret': 'download_username',
      },
      'password': {
        'from_secret': 'download_password',
      },
      'source': config['version']['qa'],
      'destination': 'owncloud-enterprise-complete-qa.tar.bz2',
    },
  },
  {
    'name': 'extract',
    'image': 'owncloudci/php:%s' % config['version']['php'],
    'pull': 'always',
    'commands': [
      'tar -xjf owncloud-enterprise-complete-qa.tar.bz2 -C /drone/src --strip 1',
    ],
  },
  {
    'name': 'version',
    'image': 'owncloudci/php:%s' % config['version']['php'],
    'pull': 'always',
    'commands': [
      'cat version.php',
    ],
  },
  {
    'name': 'behat',
    'image': 'owncloudci/php:%s' % config['version']['php'],
    'pull': 'always',
    'commands': [
      'mkdir -p vendor-bin/behat',
      'wget -O vendor-bin/behat/composer.json https://raw.githubusercontent.com/owncloud/core/%s/vendor-bin/behat/composer.json' % versionize(config['version']),
      'cd vendor-bin/behat/ && composer install',
    ],
  },
  {
    'name': 'tests',
    'image': 'owncloudci/php:%s' % config['version']['php'],
    'pull': 'always',
    'environment': {
      'TEST_SERVER_URL': 'http://server:8080',
      'SKELETON_DIR': '/mnt/data/apps/testing/data/apiSkeleton',
    },
    'commands': [
      'bash tests/acceptance/run.sh --remote --tags "@smokeTest&&~@skip&&~@skipOnDockerContainerTesting" --type api --part %d %d' % (config['step'], config['split']),
    ],
  }]

def ui(config):
  return [{
    'name': 'tarball',
    'image': 'plugins/download',
    'pull': 'always',
    'settings': {
      'username': {
        'from_secret': 'download_username',
      },
      'password': {
        'from_secret': 'download_password',
      },
      'source': config['version']['qa'],
      'destination': 'owncloud-enterprise-complete-qa.tar.bz2',
    },
  },
  {
    'name': 'extract',
    'image': 'owncloudci/php:%s' % config['version']['php'],
    'pull': 'always',
    'commands': [
      'tar -xjf owncloud-enterprise-complete-qa.tar.bz2 -C /drone/src --strip 1',
    ],
  },
  {
    'name': 'version',
    'image': 'owncloudci/php:%s' % config['version']['php'],
    'pull': 'always',
    'commands': [
      'cat version.php',
    ],
  },
  {
    'name': 'behat',
    'image': 'owncloudci/php:%s' % config['version']['php'],
    'pull': 'always',
    'commands': [
      'mkdir -p vendor-bin/behat',
      'wget -O vendor-bin/behat/composer.json https://raw.githubusercontent.com/owncloud/core/%s/vendor-bin/behat/composer.json' % versionize(config['version']),
      'cd vendor-bin/behat/ && composer install',
    ],
  },
  {
    'name': 'tests',
    'image': 'owncloudci/php:%s' % config['version']['php'],
    'pull': 'always',
    'environment': {
      'TEST_SERVER_URL': 'http://server:8080',
      'SKELETON_DIR': '/mnt/data/apps/testing/data/webUISkeleton',
      'BROWSER': 'chrome',
      'SELENIUM_HOST': 'selenium',
      'SELENIUM_PORT': '4444',
      'PLATFORM': 'Linux',
      'MAILHOG_HOST': 'email',
      'LOCAL_MAILHOG_HOST': 'email',
    },
    'commands': [
      'bash tests/acceptance/run.sh --remote --tags "@smokeTest&&~@skip&&~@skipOnDockerContainerTesting" --type webUI --part %d %d' % (config['step'], config['split']),
    ],
  }]

def tests(config):
  return [{
    'name': 'test',
    'image': 'owncloud/ubuntu:latest',
    'pull': 'always',
    'commands': [
      'curl -sSf http://server:8080/status.php',
    ],
  }]

def publish(config):
  return [{
    'name': 'publish',
    'image': 'plugins/docker',
    'pull': 'always',
    'settings': {
      'username': {
        'from_secret': 'private_username',
      },
      'password': {
        'from_secret': 'private_password',
      },
      'tags': config['tag'],
      'dockerfile': '%s/Dockerfile.%s' % (config['version']['base'], config['arch']),
      'repo': 'registry.owncloud.com/owncloud/enterprise',
      'registry': 'registry.owncloud.com',
      'context': config['version']['base'],
      'cache_from': 'registry.drone.owncloud.com/owncloud/enterprise:%s' % config['internal'],
      'pull_image': False,
    },
    'when': {
      'ref': [
        'refs/heads/master',
      ],
    },
  }]

def cleanup(config):
  return [{
    'name': 'cleanup',
    'image': 'toolhippie/reg:latest',
    'pull': 'always',
    'failure': 'ignore',
    'environment': {
      'DOCKER_USER': {
        'from_secret': 'internal_username',
      },
      'DOCKER_PASSWORD': {
        'from_secret': 'internal_password',
      },
    },
    'commands': [
      'reg rm --username $DOCKER_USER --password $DOCKER_PASSWORD registry.drone.owncloud.com/owncloud/enterprise:%s' % config['internal'],
    ],
  }]

def versionize(version):
  if 'behat_version' in version:
    raw_version = version['behat_version']
  else:
    raw_version = version['value']
  return 'v%s' % (raw_version.replace("rc", "RC").replace("-", ""))
