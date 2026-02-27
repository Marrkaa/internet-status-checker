# internet-status-checker
The developed program is a Lua-based service that monitors internet connectivity and reports its status to other system components. It integrates with the system’s inter-process communication mechanism using ubus, where it registers an object named internet with a method called status. This method allows other services or clients to query whether the device currently has an active internet connection.

Internet availability is determined by executing a ping command to an external host (8.8.8.8). The program captures the command’s return code and interprets it to decide whether the connection is reachable. A return code of zero indicates successful connectivity, while any non-zero value indicates a failure.

The application uses uloop, to implement periodic checks. A timer triggers the connectivity test every five seconds. If a change in connectivity status is detected, the program emits corresponding ubus events.