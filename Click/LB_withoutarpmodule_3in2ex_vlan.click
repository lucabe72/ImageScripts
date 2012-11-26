//------------------------------------------------
// EXT TO IN
//------------------------------------------------
// This implementation provides a LB with more than one External port
//-----------------------------------------------
// 1st suggestion : Costumized MAC address
// The MAC address will be edited and the first 4 bits will be marked with the id of the incoming port. 
//------------------------------------------------

External_in1 :: PollDevice(eth1, PROMISC true);
External_in2 :: PollDevice(eth2, PROMISC true);
//How many inputs i need ...

Internal_out1 :: ToDevice(eth3);
Internal_out2 :: ToDevice(eth4);
Internal_out3 :: ToDevice(eth5);
//How many outputs i need ...

//Filtering: ARP request, Arp reply, Telnet, SSH, SNMP, SNMPtrap, 
// ICMP, IGMP, EGP, IGRP, ICMPipv6, EIGRP, OSPF
//ARP request pass unchanged - forwarded to the BackEnd Router
//ARP reply are modified by associating a MAC broadcast as destination Mac

Classifier_ExtIn ::  Classifier(12/0806 20/0001,	//0 ARP request
			12/0806 20/0002,			//1 Arp reply
			36/0017, 					//2 Telnet
			36/0016,					//3 SSH
			36/00A1,					//4 SNMP
			36/00A2,					//5 SNMPtrap
			23/01,					//6 ICMP
			23/02,					//7 IGMP			
			23/08,					//8 EGP
			23/09,					//9 IGRP
			23/3A,					//10 ICMPipv
			23/58,					//11 EIGRP
			23/59,					//12 OSPF
		   	-);						//13 normal traffic


Balancer_modifyMAC :: RoundRobinSwitch();
Balancer_inPorts :: RoundRobinSwitch();

// encapsulate the packet with vlan-tag
vlan1 :: VLANEncap(VLAN_TCI 1);
vlan2 :: VLANEncap(VLAN_TCI 2);
// for every in ports ...

SD_macMaster :: StoreData(0,\<A0A0A0A0A0A0>);
SD_mac1 :: StoreData(0,\<A00A000A0001>);
SD_mac2 :: StoreData(0,\<A00A000A0002>);
SD_mac3 :: StoreData(0,\<A00A000A0003>);
SD_macBroadcast :: StoreData(0,\<FFFFFFFFFFFF>);

Queue_fromExt:: Queue (10000);
Queue_mergeExtIn :: Queue(10000);
Queue_toIn1 :: Queue(10000);
Queue_toIn2 :: Queue(10000);
Queue_toIn3 :: Queue(10000);

// for every in ports ...
Unqueue_toClassifier_ExtIn :: Unqueue();
Unqueue_toInPorts :: Unqueue();

External_in1 -> vlan1 -> Queue_fromExt;
External_in2 -> vlan2 -> Queue_fromExt;
//Link every input to the queue

Queue_fromExt -> Unqueue_toClassifier_ExtIn -> Classifier_ExtIn;

Classifier_ExtIn[0] -> Queue_mergeExtIn;  // ARP Request
Classifier_ExtIn[1] -> SD_macBroadcast; 	// ARP reply
Classifier_ExtIn[2] -> SD_macMaster; 		// Telnet
Classifier_ExtIn[3] -> SD_macMaster;		// SSH
Classifier_ExtIn[4] -> SD_macMaster;		// SNMP	
Classifier_ExtIn[5] -> SD_macMaster;		// SNMPTrap
Classifier_ExtIn[6] -> SD_macMaster;		// ICMP
Classifier_ExtIn[7] -> SD_macMaster;		// IGMP
Classifier_ExtIn[8] -> SD_macMaster;		// EGP
Classifier_ExtIn[9] -> SD_macMaster;		// IGRP
Classifier_ExtIn[10] -> SD_macMaster;		// ICMP ip v6
Classifier_ExtIn[11] -> SD_macMaster;		// EIGRP
Classifier_ExtIn[12] -> SD_macMaster;		// OSPF
Classifier_ExtIn[13] -> Balancer_modifyMAC;	// normal traffic

Balancer_modifyMAC[0] -> SD_mac1 -> Queue_mergeExtIn;
Balancer_modifyMAC[1] -> SD_mac2 -> Queue_mergeExtIn;
Balancer_modifyMAC[2] -> SD_mac3 -> Queue_mergeExtIn;
SD_macMaster -> Queue_mergeExtIn;
SD_macBroadcast -> Queue_mergeExtIn;    //FIXME not correct, since the braodcast can not reach some region with multiple physical switches...

Queue_mergeExtIn -> Unqueue_toInPorts -> Balancer_inPorts;

Balancer_inPorts[0] -> Queue_toIn1;
Balancer_inPorts[1] -> Queue_toIn2;
Balancer_inPorts[2] -> Queue_toIn3;

Queue_toIn1 -> Internal_out1;
Queue_toIn2 -> Internal_out2;
Queue_toIn3 -> Internal_out3;



