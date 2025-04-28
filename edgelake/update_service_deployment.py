import argparse
import ast
import json
import os

try:
    FileNotFoundError
except NameError:
    FileNotFoundError = IOError

ROOT_DIR = os.path.dirname(os.path.expanduser(os.path.expandvars(__file__)))
FILE_PATH = os.path.join(ROOT_DIR, 'service.definition.json')
IGNORE_LIST = ["REMOTE_CLI", "ENABLE_NEBULA", "NEBULA_NEW_KEYS", "IS_LIGHTHOUSE", "CIDR_OVERLAY_ADDRESS",
               "LIGHTHOUSE_IP", "LIGHTHOUSE_NODE_IP"]
IS_BASE = True

BASE_POLICY = {
	"org": "$HZN_ORG_ID",
	"label": "$SERVICE_NAME for $ARCH",
	"description": "A service to deploy EdgeLake with Open Horizon",
	"documentation": "https://edgelake.github.io/",
	"url": "$SERVICE_NAME",
	"version": "$SERVICE_VERSION",
	"arch": "$ARCH",
	"public": True,
	"sharable": "singleton",
	"requiredServices": [],
	"userInput": [
		{
			"name": "ANYLOG_PATH",
			"label": "AnyLog dir path",
			"type": "string",
			"defaultValue": "/app"
		},
		{
			"name": "INIT_TYPE",
			"label": "Whether to deploy AnyLog or shell as a docker container",
			"type": "string",
			"defaultValue": "prod"
		},
		{
			"name": "DISABLE_CLI",
			"label": "Disable CLI",
			"type": "bool",
			"defaultValue": "false"
		},

		{
			"name": "NODE_TYPE",
			"label": "Information regarding which AnyLog node configurations to enable. By default, even if everything is disabled, AnyLog starts TCP and REST connection protocols",
			"type": "string",
			"defaultValue": "generic"
		},
		{
			"name": "NODE_NAME",
			"label": "Name of the AnyLog instance",
			"type": "string",
			"defaultValue": "anylog-node"
		},
		{
			"name": "COMPANY_NAME",
			"label": "Owner of the AnyLog instance",
			"type": "string",
			"defaultValue": "New Company"
		},
		{
			"name": "ANYLOG_SERVER_PORT",
			"label": "Port address used by AnyLog's TCP protocol to communicate with other nodes in the network",
			"type": "int",
			"defaultValue": "32548"
		},
		{
			"name": "ANYLOG_REST_PORT",
			"label": "Port address used by AnyLog's REST protocol",
			"type": "int",
			"defaultValue": "32549"
		},

		{
			"name": "TCP_BIND",
			"label": "A bool value that determines if to bind to a specific IP and Port (a false value binds to all IPs)",
			"type": "bool",
			"defaultValue": "false"
		},
		{
			"name": "REST_BIND",
			"label": "A bool value that determines if to bind to a specific IP and Port (a false value binds to all IPs)",
			"type": "bool",
			"defaultValue": "false"
		},
		{
			"name": "BROKER_BIND",
			"label": "A bool value that determines if to bind to a specific IP and Port (a false value binds to all IPs)",
			"type": "bool",
			"defaultValue": "false"
		},

		{
			"name": "LEDGER_CONN",
			"label": "TCP connection information for Master Node",
			"type": "string",
			"defaultValue": "127.0.0.1:32048"
		},

		{
			"name": "DB_TYPE",
			"label": "Physical database type (sqlite or psql)",
			"type": "string",
			"defaultValue": "sqlite"
		},
		{
			"name": "DB_USER",
			"label": "Physical database type (sqlite or psql)",
			"type": "string",
			"defaultValue": "admin"
		},
		{
			"name": "DB_IP",
			"label": "Database IP address",
			"type": "string",
			"defaultValue": "127.0.0.1"
		},
		{
			"name": "DB_PORT",
			"label": "Database port number",
			"type": "int",
			"defaultValue": "5432"
		},
		{
			"name": "SYSTEM_QUERY",
			"label": "Whether to start to start system_query logical database",
			"type": "string",
			"defaultValue": "false"
		},
		{
			"name": "MEMORY",
			"label": "Run system_query using in-memory SQLite. If set to false, will use pre-set database type",
			"type": "string",
			"defaultValue": "true"
		},

		{
			"name": "CLUSTER_NAME",
			"label": "Owner of the cluster",
			"type": "string",
			"defaultValue": "new-company-cluster"
		},
		{
			"name": "DEFAULT_DBMS",
			"label": "Owner of the cluster",
			"type": "string",
			"defaultValue": "new_company"
		},

		{
			"name": "ENABLE_MQTT",
			"label": "Whether to enable the default MQTT process",
			"type": "bool",
			"defaultValue": "false"
		},
		{
			"name": "DEPLOY_LOCAL_SCRIPT",
			"label": "Whether to automatically run a local (or personalized) script at the end of the process",
			"type": "bool",
			"defaultValue": "false"
		},
		{
			"name": "MONITOR_NODES",
			"label": "Whether to monitor the node",
			"type": "bool",
			"defaultValue": "false"
		}

	],
	"deployment": {
		"services": {
			"$SERVICE_NAME": {
				"image": "$DOCKER_IMAGE_BASE:$DOCKER_IMAGE_VERSION",
				"network": "host",
				"privileged": True,
				"binds": [
					"edgelake-operator-anylog:/app/EdgeLake/anylog",
					"edgelake-operator-blockchain:/app/EdgeLake/blockchain",
					"edgelake-operator-data:/app/EdgeLake/data",
					"edgelake-operator-local-scripts:/app/deployment-scripts"
				]
			}
		}
	}
}


# read content from deployment.policy.json if exists
if os.path.isfile(FILE_PATH):
    try:
        with open(FILE_PATH, 'r') as f:
            BASE_POLICY = json.load(f)
    except:
        pass
    else:
        IS_BASE = False

def main():
    """
    The following script converts EdgeLake configuration file from dotenv format to OpenHorizon / YAML format
    :positional arguments:
      version      EdgeLake version
      config_file  config file
    :options:
      -h, --help   show this help message and exit
    :global:
        BASE_POLICY:dict - Base policy for generating deployment.policy.json
        IS_BASE:bool - if service.deployment.json use that as your base, and do not update version
        FILE_PATH:str - full path for deployment.policy.json
    :params:
        full_path:str - full path for config file
    """
    global BASE_POLICY
    global IS_BASE
    parse = argparse.ArgumentParser()
    parse.add_argument('--required-services', type=str, default=None, help='Comma separated list of service names')
    args = parse.parse_args()

    if args.required_services is not None:
        for new_service in args.required_services.split(","):
            is_service = False
            if BASE_POLICY['requiredServices']:
                for service in BASE_POLICY['requiredServices']:
                    is_service = True if service['url'] == new_service else False
            if is_service is False:
                BASE_POLICY['requiredServices'].append({
                    "url": new_service,
                    "org": "myorg",
                    "versionRange": "[0.0.0,INFINITY)",
                    "arch": "$ARCH"
                })

    with open(FILE_PATH, 'w') as fname:
        json.dump(BASE_POLICY, fname, indent=2, ensure_ascii=False)


if __name__ == '__main__':
    main()
