require 'spec_helper_acceptance'

case fact('osfamily')
when 'RedHat'
  conf_dir = '/etc/httpd/conf'
  confd_dir = '/etc/httpd/conf.d'
  conf_file = '/etc/httpd/conf/httpd.conf'
  ports_file = '/etc/httpd/conf/ports.conf'
  vhost = '/etc/httpd/conf.d/15-default.conf'
  service_name = 'httpd'
  package_name = 'httpd'
when 'Debian'
  conf_dir = '/etc/apache2/conf.d'
  confd_dir = '/etc/apache2/conf.d'
  conf_file = '/etc/apache2/conf/apache2.conf'
  ports_file = '/etc/httpd/conf/ports.conf'
  vhost = '/etc/httpd/conf.d/15-default.conf'
  service_name = 'apache2'
  package_name = 'apache2'
end

describe 'apache parameters' do

  # Currently this test only does something on FreeBSD.
  describe 'default_confd_files => false' do
    it 'doesnt do anything' do
      pp = "class { 'apache': default_confd_files => false }"
      apply_manifest(pp, :catch_failures => true)
    end

    if fact('osfamily') == 'FreeBSD'
      describe file("#{confd_dir}/no-accf.conf.erb") do
        it { should_not be_file }
      end
    end
  end
  describe 'default_confd_files => true' do
    it 'copies conf.d files' do
      pp = "class { 'apache': default_confd_files => true }"
      apply_manifest(pp, :catch_failures => true)
    end

    if fact('osfamily') == 'FreeBSD'
      describe file("#{confd_dir}/no-accf.conf.erb") do
        it { should be_file }
      end
    end
  end

  describe 'when set adds a listen statement' do
    it 'applys cleanly' do
      pp = "class { 'apache': ip => '10.1.1.1', service_ensure => stopped }"
      apply_manifest(pp, :catch_failures => true)
    end

    describe file(ports_file) do
      it { should be_file }
      it { should contain 'Listen 10.1.1.1' }
    end
  end

  describe 'service tests => true' do
    it 'starts the service' do
      pp = <<-EOS
        class { 'apache':
          service_enable => true,
          service_ensure => running,
        }
      EOS
      apply_manifest(pp, :catch_failures => true)
    end

    describe service(service_name) do
      it { should be_running }
      it { should be_enabled }
    end
  end

  describe 'service tests => false' do
    it 'stops the service' do
      pp = <<-EOS
        class { 'apache':
          service_enable => false,
          service_ensure => stopped,
        }
      EOS
      apply_manifest(pp, :catch_failures => true)
    end

    describe service(service_name) do
      it { should_not be_running }
      it { should_not be_enabled }
    end
  end

  describe 'purge parameters => false' do
    it 'applies cleanly' do
      pp = <<-EOS
        class { 'apache':
          purge_configs => false,
          purge_vdir    => false,
        }
      EOS
      shell("touch #{confd_dir}/test.conf")
      apply_manifest(pp, :catch_failures => true)
    end

    # Ensure the file didn't disappear.
    describe file("#{confd_dir}/test.conf") do
      it { should be_file }
    end
  end

  describe 'purge parameters => true' do
    it 'applies cleanly' do
      pp = <<-EOS
        class { 'apache':
          purge_configs => true,
          purge_vdir    => true,
        }
      EOS
      shell("touch #{confd_dir}/test.conf")
      apply_manifest(pp, :catch_failures => true)
    end

    # File should be gone
    describe file("#{confd_dir}/test.conf") do
      it { should_not be_file }
    end
  end

  describe 'serveradmin' do
    it 'applies cleanly' do
      pp = "class { 'apache': serveradmin => 'test@example.com' }"
      apply_manifest(pp, :catch_failures => true)
    end

    describe file(vhost) do
      it { should be_file }
      it { should contain 'ServerAdmin test@example.com' }
    end
  end

  describe 'sendfile' do
    describe 'setup' do
      it 'applies cleanly' do
        pp = "class { 'apache': sendfile => 'On' }"
        apply_manifest(pp, :catch_failures => true)
      end
    end

    describe file(conf_file) do
      it { should be_file }
      it { should contain 'EnableSendfile On' }
    end

    describe 'setup' do
      it 'applies cleanly' do
        pp = "class { 'apache': sendfile => 'Off' }"
        apply_manifest(pp, :catch_failures => true)
      end
    end

    describe file(conf_file) do
      it { should be_file }
      it { should contain 'Sendfile Off' }
    end
  end

  describe 'error_documents' do
    describe 'setup' do
      it 'applies cleanly' do
        pp = "class { 'apache': error_documents => true }"
        apply_manifest(pp, :catch_failures => true)
      end
    end

    describe file(conf_file) do
      it { should be_file }
      it { should contain 'Alias /error/' }
    end
  end

  describe 'timeout' do
    describe 'setup' do
      it 'applies cleanly' do
        pp = "class { 'apache': timeout => '1234' }"
        apply_manifest(pp, :catch_failures => true)
      end
    end

    describe file(conf_file) do
      it { should be_file }
      it { should contain 'Timeout 1234' }
    end
  end

  describe 'httpd_dir' do
    describe 'setup' do
      it 'applies cleanly' do
        pp = <<-EOS
          class { 'apache': httpd_dir => '/tmp', service_ensure => stopped }
          include 'apache::mod::nss'
        EOS
        apply_manifest(pp, :catch_failures => true)
      end
    end

    describe file("#{confd_dir}/nss.conf") do
      it { should be_file }
      it { should contain 'NSSCertificateDatabase /tmp/alias' }
    end
  end

  describe 'server_root' do
    describe 'setup' do
      it 'applies cleanly' do
        pp = "class { 'apache': server_root => '/tmp/root', service_ensure => stopped }"
        apply_manifest(pp, :catch_failures => true)
      end
    end

    describe file(conf_file) do
      it { should be_file }
      it { should contain 'ServerRoot "/tmp/root"' }
    end
  end

  describe 'confd_dir' do
    describe 'setup' do
      it 'applies cleanly' do
        pp = "class { 'apache': confd_dir => '/tmp/root', service_ensure => stopped }"
        apply_manifest(pp, :catch_failures => true)
      end
    end

    describe file(conf_file) do
      it { should be_file }
      it { should contain 'Include /tmp/root/*.conf' }
    end
  end

  describe 'conf_template' do
    describe 'setup' do
      it 'applies cleanly' do
        pp = "class { 'apache': conf_template => 'another/test.conf.erb', service_ensure => stopped }"
        shell('mkdir -p /etc/puppet/modules/another/templates')
        shell('echo "testcontent" >> /etc/puppet/modules/another/templates/test.conf.erb')
        apply_manifest(pp, :catch_failures => true)
      end
    end

    describe file(conf_file) do
      it { should be_file }
      it { should contain 'testcontent' }
    end
  end

  describe 'servername' do
    describe 'setup' do
      it 'applies cleanly' do
        pp = "class { 'apache': servername => 'test.server', service_ensure => stopped }"
        apply_manifest(pp, :catch_failures => true)
      end
    end

    describe file(conf_file) do
      it { should be_file }
      it { should contain 'ServerName "test.server"' }
    end
  end

  describe 'user' do
    describe 'setup' do
      it 'applies cleanly' do
        pp = <<-EOS
          class { 'apache':
            manage_user  => true,
            manage_group => true,
            user         => 'testweb',
            group        => 'testweb',
          }
        EOS
        apply_manifest(pp, :catch_failures => true)
      end
    end

    describe user('testweb') do
      it { should exist }
      it { should belong_to_group 'testweb' }
    end

    describe group('testweb') do
      it { should exist }
    end
  end

  describe 'keepalive' do
    describe 'setup' do
      it 'applies cleanly' do
        pp = "class { 'apache': keepalive => 'On', keepalive_timeout => '30' }"
        apply_manifest(pp, :catch_failures => true)
      end
    end

    describe file(conf_file) do
      it { should be_file }
      it { should contain 'KeepAlive On' }
      it { should contain 'KeepAliveTimeout 30' }
    end
  end

  describe 'logging' do
    describe 'setup' do
      it 'applies cleanly' do
        pp = "class { 'apache': logroot => '/tmp' }"
        apply_manifest(pp, :catch_failures => true)
      end
    end

    describe file('/tmp/error_log') do
      it { should be_file }
    end
  end

  describe 'ports_file' do
    it 'applys cleanly' do
      pp = <<-EOS
        class { 'apache':
          ports_file     => '/tmp/ports_file',
          ip             => '10.1.1.1',
          service_ensure => stopped
        }
      EOS
      apply_manifest(pp, :catch_failures => true)
    end

    describe file('/tmp/ports_file') do
      it { should be_file }
      it { should contain 'Listen 10.1.1.1' }
    end
  end

  describe 'server_tokens' do
    it 'applys cleanly' do
      pp = <<-EOS
        class { 'apache':
          server_tokens  => 'testtokens',
        }
      EOS
      apply_manifest(pp, :catch_failures => true)
    end

    describe file(conf_file) do
      it { should be_file }
      it { should contain 'ServerTokens testtokens' }
    end
  end

  describe 'server_signature' do
    it 'applys cleanly' do
      pp = <<-EOS
        class { 'apache':
          server_signature  => 'testsig',
          service_ensure    => stopped,
        }
      EOS
      apply_manifest(pp, :catch_failures => true)
    end

    describe file(conf_file) do
      it { should be_file }
      it { should contain 'ServerSignature testsig' }
    end
  end

  describe 'trace_enable' do
    it 'applys cleanly' do
      pp = <<-EOS
        class { 'apache':
          trace_enable  => 'Off',
        }
      EOS
      apply_manifest(pp, :catch_failures => true)
    end

    describe file(conf_file) do
      it { should be_file }
      it { should contain 'TraceEnable Off' }
    end
  end

  describe 'package_ensure' do
    it 'applys cleanly' do
      pp = <<-EOS
        class { 'apache':
          package_ensure  => present,
        }
      EOS
      apply_manifest(pp, :catch_failures => true)
    end

    describe package(package_name) do
      it { should be_installed }
    end
  end

end
