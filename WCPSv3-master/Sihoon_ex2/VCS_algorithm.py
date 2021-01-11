#!/usr/bin/env python
import copy


# Primary Conflict
# Input: nodeid, E
# Output: edge set that impose primary conflict
def Primary_conflict(Edge_set, nodeid, primary_path):
    SC3_set = []
    RC3_set = []
    tmp_Edge_set = Edge_set[:]
    length = len(tmp_Edge_set)

    for edge in tmp_Edge_set:
        rev_edge = list(reversed(edge))
        # SC3
        if primary_path == edge[0] and nodeid != edge[1]:
            SC3_set.append(edge)
        elif primary_path == rev_edge[0] and nodeid != rev_edge[1]:
            SC3_set.append(rev_edge)

        # RC3
        if primary_path != edge[0] and nodeid == edge[1]:
            RC3_set.append(edge)
        elif primary_path != rev_edge[0] and nodeid == rev_edge[1]:
            RC3_set.append(rev_edge)

    return SC3_set, RC3_set

# Secondary Conflict
# Input: virtual schedule edge
# Output: available edge set that can impose secondary conflict with the virtual scheduel edge
def Secondary_conflict(Edge_set, nodeid, primary_path):
    secondary_conflict_set = []
    RC1_set = []
    RC2_set = []
    SC2_set = []
    tmp_Edge_set = Edge_set[:]
    length = len(tmp_Edge_set)

    one_away_link_set = One_away_link(Edge_set, nodeid, primary_path)
    #print("one_away_link_set of [%s,%s]: %s" %(nodeid, primary_path, one_away_link_set))

    for edge in tmp_Edge_set:
        rev_edge = list(reversed(edge))
        # Conflict type: RC2
        if nodeid != edge[0] and primary_path == edge[1]:
            RC2_set.append(edge)
        elif nodeid != rev_edge[0] and primary_path == rev_edge[1]:
            RC2_set.append(rev_edge)

        # Conflict type: RC1
        for one_away_link in one_away_link_set[0]:
            if edge[1] == one_away_link[0] and edge[0] != one_away_link[1]:
                RC1_set.append(edge)
            elif rev_edge[1] == one_away_link[0] and rev_edge[0] != one_away_link[1]:
                RC1_set.append(rev_edge)

        # Conflict type: SC2
        for one_away_link in one_away_link_set[1]:
            if edge[1] != one_away_link[0] and edge[0] == one_away_link[1]:
                SC2_set.append(edge)
            elif rev_edge[1] != one_away_link[0] and rev_edge[0] == one_away_link[1]:
                SC2_set.append(rev_edge)


    for edge in RC1_set:
        if primary_path == edge[0]:
            RC1_set.remove(edge)

    for edge in SC2_set:
        if nodeid == edge[1]:
            SC2_set.remove(edge)

    # Test one_away_link_set & RC1,SC2
    #print("SC one_away_link of virtual link[%s,%s]: %s"%(nodeid, primary_path, one_away_link_set[0]))
    #print("RC1_set of virtual link[%s,%s]: %s"%(nodeid, primary_path, RC1_set))
    #print("RC one_away_link of virtual link[%s,%s]: %s"%(nodeid, primary_path, one_away_link_set[1]))
    #print("SC2_set of virtual link[%s,%s]: %s"%(nodeid, primary_path, SC2_set))

    return RC1_set, RC2_set, SC2_set

# One hop away link set
def One_away_link(Edge_set, edge_source, edge_destination):
    one_away_link_set_SC = []
    one_away_link_set_RC = []
    tmp_Edge_set = Edge_set[:]

    for edge in tmp_Edge_set:
        rev_edge = list(reversed(edge))

        # Find sender-centric one-hop away of a virtual schedule link, which will be used for RC1
        if (edge_source == edge[1] and edge_destination != edge[0]):
            one_away_link_set_SC.append(edge)
        elif (edge_source == rev_edge[1] and edge_destination != rev_edge[0]):
            one_away_link_set_SC.append(rev_edge)

        # Find receiver-centric one-hop away of a virtual schedule link, which will be used for SC2
        if (edge_source != edge[1] and edge_destination == edge[0]):
            one_away_link_set_RC.append(edge)
        elif (edge_source != rev_edge[1] and edge_destination == rev_edge[0]):
            one_away_link_set_RC.append(rev_edge)


    return one_away_link_set_SC, one_away_link_set_RC

