/* Copyright (c) 2007, Tor Petterson <motor@diku.dk>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *  - Neither the name of the University of Copenhagen nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Tor Petterson <motor@diku.dk>
*/

generic module Hcs08SerialByteCommP()
{
  provides interface StdControl;
  provides interface SerialByteComm;
  
  uses interface HplHcs08Uart as HplUart;
  uses interface McuPowerState;
}

implementation
{
  bool busy = FALSE;

  command error_t StdControl.start(){
  	call HplUart.setBaudrate(PLATFORM_BAUDRATE);
    call HplUart.enable();
    call HplUart.enableRxIntr();
    call McuPowerState.update();
    return SUCCESS;
  }

  command error_t StdControl.stop(){
    call HplUart.disable();
    call HplUart.disableRxIntr();
    call McuPowerState.update();
    return SUCCESS;
  }
  
    async command error_t SerialByteComm.put( uint8_t data)
    {
      bool tmp;
      atomic{
      	tmp = busy;
      	busy = TRUE;
     }
    
    if(tmp)
      return EBUSY;
      
    call HplUart.tx(data);
    call HplUart.enableTxIntr();
    
    return SUCCESS;
  }
  
  async event void HplUart.txDone() 
  {
  	atomic
  	{
  	  busy = FALSE;
  	}
    signal SerialByteComm.putDone();
  }
  
  async event void HplUart.rxDone( uint8_t data )
  {
    signal SerialByteComm.get(data);  
  }
  
  async event void HplUart.txComplete()
  {
  	return;
  }
}