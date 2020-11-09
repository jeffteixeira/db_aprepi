

-- VALIDADOR DE CPF

create or replace function validador_cpf(value_cpf varchar)
RETURNS varchar as
$$
    DECLARE
        number char;
        first_number char;
        equals_numbers boolean := true;
        sanitize_cpf varchar;
        t int := 9;
        d int := 0;
        c int := 0;

    BEGIN
        sanitize_cpf := REGEXP_REPLACE(value_cpf, '([^0-9])+', '', 'g');

        if LENGTH(sanitize_cpf) != 11 THEN
            raise exception 'CPF com numero de digitos diferente de 11: %', sanitize_cpf;
        END IF;

        first_number := SUBSTRING(sanitize_cpf, 1, 1);
        FOREACH number IN ARRAY regexp_split_to_array(sanitize_cpf, '') LOOP
            IF number != first_number THEN
                equals_numbers := false;
                EXIT;
            end if;
        end loop;

        IF equals_numbers THEN
            raise exception 'CPF com digitos iguais é invalido: %', sanitize_cpf;
        end if;

        LOOP
            exit when t = 11;
            -- reinicia c contador C e o D
            c := 0;
            d := 0;
            LOOP
                exit when c = t;
                d := d + SUBSTRING(sanitize_cpf, c+1, 1)::int * ((t + 1) - c);
                c := c + 1;
            end loop;

            d := ((10 * d) % 11) % 10;

            if (SUBSTRING(sanitize_cpf, c+1, 1)::int != d) THEN
                raise exception 'CPF invalido: %', sanitize_cpf;
            END IF;
            t := t + 1;
        end loop;

        return sanitize_cpf;
    END;
$$ language plpgsql SECURITY DEFINER;

-- FC TRIGGER CPF

create or replace function fc_trigger_cpf()
RETURNS trigger as
$$
    BEGIN
        select validador_cpf(NEW.cpf) into NEW.cpf;
        RETURN NEW;
    END;
$$ language plpgsql SECURITY DEFINER;

-- TRIGGERS

-- # TRIGGER CESTA BASICA

create or replace function fc_trigger_cesta_basica()
RETURNS trigger as
$$
    BEGIN

        IF NEW.quantidade <= 0 THEN
            raise ERROR_IN_ASSIGNMENT using
            message='Quantidade não pode ser negativa nem zero, insira uma quantidade maior que zero';
        end if;

        RETURN NEW;
    END;
$$ language plpgsql;

CREATE TRIGGER trigger_cesta_basica BEFORE INSERT or UPDATE on
cesta_basica for each row
execute procedure fc_trigger_cesta_basica();

-- # TRIGGER BENFEITOR

CREATE TRIGGER trigger_benfeitor BEFORE INSERT or UPDATE on
benfeitor for each row
execute procedure fc_trigger_cpf();

-- # TRIGGER SOCIO

CREATE TRIGGER trigger_socio BEFORE INSERT or UPDATE on
socio for each row
	execute procedure fc_trigger_cpf();

-- # TRIGGER ALIMENTO

create or replace function fc_trigger_alimento()
RETURNS trigger as
$$
    DECLARE
        unidades_de_medida varchar[] := '{"KG", "G", "ML", "L"}';
    BEGIN

        IF NEW.quantidade < 0 AND tg_op = 'INSERT' THEN
            raise ERROR_IN_ASSIGNMENT using
            message='Quantidade não pode ser negativo, insira uma quantidade maior ou igual a zero';
        ELSEIF NEW.quantidade < 0 THEN
            raise ERROR_IN_ASSIGNMENT using
            message=FORMAT('Estoque insulficiente de %1$s. Apenas %2$s disponiveis.', NEW.nome, OLD.quantidade);
        ELSEIF NOT NEW.unidade_de_medida ILIKE ANY(unidades_de_medida) THEN
            raise ERROR_IN_ASSIGNMENT using
            message='A unidade de medida precisa ser uma das seguintes: ' || array_to_string(unidades_de_medida, ',');
        end if;

        NEW.nome := btrim(NEW.nome);
        NEW.unidade_de_medida := upper(NEW.unidade_de_medida);

        RETURN NEW;
    END;
