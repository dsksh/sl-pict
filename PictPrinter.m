%
% Copyright (c)
% 2022
% ISHII, Daisuke
%

%
% Printer that prints a BlockType specification in the PICT input format.
%
classdef PictPrinter

properties
    Fid;
    Conf;
    MaxNumValues;
end

methods
    %
    % Constructor.
    %
    function obj = PictPrinter(conf)
        obj.Fid = [];

        obj.Conf = conf;
        % TODO
        obj.MaxNumValues = max([length(conf.ValuesFloat), length(conf.ValuesUint), length(conf.ValuesInt)]) + 1;    
    end

    function pr(obj, varargin)
        fprintf(obj.Fid, varargin{:});
    end

    function print(obj, fid, spec)
        obj.Fid = fid;

        inputs = spec.Input;
        for it = inputs
            obj.printTestItem('I', it);
            obj.printTestItemV('I', it);
        end

        outputs = spec.Output;
        for it = outputs
            obj.printTestItem('O', it);
        end

        params = spec.Param;
        for it = params
            obj.printTestItem('P', it);
            if ~isempty(it.Domain) && strcmp(it.Domain{1}(1:2), 'T_')
                obj.printTestItemV('P', it);
            end
        end

        obj.pr('\n');

        for it = inputs
            obj.printConstraint('I', it);
            obj.printConstraintV('I', it);
        end
        for it = outputs
            obj.printConstraint('O', it);
        end
        for it = params
            obj.printConstraint('P', it);
            obj.printConstraintV('P', it);
        end
    end

    function printTestItem(obj, pfx, item)
        nm = item.Name;

        ms = item.Multiplicity;
        if ~isempty(ms)
            obj.pr('%sM__%s: ', pfx, nm);
            for j = 1:length(ms)
                if j > 1; obj.pr(', '); end;
                obj.pr('%s', ms{j});
            end
            obj.pr('\n');
        end
    
        ds = item.Domain;
        if ~isempty(ds)
            obj.pr('%sD__%s: ', pfx, nm);
            if item.IsOptional
                obj.pr('Disabled, ');
            end
            for j = 1:length(ds)
                if j > 1; obj.pr(', '); end;
                obj.pr('%s', ds{j});
            end
            obj.pr('\n');
        end
    end
    
    function printTestItemV(obj, pfx, item)
        nm = item.Name;
        ms = item.Multiplicity;

        if obj.isVector(ms)
            numVs = obj.Conf.VectorSize;
        else
            numVs = 1;
        end
        for j = 1:numVs
            obj.pr('%sV%d_%s: ', pfx, j, nm);
            if item.IsOptional || j > 1
                k0 = 0;
            else
                k0 = 1;
            end
            for k = k0:obj.MaxNumValues
                if k > k0; obj.pr(', '); end;
                obj.pr('%d', k);
            end
            obj.pr('\n');
        end
    end

    function printConstraint(obj, pfx, item)
        nm = item.Name;
        md = item.MDep;
        dd = item.DDep;

        if ~isempty(md)
            obj.pr('[%sM__%s] = [%sM__%s];\n', pfx, nm, md{1}, md{2});
        end
        if ~isempty(dd)
            % TODO
            obj.pr('[%sD__%s] = [%sD__%s];\n', pfx, nm, dd{1}, dd{2});
        end

        if item.IsOptional
            obj.pr('IF %s THEN [%sD__%s] <> "Disabled" ELSE [%sD__%s] = "Disabled";\n', item.Requires, pfx, nm, pfx, nm);
        end

        if isfield(item, 'Constraint') && ~isempty(item.Constraint)
            obj.pr('%s;\n', item.Constraint);
        end
    end

    function printConstraintV(obj, pfx, item)
        nm = item.Name;
        ms = item.Multiplicity;
        ds = item.Domain;

        if obj.isVector(ms)
            numVs = obj.Conf.VectorSize;
        else
            numVs = 1;
        end
        for j = 1:numVs
            if item.IsOptional
                obj.pr('IF %s THEN [%sV%d_%s] > 0 ELSE [%sV%d_%s] = 0;\n', item.Requires, pfx, j, nm, pfx, j, nm);
            end

            if obj.isFloat(ds)
                obj.pr('IF [%sD__%s] = "T_float"  THEN [%sV%d_%s] <= %d;\n', pfx, nm, pfx, j, nm, length(obj.Conf.ValuesFloat));
            end
            if obj.isInt(ds)
                obj.pr('IF [%sD__%s] = "T_int"    THEN [%sV%d_%s] <= %d;\n', pfx, nm, pfx, j, nm, length(obj.Conf.ValuesInt));
                obj.pr('IF [%sD__%s] = "T_uint"   THEN [%sV%d_%s] <= %d;\n', pfx, nm, pfx, j, nm, length(obj.Conf.ValuesUint));
            end
            if obj.isString(ds)
                obj.pr('IF [%sD__%s] = "T_string" THEN [%sV%d_%s] <= %d;\n', pfx, nm, pfx, j, nm, length(obj.Conf.ValuesString));
            end
            if obj.isBool(ds)
                obj.pr('IF [%sD__%s] = "T_bool"   THEN [%sV%d_%s] <= %d;\n', pfx, nm, pfx, j, nm, length(obj.Conf.ValuesBool));
            end

            if PictPrinter.contains(ds, 'T_scalar');
                obj.pr('IF [%sD__%s] = "T_scalar"   THEN [%sV%d_%s] <= %d;\n', pfx, nm, pfx, j, nm, length(obj.Conf.ValuesScalar));
            end

            if PictPrinter.contains(ds, 'T_signs1');
                obj.pr('IF [%sD__%s] = "T_signs1"   THEN [%sV%d_%s] <= %d;\n', pfx, nm, pfx, j, nm, length(obj.Conf.ValuesSigns1));
            end
            if PictPrinter.contains(ds, 'T_signs2');
                obj.pr('IF [%sD__%s] = "T_signs2"   THEN [%sV%d_%s] <= %d;\n', pfx, nm, pfx, j, nm, length(obj.Conf.ValuesSigns2));
            end

            if j > 1 % && obj.isScalar(ms)
                obj.pr('IF [%sM__%s] = "scalar"  THEN [%sV%d_%s] = 0 ELSE [%sV%d_%s] > 0;\n', pfx, nm, pfx, j, nm, pfx, j, nm);
            end
        end
    end
end

methods(Static)

    function b = contains(ca, s)
        b = false;
        for i = 1:length(ca)
            if strcmp(ca{i}, s);
                b = true;
                break
            end
        end
    end
    
    function b = isScalar(ms)
        b = PictPrinter.contains(ms, 'scalar');
    end
    function b = isVector(ms)
        b = PictPrinter.contains(ms, 'vector');
    end

    function b = isFloat(ds)
        b = PictPrinter.contains(ds, 'T_float');
    end
    function b = isInt(ds)
        b = PictPrinter.contains(ds, 'T_int');
        b = b || PictPrinter.contains(ds, 'T_uint');
    end
    function b = isString(ds)
        b = PictPrinter.contains(ds, 'T_string');
    end
    function b = isBool(ds)
        b = PictPrinter.contains(ds, 'T_bool');
    end
end

end

% eof
