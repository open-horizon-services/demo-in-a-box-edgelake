The following steps are needed to install Edgelake demo-in-a-box


# clone demo-in-a-box
git clone -b edgelake-demo https://github.com/oshadman/demo-in-a-box
cd demo-in-a-box

# set type.  Supports bicycle and unicyle
export SYSTEM_CONFIGURATION=bicycle

# install exchange hub
make up-hub

#load credentials
. mycreds.env

# install agents
make up

# log into vm an check status of hzn/edgelake
vagrant global-status
make attach agent1
make attach agent2
