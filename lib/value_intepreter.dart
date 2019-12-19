//import 'dart:typed_data';
//
//class ValueInterpreter {
//
//  /*
//   * Characteristic value format type uint8
//   */
//  final int FORMAT_UINT8 = 0x11;
//
//  /*
//   * Characteristic value format type uint16
//   */
//  final int FORMAT_UINT16 = 0x12;
//
//  /*
//   * Characteristic value format type uint32
//   */
//  final int FORMAT_UINT32 = 0x14;
//
//  /*
//   * Characteristic value format type sint8
//   */
//  final int FORMAT_SINT8 = 0x21;
//
//  /*
//   * Characteristic value format type sint16
//   */
//  final int FORMAT_SINT16 = 0x22;
//
//  /*
//   * Characteristic value format type sint32
//   */
//  final int FORMAT_SINT32 = 0x24;
//
//  /*
//   * Characteristic value format type sfloat (16-bit float)
//   */
//  final int FORMAT_SFLOAT = 0x32;
//
//  /*
//   * Characteristic value format type float (32-bit float)
//   */
//  final int FORMAT_FLOAT = 0x34;
//
//  /*
//   * Return the integer value interpreted from the passed byte array.
//   *
//   * <p>The formatType parameter determines how the value
//   * is to be interpreted. For example, setting formatType to
//   * {@link #FORMAT_UINT16} specifies that the first two bytes of the
//   * characteristic value at the given offset are interpreted to generate the
//   * return value.
//   *
//   * @param value The byte array from which to interpret value.
//   * @param formatType The format type used to interpret the value.
//   * @param offset Offset at which the integer value can be found.
//   * @return The value at a given offset or null if offset exceeds value size.
//   */
//
//  static int getIntValue(Uint8List value, int formatType, int offset) {
//    if ((offset + getTypeLen(formatType)) > value.length) {
//      RxBleLog.w(
//          "Int formatType (0x%x) is longer than remaining bytes (%d) - returning null",
//          formatType, value.length - offset
//      );
//      return null;
//    }
//
//    switch (formatType) {
//      case FORMAT_UINT8:
//        return unsignedByteToInt(value[offset]);
//
//      case FORMAT_UINT16:
//        return unsignedBytesToInt(value[offset], value[offset + 1]);
//
//      case FORMAT_UINT32:
//        return unsignedBytesToInt(value[offset], value[offset + 1],
//            value[offset + 2], value[offset + 3]);
//      case FORMAT_SINT8:
//        return unsignedToSigned(unsignedByteToInt(value[offset]), 8);
//
//      case FORMAT_SINT16:
//        return unsignedToSigned(unsignedBytesToInt(value[offset],
//            value[offset + 1]), 16);
//
//      case FORMAT_SINT32:
//        return unsignedToSigned(unsignedBytesToInt(value[offset],
//            value[offset + 1], value[offset + 2], value[offset + 3]), 32);
//      default:
//        RxBleLog.w(
//            "Passed an invalid integer formatType (0x%x) - returning null",
//            formatType);
//        return null;
//    }
//  }
//
//
/////
//  /*
//   * Returns the size of a give value type.
//   */
//  static int getTypeLen(int formatType) {
//    return formatType & 0xF;
//  }
//
//  /*
//   * Convert a signed byte to an unsigned int.
//   */
//  static int unsignedByteToInt(byte b) {
//    return b & 0xFF;
//  }
//
//  /*
//   * Convert signed bytes to a 16-bit unsigned int.
//   */
//  static int unsignedBytesToInt(byte b0, byte b1) {
//    return (unsignedByteToInt(b0) + (unsignedByteToInt(b1) << 8));
//  }
//
//  /*
//   * Convert signed bytes to a 32-bit unsigned int.
//   */
//  static int unsignedBytesToInt(byte b0, byte b1, byte b2, byte b3) {
//    return (unsignedByteToInt(b0) + (unsignedByteToInt(b1) << 8))
//        + (unsignedByteToInt(b2) << 16) + (unsignedByteToInt(b3) << 24);
//  }
//
//  /*
//   * Convert signed bytes to a 16-bit short float value.
//   */
//  static float bytesToFloat(byte b0, byte b1) {
//    int mantissa = unsignedToSigned(unsignedByteToInt(b0)
//        + ((unsignedByteToInt(b1) & 0x0F) << 8), 12);
//    int exponent = unsignedToSigned(unsignedByteToInt(b1) >> 4, 4);
//    return (float) (mantissa * Math.pow(10, exponent));
//  }
//
//  /*
//   * Convert signed bytes to a 32-bit short float value.
//   */
//  static float bytesToFloat(byte b0, byte b1, byte b2, byte b3) {
//    int mantissa = unsignedToSigned(unsignedByteToInt(b0)
//        + (unsignedByteToInt(b1) << 8)
//        + (unsignedByteToInt(b2) << 16), 24);
//    return (float) (mantissa * Math.pow(10, b3));
//  }
//
//  /*
//   * Convert an unsigned integer value to a two's-complement encoded
//   * signed value.
//   */
//  static int unsignedToSigned(int unsigned, int size) {
//    if ((unsigned & (1 << size - 1)) != 0) {
//      unsigned = -1 * ((1 << size - 1) - (unsigned & ((1 << size - 1) - 1)));
//    }
//    return unsigned;
//  }
//
//
//}