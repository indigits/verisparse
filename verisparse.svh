`ifndef VERISPARSE_DEFS
`define VERISPARSE_DEFS
package verisparse;

    // signed and unsigned integers
    typedef byte int8_t;
    typedef byte unsigned uint8_t;
    typedef shortint int16_t;
    typedef shortint unsigned uint16_t;
    typedef int int32_t;
    typedef int unsigned uint32_t;
    typedef longint int64_t;
    typedef longint unsigned uint64_t;
    typedef uint8_t pixel_sample_t;
    // We are using (15, 32) fixed point number system
    parameter FP_Q_DEFAULT = 15;
    parameter FP_N_DEFAULT = 32;
    // 32 bit fixed point number
    typedef int signed fp_32_t;
    // 64 bit fixed point number
    typedef longint signed fp_64_t;
    // array of integers
    typedef int int_arr_t[];
    // array of reals
    typedef real real_arr_t[];
    // array of signed 8 bit integers
    typedef int8_t int8_arr_t[];
    // array of signed 16 bit integers
    typedef int16_t int16_arr_t[];
    // array of signed 32 bit integers
    typedef int32_t int32_arr_t[];
    // array of signed 64 bit integers
    typedef int64_t int64_arr_t[];
    // array of unsigned bytes
    typedef uint8_t uint8_arr_t[];
    // array of unsigned shorts
    typedef uint16_t uint16_arr_t[];
    // array of unsigned 32 bit integers
    typedef uint32_t uint32_arr_t[];
    // array of unsigned 64-bit integers
    typedef uint64_t uint64_arr_t[];

    // Defaults for dimensions of various spaces
    parameter SIGNAL_SIZE_DEFAULT = 64;
    parameter DICTIONARY_SIZE_DEFAULT = 256;
    parameter SPARSITY_LEVEL_DEFAULT = 4;

    parameter SIGNAL_ADDR_WIDTH = 10;
    parameter REPRESENTATION_ADDR_WIDTH = 12;
    parameter DICTIONARY_ADDR_WIDTH = 20;
    parameter DATA_BUS_WIDTH = 8;


    /**
    IEEE 32-bit floating point format
    */
    typedef struct packed {
        bit sign;
        bit [24:0] mantissa;
        bit[5:0] exponent;
    } ieee_float_32_t;


    typedef struct {
        logic write_enable;
        logic [REPRESENTATION_ADDR_WIDTH -1:0] read_addr;
        logic [REPRESENTATION_ADDR_WIDTH -1:0] write_addr;
        logic[DATA_BUS_WIDTH-1:0]  read_data;
        logic[DATA_BUS_WIDTH-1:0]  write_data;
    } pursuit_x_bus_t;

    typedef struct {
        logic write_enable;
        logic [SIGNAL_ADDR_WIDTH -1:0] read_addr;
        logic [SIGNAL_ADDR_WIDTH -1:0] write_addr;
        logic[DATA_BUS_WIDTH-1:0]  read_data;
        logic[DATA_BUS_WIDTH-1:0]  write_data;
    } pursuit_y_bus_t;

    typedef struct {
        logic write_enable;
        logic [DICTIONARY_ADDR_WIDTH -1:0] read_addr;
        logic [DICTIONARY_ADDR_WIDTH -1:0] write_addr;
        logic[DATA_BUS_WIDTH-1:0]  read_data;
        logic[DATA_BUS_WIDTH-1:0]  write_data;
    } pursuit_dict_bus_t;

    typedef struct {
        pursuit_x_bus_t x;
        pursuit_y_bus_t y;
        pursuit_dict_bus_t dict;
    } pursuit_bus_t;

endpackage
import verisparse::*;
`endif // VERISPARSE_DEFS





