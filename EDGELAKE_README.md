# clone demo-in-a-box
git clone -b edgelake-demo https://github.com/oshadman/demo-in-a-box
cd demo-in-a-box
make init

#install hzn cli
. mycreds.env
curl -sSL https://raw.githubusercontent.com/open-horizon/anax/refs/heads/master/agent-install/agent-install.sh | sudo -sE bash -s -- -i anax: -k ./agent-install.cfg -c css: -p IBM/pattern-ibm.helloworld -w '*' -T 120

# install grafana service
cd grafana
sudo -sE make publish

# install postgres service
cd ../postgres
sudo -sE make publish

# install edgelake services
cd ..
sudo -sE make publish IS_MANUAL=true EDGELAKE_TYPE=operator
sudo -sE make publish IS_MANUAL=true EDGELAKE_TYPE=query

# log into vm an check statuxs of hzn
vagrant global-status
vagrant ssh agent1
hzn agreement list
