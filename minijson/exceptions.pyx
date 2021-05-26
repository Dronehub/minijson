class MiniJSONError(ValueError):
    """Base class for MiniJSON errors"""
    pass

class EncodingError(MiniJSONError):
    """Error during encoding"""
    pass

class DecodingError(MiniJSONError):
    """Error during decoding"""
    pass
