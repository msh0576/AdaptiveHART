/* Copyright (c) 2009, Distributed Computing Group (DCG), ETH Zurich.
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without
*  modification, are permitted provided that the following conditions
*  are met:
*
*  1. Redistributions of source code must retain the above copyright
*     notice, this list of conditions and the following disclaimer.
*  2. Redistributions in binary form must reproduce the above copyright
*     notice, this list of conditions and the following disclaimer in the
*     documentation and/or other materials provided with the distribution.
*  3. Neither the name of the copyright holders nor the names of
*     contributors may be used to endorse or promote products derived
*     from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
*
*  @author Lars Schor <lschor@ee.ethz.ch>
* 
*/

// REST includes
#include "Rest.h"

module sensorTemperatureP{
	uses {
		interface Json;
		interface Rest; 
		interface Boot;
	
		interface Timer<TMilli>  as SensingTimer;;
    	interface Read<uint16_t>  as Sensor;
    } 
}
implementation{
	
	/************* Variables ***********/
	
	uint16_t sensValue; 
	
	/************* Boot ****************/
	event void Boot.booted(){
		call Rest.bind("sensor/temperature"); 
		
		call SensingTimer.startPeriodic(1000);
	}
	
	/**
	 * Generates the Element-Response
	 */
	void getSingleValue(char *buf, char *element, uint16_t len){		
		double celcisu = ((float)sensValue) * 0.03125 / 4; 
		uint16_t bufLen = 0;
		uint8_t methodList[] = {JSON_METH_GET}; 
		
		call Json.createElement(buf, "Temperature");
		call Json.addMethod(buf,methodList , 1);
		call Json.addParamInt(buf, "value", sensValue, "i", 0, 1);
		call Json.addParamInt(buf, "celcius", (int)celcisu, "i", 0, 0); 
		 
		bufLen = call Json.finishElement(buf); 
		call Rest.sendData(buf, bufLen); 
	}
	
	/**
	 * Generates the Collection-Response
	 */
	void getCollection(char *collection){
		uint16_t len; 
		
		// Add all elements one have and send them as resources
		call Json.createCollection(collection, "res"); 
		call Json.addToCollection(collection, "singleValue", 1); 
		
		len = call Json.finishCollection(collection);
		call Rest.sendData(collection, len);
	}

	/************ REST *****************/
	event void Rest.getReceived(char *elementName, uint16_t len, char* buf){
		
		// Get the request for the collection
		if (strncmp(elementName, "*", 1) == 0)
		{
			getCollection(buf);
		}
		// Get the request for an element
		else
		{
			if (strcmp(elementName, "singleValue") == 0)
				getSingleValue(buf, elementName, len); 
			else
				call Rest.sendControl(REST_NOT_IMPL); 
		}
	}

	event void Rest.putReceived(char *element, uint16_t len, char *param_name, char *param_value){
	}

	event void Rest.deleteReceived(char *elementName, uint16_t len){
	}
	
	
	/************ SensingTimer **********/
	event void SensingTimer.fired(){
		call Sensor.read();
	}

	/*********** Sensor *****************/
	event void Sensor.readDone(error_t result, uint16_t val){
		sensValue = val; 
	}
}
