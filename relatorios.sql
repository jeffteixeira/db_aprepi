SELECT a.cod_alimento, a.nome, ((sum(ir.grandeza) * sum(ir.quantidade)) / cb.quantidade * a.grandeza) as cestas, ir.unidade_de_medida FROM
item_recebimento ir inner join alimento a on a.cod_alimento = ir.cod_alimento inner join cesta_basica cb on a.cod_alimento = cb.cod_alimento
WHERE ir.unidade_de_medida = 'KG' GROUP BY a.nome, ir.unidade_de_medida, a.cod_alimento, cb.quantidade order by cestas;


drop function relatorio_doacoes_recebidas(campos json);
create or replace function relatorio_doacoes_recebidas(campos json default '{}')
RETURNS table (nome_alimento varchar, qtd_alimento bigint, unidade_medida varchar) as $$
    DECLARE
        id_socio int;
    BEGIN
        IF campos->'cpf_socio' IS NOT NULL THEN
            id_socio := buscar_cod_socio(campos->>'cpf_socio');
            RETURN QUERY SELECT 'FILTRO POR: SOCIO'::varchar, 0::bigint, ''::varchar;
            RETURN QUERY
                SELECT nome::varchar, (sum(grandeza) * sum(quantidade)), unidade_de_medida::varchar FROM
            view_doacoes_recebidas WHERE cod_socio = id_socio GROUP BY nome, unidade_de_medida;

        ELSEIF campos->'dt_inicial' IS NOT NULL and campos->'dt_final' IS NULL THEN
            RETURN QUERY SELECT FORMAT('FILTRO POR: DATA(%1$s até %2$s)', campos->>'dt_inicial', current_date)::varchar,
                                0::bigint, ''::varchar;

            RETURN QUERY SELECT nome, (sum(grandeza) * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
            view_doacoes_recebidas WHERE dt_recebimento between (campos->>'dt_inicial')::date and current_date
            GROUP BY nome, unidade_de_medida order by quantidade_total;

        ELSEIF campos->'dt_inicial' IS NOT NULL and campos->'dt_final' IS NOT NULL THEN
            RETURN QUERY SELECT FORMAT('FILTRO POR: DATA(%1$s até %2$s)', campos->>'dt_inicial',campos->>'dt_final')::varchar,
                                0::bigint, ''::varchar;

            RETURN QUERY SELECT nome, (sum(grandeza) * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
            view_doacoes_recebidas WHERE dt_recebimento between (campos->>'dt_inicial')::date and (campos->>'dt_final')::date
            GROUP BY nome, unidade_de_medida order by quantidade_total;

        ELSE
            RETURN QUERY SELECT 'FILTRO POR: GERAL'::varchar, 0::bigint, ''::varchar;
            RETURN QUERY
                SELECT nome, (sum(grandeza) * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
                view_doacoes_recebidas GROUP BY nome, unidade_de_medida;
        END IF;

        RETURN;

        EXCEPTION
            WHEN others THEN
                RETURN QUERY SELECT 'Erro durante a consulta -> '::varchar, 0::bigint, SQLERRM::varchar;
    END;

$$ language plpgsql;

create or replace function relatorio_doacoes_recebidas(campos json default '{}')
RETURNS table (relatorio text) as $$
    DECLARE
        id_socio int;
    BEGIN
        IF campos->'cpf_socio' IS NOT NULL THEN
            id_socio := buscar_cod_socio(campos->>'cpf_socio');
            RETURN QUERY SELECT 'FILTRO POR: SOCIO';
            RETURN QUERY
                SELECT FORMAT('%1$s -> %2$s %3$s', nome, (sum(grandeza) * sum(quantidade)), unidade_de_medida) FROM
            view_doacoes_recebidas WHERE cod_socio = id_socio GROUP BY nome, unidade_de_medida;

        ELSEIF campos->'dt_inicial' IS NOT NULL and campos->'dt_final' IS NULL THEN
            RETURN QUERY SELECT FORMAT('FILTRO POR: DATA(%1$s até %2$s)', (campos->>'dt_inicial')::date, current_date);

            RETURN QUERY SELECT FORMAT('%1$s -> %2$s %3$s', x.nome, x.quantidade_total, x.unidade_de_medida) FROM
            (SELECT nome, (sum(grandeza) * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
            view_doacoes_recebidas WHERE dt_recebimento between (campos->>'dt_inicial')::date and current_date
            GROUP BY nome, unidade_de_medida order by quantidade_total) x;

        ELSEIF campos->'dt_inicial' IS NOT NULL and campos->'dt_final' IS NOT NULL THEN
            RETURN QUERY SELECT FORMAT('FILTRO POR: DATA(%1$s até %2$s)', (campos->>'dt_inicial')::date,(campos->>'dt_final')::date);

            RETURN QUERY SELECT FORMAT('%1$s -> %2$s %3$s', x.nome, x.quantidade_total, x.unidade_de_medida) FROM
            (SELECT nome, (sum(grandeza) * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
            view_doacoes_recebidas WHERE dt_recebimento between (campos->>'dt_inicial')::date and (campos->>'dt_final')::date
            GROUP BY nome, unidade_de_medida order by quantidade_total) x;

        ELSE
            RETURN QUERY SELECT 'FILTRO POR: GERAL';
            RETURN QUERY SELECT FORMAT('%1$s -> %2$s %3$s', x.nome, x.quantidade_total, x.unidade_de_medida) FROM
            (SELECT nome, (sum(grandeza) * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
            view_doacoes_recebidas GROUP BY nome, unidade_de_medida order by quantidade_total) x;
        END IF;

        RETURN;

        EXCEPTION
            WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
                RETURN QUERY SELECT SQLERRM;
            WHEN others THEN
                RETURN QUERY SELECT 'Erro durante a consulta -> ' || SQLERRM;
    END;

$$ language plpgsql;

select * from socio;

select relatorio_doacoes_recebidas(json '{"cpf_socio": "78025262057"}');

select relatorio_doacoes_recebidas(json '{"dt_inicial": "2020-07-01"}');

select * from relatorio_doacoes_recebidas(json '{"dt_inicial": "2020-17-01"}');

select * from
relatorio_doacoes_recebidas(json '{"dt_inicial": "2020-07-01", "dt_final": "2020-07-30"}');

select * from
relatorio_doacoes_recebidas();

create or replace function relatorio_doacoes_feitas(campos json default '{}')
RETURNS table (relatorio text) as $$
    DECLARE
        id_benfeitor int;
    BEGIN
        IF campos->'cpf_benfeitor' IS NOT NULL THEN
            id_benfeitor := buscar_cod_benfeitor(campos->>'cpf_benfeitor');
            RETURN QUERY SELECT 'FILTRO POR: BENFEITOR';
            RETURN QUERY
                SELECT FORMAT('%1$s -> %2$s %3$s', nome, (sum(grandeza) * sum(quantidade)), unidade_de_medida) FROM
            view_doacoes_feitas WHERE cod_benfeitor = id_benfeitor GROUP BY nome, unidade_de_medida;

        ELSEIF campos->'dt_inicial' IS NOT NULL and campos->'dt_final' IS NULL THEN
            RETURN QUERY SELECT FORMAT('FILTRO POR: DATA(%1$s até %2$s)', (campos->>'dt_inicial')::date, current_date);

            RETURN QUERY SELECT FORMAT('%1$s -> %2$s %3$s', x.nome, x.quantidade_total, x.unidade_de_medida) FROM
            (SELECT nome, (sum(grandeza) * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
            view_doacoes_feitas WHERE dt_doacao between (campos->>'dt_inicial')::date and current_date
            GROUP BY nome, unidade_de_medida order by quantidade_total) x;

        ELSEIF campos->'dt_inicial' IS NOT NULL and campos->'dt_final' IS NOT NULL THEN
            RETURN QUERY SELECT FORMAT('FILTRO POR: DATA(%1$s até %2$s)', (campos->>'dt_inicial')::date,(campos->>'dt_final')::date);

            RETURN QUERY SELECT FORMAT('%1$s -> %2$s %3$s', x.nome, x.quantidade_total, x.unidade_de_medida) FROM
            (SELECT nome, (sum(grandeza) * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
            view_doacoes_feitas WHERE dt_doacao between (campos->>'dt_inicial')::date and (campos->>'dt_final')::date
            GROUP BY nome, unidade_de_medida order by quantidade_total) x;

        ELSE
            RETURN QUERY SELECT 'FILTRO POR: GERAL';
            RETURN QUERY SELECT FORMAT('%1$s -> %2$s %3$s', x.nome, x.quantidade_total, x.unidade_de_medida) FROM
            (SELECT nome, (sum(grandeza) * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
            view_doacoes_feitas GROUP BY nome, unidade_de_medida order by quantidade_total) x;
        END IF;

        RETURN;

        EXCEPTION
            WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
                RETURN QUERY SELECT SQLERRM;
            WHEN others THEN
                RETURN QUERY SELECT 'Erro durante a consulta -> ' || SQLERRM;
    END;

$$ language plpgsql;

select * from benfeitor;
select relatorio_doacoes_feitas(json '{"cpf_benfeitor": "67735947828"}');

select relatorio_doacoes_feitas(json '{"dt_inicial": "2020-07-01"}');

select * from relatorio_doacoes_feitas(json '{"dt_inicial": "2020-17-01"}');

select * from
relatorio_doacoes_feitas(json '{"dt_inicial": "2020-07-01", "dt_final": "2020-07-30"}');

select * from
relatorio_doacoes_feitas();

create or replace view view_doacoes_recebidas as
SELECT a.cod_alimento, ir.cod_recebimento, ir.quantidade, ir.unidade_de_medida, ir.grandeza, a.nome, r.cod_socio, r.dt_recebimento FROM item_recebimento ir inner join alimento a on a.cod_alimento = ir.cod_alimento
inner join recebimento r on r.cod_recebimento = ir.cod_recebimento;

SELECT nome, (sum(grandeza) * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
view_doacoes_recebidas GROUP BY nome, unidade_de_medida;

SELECT nome, (sum(grandeza) * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
view_doacoes_recebidas WHERE cod_socio = '3' GROUP BY nome, unidade_de_medida order by quantidade_total;

SELECT nome, (sum(grandeza) * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
view_doacoes_recebidas WHERE dt_recebimento between '2020-10-24' and current_date
GROUP BY nome, unidade_de_medida order by quantidade_total;


create or replace view view_doacoes_feitas as
SELECT a.cod_alimento, id.cod_doacao, id.quantidade, id.unidade_de_medida, id.grandeza, a.nome, d.cod_benfeitor, d.dt_doacao
FROM item_doacao id inner join alimento a on a.cod_alimento = id.cod_alimento
inner join doacao d on d.cod_doacao = id.cod_doacao;

create or replace view view_doacoes_feitas as
SELECT a.cod_alimento, id.cod_doacao, coalesce(id.quantidade, 0) quantidade, id.unidade_de_medida,
coalesce(id.grandeza, 0) grandeza, a.nome, d.cod_benfeitor, d.dt_doacao FROM item_doacao id
right join alimento a on a.cod_alimento = id.cod_alimento
right join doacao d on d.cod_doacao = id.cod_doacao;

create or replace view view_doacoes_recebidas as
SELECT a.cod_alimento, ir.cod_recebimento, coalesce(ir.quantidade, 0) quantidade, ir.unidade_de_medida,
coalesce(ir.grandeza, 0) granzeza, a.nome, r.cod_socio, r.dt_recebimento FROM item_recebimento ir
right join alimento a on a.cod_alimento = ir.cod_alimento
right join recebimento r on r.cod_recebimento = ir.cod_recebimento;

-- NÚMERO DE DOAÇÕES(GERAL);
SELECT nome, (sum(grandeza) * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
view_doacoes_feitas GROUP BY nome, unidade_de_medida order by quantidade_total;

-- NÚMERO DE DOAÇÕES(BENFEITOR);
SELECT nome, (sum(grandeza) * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
view_doacoes_feitas WHERE cod_benfeitor = '5'
GROUP BY nome, unidade_de_medida order by quantidade_total;

-- NÚMERO DE DOAÇÕES(POR PERÍODO);
SELECT nome, (sum(grandeza) * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
view_doacoes_feitas WHERE dt_doacao between '2020-10-24' and current_date
GROUP BY nome, unidade_de_medida order by quantidade_total;

-- NÚMERO DE DOAÇÕES RECEBIDAS(GERAL);
SELECT a.nome, (sum(ir.grandeza) * sum(ir.quantidade)) as quantidade_total, ir.unidade_de_medida FROM
item_recebimento ir inner join alimento a on a.cod_alimento = ir.cod_alimento
GROUP BY a.nome, ir.unidade_de_medida, a.cod_alimento;

-- NÚMERO DE DOAÇÕES RECEBIDAS(SOCIO);
SELECT a.nome, (sum(ir.grandeza) * sum(ir.quantidade)) as quantidade, ir.unidade_de_medida FROM
item_recebimento ir inner join alimento a on a.cod_alimento = ir.cod_alimento
inner join recebimento r on r.cod_recebimento = ir.cod_recebimento
WHERE r.cod_socio = '3'
GROUP BY a.nome, ir.unidade_de_medida, a.cod_alimento order by quantidade;

-- NÚMERO DE DOAÇÕES RECEBIDAS(POR PERÍODO);
SELECT a.nome, (sum(ir.grandeza) * sum(ir.quantidade)) as quantidade, ir.unidade_de_medida FROM
item_recebimento ir inner join alimento a on a.cod_alimento = ir.cod_alimento
inner join recebimento r on r.cod_recebimento = ir.cod_recebimento
WHERE r.dt_recebimento between '2020-10-24' and current_date
GROUP BY a.nome, ir.unidade_de_medida, a.cod_alimento order by quantidade;



-- NÚMERO DE DOAÇÕES(GERAL);
SELECT a.nome, (sum(id.grandeza) * sum(id.quantidade)) as quantidade, id.unidade_de_medida FROM
item_doacao id inner join alimento a on a.cod_alimento = id.cod_alimento
GROUP BY a.nome, id.unidade_de_medida, a.cod_alimento order by quantidade;

-- NÚMERO DE DOAÇÕES(BENFEITOR);
SELECT a.nome, (sum(id.grandeza) * sum(id.quantidade)) as quantidade, id.unidade_de_medida FROM
item_doacao id inner join alimento a on a.cod_alimento = id.cod_alimento
inner join doacao d on id.cod_doacao = d.cod_doacao
WHERE d.cod_benfeitor = '5'
GROUP BY a.nome, id.unidade_de_medida, a.cod_alimento order by quantidade;
select * from benfeitor;
-- NÚMERO DE DOAÇÕES(POR PERÍODO);
SELECT a.nome, (sum(id.grandeza) * sum(id.quantidade)) as quantidade, id.unidade_de_medida FROM
item_doacao id inner join alimento a on a.cod_alimento = id.cod_alimento
inner join doacao d on d.cod_doacao = id.cod_doacao
WHERE d.dt_doacao between '2020-10-24' and current_date
GROUP BY a.nome, id.unidade_de_medida, a.cod_alimento order by quantidade;


create or replace view view_consultas_medico as
SELECT m.cod_medico, m.nome as nome_medico, e.nome as nome_especialidade,  c.dt_consulta, c.hora_consulta FROM medico m
    join medico_especialidade me on m.cod_medico = me.cod_medico
    join especialidade e on me.cod_especialidade = e.cod_especialidade
    join consulta c on me.cod_medico_especialidade = c.cod_medico_especialidade;


create or replace function listar_consultas_medico(_nome_medico varchar, data_consulta date default current_date)
RETURNS table (consultas text) as $$
    DECLARE
        id_medico int;
        dias text[] := '{"Seg", "Ter", "Qua", "Qui", "Sex", "Sab", "Dom"}';
        meses text[] := '{"jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"}';
        dia_semana text;
        dia_mes text;
        mes text;
        ano text;
        data_formatada text;
    BEGIN
        id_medico := buscar_cod_medico(_nome_medico);
        dia_semana := dias[extract(isodow from data_consulta)];
        dia_mes := extract(day from data_consulta);
        mes := meses[extract(month from data_consulta)];
        ano := extract(year from data_consulta);

        data_formatada := FORMAT('%1$s, %2$s de %3$s de %4$s', dia_semana, dia_mes, mes, ano);

        RETURN QUERY SELECT 'Consultas para o médico ' || _nome_medico || ' - ' || data_formatada;

        IF exists(SELECT FROM view_consultas_medico
                WHERE cod_medico=id_medico AND dt_consulta=data_consulta order by hora_consulta) THEN

            RETURN QUERY SELECT FORMAT('Como %1$s às %2$s ', nome_especialidade, hora_consulta) FROM view_consultas_medico
            WHERE cod_medico=id_medico AND dt_consulta=data_consulta order by hora_consulta;
        ELSE
            RETURN QUERY SELECT 'Nenhuma consulta agendada para esta data';
        END IF;

        RETURN;
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
SELECT ('{"Seg", "Ter", "Qua", "Qui", "Sex", "Sab", "Dom"}'::text[])[extract(isodow from date '2020-11-02')];
SELECT ('{"jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"}'::text[])[extract(month from date '2020-11-02')];


SELECT to_char(date '2020-10-10', 'DD/MM/YYYY');
SELECT extract(month from date '2020-01-10');

select * from medico;
select * from consulta;
select listar_consultas_medico('Igor André Farias', '2020-11-02');
select listar_consultas_medico('Igor André Farias');


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

SELECT SUBSTRING('348905/RJ', length('348905/RJ')-1, length('348905/RJ'));
SELECT SUBSTRING('348905/RJ', length('348905/RJ')-2, 1);
SELECT SUBSTRING('3489a05/RJ', 1, 6) ~ '^[0-9\.]+$';
SELECT SUBSTRING('3a48905/RJ', 1, 6) ~ '^[0-9]';
SELECT upper('3a48905/rj');

select validador_crm('34---111905rj');

CREATE TRIGGER trigger_crm_medico BEFORE INSERT or UPDATE on
medico for each row
execute procedure fc_trigger_crm();

create or replace function fc_trigger_crm()
RETURNS trigger as
$$
    BEGIN
        select validador_crm(NEW.crm) into NEW.crm;
        RETURN NEW;
    END;
$$ language plpgsql;

UPDATE medico set crm = validador_crm(crm);
select validador_crm('776845/PI');

select * from medico;

create or replace view view_doacoes_feitas_eventos as
SELECT be.cod_evento, be.cod_benfeitor, be.valor_doado, e.nome, e.dt_inicio, e.dt_fim
FROM benfeitor_evento be inner join evento e on e.cod_evento = be.cod_evento;

create or replace view view_doacoes_feitas_eventos as
SELECT be.cod_evento, be.cod_benfeitor, COALESCE(be.valor_doado, 0) AS valor_doado, e.nome, e.dt_inicio, e.dt_fim
FROM benfeitor_evento be right join evento e on e.cod_evento = be.cod_evento;

create or replace function relatorio_doacoes_feitas_eventos(campos json default '{}')
RETURNS table (relatorio text) as $$
    DECLARE
        id_benfeitor int;
    BEGIN
        IF campos->'cpf_benfeitor' IS NOT NULL THEN
            id_benfeitor := buscar_cod_benfeitor(campos->>'cpf_benfeitor');
            RETURN QUERY SELECT 'FILTRO POR: BENFEITOR';
            RETURN QUERY
                SELECT FORMAT('%1$s -> %2$s', nome, cast(sum(valor_doado)::varchar as money)) FROM
            view_doacoes_feitas_eventos WHERE cod_benfeitor = id_benfeitor GROUP BY nome;

        ELSEIF campos->'dt_inicial' IS NOT NULL and campos->'dt_final' IS NULL THEN
            RETURN QUERY SELECT FORMAT('FILTRO POR: DATA(%1$s até %2$s)', (campos->>'dt_inicial')::date, current_date);

            RETURN QUERY SELECT FORMAT('%1$s -> %2$s', x.nome, x.quantidade_total) FROM
            (SELECT nome, cast(sum(valor_doado)::varchar as money) as quantidade_total FROM
            view_doacoes_feitas_eventos WHERE dt_inicio between (campos->>'dt_inicial')::date and current_date
            or dt_fim between (campos->>'dt_inicial')::date and current_date
            GROUP BY nome order by quantidade_total) x;

        ELSEIF campos->'dt_inicial' IS NOT NULL and campos->'dt_final' IS NOT NULL THEN
            RETURN QUERY SELECT FORMAT('FILTRO POR: DATA(%1$s até %2$s)', (campos->>'dt_inicial')::date,(campos->>'dt_final')::date);

            RETURN QUERY SELECT FORMAT('%1$s -> %2$s', x.nome, x.quantidade_total) FROM
            (SELECT nome, cast(sum(valor_doado)::varchar as money) as quantidade_total FROM
            view_doacoes_feitas_eventos WHERE
            dt_inicio between (campos->>'dt_inicial')::date and (campos->>'dt_final')::date or
            dt_fim between (campos->>'dt_inicial')::date and (campos->>'dt_final')::date
            GROUP BY nome order by quantidade_total) x;

        ELSE
            RETURN QUERY SELECT 'FILTRO POR: GERAL';
            RETURN QUERY SELECT FORMAT('%1$s -> %2$s', x.nome, x.quantidade_total) FROM
            (SELECT nome, cast(sum(valor_doado)::varchar as money) as quantidade_total FROM
            view_doacoes_feitas_eventos GROUP BY nome order by quantidade_total) x;
        END IF;

        RETURN;

        EXCEPTION
            WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
                RETURN QUERY SELECT SQLERRM;
            WHEN others THEN
                RETURN QUERY SELECT 'Erro durante a consulta -> ' || SQLERRM;
    END;

$$ language plpgsql SECURITY DEFINER;

select * from evento;

select relatorio_doacoes_feitas_eventos(json '{"dt_inicial": "2019-10-10", "dt_final": "2021-10-10"}');

select cast(100.05 as money);