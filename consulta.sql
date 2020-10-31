
create or replace function marcar_consulta(
    nome_medico varchar,
    nome_especialidade varchar,
    cpf_socio varchar,
    data date,
    hora time)
RETURNS table (n text) as $$
    DECLARE
        id_socio int;
        id_medico int;
        id_especialidade int;
        id_medico_especialidade int;
    BEGIN
        id_socio := buscar_cod_socio(cpf_socio);
        id_medico := buscar_cod_medico(nome_medico);
        id_especialidade := buscar_cod_especialidade(nome_especialidade);

        SELECT cod_medico_especialidade INTO id_medico_especialidade FROM
        medico_especialidade WHERE cod_medico=id_medico AND cod_especialidade=id_especialidade;
        raise notice 'cod med: %', id_medico;
        raise notice 'cod esp: %', id_especialidade;
        raise notice 'cod med esp: %', id_medico_especialidade;

        IF id_medico_especialidade IS NULL THEN
            RETURN QUERY SELECT nome_medico || ' não atende na especialidade ' || nome_especialidade;
            RETURN;
        end if;

        INSERT INTO consulta(cod_socio, cod_medico_especialidade, dt_consulta, hora_consulta) VALUES
        (id_socio, id_medico_especialidade, data, hora);

        RETURN QUERY SELECT 'Consulta marcada com sucesso!';
        RETURN;

       EXCEPTION
        WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
            RETURN QUERY SELECT SQLERRM;
        WHEN others THEN
            RETURN QUERY SELECT 'Erro durante o cadastro da consulta -> ' || SQLERRM;
    END
$$ language plpgsql;

select extract(isodow from current_date);
select extract(isodow from date '2020-11-02');
select time '15:00' between time '8:00' and time '12:00' or time '21:00' between time '14:00' and time '18:00';
select extract(hour from (time '10:00' - time '8:00'));
select (time '18:00' - time '10:00') > interval '01:00';
select interval '01:00';
select to_char(abs(time '10:00' - time '18:00'), 'HH:MM:SS');

SELECT ('{"Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado", "Domingo"}'::text[])[extract(isodow from date '2020-11-02')];


select * from medico;
CREATE TRIGGER trigger_cpf_medico BEFORE INSERT or UPDATE on
medico for each row
execute procedure fc_trigger_cpf();

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

--         SELECT hora_consulta INTO hora_anterior FROM consulta
--         WHERE dt_consulta=NEW.dt_consulta AND cod_medico_especialidade=NEW.cod_medico_especialidade
--         AND hora_consulta < NEW.hora_consulta
--         ORDER BY hora_consulta DESC LIMIT 1;
--
--         SELECT hora_consulta INTO proxima_hora FROM consulta
--         WHERE dt_consulta=NEW.dt_consulta AND cod_medico_especialidade=NEW.cod_medico_especialidade
--         AND hora_consulta > NEW.hora_consulta
--         ORDER BY hora_consulta LIMIT 1;

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

SELECT * FROM socio where cod_socio = ANY ('{1,2,3}'::int[]);

select * from especialidade;
select * from medico;
select * from socio;

select * from medico_especialidade;

SELECT alocar_medico_em_especialidade('Anthony Vinicius Leonardo Campos', 'fisioterapeuta');
SELECT alocar_medico_em_especialidade('Igor André Farias', 'psicologo');
SELECT alocar_medico_em_especialidade('Carolina Isis Rezende', 'oftalmologista');
SELECT alocar_medico_em_especialidade('Alana Silvana Sophia Cardoso', 'nutricionista');
SELECT alocar_medico_em_especialidade('Renan Otávio Raimundo Dias', 'cardiologista');

SELECT marcar_consulta(
    'Igor André Farias',
    'psicologo',
    '04912002003',
    '2020-11-02',
    '14:00');

select * from consulta;