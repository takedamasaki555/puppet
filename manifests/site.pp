
## site.pp ##

# This file (/etc/puppetlabs/puppet/manifests/site.pp) is the main entry point
# used when an agent connects to a master and asks for an updated configuration.
#
# Global objects like filebuckets and resource defaults should go in this file,
# as should the default node definition. (The default node can be omitted
# if you use the console and don't define any other nodes in site.pp. See
# http://docs.puppetlabs.com/guides/language_guide.html#nodes for more on
# node definitions.)

## Active Configurations ##

# PRIMARY FILEBUCKET
# This configures puppet agent and puppet inspect to back up file contents when
# they run. The Puppet Enterprise console needs this to display file contents
# and differences.

# Define filebucket 'main':
filebucket { 'main':
  server => 'puppet-decode',
  path   => false,
}

# Make filebucket 'main' the default backup location for all File resources:
File { backup => 'main' }

# DEFAULT NODE
# Node definitions in this file are merged with node data from the console. See
# http://docs.puppetlabs.com/guides/language_guide.html#nodes for more on
# node definitions.

# The default node definition matches any node lacking a more specific node
# definition. If there are no other nodes in this file, classes declared here
# will be included in every node's catalog, *in addition* to any classes
# specified in the console for that node.

node default {
    # This is where you can declare classes for all nodes.

    if $osfamily =='Windows' {
        Class['install_webpi'] -> Class['install_iis'] -> Class['add_website']
        include install_webpi, install_iis, add_website
    }
}

class install_webpi {
    file { "c:/chocolatey.ps1":
        ensure => file,
        source => "puppet:///files/chocolatey.ps1",
        source_permissions => ignore,
    }

    exec { install_chocolatey :
        command  =>'c:\chocolatey.ps1',
        provider => powershell,
        subscribe => File["c:/chocolatey.ps1"],
    }

    package { 'webpi':
        ensure          => installed,
        provider        => 'chocolatey',
        require         => Exec['install_chocolatey'],
    }
}

class install_iis {
    exec { webpi_iis:
        command  =>'& "C:\Program Files\Microsoft\Web Platform Installer\webpicmd.exe" /install /Products:IIS7 /AcceptEULA',
        provider => powershell,
    }
}

class add_website {
    iis::manage_app_pool {'decode_application_pool':
        enable_32_bit           => true,
        managed_runtime_version => 'v4.0',
    }

    iis::manage_site {'decode':
        site_path     => 'C:\inetpub\decode',
        port          => '8080',
        ip_address    => '*',
        #host_header   => 'www.mysite.com',
        app_pool      => 'decode_application_pool'
    }

    iis::manage_virtual_application {'decode_app1':
        site_name   => 'decode',
        site_path   => 'C:\inetpub\decode_app1',
        app_pool    => 'decode_application_pool'
    }
}
