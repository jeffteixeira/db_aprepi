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

-- SOCIOS

SELECT multi_cadastrar('SOCIO', json '[
  {
	"nome": "Tereza Sandra Caroline Assis",
    "genero": "feminino",
	"cpf": "049.120.020-03",
	"dt_nasc": "1946-11-08",
	"telefone": "(69) 98359-1247"
},
{
	"nome": "Nelson Osvaldo Luiz da Silva",
    "genero": "masculino",
	"cpf": "883.228.475-80",
	"dt_nasc": "1977-02-11",
	"telefone": "(65) 99384-6415"
},
{
	"nome": "Bernardo Ricardo Oliveira",
	"cpf": "316.959.744-25",
    "genero": "masculino",
	"dt_nasc": "1966-09-04",
	"telefone": "(67) 98407-9466"
},
{
	"nome": "Isabelly Daiane Vitória Santos",
	"cpf": "767.848.314-70",
    "genero": "feminino",
	"dt_nasc": "1963-07-15",
	"telefone": "(83) 98876-5727"
},
{
	"nome": "Marcelo Fernando Ian Vieira",
	"cpf": "237.849.720-20",
    "genero": "masculino",
	"dt_nasc": "1941-10-06",
	"telefone": "(83) 99518-1878"
},
{
	"nome": "Raul Calebe Aragão",
	"cpf": "196.366.963-06",
    "genero": "masculino",
	"dt_nasc": "1948-09-22",
	"telefone": "(21) 99347-6985"
},
{
	"nome": "Matheus Danilo Vitor Santos",
    "genero": "masculino",
	"cpf": "881.456.333-03",
	"dt_nasc": "1981-04-16",
	"telefone": "(34) 98812-1519"
}]');

-- BENFEITORES

SELECT multi_cadastrar('BENFEITOR', json '[
  {
	"nome": "Milena Fabiana Bruna Fernandes",
    "genero": "feminino",
	"cpf": "128.948.548-89",
	"dt_nasc": "1963-12-09",
	"telefone": "(21) 98605-2504"
},
{
	"nome": "Pedro Otávio Dias",
	"cpf": "419.711.094-44",
    "genero": "masculino",
	"dt_nasc": "1954-10-23",
	"telefone": "(27) 99902-7129"
},
{
	"nome": "Caroline Ayla Almeida",
	"cpf": "343.879.963-40",
    "genero": "feminino",
	"dt_nasc": "1964-05-15",
	"telefone": "(95) 99730-3746"
},
{
	"nome": "Fabiana Raquel Santos",
	"cpf": "857.034.260-81",
    "genero": "feminino",
	"dt_nasc": "1965-08-21",
	"telefone": "(68) 98854-3791"
},
{
	"nome": "Miguel Luís Pietro Melo",
	"cpf": "464.579.492-23",
    "genero": "masculino",
	"dt_nasc": "1969-06-23",
	"telefone": "(91) 98185-5315"
},
{
	"nome": "Cláudio Pedro Henrique Otávio de Paula",
	"cpf": "768.416.605-01",
    "genero": "masculino",
	"dt_nasc": "1966-06-23",
	"telefone": "(62) 98153-9006"
},
{
	"nome": "Renan Victor Silva",
	"cpf": "469.035.882-64",
    "genero": "masculino",
	"dt_nasc": "1975-06-12",
	"telefone": "(62) 99702-3660"
}]');

-- ALIMENTOS
SELECT multi_cadastrar('ALIMENTO', json '[
    {
        "nome": "arroz",
        "descricao": "Arroz",
        "quantidade": 96,
        "grandeza": 1,
        "unidade_de_medida": "KG"
    },
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
        "unidade_de_medida": "G"}
    ]');

-- CESTA BASICA
SELECT multi_cadastrar('CESTA_BASICA', json '[
    { "nome_alimento": "arroz", "qtd": 5},
    { "nome_alimento": "oleo", "qtd": 1},
    { "nome_alimento": "feijao", "qtd": 1},
    { "nome_alimento": "leite", "qtd": 2},
    { "nome_alimento": "acucar", "qtd": 2},
    { "nome_alimento": "macarrao", "qtd": 2},
    { "nome_alimento": "sardinha", "qtd": 2},
    { "nome_alimento": "biscoito", "qtd": 2},
    { "nome_alimento": "refresco", "qtd": 2},
    { "nome_alimento": "farinha", "qtd": 1},
    { "nome_alimento": "sal", "qtd": 1},
    { "nome_alimento": "cafe", "qtd": 1}]');