//------------------------------------------------
// IN TO EXT
//------------------------------------------------
// This implementation provides a LB whit more then one Internal port
//-----------------------------------------------
// 1st suggestion : Costumized MAC address
// The MAC address is ispected, the first 4 bits identify the chosen port. 
// The first 4 bits of the destination MAC are reset to 0
//------------------------------------------------

Internal_in1 :: FromDevice(eth3, PROMISC true);
Internal_in2 :: FromDevice(eth4, PROMISC true);
Internal_in3 :: FromDevice(eth5, PROMISC true);
//How many inputs i need ...

External_out1 :: ToDevice(eth1);
External_out2 :: ToDevice(eth2);
//How many outputs i need ...

//Filtering: 
Classifier_InExt1 :: Classifier(
	12/0800 30/E00001B9 36/1152, 			//0 pacchetti DIST - IP/DEST= 224.0.1.185/PORT DST = 4434 
	12/0800 30/C0A8????,				//1 packets whith private (192.168.x.x) Ip dest
	0/FFFFFFFFFFFF 12/0806 20/0002,			//2 ARP reply with Broadcast dest
	23/01 34/05,					//3 ICMP Redirect				
	12/0806 20/0001,				//4 ARP request
	12/0806 20/0002,				//5 ARP reply
	- );						//6 normal traffic 	

Classifier_InExt2 :: Classifier(
	12/0800 30/E00001B9 36/1152, 			//0 pacchetti DIST - IP/DEST= 224.0.1.185/PORT DST = 4434 
	12/0800 30/C0A8????,				//1 packets whith private (192.168.x.x) Ip dest
	0/FFFFFFFFFFFF 12/0806 20/0002,			//2 ARP reply with Broadcast dest
	23/01 34/05,					//3 ICMP Redirect				
	12/0806 20/0001,				//4 ARP request
	12/0806 20/0002,				//5 ARP reply
	- );						//6 normal traffic 

//Choose output port: 
Classifier_toExtPorts :: Classifier(
	14/1?,						 	//Port ID = 1
	14/2?,						 	//Port ID = 2
	-);							//others

Dropper_filter :: Discard();
Dropper_ports :: Discard();

//change to the mac of the external interfaces
SD_macSource1 :: StoreData(6,\<00BB00BB00BB>);
SD_ARPSource1 :: StoreData(6,\<00BB00BB00BB>);
SD_ARPSender1 :: StoreData(22,\<00BB00BB00BB>);

SD_macSource2 :: StoreData(6,\<00BB00BB00BB>);
SD_ARPSource2 :: StoreData(6,\<00BB00BB00BB>);
SD_ARPSender2 :: StoreData(22,\<00BB00BB00BB>);


RMvlan1 :: VLANDecap;
RMvlan2 :: VLANDecap;

Queue_fromIn :: Queue(10000);
Queue_toExternal1 :: Queue(10000);
Queue_toExternal2 :: Queue(10000);
Unqueue_toClassifierExtPorts :: Unqueue();

Internal_in1 -> Queue_fromIn;
Internal_in2 -> Queue_fromIn;
Internal_in3 -> Queue_fromIn;

Queue_fromIn -> Unqueue_toClassifierExtPorts -> Classifier_toExtPorts;

Classifier_toExtPorts[0] -> RMvlan1 -> Classifier_InExt1; 
Classifier_toExtPorts[1] -> RMvlan2 -> Classifier_InExt2;
Classifier_toExtPorts[2] -> Dropper_ports;

Classifier_InExt1[0] -> Dropper_filter;	//0 pacchetti DIST
Classifier_InExt1[1] -> Dropper_filter;	//1 packets whith private (192.168.x.x) Ip dest
Classifier_InExt1[2] -> Dropper_filter;	//2 ARP reply with Broadcast dest
Classifier_InExt1[3] -> Dropper_filter;	//3 ICMP Redirect	
Classifier_InExt1[4] -> SD_ARPSource1;	//4 ARP request
Classifier_InExt1[5] -> SD_ARPSource1;	//5 ARP reply
Classifier_InExt1[6] -> SD_macSource1;	//6 normal traffic

Classifier_InExt2[0] -> Dropper_filter;	//0 pacchetti DIST
Classifier_InExt2[1] -> Dropper_filter;	//1 packets whith private (192.168.x.x) Ip dest
Classifier_InExt2[2] -> Dropper_filter;	//2 ARP reply with Broadcast dest
Classifier_InExt2[3] -> Dropper_filter;	//3 ICMP Redirect	
Classifier_InExt2[4] -> SD_ARPSource2;	//4 ARP request
Classifier_InExt2[5] -> SD_ARPSource2;	//5 ARP reply
Classifier_InExt2[6] -> SD_macSource2;	//6 normal traffic

SD_ARPSource1 -> SD_ARPSender1 -> Queue_toExternal1;
SD_macSource1 -> Queue_toExternal1;

SD_ARPSource2 -> SD_ARPSender2 -> Queue_toExternal2;
SD_macSource2 -> Queue_toExternal2;

Queue_toExternal1 -> External_out1;
Queue_toExternal2 -> External_out2;
