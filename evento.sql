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

create or replace function doar_para_evento(nome_evento varchar, cpf_benfeitor varchar, valor_doado float)
RETURNS table (n text) as $$

    DECLARE
        id_benfeitor int;
        id_evento int;
    BEGIN
        id_benfeitor := buscar_cod_benfeitor(cpf_benfeitor);
        id_evento := buscar_cod_evento(nome_evento);

        IF valor_doado <= 0 THEN
            RETURN QUERY SELECT 'O valor doado não pode ser menor ou igual a zero.';
            RETURN;
        end if;

        UPDATE evento SET arrecadacao = arrecadacao + valor_doado WHERE cod_evento=id_evento;

        EXCEPTION
            WHEN CASE_NOT_FOUND OR ERROR_IN_ASSIGNMENT THEN
                RETURN QUERY SELECT SQLERRM;
                RETURN;
            WHEN others THEN
                RETURN QUERY SELECT CONCAT('Erro durante o cadastro -> ', SQLERRM);
                RETURN;
    END;
$$ language plpgsql;