# a source path from each node to flow destination
def Source_path(flowid, nodeid, path, losscount = 0):
    # Error check
    if nodeid == flow_destination[flowid]:
        return

    mydesti = Primary_path[flowid][nodeid]
    if losscount >= 2:
        mydesti = Backup_path[flowid][nodeid]
        if Backup_path[flowid][nodeid] == 0:    # there is no backup path
            mydesti = Primary_path[flowid][nodeid]
            print("No backup path")
    path.append(mydesti)

    if mydesti == flow_destination[flowid]:
        return
    Source_path(flowid, mydesti, path)

# Primary path scheduling of all flows, which do not consider secondary conflict
# Output: Schedule: {timeslot: [source, destination, flowid], ...}
def Basic_Scheduler(sourcepath_set_input):
    tmp_sourcepath_set = sourcepath_set_input
    sorted_res = sorted(sourcepath_set_input)
    timeslot = 0
    Scheduled_Edge = {}
    Schedule = {}

    # Define Superframe length
    for i in range(Superframe_len):
        Scheduled_Edge['slot_%s'%(i)] = []
        Schedule[i] = []

    for eg in sorted_res:           # Does not consider the order of flow criticality
        pre_offset = 0
        current_flowid = int(eg[len(eg)-1:])
        #print(current_flowid, type(current_flowid))
        node_offset = 0
        while True:
            conflict_flag = False
            timeslot = pre_offset + 1
            end = node_offset + 2

            # set current edge
            current_node = tmp_sourcepath_set[eg][node_offset]
            if current_node == flow_destination[current_flowid]:
                break

            current_edge = []
            current_edge.append(current_node)
            current_edge.append(Primary_path[current_flowid][current_node])
            #print("current_edge:%s"%(current_edge))


            # Primary conflict check
            if len(Scheduled_Edge['slot_%s'%(timeslot)]) == 0:
                pass
            else:
                for sche_edge in Scheduled_Edge['slot_%s'%(timeslot)]:
                    primary_conflict_set = []
                    primary_conflict_set = Primary_conflict(Edge, sche_edge[0], sche_edge[1])
                    #print('primary_conflict_set:%s'%(primary_conflict_set))

                    if current_edge in primary_conflict_set:
                        #print('Link:%s -- primary conflict with %s' %(current_edge, sche_edge))
                        conflict_flag = True

                    # Check simultaneous Tx
                    if current_edge[0] == sche_edge[0]:
                        #print('Link:%s -- simultaneous Tx with %s' %(current_edge, sche_edge))
                        conflict_flag = True
            # Schedule current edge
            if conflict_flag == False:
                sche_info = []
                Scheduled_Edge['slot_%s'%(timeslot)].append(current_edge)
                sche_info = current_edge[:]     # Copy
                sche_info.append(current_flowid)
                Schedule[timeslot].append(sche_info)
                pre_offset = timeslot       # Next time slot
                node_offset = node_offset + 1           # Next link
            else:
                pre_offset = timeslot
    return Scheduled_Edge, Schedule

# Find a certain flow schedule in a total schedule
def FindFlowSchedule(flowid, total_schedule):
    certain_schedule = {}
    tmp_total_schedule = total_schedule

    sche_info = []
    for slot, sche_info in tmp_total_schedule.items():   # key: timeslot, value: [source, destination, flowid]
        for list in sche_info:
            if list[2] == flowid:
                certain_schedule[slot] = list
    return certain_schedule


# schedule multiple retransmission links of hi critical flow under the static low critical flow schedule
# output: virtual schedule of vir_hi_criti_source_path

