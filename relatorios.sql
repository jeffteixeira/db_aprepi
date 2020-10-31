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