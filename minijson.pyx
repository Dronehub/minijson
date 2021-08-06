import typing as tp
import io
import struct


class MiniJSONError(ValueError):
    """
    Base class for MiniJSON errors.

    Note that it inherits from :code:`ValueError`.
    """


class EncodingError(MiniJSONError):
    """Error during encoding"""


class DecodingError(MiniJSONError):
    """Error during decoding"""


cdef:
    object STRUCT_f = struct.Struct('>f')
    object STRUCT_d = struct.Struct('>d')
    object STRUCT_b = struct.Struct('>b')
    object STRUCT_h = struct.Struct('>h')
    object STRUCT_H = struct.Struct('>H')
    object STRUCT_l = struct.Struct('>l')
    object STRUCT_L = struct.Struct('>L')
    int float_encoding_mode = 0     # 0 for default FLOAT
                                    # 1 for default DOUBLE

cpdef void switch_default_float():
    """
    Set default encoding of floats to IEEE 754 single
    """
    global float_encoding_mode
    float_encoding_mode = 0

cpdef void switch_default_double():
    """
    Set default encoding of floats to IEEE 754 double
    """
    global float_encoding_mode
    float_encoding_mode = 1

cdef inline tuple parse_cstring(bytes data, int starting_position):
    cdef:
        int strlen = data[starting_position]
        bytes subdata = data[starting_position+1:starting_position+1+strlen]
    return strlen+1, subdata

cdef inline tuple parse_list(bytes data, int elem_count, int starting_position):
    """
    Parse a list with this many elements
    
    :param data: data to parse as a list
    :param elem_count: count of elements 
    :param starting_position: starting position

    :return: tuple of (how many bytes were there in the list, the list itself)
    """
    cdef:
        list lst = []
        int i, ofs, offset = 0
    for i in range(elem_count):
        ofs, elem = parse_bytes(data, starting_position+offset)
        offset += ofs
        lst.append(elem)
    return offset, lst

cdef inline tuple parse_dict(bytes data, int elem_count, int starting_position):
    """
    Parse a dict with this many elements
    
    :param data: data to parse as a list
    :param elem_count: count of elements 
    :param starting_position: starting position

    :return: tuple of (how many bytes were there in the list, the dict itself)
    """
    cdef:
        dict dct = {}
        bytes b_field_name
        str s_field_name
        int i, ofs, offset = 0
    for i in range(elem_count):
        ofs, b_field_name = parse_cstring(data, starting_position+offset)
        try:
            s_field_name = b_field_name.decode('utf-8')
        except UnicodeDecodeError as e:
            raise DecodingError('Invalid UTF-8 field name!') from e
        offset += ofs
        ofs, elem = parse_bytes(data, starting_position+offset)
        offset += ofs
        dct[s_field_name] = elem
    return offset, dct

cdef inline tuple parse_sdict(bytes data, int elem_count, int starting_position):
    """
    Parse a sdict (with keys that are not strings) with this many elements
    
    :param data: data to parse as a list
    :param elem_count: count of elements 
    :param starting_position: starting position

    :return: tuple of (how many bytes were there in the list, the dict itself)
    """
    cdef:
        dict dct = {}
        bytes b_field_name
        str s_field_name
        int i, ofs, offset = 0
    for i in range(elem_count):
        ofs, key = parse_bytes(data, starting_position+offset)
        offset += ofs
        ofs, elem = parse_bytes(data, starting_position+offset)
        offset += ofs
        dct[key] = elem
    return offset, dct


cdef inline bint can_be_encoded_as_a_dict(dct):
    for key in dct.keys():
        if not isinstance(key, str):
            return False
        if len(key) > 255:
            return False
    return True


