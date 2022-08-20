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
        obj.Spec.BlockPath = json.BlockPath;
        obj.Spec.Input = obj.parseSection1(json, {'Input', 'Inputs'});
        obj.Spec.Output = obj.parseSection1(json, {'Output', 'Outputs'});
        obj.Spec.Param = obj.parseSection1(json, {'Param', 'Params', 'Parameter', 'Parameters'});
        obj.Spec.Input = obj.parseSection2(obj.Spec.Input);
        obj.Spec.Output = obj.parseSection2(obj.Spec.Output);
        obj.Spec.Param = obj.parseSection2(obj.Spec.Param);
    end

    function r = parseSection1(obj, json, names)
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
    
            r(i).Multiplicity = obj.getAsCA(s, {'Multiplicity'});
            r(i).Domain = obj.getAsCA(s, {'Domain'});
            if isfield(s, 'Requires')
                r(i).Requires = s.Requires;
                r(i).IsOptional = true;
            else
                r(i).IsOptional = false;
            end
            if isfield(s, 'Constraint')
                r(i).Constraint = s.Constraint;
            end
        end
    end

    function r = parseSection2(obj, section)
        r = section;
        for i = 1:length(section)
            s = section(i);
            [r(i).Multiplicity, r(i).MDep] = obj.getRefAsCA(s, {'Multiplicity'});
            [r(i).Domain, r(i).DDep] = obj.getRefAsCA(s, {'Domain'});
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

    function [r1, r2] = getRefAsCA(obj, s, names)
        r1 = obj.getAsCA(s, names);
        if ~isempty(r1)
            ref = strip(r1{1});
            if ref(1) == '<' && ref(end) == '>'
                nm = ref(2:end-1);
                s = obj.Spec.Input;
                i = find(strcmp({s.Name}, nm), 1);
                if ~isempty(i)
                    r1 = obj.getRefAsCA(s(i), names);
                    r2 = {'I', nm};
                    return
                end
                s = obj.Spec.Output;
                i = find(strcmp({s.Name}, nm), 1);
                if ~isempty(i)
                    r1 = obj.getRefAsCA(s(i), names);
                    r2 = {'O', nm};
                    return
                end
                s = obj.Spec.Param;
                i = find(strcmp({s.Name}, nm), 1);
                if ~isempty(i)
                    r1 = obj.getRefAsCA(s(i), names);
                    r2 = {'P', nm};
                    return
                end
                error(sprintf('reference %s not found', v));
            else
                %r1 = r;
                r2 = {};
            end
        else
            warning(sprintf('element does not exist: %s of %s', names{1}, s.Name));
            %r1 = {};
            r2 = {};
        end
    end
    %{
    function [r1, r2] = getRefAsCA(obj, sect, sName, names)
        ca = obj.getAsCA(sect, names);

        if ~isempty(ca)
            ref = strip(ca{1});
            if ref(1) == '<' && ref(end) == '>'
                nm = ref(2:end-1);
                s = obj.Spec.Input;
                if ~isempty(s)
                    i = find(strcmp({s.Name}, nm), 1);
                    if ~isempty(i)
                        r1 = obj.getAsCA(s(i), names);
                        r2 = {'I', nm};
                        return
                    end
                end
                s = obj.Spec.Output;
                if ~isempty(s)
                    i = find(strcmp({s.Name}, nm), 1);
                    if ~isempty(i)
                        r1 = obj.getAsCA(s(i), names);
                        r2 = {'O', nm};
                        return
                    end
                end
                s = obj.Spec.Param;
                if ~isempty(s)
                    i = find(strcmp({s.Name}, nm), 1);
                    if ~isempty(i)
                        r1 = obj.getAsCA(s(i), names);
                        r2 = {'P', nm};
                        return
                    end
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
    %}
end

end

% eof
