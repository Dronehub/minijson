import typing as tp
import io
import struct

from minijson.exceptions import DecodingError, EncodingError

STRUCT_f = struct.Struct('>f')
STRUCT_d = struct.Struct('>d')
STRUCT_b = struct.Struct('>b')
STRUCT_h = struct.Struct('>h')
STRUCT_H = struct.Struct('>H')
STRUCT_l = struct.Struct('>l')
STRUCT_L = struct.Struct('>L')

cdef int coding_mode = 0     # 0 for default FLOAT
                             # 1 for default DOUBLE

cpdef void switch_default_float():
    """
    Set default encoding of floats to IEEE 754 single
    """
    global coding_mode
    coding_mode = 0

cpdef void switch_default_double():
    """
    Set default encoding of floats to IEEE 754 double
    """
    global coding_mode
    coding_mode = 1

cdef inline tuple parse_cstring(bytes data, int starting_position):
    cdef:
        int strlen = data[starting_position]
        bytes subdata = data[starting_position+1:starting_position+1+strlen]
    return strlen+1, subdata

cpdef tuple parse(bytes data, int starting_position):
    """
    Parse given stream of data starting at a position
    and return a tuple of (how many bytes does this piece of data take, the piece of data itself)
    
    :param data: stream of bytes to examine 
    :param starting_position: first position in the bytestring at which to look
    :return: a tuple of (how many bytes does this piece of data take, the piece of data itself)
    :rtype: tp.Tuple[int, tp.Any]
    """
    cdef:
        int value_type = data[starting_position]
        int string_length
        unsigned int uint32
        int sint32
        unsigned short uint16
        short sint16
        unsigned char uint8
        char sint8
        list e_list
        dict e_dict
        int elements, i, offset, length
        bytes b_field_name
        str s_field_name
    if value_type & 0x80:
        string_length = value_type & 0x7F
        try:
            return string_length+1, data[starting_position+1:starting_position+string_length+1].decode('utf-8')
        except UnicodeDecodeError as e:
            raise DecodingError('Invalid UTF-8') from e
    elif value_type & 0xF0 == 0x40:
        elements = value_type & 0xF
        offset = 1
        e_list = []
        for i in range(elements):
            length, elem = parse(data, starting_position+offset)
            offset += length
            e_list.append(elem)
        return offset, e_list
    elif value_type & 0xF0 == 0x50:
        e_dict = {}
        offset = 1
        elements = value_type & 0xF

        for i in range(elements):
            length, b_field_name = parse_cstring(data, starting_position+offset)
            s_field_name = b_field_name.decode('utf-8')
            offset += length
            length, elem = parse(data, starting_position+offset)
            offset += length
            e_dict[s_field_name] = elem
        return offset, e_dict
    elif value_type == 0:
        string_length = data[starting_position+1]
        offset, b_field_name = parse_cstring(data, starting_position+1)
        try:
            return offset+1, b_field_name.decode('utf-8')
        except UnicodeDecodeError as e:
            raise DecodingError('Invalid UTF-8') from e
    elif value_type in (1, 4):
        uint32 = (data[starting_position+1] << 24) | (data[starting_position+2] << 16) | (data[starting_position+3] << 8) | data[starting_position+4]
        if value_type == 4:
            return 5, uint32
        else:
            sint32 = uint32
            return 5, sint32
    elif value_type in (2, 5):
        uint16 = (data[starting_position+1] << 8) | data[starting_position+2]
        if value_type == 5:
            return 3, uint16
        else:
            sint16 = uint16
            return 3, sint16
    elif value_type in (3, 6):
        uint8 = data[starting_position+1]
        if value_type == 6:
            return 2, uint8
        else:
            sint8 = uint8
            return 2, sint8
    elif value_type == 7:
        elements = data[starting_position+1]
        e_list = []
        offset = 2
        for i in range(elements):
            length, elem = parse(data, starting_position+offset)
            offset += length
            e_list.append(elem)
        return e_list
    elif value_type == 8:
        return 1, None
    elif value_type == 9:
        return 5, *STRUCT_f.unpack(data[starting_position+1:starting_position+5])
    elif value_type == 10:
        return 9, *STRUCT_d.unpack(data[starting_position+1:starting_position+9])
    elif value_type == 12:
        uint32 = (data[starting_position+1] << 16) | (data[starting_position+2] << 8) | data[starting_position+3]
        return 4, uint32
    elif value_type == 11:
        elements = data[starting_position+1]
        e_dict = {}
        offset = 2

        for i in range(elements):
            length, b_field_name = parse_cstring(data, starting_position+offset)
            s_field_name = b_field_name.decode('utf-8')
            offset += length
            length, elem = parse(data, starting_position+offset)

            offset += length
            e_dict[s_field_name] = elem
        return offset, e_dict
    raise DecodingError(f'Unknown sequence type {value_type}!')


