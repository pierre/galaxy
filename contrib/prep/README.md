galaxy prep
===========

prep is a script to create a local galaxy environment with a gonsole
and a number of agents.

Ruby needs to be installed. It is recommended to use rvm to manage
ruby and gems. See https://rvm.beginrescueend.com/ for details.

Install galaxy as a gem by running

% rake gem
% gem install pkg/galaxy-<version>.gem

in the root folder. 

prep requires a configuration file, usually called env.yaml:

base:            /home/henning/galaxy
slots:           s0,s1,s2,s3,s4,s5,v0,v1,v2,v3,z0
hostname:        machine.local
internal-ip:     127.0.0.1
external-ip:     172.16.0.1
agent-template:  sample-agent.erb
config-template: sample-config.erb
user:            henning

base:            *Required*. Folder into which the local galaxy is installed. 
slots:           *Required*. The slots created on the local galaxy install
hostname:        *Required*. Hostname for the local install. Can be "localhost" or "xyz.local"
internal-ip:     *Required*. "Internal IP" resource. Can be 127.0.0.1 or any other IP.
external-ip:     *Optional* "External-IP" resource. Can be omitted (then it is the same as internal-ip) or the same as internal-ip.
agent-template:  *Required*. An ERB template for the agent configuration. See the included agent-sample.erb
config-template: *Required*. An ERB template for the console/command line configration. See the included config-sample.erb
user:            *Optional*. The user to run the console and agent as. If omitted, the current user is used.

This file must exist and readable for the galaxy-prep.rb script. Invoke the script as

% ./galaxy-prep.rb env.yaml

This creates the galaxy environment in the base folder above. Then start the galaxy environment using

% cd /home/henning/galaxy
% eval `./start-galaxy.sh`
% galaxy show 

machine-s0   development -                                             unknown    -                                        -                    machine.local  -               online  
machine-s1   development -                                             unknown    -                                        -                    machine.local  -               online  
machine-s2   development -                                             unknown    -                                        -                    machine.local  -               online  
machine-s3   development -                                             unknown    -                                        -                    machine.local  -               online  
machine-s4   development -                                             unknown    -                                        -                    machine.local  -               online  
machine-s5   development -                                             unknown    -                                        -                    machine.local  -               online  
machine-v0   development -                                             unknown    -                                        -                    machine.local  -               online  
machine-v1   development -                                             unknown    -                                        -                    machine.local  -               online  
machine-v2   development -                                             unknown    -                                        -                    machine.local  -               online  
machine-v3   development -                                             unknown    -                                        -                    machine.local  -               online  
machine-z0   development -                                             unknown    -                                        -                    machine.local  -               online  


Configuration templates
=======================

prep requires two templates to create agent specific and general
config files. They are referenced in the yaml configuration file as
'agent-template' and 'config-template'. An agent template is written
for every galaxy agent started (there is one agent for every slot
managed) and a global config template for the console and the command
line tool.

In the agent template, the server for configuration and binaries must be adjusted:

galaxy.agent.http_user:          config-user
galaxy.agent.http_password:      config-password
galaxy.agent.config-root:        http://some.server/config
galaxy.agent.binaries-root:      http://some.server/binaries

The config template normally does not need customization.

See the source for galaxy-prep.rb for available template variables.

An additional template, script.erb, is used to create the start and stop scripts.