$$ language plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_alimento BEFORE INSERT or UPDATE on
alimento for each row
execute procedure fc_trigger_alimento();

-- # TRIGGER EVENTO

create or replace function fc_trigger_evento()
RETURNS trigger as
$$
    BEGIN
        IF NEW.custo < 0 THEN
            raise ERROR_IN_ASSIGNMENT using
            message='O custo não pode ser negativo, insira uma quantidade maior ou igual a zero';
        ELSEIF NEW.arrecadacao < 0 THEN
            raise ERROR_IN_ASSIGNMENT using
            message='A arrecadação não pode ser negativa, insira uma quantidade maior ou igual a zero';
        ELSEIF (NEW.arrecadacao != OLD.arrecadacao OR NEW.custo != OLD.custo) AND
               NEW.dt_fim IS NOT NULL AND NEW.dt_fim < current_date THEN
            raise ERROR_IN_ASSIGNMENT using
            message='Este evento foi finalizado em ' || NEW.dt_fim
                || '. Eventos finalizados não podem ter custos ou arrecadações modificados.' ;
        end if;

        NEW.nome := btrim(NEW.nome);

        RETURN NEW;
    END
$$ language plpgsql;

CREATE TRIGGER trigger_evento BEFORE INSERT or UPDATE on
evento for each row
execute procedure fc_trigger_evento();

-- # TRIGGER FUNCIONARIO

CREATE TRIGGER trigger_cpf_voluntario BEFORE INSERT or UPDATE on
voluntario for each row
execute procedure fc_trigger_cpf();

-- # TRIGGER VOLUNTARIO_FUNCAO

create or replace function fc_trigger_alocacao_evento()
RETURNS trigger as
$$
    DECLARE
        voluntario_ja_alocado boolean;
    BEGIN
        IF tg_op='INSERT' THEN
            voluntario_ja_alocado := EXISTS (
                SELECT FROM voluntario_funcao WHERE
                cod_evento=NEW.cod_evento AND cod_voluntario=NEW.cod_voluntario AND NEW.cod_funcao);
            IF voluntario_ja_alocado THEN
                RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Voluntario já alocado no evento com esta funcao';
            end if;
        end if;
        RETURN NEW;
    END;
$$ language plpgsql;

CREATE TRIGGER trigger_voluntario_funcao BEFORE INSERT or UPDATE on
voluntario_funcao for each row
execute procedure fc_trigger_alocacao_evento();

-- # TRIGGER CONSULTA

