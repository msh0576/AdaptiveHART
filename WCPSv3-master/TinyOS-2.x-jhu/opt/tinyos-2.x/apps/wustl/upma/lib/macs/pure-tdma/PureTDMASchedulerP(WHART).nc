/*
 * "Copyright (c) 2007 Washington University in St. Louis.
 * All rights reserved.
 * @author Bo Li
 * @date $Date: 2014/10/17
 */

module PureTDMASchedulerP {
	provides {
		interface Init;
		interface SplitControl;
		interface AsyncSend as Send;
		interface AsyncReceive as Receive;
		interface CcaControl[am_id_t amId];
		interface FrameConfiguration as Frame;
	}
	uses{
		interface AsyncStdControl as GenericSlotter;
		interface RadioPowerControl;
		interface Slotter;
		interface SlotterControl;
		interface FrameConfiguration;
		interface AsyncSend as SubSend;
		interface AsyncSend as BeaconSend;
		interface AsyncReceive as SubReceive;
		interface AMPacket;
		interface Resend;
		interface PacketAcknowledgements;
		interface Boot;
		interface Leds;
		//interface HplMsp430GeneralIO as Pin;

		interface CC2420Config;//Added by Bo
		interface TossimPacketModelCCA;
		interface TossimComPrintfWrite;
		interface SimMote;

		//Added by Sihoon
		interface ScheduleConfig;
		interface TossimPacketModel;
		interface Queue<TestNetworkMsg *> as forwardQ;
		interface GainRadioModel2 as CCAevent;

	}
}
implementation {
	enum {
		SIMPLE_TDMA_SYNC = 123,
		FRAME_LENGTH = 3,
		RADIO_DEF_POWER = 0,
		RADIO_MAX_POWER = 31,
		MAC_Q = 2,
	};
	bool init;
	uint32_t slotSize;
	uint32_t bi, sd, cap;
	uint8_t coordinatorId;

	message_t *toSend; //this one will become critical later on, and cause segmentation error
	uint8_t toSendLen;

	//Below added by Bo
	message_t packet;
	message_t test_signal_pkt;

	//For Queue
	message_t forwardPktBuffer[MAC_Q];
	uint8_t queueSize;

	//Added by sihoon
	uint32_t slot_;
	uint16_t rcv_count[NETWORK_FLOW];
	uint16_t trans_count[NETWORK_FLOW][MAX_LINK_RETX+1];
	uint16_t first_Retrans_count;
	uint16_t second_Retrans_count;
	uint32_t first_NoAck_count;
	uint32_t second_NoAck_count;
	bool Receive_flag;
	uint16_t Loss_count;
	uint8_t TxOffset;
	uint8_t MaxlinkRetx;


	uint8_t get_last_hop_status(uint8_t flow_id_t, uint8_t access_type_t, uint8_t hop_count_t);
	void set_current_hop_status(uint32_t slot_t, uint8_t sender, uint8_t receiver);
	void set_send_status(uint8_t ack_t);
	void set_send (uint32_t slot_t);


  	//0 Slot
  	//1 Sender
  	//2 Receiver
  	//3 Channel
  	//4 Access Type:    0: dedicated,  1: shared, 2: steal, 3: ack
  	//5 Flow Type:      0: emergency, 1: regular
  	//6 Flow ID:        1, 2
  	//7 Flow root: root of the flow, i.e., sensor that launch the communcation
  	//8 Send status in sendDone: 0: no-ack, 1: acked
  	//9 Last Hop Status:
  	//10 Hop count in the flow
		//11 Retransmissions

	uint8_t schedule[51][12]={//Source Routing, 16 sensor topology, 2 prime trans, retrans twice, baseline.
		//Flow sender schedule

		//5hop -3ReTx - T:[30, 30] (1.5Hz) -Super_len = 30
		/*
		{1, 88, 0, 22, 0, 1, 1, 1, 0, 0, 1, 0},	// Flooding slot
		{2, 88, 0, 22, 0, 1, 1, 1, 0, 0, 1, 0},	// Flooding slot

		{3, 1, 3, 22, 0, 1, 1, 1, 0, 0, 1, 0},
		{4, 1, 3, 22, 0, 1, 1, 1, 0, 0, 1, 1},
		{5, 1, 3, 22, 0, 1, 1, 1, 0, 0, 1, 2},

		{6, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 0},
		{7, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 1},
		{8, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 2},

		{9, 4, 5, 22, 0, 1, 1, 1, 0, 0, 3, 0},
		{10, 4, 5, 22, 0, 1, 1, 1, 0, 0, 3, 1},
		{11, 4, 5, 22, 0, 1, 1, 1, 0, 0, 3, 2},

		{12, 5, 6, 22, 0, 1, 1, 1, 0, 0, 4, 0},
		{13, 5, 6, 22, 0, 1, 1, 1, 0, 0, 4, 1},
		{14, 5, 6, 22, 0, 1, 1, 1, 0, 0, 4, 2},

		{15, 6, 51, 22, 0, 1, 1, 1, 0, 0, 5, 0},
		{16, 6, 51, 22, 0, 1, 1, 1, 0, 0, 5, 1},
		{17, 6, 51, 22, 0, 1, 1, 1, 0, 0, 5, 2},

		{18, 2, 3, 22, 0, 1, 1, 1, 0, 0, 1, 0},
		{19, 2, 3, 22, 0, 1, 1, 1, 0, 0, 1, 1},
		{20, 2, 3, 22, 0, 1, 1, 1, 0, 0, 1, 2},

		{21, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 0},
		{22, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 1},
		{23, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 2},

		{24, 4, 5, 22, 0, 1, 1, 1, 0, 0, 3, 0},
		{25, 4, 5, 22, 0, 1, 1, 1, 0, 0, 3, 1},
		{26, 4, 5, 22, 0, 1, 1, 1, 0, 0, 3, 2},

		{27, 5, 6, 22, 0, 1, 1, 1, 0, 0, 4, 0},
		{28, 5, 6, 22, 0, 1, 1, 1, 0, 0, 4, 1},
		{29, 5, 6, 22, 0, 1, 1, 1, 0, 0, 4, 2},

		{30, 6, 52, 22, 0, 1, 1, 1, 0, 0, 5, 0},
		{31, 6, 52, 22, 0, 1, 1, 1, 0, 0, 5, 1},
		{32, 6, 52, 22, 0, 1, 1, 1, 0, 0, 5, 2}
		*/
		// 5hop 2retx
		{1, 88, 0, 22, 0, 1, 1, 1, 0, 0, 1, 0},	// Flooding slot
		{2, 88, 0, 22, 0, 1, 1, 1, 0, 0, 1, 0},	// Flooding slot

		{3, 1, 3, 22, 0, 1, 1, 1, 0, 0, 1, 0},
		{4, 1, 3, 22, 0, 1, 1, 1, 0, 0, 1, 1},

		{5, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 0},
		{6, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 1},

		{7, 4, 5, 22, 0, 1, 1, 1, 0, 0, 3, 0},
		{8, 4, 5, 22, 0, 1, 1, 1, 0, 0, 3, 1},

		{9, 5, 6, 22, 0, 1, 1, 1, 0, 0, 4, 0},
		{10, 5, 6, 22, 0, 1, 1, 1, 0, 0, 4, 1},

		{11, 6, 51, 22, 0, 1, 1, 1, 0, 0, 5, 0},
		{12, 6, 51, 22, 0, 1, 1, 1, 0, 0, 5, 1},

		{13, 2, 3, 22, 0, 1, 2, 2, 0, 0, 1, 0},
		{14, 2, 3, 22, 0, 1, 2, 2, 0, 0, 1, 1},

		{15, 3, 4, 22, 0, 1, 2, 2, 0, 0, 2, 0},
		{16, 3, 4, 22, 0, 1, 2, 2, 0, 0, 2, 1},

		{17, 4, 5, 22, 0, 1, 2, 2, 0, 0, 3, 0},
		{18, 4, 5, 22, 0, 1, 2, 2, 0, 0, 3, 1},

		{19, 5, 6, 22, 0, 1, 2, 2, 0, 0, 4, 0},
		{20, 5, 6, 22, 0, 1, 2, 2, 0, 0, 4, 1},

		{21, 6, 52, 22, 0, 1, 2, 2, 0, 0, 5, 0},
		{22, 6, 52, 22, 0, 1, 2, 2, 0, 0, 5, 1}

		};
	uint8_t sub_schedule1[51][12]={//Source Routing, 16 sensor topology, 2 prime trans, retrans twice, baseline.
		/*
		//5hop -3ReTx - T:[30, 30] (1.5Hz) -Super_len = 30
		{1, 88, 0, 22, 0, 1, 1, 1, 0, 0, 1, 0},	// Flooding slot
		{2, 88, 0, 22, 0, 1, 1, 1, 0, 0, 1, 0},	// Flooding slot

		{3, 1, 3, 22, 0, 1, 1, 1, 0, 0, 1, 0},
		{4, 1, 3, 22, 0, 1, 1, 1, 0, 0, 1, 1},
		{5, 1, 3, 22, 0, 1, 1, 1, 0, 0, 1, 2},

		{6, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 0},
		{7, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 1},
		{8, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 2},

		{9, 4, 5, 22, 0, 1, 1, 1, 0, 0, 3, 0},
		{10, 4, 5, 22, 0, 1, 1, 1, 0, 0, 3, 1},
		{11, 4, 5, 22, 0, 1, 1, 1, 0, 0, 3, 2},

		{12, 5, 6, 22, 0, 1, 1, 1, 0, 0, 4, 0},
		{13, 5, 6, 22, 0, 1, 1, 1, 0, 0, 4, 1},
		{14, 5, 6, 22, 0, 1, 1, 1, 0, 0, 4, 2},

		{15, 6, 51, 22, 0, 1, 1, 1, 0, 0, 5, 0},
		{16, 6, 51, 22, 0, 1, 1, 1, 0, 0, 5, 1},
		{17, 6, 51, 22, 0, 1, 1, 1, 0, 0, 5, 2}
		*/
		// 5hop 2retx
		{1, 88, 0, 22, 0, 1, 1, 1, 0, 0, 1, 0},	// Flooding slot
		{2, 88, 0, 22, 0, 1, 1, 1, 0, 0, 1, 0},	// Flooding slot

		{3, 1, 3, 22, 0, 1, 1, 1, 0, 0, 1, 0},
		{4, 1, 3, 22, 0, 1, 1, 1, 0, 0, 1, 1},

		{5, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 0},
		{6, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 1},

		{7, 4, 5, 22, 0, 1, 1, 1, 0, 0, 3, 0},
		{8, 4, 5, 22, 0, 1, 1, 1, 0, 0, 3, 1},

		{9, 5, 6, 22, 0, 1, 1, 1, 0, 0, 4, 0},
		{10, 5, 6, 22, 0, 1, 1, 1, 0, 0, 4, 1},

		{11, 6, 51, 22, 0, 1, 1, 1, 0, 0, 5, 0},
		{12, 6, 51, 22, 0, 1, 1, 1, 0, 0, 5, 1},

		{13, 2, 3, 22, 0, 1, 2, 2, 0, 0, 1, 0},
		{14, 2, 3, 22, 0, 1, 2, 2, 0, 0, 1, 1},

		{15, 3, 4, 22, 0, 1, 2, 2, 0, 0, 2, 0},
		{16, 3, 4, 22, 0, 1, 2, 2, 0, 0, 2, 1},

		{17, 4, 5, 22, 0, 1, 2, 2, 0, 0, 3, 0},
		{18, 4, 5, 22, 0, 1, 2, 2, 0, 0, 3, 1},

		{19, 5, 6, 22, 0, 1, 2, 2, 0, 0, 4, 0},
		{20, 5, 6, 22, 0, 1, 2, 2, 0, 0, 4, 1},

		{21, 6, 52, 22, 0, 1, 2, 2, 0, 0, 5, 0},
		{22, 6, 52, 22, 0, 1, 2, 2, 0, 0, 5, 1}


		/*
		//4hop -2ReTx - T:[15, 15] (1.5Hz) -Super_len = 15

		{1, 88, 0, 22, 0, 1, 1, 1, 0, 0, 1, 0},	// Flooding slot
		{2, 88, 0, 22, 0, 1, 1, 1, 0, 0, 1, 0},	// Flooding slot

		{3, 1, 3, 22, 0, 1, 1, 1, 0, 0, 1, 0},
		{4, 1, 3, 22, 0, 1, 1, 1, 0, 0, 1, 1},

		{5, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 0},
		{6, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 1},

		{7, 4, 5, 22, 0, 1, 1, 1, 0, 0, 3, 0},
		{8, 4, 5, 22, 0, 1, 1, 1, 0, 0, 3, 1},

		{9, 5, 51, 22, 0, 1, 1, 1, 0, 0, 4, 0},
		{10, 5, 51, 22, 0, 1, 1, 1, 0, 0, 4, 1}
		*/
		/*
		{0, 88, 0, 22, 0, 1, 1, 1, 0, 0, 1, 0},	// Flooding slot
		{1, 88, 0, 22, 0, 1, 1, 1, 0, 0, 1, 0},	// Flooding slot

		{2, 1, 3, 22, 0, 1, 1, 1, 0, 0, 1, 0},
		{3, 1, 3, 22, 0, 1, 1, 1, 0, 0, 1, 1},

		{4, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 0},
		{5, 3, 4, 22, 0, 1, 1, 1, 0, 0, 2, 1},

		{6, 4, 51, 22, 0, 1, 1, 1, 0, 0, 3, 0},
		{7, 4, 51, 22, 0, 1, 1, 1, 0, 0, 3, 1}
		*/
		};
	uint8_t schedule_len=51;
	uint32_t superframe_length = 25; //5Hz at most
	uint32_t superframe_length_dist = 25;

			//0 backup node
			//1 criticality:		0:Lo-criti flow,	1:Hi-criti flow
			//2 Coexistance:		1: Lo-criti flow has Hi-criti packets
	uint8_t backup_schedule[3]={0, 0, 0, 0};
	uint8_t BACKUPNODE = 0;
	uint8_t CRITICALITY = 1;
	uint8_t COEXISTANCE = 2;

	/* Routing Path */
			//0 Primary path
			//1 Backup path
	uint8_t Path[NETWORK_FLOW][2];
	uint8_t PRIMARYPATH = 0;
	uint8_t BACKUPPATH = 1;

	/* Execution Buffer for receive the ACK state */
	uint8_t ExecutionBuf[NETWORK_FLOW];		//index: transmitting flowid, value: executed schedule index
	uint8_t Transmitting_flowid;

	/* Packet loss buffer for each transmitting flow to count retransmission */
	uint8_t PktLossBuff[NETWORK_FLOW];	//index: transmitting flowid, value: # of pkt loss

	/* Transmit schedule index buffer for each flow */
	uint8_t Sched_idx[NETWORK_FLOW];		//index: flowid, value: schedule index that each node should transmit pkts on the origianl schedule
	uint32_t rcv_slot[NETWORK_FLOW];		//receive slot for each flow
	bool receive_lock[NETWORK_FLOW];		//prevent multiple reception from the same flow in a superframe

	/* Flow root indicator */
	bool isFlowroot;
	bool isFlowdest;
	uint16_t kth_job = 0;
	bool Newframe = TRUE;
	uint32_t Num_superframe = 0;


	/* End-to-end delay indicator */
	uint32_t e2e_delay_buffer[NETWORK_FLOW][1000];	// index: receive slot, value: count
	/* Chcek interference & disturbance */
	uint32_t temp_interf;
	uint32_t temp_dist;

	bool sync;
	bool requestStop;
	uint32_t sync_count = 0;

	event void Boot.booted(){}

		/******** Schedule-Free MAC *******  */

	command error_t Init.init() {
		uint8_t i, j;
		uint32_t *Task_T_buffer;
		uint32_t *Task_Tx_buffer;
		//uint32_t (*VCS_buffer)[VCS_COL_SIZE];

		slotSize = 10 * 32;     //10ms
		bi = 40000; //# of slots in the supersuperframe with only one slot 0 doing sync
		sd = 40000; //last active slot
		cap = 0; // what is this used for? is this yet another superframe length?

		first_Retrans_count = 0;
		second_Retrans_count = 0;
		first_NoAck_count = 0;
		second_NoAck_count = 0;
		Receive_flag = TRUE;
		Loss_count = 0;
		MaxlinkRetx = 2;
		isFlowroot = FALSE;
		isFlowdest = FALSE;

		// Task Period
		Task_T_buffer = sim_get_TaskPeriods();
		Task_Tx_buffer = sim_get_TaskTx();
		temp_interf = Task_Tx_buffer[3];
		temp_dist = Task_T_buffer[3];


		//Store primary and backup path for each flow id
		for(i=0; i<NETWORK_FLOW; i++){
			Path[i][PRIMARYPATH] = call ScheduleConfig.primaryNode(i, TOS_NODE_ID);
			//Path[i][BACKUPPATH] = call ScheduleConfig.backupNode(i, TOS_NODE_ID);
			//dbg("transmission","Primarypath of flow%d:%d\n", i, Path[i][PRIMARYPATH]);
			//dbg("transmission","Backuppath of flow%d:%d\n", i, Path[i][BACKUPPATH]);

			//Initialize
			ExecutionBuf[i] = 0;
			PktLossBuff[i] = 0;
			rcv_slot[i] = 0;
			rcv_count[i] = 0;
			receive_lock[i] = FALSE;
			for(j=0; j<MAX_LINK_RETX+1; j++){
				trans_count[i][j] = 0;
			}

		}

		// Set whether each node is flow root or not
		if(call ScheduleConfig.flowsource(TOS_NODE_ID) == TRUE){
			isFlowroot = TRUE;
		}else if(call ScheduleConfig.flowdestination(TOS_NODE_ID) == TRUE){
			isFlowdest = TRUE;
		}


		// Find schedule informations and fow criticality of each node
		for(i=0; i<schedule_len; i++) {
			if(schedule[i][1] == TOS_NODE_ID) {
				//backup_schedule[CRITICALITY] = call ScheduleConfig.criticality(schedule[i][6]);		//Assume: primary flows are not inter-cross at some nodes

				Sched_idx[schedule[i][6]] = i;

			}
		}
		//dbg("transmission","backup_schedule[CRITICALITY]:%d\n", backup_schedule[CRITICALITY]);

		coordinatorId = 100;
		init = FALSE;
		toSend = NULL;
		toSendLen = 0;
		sync = FALSE;
		requestStop = FALSE;
		call SimMote.setTcpMsg(0, 0, 0, 0, 0); //reset TcpMsg

		/* set TxOffset based on VCS algorithm */
		// Python to MAC
		/*
		VCS_buffer = sim_get_VirtualSchedule();
		if(TOS_NODE_ID <= NETWORK_NODE){
			if(VCS_buffer[TOS_NODE_ID][0] != NULL){
				TxOffset = VCS_buffer[TOS_NODE_ID][0];
			}
		}
		dbg("VCStest","My TxOffset:%d\n", TxOffset);
		*/

		// For debug e2e delay, set e2e_delay_beffer
		for(i=0; i<NETWORK_FLOW; i++){
			for(j=0; j<superframe_length; j++){
				e2e_delay_buffer[i][j] = 0;
			}
		}

		return SUCCESS;
	}

 	command error_t SplitControl.start() {
 		error_t err;
 		if (init == FALSE) {
 			call FrameConfiguration.setSlotLength(slotSize);
 			call FrameConfiguration.setFrameLength(bi + 1);
 			//call FrameConfiguration.setFrameLength(1000);
 		}
 		err = call RadioPowerControl.start();
 		return err;
 	}

 	command error_t SplitControl.stop() {
 		printf("This is sensor: %u and the SplitControl.stop has been reached\n", TOS_NODE_ID);
 		requestStop = TRUE;
 		call GenericSlotter.stop();
 		call RadioPowerControl.stop();
 		return SUCCESS;
 	}

 	event void RadioPowerControl.startDone(error_t error) {
 	 	int i;
 		if (coordinatorId == TOS_NODE_ID) {
 			if (init == FALSE) {
 				signal SplitControl.startDone(error); //start sensor 0
 				call GenericSlotter.start(); //start slot counter
 				call SlotterControl.synchronize(0); //synchronize the rest sensors in the network
 				init = TRUE;
 			}
 		} else {
 			if (init == FALSE) {
 				signal SplitControl.startDone(error); //start all non-zero sensors
 				init = TRUE; //initialization done
 			}
 		}
	}

 	event void RadioPowerControl.stopDone(error_t error)  {
		if (requestStop)  {
			printf("This is sensor: %u and the RadioPowerControl.stopDone has been reached\n", TOS_NODE_ID);
			requestStop = FALSE;
			signal SplitControl.stopDone(error);
		}
	}

 	/****************************
 	 *   Implements the schedule
 	 */
 	async event void Slotter.slot(uint32_t slot) {
 		message_t *tmpToSend;
 		uint8_t tmpToSendLen;
 		uint8_t i,j;
		uint32_t *Interf_Check;
		uint32_t *Dist_Check;

		atomic slot_ = slot;

 		if (slot == 0 ) {
 			if (coordinatorId == TOS_NODE_ID) {
 				call BeaconSend.send(NULL, 0);
 			};
 			return;
 		}

		/* Receiver Setting */
		if ((slot % superframe_length) == 0 ) {

			/* Check Disturbances and Interferences */
			Dist_Check = sim_get_TaskPeriods();
			Interf_Check = sim_get_TaskTx();
			// Num_ReTx change
			if(Interf_Check[3] != temp_interf){
				temp_interf = Interf_Check[3];
				dbg_clear("Util_Log_data","-----Interference-----\n");
			}
			// Task Period change
			if(Dist_Check[3] != temp_dist){
				temp_dist = Dist_Check[3];
				dbg_clear("Util_Log_data","-----Disturbance-----\n");
				for(i=0; i<schedule_len; i++){
					for(j=0; j<12; j++){
						schedule[i][j] = sub_schedule1[i][j];
					}
				}
				superframe_length = superframe_length_dist;
			}


			/* Check packet loss % Utilization */
			Num_superframe = Num_superframe + 1;
			//Count Pkt loss in a superframe
			if(Receive_flag == TRUE){
				Receive_flag = FALSE;
			}else {
				Loss_count = Loss_count + 1;
			}

			if(TOS_NODE_ID == 51 || TOS_NODE_ID == 52){
				// Node id, Loss_count, Total Tx count

				dbg_clear("Util_Log_data","%d %d %d\n", TOS_NODE_ID, Loss_count, Num_superframe);

			}


 			for (i=0; i<schedule_len; i++){
  				schedule[i][8]=0; //re-enable transmission by set the flag bit to 0, implying this transmission is unfinished and to be conducted.
  				schedule[i][9]=0; //reset "last hop status" to 0 to avoid future confusions, especially in .
	  	}

			//Reset Transmitting variable & Pkt loss buffer & received slot
			for(i=0; i<NETWORK_FLOW; i++){
				ExecutionBuf[i] = 0;
				PktLossBuff[i] = 0;
				rcv_slot[i] = 0;
				receive_lock[i] = FALSE;
			}
			Transmitting_flowid = 0;
			Newframe = TRUE;




			/// Queue Initilize
			if(!call forwardQ.empty()){
				queueSize = call forwardQ.size();
				for(i=0; i<queueSize; i++){
					call forwardQ.dequeue();
				}
			}

			return;
 		}

 		if (slot >= sd+1) {
 			return;
 		}
 		if (slot < cap) {
 		} else {
 			set_send (slot % superframe_length); //heart beat control
 		}
 	}

	//for Test signals
	event void TossimPacketModel.sendDone(message_t* msg, error_t error){
		//dbg("test","sendDone\n");
	}

	//Receive signal
	event void TossimPacketModel.receive(message_t* msg){
		//dbg("test","---Test Signals	:	TossimPacketModel.receive\n");
	}
	event bool TossimPacketModel.shouldAck(message_t* msg){}

	/* For any packet reception */
	//added by sihoon
	// CCA event is triggered when a node receive any packet
  event void CCAevent.anypktreceive() {

  }

 	async command error_t Send.send(message_t * msg, uint8_t len) {
 		atomic {
 			if (toSend == NULL) {
 				toSend = msg;
 				toSendLen = len;
 				return SUCCESS;
 			}
 		}
 		return FAIL;
 	}

	async event void SubSend.sendDone(message_t * msg, error_t error) {
		uint32_t slot_at_send_done;
		uint8_t ack_at_send_done;
		slot_at_send_done = call SlotterControl.getSlot() % superframe_length;
		ack_at_send_done = call PacketAcknowledgements.wasAcked(msg)?1:0;
		//link failure statistics
		if(ack_at_send_done==0){
			PktLossBuff[Transmitting_flowid] = PktLossBuff[Transmitting_flowid] + 1;

			if(PktLossBuff[Transmitting_flowid] == 1) {
				dbg("receive_ack","No Ack --- slot:%d, ack:%d, dest:%d, first_NoAck_count:%d\n", slot_at_send_done, ack_at_send_done, call AMPacket.destination(msg), ++first_NoAck_count );
				//dbg("receive_ack","PktLossBuff[%d]:%d\n",Transmitting_flowid,PktLossBuff[Transmitting_flowid]);
			}else if (PktLossBuff[Transmitting_flowid] == 2) {
				dbg("receive_ack","No Ack --- slot:%d, ack:%d, dest:%d, second_NoAck_count:%d\n", slot_at_send_done, ack_at_send_done, call AMPacket.destination(msg), ++second_NoAck_count );
				//dbg("receive_ack","PktLossBuff[%d]:%d\n",Transmitting_flowid,PktLossBuff[Transmitting_flowid]);
			}

		}else if(ack_at_send_done==1){

			call forwardQ.dequeue();
		}
		//set ACK variable
		set_send_status(ack_at_send_done);
		//Initialize Transmitting variable
		ExecutionBuf[Transmitting_flowid] = 0;
		Transmitting_flowid = 0;

		if (msg == &packet) {
			if (call AMPacket.type(msg) != SIMPLE_TDMA_SYNC) {
				signal Send.sendDone(msg, error);
			} else {
			}
		}
	}

 	async command error_t Send.cancel(message_t *msg) {
  		atomic {
 			if (toSend == NULL) return SUCCESS;
 			atomic toSend = NULL;
 		}
 		return call SubSend.cancel(msg);
 	}

	/**
	 * Receive
	 */
	async event void SubReceive.receive(message_t *msg, void *payload, uint8_t len) {
		am_addr_t src = call AMPacket.source(msg);
		uint8_t i;
		uint8_t flow_id_rcv;
		uint8_t current_slot;
		TestNetworkMsg* tmp_payload;
		TestNetworkMsg* dataBuffer;
		char * printfResults;


		current_slot = call SlotterControl.getSlot() % superframe_length;
		tmp_payload = (TestNetworkMsg*)payload;
		set_current_hop_status(call SlotterControl.getSlot() % superframe_length, src, TOS_NODE_ID);
		flow_id_rcv = tmp_payload->flowid; //changed by sihoon

		//check flowid, destination,
		if(TOS_NODE_ID == 3 || TOS_NODE_ID == 4 || TOS_NODE_ID == 5 || TOS_NODE_ID == 6 ||TOS_NODE_ID == 7 || TOS_NODE_ID == 51 || TOS_NODE_ID == 52){
			if(flow_id_rcv != 0) {
				for(i=0; i<schedule_len; i++) {
					if(schedule[i][2] == TOS_NODE_ID && schedule[i][6] == flow_id_rcv && receive_lock[flow_id_rcv] == FALSE){
						rcv_slot[flow_id_rcv] = current_slot;
						Receive_flag = TRUE;
						rcv_count[flow_id_rcv] = rcv_count[flow_id_rcv] + 1;
						receive_lock[flow_id_rcv] = TRUE;

						dbg("receive","flow_id:%u, SLOT: %u, src:%u, myID:%u, channel:%u   rcv_count[%d]:%d\n\n", flow_id_rcv, rcv_slot[flow_id_rcv], src, TOS_NODE_ID, call CC2420Config.getChannel(), flow_id_rcv, rcv_count[flow_id_rcv]);


						if(isFlowdest == TRUE && Newframe==TRUE){
							Newframe = FALSE;
							call SimMote.setTcpMsg(flow_id_rcv, call SlotterControl.getSlot() % superframe_length, src, TOS_NODE_ID, call CC2420Config.getChannel());

							// check e2e delay
							e2e_delay_buffer[flow_id_rcv][current_slot] = e2e_delay_buffer[flow_id_rcv][current_slot] + 1;
							//Node id,	flow id,	rcv_count, rcv_count_at_slot0,1,2,...
							//dbg_clear("E2E_delay_Log_data","%d %d %d ", TOS_NODE_ID, flow_id_rcv, rcv_count[flow_id_rcv]);
							dbg_clear("E2E_delay_Log_data","%d %d %d ", TOS_NODE_ID, flow_id_rcv, rcv_count[flow_id_rcv]);
							for(i=0; i<superframe_length; i++){
								dbg_clear("E2E_delay_Log_data","%d ", e2e_delay_buffer[flow_id_rcv][i]);
							}
							dbg_clear("E2E_delay_Log_data","\n");

						}
					}
					// Queue //

					queueSize = call forwardQ.size();
					dataBuffer = (TestNetworkMsg*)call SubSend.getPayload(&forwardPktBuffer[queueSize], sizeof(TestNetworkMsg));
					dataBuffer->flowid = tmp_payload->flowid;
					if(dataBuffer != NULL){
						call forwardQ.enqueue(dataBuffer);
					}
				}
			}
		}
		//printf("RECEIVE: %u->%u, SLOT:%u (time: %s), channel: %u\n", src,TOS_NODE_ID, call SlotterControl.getSlot(), sim_time_string(), call CC2420Config.getChannel());
		signal Receive.receive(msg, payload, len);

	}

	/**
	 * Frame configuration
	 * These interfaces are provided for external use, which is misleading as these interfaces are already implemented in GenericClotterC and P
	 */
  	command void Frame.setSlotLength(uint32_t slotTimeBms) {
		atomic slotSize = slotTimeBms;
		call FrameConfiguration.setSlotLength(slotSize);
 	}
 	command void Frame.setFrameLength(uint32_t numSlots) {
 		atomic bi = numSlots;
		call FrameConfiguration.setFrameLength(bi + 1);
 	}
 	command uint32_t Frame.getSlotLength() {
 		return slotSize;
 	}
 	command uint32_t Frame.getFrameLength() {
 		return bi + 1;
 	}

	/**
	 * MISC functions
	 */
	async command void *Send.getPayload(message_t * msg, uint8_t len) {
		return call SubSend.getPayload(msg, len);
	}

	async command uint8_t Send.maxPayloadLength() {
		return call SubSend.maxPayloadLength();
	}

	//provide the receive interface
	command void Receive.updateBuffer(message_t * msg) { return call SubReceive.updateBuffer(msg); }

	default async event uint16_t CcaControl.getInitialBackoff[am_id_t id](message_t * msg, uint16_t defaultbackoff) {
		return 0;
	}

	default async event uint16_t CcaControl.getCongestionBackoff[am_id_t id](message_t * msg, uint16_t defaultBackoff) {
		return 0;
	}

	default async event bool CcaControl.getCca[am_id_t id](message_t * msg, bool defaultCca) {
		return FALSE;
	}

    event void CC2420Config.syncDone(error_t error){}
    async event void BeaconSend.sendDone(message_t * msg, error_t error){}

    uint8_t get_last_hop_status(uint8_t flow_id_t, uint8_t access_type_t, uint8_t hop_count_t){
    	uint8_t last_hop_status=0;
    	uint8_t i;
    	for (i=0; i<schedule_len; i++){
    		if(schedule[i][0] <= call SlotterControl.getSlot() % superframe_length){
    			if (schedule[i][6]==flow_id_t){//check flow ID
					if(schedule[i][10] == (hop_count_t-1)){//check the previous hop-count
						if(schedule[i][9]==1){
							last_hop_status = schedule[i][9];
							//printf("Sensor:%u, GETTING RECEIVE, Slot:%u, %u, %u, %u, %u, %u , %u, %u, %u, %u, %u.\n", TOS_NODE_ID, schedule[i][0], schedule[i][1], schedule[i][2], schedule[i][3], schedule[i][4], schedule[i][5], schedule[i][6], schedule[i][7], schedule[i][8], schedule[i][9], schedule[i][10]);
						}
					}
    			}
    		}
		}
		return last_hop_status;
    }//end of get_last_hop_status

    void set_current_hop_status(uint32_t slot_t, uint8_t sender, uint8_t receiver){
    	uint8_t i;
    	for (i=0; i<schedule_len; i++){
    		if(schedule[i][0]==slot_t){// check send-receive pairs 1 slot before/after current slot
    			if(schedule[i][1] == sender){//check sender
					if(schedule[i][2] == receiver){//check receiver
						schedule[i][9]=1;
						//printf("Sensor:%u, SETTING RECEIVE, Slot:%u, %u, %u, %u, %u, %u , %u, %u, %u, [9]%u, %u.\n", TOS_NODE_ID, schedule[i][0], schedule[i][1], schedule[i][2], schedule[i][3], schedule[i][4], schedule[i][5], schedule[i][6], schedule[i][7], schedule[i][8], schedule[i][9], schedule[i][10]);
					}
				}
    		}
		}
    }// end of set_current_hop_status


	void set_send_status(uint8_t ack_at_send_done){
			uint8_t idx;

			idx = ExecutionBuf[Transmitting_flowid];
			if (ack_at_send_done==1){
				if(Transmitting_flowid == schedule[idx][6]){
					schedule[idx][8]=1;
				}
			}

   }// end of set_send_status

   void set_send (uint32_t slot_t){
		uint8_t i,j;
		uint32_t slot_norm = slot_t; //Here slot_norm is the real time slot normalized by superframe length
		TestNetworkMsg* tmp_payload;
		TestNetworkMsg* forwardPkt;
		uint8_t flowid;
		uint32_t tmp_rcv_slot;

		for (i=0; i<schedule_len; i++){
  			if (slot_norm == schedule[i][0]){//check slot
  				if(TOS_NODE_ID == schedule[i][1] || TOS_NODE_ID == schedule[i][2]){//check sender & receiver id
  					if(schedule[i][10]>1){ //check if this is on a multi-hop path
  						if(TOS_NODE_ID == schedule[i][1] && schedule[i][8]==0){//No. 8 in the schedule is Send status in sendDone
  			  				if (get_last_hop_status(schedule[i][6], schedule[i][4], schedule[i][10])){// if above so, check delivery status of last hop
										forwardPkt = (TestNetworkMsg*)call forwardQ.head();
										tmp_payload = call SubSend.getPayload(&packet, sizeof(TestNetworkMsg));
										tmp_payload->flowid = forwardPkt->flowid;
										Transmitting_flowid = forwardPkt->flowid;

										call CC2420Config.setChannel(schedule[i][3]);
	  								call CC2420Config.sync();
	  								call AMPacket.setDestination(&packet, schedule[i][2]);
	  								call PacketAcknowledgements.requestAck(&packet);

	  								call TossimPacketModelCCA.set_cca(schedule[i][4]); //schedule[i][4]: 0, TDMA; 1, CSMA contending; 2, CSMA steal;
		  							call SubSend.send(&packet, sizeof(TestNetworkMsg));
										dbg("transmission","nodeid:%d transmit at %d\n",TOS_NODE_ID, slot_norm);

  			  				}// end check last hop
  			  			}// end sender check
  			  			if(TOS_NODE_ID == schedule[i][2] && schedule[i][8]==0){
 	 			  				//printf("RECEIVER, HOP >1: %u, slot: %u, channel: %u, time: %s\n", TOS_NODE_ID, slot_norm, schedule[i][3], sim_time_string());
  			  					call CC2420Config.setChannel(schedule[i][3]);
  								call CC2420Config.sync();
  						}//end receiver check
  					}else{
  						if(TOS_NODE_ID == schedule[i][1] && schedule[i][8]==0){
								tmp_payload = call SubSend.getPayload(&packet, sizeof(TestNetworkMsg));
								tmp_payload->flowid = schedule[i][6];
								Transmitting_flowid = schedule[i][6];

  			  				call CC2420Config.setChannel(schedule[i][3]);
  							call CC2420Config.sync();
  							call AMPacket.setDestination(&packet, schedule[i][2]);
  							call PacketAcknowledgements.requestAck(&packet);
	  						call TossimPacketModelCCA.set_cca(schedule[i][4]); //schedule[i][4]: 0, TDMA; 1, CSMA contending; 2, CSMA steal;
	  						call SubSend.send(&packet, sizeof(TestNetworkMsg));
								dbg("transmission","nodeid:%d transmit at %d\n",TOS_NODE_ID, slot_norm);


	  					}
  						if(TOS_NODE_ID == schedule[i][2] && schedule[i][8]==0){
	  						//printf("RECEIVER, HOP =1: %u, slot: %u, channel: %u, time: %s\n", TOS_NODE_ID, slot_norm, schedule[i][3], sim_time_string());
  			  				call CC2420Config.setChannel(schedule[i][3]);
  							call CC2420Config.sync();
  						}
  					}//end else
  				}//end slot check
  			}//end sender || receiver check
  		}//end for

   	}//end set_send

}
