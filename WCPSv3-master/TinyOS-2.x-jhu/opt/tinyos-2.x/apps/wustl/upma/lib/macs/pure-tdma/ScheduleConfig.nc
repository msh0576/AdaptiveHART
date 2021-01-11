
interface ScheduleConfig {

  async command uint8_t primaryNode(uint8_t flowid, uint8_t nodeid);

  async command uint8_t backupNode(uint8_t flowid, uint8_t nodeid);

  async command uint8_t criticality(uint8_t flowid);

  async command bool flowsource(uint8_t nodeid);

  async command bool flowdestination(uint8_t nodeid);

  async command uint8_t taskid(uint8_t flowroot);

  async command void VCS();


}
