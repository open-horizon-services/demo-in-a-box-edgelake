# demo-in-a-box

This is a set of materials designed to allow anyone to create a portable set of computers that will allow people to demonstrate most aspects of Open Horizon and OH-delivered applications in a single location.  It should contain a Bill of Materials, initial configuration, setup instructions, and examples of how to demonstrate most features.

## Pre-requisites

You must have the following utilities installed in order to provision:

* `make`
* `vagrant`

Additionally, this must be run on an `x86_64` architecture machine.

## System Configurations

The `x86_64` architecture host can be configured one of four ways:

- Unicycle -- As a single logical machine running the Exchange and an Agent
- Bicycle -- As three VMs, with
  - the primary running the Exchange and an Agent using 1/2 of the available resources, and
  - the remaining two running Agents each using 1/4 of the available resources.
- Car -- As five VMs (recommended for the 16GB RAM configuration only), with
  - the primary running the Exchange and an Agent using 1/2 of the available resources, and
  - the remaining four running Agents each using 1/8 of the available resources.
- Semi -- As seven VMs (recommended for the 16GB RAM configuration only), with
  - the primary running the Exchange and an Agent using 1/4 of the available resources, and
  - the remaining six running Agents each using 1/8 of the available resources.

## Installation

Run `make check` to verify dependencies are installed and defaults are correct.
Further, run `make status` to confirm that Vagrant is installed and running properly.

Running `make up` will provision the "unicycle" system configuration.  To use any other configuration, first `export SYSTEM_CONFIGURATION=<system configuration string>` where `<system configuration string>` is one of "unicycle", "bicycle", "car", or "semi" _without the quotes_.

Running `make down` will de-provision the system and cannot be undone.  Make sure you really want to do this.

## Usage

## Advanced details

