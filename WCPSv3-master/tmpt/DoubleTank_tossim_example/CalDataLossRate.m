

%initialize
P1_TransCount=12;
P2_TransCount=14;


P1_initialSlot=3;
P2_initialSlot=3;
TotalSlotNumber=P1_initialSlot + P2_initialSlot;


%%%%%%%%%%%%%%
PlusSlot=P1_initialSlot*(P1_TransCount/(P1_TransCount+P2_TransCount));
PlusSlot=round(PlusSlot);

PlusSlot;

