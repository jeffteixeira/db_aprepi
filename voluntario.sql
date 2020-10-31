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

create or replace function buscar_cod_funcao(nome_funcao varchar)
RETURNS int as $$
    DECLARE
        id int;
        total_rows int;
    BEGIN
        SELECT cod_funcao INTO id FROM FUNCAO WHERE nome ilike nome_funcao;
        SELECT count(cod_funcao) INTO total_rows FROM FUNCAO WHERE nome ilike nome_funcao;

        IF id is NULL OR total_rows = 0 THEN
            RAISE CASE_NOT_FOUND USING MESSAGE = 'Nenhuma funcao encontrada com o nome ' || nome_funcao;
        ELSEIF total_rows > 1 THEN
            RAISE ERROR_IN_ASSIGNMENT USING MESSAGE = 'Mais de uma funcao encontrada com o nome ' || nome_funcao
                                                    || '. Renomeie as funcoes que tem nomes iguais para nomes diferentes e tente novamente.';
        end if;
        RETURN id;
    END;
$$ language plpgsql;

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

select * from medico;

create or replace function fc_trigger_cpf()
RETURNS trigger as
$$
    BEGIN
        select validador_cpf(NEW.cpf) into NEW.cpf;
        RETURN NEW;
    END;
$$ language plpgsql;

CREATE TRIGGER trigger_cpf_voluntario BEFORE INSERT or UPDATE on
voluntario for each row
execute procedure fc_trigger_cpf();

select * from funcao;
select * from voluntario_funcao;

select multi_cadastrar('funcao', json '[
    {
        "nome": "publicidade",
        "descricao": "providencia a publicação de notícias sobre o evento em jornais e redes sociais."
    },
    {
        "nome": "administrativo",
        "descricao": "Faz o controle de pessoal do evento, auxilia em todas as areas."
    },
    {
        "nome": "limpeza",
        "descricao": "Responsável pela limpeza e organização do local do evento."
    },
    {
        "nome": "recepcionista",
        "descricao": "recepciona os convidados, visitantes e doadores."
    },
    {
        "nome": "seguranca",
        "descricao": "é responsável pelo planejamento da segurança nos eventos."
    }
]');
select * from voluntario;
SELECT alocar_voluntario_em_evento('bazar beneficente aprepi 2020', '59138552302', 'administrativo');
SELECT remover_voluntario_de_evento('bazar beneficente aprepi 2020', '59138552302');

create or replace function fc_trigger_alocacao_evento()
RETURNS trigger as
$$
    DECLARE
        voluntario_ja_alocado boolean;
    BEGIN
        SELECT EXISTS (SELECT FROM voluntario_funcao WHERE cod_evento=NEW.cod_evento AND cod_voluntario=NEW.cod_voluntario)
        INTO voluntario_ja_alocado;
        IF voluntario_ja_alocado THEN
            raise ERROR_IN_ASSIGNMENT using
            message='Voluntario já alocado no evento, primeiro remova o voluntario do evento para alocar ele em uma nova função.';
        end if;
        RETURN NEW;
    END;
$$ language plpgsql;

CREATE TRIGGER trigger_voluntario_funcao BEFORE INSERT or UPDATE on
voluntario_funcao for each row
execute procedure fc_trigger_alocacao_evento();

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