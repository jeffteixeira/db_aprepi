
-- # EVENTO

-- CRIAR EVENTO

create or replace function criar_evento(
nome_evento varchar,
nome_tipo_evento varchar,
valor_arrecacao float default 0,
valor_custo float default 0,
data_inicio date default current_date,
data_fim date default null)
RETURNS table (n text) as $$
    DECLARE
        id_tipo_evento int := buscar_cod_tipo_evento(nome_tipo_evento);
    BEGIN
        INSERT INTO evento(cod_tipo_evento, arrecadacao, custo, nome, dt_inicio, dt_fim) values
        (id_tipo_evento, valor_arrecacao, valor_custo, nome_evento, data_inicio, data_fim);

        RETURN QUERY SELECT 'Novo evento cadastrado com sucesso!';
        RETURN;

        EXCEPTION
            WHEN CASE_NOT_FOUND OR ERROR_IN_ASSIGNMENT THEN
                RETURN QUERY SELECT SQLERRM;
                RETURN;
            WHEN others THEN
                RETURN QUERY SELECT CONCAT('Erro durante o cadastro -> ', SQLERRM);
                RETURN;
    END;
$$ language plpgsql;

-- DOAR PARA EVENTO

create or replace function doar_para_evento(nome_evento varchar, cpf_benfeitor varchar, valor_doacao float)
RETURNS table (n text) as $$

    DECLARE
        id_benfeitor int;
        id_evento int;
    BEGIN
        id_benfeitor := buscar_cod_benfeitor(cpf_benfeitor);
        id_evento := buscar_cod_evento(nome_evento);

        IF valor_doacao <= 0 THEN
            RETURN QUERY SELECT 'O valor doado não pode ser menor ou igual a zero.';
            RETURN;
        end if;

        INSERT INTO benfeitor_evento(cod_benfeitor, cod_evento, valor_doado) values (id_benfeitor, id_evento, valor_doacao);

        UPDATE evento SET arrecadacao = arrecadacao + valor_doacao WHERE cod_evento=id_evento;
        RETURN QUERY SELECT 'Doação de valor realizada com sucesso!';
        RETURN;

        EXCEPTION
            WHEN CASE_NOT_FOUND OR ERROR_IN_ASSIGNMENT THEN
                RETURN QUERY SELECT SQLERRM;
                RETURN;
            WHEN others THEN
                RETURN QUERY SELECT CONCAT('Erro durante o cadastro da doacao -> ', SQLERRM);
                RETURN;
    END
$$ language plpgsql;

-- ADICIONAR CUSTO EVENTO

create or replace function adicionar_custo_evento(nome_evento varchar, valor_custo float)
RETURNS table (n text) as $$
    DECLARE
        id_evento int;
    BEGIN
        id_evento := buscar_cod_evento(nome_evento);

        IF valor_custo <= 0 THEN
            RETURN QUERY SELECT 'O valor do custo não pode ser menor ou igual a zero.';
            RETURN;
        end if;

        UPDATE evento SET custo=custo + valor_custo WHERE cod_evento=id_evento;
        RETURN QUERY SELECT 'Custo do evento atualizado com sucesso!';
        RETURN;

        EXCEPTION
            WHEN CASE_NOT_FOUND OR ERROR_IN_ASSIGNMENT THEN
                RETURN QUERY SELECT SQLERRM;
                RETURN;
            WHEN others THEN
                RETURN QUERY SELECT CONCAT('Erro durante o cadastro -> ', SQLERRM);
                RETURN;
    END;
$$ language plpgsql;

-- ATUALIZAR DATA FINAL DO EVENTO

create or replace function atualizar_data_final_evento(nome_evento varchar, data_fim date default current_date)
RETURNS table (n text) as $$
    DECLARE
        id_evento int;
    BEGIN
        id_evento := buscar_cod_evento(nome_evento);

        UPDATE evento SET dt_fim=data_fim WHERE cod_evento=id_evento;
        RETURN QUERY SELECT 'Data final do evento atualizada para ' || data_fim;
        RETURN;

        EXCEPTION
            WHEN CASE_NOT_FOUND OR ERROR_IN_ASSIGNMENT THEN
                RETURN QUERY SELECT SQLERRM;
                RETURN;
            WHEN others THEN
                RETURN QUERY SELECT CONCAT('Erro durante o cadastro -> ', SQLERRM);
                RETURN;
    END;
