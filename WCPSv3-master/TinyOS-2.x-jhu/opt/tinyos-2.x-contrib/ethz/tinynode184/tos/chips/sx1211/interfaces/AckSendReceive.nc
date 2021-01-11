interface AckSendReceive {
    command void setAckPayload(uint16_t _pl);
    command uint16_t getAckPayload();
    command void enableAck();
    command void disableAck();
}
