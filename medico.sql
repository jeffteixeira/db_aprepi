create or replace function alocar_medico_em_especialidade(nome_medico varchar, nome_especialidade varchar)
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
$$ language plpgsql;

create or replace function buscar_cod_medico(nome_medico varchar)
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
$$ language plpgsql;

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
$$ language plpgsql;

select alocar_medico_em_especialidade('Joao', 'cardiologista');