#cloud-config

package_update: true

package_upgrade: true

packages:
 - awscli

bootcmd:
 - echo 127.0.1.1 ${hostname}.${domainname} >> /etc/hosts
 - hostname ${hostname}.${domainname}

preserve_hostname: true

runcmd:
  - curl -s https://packagecloud.io/install/repositories/chef/stable/script.deb.sh | sudo bash
  - apt-get -y -qq install chef-server-core
  - chef-server-ctl reconfigure
  - chef-server-ctl user-create ${chef_user_name} "${chef_user_full_name}" ${chef_user_email} ${chef_user_password} --filename /tmp/admin.pem
  - chef-server-ctl org-create ${chef_org_name} "${chef_org_full_name}" --association_user ${chef_user_name} --filename /tmp/devops-demo-validator.pem
  - mkdir -p /etc/opscode/
  - chef-server-ctl install opscode-manage
  - chef-server-ctl reconfigure
  - opscode-manage-ctl reconfigure
  - chef-server-ctl install opscode-reporting
  - chef-server-ctl reconfigure
  - opscode-reporting-ctl reconfigure
  - chef-server-ctl reconfigure
  - aws s3 cp /tmp/admin.pem s3://${secrets_bucket}/ --region=${aws_region}
  - aws s3 cp /tmp/devops-demo-validator.pem s3://${secrets_bucket}/ --region=${aws_region}

  - echo "Finished"
