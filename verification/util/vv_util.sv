`include "verisparse.svh"
`ifndef VS_UTIL
`define VS_UTIL

package  vs_util;
import verisparse::*;

class Range;
    static function verisparse::int_arr_t int_range(int start, int stop, int step=1);
        int n = (stop-start) / step;
        int index = 0;
        verisparse::int_arr_t result = new[n];
        int v = start;
        while (v < stop) begin
            result[index] = v;
            v = v + step;
            index = index + 1;
        end
        return result;
    endfunction

endclass

function automatic print_uint8_array(ref uint8_arr_t data);
    int n = data.size;
    for (int i=0; i<n; ++i) begin
        if ((i & 3) == 0) $write("  ");
        if ((i & 31) == 0) $write("\n");
        $write("%02x ", data[i]);
    end
    $write("\n");    
endfunction

endpackage

`endif // VS_UTIL



