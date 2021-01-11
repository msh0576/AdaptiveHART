/*
*			F-MAC added by sihoon
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
		interface Alarm<T32khz, uint16_t> as CCATxdelay;

		//Added by Sihoon
		interface ScheduleConfig;
		interface TossimPacketModel;
		interface Queue<TestNetworkMsg *> as HIforwardQ;
		interface Queue<TestNetworkMsg *> as LOforwardQ;
		interface GainRadioModel2 as CCAevent;
		interface Read<uint16_t> as ReadRssi;
	}
}
implementation {
	enum {
		SIMPLE_TDMA_SYNC = 123,
		FRAME_LENGTH = 3,
		RADIO_DEF_POWER = 0,
		RADIO_MAX_POWER = 31,
		CHANNEL_DEF = 22,
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
	message_t HIforwardPktBuffer[MAC_Q];
	message_t LOforwardPktBuffer[MAC_Q];
	uint8_t HIqueueSize;
	uint8_t LOqueueSize;

	//Added by sihoon
	uint32_t slot_;
	uint16_t rcv_count[NETWORK_FLOW];
	uint16_t Tx_count[NETWORK_FLOW];
	uint16_t Total_tx_count[NETWORK_FLOW];

	uint8_t TxOffset;


	uint8_t get_last_hop_status(uint8_t flow_id_t, uint8_t access_type_t, uint8_t hop_count_t);
	void set_current_hop_status(uint32_t slot_t, uint8_t sender, uint8_t receiver);
	void set_send_status(uint8_t ack_at_send_done, uint8_t taskid);
	void set_send (uint32_t slot_t);
	uint32_t SuperframeLength(uint32_t Task_set[][3]);
	uint32_t getGCD(uint32_t num1, uint32_t num2);
	uint32_t getLCD(uint32_t num1, uint32_t num2);
	void printfFloat(float toBePrinted);

	//added by Sihoon
	void transmission(uint8_t Txing_flowid);


	uint8_t schedule[NETWORK_FLOW][3]={//Source Routing, 16 sensor topology, 2 prime trans, retrans twice, baseline.
		//Flow sender schedule
		{0, 0},
		{0, 1},		// Task 1 : [0] release time, [1] Source node
		{0, 2}		// Task 2 :

		};
	uint32_t superframe_length = 50; //5Hz at most

	/* Task character */
	//index: Task id
	//0 Task Period
	//1 Task deadline
	//2 Task maximum Tx oppertunity
	uint8_t NUM_TASK = 2;	// # of existing tasks
	uint8_t HI_TASK = 1;
	uint8_t LO_TASK = 2;
	uint32_t Task_character[NETWORK_FLOW][3]={
		{0, 0, 0},
		{25, 25, 2},
		{25, 25, 2}
	};
	uint8_t TASK_PERIOD = 0;
	uint8_t TASK_DEAD = 1;
	uint8_t TASK_MAXTX = 2;


	/* Routing Path */
	//0 Primary path
	//1 Backup path
	uint8_t Path[NETWORK_FLOW][2];
	uint8_t PRIMARYPATH = 0;
	uint8_t BACKUPPATH = 1;

	/* Transmit schedule index buffer for each flow */
	uint32_t rcv_slot[NETWORK_FLOW];		//receive slot for each flow
	bool receive_lock[NETWORK_FLOW];		//prevent multiple reception from the same flow in a superframe

	/* Flow root indicator */
	bool isFlowroot;
	bool isFlowdest;
	uint8_t Task_rels;

	/* End-to-end delay indicator */
	uint32_t e2e_delay_buffer[NETWORK_FLOW][10000];	// index: receive slot, value: count

	/* Tx/Rx status */
	bool send_status[NETWORK_FLOW];								// TRUE if Tx success for a task
	bool Rcv_check_mode;													// for checking pkt reception at TxOffset interval
	uint8_t taskid;
	uint8_t Transmitting_flowid;
	uint8_t My_max_txopper[NETWORK_FLOW];
	uint8_t check_link_quality_1;

	bool sync;
	bool requestStop;
	uint32_t sync_count = 0;

	/* Schedule ratio check */
	uint16_t crt_frame[NETWORK_FLOW];
	uint32_t Total_frame_count[NETWORK_FLOW];
	uint16_t Receiving_flag[NETWORK_FLOW];
	uint8_t Receiving_flow_id = 0;
	uint16_t kth_job = 0;
	uint16_t prev_job_idx[NETWORK_FLOW];
	uint16_t Loss_count[NETWORK_FLOW];
	uint16_t Miss_count[NETWORK_FLOW];

	uint8_t PDR_window = 20;
	//float AcutationPDR[PDR_window];

	// for check wireless interference (temporaly)
	uint32_t temp_interf;
	uint32_t temp_dist;



	event void Boot.booted(){}

		/******** Schedule-Free MAC *******  */

	command error_t Init.init() {
		uint8_t i, j;
		uint32_t (*VCS_buffer)[VCS_COL_SIZE];
		uint32_t *Task_T_buffer;
		uint32_t *Task_Tx_buffer;

		slotSize = 10 * 32;     //10ms
		bi = 40000; //# of slots in the supersuperframe with only one slot 0 doing sync
		sd = 40000; //last active slot
		cap = 0; // what is this used for? is this yet another superframe length?

		check_link_quality_1 = 0;
		isFlowroot = FALSE;
		isFlowdest = FALSE;
		Task_rels = 0;
		taskid = 0;

		/* Task Periods from Python */
		// For Util_Log_data
		Task_T_buffer = sim_get_TaskPeriods();
		Task_character[1][TASK_PERIOD] = Task_T_buffer[0];
		Task_character[1][TASK_DEAD] = Task_T_buffer[0];
		Task_character[2][TASK_PERIOD] = Task_T_buffer[1];
		Task_character[2][TASK_DEAD] = Task_T_buffer[1];
		superframe_length = SuperframeLength(Task_character);	//Test for AbsoluteError application
		//superframe_length = 50;


		/* Task Retransmissions from Python */
		Task_Tx_buffer = sim_get_TaskTx();
		Task_character[1][TASK_MAXTX] = Task_Tx_buffer[0];
		Task_character[2][TASK_MAXTX] = Task_Tx_buffer[1];

		// For check Interference
		temp_interf = Task_Tx_buffer[3];
		temp_dist = Task_T_buffer[3];

		//Store primary and backup path for each flow id
		for(i=0; i<NETWORK_FLOW; i++){
			Path[i][PRIMARYPATH] = call ScheduleConfig.primaryNode(i, TOS_NODE_ID);
			Path[i][BACKUPPATH] = call ScheduleConfig.backupNode(i, TOS_NODE_ID);
			//dbg("transmission","Primarypath of flow%d:%d\n", i, Path[i][PRIMARYPATH]);
			//dbg("transmission","Backuppath of flow%d:%d\n", i, Path[i][BACKUPPATH]);

			//Initialize
			rcv_slot[i] = 0;
			rcv_count[i] = 0;
			receive_lock[i] = FALSE;
			Tx_count[i] = 0;
			Total_tx_count[i] = 0;

			/* Tx/RX status */
			send_status[i] = FALSE;
			Rcv_check_mode = FALSE;
			My_max_txopper[i] = 0;
			crt_frame[i] = 0;
			Total_frame_count[i] = 0;
			Receiving_flag[i] = TRUE;
			Loss_count[i] = 0;
			Miss_count[i] = 0;
			prev_job_idx[i] = 0;

			//For E2E_delay_Log_data

			for(j=0; j<superframe_length; j++){
				e2e_delay_buffer[i][j] = 0;
			}

		}
		// Set whether each node is flow root or not
		if(call ScheduleConfig.flowsource(TOS_NODE_ID) == TRUE){
			isFlowroot = TRUE;
			taskid = call ScheduleConfig.taskid(TOS_NODE_ID);
			My_max_txopper[taskid] = Task_character[taskid][TASK_MAXTX];
			Task_rels = schedule[taskid][0];	// transmission offset
		}else if(call ScheduleConfig.flowdestination(TOS_NODE_ID) == TRUE){
			isFlowdest = TRUE;
		}

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


		dbg("Task_T_Test","Task_T_buffer[]:%d, %d, %d, %d\n", Task_T_buffer[0], Task_T_buffer[1], Task_T_buffer[2], Task_T_buffer[3]);
		dbg("Task_T_Test","Task_maxTx_buffer[]:%d, %d, %d, %d\n", Task_Tx_buffer[0], Task_Tx_buffer[1], Task_Tx_buffer[2], Task_Tx_buffer[3]);
		dbg("Task_T_Test","Superframe:%lu\n", superframe_length);
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
		uint32_t *Dist_Check;
		uint32_t *Interf_Check;

		atomic slot_ = slot;

		/* for Src node to check interference */
		//if (isFlowroot == TRUE){

			Dist_Check = sim_get_TaskPeriods();
			Interf_Check = sim_get_TaskTx();
			// Num_ReTx change
			if(Interf_Check[3] != temp_interf){
				temp_interf = Interf_Check[3];
				dbg_clear("Util_Log_data","-----Interference-----\n");
				Task_character[1][TASK_MAXTX] = Interf_Check[0];
				My_max_txopper[1] = Task_character[1][TASK_MAXTX];
				Task_character[2][TASK_MAXTX] = Interf_Check[1];
				My_max_txopper[2] = Task_character[2][TASK_MAXTX];
				dbg_clear("Util_Log_data","Task1_maxTx:%d\n",My_max_txopper[1]);
				dbg_clear("Task_T_Test","maxReTx - T1:%d / T2:%d\r\n", My_max_txopper[1], My_max_txopper[2]);
			}
			// Task Period change
			if(Dist_Check[3] != temp_dist){
				temp_dist = Dist_Check[3];
				dbg_clear("Util_Log_data","-----Disturbance-----\n");
				Task_character[1][TASK_PERIOD] = Dist_Check[0];
				Task_character[1][TASK_DEAD] = Dist_Check[0];
				Task_character[2][TASK_PERIOD] = Dist_Check[1];
				Task_character[2][TASK_DEAD] = Dist_Check[1];
				superframe_length = SuperframeLength(Task_character);
				dbg("Task_T_Test","T1:%d, T2:%d\n", Dist_Check[0], Dist_Check[1]);
				dbg("Task_T_Test","Superframe:%lu\n", superframe_length);
			}
		//}
		////////////////////////////////////////

 		if (slot == 0 ) {
 			if (coordinatorId == TOS_NODE_ID) {
 				call BeaconSend.send(NULL, 0);
 				dbg("printf","SENSOR: %u has done network synchronization in SLOT: %u at time: %s:\n", TOS_NODE_ID, slot, sim_time_string());
 			};
 			return;
 		}

		if ((slot % superframe_length) == 0 ) {
			if (1 == TOS_NODE_ID) {
				dbg("transmission","SF-------------\n");
				//dbg("Task_T_Test","SF----------------\n");
			};

			// for schedule ratio check
			crt_frame[HI_TASK] = 0;
			crt_frame[LO_TASK] = 0;
			kth_job = 0;
			prev_job_idx[HI_TASK] = 0;
			prev_job_idx[LO_TASK] = 0;
 		}

		/* Receiver Setting */
		// It should be modified, becuase it assumes that every nodes recognize Task periods, which is not reasonable
		// We will modify it to that a node transmit a packet with task period (T) and residual (R), which is the deadline_slot-current_slot
		// The node received the packet initilize receive_lock, Q, and so on after residual slots
		if(( (slot%superframe_length) % Task_character[HI_TASK][TASK_PERIOD] == 0)){

			// for schedule ratio check
			crt_frame[HI_TASK] = crt_frame[HI_TASK] + 1;
			Total_frame_count[HI_TASK] = Total_frame_count[HI_TASK] + 1;

			if(TOS_NODE_ID == 51){
				// Node id, Flow id, Loss_count, Total Tx count
				if(Receiving_flag[HI_TASK] == FALSE){
					Loss_count[HI_TASK] = Loss_count[HI_TASK] + 1;
				}
				//dbg("Task_T_Test", "T1 period\r\n");
				dbg_clear("Util_Log_data","%d %d %d %d\n", TOS_NODE_ID, HI_TASK, Loss_count[HI_TASK], Total_frame_count[HI_TASK]);
				Receiving_flag[Receiving_flow_id] = FALSE;


			}
			if(isFlowroot == TRUE && TOS_NODE_ID == 1){
				// For check link quality
				dbg_clear("check_link_quality", "---Task_period_End---\r\n");
			}
			/*
			if(TOS_NODE_ID == 3 || TOS_NODE_ID == 4){
				if(call HIforwardQ.empty() == TRUE){
					Miss_count[HI_TASK] = Miss_count[HI_TASK] + 1;

				}
			}*/

			// for nodes to prevent receiving duplicate packets from previous node
			rcv_slot[HI_TASK] = 0;
			receive_lock[HI_TASK] = FALSE;		// Rx prevent
			Tx_count[HI_TASK] = 0;

			/// Queue Initilize
			// Tx prevent
			if(!call HIforwardQ.empty()){
				//dbg("transmission","HIQ Reset\n");
				HIqueueSize = call HIforwardQ.size();
				for(i=0; i<HIqueueSize; i++){
					call HIforwardQ.dequeue();
				}
			}
		}
		if(( (slot%superframe_length) % Task_character[LO_TASK][TASK_PERIOD] == 0)){

			// for schedule ratio check
			crt_frame[LO_TASK] = crt_frame[LO_TASK] + 1;
			Total_frame_count[LO_TASK] = Total_frame_count[LO_TASK] + 1;

			if(TOS_NODE_ID == 52){
				///* for checking schedule ratio  */
				// Node id, Flow id, Loss_count, Total Tx count
				if(Receiving_flag[LO_TASK] == FALSE){
					Loss_count[LO_TASK] = Loss_count[LO_TASK] + 1;
				}
				dbg_clear("Util_Log_data","%d %d %d %d\n", TOS_NODE_ID, LO_TASK, Loss_count[LO_TASK], Total_frame_count[LO_TASK]);
				Receiving_flag[Receiving_flow_id] = FALSE;
			}

			// for nodes to prevent receiving duplicate packets from previous node
			rcv_slot[LO_TASK] = 0;
			receive_lock[LO_TASK] = FALSE;
			Tx_count[LO_TASK] = 0;

			/// Queue Initilize
			if(!call LOforwardQ.empty()){
				//dbg("transmission","LOQ Reset\n");
				LOqueueSize = call LOforwardQ.size();
				for(i=0; i<LOqueueSize; i++){
					call LOforwardQ.dequeue();
				}
			}

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
		uint8_t i;
		slot_at_send_done = call SlotterControl.getSlot() % superframe_length;
		ack_at_send_done = call PacketAcknowledgements.wasAcked(msg)?1:0;


		//link failure statistics
		if(ack_at_send_done==0){
			//dbg("transmission","No ACK\n");

			/* set Tx/Rx status */
			if(Tx_count[Transmitting_flowid] == My_max_txopper[Transmitting_flowid]){  // problem -- "Task_character[Transmitting_flowid][TASK_MAXTX]", should be
				dbg("transmission","NoACK:Reset Tx/Rx status -- Transmitting_flowid:%d\n", Transmitting_flowid);
				Tx_count[Transmitting_flowid] = 0;
				rcv_slot[Transmitting_flowid] = 0;
				//My_max_txopper[Transmitting_flowid] = 0;
				receive_lock[Transmitting_flowid] = FALSE;

				/* Q Reset */

				if(Transmitting_flowid == HI_TASK){
					if(!call HIforwardQ.empty()){
						HIqueueSize = call HIforwardQ.size();
						for(i=0; i<HIqueueSize; i++){
							call HIforwardQ.dequeue();
						}
					}
				}else if(Transmitting_flowid == LO_TASK){
					if(!call LOforwardQ.empty()){
						LOqueueSize = call LOforwardQ.size();
						for(i=0; i<LOqueueSize; i++){
							call LOforwardQ.dequeue();
						}
					}
				}
			}

		}else if(ack_at_send_done==1){
			/* set Tx/Rx status */
			Tx_count[Transmitting_flowid] = 0;
			rcv_slot[Transmitting_flowid] = 0;
			//My_max_txopper[Transmitting_flowid] = 0;
			// it should be modified
			//receive_lock[Transmitting_flowid] = FALSE;		// it should be revitalized after the Task_character[TASK_MAXTX]-1 slots, except for destination nodes

			/* Q Reset */
			//dbg("transmission","ACK receive\n");
			if(Transmitting_flowid == HI_TASK){
				//dbg("transmission","HIQ Reset\n");
				HIqueueSize = call HIforwardQ.size();
				for(i=0; i<HIqueueSize; i++){
					call HIforwardQ.dequeue();
				}
			}else if (Transmitting_flowid == LO_TASK){
				//dbg("transmission","LOQ Reset\n");
				LOqueueSize = call LOforwardQ.size();
				for(i=0; i<LOqueueSize; i++){
					call LOforwardQ.dequeue();
				}
			}

		}
		//set ACK variable
		send_status[Transmitting_flowid] = ack_at_send_done;
		//Initialize Transmitting variable
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
		uint8_t i, link;
		uint8_t flow_id_rcv;
		uint32_t current_slot;
		uint8_t curr_hopcount;
		uint16_t rssi;
		TestNetworkMsg* tmp_payload;
		TestNetworkMsg* HIdataBuffer;
		TestNetworkMsg* LOdataBuffer;
		char * printfResults;



		current_slot = call SlotterControl.getSlot() % superframe_length;
		tmp_payload = (TestNetworkMsg*)payload;
		flow_id_rcv = tmp_payload->flowid; //changed by sihoon
		set_current_hop_status(call SlotterControl.getSlot() % superframe_length, src, TOS_NODE_ID);

		//dbg("transmission","MAC receive\n");
		//check flowid, destination,
		if(TOS_NODE_ID == 3 ||  TOS_NODE_ID == 51 || TOS_NODE_ID == 4 || TOS_NODE_ID == 5 ||TOS_NODE_ID == 6 ||TOS_NODE_ID == 52){
			if(flow_id_rcv != 0 && receive_lock[flow_id_rcv] == FALSE) {
				//dbg("Task_T_Test","current frame[%d]:%u		job_idx:%u	prev_job_idx[%d];%u  My_max_txopper:%d\n", flow_id_rcv,crt_frame[flow_id_rcv], tmp_payload->job_idx, flow_id_rcv, prev_job_idx[flow_id_rcv], My_max_txopper[flow_id_rcv]);

				if(prev_job_idx[flow_id_rcv] == tmp_payload->job_idx){
					// Duplicate packet reception can be occurred because of receive_lock, which will be false after receive slot
					//dbg("Task_T_Test","duplicate receive\n");

				}else{
					// for checking schedule ratio
					prev_job_idx[flow_id_rcv] = tmp_payload->job_idx;
					Receiving_flag[flow_id_rcv] = TRUE;
					Receiving_flow_id = flow_id_rcv;

					// set Rcv_check_mode for deferring Lo task Tx
					rcv_slot[flow_id_rcv] = current_slot;		// for checking e2e delay
					rcv_count[flow_id_rcv] = rcv_count[flow_id_rcv] + 1;		// for checking PDR
					receive_lock[flow_id_rcv] = TRUE;
					curr_hopcount = tmp_payload->hopcount + 1;
					My_max_txopper[flow_id_rcv] = tmp_payload->txopper[curr_hopcount];


					dbg("receive","flow_id:%u, SLOT: %u, src:%u, myID:%u, channel:%u   rcv_count[%d]:%d\n\n", flow_id_rcv, rcv_slot[flow_id_rcv], src, TOS_NODE_ID, call CC2420Config.getChannel(), flow_id_rcv, rcv_count[flow_id_rcv]);
					//below is the tcp approach based on a global variable on each sensor, tcp_msg, defined in SimMoteP.nc added by Bo
					if(isFlowdest == TRUE){
						//call ReadRssi.read();		// return noise

						call SimMote.setTcpMsg(flow_id_rcv, call SlotterControl.getSlot() % superframe_length, src, TOS_NODE_ID, call CC2420Config.getChannel());

					}

					// Queue //
					if(flow_id_rcv == HI_TASK){
						HIqueueSize = call HIforwardQ.size();
						HIdataBuffer = (TestNetworkMsg*)call SubSend.getPayload(&HIforwardPktBuffer[HIqueueSize], sizeof(TestNetworkMsg));
						HIdataBuffer->flowid = tmp_payload->flowid;
						HIdataBuffer->hopcount = tmp_payload->hopcount;
						for(link=0; link<MAX_LINK_HOP; link++){
							HIdataBuffer->txopper[link] = tmp_payload->txopper[link];
							HIdataBuffer->txdelay[link] = tmp_payload->txdelay[link];
						}
						HIdataBuffer->job_idx = tmp_payload->job_idx;
						if(HIdataBuffer != NULL){
							call HIforwardQ.enqueue(HIdataBuffer);
						}
					}else if(flow_id_rcv == LO_TASK){
						LOqueueSize = call LOforwardQ.size();
						LOdataBuffer = (TestNetworkMsg*)call SubSend.getPayload(&LOforwardPktBuffer[LOqueueSize], sizeof(TestNetworkMsg));
						LOdataBuffer->flowid = tmp_payload->flowid;
						LOdataBuffer->hopcount = tmp_payload->hopcount;
						for(link=0; link<MAX_LINK_HOP; link++){
							LOdataBuffer->txopper[link] = tmp_payload->txopper[link];
							LOdataBuffer->txdelay[link] = tmp_payload->txdelay[link];
						}
						LOdataBuffer->job_idx = tmp_payload->job_idx;
						if(LOdataBuffer != NULL){
							call LOforwardQ.enqueue(LOdataBuffer);
						}
					}

					//Log results
					//check e2e delay
					if(isFlowdest == TRUE){

						e2e_delay_buffer[flow_id_rcv][current_slot] = e2e_delay_buffer[flow_id_rcv][current_slot] + 1;
						//dbg("E2E_delay_Log_data", "---");
						//Node id,	flow id,	rcv_count, rcv_count_at_slot0,1,2,...
						//dbg_clear("E2E_delay_Log_data","%d %d %d ", TOS_NODE_ID, flow_id_rcv, rcv_count[flow_id_rcv]);
						dbg_clear("E2E_delay_Log_data","%d %d %d %d ", TOS_NODE_ID, flow_id_rcv, rcv_count[flow_id_rcv], Total_frame_count[flow_id_rcv]);
						for(i=0; i<superframe_length; i++){
							dbg_clear("E2E_delay_Log_data","%d ", e2e_delay_buffer[flow_id_rcv][i]);
						}
						dbg_clear("E2E_delay_Log_data","\n");


						// Check link qualtiy
						if(TOS_NODE_ID == 51){
							dbg_clear("check_link_quality","RxCount: %d\n", rcv_count[1]);

						}
					}
				}
			}
		}
		//printf("RECEIVE: %u->%u, SLOT:%u (time: %s), channel: %u\n", src,TOS_NODE_ID, call SlotterControl.getSlot(), sim_time_string(), call CC2420Config.getChannel());
		signal Receive.receive(msg, payload, len);

	}

	/* For any packet reception */
	//added by sihoon
	// CCA event is triggered when a node receive any packet
  event void CCAevent.anypktreceive() {
		if(Rcv_check_mode == TRUE){
			//dbg("transmission","Rcv mode change to OFF\n");
			atomic Rcv_check_mode = FALSE;
		}
  }

	/* For Read RSSI */
	event void ReadRssi.readDone(error_t result, uint16_t val)
  {
    dbg("RSSI_TEST", "ReadRssi.readDone: %d\n", (int16_t)val-45);
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

    void set_current_hop_status(uint32_t slot_t, uint8_t sender, uint8_t receiver){
    	uint8_t i;

    }// end of set_current_hop_status

		// If it receives ack, then send_status = 1
		void set_send_status(uint8_t ack_at_send_done, uint8_t taskid){
			send_status[taskid] = ack_at_send_done;
		}

		void set_send (uint32_t slot_t){
			uint8_t i,j, link;
			uint32_t slot_norm = slot_t; //Here slot_norm is the real time slot normalized by superframe length
			TestNetworkMsg* tmp_payload;
			TestNetworkMsg* forwardPkt;
			uint8_t flowid;
			uint8_t curr_hopcount;
			uint8_t curr_hop_max_txopper;
			uint8_t curr_hop_delay;

			call CC2420Config.setChannel(CHANNEL_DEF);
			call CC2420Config.sync();

			/* Flow Root Tx */
			if(isFlowroot == TRUE){	// check flow root
				if(Tx_count[taskid] == 0 && Task_character[taskid][TASK_MAXTX] > 0){ // check first Tx
					//dbg("transmission", "check first TX\n");
					atomic Transmitting_flowid = taskid;

					if(slot_norm % (Task_character[Transmitting_flowid][TASK_PERIOD]) == 0 + Task_rels){ // check Tx slot
						tmp_payload = call SubSend.getPayload(&packet, sizeof(TestNetworkMsg));
						tmp_payload->flowid = taskid;
						tmp_payload->hopcount = 0;
						// Store Tx oppertunity for the routing link
						for(link=0; link<MAX_LINK_HOP; link++){
							tmp_payload->txopper[link] = Task_character[Transmitting_flowid][TASK_MAXTX];
							tmp_payload->txdelay[link] = 0;		//Tx delay setting
						}
						atomic Total_tx_count[Transmitting_flowid] = Total_tx_count[Transmitting_flowid] + 1;	// for counting Tx packets
						kth_job = kth_job + 1;	//for schedule ratio check
						tmp_payload->job_idx = kth_job;

						if(TOS_NODE_ID == 1){
							dbg_clear("check_link_quality","Nodeid: %d TxCount: %d\n", TOS_NODE_ID, Total_tx_count[1]);
						}
						/*
						if(TOS_NODE_ID == 2 && Total_tx_count[Transmitting_flowid] <= 1000){
							transmission(Transmitting_flowid);
						}
						if(TOS_NODE_ID == 1){
							transmission(Transmitting_flowid);
						}*/
						transmission(Transmitting_flowid);
					}
				}else if(Tx_count[taskid] != 0){ //check ReTx
					atomic Transmitting_flowid = taskid;
					if(slot_norm % (Task_character[Transmitting_flowid][TASK_PERIOD]) > 0 + Task_rels){ // check Tx slot

						if(Tx_count[Transmitting_flowid] < Task_character[Transmitting_flowid][TASK_MAXTX]){ // check maximum Tx oppertunity
							tmp_payload = call SubSend.getPayload(&packet, sizeof(TestNetworkMsg));
							tmp_payload->flowid = Transmitting_flowid;
							tmp_payload->hopcount = 0;
							// Store Tx oppertunity for the routing link
							for(link=0; link<MAX_LINK_HOP; link++){
								tmp_payload->txopper[link] = Task_character[Transmitting_flowid][TASK_MAXTX];
								tmp_payload->txdelay[link] = 0;		//Tx delay setting
							}
							tmp_payload->job_idx = kth_job;	//for schedule ratio check
							/*
							if(TOS_NODE_ID == 2 && check_link_quality_1<100){
								check_link_quality_1 = check_link_quality_1 + 1;
								dbg_clear("check_link_quality","%d %d\n", TOS_NODE_ID, check_link_quality_1);
								transmission(Transmitting_flowid);
							}*/
							transmission(Transmitting_flowid);
						}
					}
				}

			}else if(isFlowroot == FALSE && isFlowdest == FALSE){
				/* Relay Node Tx, but not destination node */
				// check receiving multi task packets
				if(!call HIforwardQ.empty() || !call LOforwardQ.empty()){
					if(TOS_NODE_ID == 4){
						//dbg("transmission","HIQ empty?:%d, LOQ empty?:%d\n", call HIforwardQ.empty(), call LOforwardQ.empty());
					}

					if(!call HIforwardQ.empty()){		// check HI Q empty
						forwardPkt = (TestNetworkMsg*)call HIforwardQ.head();
						//call HIforwardQ.dequeue();
						tmp_payload = call SubSend.getPayload(&packet, sizeof(TestNetworkMsg));
						atomic Transmitting_flowid = forwardPkt->flowid;
					}else if(!call LOforwardQ.empty()){		//check LO Q empty
						forwardPkt = (TestNetworkMsg*)call LOforwardQ.head();
						tmp_payload = call SubSend.getPayload(&packet, sizeof(TestNetworkMsg));
						atomic Transmitting_flowid = forwardPkt->flowid;

					}
					curr_hopcount = forwardPkt->hopcount + 1;
					curr_hop_delay = forwardPkt->txdelay[curr_hopcount];

					if(slot_norm > rcv_slot[Transmitting_flowid] + curr_hop_delay){ // check Tx slot
						if(Tx_count[Transmitting_flowid] < My_max_txopper[Transmitting_flowid]){	// check maximum Tx oppertunity
							tmp_payload->flowid = forwardPkt->flowid;
							tmp_payload->hopcount = curr_hopcount;
							for(link=0; link<MAX_LINK_HOP; link++){
								tmp_payload->txopper[link] = forwardPkt->txopper[link];
								tmp_payload->txdelay[link] = forwardPkt->txdelay[link];
							}
							tmp_payload->job_idx = forwardPkt->job_idx;	//for schedule ratio check
							transmission(Transmitting_flowid);	// set TxOffset
						}
					}
				}

			}
		}//end set_send


		void transmission( uint8_t Txing_flowid) {
			call AMPacket.setDestination(&packet, Path[Txing_flowid][PRIMARYPATH]);
			call PacketAcknowledgements.requestAck(&packet);
			call CC2420Config.setChannel(CHANNEL_DEF);
			call CC2420Config.setPower(RADIO_DEF_POWER);		//changed by sihoon
			call CC2420Config.sync();

			//call TossimPacketModelCCA.set_cca(schedule[i][4]); //schedule[i][4]: 0, TDMA; 1, CSMA contending; 2, CSMA steal;
			if(TOS_NODE_ID == 2){
				call Txdelay.start(32 * 3);
			}else if(TOS_NODE_ID == 3 && Txing_flowid == LO_TASK){
				Rcv_check_mode = TRUE;
				//dbg("transmission","Rcv mode on\n");
				call CCATxdelay.start(32 * 5);
			}else if(TOS_NODE_ID == 4 && Txing_flowid == LO_TASK){
				Rcv_check_mode = TRUE;
				//dbg("transmission","Rcv mode on\n");
				call CCATxdelay.start(32 * 5);
			}else if(TOS_NODE_ID == 5 && Txing_flowid == LO_TASK){
				Rcv_check_mode = TRUE;
				//dbg("transmission","Rcv mode on\n");
				call CCATxdelay.start(32 * 5);
			}else if(TOS_NODE_ID == 6 && Txing_flowid == LO_TASK){
				Rcv_check_mode = TRUE;
				//dbg("transmission","Rcv mode on\n");
				call CCATxdelay.start(32 * 5);
			}else{
				call Txdelay.start(32 * 0);
			}


		}

		/* Transmit pkt after TxOffset */
		async event void Txdelay.fired() {
			uint32_t current_slot;

			current_slot = call SlotterControl.getSlot() % superframe_length;
			if( call SubSend.send(&packet, sizeof(TestNetworkMsg)) == SUCCESS) {
				atomic Tx_count[Transmitting_flowid] = Tx_count[Transmitting_flowid] + 1;
				dbg("transmission","Tx_count[%d]:%d at slot %d\n",Transmitting_flowid, Tx_count[Transmitting_flowid], current_slot);
			}else {}

			if(TOS_NODE_ID == 1 || TOS_NODE_ID == 2){
				//Nodeid, Total_tx_count
				//dbg_clear("E2E_delay_Log_data","%d %d\n", TOS_NODE_ID, Total_tx_count[Transmitting_flowid]);
			}

		}

		/* For checking pkt reception at TxOffset interval */
		async event void CCATxdelay.fired() {
			uint32_t current_slot;

			if(Rcv_check_mode == TRUE){
				current_slot = call SlotterControl.getSlot() % superframe_length;
				if( call SubSend.send(&packet, sizeof(TestNetworkMsg)) == SUCCESS) {
					atomic Rcv_check_mode = FALSE;
					atomic Tx_count[Transmitting_flowid] = Tx_count[Transmitting_flowid] + 1;
					dbg("transmission","Tx_count[%d]:%d at slot %d\n",Transmitting_flowid, Tx_count[Transmitting_flowid], current_slot);

				}else {}
			}
		}


		uint32_t SuperframeLength(uint32_t Task_set[][3]){
			uint8_t i;
			uint32_t prv_task_period;

			prv_task_period = 1;

			for(i=1; i<NUM_TASK+1; i++){
				prv_task_period = getLCD(Task_set[i][TASK_PERIOD], prv_task_period);
			}
			return prv_task_period;
		}

		uint32_t getGCD(uint32_t num1, uint32_t num2){
			uint8_t i;
			uint32_t gcd;

			if(num1 == 0 || num2 == 0){
				return 0;
			}

			if(num1 < num2){
				return getGCD(num2, num1);
			}else if(num1%num2 == 0){
				return num2;
			}else{
				return getGCD(num2, num1%num2);
			}
		}

		uint32_t getLCD(uint32_t num1, uint32_t num2){

			if(num1 == 0 || num2 == 0){
				return 0;
			}

			return (num1*num2)/getGCD(num1, num2);
		}

		void printfFloat(float toBePrinted) {
			uint32_t fi, f0, f1, f2;
			char c;
			float f = toBePrinted;

			if (f<0){
				c = '-'; f = -f;
			} else {
				c = ' ';
			}

			// integer portion.
			fi = (uint32_t) f;

			// decimal portion...get index for up to 3 decimal places.
			f = f - ((float) fi);
			f0 = f*10;   f0 %= 10;
			f1 = f*100;  f1 %= 10;
			f2 = f*1000; f2 %= 10;
			printf("%c%ld.%d%d%d", c, fi, (uint8_t) f0, (uint8_t) f1, (uint8_t) f2);
		}


}
