#
#
#
define profile_nexus::repository (
  Optional[String]            $index_type             = undef,
  Enum['proxy', 'hosted']     $type                   = 'hosted',
  Profile_nexus::ProviderType $provider_type          = 'raw',
  String                      $blobstore_name         = 'default',
  Optional[Integer]           $http_port              = undef,
  Optional[String]            $remote_url             = undef,
  Optional[String]            $distribution           = undef,
  Boolean                     $manage_firewall_entry  = true,
  Boolean                     $manage_sd_service      = lookup('manage_sd_service', Boolean, first, true),
  String                      $sd_service_name        = "nexus_repo_${title}",
  Array                       $sd_service_tags        = [],
  Stdlib::Host                $listen_address         = $::profile_nexus::listen_address,
  Stdlib::Port::Unprivileged  $port                   = $::profile_nexus::port,
) {
  if $type == 'proxy' {
    $_remote_url = $remote_url
    $_write_policy = undef
  } else {
    $_remote_url = undef
    $_write_policy = 'allow_write'
  }

  if $http_port and $manage_firewall_entry {
    firewall{"0${http_port} allow nexus repository ${title}":
      proto  => 'tcp',
      dport  => $http_port,
      action => 'accept',
    }
  }

  nexus3_repository { $title:
    index_type                     => $index_type,
    type                           => $type,
    provider_type                  => $provider_type,
    online                         => true,
    blobstore_name                 => $blobstore_name,
    strict_content_type_validation => true,
    http_port                      => $http_port,
    write_policy                   => $_write_policy,
    remote_url                     => $remote_url,
    remote_auth_type               => 'none',
    distribution                   => $distribution,
  }


  if $http_port and $manage_sd_service {
    consul::service { $sd_service_name:
      checks => [
        {
          tcp      => "${listen_address}:${http_port}",
          interval => '10s'
        }
      ],
      port   => $http_port,
      tags   => $sd_service_tags,
    }
  }
}
