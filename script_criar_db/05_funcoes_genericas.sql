
-- BUSCAR CHAVE VALOR

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
$$ language plpgsql SECURITY DEFINER;

-- ENCAMINHAR TABELAS ESPECIFICAS

CREATE or REPLACE FUNCTION encaminhar_tabela(nome_tabela varchar, campos json)
RETURNS table (n text) as
$$
    DECLARE
        string varchar;
        lower_nome_tabela varchar := lower(nome_tabela);

    BEGIN
        IF lower_nome_tabela = 'doacao' or lower_nome_tabela = 'item_doacao' then
            IF campos->'cpf_benfeitor' IS NULL THEN
                RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [cpf_benfeitor] para usar a função "realizar_doacao" desta tabela';
            end if;
            string := (campos->'cpf_benfeitor')::varchar;
            SELECT campos::jsonb - 'cpf_benfeitor' INTO campos;
            RETURN QUERY SELECT realizar_doacao(string, campos);
            RETURN;

        ELSEIF lower_nome_tabela = 'recebimento' or lower_nome_tabela = 'item_recebimento' then
            IF campos->'cpf_socio' IS NULL THEN
                RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [cpf_socio] para usar a função "receber_doacao" desta tabela';
            end if;
            string := (campos->'cpf_socio')::varchar;
            SELECT campos::jsonb - 'cpf_socio' INTO campos;
            RETURN QUERY SELECT receber_doacao(string, campos);
            RETURN;

		ELSEIF lower_nome_tabela = 'consulta' then

		    IF campos->'nome_medico' IS NULL THEN
                RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [nome_medico] para usar a função "marcar_consulta" desta tabela';
            ELSEIF campos->'nome_especialidade' IS NULL THEN
		        RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [nome_especialidade] para usar a função "marcar_consulta" desta tabela';
            ELSEIF campos->'cpf_socio' IS NULL THEN
		        RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [cpf_socio] para usar a função "marcar_consulta" desta tabela';
            ELSEIF campos->'data' IS NULL THEN
		        RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [data] para usar a função "marcar_consulta" desta tabela';
            ELSEIF campos->'hora' IS NULL THEN
		        RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [hora] para usar a função "marcar_consulta" desta tabela';
            end if;

            RETURN QUERY SELECT marcar_consulta(
                campos->>'nome_medico',
                campos->>'nome_especialidade',
                campos->>'cpf_socio',
                campos->>'data',
                campos->>'hora');
            RETURN;

		ELSEIF lower_nome_tabela = 'medico' then
            if ((select cod_medico from medico where nome ilike campos->>'nome') is not null) then
           		RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Médico(a) já cadastrado(a)';
            elseif (campos->>'nome_especialidade' is null) or (buscar_cod_especialidade(campos->>'nome_especialidade') is null) then
            	RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Médicos não podem ser cadastrados sem uma especialidade';
            end if;

           	return query select cadastrar_medico(campos);
            RETURN QUERY select alocar_medico_em_especialidade(campos->>'nome',campos->>'nome_especialidade');
            RETURN;

        elseif lower_nome_tabela = 'medico_especialidade' then
			if (qntd_especialidades_medico(campos->>'nome') > 1) then
				RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'O médico já possui 2 especialidades cadastradas';
            end if;

            RETURN QUERY select alocar_medico_em_especialidade(campos->>'nome',campos->>'nome_especialidade');
            RETURN;

		ELSEIF lower_nome_tabela = 'medico_especialidade' then

		    IF campos->'nome_medico' IS NULL THEN
                RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [nome_medico] para usar a função ' ||
                          '"alocar_medico_em_especialidade" desta tabela';
            ELSEIF campos->'nome_especialidade' IS NULL THEN
		        RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [nome_especialidade] para usar a função ' ||
                          '"alocar_medico_em_especialidade" desta tabela';
            end if;

            RETURN QUERY SELECT alocar_medico_em_especialidade(
            campos->>'nome_medico',
            campos->>'nome_especialidade');
            RETURN;

        ELSEIF lower_nome_tabela = 'evento' then
            IF campos->'nome_evento' IS NULL THEN
                RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [nome_evento] para usar a função ' ||
                          '"criar_evento" desta tabela';
            ELSEIF campos->'nome_tipo_evento' IS NULL THEN
		        RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [nome_tipo_evento] para usar a função ' ||
                          '"criar_evento" desta tabela';
            end if;

            RETURN QUERY SELECT criar_evento(
    campos->>'nome_evento',
    campos->>'nome_tipo_evento',
    coalesce((campos->>'valor_arrecacao')::float, '0'),
    coalesce((campos->>'valor_custo')::float, '0'),
    coalesce((campos->>'data_inicio')::date, current_date),
    (campos->>'data_fim')::date);
            RETURN;

        ELSEIF lower_nome_tabela = 'voluntario_funcao' then
            IF campos->'nome_evento' IS NULL THEN
                RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [nome_evento] para usar a função ' ||
                          '"alocar_voluntario_em_evento" desta tabela';
            ELSEIF campos->'cpf_voluntario' IS NULL THEN
		        RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [cpf_voluntario] para usar a função ' ||
                          '"alocar_voluntario_em_evento" desta tabela';
            ELSEIF campos->'nome_funcao' IS NULL THEN
		        RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [nome_funcao] para usar a função ' ||
                          '"alocar_voluntario_em_evento" desta tabela';
            end if;

            RETURN QUERY SELECT alocar_voluntario_em_evento(
    campos->>'nome_evento',
    campos->>'cpf_voluntario',
    campos->>'nome_funcao');
            RETURN;

        ELSEIF lower_nome_tabela = 'benfeitor_evento' then
            IF campos->'nome_evento' IS NULL THEN
                RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [nome_evento] para usar a função ' ||
                          '"doar_para_evento" desta tabela';
            ELSEIF campos->'cpf_benfeitor' IS NULL THEN
		        RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [cpf_benfeitor] para usar a função ' ||
                          '"doar_para_evento" desta tabela';
            ELSEIF campos->'valor_doacao' IS NULL THEN
		        RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [valor_doacao] para usar a função ' ||
                          '"doar_para_evento" desta tabela';
            end if;

            RETURN QUERY SELECT doar_para_evento(
    campos->>'nome_evento',
    campos->>'cpf_benfeitor',
    (campos->>'valor_doacao')::float);
            RETURN;

        ELSEIF lower_nome_tabela = 'cesta_basica' then
            IF campos->'nome_alimento' IS NULL THEN
                RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [nome_alimento] para usar a função "inserir_item_cesta" desta tabela';
            ELSEIF campos->'qtd' IS NULL THEN
                RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [qtd] para usar a função "inserir_item_cesta" desta tabela';
            end if;
            string := (campos->>'nome_alimento')::varchar;
            RETURN QUERY SELECT inserir_item_cesta_basica(string, (campos->>'qtd')::int);
            RETURN;

        ELSE
            RETURN QUERY SELECT 'Tabela desconhecida.';
            RETURN;
		END IF;
    END
