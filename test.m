%
% Copyright (c)
% 2022
% ISHII, Daisuke
%

%
% Script for combinatorial block instance generation.
%

specFilename = 'delay.json';

pictCommand = './pict';
pictFilename = 'delay_pict.txt';
pictResFilename = 'pict_out.txt';

%

conf = struct();
conf.VectorDim = 3;
conf.VectorSize = 3;
conf.TypeFloat = 'double';
conf.TypeInt = 'int8';
conf.TypeUint = 'uint8';
conf.TypeString = 'string';
conf.TypeBool = 'boolean';
conf.ValuesFloat = {realmin('double'), -10.1, -1.1, 0, 1.1, 2.3, realmax('double')};
conf.ValuesUint = {0, 1, 2, intmax('int8')};
conf.ValuesInt = {intmin('int8'), -10, -1, 0, 1, 2, intmax('int8')};
conf.ValuesString = {'', 'foo'};
conf.ValuesBool = {false, true};

%

parser = SpecParser();
parser = parser.parse(specFilename);
spec = parser.Spec;

blockType = spec.BlockType;

pr = PictPrinter(conf);
fid = fopen(pictFilename, 'w');
pr.print(fid, spec);
fclose(fid);

%

[st, cout] = system(sprintf('%s %s 2> /dev/null', pictCommand, pictFilename));
if st
    error('error in the PICT process');
end

cout = split(cout, newline);
%{
for i = 1:length(cout)
    td = split(cout{i}, sprintf('\t'));
    for j = 1:length(td)
        fprintf(1, ' %s', td{j});
    end
    fprintf(1, '\n');
end
%}

td0 = split(cout{1}, sprintf('\t'));
td = split(cout{2}, sprintf('\t'));
for j = 1:length(td0)
    fprintf(1, ' %s: %s\n', td0{j}, td{j});

    s = td0{j}(1);
    f = td0{j}(2);
    n = str2double(td0{j}(3));
    nm = td0{j}(5:end);

    if s == 'I'
        k = find(strcmp({spec.Input.Name}, nm), 1);
        if ~isempty(k)
            if f == 'M'
                spec.Input(k).MV = td{j};
            elseif f == 'D'
                spec.Input(k).DV = td{j};
            else % if f == 'V'
                spec.Input(k).V{n} = td{j};
            end
        else
            error(sprintf('cannot find entry for %s', td0{j}));
        end
    elseif s == 'O'
        k = find(strcmp({spec.Output.Name}, nm), 1);
        if ~isempty(k)
            if f == 'M'
                spec.Output(k).MV = td{j};
            elseif f == 'D'
                spec.Output(k).DV = td{j};
            else % if f == 'V'
                spec.Output(k).V{n} = td{j};
            end
        else
            error(sprintf('cannot find entry for %s', td0{j}));
        end
    elseif s == 'P'
        k = find(strcmp({spec.Param.Name}, nm), 1);
        if ~isempty(k)
            if f == 'M'
                spec.Param(k).MV = td{j};
            elseif f == 'D'
                spec.Param(k).DV = td{j};
            else % if f == 'V'
                spec.Param(k).V{n} = td{j};
            end
        else
            error(sprintf('cannot find entry for %s', td0{j}));
        end
    end
end

%

modelName = 'testModel';
testUnitName = sprintf('Test Unit (copied from %s)', modelName);
sbName = 'Inputs';

new_system(modelName);
open_system(modelName);

b = add_block('simulink/Discrete/Delay', [modelName '/Target']);
set(b, 'Position', [120 80 150 110]);

its = spec.Param;
for it = its
    if isempty(it.V)
        set(b, it.Name, it.DV);
    else
        set(b, it.Name, it.V{1});
    end
end

i = 1;
its = spec.Input;
for it = its
    if strcmp(it.DV, 'Disabled');
        continue
    end

    if isempty(it.Name)
        nm = sprintf('In%d', i);
    else
        nm = it.Name;
    end
    b = add_block('simulink/Sources/In1', [modelName '/' nm]);
    %set(b, 'Position', [35 88 65 102]);
    set(b, 'Position', [35, 44*i+44, 65, 44*i+58]);

    switch it.DV
        case 'T_float'
            ty = conf.TypeFloat;
        case 'T_int'
            ty = conf.TypeInt;
        case 'T_uint'
            ty = conf.TypeUint;
        case 'T_string'
            ty = conf.TypeString;
        case 'T_bool'
            ty = conf.TypeBool;
        otherwise
            ty = it.DV;
    end
    set(b, 'OutDataTypeStr', ty);

    if strcmp(it.MV, 'vector')
        set(b, 'PortDimensions', sprintf('%d', conf.VectorDim));
    end

    add_line(modelName, [sprintf('%s/1', nm)], [sprintf('Target/%d', i)], 'autorouting','smart');

    i = i + 1;
