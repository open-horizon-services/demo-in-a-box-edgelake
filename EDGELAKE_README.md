The following steps are needed to install Edgelake demo-in-a-box


# Clone demo-in-a-box
git clone https://github.com/open-horizon-services/demo-in-a-box-edgelake

cd demo-in-a-box

# Set demo-in-a-box type.  Supports bicycle and unicyle
export SYSTEM_CONFIGURATION=bicycle

# Install exchange hub
make up hub

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
http://hostvmserverip:3001