def VirtualScheduler(vir_hi_criti_source_path, flowid):
    virtual_schedule = {}
    timeslot = 0

    pre_offset = 0
    current_flowid = flowid
    node_offset = 0
    retx_count = 0
    previous_edge = []

    while True:
        conflict_flag = False
        timeslot = pre_offset + 1

        # set current edge
        current_node = vir_hi_criti_source_path[node_offset]
        if current_node == flow_destination[current_flowid]:
            break

        current_edge = []
        current_edge.append(current_node)
        current_edge.append(Primary_path[current_flowid][current_node])

        # for 2-th retx routing path
        if previous_edge == current_edge:
            retx_count = retx_count + 1
            if retx_count == MaxLinkReTx:
                retx_count = 0
                if Backup_path[current_flowid][current_node] == 0:
                    pass
                else:
                    del current_edge[1]
                    current_edge.append(Backup_path[current_flowid][current_node])
        else:
            retx_count = 0

        #print("current_edge:%s"%(current_edge))


        # Schedule current edge
        if conflict_flag == False:
            sche_info = []
            sche_info = current_edge[:]     # Copy
            sche_info.append(current_flowid)
            virtual_schedule[timeslot] = sche_info
            pre_offset = timeslot                   # Next time slot
            node_offset = node_offset + 1           # Next link
            previous_edge = current_edge[:]
        else:
            pre_offset = timeslot

    return virtual_schedule

# Find types of tx conflicts of each low critical flow nodes, where virtual schedule of the hi critical flow is executed
# output: which types of transmission conflicts on each node
# [edge, slot, conflict type]
def TxConflicts(low_crit_schedule, vir_hi_criti_schedule):
    Output = []

    # Find types of Tx conflicts for each link of low critical flow
    for slot, value in low_crit_schedule.items():
        ConflictType = 0
        static_edge = []
        static_edge = value[:2]
        if slot in vir_hi_criti_schedule:
            #print("static_edge:%s, virtual edge:%s"%(static_edge, vir_hi_criti_schedule[slot][:2]))
            virtual_edge = vir_hi_criti_schedule[slot][:2]

            ### Check secondary conflicts
            secondary_conflict_set = []
            secondary_conflict_set = Secondary_conflict(Edge, virtual_edge[0], virtual_edge[1])
            #print("secondary_conflict_set of %s at slot %s: RC1 -> %s"%(slot, virtual_edge, secondary_conflict_set[0]))
            #print("secondary_conflict_set of %s at slot %s: RC2 -> %s"%(slot, virtual_edge, secondary_conflict_set[1]))
            #print("secondary_conflict_set of %s at slot %s: SC2 -> %s"%(slot, virtual_edge, secondary_conflict_set[2]))
            if static_edge in secondary_conflict_set[0]:    #RC1
                ConflictType = "RC1"
                #print("[dbg]--- edge %s has secondary conflict (RC1) at slot %s---"%(static_edge, slot))
            elif static_edge in secondary_conflict_set[1]:  #RC2
                ConflictType = "RC2"
                #print("[dbg]--- edge %s has secondary conflict (RC2) at slot %s---"%(static_edge, slot))
            elif static_edge in secondary_conflict_set[2]:  #SC2
                ConflictType = "SC2"
                #print("[dbg]--- edge %s has secondary conflict (SC2) at slot %s---"%(static_edge, slot))

            ### Check primary conflicts
            primary_conflict_set = []
            primary_conflict_set = Primary_conflict(Edge, virtual_edge[0], virtual_edge[1])
            #print("primary_conflict_set of virtual_edge:%s"%(primary_conflict_set))
            if static_edge in primary_conflict_set[0]:      #SC3
                ConflictType = "SC3"
                #print("[dbg]=== low critical edge %s has primary conflict (SC3) with virtual edge at slot %s ==="%(static_edge, slot))
            elif static_edge in primary_conflict_set[1]:    #RC3
                ConflictType = "RC3"
                #print("[dbg]=== low critical edge %s has primary conflict (RC3) with virtual edge at slot %s ==="%(static_edge, slot))


        if ConflictType != 0:
            total = []
            total.append(static_edge)
            total.append(slot)
            total.append(ConflictType)
            Output.append(total)


    return Output

# This function is used for counting link loss
def loss_recur(vector, ele, maxlinkretx):
    vec_len = len(vector)
    if vector[ele] > maxlinkretx:
        vector[ele] = 0
        if ele + 1 <= vec_len:
            vector[ele+1] = vector[ele+1] + 1
            loss_recur(vector, ele+1, maxlinkretx)

    if vector[ele] <= maxlinkretx:
        return

