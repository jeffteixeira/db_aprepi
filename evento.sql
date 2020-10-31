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

drop function doar_para_evento(nome_evento varchar, cpf_benfeitor varchar, valor_doado float);
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
                   raise notice 'old dt %', old.dt_fim;
                   raise notice 'new dt %', new.dt_fim;
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


SELECT multi_cadastrar('TIPO_EVENTO', json '[
    {
        "nome": "bazar",
        "descricao": "Venda organizada de objetos para fins de caridade."
    },
    {
        "nome": "feijoada",
        "descricao": "Evento com o objetivo de angariar fundos para a instituição."
    },
    {
        "nome": "jantar",
        "descricao": "Evento com o objetivo de angariar fundos para a instituição."
    },
    {
        "nome": "quermesse",
        "descricao": "Evento com o objetivo de angariar fundos para a instituição."
    },
    {
        "nome": "show",
        "descricao": "Evento com o objetivo de angariar fundos para a instituição."
    }
]');

select * from tipo_evento;
select * from evento;
select buscar_cod_evento('1 feijoada aprepi');
select criar_evento('1 Feijoada APREPI', 'feijoada');
select criar_evento(
    'Bazar Beneficente APREPI 2020',
    'bazar',
    0,
    0,
    '2020-11-16',
    '2020-11-20');

select * from benfeitor;
select * from benfeitor_evento;

select doar_para_evento('bazar beneficente aprepi 2020', '67735947828', 1000);
select doar_para_evento('bazar beneficente aprepi 2020', '895.976.010-28', 1000);

select atualizar_data_final_evento('1 feijoada aprepi');

select adicionar_custo_evento('1 feijoada aprepi', 350);

