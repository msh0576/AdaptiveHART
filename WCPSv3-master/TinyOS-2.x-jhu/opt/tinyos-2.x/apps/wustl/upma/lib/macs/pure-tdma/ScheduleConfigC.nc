

module ScheduleConfigC {
  provides {
    interface ScheduleConfig;
  }
}
implementation {

  uint8_t Primarypath[NETWORK_FLOW][NETWORK_NODE] ={
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 3, 0, 4, 5, 6, 51, 0},
    {0, 0, 3, 4, 5, 6, 52, 0}
  };

  uint8_t Backuppath[NETWORK_FLOW][NETWORK_NODE] ={
    /*
    {0, 0, 0, 0, 0},
    {0, 4, 0, 4, 51},
    {0, 0, 3, 52, 3}
    */
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 3, 0, 5, 51, 7, 0, 51},
    {0, 0, 3, 52, 3, 0, 0, 0}
  };

  uint8_t flow_destination[NETWORK_FLOW] = {0, 51, 52};
  uint8_t flow_source[NETWORK_FLOW] = {0, 1, 2};

  /*
  * the index of flow_criticality[] indicate flow id
  * the value of each index means flow criticality`
  * 1: Hi-criti,  2:Lo-criti
  */
  uint8_t flow_criticality[NETWORK_FLOW]={0, 1, 0};

  /*
  * We should change the index of the backup_topology, when we change the network topology
  * 0: No-backup node,  N: backup nodeid is N
  */
  uint8_t backup_topology[NETWORK_NODE]={0, 52, 51};



  async command uint8_t ScheduleConfig.primaryNode(uint8_t flowid, uint8_t nodeid) {
    if(nodeid > NETWORK_NODE || nodeid < 0) {  //check whether nodeid is bounded in NETWORK_NODE
      return 0;
    }else {
      return Primarypath[flowid][nodeid];
    }
  }

  async command uint8_t ScheduleConfig.backupNode(uint8_t flowid, uint8_t nodeid) {
    if(nodeid > NETWORK_NODE || nodeid < 0) {  //check whether nodeid is bounded in NETWORK_NODE
      return 0;
    }else {
      //return backup_topology[nodeid];
      return Backuppath[flowid][nodeid];
    }
  }

  async command uint8_t ScheduleConfig.criticality(uint8_t flowid) {
    if(flowid > NETWORK_FLOW || flowid < 0) { //check flowid is bounded
      return 0;
    }else {
      return flow_criticality[flowid];
    }
  }

  async command bool ScheduleConfig.flowsource(uint8_t nodeid) {
    uint8_t i;
    for(i=0; i<NETWORK_FLOW; i++){
      if(flow_source[i] == nodeid){
        return TRUE;
      }
    }
    return FALSE;
  }

  async command bool ScheduleConfig.flowdestination(uint8_t nodeid) {
    uint8_t i;
    for(i=0; i<NETWORK_FLOW; i++){
      if(flow_destination[i] == nodeid){
        return TRUE;
      }
    }
    return FALSE;
  }

  async command uint8_t ScheduleConfig.taskid(uint8_t flowroot) {
    uint8_t i;
    for(i=0; i<NETWORK_FLOW; i++){
      if(flow_source[i] == flowroot){
        return i;
      }
    }
  }

  async command void ScheduleConfig.VCS(){

  }

  /* Define a Source path */
  //a source path of node i for flow k
  void SourcePath(uint8_t flowid, uint8_t nodeid){
    uint8_t *sourcepath;

    Primarypath[flowid][nodeid];
  }


}
