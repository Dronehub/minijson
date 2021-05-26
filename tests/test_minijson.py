import unittest
from minijson import dumps, loads, dumps_object, loads_object, EncodingError, DecodingError, \
    switch_default_double, switch_default_float


class TestMiniJSON(unittest.TestCase):

    def assertSameAfterDumpsAndLoads(self, c):
        self.assertEqual(loads(dumps(c)), c)

    def test_malformed(self):
        self.assertRaises(EncodingError, lambda: dumps(2+3j))
        self.assertRaises(DecodingError, lambda: loads(b'\x00\x02a'))
        self.assertRaises(DecodingError, lambda: loads(b'\x00\x02a'))
        self.assertRaises(DecodingError, lambda: loads(b'\x09\x00'))

    def test_short_nonstring_key_dicts(self):
        a = {}
        for i in range(20):
            a[i] = i
        self.assertSameAfterDumpsAndLoads(a)
        a = {}
        for i in range(300):
            a[i] = i
        self.assertSameAfterDumpsAndLoads(a)
        for i in range(70000):
            a[i] = i
        self.assertSameAfterDumpsAndLoads(a)

    def test_invalid_name_dict(self):
        self.assertRaises(DecodingError, lambda: loads(b'\x15\x01\x81\x01'))
        self.assertRaises(DecodingError, lambda: loads(b'\x0B\x01\x01\xFF\x15'))

    def test_encode_double(self):
        switch_default_double()
        self.assertGreaterEqual(len(dumps(4.5)), 5)
        switch_default_float()

    def test_booleans(self):
        self.assertSameAfterDumpsAndLoads({'test': True,
                                           'test2': False})

    def test_string(self):
        a = 'test'
        b = 't'*128
        c = 't'*65535
        d = 't'*128342
        self.assertSameAfterDumpsAndLoads(a)
        self.assertSameAfterDumpsAndLoads(b)
        self.assertSameAfterDumpsAndLoads(c)
        self.assertSameAfterDumpsAndLoads(d)

    def test_too_long_string(self):
        class Test(str):
            def __len__(self):
                return 0x1FFFFFFFF

        self.assertRaises(EncodingError, lambda: dumps(Test()))

    def test_lists(self):
        a = [None]*4
        self.assertSameAfterDumpsAndLoads(a)

        a = [None]*256
        self.assertSameAfterDumpsAndLoads(a)

    def test_long_lists(self):
        a = [None]*17
        self.assertSameAfterDumpsAndLoads(a)

    def test_long_dicts(self):
        a = {}
        for i in range(17):
            a[str(i)] = i
        self.assertSameAfterDumpsAndLoads(a)

    def test_dicts_not_string_keys(self):
        a = {}
        for i in range(17):
            a[i] = i
        self.assertSameAfterDumpsAndLoads(a)

    def test_long_dicts_and_lists(self):
        a = {}
        for i in range(65535):
            a[str(i)] = i*2
        self.assertSameAfterDumpsAndLoads(a)
        a = {}
        for i in range(0x1FFFF):
            a[str(i)] = i*2
        self.assertSameAfterDumpsAndLoads(a)
        a = list(range(0xFFFF))
        self.assertSameAfterDumpsAndLoads(a)
        a = list(range(0x1FFFF))
        self.assertSameAfterDumpsAndLoads(a)

    def test_weird_dict(self):
        key = 'a'*300
        a = {key: 2}
        self.assertSameAfterDumpsAndLoads(a)

    def test_negatives(self):
        self.assertSameAfterDumpsAndLoads(-1)
        self.assertSameAfterDumpsAndLoads(-259)
        self.assertSameAfterDumpsAndLoads(-0x7FFF)
        self.assertSameAfterDumpsAndLoads(-0xFFFF)
        self.assertSameAfterDumpsAndLoads(0x1FFFF)
        self.assertSameAfterDumpsAndLoads(0x1FFFFFF)
        self.assertRaises(EncodingError, lambda: dumps(0xFFFFFFFFF))

    def test_dumps(self):
        v = {"name": "land", "operator_id": "dupa", "parameters":
            {"lat": 45.22999954223633, "lon": 54.79999923706055, "alt": 234}}
        self.assertSameAfterDumpsAndLoads(v)

    def test_loads_exception(self):
        self.assertRaises(DecodingError, lambda: loads(b'\x1F'))
        self.assertRaises(DecodingError, lambda: loads(b'\x00\x01'))
        self.assertRaises(DecodingError, lambda: loads(b'\x00\x01\xFF'))
        self.assertRaises(DecodingError, lambda: loads(b'\x81\xFF'))

    def test_loads(self):
        a = loads(b'\x0B\x03\x04name\x84land\x0Boperator_id\x84dupa\x0Aparameters\x0B\x03\x03lat\x09B4\xeb\x85\x03lon\x09B[33\x03alt\x09Cj\x00\x00')
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