''' Virtual Conflict-aware Scheduler '''
# Output: {nodeid: [slot, conflict types], ...}
def VCS(sourcepath_set_input, BasicSchedule):                                          # We do not consider hi-critical flow order yet
    Output = {}
    for i in Vertex:
        Output[i] = []
    # Initialize
    linklosscount = 0

    sorted_res = sorted(sourcepath_set_input)
    current_flow = sorted_res[0]
    current_flowid = int(current_flow[len(current_flow)-1:])
    Hi_criti_source_path = sourcepath_set_input[current_flow][:]       # copy First source path from source_path_set
    SLength = len(Hi_criti_source_path) - 1
    LV = [0 for i in range(SLength)]

    linklosscount = -1
    cnt = 0

    # set low critical schedule from total schedule
    low_crit_schedule = {}
    low_crit_schedule = FindFlowSchedule(2, BasicSchedule)
    #print("[dbg]low_crit_schedule:%s\n"%(low_crit_schedule))

    # Start VCS
    while True:
        vir_Hi_criti_source_path = Hi_criti_source_path[:]
        TxConflict_output_set = []

        # Make LV permutation
        linklosscount = linklosscount + 1
        LV[0] = linklosscount
        if LV[0] > MaxLinkReTx:
            linklosscount = 0
            loss_recur(LV, 0, MaxLinkReTx)

        #print("[dbg]LV:%s"%(LV))
        tmp_LV = LV[:]



        ##### Modify source path set considering the virtual link loss #####
        # reconfigure the source path based on backup path
        for linkidx, linkloss in enumerate(LV):
            if linkloss == 2:
                # build new source path due to 2 loss of a certain link
                new_path = []
                #print("[dbg]vir_Hi_criti_source_path:%s" %(vir_Hi_criti_source_path))
                Source_path(current_flowid, vir_Hi_criti_source_path[linkidx], new_path, LV[linkidx])
                vir_Hi_criti_source_path = vir_Hi_criti_source_path[:linkidx+1]     # slicing primary path of virtual source path
                vir_Hi_criti_source_path.extend(new_path)
                #print("[dbg]Backup vir_Hi_criti_source_path:%s" %(vir_Hi_criti_source_path))

                if len(LV) < len(vir_Hi_criti_source_path)-1:
                    for i in range((len(vir_Hi_criti_source_path)-1)-len(LV)):
                        LV.append(0)
                    #print("change LV:%s"%( LV))
                else:
                    pass

        # Add retrnsmission transmitter to source path according to link loss count
        retx_buffer = []
        for linkidx, linkloss in enumerate(LV):
            tmp_list = []       # [link loss count, retransmission node]
            if linkloss != 0:
                if linkloss >= 1:       # rebuild virtual source path set considering link loss
                    retx_node = vir_Hi_criti_source_path[linkidx]
                    tmp_list.append(linkloss)
                    tmp_list.append(retx_node)
                    retx_buffer.append(tmp_list)
        #print("retx_buffer:%s"%(retx_buffer))
        for buffer in retx_buffer:
            tmp_index = vir_Hi_criti_source_path.index(buffer[1])
            for _ in range(buffer[0]):
                vir_Hi_criti_source_path.insert(tmp_index, buffer[1])
        #print("[dbg]New vir_Hi_criti_source_path:%s" %(vir_Hi_criti_source_path))


        ##### Virtual Schedule #####
        vir_schedule = {}
        vir_schedule = VirtualScheduler(vir_Hi_criti_source_path, current_flowid)
        #print("[dbg]vir_schedule:%s"%(vir_schedule))

        # Find Types of transmission conflicts on each low critical flow node
        #print("-----TxConflicts---------")
        TxConflict_output_set = TxConflicts(low_crit_schedule, vir_schedule)
        #print("[dbg]TxConflict_output:%s"%(TxConflict_output_set))
        for TxConflict_output in TxConflict_output_set:
            low_crit_sender = TxConflict_output[0][0]
            conflict_type = TxConflict_output[2]
            if conflict_type in Output[low_crit_sender]:
                pass
            else:
                Output[low_crit_sender].append(conflict_type)
        #print("[dbg]VCS Output:%s\n\n"%(Output))


        # Finish VCS algorithm
        del LV[:]
        LV = tmp_LV[:]
        LV_len = len(LV)
        finish_count = 0
        for i in LV:
            if i != MaxLinkReTx:
                break
            else:
                finish_count = finish_count + 1

        if finish_count == LV_len:
            return Output

