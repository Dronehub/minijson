import unittest
from minijson import dumps, loads, dumps_object, loads_object, EncodingError, DecodingError, \
    switch_default_double, switch_default_float


class TestMiniJSON(unittest.TestCase):

    def test_accepts_bytearrays(self):
        b = {'test': 'hello'}
        a = dumps(b)
        a = bytearray(a)
        self.assertEqual(loads(a), b)

    def assertLoadingIsDecodingError(self, b: bytes):
        self.assertRaises(DecodingError, lambda: loads(b))

    def assertSameAfterDumpsAndLoads(self, c):
        self.assertEqual(loads(dumps(c)), c)

    def test_malformed(self):
        self.assertRaises(EncodingError, lambda: dumps(2 + 3j))
        self.assertLoadingIsDecodingError(b'\x00\x02a')
        self.assertLoadingIsDecodingError(b'\x00\x02a')
        self.assertLoadingIsDecodingError(b'\x09\x00')
        self.assertLoadingIsDecodingError(b'\x82\x00')

    def test_short_nonstring_key_dicts(self):
        self.assertSameAfterDumpsAndLoads({i: i for i in range(20)})
        self.assertSameAfterDumpsAndLoads({i: i for i in range(300)})
        self.assertSameAfterDumpsAndLoads({i: i for i in range(66000)})

    def test_invalid_name_dict(self):
        self.assertLoadingIsDecodingError(b'\x15\x01\x81\x01')
        self.assertLoadingIsDecodingError(b'\x0B\x01\x01\xFF\x15')
        self.assertLoadingIsDecodingError(b'\x0D\x01\x00\x00')
        self.assertLoadingIsDecodingError(b'\x0E\x00\x00\x01\x00\x00')

    def test_encode_double(self):
        switch_default_double()
        b = dumps(4.5)
        self.assertGreaterEqual(len(b), 5)
        self.assertEqual(loads(b), 4.5)
        switch_default_float()

    def test_booleans(self):
        self.assertSameAfterDumpsAndLoads({'test': True,
                                           'test2': False})

    def test_string(self):
        self.assertSameAfterDumpsAndLoads('test')
        self.assertSameAfterDumpsAndLoads('t' * 128)
        self.assertSameAfterDumpsAndLoads('t' * 65535)
        self.assertSameAfterDumpsAndLoads('t' * 65540)

    def test_lists(self):
        self.assertSameAfterDumpsAndLoads([None] * 4)
        self.assertSameAfterDumpsAndLoads([None] * 256)
        self.assertSameAfterDumpsAndLoads([None] * 17)

    def test_long_dicts(self):
        self.assertSameAfterDumpsAndLoads({str(i): i for i in range(17)})

    def test_dicts_not_string_keys(self):
        self.assertSameAfterDumpsAndLoads({i: i for i in range(17)})

    def test_long_dicts_and_lists(self):
        self.assertSameAfterDumpsAndLoads({str(i): i * 2 for i in range(65535)})
        self.assertSameAfterDumpsAndLoads({str(i): i * 2 for i in range(0x1FFFFF)})
        self.assertSameAfterDumpsAndLoads(list(range(0xFFFF)))
        self.assertSameAfterDumpsAndLoads(list(range(0x1FFFF)))

    def test_weird_dict(self):
        self.assertSameAfterDumpsAndLoads({'a' * 300: 2})

    def test_negatives(self):
        self.assertSameAfterDumpsAndLoads(-1)
        self.assertSameAfterDumpsAndLoads(-259)
        self.assertSameAfterDumpsAndLoads(-0x7FFF)
        self.assertSameAfterDumpsAndLoads(-0xFFFF)
        self.assertSameAfterDumpsAndLoads(0x1FFFF)
        self.assertSameAfterDumpsAndLoads(0xFFFFFFFF)
        self.assertSameAfterDumpsAndLoads(0x1FFFFFF)
        self.assertSameAfterDumpsAndLoads(0xFFFFFFFFF)
        self.assertSameAfterDumpsAndLoads(0xFFFFFFFFFFFFF)

    def test_dumps(self):
        self.assertSameAfterDumpsAndLoads({"name": "land", "operator_id": "dupa", "parameters":
            {"lat": 45.22999954223633, "lon": 54.79999923706055, "alt": 234}})

    def test_loads_exception(self):
        self.assertLoadingIsDecodingError(b'')
        self.assertLoadingIsDecodingError(b'\x1F')
        self.assertLoadingIsDecodingError(b'\x00\x01')
        self.assertLoadingIsDecodingError(b'\x00\x01\xFF')
        self.assertLoadingIsDecodingError(b'\x81\xFF')

    def test_loads(self):
        a = loads(
            b'\x0B\x03\x04name\x84land\x0Boperator_id\x84dupa\x0Aparameters\x0B\x03\x03lat\x09B4\xeb\x85\x03lon\x09B[33\x03alt\x09Cj\x00\x00')
        self.assertEqual(a, {"name": "land", "operator_id": "dupa", "parameters":
            {"lat": 45.22999954223633, "lon": 54.79999923706055, "alt": 234}})

    def test_dumps_loads_object(self):
        class Test:
            def __init__(self, a):
                self.a = a

        a = Test(2)
        b = dumps_object(a)
        c = loads_object(b, Test)
        self.assertEqual(a.a, c.a)
        self.assertIsInstance(c, Test)
        self.assertRaises(DecodingError, lambda: loads_object(b'\x07\x00', Test))
