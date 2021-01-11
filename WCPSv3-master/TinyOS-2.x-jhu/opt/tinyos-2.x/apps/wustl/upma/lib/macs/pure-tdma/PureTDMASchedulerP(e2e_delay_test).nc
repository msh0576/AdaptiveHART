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

		interface Alarm<T32khz, uint16_t> as Txdelay;

		//Added by Sihoon
		interface ScheduleConfig;
		interface TossimPacketModel;
		interface Queue<TestNetworkMsg *> as forwardQ;

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

	//added by Sihoon
	void transmission(uint8_t schedule_idx, uint8_t ReTx_flag, bool relay_flag);
	void flow_centric_transmission(uint8_t slot_t ,uint32_t rcv_slot, uint8_t flowid, uint8_t slot_offset, bool isflowroot);

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

	uint8_t schedule[32][11]={//Source Routing, 16 sensor topology, 2 prime trans, retrans twice, baseline.
		//Flow sender schedule
		{1, 1, 3, 22, 0, 1, 1, 1, 0, 0, 1},
		{2, 3, 5, 22, 0, 1, 1, 1, 0, 0, 2},
		{3, 5, 7, 22, 0, 1, 1, 1, 0, 0, 3},
		{4, 7, 51, 22, 0, 1, 1, 1, 0, 0, 4}
		///
		//{1, 2, 4, 22, 0, 1, 2, 2, 0, 0, 1},
		//{2, 4, 52, 22, 0, 1, 2, 2, 0, 0, 2}
		};
	uint8_t schedule_len=32;
	uint32_t superframe_length = 15; //5Hz at most

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
	bool Transmit_ready[NETWORK_FLOW];		//flowid to be transmitted at next slot
	bool receive_lock[NETWORK_FLOW];		//prevent multiple reception from the same flow in a superframe

	/* Flow root indicator */
	bool isFlowroot;
	uint8_t Slot_offset;

	/* End-to-end delay indicator */
	uint32_t e2e_delay_buffer[15] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};	// index: receive slot, value: count

	bool sync;
	bool requestStop;
	uint32_t sync_count = 0;

	event void Boot.booted(){}

		/******** Schedule-Free MAC *******  */

	command error_t Init.init() {
		uint8_t i, j;
		uint32_t (*VCS_buffer)[VCS_COL_SIZE];

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
		Slot_offset = 0;
		//backup_schedule[BACKUPNODE] = call ScheduleConfig.backupNode(TOS_NODE_ID);
		//dbg("transmission","backup_schedule[0]:%d\n", backup_schedule[0]);

		//Store primary and backup path for each flow id
		for(i=0; i<NETWORK_FLOW; i++){
			Path[i][PRIMARYPATH] = call ScheduleConfig.primaryNode(i, TOS_NODE_ID);
			Path[i][BACKUPPATH] = call ScheduleConfig.backupNode(i, TOS_NODE_ID);
			//dbg("transmission","Primarypath of flow%d:%d\n", i, Path[i][PRIMARYPATH]);
			//dbg("transmission","Backuppath of flow%d:%d\n", i, Path[i][BACKUPPATH]);

			//Initialize
			ExecutionBuf[i] = 0;
			PktLossBuff[i] = 0;
			rcv_slot[i] = 0;
			rcv_count[i] = 0;
			Transmit_ready[i] = FALSE;
			receive_lock[i] = FALSE;
			for(j=0; j<MAX_LINK_RETX+1; j++){
				trans_count[i][j] = 0;
			}

		}

		// Set whether each node is flow root or not
		if(call ScheduleConfig.flowsource(TOS_NODE_ID) == TRUE){
			isFlowroot = TRUE;
		}


		// Find schedule informations and fow criticality of each node
		for(i=0; i<schedule_len; i++) {
			if(schedule[i][1] == TOS_NODE_ID) {
				backup_schedule[CRITICALITY] = call ScheduleConfig.criticality(schedule[i][6]);		//Assume: primary flows are not inter-cross at some nodes

				Sched_idx[schedule[i][6]] = i;

				// Set Tx start time slot of each flow root node
				if(isFlowroot == TRUE){
					Slot_offset = schedule[i][0];
				}
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

		VCS_buffer = sim_get_VirtualSchedule();
		if(TOS_NODE_ID <= NETWORK_NODE){
			if(VCS_buffer[TOS_NODE_ID][0] != NULL){
				TxOffset = VCS_buffer[TOS_NODE_ID][0];
			}
		}
		dbg("VCStest","My TxOffset:%d\n", TxOffset);


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
 		uint8_t i;

		atomic slot_ = slot;

 		if (slot == 0 ) {
 			if (coordinatorId == TOS_NODE_ID) {
 				call BeaconSend.send(NULL, 0);
 				dbg("printf","SENSOR: %u has done network synchronization in SLOT: %u at time: %s:\n", TOS_NODE_ID, slot, sim_time_string());
 			};
 			return;
 		}

		/* Receiver Setting */


  		if ((slot % superframe_length) == 0 ) {
	 			for (i=0; i<schedule_len; i++){
	  				schedule[i][8]=0; //re-enable transmission by set the flag bit to 0, implying this transmission is unfinished and to be conducted.
	  				schedule[i][9]=0; //reset "last hop status" to 0 to avoid future confusions, especially in .
		  	}

				//Reset Transmitting variable & Pkt loss buffer & received slot
				for(i=0; i<NETWORK_FLOW; i++){
					ExecutionBuf[i] = 0;
					PktLossBuff[i] = 0;
					rcv_slot[i] = 0;
					Transmit_ready[i] = FALSE;
					receive_lock[i] = FALSE;
				}
				Transmitting_flowid = 0;

				//Count Pkt loss in a superframe
				if(Receive_flag == TRUE){
					Receive_flag = FALSE;
				}else {
					Loss_count = Loss_count + 1;
				}

				if(TOS_NODE_ID == 51 || TOS_NODE_ID == 52){
					//dbg("receive","Loss_count:%d\n", Loss_count);
				}
				/// Queue Initilize
				if(!call forwardQ.empty()){
					queueSize = call forwardQ.size();
					for(i=0; i<queueSize; i++){
						call forwardQ.dequeue();
					}
				}

				//e2e delay print
				if(TOS_NODE_ID == 51){
					dbg("receive","e2e_delay_buffer[1]:%d, [2]:%d, [3]:%d, [4]:%d, [5]:%d, [6]:%d, [7]:%d, [8]:%d, [9]:%d, [10]:%d, [11]:%d, [12]:%d\n", e2e_delay_buffer[1], e2e_delay_buffer[2], e2e_delay_buffer[3], e2e_delay_buffer[4], e2e_delay_buffer[5], e2e_delay_buffer[6], e2e_delay_buffer[7], e2e_delay_buffer[8], e2e_delay_buffer[9], e2e_delay_buffer[10], e2e_delay_buffer[11], e2e_delay_buffer[12]);

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
			atomic Transmit_ready[Transmitting_flowid] = FALSE;
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
		if(TOS_NODE_ID == 3 || TOS_NODE_ID == 5 || TOS_NODE_ID == 7 || TOS_NODE_ID == 51 || TOS_NODE_ID == 4 || TOS_NODE_ID == 52){
		if(flow_id_rcv != 0 && receive_lock[flow_id_rcv] == FALSE) {
			for(i=0; i<schedule_len; i++) {
				if(schedule[i][2] == TOS_NODE_ID && schedule[i][6] == flow_id_rcv){
					rcv_slot[flow_id_rcv] = current_slot;
					Receive_flag = TRUE;
					rcv_count[flow_id_rcv] = rcv_count[flow_id_rcv] + 1;
					Transmit_ready[flow_id_rcv] = TRUE;
					receive_lock[flow_id_rcv] = TRUE;

					//check e2e delay
					if(TOS_NODE_ID == 51){
						e2e_delay_buffer[current_slot] = e2e_delay_buffer[current_slot] + 1;
					}

					dbg("receive","flow_id:%u, SLOT: %u, src:%u, myID:%u, channel:%u   rcv_count[%d]:%d\n\n", flow_id_rcv, rcv_slot[flow_id_rcv], src, TOS_NODE_ID, call CC2420Config.getChannel(), flow_id_rcv, rcv_count[flow_id_rcv]);

					//Log results
					//Node id,	flow id,	rcv_count, rcv_count_at_slot1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
					dbg_clear("Log_data","%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n", TOS_NODE_ID, flow_id_rcv, rcv_count[flow_id_rcv], e2e_delay_buffer[1], e2e_delay_buffer[2], e2e_delay_buffer[3], e2e_delay_buffer[4], e2e_delay_buffer[5], e2e_delay_buffer[6], e2e_delay_buffer[7], e2e_delay_buffer[8], e2e_delay_buffer[9], e2e_delay_buffer[10], e2e_delay_buffer[11], e2e_delay_buffer[12]);



					//below is the tcp approach based on a global variable on each sensor, tcp_msg, defined in SimMoteP.nc added by Bo
					call SimMote.setTcpMsg(flow_id_rcv, call SlotterControl.getSlot() % superframe_length, src, TOS_NODE_ID, call CC2420Config.getChannel());

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
		uint8_t flowid;
		uint32_t tmp_rcv_slot;

		// bool idleStatus;
		for (i=0; i<schedule_len; i++){
  			if (slot_norm == schedule[i][0]){//check slot
  				if(TOS_NODE_ID == schedule[i][1] || TOS_NODE_ID == schedule[i][2]){//check sender & receiver id
  					if(schedule[i][10]>1){ //check if this is on a multi-hop path

							// Receiver Setting
							if(TOS_NODE_ID == schedule[i][2] && schedule[i][8]==0){
	 			  				//printf("RECEIVER, HOP >1: %u, slot: %u, channel: %u, time: %s\n", TOS_NODE_ID, slot_norm, schedule[i][3], sim_time_string());
			  					call CC2420Config.setChannel(schedule[i][3]);
								call CC2420Config.sync();
							}//end receiver check
  					}
						// Flow Root Tx
						else{

							// Receiver Setting
  						if(TOS_NODE_ID == schedule[i][2] && schedule[i][8]==0 && schedule[i][10]==1){
			  				call CC2420Config.setChannel(schedule[i][3]);
  							call CC2420Config.sync();
  						}
  					}//end else
  				}
  			}//end slot check

  		}//end for

			// What is the order of transmit flow...
			// * Caution: a node pre-transmit pkts of a flow that has fast flow id.
			for(i=0; i<NETWORK_FLOW; i++){
					//dbg("transmission","Transmit_ready[%d]:%d at slot:%d\n", i,Transmit_ready[i], slot_norm);
					if(Transmit_ready[i] == TRUE){
						flowid = i;
						tmp_rcv_slot = rcv_slot[flowid];
						flow_centric_transmission(slot_norm ,tmp_rcv_slot, flowid, Slot_offset, FALSE);
						break;
					}
			}
			// for flow root Tx
			// * Caution: Flow id should be same with the flow root node id
			if(isFlowroot == TRUE){
				flowid = TOS_NODE_ID;
				tmp_rcv_slot = 0;
				flow_centric_transmission(slot_norm ,tmp_rcv_slot, flowid, Slot_offset, TRUE);	//Slot_offset: The start slot of the flow Tx
			}

			/* Flow Root Tx */
			

			/* Relay Node Tx */

   	}//end set_send

		void transmission(uint8_t schedule_idx, uint8_t ReTx_flag, bool relay_flag) {
			TestNetworkMsg* tmp_payload;
			TestNetworkMsg* forwardPkt;
			uint8_t i;

			i = schedule_idx;



			/// check the flow root Tx or the relay Tx
			if(relay_flag == FALSE){
				tmp_payload = call SubSend.getPayload(&packet, sizeof(TestNetworkMsg));
				tmp_payload->flowid = schedule[i][6];
			}else{
				if(!call forwardQ.empty()){
					forwardPkt = (TestNetworkMsg*)call forwardQ.head();
					//call forwardQ.dequeue();

					tmp_payload = call SubSend.getPayload(&packet, sizeof(TestNetworkMsg));
					tmp_payload->flowid = forwardPkt->flowid;
				}else{
					dbg("transmission","Q empty\n");
					return;
				}
			}

			call CC2420Config.setChannel(schedule[i][3]);
			call CC2420Config.setPower(RADIO_DEF_POWER);		//changed by sihoon
			call CC2420Config.sync();

			if(ReTx_flag == 2) {	// Second retransmission change their destination
				call AMPacket.setDestination(&packet, Path[schedule[i][6]][BACKUPPATH]);
				//dbg("transmission","!!!!!!!!!!!!!!!!!backupnode:%d\n", backup_schedule[BACKUPNODE]);
			}else if(ReTx_flag == 1 || ReTx_flag == 0) {
				call AMPacket.setDestination(&packet, Path[schedule[i][6]][PRIMARYPATH]);
			}

			// Prevent retransmissions of low critical flows
			if((ReTx_flag == 1 || ReTx_flag == 2) && backup_schedule[CRITICALITY] == 0){
				return;
			}



			//dbg("transmission","sdfs\n");
			call PacketAcknowledgements.requestAck(&packet);
			call TossimPacketModelCCA.set_cca(schedule[i][4]); //schedule[i][4]: 0, TDMA; 1, CSMA contending; 2, CSMA steal;
			//Set transmitting variable
			atomic Transmitting_flowid = tmp_payload->flowid;
			if(Transmitting_flowid <= NETWORK_FLOW-1){
				//dbg("transmission","sdfs\n");
				ExecutionBuf[Transmitting_flowid] = i;
				call Txdelay.start(32 * TxOffset);
			}
		}


		/* Transmit pkt after TxOffset */
		async event void Txdelay.fired() {
			//dbg("transmission","");

			if( call SubSend.send(&packet, sizeof(TestNetworkMsg)) == SUCCESS) {
				atomic trans_count[Transmitting_flowid][PktLossBuff[Transmitting_flowid]] = trans_count[Transmitting_flowid][PktLossBuff[Transmitting_flowid]] + 1;

				dbg("transmission","trans_count[%d][%d]:%d\n",Transmitting_flowid, PktLossBuff[Transmitting_flowid], trans_count[Transmitting_flowid][PktLossBuff[Transmitting_flowid]]);

			}else {}

		}



		/* Relay node flow-centric (Re)transmissions */
		// This function is executed after checking multihop transmission
		void flow_centric_transmission(uint8_t slot_t ,uint32_t rcv_slot, uint8_t flowid, uint8_t slot_offset, bool isflowroot) {
			uint8_t Tx_slot;
			uint8_t Max_Tx_slot;
			uint8_t Root_Tx_slot;			//for flow root Tx
			uint8_t Max_Root_Tx_slot;
			uint8_t tmp_sched_idx = Sched_idx[flowid];
			uint8_t retx_idx = PktLossBuff[flowid];


			//for flow root transmission
			if(isflowroot == TRUE){
				Root_Tx_slot = slot_offset;
				Max_Root_Tx_slot = Root_Tx_slot + MAX_LINK_RETX;

				if(slot_t >= Root_Tx_slot && slot_t <= Max_Root_Tx_slot){
					if(schedule[tmp_sched_idx][10]==1){
						//check (sender, no-ack, retransmission count)
						if(schedule[tmp_sched_idx][1] == TOS_NODE_ID && schedule[tmp_sched_idx][8] == 0 && retx_idx <= MAX_LINK_RETX){
							dbg("transmission","flow root transmission, tmp_sched_idx:%d, retx_idx:%d at slot:%d\n", tmp_sched_idx, retx_idx, slot_t);
							transmission(tmp_sched_idx, retx_idx, FALSE);
							return;
						}
					}
				}
			}
			//for relay node transmission
			else{
				Tx_slot = rcv_slot + 1;
				Max_Tx_slot = Tx_slot + MAX_LINK_RETX;

				//check the current slot is on the boundary of (re)transmission
				if(slot_t >= Tx_slot && slot_t <= Max_Tx_slot){
					//check multihop transmission
					if(schedule[tmp_sched_idx][10]>1){
						//check (sender, no-ack)
						if(schedule[tmp_sched_idx][1] == TOS_NODE_ID && schedule[tmp_sched_idx][8] == 0 && retx_idx <= MAX_LINK_RETX){
							dbg("transmission","relay transmission, tmp_sched_idx:%d, retx_idx:%d at slot:%d\n", tmp_sched_idx, retx_idx, slot_t);
							transmission(tmp_sched_idx, retx_idx, TRUE);
							return;
						}
					}
				}
			}

		}

}
