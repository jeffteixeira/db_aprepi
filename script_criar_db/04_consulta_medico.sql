
-- CADASTRAR MEDICO
create or replace function cadastrar_medico(campos json)
returns table (n text) as
$$
	declare
		quantity_spec int;
		data_nasc date := campos->>'dt_nasc';
	begin
		insert into medico values(default,campos->>'nome',data_nasc,campos->>'cpf',campos->>'crm',campos->>'telefone');

		RETURN QUERY SELECT FORMAT('Dr(a). %1$s cadastrado(a) com sucesso.', campos->>'nome');

        EXCEPTION
        WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
            RETURN QUERY SELECT SQLERRM;
        WHEN others THEN
            RETURN QUERY SELECT CONCAT('Erro durante a execução -> ', SQLERRM);
	END;
$$ language plpgsql SECURITY DEFINER;

-- ALOCAR MEDICO EM ESPECIALIDADE

CREATE or REPLACE FUNCTION alocar_medico_em_especialidade(nome_medico varchar, nome_especialidade varchar)
RETURNS table (n text) as
$$
    DECLARE
        id_medico int;
        id_especialidade int;
    BEGIN
        id_medico := buscar_cod_medico(nome_medico);
        id_especialidade := buscar_cod_especialidade(nome_especialidade);

        INSERT INTO medico_especialidade(cod_especialidade, cod_medico) VALUES (id_especialidade, id_medico);

        RETURN QUERY SELECT FORMAT('%1$s alocado na especialidade %2$s com sucesso.', nome_medico, nome_especialidade);

        EXCEPTION
        WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
            RETURN QUERY SELECT SQLERRM;
        WHEN others THEN
            RETURN QUERY SELECT CONCAT('Erro durante a execução -> ', SQLERRM);
    END;
$$ language plpgsql SECURITY DEFINER;

CREATE or REPLACE FUNCTION remover_especialidade_de_medico(nome_medico varchar, nome_especialidade varchar)
RETURNS table (n text) as
$$
    DECLARE
        id_medico int;
        id_especialidade int;
        resultado text;
        linhas_afetadas int;
    BEGIN
        id_medico := buscar_cod_medico(nome_medico);
        id_especialidade := buscar_cod_especialidade(nome_especialidade);

        DELETE FROM medico_especialidade WHERE cod_medico=id_medico AND cod_especialidade=id_especialidade;
        GET DIAGNOSTICS linhas_afetadas := ROW_COUNT;

        IF linhas_afetadas = 0 THEN
            resultado := nome_medico || 'não atende na especialidade ' || nome_especialidade;
        ELSE
            resultado := nome_medico || 'removido da especialidade ' || nome_especialidade;
        end if;

        RETURN QUERY SELECT resultado;
        RETURN;

        EXCEPTION
        WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
            RETURN QUERY SELECT SQLERRM;
        WHEN others THEN
            RETURN QUERY SELECT CONCAT('Erro durante a execução -> ', SQLERRM);
    END;
$$ language plpgsql SECURITY DEFINER;

-- LISTAGEM DE CONSULTAS POR MEDICO E DIA

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

-- MARCAR CONSULTA

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