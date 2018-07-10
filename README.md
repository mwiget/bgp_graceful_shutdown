# BGP graceful shutdown scripts

## Overview
[RFC 6198](https://tools.ietf.org/html/rfc6198) describes requirements for a solution to minimize the impact of bringing down BGP sessions for maintenance purpose. In a nutshell, the operation of BGP graceful shutdown is as follows:

1. Operator issues a command to activate maintenance mode
2. All BGP sessions (in master and non-master instances) get augmented by a user-defined community
3. Operator issues a command to disable maintenance mode 
4. The user-defined community is removed from all BGP routes

This project implements the functionality via SLAX based operational scripts to enable and disable the BGP route augmentation via ephemeral DB. 

## Requirements

Junos version 16.1R3 or newer due to ephemeral DB.

## Installation

Upload the SLAX script [bgp_graceful_shutdown.slax](bgp_graceful_shutdown.slax) to the router (on all routing engines) into /var/db/scripts/op/:

```
$ scp bgp_graceful_shutdown.slax vmx1:/var/db/scripts/op/
```

Define the op script and enable ephemeral DB instance:

```
user@vmx1> conf
set system configuration-database ephemeral instance bgp_graceful_shutdown
set system scripts op file bgp_graceful_shutdown.slax
user@vmx1> commit and-quit
```

Check the script is installed correctly and get some basic usage help:

```
user@vmx1> op bgp_graceful_shutdown 
BGP graceful shutdown not active

user@vmx1> op bgp_graceful_shutdown ?  
Possible completions:
  <[Enter]>            Execute this command
  <name>               Argument name
  action               Action enable|disable|status
  community            community member (e.g. origin:65535:0)
  detail               Display detailed output
  invoke-debugger      Invoke script in debugger mode
  |                    Pipe through a command 
```

The community can be specified as argument together with 'action enable', but it is recommended to modify its default value in the script itself to ensure the same community is used every time it gets activated.

## Activate BGP graceful shutdown

To enable BGP graceful shutdown mode, launch the op script with the argument 'action enable' and optional a community member. This will dynamically augment the ephemeral database with export policies on all configured BGP peers within the master and non-master routing instances:

```
user@vmx1> op bgp_graceful_shutdown action enable     
BGP graceful shutdown enabled (origin:65535:0)
```

You can verify the augmented BGP routes on the local or remote router:

```
user@vmx1> show route advertising-protocol bgp 10.1.1.12 extensive 

inet.0: 17 destinations, 17 routes (17 active, 0 holddown, 0 hidden)
* 203.0.113.1/32 (1 entry, 1 announced)
 BGP group junos type External
     Nexthop: 10.1.1.100
     AS path: [65011] 65536 I
     Communities: origin:65535:0 large:65536:1:2

* 203.0.113.2/32 (1 entry, 1 announced)
 BGP group junos type External
     Nexthop: 10.1.1.100
     AS path: [65011] 65536 I
     Communities: origin:65535:0 large:65536:1:2
```

and on a peer router:

```
lab@vmx2> show route receive-protocol bgp 10.1.1.11 extensive                                                  

inet.0: 7 destinations, 7 routes (7 active, 0 holddown, 0 hidden)
* 203.0.113.1/32 (1 entry, 1 announced)
     Accepted
     Nexthop: 10.1.1.100
     AS path: 65011 65536 I
     Communities: origin:65535:0 large:65536:1:2

* 203.0.113.2/32 (1 entry, 1 announced)
     Accepted
     Nexthop: 10.1.1.100
     AS path: 65011 65536 I
     Communities: origin:65535:0 large:65536:1:2

inet6.0: 1 destinations, 1 routes (1 active, 0 holddown, 0 hidden)
```

You can also have a peek at the ephemeral DB instance where the state is kept until disabled (or the device rebooted):

```
lab@vmx1> > show ephemeral-configuration bgp_graceful_shutdown   
## Last changed: 2017-10-24 02:58:31 PDT
protocols {
    bgp {
        group junos {
            export set-bgp-graceful-shutdown;
        }
        group exabgp {
            export set-bgp-graceful-shutdown;
        }
        group ibgp-tr {
            export set-bgp-graceful-shutdown;
        }
    }
}
policy-options {
    policy-statement set-bgp-graceful-shutdown {
        then {
            community add bgp_graceful_shutdown;
        }
    }
    community bgp_graceful_shutdown members origin:65535:0;
}
routing-instances {
    VRF-1 {
        protocols {
            bgp {
                group CE-1 {
                    export set-bgp-graceful-shutdown;
                }                       
                group VRF-1 {           
                    export set-bgp-graceful-shutdown;
                }                       
            }                           
        }                               
    }           
    VRF-10 {                            
        protocols {                     
            bgp {                       
                group CE-10 {           
                    export set-bgp-graceful-shutdown;
                }                       
                group VRF-10 {          
                    export set-bgp-graceful-shutdown;
                }                       
            }                           
        }                               
    }                                        
. . .
```

## Disable BGP graceful shutdown

To de-activate/disable BGP graceful shutdown, reboot the device or run the following command:

```
lab@vmx1> > op bgp_graceful_shutdown action disable 
BGP graceful shutdown disabled
```

Verify the BGP routes:

```
lab@vmx2> show route receive-protocol bgp 10.1.1.11 extensive   

inet.0: 7 destinations, 7 routes (7 active, 0 holddown, 0 hidden)
inet.0: 7 destinations, 7 routes (7 active, 0 holddown, 0 hidden)
* 203.0.113.1/32 (1 entry, 1 announced)
     Accepted
     Nexthop: 10.1.1.100
     AS path: 65011 65536 I
     Communities: large:65536:1:2

* 203.0.113.2/32 (1 entry, 1 announced)
     Accepted
     Nexthop: 10.1.1.100
     AS path: 65011 65536 I
     Communities: large:65536:1:2

inet6.0: 1 destinations, 1 routes (1 active, 0 holddown, 0 hidden)
```

Check the ephemeral DB instance is indeed empty:

```
lab@vmx1> show ephemeral-configuration bgp_graceful_shutdown                 
## Last changed: 2017-10-24 03:08:23 PDT

lab@vmx1>
```

## How it works

To activate the BGP graceful shutdown mode, the script walks all BGP neighbors and programs export policy set-bgp-graceful-shutdown, configured with the community bgp_graceful_shutdown member given as argument or the default value from the script. Each neighbors routing-instance and BGP group is used to properly provision the export policy.

The script has been tested with 2000 VRF's and completes in seconds.

## Feedback

If you need to get in touch with the developer, open a git issue or provide direct feedack via email to Marcel Wiget <mwiget@juniper.net>

