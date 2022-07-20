%
% Copyright (c)
% 2022
% ISHII, Daisuke
%

%
% Parser for a JSON file describing a BlockType specification.
%
classdef SpecParser

properties
    % Intermediate specification data.
    Spec;
end

methods
    %
    % Constructor.
    %
    function obj = SpecParser()
    end

    function obj = parse(obj, filename)
        jsonText = fileread(filename);
        json = jsondecode(jsonText);

        obj.Spec = struct('BlockType',[], 'Input',[], 'Output',[], 'Param',[]);
        obj.Spec.BlockType = json.BlockType;
        obj.Spec.Input = obj.parseSection(json, {'Input', 'Inputs'});
        obj.Spec.Output = obj.parseSection(json, {'Output', 'Outputs'});
        obj.Spec.Param= obj.parseSection(json, {'Param', 'Params', 'Parameter', 'Parameters'});
    end

    function r = parseSection(obj, json, names)
        section = obj.getAsCA(json, names);

        r = [];
        for i = 1:length(section)
            s = section{i};
            if isfield(s, 'Name')
                nm = s.Name;
            else
                nm = sprintf('%d', i);
            end
            r(i).Name = nm;
    
            [r(i).Multiplicity, r(i).MDep] = obj.getRefAsCA(s, nm, {'Multiplicity'});
            [r(i).Domain, r(i).DDep] = obj.getRefAsCA(s, nm, {'Domain'});
            if isfield(s, 'Requires')
                r(i).Requires = s.Requires;
                r(i).IsOptional = true;
            else
                r(i).IsOptional = false;
            end
        end
    end

    function r = getAsArray(obj, s, names)
        ca = obj.getAsCA(s, names);
        r = [];
        for i = 1:length(ca)
            r = [r, ca{i}];
        end
    end

    function r = getAsCA(obj, s, names)
        r = {};
        for i = 1:length(names)
            if isfield(s, names{i})
                r = getfield(s, names{i});
                if ~iscell(r)
                    r = {r};
                end
                break
            end
        end
    end

    function [r1, r2] = getRefAsCA(obj, sect, sName, names)
        ca = obj.getAsCA(sect, names);

        if ~isempty(ca)
            ref = strip(ca{1});
            if ref(1) == '<' && ref(end) == '>'
                nm = ref(2:end-1);
                s = obj.Spec.Input;
                i = find(strcmp({s.Name}, nm), 1);
                if ~isempty(i)
                    r1 = obj.getAsCA(s(i), names);
                    r2 = {'I', nm};
                    return
                end
                s = obj.Spec.Output;
                i = find(strcmp({s.Name}, nm), 1);
                if ~isempty(i)
                    r1 = obj.getAsCA(s(i), names);
                    r2 = {'O', nm};
                    return
                end
                s = obj.Spec.Param;
                i = find(strcmp({s.Name}, nm), 1);
                if ~isempty(i)
                    r1 = obj.getAsCA(s(i), names);
                    r2 = {'P', nm};
                    return
                end
                error(sprintf('reference %s not found', v));
            else
                r1 = ca;
                r2 = {};
            end
        else
            warning(sprintf('element does not exist: %s of %s', names{1}, sName));
            r1 = {};
            r2 = {};
        end
    end
end

end

% eof