cpdef object loads(bytes data):
    """
    Reconstruct given JSON from a given value

    :param data: MiniJSON value to reconstruct it from
    :return: return value
    :raises DecodingError: something was wrong with the stream
    """
    return parse(data, 0)[1]


cpdef int dump(object data, cio: io.BytesIO) except -1:
    """
    Write an object to a stream

    :param data: object to write
    :param cio: stream to write to
    :return: bytes written
    """
    cdef:
        str field_name
        int length
    if data is None:
        cio.write(b'\x08')
        return 1
    elif isinstance(data, str):
        length = len(data)
        if length > 255:
            raise EncodingError('Cannot encode string longer than 255 characters')
        if length < 128:
            cio.write(bytearray([0x80 | length]))
            cio.write(data.encode('utf-8'))
            return 1+length
        else:
            cio.write(bytearray([0, length]))
            cio.write(data.encode('utf-8'))
            return 2+length
    elif isinstance(data, int):
        if -128 <= data <= 127: # signed char, type 3
            cio.write(b'\x03')
            cio.write(STRUCT_b.pack(data))
            return 2
        elif 0 <= data <= 255:  # unsigned char, type 6
            cio.write(bytearray([6, data]))
            return 2
        elif -32768 <= data <= 32767:   # signed short, type 2
            cio.write(b'\x02')
            cio.write(STRUCT_h.pack(data))
            return 3
        elif 0 <= data <= 65535:        # unsigned short, type 5
            cio.write(b'\x05')
            cio.write(STRUCT_H.pack(data))
            return 3
        elif -2147483648 <= data <= 2147483647:     # signed int, type 1
            cio.write(b'\x01')
            cio.write(STRUCT_l.pack(data))
            return 5
        elif 0 <= data <= 0xFFFFFF:         # unsigned 3byte, type 12
            cio.write(b'\x0C')
            cio.write(STRUCT_L.pack(data)[1:])
            return 4
        elif 0 <= data <= 0xFFFFFFFF:       # unsigned int, type 6
            cio.write(b'\x06')
            cio.write(STRUCT_L.pack(data))
            return 5
        else:
            raise EncodingError(f'Too large integer {data}')
    elif isinstance(data, float):
        if coding_mode == 0:
            cio.write(b'\x09')
            cio.write(STRUCT_f.pack(data))
            return 5
        else:
            cio.write(b'\x0A')
            cio.write(STRUCT_d.pack(data))
            return 9
    elif isinstance(data, (tuple, list)):
        length = len(data)
        if length > 255:
            raise EncodingError('Too long of a list, maximum list length is 255')
        if length < 16:
            cio.write(bytearray([0b01000000 | length]))
            length = 1
        else:
            cio.write(bytearray([7, length]))
            length = 2
        for elem in data:
            length += dump(elem, cio)
        return length
    elif isinstance(data, dict):
        length = len(data)
        if length > 255:
            raise EncodingError('Too long of a dict, maximum dict length is 255')
        if length < 16:
            cio.write(bytearray([0b01010000 | length]))
            length = 1
        else:
            cio.write(bytearray([11, len(data)]))
            length = 2
        for field_name, elem in data.items():
            cio.write(bytearray([len(field_name)]))
            cio.write(field_name.encode('utf-8'))
            length += dump(elem, cio)
        return length
    else:
        raise EncodingError(f'Unknown value type {data}')

cpdef bytes dumps(object data):
    """
    Serialize given data to a MiniJSON representation

    :param data: data to serialize
    :return: return MiniJSON representation
    :raises DecodingError: object not serializable
    """
    cio = io.BytesIO()
    dump(data, cio)
    return cio.getvalue()


cpdef bytes dumps_object(object data):
    """
    Dump an object's __dict__
    
    :param data: object to dump 
    :return: resulting bytes
    :raises EncodingError: encoding error
    """
    return dumps(data.__dict__)

cpdef object loads_object(bytes data, object obj_class):
    """
    Load a dict from a bytestream, unserialize it and use it as a kwargs to instantiate
    an object of given class
    
    :param data: data to unserialized 
    :param obj_class: class to instantiate
    :return: instance of obj_class
    :raises DecodingError: decoding error
    """
    cdef dict kwargs = loads(data)
    return obj_class(**kwargs)
