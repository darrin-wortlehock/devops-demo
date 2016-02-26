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
 - path: /tmp/config.rb
   content: |
     log_level :info
     log_location STDOUT
     chef_server_url 'https://chef-server.internal.devops-demo.co.uk/organizations/devops-demo'
     node_name 'deploy'
     client_key '/home/ubuntu/.chef/deploy.pem'

 - path: /tmp/config.json
   content: |
     {
       "ssl": {
         "verify": false
       }
     }

 - path: /tmp/Berksfile
   content: |
     source 'https://supermarket.chef.io'

     cookbook 'devops-demo', github: 'darrin-wortlehock/devops-demo-cookbook'
     cookbook 'gocd', github: 'darrin-wortlehock/go-cookbook', branch: 'fix-missing-metadata' # rubocop:disable Metrics/LineLength

 - path: /etc/chef/client.rb
   content: |
     log_level :info
     log_location STDOUT
     chef_server_url 'https://chef-server.internal.devops-demo.co.uk/organizations/devops-demo'
     validation_client_name 'devops-demo-validator'

runcmd:
 - echo ######## Installing ChefDK ########
 - curl -s https://packagecloud.io/install/repositories/chef/stable/script.deb.sh | sudo bash
 - apt-get -y -qq install chefdk
 - echo ######## Creating Chef Repo  ########
 - cd /home/ubuntu
 - sudo -u ubuntu mkdir .chef
 - mv /tmp/config.rb .chef/
 - chown ubuntu:ubuntu .chef/config.rb
 - sudo -u ubuntu mkdir .berkshelf
 - mv /tmp/config.json .berkshelf/
 - chown ubuntu:ubuntu .berkshelf/config.json
 - sudo -u ubuntu chef generate app chef-repo
 - cd chef-repo
 - mv /tmp/Berksfile .
 - chown ubuntu:ubuntu Berksfile
 - sudo -u ubuntu berks install
 - echo ######## Waiting For Chef Server ########
 - until aws s3 ls s3://${secrets_bucket} --region=${aws_region} | grep -q "devops-demo-validator.pem"; do echo "waiting for s3://${secrets_bucket}/devops-demo-validator.pem ..."; sleep 10; done;
 - aws s3 cp s3://${secrets_bucket}/devops-demo-validator.pem /etc/chef/validation.pem --region=${aws_region}
 - aws s3 cp s3://${secrets_bucket}/chef-server.internal.devops-demo.co.uk.crt /etc/chef/trusted_certs/ --region=${aws_region}
 - aws s3 cp s3://${secrets_bucket}/deploy.pem /home/ubuntu/.chef/deploy.pem --region=${aws_region}
 - echo ######## Uploading Cookbooks ########
 - sudo -u ubuntu berks upload
 - echo ######## Converging Node ########
 - chef-client
 - echo ######## Finished Provisioning ########