-- MEDICO
SELECT multi_cadastrar('MEDICO', json '[
    {
        "nome": "Anthony Vinicius Leonardo Campos",
        "cpf": "567.943.607-80",
        "genero": "masculino",
        "dt_nasc": "1967-01-24",
        "telefone": "(46) 99407-9744",
        "crm": "776845/PI"
    },
    {
        "nome": "Osvaldo Diogo Pires",
        "cpf": "589.702.154-68",
        "genero": "masculino",
        "dt_nasc": "1949-12-27",
        "telefone": "(66) 99437-2496",
        "crm": "1051190/GO"
    },
    {
        "nome": "Renan Otávio Raimundo Dias",
        "cpf": "189.117.157-78",
        "genero": "masculino",
        "dt_nasc": "1973-03-13",
        "telefone": "(79) 99120-6252",
        "crm": "876207/RO"
    },
    {
        "nome": "Igor André Farias",
        "cpf": "631.045.689-01",
        "genero": "masculino",
        "dt_nasc": "1950-03-22",
        "telefone": "(98) 99907-8442",
        "crm": "1056532/PE"
    },
    {
        "nome": "Vera Sarah Simone Teixeira",
        "cpf": "054.001.119-39",
        "genero": "feminino",
        "dt_nasc": "1982-02-14",
        "telefone": "(82) 99406-7902",
        "crm": "837499/CE"
    },
    {
        "nome": "Alana Silvana Sophia Cardoso",
        "cpf": "990.523.024-64",
        "genero": "feminino",
        "dt_nasc": "1969-05-01",
        "telefone": "(82) 98125-7446",
        "crm": "937561/MS"
    },
    {
        "nome": "Carolina Isis Rezende",
        "cpf": "303.005.068-80",
        "genero": "feminino",
        "dt_nasc": "1951-11-07",
        "telefone": "(95) 98774-4069",
        "crm": "692521/MA"}
    ]');

-- ESPECIALIDADE

SELECT multi_cadastrar('ESPECIALIDADE', json '[
    {
        "nome": "oftalmologista",
        "descricao": "O médico oftalmologista prescreve tratamentos e correções para os distúrbios de visão"
    },
    {
        "nome": "nutricionista",
        "descricao": "Presta assistência dietética e promover educação nutricional"
    },
    {
        "nome": "psicologo",
        "descricao": "aplica métodos científicos para compreender a psiquê humana e atuar no tratamento e prevenção de doenças mentais"
    },
    {
        "nome": "cardiologista",
        "descricao": "se ocupa do diagnóstico e tratamento das doenças que acometem o coração"
    },
    {
        "nome": "fisioterapeuta",
        "descricao": "atua no tratamento e prevenção de doenças e lesões, decorrentes de fraturas ou má-formação ou vícios de postura"
    }
]');

-- TIPO_EVENTO

SELECT multi_cadastrar('TIPO_EVENTO', json '[
    {
        "nome": "bazar",
        "descricao": "Venda organizada de objetos para fins de caridade."
    },
    {
        "nome": "feijoada",
        "descricao": "Evento com o objetivo de angariar fundos para a instituição."
    },
    {
        "nome": "jantar",
        "descricao": "Evento com o objetivo de angariar fundos para a instituição."
    },
    {
        "nome": "quermesse",
        "descricao": "Evento com o objetivo de angariar fundos para a instituição."
    },
    {
        "nome": "show",
        "descricao": "Evento com o objetivo de angariar fundos para a instituição."
    }
]');

-- VOLUNTARIO

SELECT multi_cadastrar('VOLUNTARIO', json '[
    {
        "nome": "Elias Vitor Kauê das Neves",
        "cpf": "913.208.570-27",
        "genero": "masculino",
        "dt_nasc": "1985-04-07",
        "telefone": "(62) 99551-7239"
    },
    {
        "nome": "Bianca Sophie Rezende",
        "cpf": "149.752.013-48",
        "genero": "feminino",
        "dt_nasc": "1984-05-27",
        "telefone": "(86) 99264-2423"
    },
    {
        "nome": "Thomas Manoel da Silva ",
        "cpf": "591.385.523-02",
        "genero": "masculino",
        "dt_nasc": "1986-12-26",
        "telefone": "(86) 98320-5518"
    },
    {
        "nome": "Andrea Francisca Freitas",
        "cpf": "719.577.023-03",
        "genero": "feminino",
        "dt_nasc": "1968-01-13",
        "telefone": "(86) 99416-3665"
    },
    {
        "nome": "Luna Alana Martins",
        "cpf": "227.631.563-63",
        "genero": "feminino",
        "dt_nasc": "1999-01-15",
        "telefone": "(86) 99463-5648"
    },
    {
        "nome": "Renato Carlos Eduardo Marcos Vinicius Porto",
        "cpf": "771.131.243-13",
        "genero": "masculino",
        "dt_nasc": "1976-03-10",
        "telefone": "(89) 99916-0912"
    },
    {
        "nome": "Tânia Marlene Bernardes",
        "cpf": "648.907.663-24",
        "genero": "feminino",
        "dt_nasc": "1982-10-09",
        "telefone": "(86) 98354-3423"
    },
    {
        "nome": "Bernardo Hugo Assunção",
        "cpf": "456.599.693-64",
        "genero": "masculino",
        "dt_nasc": "1989-06-16",
        "telefone": "(86) 98354-3423"
    }
    ]');

-- FUNCOES

SELECT multi_cadastrar('FUNCAO', json '[
    {
        "nome": "publicidade",
        "descricao": "providencia a publicação de notícias sobre o evento em jornais e redes sociais."
    },
    {
        "nome": "administrativo",
        "descricao": "Faz o controle de pessoal do evento, auxilia em todas as areas."
    },
    {
        "nome": "limpeza",
        "descricao": "Responsável pela limpeza e organização do local do evento."
    },
    {
        "nome": "recepcionista",
        "descricao": "recepciona os convidados, visitantes e doadores."
    },
    {
        "nome": "seguranca",
        "descricao": "é responsável pelo planejamento da segurança nos eventos."
    }
]');

