galaxy prep
===========

prep is a script to create a local galaxy environment with a gonsole and a number of agents. 

It requires a configuration file, env.yaml:

base:            /home/henning/galaxy
slots:           s0,s1,s2,s3,s4,s5,v0,v1,v2,v3,z0
hostname:        machine.local
internal-ip:     127.0.0.1
external-ip:     172.16.0.1
agent-template:  sample-agent.erb
config-template: sample-config.erb

base:            Folder into which the local galaxy is installed. 
slots:           The slots created on the local galaxy install
hostname:        Hostname for the local install. Can be "localhost" or "xyz.local"
internal-ip:     "Internal IP" resource. Can be 127.0.0.1 or any other IP.
external-ip:     "External-IP" resource. Can be omitted (then it is the same as internal-ip) or the same as internal-ip.
agent-template:  An ERB template for the agent configuration. See the included agent-sample.erb
config-template: An ERB template for the console/command line configration. See the included config-sample.erb

This file must exist and readable for the galaxy-prep.rb script. Invoke the script as

% ./galaxy-prep.rb env.yaml

This creates the galaxy environment in the base folder above. Then start the galaxy environment using

% cd /home/henning/galaxy
% .eval `/start-galaxy.sh`
export GALAXY_CONFIG=/home/henning/galaxy/config/galaxy.conf
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


