select cadastrar('ALIMENTO', json '{
	"nome": "arroz",
	"descricao": "Arroz",
	"quantidade": 96,
    "grandeza": 1,
    "unidade_de_medida": "KG"
}');

select listar_alimentos();

-- DOACAO

select cadastrar('BENFEITOR', json '{
  "nome": "Luan Marcos Vinicius da Costa",
  "cpf": "533.550.193-64",
  "dt_nasc": "1989-09-15",
  "telefone": "(86) 99866-8152"}');

select listar_cesta_basica();

select inserir_item_cesta_basica('arroz', 5);

select realizar_doacao('533.550.193-64', json '{"arroz": 30, "feijao": 30, "leite": 12}');

select relatorio_doacoes_feitas(json'{"cpf_benfeitor": "533.550.193-64"}');

select realizar_doacao('533.550.193-64', json '{"cesta_basica": 10}');

-- RECEBIMENTO

select cadastrar('SOCIO', json '{
  "nome": "Laura Betina Rezende",
  "cpf": "576.780.563-62",
  "dt_nasc": "1968-06-20",
  "telefone": "(86) 98165-7414"}');

select receber_doacao('576.780.563-62', json '{"cesta_basica": 1}');

select relatorio_doacoes_recebidas(json'{"cpf_benfeitor": "576.780.563-62"}');

select receber_doacao('576.780.563-62', json '{"arroz": 10000}');

select informar_falecimento_socio('576.780.563-62');

select receber_doacao('576.780.563-62', json '{"farinha": 2}');






