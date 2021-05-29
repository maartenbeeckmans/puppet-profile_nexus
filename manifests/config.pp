#
#
#
class profile_nexus::config (
  Stdlib::Absolutepath       $data_path                 = $::profile_nexus::data_path,
  Boolean                    $manage_firewall_entry     = $::profile_nexus::manage_firewall_entry,
  Boolean                    $manage_sd_service         = $::profile_nexus::manage_sd_service,
  String                     $sd_service_name           = $::profile_nexus::sd_service_name,
  Array                      $sd_service_tags           = $::profile_nexus::sd_service_tags,
  String                     $admin_username            = $::profile_nexus::admin_username,
  String                     $admin_password            = $::profile_nexus::admin_password,
  Stdlib::Host               $listen_address            = $::profile_nexus::listen_address,
  Stdlib::Port::Unprivileged $port                      = $::profile_nexus::port,
  Hash                       $users                     = $::profile_nexus::users,
  Hash                       $user_defaults             = $::profile_nexus::user_defaults,
  Hash                       $blobstores                = $::profile_nexus::blobstores,
  Hash                       $blobstore_defaults        = $::profile_nexus::blobstore_defaults,
  Hash                       $repositories              = $::profile_nexus::repositories,
  Hash                       $repository_defaults       = $::profile_nexus::repository_defaults,
  Hash                       $repository_groups         = $::profile_nexus::repository_groups,
  Hash                       $repository_group_defaults = $::profile_nexus::repository_group_defaults,
) {
  if $manage_firewall_entry {
    firewall { "0${port} accept nexus ui":
      dport  => $port,
      proto  => 'tcp',
      action => 'accept',
    }
  }

  if $manage_sd_service {
    consul::service { $sd_service_name:
      checks => [
        {
          http     => "http://${listen_address}:${port}",
          interval => '10s'
        }
      ],
      port   => $port,
      tags   => $sd_service_tags,
    }
  }

  ini_setting { 'storage.diskCache.diskFreeSpaceLimit':
    ensure  => present,
    path    => "${data_path}/nexus/etc/karaf/system.properties",
    setting => 'storage.diskCache.diskFreeSpaceLimit',
    value   => 512,
    notify  => Service['nexus'],
  }

  ini_setting { 'nexus.scripts.allowCreation':
    ensure  => present,
    path    => "${data_path}/sonatype-work/nexus3/etc/nexus.properties",
    setting => 'nexus.scripts.allowCreation',
    value   => true,
    notify  => Service['nexus'],
  }

  $_nexus3_rest_config = {
    'admin_username' => $admin_username,
    'admin_password' => $admin_password,
    'nexus_base_url' => "http://${listen_address}:${port}",
  }

  file { '/etc/puppetlabs/puppet/nexus3_rest.conf':
    ensure  => present,
    mode    => '0755',
    content => epp("${module_name}/nexus3_rest.conf.epp", $_nexus3_rest_config),
  }

  # set admin password
  nexus3_admin_password { 'admin_password':
    admin_password_file => '/opt/sonatype-work/nexus3/admin.password',
    password            => $admin_password,
  }

  # disable anonymous access
  nexus3_anonymous_settings { 'global':
    enabled  => false,
    realm    => 'Local Authorizatioon Realm',
    username => 'anonymous',
  }

  # disable anonymous user
  nexus3_user { 'anonymous':
    firstname => 'Anonymous',
    lastname  => 'User',
    password  => 'unrelevantpw',   #only used while creating the user
    email     => 'anonymous@example.org',
    read_only => bool2str(false),
    roles     => ['nx-anonymous'],
    status    => 'disabled',
  }

  create_resources( nexus3_user, $users, $user_defaults )
  create_resources( nexus3_blobstore, $blobstores, $blobstore_defaults)
  create_resources( profile_nexus::repository, $repositories, $repository_defaults)
  create_resources( profile_nexus::repository_group, $repository_groups, $repository_group_defaults)
}
