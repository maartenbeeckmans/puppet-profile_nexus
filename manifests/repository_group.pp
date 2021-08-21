#
#
#
define profile_nexus::repository_group (
  Profile_nexus::ProviderType $provider_type          = 'raw',
  String                      $blobstore_name         = 'default',
  Optional[Integer]           $http_port              = undef,
  Array[String]               $repositories           = [],
  Boolean                     $manage_firewall_entry  = true,
  Boolean                     $manage_sd_service      = lookup('manage_sd_service', Boolean, first, true),
  String                      $sd_service_name        = "nexus-repo-group-${title}",
  Array                       $sd_service_tags        = [],
  Stdlib::Host                $listen_address         = $::profile_nexus::listen_address,
  Stdlib::Port::Unprivileged  $port                   = $::profile_nexus::port,
) {
  if $http_port and $manage_firewall_entry {
    firewall{"0${http_port} allow nexus repository group ${title}":
      proto  => 'tcp',
      dport  => $http_port,
      action => 'accept',
    }
  }

  nexus3_repository_group { $title:
    provider_type                  => $provider_type,
    online                         => true,
    blobstore_name                 => $blobstore_name,
    strict_content_type_validation => true,
    http_port                      => $http_port,
    repositories                   => $repositories,
  }

  if $manage_sd_service {
    consul::service { $sd_service_name:
      checks => [
        {
          tcp      => "${listen_address}:${port}",
          interval => '10s'
        }
      ],
      port   => $port,
      tags   => $sd_service_tags,
    }
  }
}
