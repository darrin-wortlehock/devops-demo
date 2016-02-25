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
  - su - -c 'apt-get -y -qq install chef-server-core'
  - su - -c 'chef-server-ctl reconfigure'
  - su - -c 'chef-server-ctl user-create ${chef_admin_user_name} ${chef_admin_user_full_name} ${chef_admin_user_email} ${chef_admin_user_password} --filename /tmp/admin.pem'
  - su - -c 'chef-server-ctl org-create ${chef_org_name} ${chef_org_full_name} --association_user ${chef_user_name} --filename /tmp/devops-demo-validator.pem'
  - su - -c 'chef-server-ctl user-create ${chef_deploy_user_name} ${chef_deploy_user_full_name} ${chef_deploy_user_email} ${chef_deploy_user_password} --filename /tmp/deploy.pem'
  - su - -c 'chef-server-ctl install opscode-manage'
  - su - -c 'chef-server-ctl reconfigure'
  - su - -c 'opscode-manage-ctl reconfigure'
  - su - -c 'chef-server-ctl install opscode-reporting'
  - su - -c 'chef-server-ctl reconfigure'
  - su - -c 'opscode-reporting-ctl reconfigure'
  - aws s3 cp /var/opt/opscode/nginx/ca/chef-server.internal.devops-demo.co.uk.crt s3://${secrets_bucket}/ --region=${aws_region}
  - aws s3 cp /tmp/admin.pem s3://${secrets_bucket}/ --region=${aws_region}
  - aws s3 cp /tmp/deploy.pem s3://${secrets_bucket}/ --region=${aws_region}
  - aws s3 cp /tmp/devops-demo-validator.pem s3://${secrets_bucket}/ --region=${aws_region}
  - echo "Finished"
