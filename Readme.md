### This is to setup complete infra bulit on MS Azure like the below


###### OS : Ubuntu 18.04 TLS

##### ### Servers and Tech Stack
- ###### Web - Nginx And Php  - VMSS - RULE 
- ###### API - php-fpm 7.2 - VMSS 
- ###### Queue Server - Beanstalk port 8080
- ###### Worker server - VM port 22
- ###### Cache - VM - KeyDB - VM port 6379
- ###### Elasticsearch - VM port : 9300, 9200
- ###### HAPROXY - AS LOAD BALANCER - vm  
- ###### database cluster on percona mysql - cluster XDB port 3306 - Name : PXC

#### - Security Group

- Different  SUBNET- DB SUBNET
- PERCONA DB cLUSTER - 3 SERVER
- SSH aLLOW ON ALL OF THE SERVER
- PUBLIC KEY


#### One virtual network 
**four Subnets like the following:-**

1.  Public  - Will have the WEB/API
2.  The 1st Private  will have -  Queue , Worker , Elastic Search
3.  Database Subnet the 2nd Private -  database mysql
4.  Cache subnet the 3rd private - KeyDB 

##### Rules for Auto Scaling group.

- API and Web VMSS --> Scale out (Average) Percentage CPU > 70 / Increase count by 1
		 Scale in (Average) Percentage CPU <= 45/ Decrease count by 1

##### Auto Scaling Extenstion
- Extension API - healthRepairExtension (Microsoft.ManagedServices.ApplicationHealthLinux) 1.7
		DependencyAgentLinux  (Microsoft.Azure.Monitoring.DependencyAgent.DependencyAgentLinux) 9.10
		MMAExtension		(Microsoft.EnterpriseCloud.Monitoring.OmsAgentForLinux) 1.0

- Web 
		DependencyAgentLinux  (Microsoft.Azure.Monitoring.DependencyAgent.DependencyAgentLinux) 9.10
		MMAExtension		(Microsoft.EnterpriseCloud.Monitoring.OmsAgentForLinux) 1.0
