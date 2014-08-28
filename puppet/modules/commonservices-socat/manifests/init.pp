#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

class commonservices-socat {

  package { 'socat':
    ensure => present,
  }

  case $operatingsystem {
     centos: {
       file {'/lib/systemd/system/socat.service':
         ensure => file,
         mode   => '0640',
         owner  => 'root',
         group  => 'root',
         source  => 'puppet:///modules/commonservices-socat/socat.service',
         notify => Service[socat],
       }
       service {'socat':
         ensure     => running,
         enable     => true,
         hasrestart => true,
         hasstatus  => true,
       }
     }
     debian: {
       file {'/etc/default/socat.conf':
         ensure => file,
         mode   => '0640',
         owner  => 'root',
         group  => 'root',
         source  => 'puppet:///modules/commonservices-socat/socat.conf',
         notify => Service[socat],
       }
       service {'socat':
         ensure     => running,
         enable     => true,
         hasrestart => true,
         hasstatus  => true,
         require    => File['/etc/default/socat.conf'],
       }
     }
  }
}