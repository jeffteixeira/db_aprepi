create or replace function buscar_cod_socio(cpf_socio varchar)
RETURNS int as $$
    DECLARE
        sanitize_cpf varchar := validador_cpf(cpf_socio);
        id int;
    BEGIN
        SELECT cod_socio INTO id FROM SOCIO WHERE cpf ilike sanitize_cpf;
        IF id IS NULL THEN
            RAISE CASE_NOT_FOUND USING MESSAGE = 'Nenhum socio encontrado com o CPF ' || cpf_socio;
        end if;
        RETURN id;
    END;
$$ language plpgsql;

create or replace function receber_doacao(cpf_socio varchar, alimentos json, id_recebimento int default null)
RETURNS table (n text) as $$
    DECLARE
        cesta_basica json := montar_cesta_basica();
        chave_cesta varchar;

        id_socio int;
        format_alimentos json;
        id_alimento int;
        nome_alimento varchar;
        qtd_alimento int;
        nome_alimentos_bd varchar[] := (SELECT array_agg(nome::varchar) FROM ALIMENTO);
        erros text[]:= '{"OS SEGUINTES ERROS FORAM ENCONTRADOS"}';
        relatorio text[]:= '{"Novo recebimento de doação cadastrado com sucesso!"}';
        length_alimentos int := (SELECT count(*) FROM json_object_keys(alimentos));
        campos_validos boolean := true;
    BEGIN
        IF (alimentos->'cesta_basica') IS NOT NULL THEN
            IF (alimentos->>'cesta_basica')::int <= 0 THEN
                raise ERROR_IN_ASSIGNMENT USING
                MESSAGE = '[ERRO] A quantidade de cestas basicas precisa ser maior que zero.';
            end if;
            -- BUSCA COD SOCIO
            id_socio := buscar_cod_socio(cpf_socio);

            IF (SELECT dt_falecimento from socio where cod_socio = id_socio) IS NOT NULL THEN
                    raise ERROR_IN_ASSIGNMENT USING MESSAGE =
                    '[ERRO] Sócios falecidos não podem receber doação.';
            end if;

            -- CRIA NOVO RECEBIMENTO
            INSERT INTO RECEBIMENTO(cod_socio) VALUES (id_socio);
            SELECT currval('recebimento_cod_recebimento_seq') INTO id_recebimento;

            FOR chave_cesta IN SELECT json_object_keys(cesta_basica) LOOP
                cesta_basica := jsonb_set(
                    cesta_basica::jsonb,
                    ARRAY [chave_cesta],
                    FORMAT('%1$s', (cesta_basica->>chave_cesta)::int * (alimentos->>'cesta_basica')::int)::jsonb,
                    true);

            end loop;

            PERFORM receber_doacao(cpf_socio, cesta_basica, id_recebimento);

            RETURN QUERY SELECT FORMAT('%1$s cesta(s) entregues.', (alimentos->>'cesta_basica')::int);
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
                raise notice '% ', nome_alimentos_bd;
                raise notice '%', erros;
                RETURN QUERY SELECT nome FROM unnest(erros) as nome;
                RETURN;
            ELSEIF length_alimentos = 0 THEN
                RETURN QUERY SELECT 'Nenhum alimento doado!';
                RETURN;
            end if;
        END IF;

        -- FORMATAR_JSON_DE_ALIMENTOS
        SELECT alimentos_json, relatorio_list INTO format_alimentos, relatorio FROM formatar_alimentos(alimentos);

        -- BUSCA COD SOCIO
        id_socio := buscar_cod_socio(cpf_socio);

        IF (SELECT dt_falecimento from socio where cod_socio = id_socio) IS NOT NULL THEN
                raise ERROR_IN_ASSIGNMENT USING MESSAGE =
                '[ERRO] Sócios falecidos não podem receber doação.';
        end if;

        -- CRIA NOVO RECEBIMENTO
        IF id_recebimento IS NULL THEN
            INSERT INTO RECEBIMENTO(cod_socio) VALUES (id_socio);
            SELECT currval('recebimento_cod_recebimento_seq') INTO id_recebimento;
        END IF;

        -- INSERE TODOS OS ALIMENTOS EM ITEM_RECEBIMENTO
        FOR id_alimento IN
            SELECT json_object_keys(format_alimentos) LOOP

                qtd_alimento := (format_alimentos->(id_alimento::varchar)->>(id_alimento::varchar))::int;

                UPDATE ALIMENTO SET quantidade = quantidade - qtd_alimento WHERE cod_alimento=id_alimento;
                INSERT INTO ITEM_RECEBIMENTO(cod_alimento, cod_recebimento, quantidade, grandeza, unidade_de_medida)
                VALUES (id_alimento, id_recebimento, qtd_alimento, (format_alimentos->(id_alimento::varchar)->>'grandeza')::int, format_alimentos->(id_alimento::varchar)->>'unidade_de_medida');
        END LOOP;

        RETURN QUERY SELECT nome FROM unnest(relatorio) as nome;
        RETURN;

        EXCEPTION
            WHEN CASE_NOT_FOUND OR ERROR_IN_ASSIGNMENT THEN
                RETURN QUERY SELECT unnest( ARRAY['Um erro ocorreu durante o recebimento da doação:', SQLERRM]);
            WHEN others THEN
                RETURN QUERY SELECT unnest(
                    ARRAY[CONCAT('Erro durante o cadastro -> ', SQLERRM)]);
    END;
$$ language plpgsql;

create or replace function formatar_alimentos(alimentos json)
RETURNS table (alimentos_json json, relatorio_list text[]) as $$
    DECLARE
        id_alimento int;
        nome_alimento varchar;
        grandeza_alimento int;
        uni_medida_alimento varchar;
        format_alimentos json := '{}';
        relatorio text[]:= '{"Novo recebimento de doação cadastrado com sucesso!"}';
    BEGIN
        FOR id_alimento, nome_alimento, grandeza_alimento, uni_medida_alimento IN
            SELECT cod_alimento, nome, grandeza, unidade_de_medida FROM ALIMENTO LOOP

            IF (alimentos->nome_alimento) IS NOT NULL THEN
                IF (alimentos->>nome_alimento)::int <= 0 THEN
                    RAISE RESTRICT_VIOLATION USING MESSAGE = 'Não pode haver alimentos com quantidade menor ou igual a zero.';
                END IF;
                relatorio := array_append(relatorio,
                    concat((alimentos->>nome_alimento)::int, ' x ', nome_alimento, ' ', grandeza_alimento, uni_medida_alimento));
                SELECT format_alimentos::jsonb ||
                       FORMAT(
                           '{"%1$s": {"%1$s": %2$s, "grandeza": %3$s, "unidade_de_medida": "%4$s"}}',
                           id_alimento, (alimentos->>nome_alimento)::int, grandeza_alimento, uni_medida_alimento)::jsonb INTO format_alimentos;
            END IF;
        END LOOP;

        RETURN QUERY SELECT format_alimentos, relatorio;
        RETURN;

        END;
$$ language plpgsql;

DROP FUNCTION formatar_alimentos(alimentos json);

select jsonb_set(jsonb '{}', '{name}', (1)::jsonb, true);


