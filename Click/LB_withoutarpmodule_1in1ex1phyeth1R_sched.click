//------------------------------------------------
// EXT TO IN
//------------------------------------------------

/*
MODIFY:
1. FromDevice to PollDevice if NAPI is enabled.
2. Extend interfaces if needed: External_in1, External_in2 etc.
3. Change the interface name and mac addresses accordingly in the positions with "CHANGE"
4. Change the internal filtering rules as necessary(i.e, 192.168.x.x for now), marked with "CHANGE"
*/



/*CHANGE*/ External_in1 :: FromDevice(eth0, PROMISC true);
/*CHANGE*/ Internal_out :: ToDevice(eth1);

classifierExtIn ::  Classifier(12/0806 20/0001, //0 ARP request
			12/0806 20/0002,	//1 Arp reply
			36/0017, 		//2 Telnet
			36/0016,		//3 SSH
			36/00A1,		//4 SNMP
			36/00A2,		//5 SNMPtrap
			23/01,			//6 ICMP
			23/02,			//7 IGMP			
			23/08,			//8 EGP
			23/09,			//9 IGRP
			23/3A,			//10 ICMPipv
			23/58,			//11 EIGRP
			23/59,			//12 OSPF
		   	-);			//13 normal traffic

balancer :: RoundRobinSwitch();
/*CHANGE - D*/ macMaster :: StoreData(0,\<001635af9442>);  //mac of the router 
/*CHANGE - D*/ mac1 :: StoreData(0,\<001635af9442>);   //mac of the router
macBroadcast :: StoreData(0,\<FFFFFFFFFFFF>);

ToInQueue :: Queue(1000);

External_in1 -> classifierExtIn;

classifierExtIn[0] -> ToInQueue;  		// ARP Request
classifierExtIn[1] -> macBroadcast; 		// ARP reply
classifierExtIn[2] -> macMaster; 		// Telnet
classifierExtIn[3] -> macMaster;		// SSH
classifierExtIn[4] -> macMaster;		// SNMP	
classifierExtIn[5] -> macMaster;		// SNMPTrap
classifierExtIn[6] -> macMaster;		// ICMP
classifierExtIn[7] -> macMaster;		// IGMP
classifierExtIn[8] -> macMaster;		// EGP
classifierExtIn[9] -> macMaster;		// IGRP
classifierExtIn[10] -> macMaster;		// ICMP ip v6
classifierExtIn[11] -> macMaster;		// EIGRP
classifierExtIn[12] -> macMaster;		// OSPF
classifierExtIn[13] -> balancer;		// normal traffic

balancer[0] -> mac1 -> ToInQueue;

macMaster -> ToInQueue;
macBroadcast -> ToInQueue;

ToInQueue -> Internal_out;

ScheduleInfo(Internal_out 8);

//------------------------------------------------
// IN TO EXT
//------------------------------------------------

/*CHANGE*/ Internal_in :: FromDevice(eth1, PROMISC true);
/*CHANGE*/ External_out :: ToDevice(eth0);



//Filtering: 
//DIST packets: destination IP is a multicast address 224.0.1.186:4434
//Private IP address Packets: 192.168.x.x
//ARP Request, ARP reply
classifierInExt :: Classifier(
		12/0800 30/E00001BA 36/1152, 		//0 pacchetti DIST
/*CHANGE*/	12/0800 30/C0A9????,			//1 packets whith private (192.168.x.x) Ip dest
		0/FFFFFFFFFFFF 12/0806 20/0002,		//2 ARP reply with Broadcast dest
		23/01 34/05,				//3 ICMP Redirect				
		12/0806 20/0001,			//4 ARP request
		12/0806 20/0002,			//5 ARP reply
		- );					//6 normal traffic

Dropper :: Discard();
/*CHANGE - D */ macSource :: StoreData(6,\<001635af9440>);    //mac of the LB, external link
/*CHANGE - D */ ARPSource :: StoreData(6,\<001635af9440>);    //mac of the LB, external link
/*CHANGE - D */ ARPSender :: StoreData(22,\<001635af9440>);   //mac of the LB, external link
queue2 :: Queue(1000);

Internal_in -> classifierInExt;

classifierInExt[0] -> Dropper;
classifierInExt[1] -> Dropper;
classifierInExt[2] -> Dropper;
classifierInExt[3] -> Dropper;
classifierInExt[4] -> ARPSource;
classifierInExt[5] -> ARPSource;
classifierInExt[6] -> macSource;

ARPSource -> ARPSender -> queue2;
macSource -> queue2;

queue2 -> External_out;

ScheduleInfo(External_out 32, queue2 8, macSource 1, ClassifierInExt 1, Internal_in 1);



