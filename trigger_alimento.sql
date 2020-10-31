create or replace function fc_trigger_alimento()
RETURNS trigger as
$$
    DECLARE
        unidades_de_medida varchar[] := '{"KG", "G", "ML", "L"}';
    BEGIN

        IF NEW.quantidade < 0 AND tg_op = 'INSERT' THEN
            raise ERROR_IN_ASSIGNMENT using
            message='Quantidade não pode ser negativo, insira uma quantidade maior ou igual a zero';
        ELSEIF NEW.quantidade < 0 THEN
            raise ERROR_IN_ASSIGNMENT using
            message=FORMAT('Estoque insulficiente de %1$s. Apenas %2$s disponiveis.', NEW.nome, OLD.quantidade);
        ELSEIF NOT NEW.unidade_de_medida ILIKE ANY(unidades_de_medida) THEN
            raise ERROR_IN_ASSIGNMENT using
            message='A unidade de medida precisa ser uma das seguintes: ' || array_to_string(unidades_de_medida, ',');
        end if;

        NEW.nome := btrim(NEW.nome);
        NEW.unidade_de_medida := upper(NEW.unidade_de_medida);

        RETURN NEW;
    END;
$$ language plpgsql;

CREATE TRIGGER trigger_alimento BEFORE INSERT or UPDATE on
alimento for each row
execute procedure fc_trigger_alimento();

create or replace function buscar_cod_alimento(nome_alimento varchar)
RETURNS int as $$
    DECLARE
        id int;
        total_rows int;
    BEGIN
        SELECT cod_alimento INTO id FROM ALIMENTO WHERE nome ilike nome_alimento;
        SELECT count(cod_alimento) INTO total_rows FROM ALIMENTO WHERE nome ilike nome_alimento;

        IF id is NULL OR total_rows = 0 THEN
            RAISE CASE_NOT_FOUND USING MESSAGE = 'Nenhum alimento encontrado com o nome ' || nome_alimento;
        ELSEIF total_rows > 1 THEN
            RAISE ERROR_IN_ASSIGNMENT USING MESSAGE = 'Mais de um alimento encontrado com o nome ' || nome_alimento
                                                    || '. Renomeie os alimentos que tem nomes iguais para nomes diferentes e tente novamente.';
        end if;
        RETURN id;
    END;
$$ language plpgsql;

create or replace function inserir_item_cesta_basica(nome_alimento varchar, qtd int)
RETURNS table (n text) as $$
    DECLARE
        id_alimento int;
        alimento_cadastrado boolean := false;

    BEGIN
        id_alimento := buscar_cod_alimento(nome_alimento);
        SELECT EXISTS (SELECT * FROM cesta_basica WHERE cod_alimento = id_alimento) INTO alimento_cadastrado;
        IF alimento_cadastrado THEN
            UPDATE cesta_basica SET quantidade = qtd WHERE cod_alimento = id_alimento;
            RETURN QUERY SELECT FORMAT('Quantidade de %1$s na cesta basica atualizada para %2$s.', nome_alimento, qtd);
            RETURN;
        ELSE
            INSERT INTO cesta_basica(cod_alimento, quantidade) VALUES (id_alimento, qtd);
            RETURN QUERY SELECT FORMAT('%1$s inserido(a) na cesta basica com a quantidade %2$s.', nome_alimento, qtd);
            RETURN;
        end if;

        EXCEPTION
            WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
                RETURN QUERY SELECT SQLERRM;
            WHEN others THEN
                RETURN QUERY SELECT unnest(
                    ARRAY[CONCAT('Erro durante o cadastro -> ', SQLERRM)]);
    END;
$$ language plpgsql;

create or replace function fc_trigger_cesta_basica()
RETURNS trigger as
$$
    BEGIN

        IF NEW.quantidade <= 0 THEN
            raise ERROR_IN_ASSIGNMENT using
            message='Quantidade não pode ser negativa nem zero, insira uma quantidade maior que zero';
        end if;

        RETURN NEW;
    END;
$$ language plpgsql;

CREATE TRIGGER trigger_cesta_basica BEFORE INSERT or UPDATE on
cesta_basica for each row
execute procedure fc_trigger_cesta_basica();


create or replace function montar_cesta_basica()
RETURNS json as $$
    DECLARE
        row jsonb;
        cesta_basica_json json := '{}';
    BEGIN
        FOR row IN SELECT FORMAT('{"%1$s": %2$s}', x.nome, x.quantidade)::json from
        (SELECT a.nome, cb.quantidade from
          alimento a inner join cesta_basica cb on a.cod_alimento = cb.cod_alimento) x LOOP

                SELECT cesta_basica_json::jsonb || row INTO cesta_basica_json;
            end loop;

        RETURN cesta_basica_json;
    END;

$$ language plpgsql;

SELECT montar_cesta_basica();

