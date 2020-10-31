CREATE OR REPLACE FUNCTION atualizar_generico(nome_tabela varchar, chave varchar, valor varchar,  campos json, forbidden_fields text[])
    RETURNS table (n text) as $$
        DECLARE
            table_fields text [];
            valid_fields text [];
            qtd_r int;
            c_name varchar;
            c_values varchar;

            keys text[];
            key text;

            update_str text;
        BEGIN

            SELECT cod_name, cod_value, qtd_registros into c_name, c_values, qtd_r from buscar_chave_valor(
                nome_tabela, chave, valor);

            SELECT array_agg(column_name::TEXT) INTO table_fields
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE table_name ilike nome_tabela and
                  not column_name = ANY(forbidden_fields);

            FOR key in SELECT json_object_keys(campos) LOOP
                IF key ILIKE ANY(table_fields) THEN
                    valid_fields := array_append(valid_fields, key);
                end if;
            end loop;

            FOREACH key in ARRAY valid_fields LOOP
                keys := array_append(keys, FORMAT('%1$s = ''%2$s''', key, campos->>key));
            end loop;

            update_str := FORMAT('UPDATE %1$s SET %2$s WHERE %3$s IN %4$s', nome_tabela, array_to_string(keys, ', '), c_name, c_values);
            raise notice '%', update_str;
            EXECUTE update_str;

            IF qtd_r = 1 THEN
                RETURN QUERY SELECT qtd_r || ' registro atualizado';
            ELSE
                RETURN QUERY SELECT qtd_r || ' registros atualizados';
            END IF;

            EXCEPTION
            WHEN CASE_NOT_FOUND OR ERROR_IN_ASSIGNMENT THEN
            RETURN QUERY SELECT unnest(ARRAY[SQLERRM]);
            WHEN unique_violation THEN
                RETURN QUERY SELECT unnest(
                    ARRAY[CONCAT('Campo já cadastrado! -> ', SQLERRM)]);
            WHEN others THEN
                RETURN QUERY SELECT unnest(
                    ARRAY[CONCAT('Erro durante o cadastro -> ', SQLERRM)]);

        END;
    $$ language plpgsql;


SELECT atualizar_generico('socio','cpf','78025262057', json '{"nome": "Joao", "dt_nasc": "1999-01-01"}', ARRAY ['cod_socio']);
SELECT atualizar('socio','cpf', '78025262057', json '{"nome": "JooJ", "dt_nasc": "1999-01-01"}');
select * from socio;
DROP FUNCTION buscar_chave_valor(nome_tabela varchar, chave varchar, valor varchar);
CREATE OR REPLACE FUNCTION buscar_chave_valor(nome_tabela varchar, chave varchar, valor varchar)
    RETURNS table (cod_name varchar, cod_value varchar, qtd_registros int) as $$
    declare
        c_name varchar;
        c_values varchar[];
    BEGIN
        SELECT c.column_name INTO c_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage AS ccu USING (constraint_schema, constraint_name)
        JOIN information_schema.columns AS c ON c.table_schema = tc.constraint_schema
          AND tc.table_name = c.table_name AND ccu.column_name = c.column_name
        WHERE constraint_type = 'PRIMARY KEY' and tc.table_name ilike nome_tabela;

        EXECUTE FORMAT('SELECT array_agg(%1$s::text) FROM %2$s WHERE %3$s = ''%4$s''', c_name, nome_tabela, chave, valor) INTO c_values;

        IF c_name IS NULL THEN
            RAISE CASE_NOT_FOUND USING MESSAGE = 'Tabela' || nome_tabela || 'Não encontrada.';
        ELSEIF c_values IS NULL THEN
            RAISE CASE_NOT_FOUND USING MESSAGE = 'Nenhum registro encontrado para a chave e valor procurados.';
        end if;

        RETURN QUERY SELECT c_name, FORMAT('(%1$s)', array_to_string(c_values, ','))::varchar, array_length(c_values, 1);
        RETURN;
    END;
$$ language plpgsql;

select * from buscar_chave_valor('socio', 'cpf', '78025262057');

CREATE OR REPLACE FUNCTION atualizar(nome_tabela varchar, chave varchar, valor varchar, campos json)
    RETURNS table (n text) as $$
        DECLARE
            forbidden_fields_by_table json := '{"SOCIO": ["dt_falecimento", "cod_socio"],' ||
                                              '"BENFEITOR": ["cod_benfeitor"],' ||
                                              '"MEDICO": ["cod_medico"],' ||
                                              '"ESPECIALIDADE": ["cod_especialidade"],' ||
                                              '"VOLUNTARIO": ["cod_voluntario"],' ||
                                              '"FUNCAO": ["cod_funcao"],' ||
                                              '"ALIMENTO": ["cod_alimento"]}';
            forbidden_tables varchar[] := '{"consulta", ' ||
                                          '"recebimento", ' ||
                                          '"doacao", ' ||
                                          '"item_recebimento", ' ||
                                          '"item_doacao", ' ||
                                          '"medico_especialidade", ' ||
                                          '"voluntario_funcao", ' ||
                                          '"evento", ' ||
                                          '"cesta_basica", ' ||
                                          '"benfeitor_evento"}';
            forbidden_fields text [];
            fbn_field json;
            table_exists boolean;
            nome_tabela_upper varchar := upper(nome_tabela);
        BEGIN
            SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name ilike nome_tabela) INTO table_exists;

            IF nome_tabela ILIKE ANY(forbidden_tables) THEN
                RETURN QUERY SELECT 'Essa tabela é controlada pelo sistema e não pode ser manipulada.';
                RETURN;
            ELSEIF NOT table_exists THEN

                RETURN QUERY SELECT unnest(
                    ARRAY[CONCAT('A tabela ', nome_tabela, ' não foi encontrada, verifique o nome e tente novamente.')]);
                    RETURN;
            ELSEIF (forbidden_fields_by_table->nome_tabela_upper) IS NULL THEN
                RETURN QUERY SELECT unnest(
                    ARRAY[CONCAT('A tabela ', nome_tabela, ' não foi cadastrada corretamente. Contate o administrador.')]);
                    RETURN;
            END IF;

            FOR fbn_field IN
                SELECT json_array_elements FROM json_array_elements(forbidden_fields_by_table->nome_tabela_upper) LOOP
                forbidden_fields := array_append(forbidden_fields, REGEXP_REPLACE(fbn_field::text, '"', '', 'g'));
            END LOOP;

            raise notice '%', forbidden_fields;

            -- SANITIZE DE CPF
            IF chave = 'cpf' THEN
                valor := validador_cpf(valor);
            end if;

            RETURN QUERY SELECT atualizar_generico(nome_tabela_upper, chave, valor, campos, forbidden_fields);
            RETURN;

            EXCEPTION
            WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
                RETURN QUERY SELECT SQLERRM;
            WHEN others THEN
                RETURN QUERY SELECT unnest(
                    ARRAY[CONCAT('Erro durante o cadastro -> ', SQLERRM)]);
        END;
    $$ language plpgsql;


SELECT c.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage AS ccu USING (constraint_schema, constraint_name)
JOIN information_schema.columns AS c ON c.table_schema = tc.constraint_schema
  AND tc.table_name = c.table_name AND ccu.column_name = c.column_name
WHERE constraint_type = 'PRIMARY KEY' and tc.table_name = 'socio';
