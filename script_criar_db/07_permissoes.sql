-- CONFIGURACAO DE FUNCOES
ALTER FUNCTION cadastrar(nome_tabela varchar, campos json) SECURITY DEFINER SET search_path = default;
REVOKE ALL ON FUNCTION cadastrar(nome_tabela varchar, campos json) FROM PUBLIC;

ALTER FUNCTION atualizar(nome_tabela varchar, chave varchar, valor varchar, campos json) SECURITY DEFINER SET search_path = default;
REVOKE ALL ON FUNCTION atualizar(nome_tabela varchar, chave varchar, valor varchar, campos json) FROM PUBLIC;

ALTER FUNCTION deletar(nome_tabela varchar, chave varchar, valor varchar) SECURITY DEFINER SET search_path = default;
REVOKE ALL ON FUNCTION deletar(nome_tabela varchar, chave varchar, valor varchar) FROM PUBLIC;
REVOKE ALL ON FUNCTION encaminhar_tabela(nome_tabela varchar, campos json) FROM PUBLIC;

-- DOACAO DE ALIMENTOS
REVOKE ALL ON FUNCTION montar_cesta_basica() FROM PUBLIC;
REVOKE ALL ON FUNCTION formatar_alimentos(alimentos json) FROM PUBLIC;
REVOKE ALL ON FUNCTION informar_falecimento_socio(cpf varchar) FROM PUBLIC;
REVOKE ALL ON FUNCTION inserir_item_cesta_basica(nome_alimento varchar, qtd int) FROM PUBLIC;
REVOKE ALL ON FUNCTION deletar_item_cesta_basica(nome_alimento varchar) FROM PUBLIC;
REVOKE ALL ON FUNCTION listar_cesta_basica() FROM PUBLIC;
REVOKE ALL ON FUNCTION realizar_doacao(cpf_benfeitor varchar, alimentos json, id_doacao int) FROM PUBLIC;
REVOKE ALL ON FUNCTION receber_doacao(cpf_socio varchar, alimentos json, id_recebimento int) FROM PUBLIC;

-- EVENTO
REVOKE ALL ON FUNCTION criar_evento(
nome_evento varchar,
nome_tipo_evento varchar,
valor_arrecacao float,
valor_custo float,
data_inicio date,
data_fim date) FROM PUBLIC;
REVOKE ALL ON FUNCTION doar_para_evento(nome_evento varchar, cpf_benfeitor varchar, valor_doacao float) FROM PUBLIC;
REVOKE ALL ON FUNCTION adicionar_custo_evento(nome_evento varchar, valor_custo float) FROM PUBLIC;
REVOKE ALL ON FUNCTION atualizar_data_final_evento(nome_evento varchar, data_fim date) FROM PUBLIC;

REVOKE ALL ON FUNCTION alocar_voluntario_em_evento(nome_evento varchar, cpf_voluntario varchar, nome_funcao varchar) FROM PUBLIC;
REVOKE ALL ON FUNCTION remover_voluntario_de_evento(nome_evento varchar, cpf_voluntario varchar) FROM PUBLIC;
REVOKE ALL ON FUNCTION remover_voluntario_de_evento_pela_funcao(
    nome_evento varchar, cpf_voluntario varchar, nome_funcao varchar) FROM PUBLIC;
REVOKE ALL ON FUNCTION listar_funcoes_voluntario_evento(nome_evento varchar) FROM PUBLIC;
REVOKE ALL ON FUNCTION listar_eventos_por_voluntario(cpf_voluntario varchar, eventos_ativos boolean) FROM PUBLIC;

-- CONSULTA MEDICO
REVOKE ALL ON FUNCTION alocar_medico_em_especialidade(nome_medico varchar, nome_especialidade varchar) FROM PUBLIC;
REVOKE ALL ON FUNCTION remover_especialidade_de_medico(nome_medico varchar, nome_especialidade varchar) FROM PUBLIC;
REVOKE ALL ON FUNCTION listar_consultas_medico(_nome_medico varchar, data_consulta date) FROM PUBLIC;
REVOKE ALL ON FUNCTION marcar_consulta(
    nome_medico varchar,
    nome_especialidade varchar,
    cpf_socio varchar,
    data date,
    hora time) FROM PUBLIC;

REVOKE ALL ON FUNCTION buscar_chave_valor(nome_tabela varchar, chave varchar, valor varchar) FROM PUBLIC;

REVOKE ALL ON FUNCTION
    atualizar_generico(nome_tabela varchar, chave varchar, valor varchar,  campos json, forbidden_fields text[])
FROM PUBLIC;
REVOKE ALL ON FUNCTION cadastrar_generico(nome_tabela varchar, campos json, forbidden_fields text[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION deletar_generico(nome_tabela varchar, chave varchar, valor varchar) FROM PUBLIC;

-- FUNCIONARIO

CREATE ROLE funcionario;

GRANT EXECUTE ON FUNCTION cadastrar(varchar, json) TO funcionario;
GRANT EXECUTE ON FUNCTION atualizar(nome_tabela varchar, chave varchar, valor varchar, campos json) TO funcionario;
GRANT EXECUTE ON FUNCTION listar_cesta_basica() TO funcionario;
GRANT EXECUTE ON FUNCTION inserir_item_cesta_basica(nome_alimento varchar, qtd int) TO funcionario;
GRANT EXECUTE ON FUNCTION realizar_doacao(cpf_benfeitor varchar, alimentos json, id_doacao int) TO funcionario;
GRANT EXECUTE ON FUNCTION receber_doacao(cpf_socio varchar, alimentos json, id_recebimento int) TO funcionario;
GRANT EXECUTE ON FUNCTION informar_falecimento_socio(cpf varchar) TO funcionario;


GRANT SELECT ON socio TO funcionario;
GRANT SELECT ON benfeitor TO funcionario;
GRANT SELECT ON alimento TO funcionario;
GRANT SELECT ON evento TO funcionario;
GRANT SELECT ON voluntario TO funcionario;
GRANT SELECT ON funcao TO funcionario;
GRANT SELECT ON medico TO funcionario;
GRANT SELECT ON especialidade TO funcionario;

CREATE USER flavio PASSWORD 'postgres01';

GRANT funcionario TO flavio;

-- ADMINISTRADOR
CREATE ROLE administrador;

GRANT funcionario to administrador;
GRANT EXECUTE ON FUNCTION deletar(nome_tabela varchar, chave varchar, valor varchar) TO administrador;

CREATE USER jose PASSWORD 'postgres01';
GRANT administrador TO jose;

CREATE ROLE medico;
GRANT EXECUTE ON FUNCTION listar_consultas_medico(_nome_medico varchar, data_consulta date) TO medico;
CREATE USER heloisa PASSWORD 'postgres01';
GRANT medico TO heloisa;

CREATE ROLE doacoes;
GRANT EXECUTE ON FUNCTION relatorio_doacoes_feitas_eventos(campos json) TO doacoes;
GRANT EXECUTE ON FUNCTION relatorio_doacoes_recebidas(campos json) TO doacoes;
GRANT EXECUTE ON FUNCTION relatorio_doacoes_feitas(campos json) TO doacoes;

CREATE USER luan PASSWORD 'postgres01';
GRANT doacoes TO luan;

-- select usesysid as user_id,
--        usename as username,
--        usesuper as is_superuser,
--        passwd as password_md5,
--        valuntil as password_expiration
-- from pg_shadow
-- order by usename;