$$ language plpgsql SECURITY DEFINER;

-- CADASTRAR_GENERICO

CREATE OR REPLACE FUNCTION cadastrar_generico(nome_tabela varchar, campos json, forbidden_fields text[])
    RETURNS table (n text) as $$
        DECLARE
            required_fields text [];
            nullable_fields text [];
            campo text;
            erros text[]:= '{"OS SEGUINTES ERROS FORAM ENCONTRADOS"}';
            campos_validos boolean := true;
            keys_str text;
            keys text[];
            values_str text;
            values text[];
            insert_str text;
        BEGIN

            SELECT array_agg(column_name::TEXT) INTO required_fields
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE table_name ilike nome_tabela and is_nullable ilike 'NO' and
                  not column_name = ANY(forbidden_fields);

            FOREACH campo IN ARRAY required_fields LOOP
                IF (campos->campo) IS NULL THEN
                    raise notice '[%] nao pode ser vazio', campo;
                    erros := array_append(erros, concat('[', campo, '] não pode ser vazio'));
                    campos_validos := false;
                ELSE
                    keys := array_append(keys, campo);
                    values := array_append(values, (campos->campo)::text);
                end if;
            END LOOP;

            IF NOT campos_validos THEN
                RETURN QUERY SELECT nome FROM unnest(erros) as nome;
                RETURN;
            end if;

            SELECT array_agg(column_name::TEXT) INTO nullable_fields
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE table_name ilike nome_tabela and is_nullable ilike 'YES' and
                  not column_name = ANY(forbidden_fields);

						IF array_length(nullable_fields, 1) > 0 THEN
                FOREACH campo IN ARRAY nullable_fields LOOP
                    IF (campos->campo) IS NULL THEN
                        keys := array_append(keys, campo);
                        values := array_append(values, 'null');
                    ELSE
                        keys := array_append(keys, campo);
                        values := array_append(values, (campos->campo)::text);
                    end if;
                END LOOP;
            end if;

            keys_str := array_to_string(keys, ', ');
            values_str := array_to_string(values, ', ');

            insert_str := REGEXP_REPLACE(FORMAT('INSERT INTO %s(%s) VALUES (%s)',nome_tabela, keys_str, values_str), '"', '''', 'g');
            raise notice '%', insert_str;
            EXECUTE insert_str;

            RETURN QUERY SELECT FORMAT('Novo(a) %s cadastrado(a) com sucesso!', nome_tabela);

            EXCEPTION
            WHEN unique_violation THEN
                RETURN QUERY SELECT 'Campo já cadastrado -> ' || SQLERRM;
            WHEN others THEN
                RETURN QUERY SELECT 'Erro durante o cadastro -> ' || SQLERRM;
        END;
    $$ language plpgsql SECURITY DEFINER;

-- CADASTRAR (FUNCAO PRINCIPAL)

CREATE OR REPLACE FUNCTION cadastrar(nome_tabela varchar, campos json)
    RETURNS table (n text) as $$
        DECLARE
            forbidden_fields_by_table json := '{"SOCIO": ["dt_falecimento", "cod_socio"],' ||
                                              '"BENFEITOR": ["cod_benfeitor"],' ||
                                              '"TIPO_EVENTO": ["cod_tipo_evento"],' ||
                                              '"ESPECIALIDADE": ["cod_especialidade"],' ||
                                              '"VOLUNTARIO": ["cod_voluntario"],' ||
                                              '"FUNCAO": ["cod_funcao"],' ||
                                              '"ALIMENTO": ["cod_alimento"]}';
            forbidden_tables varchar[] := '{"consulta", ' ||
                                          '"recebimento", ' ||
                                          '"doacao", ' ||
                                          '"item_recebimento", ' ||
                                          '"item_doacao", ' ||
                                          '"medico", ' ||
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
                RETURN QUERY SELECT encaminhar_tabela(nome_tabela, campos);
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

            RETURN QUERY SELECT cadastrar_generico(nome_tabela_upper, campos, forbidden_fields);
            RETURN;

            EXCEPTION
            WHEN ERROR_IN_ASSIGNMENT THEN
                RETURN QUERY SELECT SQLERRM;
            WHEN others THEN
                RETURN QUERY SELECT 'Erro durante o cadastro -> ' || SQLERRM;
        END
    $$ language plpgsql SECURITY DEFINER;

--  ATUALIZAR_GENERICO

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
    $$ language plpgsql SECURITY DEFINER;

-- ATUALIZAR (FUNCAO PRINCIPAL)

CREATE OR REPLACE FUNCTION atualizar(nome_tabela varchar, chave varchar, valor varchar, campos json)
    RETURNS table (n text) as $$
        DECLARE
            forbidden_fields_by_table json := '{"SOCIO": ["cod_socio"],' ||
                                              '"BENFEITOR": ["cod_benfeitor"],' ||
                                              '"TIPO_EVENTO": ["cod_tipo_evento"],' ||
                                              '"EVENTO": ["cod_evento", "cod_tipo_evento"],' ||
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
                RETURN QUERY SELECT 'Erro durante o cadastro -> ' || SQLERRM;
        END
    $$ language plpgsql SECURITY DEFINER;

--  DELETAR_GENERICO

CREATE OR REPLACE FUNCTION deletar_generico(nome_tabela varchar, chave varchar, valor varchar)
    RETURNS table (n text) as $$
        DECLARE
            qtd_r int;
            c_name varchar;
            c_values varchar;

            delete_str text;
        BEGIN

            SELECT cod_name, cod_value, qtd_registros into c_name, c_values, qtd_r from buscar_chave_valor(
                nome_tabela, chave, valor);


            delete_str := FORMAT('DELETE FROM %1$s WHERE %2$s IN %3$s', nome_tabela, c_name, c_values);
            raise notice '%', delete_str;
            EXECUTE delete_str;

            IF qtd_r = 1 THEN
                RETURN QUERY SELECT qtd_r || ' registro atualizado';
            ELSE
                RETURN QUERY SELECT qtd_r || ' registros atualizados';
            END IF;

            EXCEPTION
            WHEN CASE_NOT_FOUND OR ERROR_IN_ASSIGNMENT THEN
                RETURN QUERY SELECT unnest(ARRAY[SQLERRM]);
            WHEN others THEN
                RETURN QUERY SELECT unnest(
                    ARRAY[CONCAT('Erro durante a deleção -> ', SQLERRM)]);

        END;
    $$ language plpgsql SECURITY DEFINER;

-- DELETAR (FUNCAO PRINCIPAL)

CREATE OR REPLACE FUNCTION deletar(nome_tabela varchar, chave varchar, valor varchar)
    RETURNS table (n text) as $$
        DECLARE
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
            END IF;

            -- SANITIZE DE CPF
            IF chave = 'cpf' THEN
                valor := validador_cpf(valor);
            end if;

            RETURN QUERY SELECT deletar_generico(nome_tabela_upper, chave, valor);
            RETURN;

            EXCEPTION
            WHEN ERROR_IN_ASSIGNMENT OR CASE_NOT_FOUND THEN
                RETURN QUERY SELECT SQLERRM;
            WHEN others THEN
                RETURN QUERY SELECT unnest(
                    ARRAY[CONCAT('Erro durante a delecao -> ', SQLERRM)]);
        END;
    $$ language plpgsql SECURITY DEFINER;





