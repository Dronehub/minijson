MiniJSON specification
======================

MiniJSON is a binary encoding for a subset of JSON that:

* has no keys longer than 255 bytes UTF-8
* all keys are string

MiniJSON is bigger endian.

Type Value consists of:

* unsigned char value
* unsigned char * data

* If value's highest bit is turned on, then remains are a UTF-8 string
with len of (value & 0x7F)
* If value's two highest bits are 0100 or 0101, then four lowest bits encode the number of elements,
  and the four highest bits encode type of the object:
  * 0100 - a list
  * 0101 - an object
  Standard representation for an object or list follows,
  sans the element count.
* If value is zero, then next character is the length of the string followed by the string
* If value is 1, then next data is signed int 
* If value is 2, then next data is signed short
* If value is 3, then next data is signed char
* If value is 4, then next data is unsigned int
* If value is 5, then next data is unsigned short
* If value is 6, then next data is unsigned char
* If value is 7, then next data is number of elements of a list, 
 follows by Value of each element
* If value is 8, the value is a NULL
* If value is 9, then next element is a IEEE single
* If value is 10, then next element is a IEEE double
* If value is 11, then next element is amount of entries for
    an object, then there goes the length of the field name,
    followed by field name in UTF-8, and then goes the Value
    of the element
* If value is 12, then next data is unsigned int24
* If value is 13, then next data is an unsigned short representing the count
    of characters, and then these characters follow and are
    interpreted as a UTF-8 string
* If value is 14, then next data is an unsigned int representing the count
    of characters, and then these characters follow and are
* If value is 15, then next data is a unsigned short,
  and then a list follows of that many elements
* If value is 16, then next data is a unsigned int,
  and then a list follows of that many elements
* If value is 17, then next data is a unsigned short,
  and then an object follows of that many elements
* If value is 18, then next data is a unsigned int,
  and then an object follows of that many elements
