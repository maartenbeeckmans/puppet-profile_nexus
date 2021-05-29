#
#
#
class profile_nexus (
  String                     $version,
  String                     $revision,
  Stdlib::Absolutepath       $data_path,
  Stdlib::Absolutepath       $data_device,
  Stdlib::Host               $listen_address,
  Stdlib::Port::Unprivileged $port,
  Boolean                    $manage_firewall_entry,
  String                     $sd_service_name,
  Array                      $sd_service_tags,
  String                     $admin_username,
  String                     $admin_password,
  Boolean                    $nexus_backup,
  Hash                       $users,
  Hash                       $user_defaults,
  Hash                       $blobstores,
  Hash                       $blobstore_defaults,
  Hash                       $repositories,
  Hash                       $repository_defaults,
  Hash                       $repository_groups,
  Hash                       $repository_group_defaults,
  Boolean                    $manage_sd_service       = lookup('manage_sd_service', Boolean, first, true),
) {
  class { 'java':
    package => 'java-1.8.0-openjdk',
  }

  exec { $data_path:
    path    => $::path,
    command => "mkdir -p ${data_path}",
    unless  => "test -d ${data_path}",
  }
  -> profile_base::mount{ $data_path:
    device => $data_device,
    mkdir  => false,
  }

  class { 'nexus':
    download_site => 'https://download.sonatype.com/nexus/3',
    version       => $version,
    revision      => $revision,
    nexus_type    => 'unix',
    nexus_root    => $data_path,
    nexus_host    => '0.0.0.0',
    nexus_port    => $port,
  }

  include profile_nexus::config


  if $nexus_backup {
    include profile_nexus::backup
  }

  Class['java'] -> Class['nexus']
  Profile_base::Mount[$data_path] -> Class['nexus']
}
