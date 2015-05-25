`ifndef VS_LOGGER
`define VS_LOGGER

`define ASSERT_INFO(condition,message)\
    assert ((condition)) else $info((message))

`define ASSERT_WARNING(condition,message)\
    assert ((condition)) else $warning((message))

`define ASSERT_ERROR(condition,message)\
    assert ((condition)) else $error((message))

`define ASSERT_FATAL(condition,message)\
    assert ((condition)) else $fatal((message))


`define ASSERT_EQ_INFO(a, b,message)\
    assert ((a) == (b)) else $info((message))

`define ASSERT_EQ_WARNING(a, b,message)\
    assert ((a) == (b)) else $warning((message))

`define ASSERT_EQ_ERROR(a, b,message)\
    assert ((a) == (b)) else $error((message))

`define ASSERT_EQ_FATAL(a, b,message)\
    assert ((a) == (b)) else $fatal((message))

`define TEST_CONDITION(testcase, condition)\
    assert((condition)) $display("%s", {"PASSED: ", (testcase)});\
    else $error((testcase)) 

`define TEST_EQUAL(testcase, a, b)\
    assert((a) == (b)) $display("%s", {"PASSED: ", (testcase)});\
    else $error((testcase)) // TODO display a, b 

`define TEST_SET_START\
    int num_success = 0; int num_failure = 0;

`define TEST_SET_CONDITION(condition)\
    assert(condition) ++num_success;\
    else ++num_failure

`define TEST_SET_EQUAL(a, b)\
    assert((a) == (b)) ++num_success;\
    else ++num_failure

`define TEST_SET_APPROX_EQ_TH(a, b, threshold)\
    assert((  ((a) > (b)) ? ((a) - (b)) : ((b) - (a)) )  < threshold ) ++num_success;\
    else ++num_failure

`define TEST_SET_SUMMARIZE(testset)\
    if (num_failure == 0) $display("PASSED: %s: %d", (testset), num_success);\
    else begin $error((testset)); $display("Passed: %d, Failed: %d", num_success, num_failure); end

`endif // VS_LOGGER

