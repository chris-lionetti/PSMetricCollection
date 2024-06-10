## PS Collection Tool

This tool is designed to create a long running task of itself, which will run every 5 minutes (or 2), and on each run will gather statistics about hardware in the Datacenter.

It will assume that required Modules needed to gather the information are all available locally. 

Initially I am using the SNIA Swordfish/Redfish module so that I can gather Power and Temp settings from HPE Proliant servers.
I will add to this being able to retrieve tempa and power settings from the HPE MSA type device.

Once I can gather this information, I will expand the codebase to retreive power and temp values from the HPE Nimble Storage, Alletra6000,
3Par, Primera, and Alletra9000. 

Initially the data is stored in a local flat file, but in CSV format.
Next, I will build a connector to insert this data into a common SQL server, or a Azure Object Store. 

When I have the data able to be forwarded to a Database, I will work on building the infrasturcture and codebase that allows for the data to
be fed to a Grafana for visuallization.

Next I will add performance statistics for various network and storage, such as drives, or iSCSI/FC connections.

Next I will add the ability to monitor Volume Sizes, and Snapshot size growth. 

I don't know eventually where this will end up, but this data could at some point be fed into an AI to model a heat map of my infrastructure to 
help find underutilized assets and determine the effects of alternet cooling/power-limiting methods.


