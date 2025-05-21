The following steps are needed to install Edgelake demo-in-a-box


# Clone demo-in-a-box
git clone -b edgelake-demo https://github.com/oshadman/demo-in-a-box

cd demo-in-a-box

# Set demo-in-a-box type.  Supports bicycle and unicyle
export SYSTEM_CONFIGURATION=bicycle

# Install exchange hub
make up-hub

# Load credentials
source mycreds.env

# Install agents
make up

# Log into vm and check status of hzn/edgelake
vagrant global-status

make connect-hub

make connect VMNAME=agent1

make connect VMNAME=agent2

# Access to Remote CLI
http://hostvmserverip:31800