$$ language plpgsql;

-- # VOLUNTARIO

-- ALOCA VOLUNTARIO EM FUNCAO E EVENTO

create or replace function alocar_voluntario_em_evento(nome_evento varchar, cpf_voluntario varchar, nome_funcao varchar)
RETURNS table (n text) as
$$
    DECLARE
        id_evento int;
        id_voluntario int;
        id_funcao int;
        nome_voluntario varchar;
        dt_fim_evento date;
    BEGIN
        id_evento := buscar_cod_evento(nome_evento);
        id_voluntario := buscar_cod_voluntario(cpf_voluntario);
        id_funcao = buscar_cod_funcao(nome_funcao);

        SELECT dt_fim INTO dt_fim_evento FROM evento WHERE cod_evento=id_evento;

        IF dt_fim_evento IS NOT NULL AND dt_fim_evento < current_date THEN
            RETURN QUERY SELECT 'Não é possivel alocar um voluntário em um evento já encerrado.';
            RETURN;
        end if;

        INSERT INTO voluntario_funcao(cod_voluntario, cod_evento, cod_funcao) VALUES (id_voluntario, id_evento, id_funcao);

        SELECT nome into nome_voluntario FROM voluntario WHERE cod_voluntario=id_voluntario;
        RETURN QUERY SELECT FORMAT('%1$s alocado na função %2$s do evento %3$s com sucesso.', nome_voluntario, nome_funcao, nome_evento);

        EXCEPTION
        WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
            RETURN QUERY SELECT SQLERRM;
        WHEN others THEN
            RETURN QUERY SELECT CONCAT('Erro durante o cadastro da alocação -> ', SQLERRM);
    END
$$ language plpgsql;

-- REMOVER VOLUNTARIO DE EVENTO

create or replace function remover_voluntario_de_evento(nome_evento varchar, cpf_voluntario varchar)
RETURNS table (n text) as
$$
    DECLARE
        id_evento int;
        id_voluntario int;
        nome_voluntario varchar;
        dt_fim_evento date;
    BEGIN
        id_evento := buscar_cod_evento(nome_evento);
        id_voluntario := buscar_cod_voluntario(cpf_voluntario);

        SELECT dt_fim INTO dt_fim_evento FROM evento WHERE cod_evento=id_evento;
        SELECT nome into nome_voluntario FROM voluntario WHERE cod_voluntario=id_voluntario;

        IF dt_fim_evento IS NOT NULL AND dt_fim_evento < current_date THEN
            RETURN QUERY SELECT 'Não é possivel remover um voluntário de um evento já encerrado.';
            RETURN;
        ELSEIF NOT EXISTS(SELECT FROM voluntario_funcao WHERE cod_evento=id_evento AND cod_voluntario=id_voluntario) THEN
            RETURN QUERY SELECT FORMAT('%1$s não está alocado no evento %2$s.', nome_voluntario, nome_evento);
            RETURN;
        end if;
        DELETE FROM voluntario_funcao WHERE cod_evento=id_evento and cod_voluntario=id_voluntario;
        RETURN QUERY SELECT FORMAT('%1$s removido do evento %2$s com sucesso.', nome_voluntario, nome_evento);

        EXCEPTION
        WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
            RETURN QUERY SELECT SQLERRM;
        WHEN others THEN
            RETURN QUERY SELECT CONCAT('Erro durante a remoção -> ', SQLERRM);
    END
$$ language plpgsql;

-- REMOVER VOLUNTARIO DE EVENTO PELA FUNCAO

