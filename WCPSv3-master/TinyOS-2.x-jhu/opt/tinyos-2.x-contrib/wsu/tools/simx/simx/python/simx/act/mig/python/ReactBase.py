#
# This class is automatically generated by mig. DO NOT EDIT THIS FILE.
# This class implements a Python interface to the 'Msg'
# message type.
#

import tinyos.message.Message

# The default size of this message type in bytes.
DEFAULT_MESSAGE_SIZE = 6

# The Active Message type associated with this message.
AM_TYPE = 239

class Msg(tinyos.message.Message.Message):
    # Create a new Msg of size 6.
    def __init__(self, data="", addr=None, gid=None, base_offset=0, data_length=6):
        tinyos.message.Message.Message.__init__(self, data, addr, gid, base_offset, data_length)
        self.amTypeSet(AM_TYPE)
    
    # Get AM_TYPE
    def get_amType(cls):
        return AM_TYPE
    
    get_amType = classmethod(get_amType)
    
    #
    # Return a String representation of this message. Includes the
    # message type name and the non-indexed field values.
    #
    def __str__(self):
        s = "Message <Msg> \n"
        try:
            s += "  [track_id=0x%x]\n" % (self.get_track_id())
        except:
            pass
        try:
            s += "  [type=0x%x]\n" % (self.get_type())
        except:
            pass
        try:
            s += "  [remaining=0x%x]\n" % (self.get_remaining())
        except:
            pass
        try:
            s += "  [payload_start_byte=0x%x]\n" % (self.get_payload_start_byte())
        except:
            pass
        return s

    # Message-type-specific access methods appear below.

    #
    # Accessor methods for field: track_id
    #   Field type: int
    #   Offset (bits): 0
    #   Size (bits): 16
    #

    #
    # Return whether the field 'track_id' is signed (False).
    #
    def isSigned_track_id(self):
        return False
    
    #
    # Return whether the field 'track_id' is an array (False).
    #
    def isArray_track_id(self):
        return False
    
    #
    # Return the offset (in bytes) of the field 'track_id'
    #
    def offset_track_id(self):
        return (0 / 8)
    
    #
    # Return the offset (in bits) of the field 'track_id'
    #
    def offsetBits_track_id(self):
        return 0
    
    #
    # Return the value (as a int) of the field 'track_id'
    #
    def get_track_id(self):
        return self.getUIntElement(self.offsetBits_track_id(), 16, 1)
    
    #
    # Set the value of the field 'track_id'
    #
    def set_track_id(self, value):
        self.setUIntElement(self.offsetBits_track_id(), 16, value, 1)
    
    #
    # Return the size, in bytes, of the field 'track_id'
    #
    def size_track_id(self):
        return (16 / 8)
    
    #
    # Return the size, in bits, of the field 'track_id'
    #
    def sizeBits_track_id(self):
        return 16
    
    #
    # Accessor methods for field: type
    #   Field type: short
    #   Offset (bits): 16
    #   Size (bits): 8
    #

    #
    # Return whether the field 'type' is signed (False).
    #
    def isSigned_type(self):
        return False
    
    #
    # Return whether the field 'type' is an array (False).
    #
    def isArray_type(self):
        return False
    
    #
    # Return the offset (in bytes) of the field 'type'
    #
    def offset_type(self):
        return (16 / 8)
    
    #
    # Return the offset (in bits) of the field 'type'
    #
    def offsetBits_type(self):
        return 16
    
    #
    # Return the value (as a short) of the field 'type'
    #
    def get_type(self):
        return self.getUIntElement(self.offsetBits_type(), 8, 1)
    
    #
    # Set the value of the field 'type'
    #
    def set_type(self, value):
        self.setUIntElement(self.offsetBits_type(), 8, value, 1)
    
    #
    # Return the size, in bytes, of the field 'type'
    #
    def size_type(self):
        return (8 / 8)
    
    #
    # Return the size, in bits, of the field 'type'
    #
    def sizeBits_type(self):
        return 8
    
    #
    # Accessor methods for field: remaining
    #   Field type: int
    #   Offset (bits): 24
    #   Size (bits): 16
    #

    #
    # Return whether the field 'remaining' is signed (False).
    #
    def isSigned_remaining(self):
        return False
    
    #
    # Return whether the field 'remaining' is an array (False).
    #
    def isArray_remaining(self):
        return False
    
    #
    # Return the offset (in bytes) of the field 'remaining'
    #
    def offset_remaining(self):
        return (24 / 8)
    
    #
    # Return the offset (in bits) of the field 'remaining'
    #
    def offsetBits_remaining(self):
        return 24
    
    #
    # Return the value (as a int) of the field 'remaining'
    #
    def get_remaining(self):
        return self.getUIntElement(self.offsetBits_remaining(), 16, 1)
    
    #
    # Set the value of the field 'remaining'
    #
    def set_remaining(self, value):
	print value," ",self.offsetBits_remaining(),"\n";
        self.setUIntElement(self.offsetBits_remaining(), 16, value, 1)
    
    #
    # Return the size, in bytes, of the field 'remaining'
    #
    def size_remaining(self):
        return (16 / 8)
    
    #
    # Return the size, in bits, of the field 'remaining'
    #
    def sizeBits_remaining(self):
        return 16
    
    #
    # Accessor methods for field: payload_start_byte
    #   Field type: short
    #   Offset (bits): 40
    #   Size (bits): 8
    #

    #
    # Return whether the field 'payload_start_byte' is signed (False).
    #
    def isSigned_payload_start_byte(self):
        return False
    
    #
    # Return whether the field 'payload_start_byte' is an array (False).
    #
    def isArray_payload_start_byte(self):
        return False
    
    #
    # Return the offset (in bytes) of the field 'payload_start_byte'
    #
    def offset_payload_start_byte(self):
        return (40 / 8)
    
    #
    # Return the offset (in bits) of the field 'payload_start_byte'
    #
    def offsetBits_payload_start_byte(self):
        return 40
    
    #
    # Return the value (as a short) of the field 'payload_start_byte'
    #
    def get_payload_start_byte(self):
        return self.getUIntElement(self.offsetBits_payload_start_byte(), 8, 1)
    
    #
    # Set the value of the field 'payload_start_byte'
    #
    def set_payload_start_byte(self, value):
        self.setUIntElement(self.offsetBits_payload_start_byte(), 8, value, 1)
    
    #
    # Return the size, in bytes, of the field 'payload_start_byte'
    #
    def size_payload_start_byte(self):
        return (8 / 8)
    
    #
    # Return the size, in bits, of the field 'payload_start_byte'
    #
    def sizeBits_payload_start_byte(self):
        return 8
    
