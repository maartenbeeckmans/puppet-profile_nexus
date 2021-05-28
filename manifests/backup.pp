#
#
#
class profile_nexus::backup (
  Stdlib::AbsolutePath $data_path = $::profile_nexus::data_path,
) {
  include profile_rsnapshot::user

  @@rsnapshot::backup{ "backup ${facts['networking']['fqdn']} nexus-data":
    source     => "rsnapshot@${facts['networking']['fqdn']}:${data_path}",
    target_dir => "${facts['networking']['fqdn']}/nexus-data",
    tag        => lookup('rsnapshot_tag', String, undef, 'rsnapshot'),
  }
}
