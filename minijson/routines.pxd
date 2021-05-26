import io

cpdef object loads(bytes data)
cpdef int dump(object data, cio: io.BytesIO) except -1
cpdef bytes dumps(object data)
cpdef tuple parse(bytes data, int starting_position)
cpdef void switch_default_float()
cpdef void switch_default_double()

cpdef bytes dumps_object(object data)
cpdef object loads_object(bytes data, object obj_class)