create or replace function fc_trigger_consulta()
RETURNS trigger as
$$
    DECLARE
        proxima_hora time;
        id_medico int;
        especialidades_medico int[];
        hora_anterior time;
        intervalo_minimo interval := '01:00';
        intervalo_consulta interval;
        horario_valido boolean;
    BEGIN

        IF extract(isodow from NEW.dt_consulta) = ANY('{7,6}'::int[]) THEN
            raise ERROR_IN_ASSIGNMENT using
                message='As consultas so podem ser marcadas de Segunda a Sexta';
        ELSEIF NOT (NEW.hora_consulta between time '8:00' and time '12:00' or
               NEW.hora_consulta between time '14:00' and time '18:00') THEN
            raise ERROR_IN_ASSIGNMENT using
                message='As consultas so podem ser marcadas pela manhã entre 8:00h e 12:00h ou pela tarde entre 14:00h e 18:00h';
        end if;

        SELECT cod_medico into id_medico from medico_especialidade WHERE cod_medico_especialidade=NEW.cod_medico_especialidade;
        SELECT array_agg(cod_medico_especialidade) INTO especialidades_medico FROM medico_especialidade WHERE cod_medico=id_medico;

        SELECT hora_consulta INTO hora_anterior FROM consulta
        WHERE dt_consulta=NEW.dt_consulta AND cod_medico_especialidade = ANY (especialidades_medico)
        AND hora_consulta <= NEW.hora_consulta
        ORDER BY hora_consulta DESC LIMIT 1;

        SELECT hora_consulta INTO proxima_hora FROM consulta
        WHERE dt_consulta=NEW.dt_consulta AND cod_medico_especialidade = ANY (especialidades_medico)
        AND hora_consulta >= NEW.hora_consulta
        ORDER BY hora_consulta LIMIT 1;

        raise notice 'proxima hora: %', proxima_hora;
        raise notice 'hora anterior: %', hora_anterior;

        IF proxima_hora IS NULL AND hora_anterior IS NOT NULL THEN
            intervalo_consulta := (NEW.hora_consulta - hora_anterior);
            SELECT intervalo_consulta >= intervalo_minimo INTO horario_valido;
            IF not horario_valido THEN
                raise ERROR_IN_ASSIGNMENT using
                message=FORMAT('O intervalo minimo entre duas consultas é de %1$s. ' ||
                               'A ultima consulta desse medico está marcada para %2$s h.', intervalo_minimo, hora_anterior);
            end if;

        ELSEIF proxima_hora IS NOT NULL AND hora_anterior IS NOT NULL THEN
            intervalo_consulta := (NEW.hora_consulta - hora_anterior);
            SELECT intervalo_consulta >= intervalo_minimo INTO horario_valido;

            IF not horario_valido THEN
                raise ERROR_IN_ASSIGNMENT using
                message=FORMAT('O intervalo minimo entre duas consultas é de %1$s. ' ||
                               'A ultima consulta desse medico está marcada para %2$s h.', intervalo_minimo, hora_anterior);
            end if;

            intervalo_consulta := (proxima_hora - NEW.hora_consulta);
            SELECT intervalo_consulta >= intervalo_minimo INTO horario_valido;

            IF not horario_valido THEN
                raise ERROR_IN_ASSIGNMENT using
                message=FORMAT('O intervalo minimo entre duas consultas é de %1$s. ' ||
                               'A proxima consulta desse medico está marcada para %2$s h.', intervalo_minimo, proxima_hora);
            end if;

        ELSEIF proxima_hora IS NOT NULL AND hora_anterior IS NULL THEN
            intervalo_consulta := (proxima_hora - NEW.hora_consulta);
            SELECT intervalo_consulta >= intervalo_minimo INTO horario_valido;
            IF not horario_valido THEN
                raise ERROR_IN_ASSIGNMENT using
                message=FORMAT('O intervalo minimo entre duas consultas é de %1$s. ' ||
                               'A proxima consulta desse medico está marcada para %2$s h.', intervalo_minimo, proxima_hora);
            end if;
        end if;

        RETURN NEW;
    END;
$$ language plpgsql;

CREATE TRIGGER trigger_consulta BEFORE INSERT or UPDATE on
consulta for each row
execute procedure fc_trigger_consulta();

-- # TRIGGER MEDICO

CREATE TRIGGER trigger_cpf_medico BEFORE INSERT or UPDATE on
medico for each row
execute procedure fc_trigger_cpf();

