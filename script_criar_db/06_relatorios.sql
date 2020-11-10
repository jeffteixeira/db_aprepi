-- RELATORIO DOACOES FEITAS PARA EVENTO (GERAL, POR PERÍODO e POR BENFEITOR);

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

-- NÚMERO DE DOAÇÕES RECEBIDAS (GERAL, POR PERÍODO e POR SOCIO);

create or replace view view_doacoes_recebidas as
SELECT a.cod_alimento, ir.cod_recebimento, coalesce(ir.quantidade, 0) quantidade, ir.unidade_de_medida,
coalesce(ir.grandeza, 0) grandeza, a.nome, r.cod_socio, r.dt_recebimento FROM item_recebimento ir
right join alimento a on a.cod_alimento = ir.cod_alimento
right join recebimento r on r.cod_recebimento = ir.cod_recebimento;

create or replace function relatorio_doacoes_recebidas(campos json default '{}')
RETURNS table (relatorio text) as $$
    DECLARE
        id_socio int;
    BEGIN
        IF campos->'cpf_socio' IS NOT NULL THEN
            id_socio := buscar_cod_socio(campos->>'cpf_socio');
            RETURN QUERY SELECT 'FILTRO POR: SOCIO';
            RETURN QUERY
                SELECT FORMAT('%1$s -> %2$s %3$s', nome, (grandeza * sum(quantidade)), unidade_de_medida) FROM
            view_doacoes_recebidas WHERE cod_socio = id_socio GROUP BY nome, unidade_de_medida, grandeza;

        ELSEIF campos->'dt_inicial' IS NOT NULL and campos->'dt_final' IS NULL THEN
            RETURN QUERY SELECT FORMAT('FILTRO POR: DATA(%1$s até %2$s)', (campos->>'dt_inicial')::date, current_date);

            RETURN QUERY SELECT FORMAT('%1$s -> %2$s %3$s', x.nome, x.quantidade_total, x.unidade_de_medida) FROM
            (SELECT nome, (grandeza * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
            view_doacoes_recebidas WHERE dt_recebimento between (campos->>'dt_inicial')::date and current_date
            GROUP BY nome, unidade_de_medida, grandeza order by quantidade_total) x;

        ELSEIF campos->'dt_inicial' IS NOT NULL and campos->'dt_final' IS NOT NULL THEN
            RETURN QUERY SELECT FORMAT('FILTRO POR: DATA(%1$s até %2$s)', (campos->>'dt_inicial')::date,(campos->>'dt_final')::date);

            RETURN QUERY SELECT FORMAT('%1$s -> %2$s %3$s', x.nome, x.quantidade_total, x.unidade_de_medida) FROM
            (SELECT nome, (grandeza * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
            view_doacoes_recebidas WHERE dt_recebimento between (campos->>'dt_inicial')::date and (campos->>'dt_final')::date
            GROUP BY nome, unidade_de_medida, grandeza order by quantidade_total) x;

        ELSE
            RETURN QUERY SELECT 'FILTRO POR: GERAL';
            RETURN QUERY SELECT FORMAT('%1$s -> %2$s %3$s', x.nome, x.quantidade_total, x.unidade_de_medida) FROM
            (SELECT nome, (grandeza * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
            view_doacoes_recebidas GROUP BY nome, unidade_de_medida, grandeza order by quantidade_total) x;
        END IF;

        RETURN;

        EXCEPTION
            WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
                RETURN QUERY SELECT SQLERRM;
            WHEN others THEN
                RETURN QUERY SELECT 'Erro durante a consulta -> ' || SQLERRM;
    END;

$$ language plpgsql SECURITY DEFINER;

-- NÚMERO DE DOAÇÕES RECEBIDAS (GERAL, POR PERÍODO e POR BENFEITOR);

create or replace view view_doacoes_feitas as
SELECT a.cod_alimento, id.cod_doacao, coalesce(id.quantidade, 0) quantidade, id.unidade_de_medida,
coalesce(id.grandeza, 0) grandeza, a.nome, d.cod_benfeitor, d.dt_doacao FROM item_doacao id
right join alimento a on a.cod_alimento = id.cod_alimento
right join doacao d on d.cod_doacao = id.cod_doacao;

create or replace function relatorio_doacoes_feitas(campos json default '{}')
RETURNS table (relatorio text) as $$
    DECLARE
        id_benfeitor int;
    BEGIN
        IF campos->'cpf_benfeitor' IS NOT NULL THEN
            id_benfeitor := buscar_cod_benfeitor(campos->>'cpf_benfeitor');
            RETURN QUERY SELECT 'FILTRO POR: BENFEITOR';
            RETURN QUERY
                SELECT FORMAT('%1$s -> %2$s %3$s', nome, (grandeza * sum(quantidade)), unidade_de_medida) FROM
            view_doacoes_feitas WHERE cod_benfeitor = id_benfeitor GROUP BY nome, unidade_de_medida, grandeza;

        ELSEIF campos->'dt_inicial' IS NOT NULL and campos->'dt_final' IS NULL THEN
            RETURN QUERY SELECT FORMAT('FILTRO POR: DATA(%1$s até %2$s)', (campos->>'dt_inicial')::date, current_date);

            RETURN QUERY SELECT FORMAT('%1$s -> %2$s %3$s', x.nome, x.quantidade_total, x.unidade_de_medida) FROM
            (SELECT nome, (grandeza * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
            view_doacoes_feitas WHERE dt_doacao between (campos->>'dt_inicial')::date and current_date
            GROUP BY nome, unidade_de_medida, grandeza order by quantidade_total) x;

        ELSEIF campos->'dt_inicial' IS NOT NULL and campos->'dt_final' IS NOT NULL THEN
            RETURN QUERY SELECT FORMAT('FILTRO POR: DATA(%1$s até %2$s)', (campos->>'dt_inicial')::date,(campos->>'dt_final')::date);

            RETURN QUERY SELECT FORMAT('%1$s -> %2$s %3$s', x.nome, x.quantidade_total, x.unidade_de_medida) FROM
            (SELECT nome, (grandeza * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
            view_doacoes_feitas WHERE dt_doacao between (campos->>'dt_inicial')::date and (campos->>'dt_final')::date
            GROUP BY nome, unidade_de_medida, grandeza order by quantidade_total) x;

        ELSE
            RETURN QUERY SELECT 'FILTRO POR: GERAL';
            RETURN QUERY SELECT FORMAT('%1$s -> %2$s %3$s', x.nome, x.quantidade_total, x.unidade_de_medida) FROM
            (SELECT nome, (grandeza * sum(quantidade)) as quantidade_total, unidade_de_medida FROM
            view_doacoes_feitas GROUP BY nome, unidade_de_medida, grandeza order by quantidade_total) x;
        END IF;

        RETURN;

        EXCEPTION
            WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
                RETURN QUERY SELECT SQLERRM;
            WHEN others THEN
                RETURN QUERY SELECT 'Erro durante a consulta -> ' || SQLERRM;
    END;

$$ language plpgsql SECURITY DEFINER;

-- MAIS VELHO E MAIS NOVO(SÓCIO, VOLUNTÁRIO, MÉDICO, BENFEITOR);

create or replace function obter_mais_velho(nome_tabela varchar(10))
RETURNS setof record as $$
	BEGIN
		IF nome_tabela NOT ILIKE 'socio' and nome_tabela NOT ILIKE 'voluntario' and nome_tabela NOT ILIKE 'medico' and nome_tabela NOT ILIKE 'benfeitor' THEN
			RAISE EXCEPTION 'Nome de tabela inválido!';
		ELSE
			IF nome_tabela ILIKE 'socio' THEN
				RETURN QUERY SELECT * FROM socio WHERE
				dt_nasc in (select min(dt_nasc) from socio);
			elseif nome_tabela ilike 'voluntario' then
				return query select * from voluntario where
				dt_nasc in (select min(dt_nasc) from voluntario);
			elseif nome_tabela ilike 'medico' then
				return query select * from medico where
				dt_nasc in (select min(dt_nasc) from medico);
			elseif nome_tabela ilike 'benfeitor' then
				return query select * from benfeitor where
				dt_nasc in (select min(dt_nasc) from benfeitor);
			end if;
		end if;
	end;
$$ language plpgsql SECURITY DEFINER;

create or replace function obter_mais_novo(nome_tabela varchar(10))
returns setof record
as $$
begin
	if nome_tabela not in ('socio', 'voluntario', 'medico', 'benfeitor') then
		raise exception 'Nome de tabela inválido!';
	else
		if nome_tabela = 'socio' then
			return query select * from socio where
			dt_nasc in (select max(dt_nasc) from socio);
		elseif nome_tabela = 'voluntario' then
			return query select * from voluntario where
			dt_nasc in (select max(dt_nasc) from voluntario);
		elseif nome_tabela = 'medico' then
			return query select * from medico where
			dt_nasc in (select max(dt_nasc) from medico);
		elseif nome_tabela = 'benfeitor' then
			return query select * from benfeitor where
			dt_nasc in (select max(dt_nasc) from benfeitor);
		end if;
	end if;
end;
$$ language plpgsql SECURITY DEFINER;

-- MÉDICOS DE CADA ESPECIALIDADE

create or replace function obter_medicos_da_especialidade(nome_esp varchar(30))
returns table(nome_medico varchar(50), nome_especialidade varchar(30))
as $$
begin
	return query select medico.nome, especialidade.nome from medico
	natural join medico_especialidade natural join especialidade
	where especialidade.nome ilike nome_esp;
end;
$$ language plpgsql SECURITY DEFINER;

-- ESPECIALIDADE(S) COM MAIS MÉDICOS E A COM MENOS

create or replace function especialidade_com_mais_ou_menos_medicos(opcao varchar(5))
returns table(nome_especialidade varchar(30), quantidade_medicos int)
as $$
begin
	if opcao = 'mais' then
		return query select especialidade.nome, count(*) as quantidade_medicos
		from medico natural join medico_especialidade natural join especialidade
		group by especialidade.nome having count(*) in
		(select max(quantidade_medicos) from (select especialidade.nome, count(*)
		as quantidade_medicos from medico natural join medico_especialidade
		natural join especialidade group by especialidade.nome) as dados);
	elseif opcao = 'menos' then
		return query select especialidade.nome, count(*) as quantidade_medicos
		from medico natural join medico_especialidade natural join especialidade
		group by especialidade.nome having count(*) in
		(select min(quantidade_medicos) from (select especialidade.nome, count(*)
		as quantidade_medicos from medico natural join medico_especialidade
		natural join especialidade group by especialidade.nome) as dados);
	end if;
end;
$$ language plpgsql SECURITY DEFINER;

-- MÉDICOS DE CADA ESPECIALIDADE E ESPECIALIDADES DE CADA MÉDICO

CREATE OR REPLACE FUNCTION especialidades_medicos(nome_tabela varchar, nome_procurado varchar)
RETURNS SETOF RECORD AS
$$
	BEGIN
		IF coalesce(TRIM(nome_tabela), '') = '' THEN
			RAISE NO_DATA_FOUND USING MESSAGE = 'O campo "nome da tabela" não pode ser nulo';

		ELSEIF nome_tabela NOT ILIKE 'medico' AND nome_tabela NOT ILIKE 'especialidade' THEN
			RAISE NO_DATA_FOUND USING MESSAGE = 'Tabela não encontrada';

		ELSE

			IF coalesce(TRIM(nome_procurado), '') != '' THEN
				IF nome_tabela ILIKE 'medico' THEN
					IF nome_procurado ILIKE 'medicos' THEN
						RETURN QUERY SELECT medico.nome, esp.nome
						FROM medico_especialidade AS med_esp
						JOIN medico ON med_esp.cod_medico = medico.cod_medico
						JOIN especialidade AS esp ON med_esp.cod_especialidade = esp.cod_especialidade
						GROUP BY esp.nome, medico.nome;
					ELSEIF (SELECT cod_medico FROM medico WHERE nome ilike nome_procurado) is null THEN
						RAISE NO_DATA_FOUND USING MESSAGE = 'Médico(a) ' || nome_procurado || ' não cadastrado(a)';
					ELSE
						RETURN QUERY SELECT medico.nome, esp.nome
						FROM medico_especialidade AS med_esp
						JOIN medico ON med_esp.cod_medico = medico.cod_medico
						JOIN especialidade AS esp ON med_esp.cod_especialidade = esp.cod_especialidade
						WHERE med_esp.cod_medico IN
						(SELECT cod_medico FROM medico WHERE nome ilike nome_procurado);
					END IF;

				ELSEIF nome_tabela ILIKE 'especialidade' THEN
					IF nome_procurado ILIKE 'especialidades' THEN
						RETURN QUERY SELECT esp.nome, medico.nome
						FROM medico_especialidade AS med_esp
						JOIN medico ON med_esp.cod_medico = medico.cod_medico
						JOIN especialidade AS esp ON med_esp.cod_especialidade = esp.cod_especialidade
						GROUP BY medico.nome, esp.nome;
					ELSEIF (SELECT cod_especialidade FROM especialidade WHERE nome ilike nome_procurado) is null THEN
						RAISE NO_DATA_FOUND USING MESSAGE = 'Especialidade ' || nome_procurado || ' não cadastrada';
					ELSE
						RETURN QUERY SELECT esp.nome, medico.nome
						FROM medico_especialidade AS med_esp
						JOIN medico ON med_esp.cod_medico = medico.cod_medico
						JOIN especialidade AS esp ON med_esp.cod_especialidade = esp.cod_especialidade
						WHERE med_esp.cod_especialidade IN
						(SELECT cod_especialidade FROM especialidade WHERE nome ilike nome_procurado);
					END IF;
				ELSE
					RAISE NO_DATA_FOUND USING MESSAGE = 'Campo ' || nome_procurado || ' não encontrado para a tabela ' || nome_tabela;
				END IF;

			ELSE
				RAISE NO_DATA_FOUND USING MESSAGE = 'O campo "nome procurado" não pode ser nulo';
			END IF;
		END IF;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- QUANTIDADE DE ESPECIALIDADES DE CADA MÉDICO

CREATE OR REPLACE FUNCTION qntd_especialidades_medico(nome_medico varchar)
RETURNS int AS
$$
	DECLARE
		qntd int;
	BEGIN
		IF coalesce(TRIM(nome_medico), '') = '' THEN
			RAISE NO_DATA_FOUND USING MESSAGE = 'O campo "nome do médico" não pode ser nulo';

		ELSEIF (SELECT cod_medico FROM medico WHERE nome ilike nome_medico) IS NULL THEN
			RAISE NO_DATA_FOUND USING MESSAGE = 'Médico(a) ' || nome_medico || ' não cadastrado(a)';

		ELSE
			SELECT COUNT(cod_especialidade) INTO qntd
			FROM medico_especialidade
			WHERE cod_medico IN
			(SELECT cod_medico FROM medico WHERE nome ilike nome_medico)
			GROUP BY cod_medico;
		END IF;

		RETURN QNTD;
	END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ANIVERSARIANTES DE UM PERÍODO(SÓCIO, VOLUNTÁRIO, MÉDICO, BENFEITOR)

create or replace function obter_aniversariantes(nome_tabela varchar(10), data_inicial date, data_final date)
returns table (nome varchar, dt_nasc date)
as $$
begin
	if nome_tabela = 'socio' then
		return query select nome, dt_nasc from socio where
		extract(month from dt_nasc) >= extract(month from data_inicial)
		and extract(day from dt_nasc) >= extract(day from data_inicial)
		and extract(month from dt_nasc) <= extract(month from data_inicial)
		and extract(day from dt_nasc) <= extract(day from data_inicial);
	elseif nome_tabela = 'voluntario' then
		return query select nome, dt_nasc from voluntario where
		extract(month from dt_nasc) >= extract(month from data_inicial)
		and extract(day from dt_nasc) >= extract(day from data_inicial)
		and extract(month from dt_nasc) <= extract(month from data_inicial)
		and extract(day from dt_nasc) <= extract(day from data_inicial);
	elseif nome_tabela = 'medico' then
		return query select nome, dt_nasc from medico where
		extract(month from dt_nasc) >= extract(month from data_inicial)
		and extract(day from dt_nasc) >= extract(day from data_inicial)
		and extract(month from dt_nasc) <= extract(month from data_inicial)
		and extract(day from dt_nasc) <= extract(day from data_inicial);
	elseif nome_tabela = 'benfeitor' then
		return query select nome, dt_nasc from benfeitor where
		extract(month from dt_nasc) >= extract(month from data_inicial)
		and extract(day from dt_nasc) >= extract(day from data_inicial)
		and extract(month from dt_nasc) <= extract(month from data_inicial)
		and extract(day from dt_nasc) <= extract(day from data_inicial);
	end if;
end;
$$ language plpgsql SECURITY DEFINER;

-- EVENTO(S) MAIS LUCRATIVO(S) E MENOS LUCRATIVO(S)

create or replace function obter_eventos_mais_lucrativos()
returns table(nome varchar(32), lucro float) as $$
    begin
	return query select evento.nome, (arrecadacao - custo) as lucro from evento
	where arrecadacao - custo in (select max(arrecadacao - custo) from evento);
    end;
$$ language plpgsql security definer;

create or replace function obter_eventos_menos_lucrativos()
returns table(nome varchar(32), lucro float) as $$
    begin
	return query select evento.nome, (arrecadacao - custo) as lucro from evento
	where arrecadacao - custo in (select min(arrecadacao - custo) from evento);
    end;
$$ language plpgsql security definer;


-- EVENTO(S) MAIS LUCRATIVO(S) E MENOS LUCRATIVO(S)

create or replace function obter_eventos_menos_lucrativos()
returns table(nome varchar(32), lucro float) as $$
    begin
	return query select evento.nome, (arrecadacao - custo) as lucro from evento
	where arrecadacao - custo in (select min(arrecadacao - custo) from evento);
    end;
$$ language plpgsql security definer;

-- QUANTIDADE E PERCENTUAL DE GÊNERO POR TABELA(SÓCIO, BENFEITOR, MÉDICO E VOLUNTÁRIO)

create or replace function obter_quantidade_por_genero(nome_tabela varchar(10), gen varchar(10))
returns table(genero varchar, quantidade int) as $$
    begin
	if gen ilike 'masculino' or gen ilike 'feminino' or gen ilike 'outro' then
		if nome_tabela ilike 'socio' then
			return query select socio.genero, count(*)::int as quantidade from socio group by socio.genero having socio.genero ilike gen;
		elseif nome_tabela ilike 'benfeitor' then
			return query select benfeitor.genero, count(*)::int as quantidade from benfeitor group by benfeitor.genero having benfeitor.genero ilike gen;
		elseif nome_tabela ilike 'medico' then
			return query select medico.genero, count(*)::int as quantidade from medico group by medico.genero having medico.genero ilike gen;
		elseif nome_tabela ilike 'voluntario' then
			return query select medico.genero, count(*)::int as quantidade from voluntario group by medico.genero having medico.genero ilike gen;
		else
			raise exception 'Nome da tabela inválido!';
		end if;
	else
		raise exception 'Gênero inválido!';
	end if;
    end;
$$ language plpgsql security definer;

create or replace function obter_percentual_por_genero(nome_tabela varchar, gen varchar)
returns table(genero varchar, percentual float) as $$
    declare
	total float;
    begin
	if gen ilike 'masculino' or gen ilike 'feminino' or gen ilike 'outro' then
	    if nome_tabela ilike 'socio' then
	        select count(*) into total from socio;
	        return query select socio.genero, (count(*) / total * 100) as percentual
		from socio group by socio.genero having socio.genero ilike gen;
	    elseif nome_tabela ilike 'benfeitor' then
		select count(*) into total from benfeitor;
	        return query select benfeitor.genero, (count(*) / total * 100) as percentual
		from benfeitor group by benfeitor.genero having benfeitor.genero ilike gen;
   	    elseif nome_tabela ilike 'medico' then
		select count(*) into total from medico;
		return query select medico.genero, (count(*) / total * 100) as percentual
		from medico group by medico.genero having medico.genero ilike gen;
	    elseif nome_tabela ilike 'voluntario' then
	        select count(*) into total from voluntario;
   	        return query select medico.genero, (count(*) / total * 100) as percentual
		from voluntario group by medico.genero having medico.genero ilike gen;
	    else
		raise exception 'Nome da tabela inválido!';
	    end if;
	else
	    raise exception 'Gênero inválido!';
	end if;
    end;
$$ language plpgsql security definer;


-- MÉDICO QUE MAIS E QUE MENOS ATENDEU PACIENTES(GERAL E EM UM PERÍODO)

create or replace function obter_medicos_que_mais_atenderam_geral()
returns table(nome varchar, quantidade int) as $$
    begin
	return query select medico.nome, count(*)::int as quantidade from medico natural join medico_especialidade
	natural join consulta group by medico.nome
	having count(*) in (select max(quantidade_atendimentos) from (select medico.nome, count(*) as quantidade_atendimentos
	from medico natural join medico_especialidade natural join consulta group by medico.nome) as dados);
    end;
$$ language plpgsql security definer;

create or replace function obter_medicos_que_mais_atenderam_periodo(data_inicial date, data_final date)
returns table(nome varchar, quantidade int) as $$
    begin
	if data_final >= data_inicial then
	    return query select medico.nome, count(*)::int as quantidade from medico natural join medico_especialidade
	    natural join consulta where dt_consulta between data_inicial and data_final group by medico.nome
	    having count(*) in (select max(quantidade_atendimentos) from (select medico.nome, count(*) as quantidade_atendimentos
	    from medico natural join medico_especialidade natural join consulta where dt_consulta between data_inicial and data_final
	    group by medico.nome) as dados);
	else
	    raise exception 'A data final deve ser maior ou igual à data inicial';
	end if;
    end;
$$ language plpgsql security definer;

create or replace function obter_medicos_que_menos_atenderam_geral()
returns table(nome varchar, quantidade int) as $$
    begin
	return query select medico.nome, count(*)::int as quantidade from medico natural join medico_especialidade
	natural join consulta group by medico.nome
	having count(*) in (select min(quantidade_atendimentos) from (select medico.nome, count(*) as quantidade_atendimentos
	from medico natural join medico_especialidade natural join consulta group by medico.nome) as dados);
    end;
$$ language plpgsql security definer;

create or replace function obter_medicos_que_menos_atenderam_periodo(data_inicial date, data_final date)
returns table(nome varchar, quantidade int) as $$
    begin
	if data_final >= data_inicial then
	    return query select medico.nome, count(*)::int as quantidade from medico natural join medico_especialidade
	    natural join consulta where dt_consulta between data_inicial and data_final group by medico.nome
	    having count(*) in (select min(quantidade_atendimentos) from (select medico.nome, count(*) as quantidade_atendimentos
	    from medico natural join medico_especialidade natural join consulta where dt_consulta between data_inicial and data_final
	    group by medico.nome) as dados);
	else
	    raise exception 'A data final deve ser maior ou igual à data inicial';
    end;
$$ language plpgsql security definer;

-- BENFEITOR QUE DOOU O MAIOR VALOR(GERAL)

create or replace function obter_benfeitores_maior_doacao_geral()
returns table(nome varchar, valor_doado float) as $$
    begin
        return query select benfeitor.nome, valor_doado from benfeitor natural join benfeitor_evento where
        valor_doado in (select max(valor_doado) from benfeitor_evento);
    end;
$$ language plpgsql security definer;

create or replace function obter_benfeitores_menor_doacao_geral()
returns table(nome varchar, valor_doado float) as $$
    begin
        return query select benfeitor.nome, valor_doado from benfeitor natural join benfeitor_evento where
        valor_doado in (select min(valor_doado) from benfeitor_evento);
    end;
$$ language plpgsql security definer;

-- FILTRAR POR NOME(COMEÇO, MEIO E FIM) - TODAS AS TABELAS
create or replace function filtrar_por_nome(nome_tabela varchar(30), nome_procurado varchar(120), localizacao varchar(10))
returns table (nome varchar(120)) as
$$
	declare
		nome_conca varchar(120);
		forbidden_tables varchar[] := '{"consulta", ' ||
                                          '"especialidade", ' ||
                                          '"socio", ' ||
                                          '"benfeitor", ' ||
                                          '"voluntário", ' ||
                                          '"funcao", ' ||
                                          '"alimento", ' ||
                                          '"recebimento", ' ||
                                          '"doacao", ' ||
                                          '"item_recebimento", ' ||
                                          '"item_doacao", ' ||
                                          '"medico", ' ||
                                          '"medico_especialidade", ' ||
                                          '"voluntario_funcao", ' ||
                                          '"evento", ' ||
                                          '"cesta_basica", ' ||
                                          '"benfeitor_evento"}';
	begin
		if (nome_procurado is not null) and (nome_procurado not ilike '') then

			if (nome_tabela ilike any(forbidden_tables)) then
				if (localizacao ilike 'comeco') then
					select nome_procurado || '%' into nome_conca;
				elseif (localizacao ilike 'meio') then
					select '%' || nome_procurado || '%' into nome_conca;
				elseif (localizacao ilike 'fim') then
					select '%' || nome_procurado into nome_conca;
				else
					RAISE NO_DATA_FOUND USING MESSAGE = 'Digite uma localização válida("comeco", "meio" ou "fim")';
				end if;

				return query execute format('select nome from %I where nome ilike %L ',nome_tabela,nome_conca);

			else
				RAISE NO_DATA_FOUND USING MESSAGE = 'Tabela não encontrada';
			end if;

		else
			RAISE NO_DATA_FOUND USING MESSAGE = 'O campo "nome procurado" não pode ser nulo';
		end if;

	end;
$$ language plpgsql security definer;

