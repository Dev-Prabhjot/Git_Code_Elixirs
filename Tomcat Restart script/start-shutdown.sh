#!/bin/sh


#using Associative arrays

declare -A server_homes

server_homes[0,0]="path to tomcaat server-->..../apache-tomcat-7.0.53_TA"	       #server1 App1 DEV 
server_homes[0,1]="https://url:port/manager/status"     						   #"url1"   DEV Server
server_homes[1,0]="path to tomcaat server-->..../apache-tomcat-7.0.53_TA"		   #server2  TA  
server_homes[1,1]="https://url:port/manager/status"							   #"url2"   TA  Server
server_homes[2,0]="path to tomcaat server-->..../apache-tomcat-7.0.53_TA"	       #server3 App2 DEV
server_homes[2,1]="https://url:port/manager/status"     						   #"url3"   DEV Server
server_homes[3,0]="path to tomcaat server-->..../apache-tomcat-7.0.53_TA"	   #server4  TA SERVER
server_homes[3,1]="https://url:port/manager/status"     						   #"url4"   TA Server

maxServerCounts=$((${#server_homes[@]}/2))  # returns number of servers


clear


#checkPID

check_tomcat_status()
{
TOMCAT_PID=$(ps -eaf | grep -v grep | grep -i $server_home/conf | awk '{print $2}')
if [ -n "$TOMCAT_PID" ]
then 
echo " "
echo "SERVER Process ID found as: $TOMCAT_PID"

return 1
else
echo " "
echo "SERVER Process ID not found, might be server is not running."
return 0
fi
}

###NOTE###

# http_code   
# The numerical response code that was found in the
# last  retrieved  HTTP(S)  or  FTP(s) transfer. In
# 7.18.2 the alias response_code was added to  show
# the same info.
# We are currently using curl 7.19.7 #(x86_64-redhat-linux-gnu)


#check http_response

check_httpResponse()
{ 
server_status_code=$(curl --connect-timeout 120 -u manager:stmicro@123 -k -sL ${server_url} -w "%{response_code}\\n"  -o /dev/null) 		
echo "url: ${server_url} " >&2	

	
echo "$server_status_code"
}


shutdown_tomcat() {

	echo "Waiting for server to shutdown..."
	sh $server_home/bin/catalina.sh stop 70 -force
	echo "Server shutdown successful"
	
}

#clean cache

clean_tomcat() {
	echo "Cleaning cache, logs, exploded wars etc. - Start"
	
	echo "Logs deletion - START - [$server_home/logs/*]"
	cd $server_home
	echo " rm -rf $server_home/logs/*"
	rm -rf $server_home/logs/*
	
	echo "Logs deletion - ENDS"
	
	echo "Exploded war deletion - START - [$server_home/webapps]"
	cd $server_home/webapps
	echo "ls -d */ | grep -v host-manager | grep -v manager | grep -v ROOT | xargs rm -r"
	ls -d */ | grep -v host-manager | grep -v manager | grep -v ROOT | xargs rm -r
	echo "Exploded war deletion - ENDS"
	
	echo "Cleaning up WORK directory - START - [$server_home/work/Catalina/localhost]"
	echo "rm -rf $server_home/work/Catalina/localhost"
	rm -rf $server_home/work/Catalina/localhost
	echo "Cleaning up WORK directory - ENDS"
	
	echo "Cleaning cache, logs, exploded wars etc. - Ends"
}

#start server

start_tomcat() {

	echo "Starting server at:["$server_home"]"
	sh $server_home/bin/startup.sh
	
	
}


start_shutdown () {
	echo "Status checking begins for:["$server_home"] on $(date)"
	check_tomcat_status
	temp=$?
	result=$(check_httpResponse)
	echo "Server Http_Response Code = $result"
	
	
	if [ $temp -eq 1 -a $result -eq 200 ]
	then
	echo "Current Status: Tomcat is Running"
	echo " "
	echo "Skipping Restart Cycle as Tomcat Found Running on $(date)"
	echo " "
	echo "Aborting..."
	else
	
	# echo ":: INIT :: Shutdown,Clean and Start ::"
	
	echo "Current Status: Tomcat found in Unstable State"
	echo ""
	echo "Restart process begins for:["$server_home"]"
	echo ":: INIT :: Shutdown,Clean and Start ::"
	echo " "
	shutdown_tomcat
	echo " "
	clean_tomcat
	echo " "
	start_tomcat
	echo " "
	echo "Restart process ends for:["$server_home"]"
	echo " "
	fi
	echo " "
	echo "Script Execution Ends..."
	echo " "
}
echo "Total servers: $maxServerCounts"
#for server in ${server_homes[@]}
for ((i=0; i<maxServerCounts; i++ ))
do

	
	server_home=${server_homes[$i,0]}
	 echo "Server $(($i+1))  "
	server_url=${server_homes[$i,1]}
	 
	 
	if  test -s "$server_home"
	then
		echo
		start_shutdown 
	else
		echo
		echo "********************************************************"
		echo "No CATALINA_HOME found at:["$server_home"]"
		echo "********************************************************"
		echo
	fi
	
done