end

i = 1;
its = spec.Output;
for it = its
    if strcmp(it.DV, 'Disabled');
        continue
    end

    if isempty(it.Name)
        nm = sprintf('Out%d', i);
    else
        nm = it.Name;
    end
    b = add_block('simulink/Sinks/Out1', [modelName '/' nm]);
    %set(b, 'Position', [205 88 235 102]);
    set(b, 'Position', [205, 44*i+44, 235, 44*i+58]);

    switch it.DV
        case 'T_float'
            ty = conf.TypeFloat;
        case 'T_int'
            ty = conf.TypeInt;
        case 'T_uint'
            ty = conf.TypeUint;
        case 'T_string'
            ty = conf.TypeString;
        case 'T_bool'
            ty = conf.TypeBool;
        otherwise
            ty = it.DV;
    end
    set(b, 'OutDataTypeStr', ty);

    if strcmp(it.MV, 'vector')
        set(b, 'PortDimensions', sprintf('%d', conf.VectorDim));
    end

    add_line(modelName, [sprintf('Target/%d', i)], [sprintf('%s/1', nm)], 'autorouting','smart');

    i = i + 1;
end

%

ho = sldvharnessopts();
ho.modelRefHarness = false;
sldvmakeharness(modelName, '', ho);

close_system(modelName, 0);

harnessName = [modelName '_harness'];

%

[t, d, s, g] = signalbuilder([harnessName, '/', sbName]);
gName = g{length(g)};

ts = [0, 1, 2];
ds = [1, 1, 1];

fprintf('\nInput:\ntime:');
fprintf('\t%g', ts);
fprintf('\t* SampleTime\n');

i = 1;
j = 1;
its = spec.Input;
for it = its
    if strcmp(it.DV, 'Disabled');
        continue
    end

    for j = 1:conf.VectorSize
        vi = str2double(it.V{j});
        switch it.DV
            case 'T_float'
                v = conf.ValuesFloat{vi};
            case 'T_int'
                v = conf.ValuesInt{vi};
            case 'T_uint'
                v = conf.ValuesUint{vi};
            case 'T_string'
                v = conf.ValuesString{vi};
            case 'T_bool'
                v = conf.ValuesBool{vi};
            otherwise
                error('unexpected branch');
        end

        signalbuilder([harnessName, '/', sbName], 'set', i + j - 1, gName, ts, double(v) * ds);

        fprintf('in(%d):', i+j-1);
        fprintf('\t%g', double(v) * ds);
        fprintf('\n');

        if ~strcmp(it.MV, 'vector')
            break
        end
    end

    i = i + j;
end

%
% Numerical simulation using Simulink.
%

set_param(harnessName, 'FastRestart','off');
set_param(harnessName, 'SimulationMode','normal');
set_param(harnessName, 'CovEnable', 'off');
set_param(harnessName, 'RecordCoverage', 'off');
phs = get_param([harnessName '/' testUnitName], 'PortHandles');
i = 1;
for it = spec.Output
    if strcmp(it.DV, 'Disabled');
        continue
    end

    o = phs.Outport(i);
    set(o, 'DataLogging','on');
    set(o, 'DataLoggingNameMode','Custom');
    set(o, 'DataLoggingName',['EncTest:' spec.Output(i).Name]);
    i = i + 1;
end

try
    simout = sim(harnessName, 'SignalLogging','on', 'SignalLoggingName','logsout');
catch e
    sprintf(2, 'error in simulation');
    rethrow(e);
end

% Get timeseries data.
ts = {};
for i = 1:length(spec.Output)
    if ~isempty(simout)
        if isa(simout, 'Simulink.SimulationOutput')
            logs = simout.get('logsout');
        else
            error('unexpected simout');
        end
        
        if isa(logs, 'Simulink.SimulationData.Dataset')
            raw = logs.get(['EncTest:' spec.Output(i).Name]).Values;
        elseif isa(logs, 'Simulink.SimulationData.Signal')
            raw = logs.Values;
        else
            error('unexpected logs data');
        end

        if isa(raw, 'Simulink.Timeseries')
            ts{i} = timeseries(raw.Data, raw.Time);
        else
            ts{i} = raw;
        end
    else
        error('empty simout');
    end
end

if isempty(ts) 
    error('empty output');
end

fprintf('\nOutput:\ntime:');
fprintf('\t%g', ts{1}.Time(1:3));
fprintf('\n');

for i = 1:length(spec.Output)
    fprintf('out(%d):', i);
    fprintf('\t%g', ts{i}.Data(1:3));
    fprintf('\n');
end

% eof