cdef tuple parse_bytes(bytes data, int starting_position):
    cdef:
        int value_type
        int string_length, elements, i, offset
        unsigned int uint32, length
        int sint32
        unsigned short uint16
        short sint16
        unsigned char uint8
        char sint8
        list e_list
        dict e_dict
        bytes b_field_name, byte_data
        str s_field_name
    try:
        value_type = data[starting_position]
        if value_type & 0x80:
            string_length = value_type & 0x7F
            try:
                byte_data = data[starting_position+1:starting_position+string_length+1]
                if len(byte_data) != string_length:
                    raise DecodingError('Too short a frame, expected %s bytes got %s' % (string_length,
                                                                                         len(byte_data)))
                return string_length+1, byte_data.decode('utf-8')
            except UnicodeDecodeError as e:
                raise DecodingError('Invalid UTF-8') from e
        elif value_type & 0xF0 == 0x40:
            elements = value_type & 0xF
            string_length, e_list = parse_list(data, elements, starting_position+1)
            return string_length+1, e_list
        elif value_type & 0xF0 == 0x50:
            elements = value_type & 0xF
            offset, e_dict = parse_dict(data, elements, starting_position+1)
            return offset+1, e_dict
        elif value_type & 0xF0 == 0x60:
            elements = value_type & 0xF
            offset, e_dict = parse_sdict(data, elements, starting_position+1)
            return offset+1, e_dict
        elif value_type == 0:
            string_length = data[starting_position+1]
            offset, b_field_name = parse_cstring(data, starting_position+1)
            if len(b_field_name) != string_length:
                raise DecodingError('Expected %s bytes, got %s' % (string_length, len(b_field_name)))
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
            offset, e_list = parse_list(data, elements, starting_position+2)
            return offset+2, e_list
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
            offset, e_dict = parse_dict(data, elements, starting_position+2)
            return offset+2, e_dict
        elif value_type == 13:
            string_length, = STRUCT_H.unpack(data[starting_position+1:starting_position+3])
            byte_data = data[starting_position+3:starting_position+string_length+3]
            if len(byte_data) != string_length:
                raise DecodingError('Too short a frame, expected %s bytes got %s' % (string_length,
                                                                                     len(byte_data)))
            return 3+string_length, byte_data.decode('utf-8')
        elif value_type == 14:
            string_length, = STRUCT_L.unpack(data[starting_position+1:starting_position+5])
            byte_data = data[starting_position+5:starting_position+string_length+5]
            if len(byte_data) != string_length:
                raise DecodingError('Too short a frame, expected %s bytes got %s' % (string_length,
                                                                                     len(byte_data)))
            return 5+string_length, byte_data.decode('utf-8')
        elif value_type == 15:
            elements, = STRUCT_H.unpack(data[starting_position+1:starting_position+3])
            offset, e_list = parse_list(data, elements, starting_position+3)
            return 3+offset, e_list
        elif value_type == 16:
            elements, = STRUCT_L.unpack(data[starting_position+1:starting_position+5])
            offset, e_list = parse_list(data, elements, starting_position+5)
            return 5+offset, e_list
        elif value_type == 17:
            elements, = STRUCT_H.unpack(data[starting_position+1:starting_position+3])
            offset, e_dict = parse_dict(data, elements, starting_position+3)
            return offset+3, e_dict
        elif value_type == 18:
            elements, = STRUCT_L.unpack(data[starting_position+1:starting_position+5])
            offset, e_dict = parse_dict(data, elements, starting_position+5)
            return offset+5, e_dict
        elif value_type == 19:
            elements, = STRUCT_L.unpack(data[starting_position+1:starting_position+5])
            offset, e_dict = parse_sdict(data, elements, starting_position+5)
            return offset+5, e_dict
        elif value_type == 20:
            elements = data[starting_position+1]
            offset, e_dict = parse_sdict(data, elements, starting_position+2)
            return offset+2, e_dict
        elif value_type == 21:
            elements, = STRUCT_H.unpack(data[starting_position+1:starting_position+3])
            offset, e_dict = parse_sdict(data, elements, starting_position+3)
            return offset+3, e_dict
        elif value_type == 22:
            return 1, True
        elif value_type == 23:
            return 1, False
        elif value_type == 24:
            length = data[starting_position+1]
            byte_data = data[starting_position+2:starting_position+2+length]
            return length+2, int.from_bytes(byte_data, 'big', signed=True)
        elif value_type == 25:
            length = data[starting_position+1]
            byte_data = data[starting_position+2:starting_position+2+length]
            return length+2, byte_data
        elif value_type == 26:
            length, = STRUCT_H.unpack(data[starting_position+1:starting_position+3])
            byte_data = data[starting_position+3:starting_position+3+length]
            return length+3, byte_data
        elif value_type == 27:
            length, = STRUCT_L.unpack(data[starting_position+1:starting_position+5])
            byte_data = data[starting_position+5:starting_position+5+length]
            return length+5, byte_data
        else:
            raise DecodingError('Unknown sequence type %s!' % (value_type, ))
    except (IndexError, struct.error) as e:
        raise DecodingError('String too short!') from e


