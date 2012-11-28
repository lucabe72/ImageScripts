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

/*CHANGE*/ External_in1 :: PollDevice(eth1, PROMISC true);

/*CHANGE*/ Internal_out1 :: ToDevice(eth3);
/*CHANGE*/ Internal_out2 :: ToDevice(eth4);

//Filtering: ARP request, Arp reply, Telnet, SSH, SNMP, SNMPtrap, 
// ICMP, IGMP, EGP, IGRP, ICMPipv6, EIGRP, OSPF
//ARP request pass unchanged - forwarded to the BackEnd Router
//ARP reply are modified by associating a MAC broadcast as destination Mac

Classifier_ExtIn ::  Classifier(12/0806 20/0001,	//0 ARP request
			12/0806 20/0002,		//1 Arp reply
			36/0017, 			//2 Telnet
			36/0016,			//3 SSH
			36/00A1,			//4 SNMP
			36/00A2,			//5 SNMPtrap
			23/01,				//6 ICMP
			23/02,				//7 IGMP			
			23/08,				//8 EGP
			23/09,				//9 IGRP
			23/3A,				//10 ICMPipv
			23/58,				//11 EIGRP
			23/59,				//12 OSPF
		   	-);				//13 normal traffic


Balancer :: RoundRobinSwitch();
Duplicator :: Tee()

/*CHANGE*/ macMaster :: StoreData(0,\<A0A0A0A0A0A0>);
/*CHANGE*/ mac1 :: StoreData(0,\<A00A000A0001>);
/*CHANGE*/ mac2 :: StoreData(0,\<A00A000A0002>);
macBroadcast :: StoreData(0,\<FFFFFFFFFFFF>);

Queue_toIn1 :: Queue(1000);
Queue_toIn2 :: Queue(1000);
/*ADDING*/

External_in1 -> Classifier_ExtIn;

Classifier_ExtIn[0] -> Duplicator;  // ARP Request
Classifier_ExtIn[1] -> macBroadcast; 	// ARP reply
Classifier_ExtIn[2] -> macMaster; 		// Telnet
Classifier_ExtIn[3] -> macMaster;		// SSH
Classifier_ExtIn[4] -> macMaster;		// SNMP	
Classifier_ExtIn[5] -> macMaster;		// SNMPTrap
Classifier_ExtIn[6] -> macMaster;		// ICMP
Classifier_ExtIn[7] -> macMaster;		// IGMP
Classifier_ExtIn[8] -> macMaster;		// EGP
Classifier_ExtIn[9] -> macMaster;		// IGRP
Classifier_ExtIn[10] -> macMaster;		// ICMP ip v6
Classifier_ExtIn[11] -> macMaster;		// EIGRP
Classifier_ExtIn[12] -> macMaster;		// OSPF
Classifier_ExtIn[13] -> Balancer;	// normal traffic

Balancer[0] -> mac1 -> Queue_toIn1;
Balancer[1] -> mac2 -> Queue_toIn2;
/*ADDING*/

macMaster -> Queue_toIn1;
macBroadcast -> Duplicator;

Duplicator[0] -> Queue_toIn1;
Duplicator[1] -> Queue_toIn2;
/*ADDING*/

Queue_toIn1 -> Internal_out1;
Queue_toIn2 -> Internal_out2;
/*ADDING*/



//------------------------------------------------
// IN TO EXT
//------------------------------------------------

/*CHANGE*/Internal_in1 :: PollDevice(eth3, PROMISC true);
/*CHANGE*/Internal_in2 :: PollDevice(eth4, PROMISC true);

/*CHANGE*/External_out :: ToDevice(eth1);

//Filtering: 
Classifier_InExt :: Classifier(
		12/0800 30/E00001B9 36/1152, 			//0 pacchetti DIST - IP/DEST= 224.0.1.185/PORT DST = 4434 
/*CHANGE*/	12/0800 30/0A0A????,				//1 packets whith private (10.10.x.x) Ip dest
		0/FFFFFFFFFFFF 12/0806 20/0002,			//2 ARP reply with Broadcast dest
		23/01 34/05,					//3 ICMP Redirect				
		12/0806 20/0001,				//4 ARP request
		12/0806 20/0002,				//5 ARP reply
		- );						//6 normal traffic 	


Dropper_filter :: Discard();

/*CHANGE*/macSource :: StoreData(6,\<00BB00BB00BB>);
/*CHANGE*/ARPSource :: StoreData(6,\<00BB00BB00BB>);
/*CHANGE*/ARPSender :: StoreData(22,\<00BB00BB00BB>);

Queue_fromIn :: Queue(1000);
Queue_toExternal :: Queue(1000);
Unqueue_toClassifierExtPorts :: Unqueue();

Internal_in1 -> Queue_fromIn;
Internal_in2 -> Queue_fromIn;
/*ADDING*/

Queue_fromIn -> Unqueue_toClassifierExtPorts -> Classifier_InExt;


Classifier_InExt[0] -> Dropper_filter;	//0 pacchetti DIST
Classifier_InExt[1] -> Dropper_filter;	//1 packets whith private (192.168.x.x) Ip dest
Classifier_InExt[2] -> Dropper_filter;	//2 ARP reply with Broadcast dest
Classifier_InExt[3] -> Dropper_filter;	//3 ICMP Redirect	
Classifier_InExt[4] -> ARPSource;	//4 ARP request
Classifier_InExt[5] -> ARPSource;	//5 ARP reply
Classifier_InExt[6] -> macSource;	//6 normal traffic


ARPSource -> ARPSender -> Queue_toExternal;
macSource -> Queue_toExternal;

Queue_toExternal -> External_out;
