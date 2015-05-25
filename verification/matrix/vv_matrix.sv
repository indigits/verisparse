`include "verisparse.svh"
`ifndef MATRIX_PACKAGE
`define MATRIX_PACKAGE
package vs_matrix;
import verisparse::*;
class Matrix #(int Q=15);

    static const int FRACTION_BITS = Q;
    static const int INTEGER_BITS = 31 - Q;
    static const int FLOAT_TO_FIXED_FACTOR = (1 << Q);
    static const real FIXED_TO_FLOAT_FACTOR = 1.0 / real'(FLOAT_TO_FIXED_FACTOR);
    static const int FRACTION_MASK = (FLOAT_TO_FIXED_FACTOR - 1);

    //! Number of rows in matrix
    local int m_rows;
    //! Number of columns in matrix
    local int m_cols;
    //! Data for matrix
    local int m_data[];

    /******************************************
     *
     *      Basic functions
     *
     ******************************************/

    function int num_rows();
        return m_rows;
    endfunction

    function int num_cols();
        return m_cols;
    endfunction


    function int size();
        return m_rows * m_cols;
    endfunction

    function bit is_row();
        return m_rows == 1;
    endfunction

    function bit is_col();
        return m_cols == 1;
    endfunction

    function bit is_scalar();
        return this.size() == 1;
    endfunction

    function bit is_vector();
        return (m_rows == 1)^(m_cols == 1);
    endfunction


    function bit is_empty();
        return this.size() == 0;
    endfunction

    function bit is_square();
        return m_rows == m_cols;
    endfunction

    function int cell_to_index(int r, int c);
        return c*m_rows + r;
    endfunction

    function void index_to_cell(int index, ref int r, ref int c);
        c = index / m_rows;
        r = index - c * m_rows;
    endfunction

    function int get(int r, int c);
        int index = this.cell_to_index(r, c);
        return m_data[index];
    endfunction

    function void set(int r, int c, int value);
        int index = this.cell_to_index(r, c);
        m_data[index] = value;
    endfunction

    function int smaller_dim();
        return m_rows > m_cols? m_cols : m_rows;
    endfunction

    function int larger_dim();
        return m_rows < m_cols? m_cols : m_rows;
    endfunction

    function bit reshape(int r, int c);
        int new_size = r * c;
        if (new_size != size())
            return 0;
        m_rows = r;
        m_cols = c;
        return 1;
    endfunction

    function Matrix#(Q) clone();
        Matrix#(Q) m = new(m_rows, m_cols);
        int n = size();
        for (int i=0;i < n ; ++i) 
            m.m_data[i] = m_data[i];
        return m;
    endfunction

    /******************************************
     *
     *      Creation functions
     *
     ******************************************/


    function new(int rows, int cols);
        int size;
        m_rows = rows;
        m_cols = cols;
        size = rows * cols;
        m_data = new[size];
    endfunction

    static function Matrix#(Q) from_scalar(int scalar);
        Matrix#(Q) m = new(1, 1);
        m.m_data[0] = scalar;
        return m;
    endfunction

    static function Matrix#(Q) zeros(int rows, int cols);
        Matrix#(Q) m = new(rows, cols);
        int n  = m.size();
        for (int i=0; i < n; ++i)
            m.m_data[i] = 0;
        return m;
    endfunction

    static function Matrix#(Q) ones(int rows, int cols);
        Matrix#(Q) m = new(rows, cols);
        int n  = m.size();
        int one = 1 << Q;
        for (int i=0; i < n; ++i)
            m.m_data[i] = one;
        return m;
    endfunction

    static function Matrix#(Q) identity(int rows, int cols);
        Matrix#(Q) m = zeros(rows, cols);
        int n  = m.smaller_dim();
        int one = 1 << Q;
        for (int i=0; i < n; ++i)
            m.m_data[m.cell_to_index(i, i)] = one;
        return m;
    endfunction

    static function Matrix#(Q) unit_vector(int length, int dim);
        Matrix#(Q) m = zeros(length, 1);
        int one = 1 << Q;
        m.m_data[dim] = one;
        return m;
    endfunction

    static function Matrix#(Q) from_array_cw(int rows, int cols, 
        ref int arr[]);
        Matrix#(Q) m = new(rows, cols);
        int n1  = m.size();
        int n2 = arr.size();
        int n = n1 > n2 ? n2 : n1;
        for (int i=0; i < n; ++i)
            m.m_data[i] = arr[i];
        return m;
    endfunction

    static function Matrix#(Q) from_array_rw(int rows, int cols, 
        ref int arr[]);
        Matrix#(Q) m = new(rows, cols);
        int n1  = m.size();
        int n2 = arr.size();
        int n = n1 > n2 ? n2 : n1;
        int i=0;
        int index;
        for (int r=0; r < rows; ++r)
        begin
            index = m.cell_to_index(r,0);
            for (int c=0; c < cols; ++c)
            begin
                m.m_data[index] = arr[i];
                ++i;
                index = index + rows;
                if (i == n) return m;
            end
        end
        return m;
    endfunction

    static function Matrix#(Q) from_real_arr_rw(int rows, int cols, 
        ref real arr[]);
        Matrix#(Q) m = new(rows, cols);
        int n1  = m.size();
        int n2 = arr.size();
        int n = n1 > n2 ? n2 : n1;
        int i=0;
        int index;
        for (int r=0; r < rows; ++r)
        begin
            index = m.cell_to_index(r,0);
            for (int c=0; c < cols; ++c)
            begin
                m.m_data[index] = int'(arr[i] * FLOAT_TO_FIXED_FACTOR);
                ++i;
                index = index + rows;
                if (i == n) return m;
            end
        end
        return m;
    endfunction

    static function Matrix#(Q) from_byte_array_cw(int rows, int cols, 
        ref byte unsigned arr[]);
        Matrix#(Q) m = new(rows, cols);
        int n1  = m.size();
        int n2 = arr.size() / 4;
        int n = n1 > n2 ? n2 : n1;
        int i=0;
        int index = 0;
        byte unsigned b0, b1, b2, b3;
        for (int c=0; c < cols; ++c)
        begin
            for (int r=0; r < rows; ++r)
            begin
                b3 = arr[i++];
                b2 = arr[i++];
                b1 = arr[i++];
                b0 = arr[i++];
                m.m_data[index] = {b3, b2, b1, b0};
                //$display("%d ", m.m_data[index]);
                index = index + 1;
                if (index == n) return m;
            end
        end
        return m;
    endfunction

    static function Matrix#(Q) from_data(int rows, int cols, 
        ref int data[]);
        Matrix#(Q) m = new(rows, cols);
        int n1  = m.size();
        int n2 = data.size();
        int n = n1 > n2 ? n2 : n1;
        for (int i=0; i < n; ++i)
            m.m_data[i] = data[i];
        return m;
    endfunction

    /******************************************
     *
     *      Export functions
     *
     ******************************************/
    function verisparse::int_arr_t to_array();
        return m_data;
    endfunction

    function verisparse::real_arr_t to_real_array();
        int n  = this.size();
        verisparse::real_arr_t result= new[n];
        for (int i=0; i  < n; ++i)
            result[i] = real'(m_data[i]) * FIXED_TO_FLOAT_FACTOR;
        return result;
    endfunction

    function uint8_arr_t to_byte_array_cw();
        int n  = size();
        int bytes = n*4;
        uint8_arr_t result = new[bytes];
        int i=0;
        int j = 0;
        int value;
        byte unsigned b0, b1, b2, b3;
        for (int i=0; i < n; ++i) begin
            value = m_data[i];
            b3 = value[31:24];
            b2 = value[23:16];
            b1 = value[15:8];
            b0 = value[7:0];
            result[j++] = b3;
            result[j++] = b2;
            result[j++] = b1;
            result[j++] = b0;
        end
        return result;
    endfunction

    /******************************************
     *
     *      Operator functions
     *
     ******************************************/
    function Matrix#(Q) uminus();
        Matrix#(Q) m = new(m_rows, m_cols);
        int n = size();
        for (int i=0;i < n ; ++i) 
            m.m_data[i] = -m_data[i];
        return m;
    endfunction

    function Matrix#(Q) add(ref Matrix#(Q) other);
        Matrix#(Q) m = new(m_rows, m_cols);
        int n = size();
        for (int i=0;i < n ; ++i) 
            m.m_data[i] = m_data[i] + other.m_data[i];
        return m;
    endfunction

    function Matrix#(Q) sub(ref Matrix#(Q) other);
        Matrix#(Q) m = new(m_rows, m_cols);
        int n = size();
        for (int i=0;i < n ; ++i) 
            m.m_data[i] = m_data[i] - other.m_data[i];
        return m;
    endfunction

    function bit eq(ref Matrix#(Q) other);
        int n = size();
        for (int i=0;i < n ; ++i) 
            if (m_data[i] != other.m_data[i])
                return 0;
        return 1;
    endfunction

    function Matrix#(Q) transpose();
        Matrix#(Q) m = new(m_cols, m_rows);
        for (int c=0; c < m_cols; ++c)
            for (int r=0; r < m_rows; ++r)
                m.set(c, r, get(r, c));
        return m;
    endfunction

    function Matrix#(Q) mul(ref Matrix#(Q) other);
        int rows = m_rows;
        int cols = other.m_cols;
        int n = m_cols;
        Matrix#(Q) m = new(rows, cols);
        for (int r=0; r < rows; ++r)
            for (int c=0; c < cols; ++c) begin
                longint sum = 0;
                for (int j=0; j < n; ++j) begin
                    int v1 = get(r, j);
                    int v2 = other.get(j, c);
                    longint prod = longint'(v1 * v2);
                    sum += prod;
                end
                // scale down
                sum = sum >> Q;
                m.set(r, c, int'(sum));
            end
        return m;
    endfunction

    function int inner_product(ref Matrix#(Q) other);
        longint sum = 0;
        int n = this.size;
        assert (this.is_col)
        else begin 
            $fatal("left is not column vector");
            return 0;
        end
        assert (other.is_col)
        else begin 
            $fatal("right is not column vector");
            return 0;
        end
        assert (this.m_rows == other.m_rows) 
        else begin 
            $fatal("Vectors are not of same size");
            return 0;
        end
        for (int j=0; j < n; ++j) begin
            int v1 = m_data[j];
            int v2 = other.m_data[j];
            longint prod = longint'(v1 * v2);
            sum += prod;
        end
        // scale down
        sum = sum >> Q;
        // type cast and return
        return int'(sum);
    endfunction 

    /******************************************
     *
     *      Extraction functions
     *
     ******************************************/
    function Matrix#(Q) sub_matrix(int r, int c, int rows, int cols);
        Matrix#(Q) m = new(rows, cols);
        for (int rr=0; rr< rows; ++rr)
            for (int cc=0; cc<cols; ++cc)
                m.set(rr, cc, this.get(rr+r, cc+c));
        return m;
    endfunction

    /******************************************
     *
     *      Debugging functions
     *
     ******************************************/

    function void print();
        int index;
        int value;
        string value_str;
        for (int r=0; r<m_rows; ++r)
        begin
            index = cell_to_index(r,0);
            for(int c=0; c<m_cols; ++c)
            begin
                value = m_data[index];
                fixed_to_string(value, value_str);
                $write("%s ", value_str);
                index = index + m_rows;
            end
            $write("\n");
        end
        $write("\n");
    endfunction


    static function fixed_to_string(int value, output string result);
        string sgn_str, int_str, frac_str;
        bit[30 - Q: 0] integral;
        int fraction;
        bit sgn = value[31];
        if (sgn) value = -value;
        sgn_str = sgn ? "-"  : ""; 
        fraction = value & FRACTION_MASK;
        integral = value >> Q;
        int_str.itoa(integral);
        fraction = (fraction*10000)>> Q;
        if (fraction != 0) begin
            $sformat(frac_str, "%04d", fraction);
            result = {sgn_str, int_str, ".", frac_str};
        end
        else result = {sgn_str, int_str};

    endfunction

    static function int real_to_fixed(real value);
        return  int'(value * FLOAT_TO_FIXED_FACTOR);  
    endfunction

    static function real fixed_to_real(int value);
        return  real'(value) * FIXED_TO_FLOAT_FACTOR;  
    endfunction

endclass
typedef Matrix#(0) MatrixInt;
typedef Matrix#(15) MatrixQ15;
typedef Matrix#(16) MatrixQ16;
endpackage
`endif // MATRIX_PACKAGE