# set TxOffset of each node based on the TxConflict types
def Conflict2TxOffset(nodeid, ConflictType_list):
    RC1 = "RC1"
    RC2 = "RC2"
    RC3 = "RC3"
    SC2 = "SC2"
    SC3 = "SC3"

    if RC3 in ConflictType_list:
        TxOffset = 10
    elif SC3 in ConflictType_list:
        TxOffset = 5
    else:
        TxOffset = 3

    return TxOffset


def Execution_func():
    global Primary_path, Backup_path, flow_destination, flow_source, flowid, Vertex, Edge
    global Superframe_len, MaxLinkReTx, MaxFlowReTx
    ''' Initialize Basic network topology'''

    # Topology Test 1
    # col: nodeid,  row: flowid
    Primary_path = [
    [0, 0, 0, 0, 0],
    [0, 3, 0, 51, 51],
    [0, 0, 4, 52, 52]
    ]

    Backup_path = [
    [0, 0, 0, 0, 0],
    [0, 4, 0, 4, 51],
    [0, 0, 3, 0, 3]
    ]

    flow_destination = [0, 51, 52]
    flow_source = [0, 1, 2]
    flowid = [1, 2]


    # Make Vertex and Edge
    Vertex = [1, 2, 3, 4, 51, 52]
    Edge = [
    [1, 3], [1, 4],
    [2, 3], [2, 4],
    [3, 4], [3, 51], [3, 52],
    [4, 51], [4, 52]
    ]

    '''
    # Topology Test 2
    Primary_path = [
    [0, 0, 0, 0, 0, 0],
    [0, 3, 52, 5, 0, 52],
    [0, 0, 3, 4, 0, 0]
    ]

    Backup_path = [
    [0, 0, 0, 0, 0, 0],
    [0, 2, 0, 2, 0, 0],
    [0, 0, 0, 0, 0, 0]
    ]

    flow_destination = [0, 52, 4]
    flow_source = [0, 1, 2]
    flowid = [1, 2]


    # Make Vertex and Edge
    Vertex = [1, 2, 3, 4, 5, 52]
    Edge = [
    [1,3], [1,2],
    [2,3], [2,52],
    [3,5], [3,4],
    [4,5],
    [5,52]
    ]
    '''

    # Superframe length
    Superframe_len = 10
    MaxLinkReTx = 2
    MaxFlowReTx = 0     # it should be changed


    # build source_path_set for every flow
    source_path = []
    source_path_set = {}

    for i in flowid:
        source_path_set['Flow_%s'%(i)] = []
        source_path_set['Flow_%s'%(i)].append(flow_source[i])
        Source_path(i, flow_source[i], source_path_set['Flow_%s'%(i)])
    print('source_path_set:%s\n'%(source_path_set))


    ### Basic_Scheduler
    Scheduled_Edge = {}
    Schedule = {}   # key: tiem slot, value: sender i, receiver j, and flowid k (ex. [i,j,k])
    Scheduled_Edge, Schedule = Basic_Scheduler(source_path_set)
    print('Scheduled_Edge:%s\n'%(Scheduled_Edge))
    print('Schedule:%s\n' %(Schedule))

    ### VCS_algorithm
    VCS_output = VCS(source_path_set, Schedule)
    print("VCS Output:%s\n\n"%(VCS_output))

    # Conflict2TxOffset(nodeid, ConflictType_list)
    send_to_MAClayer = []   # [ [nodeid, TxOffset], ... ]
    for nodeid, types in VCS_output.items():
        if types:       # if types is empty, it return false
            tmp_ = []
            tmp_.append(nodeid)
            tmp_.append(Conflict2TxOffset(nodeid, types))
            send_to_MAClayer.append(tmp_)
    print("send_to_MAClayer:%s"%(send_to_MAClayer))

    return send_to_MAClayer

if __name__=='__main__':
    Execution_func()
