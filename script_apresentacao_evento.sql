-- Chaves Possiveis no cadastro de evento
-- "nome_evento"
-- "nome_tipo_evento"
-- "valor_arrecacao"
-- "valor_custo"
-- "data_inicio"
-- "data_fim"

select cadastrar('EVENTO', json '{
	"nome_evento": "Bazar aprepi 2020",
    "nome_tipo_evento": "bazar",
    "data_fim": "2020-11-13"
}');

select * from listar_tipos_evento();

select cadastrar('BENFEITOR', json '{
  "nome": "Leonardo Sérgio Raimundo Moura",
  "genero": "masculino",
  "cpf": "003.851.923-20",
  "dt_nasc": "1989-12-12",
  "telefone": "(51) 99855-7333"}');

select doar_para_evento('bazar aprepi 2020', '003.851.923-20', 1000);

select relatorio_doacoes_feitas_eventos(json '{"cpf_benfeitor": "003.851.923-20"}');

select adicionar_custo_evento('bazar aprepi 2020', 200);

select * from listar_eventos();

select atualizar_data_final_evento('bazar aprepi 2020', '2020-11-10');


select cadastrar('VOLUNTARIO', json '{
  "nome": "Gustavo Kaique dos Santos",
  "genero": "masculino",
  "cpf": "608.049.543-05",
  "dt_nasc": "1986-11-16",
  "telefone": "(61) 98478-2243"}');

select * from listar_funcoes();

select alocar_voluntario_em_evento('bazar aprepi 2020', '608.049.543-05', 'seguranca');

select listar_funcoes_voluntario_evento('bazar aprepi 2020');

select remover_voluntario_de_evento_pela_funcao('bazar aprepi 2020', '608.049.543-05', 'seguranca');

select listar_funcoes_voluntario_evento('bazar aprepi 2020');

select remover_voluntario_de_evento('bazar aprepi 2020', '608.049.543-05');

select listar_eventos_por_voluntario('608.049.543-05', true);