create or replace function validador_crm(crm varchar)
RETURNS varchar as $$
    DECLARE

        estados text[] := '{"AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", ' ||
                          '"GO", "MA", "MT", "MS", "MG", "PA", "PB", "PR", "PE", ' ||
                          '"PI", "RJ", "RN", "RS", "RO", "RR", "SC", "SP", "SE", "TO"}';
        sanitize_crm varchar := UPPER(REGEXP_REPLACE(crm, '([^0-9/\\a-zA-Z])+', '', 'g'));
        length_crm int := length(sanitize_crm);
    BEGIN

        IF not SUBSTRING(sanitize_crm, length_crm -1, length_crm) ilike any(estados) THEN
            RAISE ERROR_IN_ASSIGNMENT USING
            MESSAGE = 'Informe um UF valido para o CRM no seguinte formato 000000/UF';

        ELSEIF not SUBSTRING(sanitize_crm, length_crm -2, 1) ilike '/' THEN
            raise notice 'substr: %', SUBSTRING(sanitize_crm, length_crm -3, 1);
            RAISE ERROR_IN_ASSIGNMENT USING
            MESSAGE = 'Informe um CRM no seguinte formato 000000/UF';

        ELSEIF not SUBSTRING(sanitize_crm, 1, length_crm - 3) ~ '^[0-9\.]+$' THEN
            RAISE ERROR_IN_ASSIGNMENT USING
            MESSAGE = 'Informe um CRM no seguinte formato 000000/UF';
        end if;

        RETURN sanitize_crm;
    END
$$ language plpgsql;

create or replace function fc_trigger_crm()
RETURNS trigger as
$$
    BEGIN
        select validador_crm(NEW.crm) into NEW.crm;
        RETURN NEW;
    END;
$$ language plpgsql;

CREATE TRIGGER trigger_crm_medico BEFORE INSERT or UPDATE on
medico for each row
execute procedure fc_trigger_crm();

-- TRIGGER MEDICO_ESPECIALIDADE

create or replace function fc_trigger_especialidade_medico()
RETURNS trigger as
$$
    DECLARE
        medico_ja_cadastrado boolean;
    BEGIN
        IF tg_op='INSERT' THEN
            medico_ja_cadastrado := exists(
                SELECT FROM medico_especialidade WHERE
                cod_especialidade=NEW.cod_especialidade AND cod_medico=NEW.cod_medico);
            IF medico_ja_cadastrado THEN
                RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Medico já cadastrado nesta especialidade';
            end if;
        end if;
        RETURN NEW;
    END;
$$ language plpgsql;

CREATE TRIGGER trigger_especialidade_medico BEFORE INSERT or UPDATE on
medico_especialidade for each row
execute procedure fc_trigger_especialidade_medico();

-- BUSCA CODIGO

-- CREATE IF NOT EXISTS INDEX alimento_nome_idx ON alimento(nome);

create or replace function buscar_cod_alimento(nome_alimento varchar)
RETURNS int as $$
    DECLARE
        id int;
        total_rows int;
    BEGIN
        SELECT cod_alimento INTO id FROM ALIMENTO WHERE nome ilike nome_alimento;
        SELECT count(cod_alimento) INTO total_rows FROM ALIMENTO WHERE nome ilike nome_alimento;

        IF id is NULL OR total_rows = 0 THEN
            RAISE CASE_NOT_FOUND USING MESSAGE = 'Nenhum alimento encontrado com o nome ' || nome_alimento;
        ELSEIF total_rows > 1 THEN
            RAISE ERROR_IN_ASSIGNMENT USING MESSAGE = 'Mais de um alimento encontrado com o nome ' || nome_alimento
                                                    || '. Renomeie os alimentos que tem nomes iguais para nomes diferentes e tente novamente.';
        end if;
        RETURN id;
    END;
$$ language plpgsql;

-- CREATE IF NOT EXISTS INDEX benfeitor_cpf_idx ON benfeitor(cpf);

create or replace function buscar_cod_benfeitor(cpf_benfeitor varchar)
RETURNS int as $$
    DECLARE
        sanitize_cpf varchar := validador_cpf(cpf_benfeitor);
        id int;
    BEGIN
        SELECT cod_benfeitor INTO id FROM BENFEITOR WHERE cpf ilike sanitize_cpf;
        IF id IS NULL THEN
            RAISE CASE_NOT_FOUND USING MESSAGE = 'Nenhum benfeitor encontrado com o CPF ' || cpf_benfeitor;
        end if;
        RETURN id;
    END