create or replace function remover_voluntario_de_evento_pela_funcao(nome_evento varchar, cpf_voluntario varchar, nome_funcao varchar)
RETURNS table (n text) as
$$
    DECLARE
        id_evento int;
        id_voluntario int;
        id_funcao int;
        nome_voluntario varchar;
        dt_fim_evento date;
    BEGIN
        id_evento := buscar_cod_evento(nome_evento);
        id_voluntario := buscar_cod_voluntario(cpf_voluntario);
        id_funcao := buscar_cod_funcao(nome_funcao);

        SELECT dt_fim INTO dt_fim_evento FROM evento WHERE cod_evento=id_evento;
        SELECT nome into nome_voluntario FROM voluntario WHERE cod_voluntario=id_voluntario;

        IF dt_fim_evento IS NOT NULL AND dt_fim_evento < current_date THEN
            RETURN QUERY SELECT 'Não é possivel remover um voluntário de um evento já encerrado.';
            RETURN;
        ELSEIF NOT EXISTS(SELECT FROM voluntario_funcao WHERE cod_evento=id_evento AND cod_voluntario=id_voluntario) THEN
            RETURN QUERY SELECT FORMAT('%1$s não está alocado no evento %2$s.', nome_voluntario, nome_evento);
            RETURN;
        end if;
        DELETE FROM voluntario_funcao WHERE cod_evento=id_evento and cod_voluntario=id_voluntario and cod_funcao=id_funcao;
        RETURN QUERY SELECT FORMAT('%1$s removido da funcao %2$s do evento %3$s com sucesso.',
            nome_voluntario, nome_funcao, nome_evento);

        EXCEPTION
        WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
            RETURN QUERY SELECT SQLERRM;
        WHEN others THEN
            RETURN QUERY SELECT CONCAT('Erro durante a remoção -> ', SQLERRM);
    END
$$ language plpgsql;

-- LISTAR FUNCOES VOLUNTARIO NO EVENTO

create or replace function listar_funcoes_voluntario_evento(nome_evento varchar)
RETURNS table (n text) as $$
    DECLARE
        id_evento int;
    BEGIN
        id_evento := buscar_cod_evento(nome_evento);

        RETURN QUERY select FORMAT('%1$s, (%2$s%)',
                                    v.nome, string_agg(f.nome, ','))
                            from voluntario_funcao vf
                            inner join voluntario v on vf.cod_voluntario = v.cod_voluntario
                            inner join funcao f on vf.cod_funcao = f.cod_funcao
                            WHERE vf.cod_evento=id_evento GROUP BY v.nome;
        RETURN;

        EXCEPTION
            WHEN others THEN
                RETURN QUERY SELECT 'Erro durante a consulta -> ', SQLERRM;
    END;
$$ language plpgsql SECURITY DEFINER;


-- LISTAR EVENTOS ATIVOS OU NAO QUE VOLUNTARIO ESTA PARTICIPANDO

create or replace view view_listar_eventos_por_funcionario as
    select vf.cod_voluntario, e.nome as nome_evento, f.nome as nome_funcao, e.dt_fim
                            from voluntario_funcao vf
                            inner join voluntario v on vf.cod_voluntario = v.cod_voluntario
                            inner join funcao f on vf.cod_funcao = f.cod_funcao
                            inner join evento e on vf.cod_evento = e.cod_evento;

create or replace function listar_eventos_por_voluntario(cpf_voluntario varchar, eventos_ativos boolean default true)
RETURNS table (n text) as $$
    DECLARE
        id_voluntario int;
    BEGIN
        id_voluntario := buscar_cod_voluntario(cpf_voluntario);

        if eventos_ativos THEN
            RETURN QUERY select FORMAT('%1$s com as funcoes (%2$s%)',
                                    nome_evento, string_agg(nome_funcao, ','))
                            from view_listar_eventos_por_funcionario
                            WHERE cod_voluntario = id_voluntario AND
                            dt_fim is null or dt_fim >= current_date GROUP BY nome_evento;
        ELSE
            RETURN QUERY select FORMAT('%1$s com as funcoes (%2$s%)',
                                    nome_evento, string_agg(nome_funcao, ','))
                            from view_listar_eventos_por_funcionario
                            WHERE cod_voluntario = id_voluntario GROUP BY nome_evento;
        END IF;
        RETURN;

        EXCEPTION
            WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
                RETURN QUERY SELECT SQLERRM;
            WHEN others THEN
                RETURN QUERY SELECT 'Erro durante a consulta -> ', SQLERRM;
    END
$$ language plpgsql;