cpdef tuple parse(object data, int starting_position):
    """
    Parse given stream of data starting at a position
    and return a tuple of (how many bytes does this piece of data take, the piece of data itself)
    
    :param data: stream of bytes to examine. Must be able to provide it's bytes value
        via :code:`__bytes__` 
    :param starting_position: first position in the bytestring at which to look
    :return: a tuple of (how many bytes does this piece of data take, the piece of data itself)
    :rtype: tp.Tuple[int, tp.Any]
    :raises DecodingError: invalid stream
    """
    cdef bytes b_data = bytes(data)
    return parse_bytes(b_data, starting_position)


cpdef object loads(object data):
    """
    Reconstruct given JSON from a given value

    :param data: MiniJSON value to reconstruct it from.
        Must be able to provide bytes representation.
    :return: return value
    :raises DecodingError: something was wrong with the stream
    """
    return parse(data, 0)[1]


cdef inline bint is_jsonable(y):
    return y is None or isinstance(y, (int, float, str, dict, list, tuple))


cdef class MiniJSONEncoder:
    """
    A base class for encoders.

    It is advised to use this class over :meth:`~minijson.dump` and
    :meth:`~minijson.dumps` due to finer grained control over floats.

    :param default: a default function used
    :param use_double: whether to use doubles instead of floats to represent floating point numbers
    :param use_strict_order: if set to True, dictionaries will be encoded by first
        dumping them to items and sorting the resulting elements, essentially
        two same dicts will be encoded in the same way.
    :ivar use_double: (bool) whether to use doubles instead of floats (used when
        :meth:`~minijson.MiniJSONEncoder.should_double_be_used` is not overrided)
    """
    cdef:
        object _default
        public bint use_double
        public bint use_strict_order

    def __init__(self, default: tp.Optional[None] = None,
                 bint use_double = False,
                 bint use_strict_order = False):
        self._default = default
        self.use_double = use_double
        self.use_strict_order = use_strict_order

    def should_double_be_used(self, y) -> bool:
        """
        A function that you are meant to overload that will decide on a per-case basis
        which representation should be used for given number.

        :param y: number to check
        :return: True if double should be used, else False
        """
        return self.use_double

    def default(self, v):
        """
        Convert an object to a JSON-able representation.

        Overload this to provide your default function in other way that giving
        the callable as a parameter.

        :param v: object to convert
        :return: a JSONable representation
        """
        if self._default is None:
            raise EncodingError('Unknown value type %s' % (v, ))
        else:
            return self._default(v)

    def encode(self, v) -> bytes:
        """
        Encode a provided object

        :param v: object to encode
        :return: returned bytes
        """
        cio = io.BytesIO()
        self.dump(v, cio)
        return cio.getvalue()

    cpdef int dump(self, object data, cio: io.BytesIO) except -1:
        """
        Write an object to a stream
    
        :param data: object to write
        :param cio: stream to write to
        :return: amount of bytes written
        :raises EncodingError: invalid data
        """
        cdef:
            str field_name
            unsigned int length
            bytes b_data
            list items
        if data is None:
            cio.write(b'\x08')
            return 1
        elif data is True:
            cio.write(b'\x16')
            return 1
        elif data is False:
            cio.write(b'\x17')
            return 1
        elif isinstance(data, bytes):
            length = len(data)
            if length < 256:
                cio.write(bytearray([0x19, length]))
                cio.write(data)
            elif length < 65536:
                cio.write(b'\x1A' + struct.pack('>H', length))
                cio.write(data)
            else:
                cio.write(b'\x1B' + struct.pack('>L', length))
                cio.write(data)
        elif isinstance(data, str):
            length = len(data)
            if length < 128:
                cio.write(bytearray([0x80 | length]))
                cio.write(data.encode('utf-8'))
                return 1+length
            elif length <= 0xFF:
                cio.write(bytearray([0, length]))
                cio.write(data.encode('utf-8'))
                return 2+length
            elif length <= 0xFFFF:
                cio.write(b'\x0D')
                cio.write(STRUCT_H.pack(length))
                cio.write(data.encode('utf-8'))
                return 3+length
            else:       # Python strings cannot grow past 0xFFFFFFFF characters
                cio.write(b'\x0E')
                cio.write(STRUCT_L.pack(length))
                cio.write(data.encode('utf-8'))
                return 5+length
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
            elif 0 <= data <= 0xFFFFFF:         # unsigned 3byte, type 12
                cio.write(b'\x0C')
                cio.write(STRUCT_L.pack(data)[1:])
                return 4
            elif -2147483648 <= data <= 2147483647:     # signed int, type 1
                cio.write(b'\x01')
                cio.write(STRUCT_l.pack(data))
                return 5
            elif 0 <= data <= 0xFFFFFFFF:       # unsigned int, type 4
                cio.write(b'\x04')
                cio.write(STRUCT_L.pack(data))
                return 5
            else:
                length = 5
                while True:
                    try:
                        b_data = data.to_bytes(length, 'big', signed=True)
                        break
                    except OverflowError:
                        length += 1
                cio.write(bytearray([0x18, length]))
                cio.write(b_data)
        elif isinstance(data, float):
            if self.should_double_be_used(data):
                cio.write(b'\x0A')
                cio.write(STRUCT_d.pack(data))
                return 9
            else:
                cio.write(b'\x09')
                cio.write(STRUCT_f.pack(data))
                return 5
        elif isinstance(data, (tuple, list)):
            length = len(data)
            if length < 16:
                cio.write(bytearray([0b01000000 | length]))
                length = 1
            elif length < 256:
                cio.write(bytearray([7, length]))
                length = 2
            elif length < 65536:
                cio.write(b'\x0F')
                cio.write(STRUCT_H.pack(length))
                length = 3
            elif length <= 0xFFFFFFFF:
                cio.write(b'\x10')
                cio.write(STRUCT_L.pack(length))
                length = 5
            for elem in data:
                length += self.dump(elem, cio)
            return length
        elif isinstance(data, dict):
            length = len(data)
            if can_be_encoded_as_a_dict(data):
                if length < 16:
                    cio.write(bytearray([0b01010000 | length]))
                    length = 1
                elif length < 256:
                    cio.write(bytearray([11, len(data)]))
                    length = 2
                elif length < 65536:
                    cio.write(b'\x11')
                    cio.write(STRUCT_H.pack(length))
                    length = 3
                elif length <= 0xFFFFFFFF:
                    cio.write(b'\x12')
                    cio.write(STRUCT_L.pack(length))
                    length = 5
                if self.use_strict_order:
                    items = list(data.items())
                    items.sort()
                    for field_name, elem in items:
                        cio.write(bytearray([len(field_name)]))
                        cio.write(field_name.encode('utf-8'))
                        length += self.dump(elem, cio)
                else:
                    for field_name, elem in data.items():
                        cio.write(bytearray([len(field_name)]))
                        cio.write(field_name.encode('utf-8'))
                        length += self.dump(elem, cio)
                return length
            else:
                if length <= 0xF:
                    cio.write(bytearray([0b01100000 | length]))
                    offset = 1
                elif length <= 0xFF:
                    cio.write(bytearray([20, length]))
                    offset = 2
                elif length <= 0xFFFF:
                    cio.write(b'\x15')
                    cio.write(STRUCT_H.pack(length))
                    offset = 3
                else:       # Python objects cannot grow to have more than 0xFFFFFFFF members
                    cio.write(b'\x13')
                    cio.write(STRUCT_L.pack(length))
                    offset = 5
                if self.use_strict_order:
                    items = list(data.items())
                    items.sort()
                    for key, value in items:
                        offset += self.dump(key, cio)
                        offset += self.dump(value, cio)
                else:
                    for key, value in data.items():
                        offset += self.dump(key, cio)
                        offset += self.dump(value, cio)
                return offset
        else:
            v = self.default(data)
            if not is_jsonable(v):
                raise EncodingError('default returned a non-JSONable value!')
            return self.dump(v, cio)