$$ language plpgsql SECURITY DEFINER;

-- CREATE IF NOT EXISTS INDEX socio_cpf_idx ON socio(cpf);

create or replace function buscar_cod_socio(cpf_socio varchar)
RETURNS int as $$
    DECLARE
        sanitize_cpf varchar := validador_cpf(cpf_socio);
        id int;
    BEGIN
        SELECT cod_socio INTO id FROM SOCIO WHERE cpf ilike sanitize_cpf;
        IF id IS NULL THEN
            RAISE NO_DATA_FOUND USING MESSAGE = 'Nenhum socio encontrado com o CPF ' || cpf_socio;
        end if;
        RETURN id;
    END;
$$ language plpgsql SECURITY DEFINER;

-- CREATE IF NOT EXISTS INDEX evento_nome_idx ON evento(nome);

create or replace function buscar_cod_evento(nome_evento varchar)
RETURNS int as $$
    DECLARE
        id int;
        total_rows int;
    BEGIN
        SELECT cod_evento INTO id FROM EVENTO WHERE nome ilike nome_evento;
        SELECT count(cod_evento) INTO total_rows FROM EVENTO WHERE nome ilike nome_evento;

        IF id is NULL OR total_rows = 0 THEN
            RAISE CASE_NOT_FOUND USING MESSAGE = 'Nenhum evento encontrado com o nome ' || nome_evento;
        ELSEIF total_rows > 1 THEN
            RAISE ERROR_IN_ASSIGNMENT USING MESSAGE = 'Mais de um evento encontrado com o nome ' || nome_evento
                                                    || '. Renomeie os eventos que tem nomes iguais para nomes diferentes e tente novamente.';
        end if;
        RETURN id;
    END;
$$ language plpgsql;

-- CREATE IF NOT EXISTS INDEX tipo_evento_nome_idx ON tipo_evento(nome);

create or replace function buscar_cod_tipo_evento(nome_tipo_evento varchar)
RETURNS int as $$
    DECLARE
        id int;
        total_rows int;
    BEGIN
        SELECT cod_tipo_evento INTO id FROM TIPO_EVENTO WHERE nome ilike nome_tipo_evento;
        SELECT count(cod_tipo_evento) INTO total_rows FROM TIPO_EVENTO WHERE nome ilike nome_tipo_evento;

        IF id is NULL OR total_rows = 0 THEN
            RAISE CASE_NOT_FOUND USING MESSAGE = 'Nenhum tipo de evento encontrado com o nome ' || nome_tipo_evento;
        ELSEIF total_rows > 1 THEN
            RAISE ERROR_IN_ASSIGNMENT USING MESSAGE = 'Mais de um tipo de evento encontrado com o nome ' || nome_tipo_evento
                                                    || '. Renomeie os tipos de evento que tem nomes iguais para nomes diferentes e tente novamente.';
        end if;
        RETURN id;
    END;
$$ language plpgsql;

-- CREATE IF NOT EXISTS INDEX voluntario_cpf_idx ON voluntario(cpf);

create or replace function buscar_cod_voluntario(cpf_voluntario varchar)
RETURNS int as $$
    DECLARE
        sanitize_cpf varchar := validador_cpf(cpf_voluntario);
        id int;
    BEGIN
        SELECT cod_voluntario INTO id FROM VOLUNTARIO WHERE cpf ilike sanitize_cpf;
        IF id IS NULL THEN
            RAISE CASE_NOT_FOUND USING MESSAGE = 'Nenhum voluntario encontrado com o CPF ' || cpf_voluntario;
        end if;
        RETURN id;
    END
$$ language plpgsql;

-- CREATE IF NOT EXISTS INDEX funcao_nome_idx ON funcao(nome);

