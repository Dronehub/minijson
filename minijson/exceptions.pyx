class MiniJSONError(ValueError):
    """
    Base class for MiniJSON errors.

    Note that it inherits from :code:`ValueError`.
    """


class EncodingError(MiniJSONError):
    """Error during encoding"""


class DecodingError(MiniJSONError):
    """Error during decoding"""