cpdef int dump(object data, cio: io.BytesIO, default: tp.Optional[tp.Callable] = None) except -1:
    """
    Write an object to a stream.
    
    Note that this will load the initial value of current default float encoding mode and remember
    it throughout the streaming process, so you can't change it mid-value.
    
    To do so, please use :class:`~minijson.MiniJSONEncoder`

    :param data: object to write
    :param cio: stream to write to
    :param default: a callable/1 that should return a JSON-able representation for objects
        that can't be JSONed otherwise
    :return: amount of bytes written
    :raises EncodingError: invalid data
    """
    global float_encoding_mode
    cdef MiniJSONEncoder mje = MiniJSONEncoder(default, float_encoding_mode == 1)
    return mje.dump(data, cio)


cpdef bytes dumps(object data, default: tp.Optional[tp.Callable] = None):
    """
    Serialize given data to a MiniJSON representation.

    Note that this will load the initial value of current default float encoding mode and remember
    it throughout the streaming process, so you can't change it mid-value.
    
    To do so, please use :class:`~minijson.MiniJSONEncoder`
        
    :param data: data to serialize
    :param default: a function that should be used to convert non-JSONable objects to JSONable ones.
        Default, None, will raise an EncodingError upon encountering such a value
    :return: return MiniJSON representation
    :raises EncodingError: object not serializable
    """
    cio = io.BytesIO()
    dump(data, cio, default)
    return cio.getvalue()


cpdef bytes dumps_object(object data, default: tp.Optional[tp.Callable] = None):
    """
    Dump an object's :code:`__dict__`.
    
    Note that subobject's :code:`__dict__` will not be copied. Use default for that.
    
    Note that this will load the initial value of current default float encoding mode and remember
    it throughout the streaming process, so you can't change it mid-value.
    
    To do so, please use :class:`~minijson.MiniJSONEncoder`
    
    :param data: object to dump 
    :param default: a function that should be used to convert non-JSONable objects to JSONable ones.
        Default, None, will raise an EncodingError upon encountering such a value
    :return: resulting bytes
    :raises EncodingError: encoding error
    """
    return dumps(data.__dict__, default)


cpdef object loads_object(data, object obj_class):
    """
    Load a dict from a bytestream, unserialize it and use it as a kwargs to instantiate
    an object of given class.

    :param data: data to unserialized 
    :param obj_class: class to instantiate
    :return: instance of obj_class
    :raises DecodingError: decoding error
    :raises TypeError: invalid class has been passed (the argument's don't match)
    """
    cdef dict kwargs
    try:
         kwargs = loads(data)
    except TypeError:
        raise DecodingError('Expected an object to be of type dict!')
    return obj_class(**kwargs)
