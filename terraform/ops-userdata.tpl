#cloud-config

package_update: true

package_upgrade: true

packages:
 - awscli
 - curl
 - git
 - build-essential

bootcmd:
 - echo 127.0.1.1 ${hostname}.${domainname} ${hostname} >> /etc/hosts
 - hostname ${hostname}.${domainname}

preserve_hostname: true

write_files:
 - path: /etc/chef/client.rb
   content: |
     log_level :info
     log_location STDOUT
     chef_server_url 'https://chef-server.internal.devops-demo.co.uk/organizations/devops-demo'
     validation_client_name 'devops-demo-validator'

runcmd:
 - curl -s https://packagecloud.io/install/repositories/chef/stable/script.deb.sh | sudo bash
 - apt-get -y -qq install chefdk
 - mkdir /var/chef-solo
 - chown ubuntu /var/chef-solo
 - cd /var/chef-solo
 - sudo -u ubuntu git clone https://github.com/darrin-wortlehock/devops-demo.git
 - cd devops-demo
 - sudo -u ubuntu berks vendor cookbooks
 - chef-solo -c solo/solo.rb -j solo/ops.json
 - until aws s3 ls s3://${secrets_bucket} --region=${aws_region} | grep -q "devops-demo-validator.pem"; do echo "waiting for s3://${secrets_bucket}/devops-demo-validator.pem ..."; sleep 10; done;
 - aws s3 cp s3://${secrets_bucket}/devops-demo-validator.pem /etc/chef/validation.pem --region=${aws_region}
 - aws s3 cp s3://${secrets_bucket}/chef-server.internal.devops-demo.co.uk.crt /etc/chef/trusted_certs/ --region=${aws_region}
 - aws s3 cp s3://${secrets_bucket}/deploy.pem /etc/chef/deploy.pem --region=${aws_region}
 - chef-client
 - echo "Finished."
