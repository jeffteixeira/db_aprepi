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

            raise notice '======== %', forbidden_fields;
            raise notice '======== %', required_fields;

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

            FOREACH campo IN ARRAY nullable_fields LOOP
                IF (campos->campo) IS NULL THEN
--                     SELECT campos::jsonb || FORMAT('{"%s": %s}', campo, 'null')::jsonb INTO campos;
--                 ELSE
                    keys := array_append(keys, campo);
                    values := array_append(values, 'null');
                ELSE
                    keys := array_append(keys, campo);
                    values := array_append(values, (campos->campo)::text);
                end if;
            END LOOP;

--             select string_agg(key, ', '), string_agg(value::text, ', ') INTO keys_str, values_str
--             from json_each(campos);

            keys_str := array_to_string(keys, ', ');
            values_str := array_to_string(values, ', ');

            insert_str := REGEXP_REPLACE(FORMAT('INSERT INTO %s(%s) VALUES (%s)',nome_tabela, keys_str, values_str), '"', '''', 'g');
            raise notice '%', insert_str;
            EXECUTE insert_str;

            RETURN QUERY SELECT unnest(ARRAY[FORMAT('Novo %s cadastrado com sucesso!', nome_tabela)]);

            EXCEPTION
            WHEN unique_violation THEN
                RETURN QUERY SELECT unnest(
                    ARRAY[CONCAT('Campo já cadastrado! ', SQLERRM)]);
            WHEN others THEN
                RETURN QUERY SELECT unnest(
                    ARRAY[CONCAT('Erro durante o cadastro -> ', SQLERRM)]);
        END;
    $$ language plpgsql;

CREATE OR REPLACE FUNCTION cadastrar(nome_tabela varchar, campos json)
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
                RETURN QUERY SELECT unnest(
                    ARRAY[CONCAT('Erro durante o cadastro: ', SQLERRM)]);
        END;
    $$ language plpgsql;


create or replace function encaminhar_tabela(nome_tabela varchar, campos json)
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
            RETURN QUERY SELECT unnest(
                ARRAY[CONCAT('Use a função especifica para esta tabela.')]);
            RETURN;

		ELSEIF lower_nome_tabela = 'medico_especialidade' then
            RETURN QUERY SELECT unnest(
                ARRAY[CONCAT('Use a função especifica para esta tabela.')]);
            RETURN;

        ELSEIF lower_nome_tabela = 'evento' then
            RETURN QUERY SELECT unnest(
                ARRAY[CONCAT('Use a função especifica para esta tabela.')]);
            RETURN;

        ELSEIF lower_nome_tabela = 'voluntario_funcao' then
            RETURN QUERY SELECT unnest(
                ARRAY[CONCAT('Use a função especifica para esta tabela.')]);
            RETURN;

        ELSEIF lower_nome_tabela = 'benfeitor_evento' then
            RETURN QUERY SELECT unnest(
                ARRAY[CONCAT('Use a função especifica para esta tabela.')]);
            RETURN;

        ELSEIF lower_nome_tabela = 'cesta_basica' then
            IF campos->'item_cesta' IS NULL THEN
                RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [item_cesta] para usar a função "inserir_item_cesta" desta tabela';
            ELSEIF campos->'quantidade' IS NULL THEN
                RAISE ERROR_IN_ASSIGNMENT USING
                MESSAGE = 'Informe a chave [quantidade] para usar a função "inserir_item_cesta" desta tabela';
            end if;
            string := (campos->'item_cesta')::varchar;
            SELECT campos::jsonb - 'cpf_benfeitor' INTO campos;
            RETURN QUERY SELECT inserir_item_cesta_basica(trim('"' FROM string::text), (campos->>'quantidade')::int);
            RETURN;

        ELSE
            RETURN QUERY SELECT unnest(
                ARRAY[CONCAT('Tabela desconhecida.')]);
            RETURN;
		END IF;
    END;
$$ language plpgsql;

drop function multi_cadastrar(nome_tabela varchar, array_json json[]);
create or replace function multi_cadastrar(nome_tabela varchar, array_json json)
RETURNS table (n text) as $$
    DECLARE
        json_item json;
    BEGIN
        FOR json_item IN SELECT * FROM json_array_elements(array_json) LOOP
            RETURN QUERY SELECT cadastrar(nome_tabela, json_item);
        end loop;
        RETURN;
    END;
$$ language plpgsql;



SELECT multi_cadastrar('ALIMENTO', json '[
{
"nome": "oleo",
"descricao": "óleo de cozinha",
"quantidade": 88,
"grandeza": 900,
"unidade_de_medida": "ML"
},
{
"nome": "feijao",
"descricao": "Feijão carioca",
"quantidade": 88,
"grandeza": 1,
"unidade_de_medida": "KG"
},
{
"nome": "leite",
"descricao": "Leite longa vida",
"quantidade": 54,
"grandeza": 1,
"unidade_de_medida": "L"
},
{
"nome": "acucar",
"descricao": "Açucar refinado",
"quantidade": 73,
"grandeza": 1,
"unidade_de_medida": "KG"
},
{
"nome": "macarrao",
"descricao": "Macarrão spaghetti",
"quantidade": 91,
"grandeza": 500,
"unidade_de_medida": "G"
},
{
"nome": "sardinha",
"descricao": "Sardinha enlatada",
"quantidade": 81,
"grandeza": 125,
"unidade_de_medida": "G"
},
{
"nome": "biscoito",
"descricao": "Biscoito cream cracker 3 em 1",
"quantidade": 61,
"grandeza": 400,
"unidade_de_medida": "G"
},
{
"nome": "refresco",
"descricao": "Refresco em pó",
"quantidade": 92,
"grandeza": 30,
"unidade_de_medida": "G"
},
{
"nome": "farinha",
"descricao": "Farinha de mandioca",
"quantidade": 72,
"grandeza": 500,
"unidade_de_medida": "G"
},
{
"nome": "sal",
"descricao": "Sal refinado",
"quantidade": 49,
"grandeza": 1,
"unidade_de_medida": "KG"
},
{
"nome": "cafe",
"descricao": "Café a vacúo",
"quantidade": 62,
"grandeza": 500,
"unidade_de_medida": "G"
}
]');

select * from alimento;
delete from alimento where cod_alimento in (2, 4, 10);