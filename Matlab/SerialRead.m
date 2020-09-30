choice_serial = 1; % serial port you connect, the choice of serial_ports
default = [3 4 1 1]; % default parameter choice
choice = default; % you can specific yourself;
format = '%d'; % scan format

% Do not change it
choice_baud_rate = [2400 4800 9600 11400 19200 28800 38400 57600 115200 128000];
choice_data_bits = [5 6 7 8];
choice_stop_bits = [1 1.5 2];
choice_check_sum = {'None';'Odd';'even'}; % cell array
serial_info = instrhwinfo('serial');
ports_name = serial_info.SerialPorts;
ports_name(contains(ports_name, 'cu.') |...
    ~contains(ports_name, 'usbserial')) = [];
ports_name

baud_rate = choice_baud_rate(choice(1));
data_bits = choice_data_bits(choice(2));
stop_bits = choice_stop_bits(choice(3));
check_sum = choice_check_sum{choice(4)}; % need to use '{}'
if exist('serial_com','var')
    fclose(serial_com);
end
serial_com = serial(ports_name{choice_serial});
set(serial_com, 'BaudRate', baud_rate, 'Parity', check_sum, 'DataBits',...
     data_bits, 'StopBits', stop_bits);
fopen(serial_com);
go_error = false;
raw_data = zeros(1,0);
while ~go_error
    try
        str_in = fscanf(serial_com);
        data = str2double(str_in);
        fprintf('%d\n',data);
        if ~isnan(data)
            raw_data = cat(2,raw_data, data);
        end
%         disp(data);
    catch ME
        go_error = true;
        getreport(ME);
    end
end
fclose(serial_com);



