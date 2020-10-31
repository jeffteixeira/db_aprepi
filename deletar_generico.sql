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
    $$ language plpgsql;


SELECT atualizar_generico('socio','cpf','78025262057', json '{"nome": "Joao", "dt_nasc": "1999-01-01"}', ARRAY ['cod_socio']);
SELECT deletar('socio','cpf', '720.914.248-70');
SELECT cadastrar('socio', json '
{
	"nome": "Severino Henry da Silva",
	"cpf": "720.914.248-70",
	"dt_nasc": "1975-10-19",
	"telefone": "(79) 98944-3867"

}
');

select * from socio;
DROP FUNCTION buscar_chave_valor(nome_tabela varchar, chave varchar, valor varchar);


select * from buscar_chave_valor('socio', 'cpf', '78025262057');

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
    $$ language plpgsql;
