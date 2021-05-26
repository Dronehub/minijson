import unittest
from minijson import dumps, loads, dumps_object, loads_object, EncodingError, DecodingError


class TestMiniJSON(unittest.TestCase):

    def test_lists(self):
        a = [1, 2, 3]
        b = dumps(a)
        c = loads(b)
        self.assertEqual(a, c)

        a = [None]*256
        self.assertRaises(EncodingError, lambda: dumps(a))

    def test_long_lists(self):
        a = [None]*17
        b = dumps(a)
        print('Encoded %s' % (b, ))
        c = loads(b)
        self.assertEqual(a, c)

    def test_long_dicts(self):
        a = {}
        for i in range(17):
            a[str(i)] = i
        b = dumps(a)
        c = loads(b)
        self.assertEqual(a, c)

    def test_exceptions(self):
        a = {}
        for i in range(65535):
            a[i] = i*2
        self.assertRaises(EncodingError, lambda: dumps(a))
        a = []
        for i in range(65535):
            a.append(i)
        self.assertRaises(EncodingError, lambda: dumps(a))

    def test_dumps(self):
        v = {"name": "land", "operator_id": "dupa", "parameters":
            {"lat": 45.22999954223633, "lon": 54.79999923706055, "alt": 234}}
        b = dumps(v)
        c = loads(b)
        self.assertEqual(v, c)

    def test_loads_exception(self):
        b = b'\x1A'
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
