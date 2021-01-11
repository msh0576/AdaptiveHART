// $Id: OctopusC.nc,v 1.6 2008/03/13 14:16:37 a_barbirato Exp $

/*									tab:4
 * Copyright (c) 2007 University College Dublin.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL UNIVERSITY COLLEGE DUBLIN BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF 
 * UNIVERSITY COLLEGE DUBLIN HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * UNIVERSITY COLLEGE DUBLIN SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND UNIVERSITY COLLEGE DUBLIN HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Raja Jurdak, Antonio Ruzzelli, Samuel Boivineau and Alessio Barbirato
 * Date created: 2007/09/07
 *
 */

/**
 * @author Raja Jurdak, Antonio Ruzzelli, Samuel Boivineau and Alessio Barbirato
 */


#include "Octopus.h"
/*
	TODO :	
			Battery support
			Leds support
			Add a summary
	BUG :

*/

module OctopusC {
  uses {
    // Interfaces for initialization:
    interface Boot;
	//interface NetProg;
	//interface InternalFlash;
    interface SplitControl as RadioControl;
    interface SplitControl as SerialControl;

#ifndef TOSSIM	
	// Interface for radio
	interface LowPowerListening;
#endif
	
	// Interface for broadcast of data
	interface StdControl as BroadcastControl; 	// Control of the protocol (replace DisseminationControl)
#if defined(DISSEMINATION_PROTOCOL)
	interface DisseminationUpdate<octopus_sent_msg_t>  			// for the root
		as RequestUpdate;
	interface DisseminationValue<octopus_sent_msg_t> 			// for the motes
		as RequestValue;
#elif defined(DUMMY_BROADCAST_PROTOCOL)
	interface DummyBroadcast;
#else
#error "A protocol needs to be selected to broadcast data"
#endif
	
	// Interface for collect data
    interface Send as CollectSend;				// used by a node which want to send data to the root
    interface Receive as Snoop;					// used when we have to forward data
    interface Receive as CollectReceive;		// used for reception of data collected by the root of the network
	interface RootControl;						// used to specify which one of the mote is the root
	interface StdControl as CollectControl;		// used to start the service protocol
#if defined(COLLECTION_PROTOCOL)
    interface CtpInfo as CollectInfo;			// specific to the ctp protocol, used to get some data (parent and quality here)
#elif defined(DUMMY_COLLECT_PROTOCOL)
	interface DummyInfo as CollectInfo;			// specific to dummy protocol, used to get some data
#else
#error "A protocol needs to be selected to collect data"
#endif
	
	// Interface for serial :
	interface AMSend as SerialSend;
	interface Receive as SerialReceive;
	
    // Miscalleny:
    interface Timer<TMilli>;
	interface Timer<TMilli> as WaitTimer;
    interface Read<uint32_t>; // sensor
    interface Leds;
    interface Random;
  }
}
implementation {
	/*
		Variables
	*/
	
	octopus_collected_msg_t localCollectedMsg;
	message_t fwdMsg;
	message_t sndMsg, serialMsg;
	bool fwdBusy, sendBusy, uartBusy;
	uint16_t samplingPeriod = DEFAULT_SAMPLING_PERIOD;
	uint16_t waitT;
	uint16_t vet[100];
	uint16_t array[100];
	uint16_t counter = 0;
	uint8_t counter2 = 0;
	uint16_t count = 0;
	//uint16_t flag;
	uint16_t nodes = 0;
	uint16_t alpha = 40;
	uint16_t max_num_nodes = 30;
        nx_am_addr_t ttt_optimized_out;
	nx_am_addr_t ttt;
	uint16_t threshold;
	bool modeAuto, sleeping, root=FALSE;
	uint16_t battery, sleepDutyCycle, awakeDutyCycle;
	uint16_t oldSensorValue=0;
	
	// Use LEDs to report various status issues.
	static void fatalProblem() { 
		call Leds.led0On(); 
		call Leds.led1On();
		call Leds.led2On();
		call Timer.stop();
	}
	static void reportProblem() { call Leds.led0Toggle(); } // if there is any problem
	static void reportSent() { call Leds.led1Toggle(); } // when a message is sent
	static void reportReceived() {call Leds.led2Toggle();} // when a message is received
	void processRequest(octopus_sent_msg_t *newRequest);
	task void collectSendTask();
	task void serialSendTask();
	void fillPacket();
	void setLocalDutyCycle();
	
	/*
		On bootup, we initialize the radio, serial, 
		and all the communication protocols used.
		We also initialize the packet (to update)
	*/
	event void Boot.booted() {
          // variables must be assigned to or they will be
          // optimized out by the nesC compiler.
          ttt = 0;
		localCollectedMsg.moteId = TOS_NODE_ID;
		localCollectedMsg.reply = NO_REPLY;

		threshold = DEFAULT_THRESHOLD;
		modeAuto = DEFAULT_MODE;
		sleeping = FALSE;
		sleepDutyCycle = DEFAULT_SLEEP_DUTY_CYCLE;
		awakeDutyCycle = DEFAULT_AWAKE_DUTY_CYCLE;
		sendBusy = FALSE;
		uartBusy = FALSE;
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();
		samplingPeriod = DEFAULT_SAMPLING_PERIOD;
		if (call RadioControl.start() != SUCCESS)
			fatalProblem();
		if (TOS_NODE_ID == 0) {	// if we are the root, we have to use the serial port
			root = TRUE;
			if (call SerialControl.start() != SUCCESS)
				fatalProblem();
		}
		// battery = getBatteryValue(); ???
	}
	event void RadioControl.startDone(error_t error) {
		if (error == SUCCESS) {
			if (call CollectControl.start() != SUCCESS)
				fatalProblem();
			if (root)
				call RootControl.setRoot();
			if (call BroadcastControl.start() != SUCCESS)
				fatalProblem();
			setLocalDutyCycle();
			samplingPeriod = DEFAULT_SAMPLING_PERIOD;
			call Timer.startPeriodic(samplingPeriod);
		} else
			fatalProblem();
	}
	event void RadioControl.stopDone(error_t error) { }
	event void SerialControl.startDone(error_t error) { 
  		if (error != SUCCESS)
			fatalProblem();
	}
	event void SerialControl.stopDone(error_t error) { }

	/*
		Each request is processed by this function
	*/
	
	void processRequest(octopus_sent_msg_t

 *newRequest) {
		if (newRequest->targetId == TOS_NODE_ID || newRequest->targetId == 0xFFFF) {
			//int aaa=counter;
			switch(newRequest->request) {
			case SET_MODE_AUTO_REQUEST:
				modeAuto = TRUE;
				call Timer.stop();
				waitT = (1+TOS_NODE_ID%MAX_NUM_NODES)*alpha;		
				call WaitTimer.startOneShot(waitT);
				break;
			case SET_MODE_QUERY_REQUEST:
				modeAuto = FALSE;
				call Timer.stop();
				break;
			case SET_PERIOD_REQUEST:
				samplingPeriod = newRequest->parameters;
				call Timer.stop();
				alpha = samplingPeriod/(max_num_nodes+1);
				waitT = (1+TOS_NODE_ID)*alpha;
				
				if(sleeping == FALSE)
					call WaitTimer.startOneShot(waitT);   
				break;
			case SET_THRESHOLD_REQUEST:
				threshold = newRequest->parameters;
				break;
			case GET_STATUS_REQUEST:		// we send the battery value and the current mode
				if(modeAuto)
					localCollectedMsg.reply = BATTERY_AND_MODE_REPLY | MODE_AUTO;
				else
					localCollectedMsg.reply = BATTERY_AND_MODE_REPLY | MODE_QUERY;
				if (sleeping)
					localCollectedMsg.reply |= SLEEPING;
				else
					localCollectedMsg.reply |= AWAKE;
				localCollectedMsg.reading = battery;
				fillPacket();
				SEND_TASK
				break;
			case GET_PERIOD_REQUEST:		// we send the period value
				if(sleeping == FALSE) {
					localCollectedMsg.reply = PERIOD_REPLY;
					localCollectedMsg.reading = samplingPeriod;
					fillPacket();
					SEND_TASK
				}
				break;
			case GET_THRESHOLD_REQUEST:		// we send the threshold value
				if(sleeping == FALSE) {
					localCollectedMsg.reply = THRESHOLD_REPLY;
					localCollectedMsg.reading = threshold;
					fillPacket();
					SEND_TASK
				}
				break;
			case GET_READING_REQUEST:		// we send the sensor value (request-driven mode)
				call Read.read();
				break;
			case SLEEP_REQUEST:
				if(!root) {					// the gateway do NOT sleep
					sleeping = TRUE;
					setLocalDutyCycle();
					call Timer.stop();
				}
				break;
			case WAKE_UP_REQUEST:
				if(!root) {					// the gateway do NOT sleep
					sleeping = FALSE;
					setLocalDutyCycle();
					if (modeAuto)
						call Timer.startPeriodic(samplingPeriod);
				}
				break;
			case GET_SLEEP_DUTY_CYCLE_REQUEST:
				localCollectedMsg.reply = SLEEP_DUTY_CYCLE_REPLY;
				localCollectedMsg.reading = sleepDutyCycle;
				fillPacket();
				SEND_TASK
				break;
			case SET_SLEEP_DUTY_CYCLE_REQUEST:
				sleepDutyCycle = newRequest->parameters;
				setLocalDutyCycle();
				break;
			case SET_AWAKE_DUTY_CYCLE_REQUEST:
				awakeDutyCycle = newRequest->parameters;

				setLocalDutyCycle();
				break;
			case GET_AWAKE_DUTY_CYCLE_REQUEST:
				localCollectedMsg.reply = AWAKE_DUTY_CYCLE_REPLY;
				localCollectedMsg.reading = awakeDutyCycle;
				fillPacket();
				SEND_TASK
				break;
			case BOOT_REQUEST:
				//call NetProg.reboot();
				break;
			case MAX_ID:
				max_num_nodes = newRequest->parameters;
				if(max_num_nodes == 36){
					call Leds.led0On();
					call Leds.led2Off();
					call Leds.led1Off();
				}
				else if(max_num_nodes == 37){
					call Leds.led0Off();
					call Leds.led2On();
					call Leds.led1Off();
				}
				else if(max_num_nodes == 38){
					call Leds.led0On();
					call Leds.led2On();
					call Leds.led1Off();
				}/*
				else if(idRec == 3){
					call Leds.led0Off();
					call Leds.led2On();
					call Leds.led1Off();
				}
				else if(nodes == 5){
					call Leds.led0On();
					call Leds.led2On();
					call Leds.led1Off();
				}
				else if(nodes == 6){
					call Leds.led0Off();
					call Leds.led2On();
					call Leds.led1On();
				}
				else if(nodes == 7){
					call Leds.led0On();
					call Leds.led2On();
					call Leds.led1On();
				}
				else if(nodes == 8){
					call Leds.led0Toggle();
					call Leds.led2Off();
					call Leds.led1Off();
				}
				else if(nodes == 9){
					call Leds.led0Off();
					call Leds.led2Off();
					call Leds.led1Toggle();
				}
				else if(nodes == 10){
					call Leds.led0Toggle();
					call Leds.led2Off();
					call Leds.led1Toggle();
				}
				else if(nodes == 11){
					call Leds.led0Off();
					call Leds.led2Toggle();
					call Leds.led1Off();
				}
				else if(nodes == 12){
					call Leds.led0Toggle();
					call Leds.led2Toggle();
					call Leds.led1Off();
				}*/
				//alpha = samplingPeriod/(2+nodes);
				break;
			}
		}
	}

	/* 
		GATEWAY : When we receive a request from the serial port, 
		we broadcast it by calling the change command and next we
		execute it.
	*/
	
	event message_t *SerialReceive.receive(message_t* msg, void* payload, uint8_t len) {
		octopus_sent_msg_t *newRequest = payload;
		if (len == sizeof(octopus_sent_msg_t)) {
#if defined(DISSEMINATION_PROTOCOL)
			call RequestUpdate.change(newRequest);
#elif defined(DUMMY_BROADCAST_PROTOCOL)
			call DummyBroadcast.send(newRequest);
#endif
			processRequest(newRequest); // add an option GATEWAY_SENSING_ENV
		}
		return msg;
	}
	
	task void collectSendTask() {
		if (!sendBusy && !root) {
                  octopus_collected_msg_t *o = call CollectSend.getPayload(&sndMsg, sizeof(octopus_collected_msg_t));
                    
			memmove(o, &localCollectedMsg, sizeof(octopus_collected_msg_t));
			if (call CollectSend.send(&sndMsg, sizeof(octopus_collected_msg_t)) == SUCCESS)
				sendBusy = TRUE;
			else
				reportProblem();
	    }
	}
	
	task void serialSendTask() {
          if (!uartBusy && root) {
            octopus_collected_msg_t * o = (octopus_collected_msg_t *)call SerialSend.getPayload(&sndMsg, sizeof(octopus_collected_msg_t));
            memcpy(o, &localCollectedMsg, sizeof(octopus_collected_msg_t));
			if (call SerialSend.send(0xffff, &sndMsg, sizeof(octopus_collected_msg_t)) == SUCCESS)
				uartBusy = TRUE;
			else
				reportProblem();
		}
	}
	
	event void CollectSend.sendDone(message_t* msg, error_t error) {
		if (error != SUCCESS)
			reportProblem();
		sendBusy = FALSE;
		localCollectedMsg.reply = NO_REPLY;
		reportSent();
	}
	
	event void SerialSend.sendDone(message_t *msg, error_t error) {
		if (error != SUCCESS)
			reportProblem();
		if (msg == &fwdMsg)
			fwdBusy = FALSE;
		else
			uartBusy = FALSE;
		localCollectedMsg.reply = NO_REPLY;
		reportSent();
	}
	
	/*
		The quality of the link with the parent and the parent Id
		are filled here.
	*/
	
	void fillPacket() {
		uint16_t tmp;
#if defined(COLLECTION_PROTOCOL)
		call CollectInfo.getEtx(&tmp);
#elif defined(DUMMY_COLLECT_PROTOCOL)
		call CollectInfo.getQuality(&tmp);
#endif
		localCollectedMsg.quality = tmp;
		call CollectInfo.getParent(&tmp);
		localCollectedMsg.parentId = tmp;
	}
	

	/*
		NODE : When we receive a request from the serial port,
		we execute it.
	*/
	
#if defined(DISSEMINATION_PROTOCOL)
	event void RequestValue.changed() {
		octopus_sent_msg_t *newRequest = (octopus_sent_msg_t *)call RequestValue.get();
#elif defined(DUMMY_BROADCAST_PROTOCOL)
	event void BrodcastReceive.received() {
		octopus_sent_msg_t *newRequest = (octopus_sent_msg_t *)call BroadcastReceive.get();
#endif
		processRequest(newRequest);
	}

	event void Timer.fired() {
		if (!sleeping && modeAuto) // Reading of the sensor in timer-driven mode
			call Read.read();
	}
	event void WaitTimer.fired() {
		call Timer.startPeriodic(samplingPeriod); 
	}
	/*
		Once the sensor is read, the value is computed to check if it's
		out of the range of the threshold, if so the value is sent.
	*/
	
	event void Read.readDone(error_t ok, uint32_t val) {
		if (ok == SUCCESS ) {
			localCollectedMsg.count++;
			fillPacket();
			if(!modeAuto) {	// request-driven mode (no threshold)
				localCollectedMsg.reading = val;
				if(!root)
					post collectSendTask();
				else
					post serialSendTask();
			} else if ((val>oldSensorValue) && !(0xFFFF-oldSensorValue<threshold)){ // we avoid the overflow
				if(oldSensorValue+threshold < val) { 	// if the threshold is exceeded
					localCollectedMsg.reading = val;
					if(!root)					// then we send the value
						post collectSendTask();
					else
						post serialSendTask();
				}
			} else if ((val<oldSensorValue) && !(oldSensorValue<threshold)){ // we avoid the overflow
				if(oldSensorValue-threshold > val) { 	// if the threshold is exceeded
					localCollectedMsg.reading = val;
					if(!root)					// then we send the value
						post collectSendTask();
					else
						post serialSendTask();
				}
			}
		}
	}
	
	/*
		GATEWAY : When we receive a collected message,
		we forward it to the PC via the serial port 
		! we assume the protocol used implements an interface called 
		! receive for the reception of frames by the gateway
	*/

	event message_t *CollectReceive.receive(message_t* msg, void* payload, uint8_t len) {
		octopus_collected_msg_t *collectedMsg = payload;
		
		/*PROBLEM WITH THE id MOTE*************************************************
		Using the sequent function the Id mote is not recognised anyomre in Octopus.
		Maybe there is a conflict between Java code and nesC code
		***************************************************************************/
		
		/*octopus_collected_msg_t test = *collectedMsg;
		octopus_sent_msg_t *newR;
		uint16_t a;
		uint16_t flag=0;

		t = test.moteId;

		newR->targetId = 0xFFFF;
		newR->request = SET_NUM_NODES_REQUEST;

		for(a=0;a<counter;a++){
			if(vet[a]==t)
				flag = 1;					
		}
		if(flag == 0){
			
			vet[counter]=t;
				counter++;
			for(a=0;a<counter;a++){
				newR->parameters = counter;
			#if defined(DISSEMINATION_PROTOCOL)
				call RequestUpdate.change(newR);
			#elif defined(DUMMY_BROADCAST_PROTOCOL)
				call DummyBroadcast.send(newR);
			#endif
				processRequest(newR); // add an option GATEWAY_SENSING_ENV
			}
        }*/
		if (len == sizeof(octopus_collected_msg_t) && !fwdBusy) {
			/* Copy payload (collectedMsg) from collection system to our serial
			   message buffer (fwdCollectedMsg), then send our serial message */
                  octopus_collected_msg_t *fwdCollectedMsg = call SerialSend.getPayload(&fwdMsg, sizeof(octopus_collected_msg_t));
			
			*fwdCollectedMsg = *collectedMsg;
			if (call SerialSend.send(AM_BROADCAST_ADDR, &fwdMsg, sizeof(*collectedMsg)) == SUCCESS)
				fwdBusy = TRUE;
			reportReceived();
		}
		return msg;
	}

	/*
		Function called when a message is forwarded to the gateway.
	*/
	
	event message_t* Snoop.receive(message_t* msg, void* payload, uint8_t len) {
		return msg;
	}
	
	void setLocalDutyCycle() {
          if (sleeping) {
#ifndef TOSSIM
			call LowPowerListening.setLocalDutyCycle(sleepDutyCycle);
#endif
          }else{
				if(awakeDutyCycle>5000){	
					/*call Leds.led2On();
					call Leds.led0Off();*/
				}
				else{	
					//call Leds.led0On();
					//call Leds.led2Off();
				}
#ifndef TOSSIM
				call LowPowerListening.setLocalDutyCycle(awakeDutyCycle);
#endif
		}	
	}
}
