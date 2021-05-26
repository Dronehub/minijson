import unittest
from minijson import dumps, loads, dumps_object, loads_object, EncodingError, DecodingError


class TestMiniJSON(unittest.TestCase):

    def assertSameAfterDumpsAndLoads(self, c):
        self.assertEqual(loads(dumps(c)), c)

    def test_short_nonstring_key_dicts(self):
        a = {}
        for i in range(20):
            a[i] = i
        self.assertSameAfterDumpsAndLoads(a)
        a = {}
        for i in range(300):
            a[i] = i
        self.assertSameAfterDumpsAndLoads(a)
        for i in range(700000):
            a[i] = i
        self.assertSameAfterDumpsAndLoads(a)

    def test_string(self):
        a = 'test'
        b = 't'*128
        c = 't'*65535
        d = 't'*128342
        self.assertSameAfterDumpsAndLoads(a)
        self.assertSameAfterDumpsAndLoads(b)
        self.assertSameAfterDumpsAndLoads(c)
        self.assertSameAfterDumpsAndLoads(d)

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
        for i in range(0xFFFFF):
            a[str(i)] = i*2
        self.assertSameAfterDumpsAndLoads(a)
        a = []
        for i in range(65535):
            a.append(i)
        self.assertSameAfterDumpsAndLoads(a)
        a = []
        for i in range(0xFFFFFF):
            a.append(i*2)
        self.assertSameAfterDumpsAndLoads(a)

    def test_negatives(self):
        self.assertSameAfterDumpsAndLoads(-1)
        self.assertSameAfterDumpsAndLoads(-259)
        self.assertSameAfterDumpsAndLoads(-0x7FFF)
        self.assertSameAfterDumpsAndLoads(-0xFFFF)

    def test_dumps(self):
        v = {"name": "land", "operator_id": "dupa", "parameters":
            {"lat": 45.22999954223633, "lon": 54.79999923706055, "alt": 234}}
        self.assertSameAfterDumpsAndLoads(v)

    def test_loads_exception(self):
        b = b'\x1F'
        self.assertRaises(DecodingError, lambda: loads(b))

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
