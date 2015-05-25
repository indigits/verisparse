`include "verisparse.svp"
`include "verification/vv_logger.svh"

// local imports
import vs_matrix::*;
import vs_logger::*;
import vs_util::*;
// test module for CS matrix
module test_vv_matrix;

    initial begin
        MatrixInt m;
        $display("Testing matrix");
        m = new(4, 2);
        $display("Matrix size: %d", m.size());
        `TEST_CONDITION("Size", m.size() == 8);
        test_basics();
        test_ones();
        test_from_arr_rw();
        test_from_real_arr_rw();
        test_identity();
        test_index();
        test_to_arr();
        test_sum();
        test_sub();
        test_eq();
        test_from_scalar();
        test_mul_1();
        test_mul_2();
        test_mul_3();
        test_sub_matrix();
        test_from_data();
        test_load_dict_bin();
        test_to_byte_array_cw();
        test_inner_product();
        //test_fixed_point();
        $display("Testing completed.");

    end

    function automatic void test_basics;
        MatrixInt m = new(3, 4);
        int v;
        `TEST_EQUAL("Basics", m.size(), 12);
        `TEST_EQUAL("Basics", m.num_rows(), 3);
        `TEST_EQUAL("Basics", m.num_cols(), 4);
        `TEST_CONDITION("Basics", !m.is_row());        
        `TEST_EQUAL("Basics", m.smaller_dim(), 3);
        `TEST_EQUAL("Basics", m.larger_dim(), 4);
        v = m.get(0, 0);
        `TEST_EQUAL("Basics", v, 0);
    endfunction

    function automatic void test_ones();
        MatrixInt m;
        MatrixQ15 m2;
        `TEST_SET_START
        m = MatrixInt::ones(4, 4);
        for (int r=0; r < 4; ++r)
            for (int c=0; c < 4; ++c)
                `TEST_SET_EQUAL(m.get(r, c), 1);
        m2 = MatrixQ15::ones(4, 4);
        for (int r=0; r < 4; ++r)
            for (int c=0; c < 4; ++c)
                `TEST_SET_EQUAL(m2.get(r, c), 1<<15);
        `TEST_SET_SUMMARIZE("Ones")
    endfunction

    function automatic void test_from_arr_rw();
        `TEST_SET_START
        MatrixInt m;
        int arr[] = { 1, 2, 3, 4,
        5 , 6 , 7, 8};
        int index = 0;
        m = MatrixInt::from_array_rw(2,4, arr);
        for (int r=0; r < 2; ++r)
            for (int c=0; c < 4; ++c)
            begin
                `TEST_SET_EQUAL(m.get(r, c), arr[index]);
                ++index;
            end
        `TEST_SET_SUMMARIZE("from_arr_rw")
    endfunction

    function automatic void test_from_real_arr_rw();
        MatrixQ15 m;
        `TEST_SET_START
        real arr[] = { 1.5, 2.6, 3.9, 4.1,
        5.0 , 6.2 , 7.7, 8.3};
        int index = 0;
        m = MatrixQ15::from_real_arr_rw(2,4, arr);
        for (int r=0; r < 2; ++r)
            for (int c=0; c < 4; ++c)
            begin
                `TEST_SET_EQUAL(m.get(r, c), MatrixQ15::real_to_fixed(arr[index]));
                ++index;
            end
        `TEST_SET_SUMMARIZE("from_real_arr_rw")
    endfunction

    function automatic void test_identity();
        MatrixQ15 m;
        `TEST_SET_START
        m = MatrixQ15::identity(3,4);
        for (int r=0; r < 3; ++r)
            for (int c=0; c < 4; ++c)
            begin
                if (r == c) `TEST_SET_EQUAL(m.get(r, c), MatrixQ15::real_to_fixed(1.0));
                else `TEST_SET_EQUAL(m.get(r, c), 0);
            end
        `TEST_SET_SUMMARIZE("identity")
    endfunction

    function automatic void test_index();
        verisparse::int_arr_t arr = Range::int_range(1, 18, 2);
        MatrixInt m = MatrixInt::from_array_rw(2, 4, arr);
        `TEST_SET_START
        `TEST_SET_EQUAL(m.get(0, 0), 1);
        `TEST_SET_EQUAL(m.get(0, 1), 3);
        `TEST_SET_EQUAL(m.get(0, 2), 5);
        `TEST_SET_EQUAL(m.get(0, 3), 7);
        `TEST_SET_EQUAL(m.get(1, 0), 9);
        `TEST_SET_EQUAL(m.get(1, 1), 11);
        `TEST_SET_EQUAL(m.get(1, 2), 13);
        `TEST_SET_EQUAL(m.get(1, 3), 15);
        `TEST_SET_SUMMARIZE("index")
    endfunction 

    function automatic void test_to_arr();
        verisparse::int_arr_t arr = Range::int_range(1, 18, 2);
        MatrixInt m = MatrixInt::from_array_cw(2, 4, arr);
        verisparse::int_arr_t arr2 = m.to_array();
        int n = arr2.size;
        `TEST_SET_START
        for (int i=0; i< n ; ++i) begin
            `TEST_SET_EQUAL(arr[i], arr2[i]);
        end
        m = MatrixInt::from_array_rw(2, 4, arr);
        m = m.transpose();
        arr2 = m.to_array();
        for (int i=0; i< n ; ++i) begin
            `TEST_SET_EQUAL(arr[i], arr2[i]);
        end
        `TEST_SET_SUMMARIZE("to_array")
    endfunction 

    function automatic void test_sum();
        MatrixInt m = MatrixInt::ones(4, 2);
        MatrixInt m2 = m.add(m);
        `TEST_SET_START
        for (int r=0; r < 4; ++r)
            for (int c=0; c < 2; ++c)
            `TEST_SET_EQUAL(m2.get(r, c), 2);
        `TEST_SET_SUMMARIZE("sum")
        //m.print();
        //m2.print();
    endfunction 

    function automatic void test_sub();
        MatrixInt m1 = MatrixInt::ones(4, 2);
        MatrixInt m2 = MatrixInt::zeros(4, 2);
        MatrixInt m3 = m2.sub(m1);
        `TEST_SET_START
        for (int r=0; r < 4; ++r)
            for (int c=0; c < 2; ++c)
            `TEST_SET_EQUAL(m3.get(r, c), -1);
        `TEST_SET_SUMMARIZE("sub")
        //m.print();
        //m2.print();
    endfunction

    function automatic void test_eq();
        verisparse::int_arr_t arr = Range::int_range(1, 18, 2);
        MatrixInt m1 = MatrixInt::from_array_cw(4, 2, arr);
        MatrixInt m2 = MatrixInt::from_array_cw(4, 2, arr);
        `TEST_SET_START
        `TEST_SET_CONDITION(m1.eq(m2));
        `TEST_SET_SUMMARIZE("eq")
    endfunction

    function automatic void test_from_scalar();
        MatrixInt m = MatrixInt::from_scalar(10);
        `TEST_SET_START
        `TEST_SET_EQUAL(m.get(0, 0), 10);
        `TEST_SET_EQUAL(m.size(), 1);
        `TEST_SET_CONDITION(m.is_scalar());
        `TEST_SET_CONDITION(!m.is_vector());
        `TEST_SET_SUMMARIZE("from_scalar")
    endfunction

    function automatic void test_mul_1();
        verisparse::int_arr_t arr = Range::int_range(0, 4);
        MatrixInt m1 = MatrixInt::from_array_rw(2,2, arr);
        MatrixInt m2 = MatrixInt::from_array_rw(2,2, arr);
        MatrixInt m3 = m1.mul(m2);
        verisparse::int_arr_t arr2 = {2, 3, 6, 11};
        MatrixInt m4 = MatrixInt::from_array_rw(2,2, arr2);
        `TEST_SET_START
        `TEST_SET_CONDITION(m4.eq(m3));
        `TEST_SET_SUMMARIZE("mul 1")
        // m1.print();
        // m2.print();
        // m3.print();
        // m4.print();
    endfunction

    function automatic void test_mul_2();
        verisparse::int_arr_t arr = Range::int_range(0, 400);
        MatrixInt m1 = MatrixInt::from_array_rw(10,20, arr);
        MatrixInt m2 = MatrixInt::from_array_rw(20,5, arr);
        MatrixInt m3 = m1.mul(m2);
        verisparse::int_arr_t arr2 = {
            12350, 12540, 12730, 12920, 13110,
           31350, 31940, 32530, 33120, 33710,
           50350, 51340, 52330, 53320, 54310,
           69350, 70740, 72130, 73520, 74910,
           88350, 90140, 91930, 93720, 95510,
          107350, 109540, 111730, 113920, 116110,
          126350, 128940, 131530, 134120, 136710,
          145350, 148340, 151330, 154320, 157310,
          164350, 167740, 171130, 174520, 177910,
          183350, 187140, 190930, 194720, 198510
        };
        MatrixInt m4 = MatrixInt::from_array_rw(10,5, arr2);
        `TEST_SET_START
        `TEST_SET_CONDITION(m4.eq(m3));
        `TEST_SET_SUMMARIZE("mul 2")
        // m1.print();
        // m2.print();
        // m3.print();
        // m4.print();
    endfunction

    function automatic void test_mul_3();
        verisparse::real_arr_t arr = {1.5, 2.5, 3.5, 4.5};
        MatrixQ15 m1 = MatrixQ15::from_real_arr_rw(2, 2, arr);
        MatrixQ15 m2 = MatrixQ15::from_real_arr_rw(2, 2, arr);
        MatrixQ15 m3 = m1.mul(m2);
        verisparse::real_arr_t arr2 = {11, 15, 21, 29};
        MatrixQ15 m4 = MatrixQ15::from_real_arr_rw(2, 2, arr2);
        `TEST_SET_START
        `TEST_SET_CONDITION(m4.eq(m3));
        `TEST_SET_SUMMARIZE("mul 3")
        // m1.print();
        // m2.print();
        // m3.print();
        // m4.print();
    endfunction
    function automatic void test_fixed_point();
        int a, b, c;
        longint x, y;
        a = 1 << 30;
        $display("a: %d, %b", a, a);
        x = 8 * a;
        $display("x: %d, %b", x, x);
        b = 8 * a;
        $display("b: %d, %b", b, b);
    endfunction

    function automatic void test_sub_matrix();
        verisparse::int_arr_t arr = Range::int_range(0, 1000);
        MatrixInt m1 = MatrixInt::from_array_rw(20,20, arr);
        MatrixInt m2 = m1.sub_matrix(0, 0, 10, 10);
        `TEST_SET_START
        `TEST_SET_EQUAL(m2.size(), 100);
        `TEST_SET_EQUAL(m2.get(0, 0), 0);
        `TEST_SET_EQUAL(m2.get(9, 9), 189);
        `TEST_SET_SUMMARIZE("sub_matrix")
    endfunction

    function  automatic void test_from_data();
        verisparse::int_arr_t arr = Range::int_range(0, 1000);
        MatrixInt m1 = MatrixInt::from_array_cw(20,20, arr);
        MatrixInt m2;
        verisparse::int_arr_t data;
        `TEST_SET_START
        data = m1.to_array();
        m2 = MatrixInt::from_data(10, 10, data);
        `TEST_SET_EQUAL(m2.size(), 100);
        `TEST_SET_EQUAL(m2.get(0, 0), 0);
        `TEST_SET_EQUAL(m2.get(9, 9), 99);
        `TEST_SET_SUMMARIZE("from_data")
    endfunction

    function automatic void test_load_dict_bin();
        // loading data from dict.bin
        MatrixQ15 m;
        MatrixInt m2;
        verisparse::int_arr_t data;
        integer dict_file_id;
        integer dict_byte_count;
        byte unsigned dict_buffer[0:(1<<DICTIONARY_ADDR_WIDTH)-1];
        byte unsigned dict_buffer2[] = new[(1<<DICTIONARY_ADDR_WIDTH)];
        `TEST_SET_START
        dict_file_id = $fopen("dict.bin", "rb");
        dict_byte_count = $fread(dict_buffer, dict_file_id);
        //$display("Number of bytes read: %d", dict_byte_count);
        for (int i=0; i < dict_byte_count; ++i)
            dict_buffer2[i] = dict_buffer[i];
        $fclose(dict_file_id);
        m = MatrixQ15::from_byte_array_cw(SIGNAL_SIZE_DEFAULT, 
            DICTIONARY_SIZE_DEFAULT, dict_buffer2);
        m = m.sub_matrix(0, 0, 10, 10);
        data = m.to_array();
        m2 = MatrixInt::from_data(10, 10, data);
        `TEST_SET_EQUAL(m2.get(0, 0), 2933);
        `TEST_SET_EQUAL(m2.get(1, 0), -255);
        `TEST_SET_EQUAL(m2.get(0, 1), -5403);
        `TEST_SET_SUMMARIZE("load_dict_bin")
    endfunction 


    function automatic void test_to_byte_array_cw();
        verisparse::int_arr_t arr = Range::int_range(0, 100);
        MatrixInt m = MatrixInt::from_array_cw(4, 4, arr);
        uint8_arr_t arr2 = m.to_byte_array_cw();
        int n = arr2.size;
        `TEST_SET_START
        for (int i=0; i<n; ++i) begin
            int j = i & 3;
            if (j == 3)
                `TEST_SET_EQUAL(arr2[i], i >> 2);
            else
                `TEST_SET_EQUAL(arr2[i], 0);
        end
        `TEST_SET_SUMMARIZE("to_byte_array_cw")
    endfunction 

    function automatic void test_inner_product();
        verisparse::real_arr_t arr = {0, 1, 2, 3};
        MatrixQ15 m1 = MatrixQ15::from_real_arr_rw(4, 1, arr);
        MatrixQ15 m2 = MatrixQ15::from_real_arr_rw(4, 1, arr);
        int prod = m1.inner_product(m2);
        `TEST_SET_START
        `TEST_SET_EQUAL(prod, 14<<15);
        `TEST_SET_SUMMARIZE("inner_product")
    endfunction 

endmodule