create or replace function buscar_cod_funcao(nome_funcao varchar)
RETURNS int as $$
    DECLARE
        id int;
        total_rows int;
    BEGIN
        SELECT cod_funcao INTO id FROM FUNCAO WHERE nome ilike nome_funcao;
        SELECT count(cod_funcao) INTO total_rows FROM FUNCAO WHERE nome ilike nome_funcao;

        IF id is NULL OR total_rows = 0 THEN
            RAISE CASE_NOT_FOUND USING MESSAGE = 'Nenhuma funcao encontrado com o nome ' || nome_funcao;
        ELSEIF total_rows > 1 THEN
            RAISE ERROR_IN_ASSIGNMENT USING MESSAGE = 'Mais de uma funcao encontrado com o nome ' || nome_funcao
                                                    || '. Renomeie as funcoes que tem nomes iguais para nomes diferentes e tente novamente.';
        end if;
        RETURN id;
    END;
$$ language plpgsql;

-- CREATE IF NOT EXISTS INDEX medico_nome_idx ON medico(nome);

CREATE or REPLACE FUNCTION buscar_cod_medico(nome_medico varchar)
RETURNS int as
$$
    DECLARE
        id int;
        total_rows int;
    BEGIN
        SELECT cod_medico INTO id FROM MEDICO WHERE nome ilike nome_medico;
        SELECT count(cod_medico) INTO total_rows FROM MEDICO WHERE nome ilike nome_medico;

        IF id is NULL OR total_rows = 0 THEN
            RAISE CASE_NOT_FOUND USING MESSAGE = 'Nenhum medico encontrado com o nome ' || nome_medico;
        ELSEIF total_rows > 1 THEN
            RAISE ERROR_IN_ASSIGNMENT USING MESSAGE = 'Mais de um medico encontrado com o nome ' || nome_medico
                                                    || '. Renomeie os medicos que tem nomes iguais para nomes diferentes e tente novamente.';
        end if;
        RETURN id;
    END;
$$ language plpgsql SECURITY DEFINER;

-- CREATE INDEX IF NOT EXISTS especialidade_nome_idx ON especialidade(nome);

create or replace function buscar_cod_especialidade(nome_especialidade varchar)
RETURNS int as
$$
    DECLARE
        id int;
        total_rows int;
    BEGIN
        SELECT cod_especialidade INTO id FROM ESPECIALIDADE WHERE nome ilike nome_especialidade;
        SELECT count(cod_especialidade) INTO total_rows FROM ESPECIALIDADE WHERE nome ilike nome_especialidade;

        IF id is NULL OR total_rows = 0 THEN
            RAISE CASE_NOT_FOUND USING MESSAGE = 'Nenhuma especialidade encontrado com o nome ' || nome_especialidade;
        ELSEIF total_rows > 1 THEN
            RAISE ERROR_IN_ASSIGNMENT USING MESSAGE = 'Mais de uma especialidade encontrada com o nome ' || nome_especialidade
                                                    || '. Renomeie as especialidades que tem nomes iguais para nomes diferentes e tente novamente.';
        end if;
        RETURN id;
    END;
$$ language plpgsql SECURITY DEFINER;

-- TRIGGER GENERO

create or replace function trigger_genero()
returns trigger as $$
    begin
	if new.genero not ilike 'masculino' and new.genero not ilike 'feminino' and new.genero not ilike 'outro' then
	    raise exception 'Gênero inválido!';
	end if;
	return new;
    end;
$$ language plpgsql security definer;

create trigger trigger_genero_socio before insert or update
on socio for each row execute procedure trigger_genero();

create trigger trigger_genero_benfeitor before insert or update
on benfeitor for each row execute procedure trigger_genero();

create trigger trigger_genero_medico before insert or update
on medico for each row execute procedure trigger_genero();

create trigger trigger_genero_voluntario before insert or update
on voluntario for each row execute procedure trigger_genero();
