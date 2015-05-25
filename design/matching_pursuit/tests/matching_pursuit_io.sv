
`include "verisparse.svp"
module matching_pursuit_io(input clock,
        input resetN);

    integer x_file_id;
    integer y_file_id;
    integer dict_file_id;

    integer x_byte_count;
    integer y_byte_count;
    integer dict_byte_count;

    byte x_buffer[0:(1<<REPRESENTATION_ADDR_WIDTH) - 1];
    byte y_buffer[0:(1<<SIGNAL_ADDR_WIDTH) - 1];
    byte dict_buffer[0:(1<<DICTIONARY_ADDR_WIDTH) - 1];

    initial begin
        x_file_id = $fopen("x.bin", "rb");
        x_byte_count = $fread(x_buffer, x_file_id);
        $fclose(x_file_id);

        // load signal into RAM
        y_file_id = $fopen("y.bin", "rb");
        y_byte_count = $fread(y_buffer, y_file_id);
        $fclose(y_file_id);

        // Load dictionary into RAM
        dict_file_id = $fopen("dict.bin", "rb");
        dict_byte_count = $fread(dict_buffer, dict_file_id);
        $fclose(dict_file_id);


        // Load data into RAMs.
        for (int i=0;i < y_byte_count; i = i + 1) begin
                PE.y_ram.ram[i] = y_buffer[i];
        end
        for (int i=0;i < dict_byte_count; ++i) begin
                PE.dict_ram.ram[i] = dict_buffer[i];
        end
        for (int i=0;i < (1<<REPRESENTATION_ADDR_WIDTH) ; ++i) begin
                PE.x_ram.ram[i] = 0;
        end
    end

endmodule
