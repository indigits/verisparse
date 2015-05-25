import "DPI-C" function string getenv(input string env_name);

module test_dpi;

    integer file_id;

    initial begin
        $write("env = %s\n", {getenv("HOME"), "/FileName"});
        file_id = $fopen("x.bin", "rb");
        $fclose(file_id);
    end
endmodule

