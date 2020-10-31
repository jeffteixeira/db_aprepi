create or replace function buscar_cod_benfeitor(cpf_benfeitor varchar)
RETURNS int as $$
    DECLARE
        sanitize_cpf varchar := validador_cpf(cpf_benfeitor);
        id int;
    BEGIN
        SELECT cod_benfeitor INTO id FROM BENFEITOR WHERE cpf ilike sanitize_cpf;
        IF id IS NULL THEN
            RAISE CASE_NOT_FOUND USING MESSAGE = 'Nenhum benfeitor encontrado com o CPF ' || cpf_benfeitor;
        end if;
        raise notice '%', sanitize_cpf;
        RETURN id;
    END;
$$ language plpgsql;

create or replace function realizar_doacao(cpf_benfeitor varchar, alimentos json, id_doacao int default null)
RETURNS table (n text) as $$
    DECLARE
        cesta_basica json := montar_cesta_basica();
        chave_cesta varchar;

        id_benfeitor int;
        format_alimentos json := '{}';
        id_alimento int;
        nome_alimento varchar;
        qtd_alimento int;
        nome_alimentos_bd varchar[] := (SELECT array_agg(nome::varchar) FROM ALIMENTO);
        erros text[]:= '{"OS SEGUINTES ERROS FORAM ENCONTRADOS"}';
        relatorio text[]:= '{"Novo doação cadastrada com sucesso!"}';
        length_alimentos int := (SELECT count(*) FROM json_object_keys(alimentos));
        campos_validos boolean := true;
    BEGIN

        IF (alimentos->'cesta_basica') IS NOT NULL THEN
            IF (alimentos->>'cesta_basica')::int <= 0 THEN
                raise ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'A quantidade de cestas basicas precisa ser maior que zero.';
            end if;
            -- BUSCA BENFEITOR
            id_benfeitor := buscar_cod_benfeitor(cpf_benfeitor);

            -- CRIA NOVA DOACAO
            INSERT INTO DOACAO(cod_benfeitor) VALUES (id_benfeitor);
            SELECT currval('doacao_cod_doacao_seq') INTO id_doacao;

            FOR chave_cesta IN SELECT json_object_keys(cesta_basica) LOOP
                cesta_basica := jsonb_set(
                    cesta_basica::jsonb,
                    ARRAY [chave_cesta],
                    FORMAT('%1$s', (cesta_basica->>chave_cesta)::int * (alimentos->>'cesta_basica')::int)::jsonb,
                    true);

            end loop;

            PERFORM realizar_doacao(cpf_benfeitor, cesta_basica, id_doacao);

            RETURN QUERY SELECT FORMAT('%1$s cesta(s) doadas.', (alimentos->>'cesta_basica')::int);
            RETURN;
        ELSE
            FOR nome_alimento IN
            SELECT json_object_keys(alimentos) LOOP
                IF not (nome_alimento ilike ANY (nome_alimentos_bd)) THEN
                    erros := array_append(erros, concat('[', nome_alimento, '] não existe no banco!'));
                    campos_validos := false;
                end if;
            END LOOP;

            IF NOT campos_validos THEN
                RETURN QUERY SELECT nome FROM unnest(erros) as nome;
                RETURN;
            ELSEIF length_alimentos = 0 THEN
                RETURN QUERY SELECT 'Nenhum alimento doado!';
                RETURN;
            end if;
        END IF;

        -- FORMATAR_JSON_DE_ALIMENTOS
        SELECT alimentos_json, relatorio_list INTO format_alimentos, relatorio FROM formatar_alimentos(alimentos);

        -- BUSCA BENFEITOR
        id_benfeitor := buscar_cod_benfeitor(cpf_benfeitor);

        -- CRIA NOVA DOACAO
        IF id_doacao IS NULL THEN
            INSERT INTO DOACAO(cod_benfeitor) VALUES (id_benfeitor);
            SELECT currval('doacao_cod_doacao_seq') INTO id_doacao;
        END IF;

        -- INSERE TODOS OS ALIMENTOS EM ITEM_RECEBIMENTO
        FOR id_alimento IN
            SELECT json_object_keys(format_alimentos) LOOP
                qtd_alimento := (format_alimentos->(id_alimento::varchar)->>(id_alimento::varchar))::int;

                UPDATE ALIMENTO SET quantidade = quantidade + qtd_alimento WHERE cod_alimento=id_alimento;
                INSERT INTO ITEM_DOACAO(cod_alimento, cod_doacao, quantidade, grandeza, unidade_de_medida)
                VALUES (id_alimento, id_doacao, qtd_alimento, (format_alimentos->(id_alimento::varchar)->>'grandeza')::int, format_alimentos->(id_alimento::varchar)->>'unidade_de_medida');
        END LOOP;

        RETURN QUERY SELECT nome FROM unnest(relatorio) as nome;
        RETURN;

        EXCEPTION
            WHEN CASE_NOT_FOUND THEN
                RETURN QUERY SELECT unnest( ARRAY[SQLERRM]);
            WHEN others THEN
                RETURN QUERY SELECT unnest(
                    ARRAY[CONCAT('Erro durante o cadastro -> ', SQLERRM)]);
    END;
$$ language plpgsql;
