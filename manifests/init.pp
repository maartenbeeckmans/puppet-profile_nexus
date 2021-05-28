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
  Boolean                    $nexus_backup,
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
    nexus_host    => $listen_address,
    nexus_port    => $port,
  }

  if $manage_firewall_entry {
    firewall { "0${port} accept nexus":
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

  if $nexus_backup {
    include profile_nexus::backup
  }

  Class['java'] -> Class['nexus']
  Profile_base::Mount[$data_path] -> Class['nexus']
}
