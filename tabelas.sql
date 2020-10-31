CREATE TABLE SOCIO(
    cod_socio serial primary key,
    nome varchar(32) not null,
    dt_nasc date not null,
    cpf varchar(14) unique not null,
    telefone varchar(15) null,
    dt_falecimento date null
);

ALTER TABLE BENFEITOR ALTER COLUMN telefone TYPE varchar(15);

CREATE TABLE ALIMENTO(
    cod_alimento serial primary key,
    nome varchar(20) not null,
    descricao varchar(128) null,
    quantidade int not null,
    grandeza int not null,
    unidade_de_medida varchar(2) not null
);

ALTER TABLE ALIMENTO ALTER COLUMN unidade_de_medida SET not null;
ALTER TABLE ALIMENTO ALTER COLUMN unidade_de_medida drop default;
ALTER TABLE ALIMENTO ADD COLUMN  grandeza int not null default 1;
ALTER TABLE ALIMENTO ALTER COLUMN grandeza drop default;

CREATE TABLE RECEBIMENTO(
    cod_recebimento serial primary key,
    cod_socio int references socio(cod_socio),
	dt_recebimento timestamp default current_timestamp
);

CREATE TABLE ITEM_RECEBIMENTO(
    cod_item_recebimento serial primary key,
    cod_alimento int references alimento(cod_alimento),
    cod_recebimento int references recebimento(cod_recebimento),
	quantidade int not null,
	grandeza int not null,
    unidade_de_medida varchar(2) not null
);

ALTER TABLE ITEM_RECEBIMENTO ADD COLUMN unidade_de_medida varchar(2) not null default 'KG';
ALTER TABLE ITEM_RECEBIMENTO ALTER COLUMN unidade_de_medida drop default;
ALTER TABLE ITEM_RECEBIMENTO ADD COLUMN  grandeza int not null default 1;
ALTER TABLE ITEM_RECEBIMENTO ALTER COLUMN grandeza drop default;

CREATE TABLE BENFEITOR(
    cod_benfeitor serial primary key,
    nome varchar(50) not null,
    dt_nasc date not null,
    cpf varchar(14) unique not null,
    telefone varchar(15) null
);

CREATE TABLE DOACAO(
    cod_doacao serial primary key,
    cod_benfeitor int references benfeitor(cod_benfeitor),
	dt_doacao timestamp default current_timestamp
);

CREATE TABLE ITEM_DOACAO(
    cod_item_doacao serial primary key,
    cod_doacao int references doacao(cod_doacao),
    cod_alimento int references alimento(cod_alimento),
	quantidade int not null,
	grandeza int not null,
    unidade_de_medida varchar(2) not null
);

ALTER TABLE ITEM_DOACAO ADD COLUMN unidade_de_medida varchar(2) not null default 'KG';
ALTER TABLE ITEM_DOACAO ALTER COLUMN unidade_de_medida drop default;
ALTER TABLE ITEM_DOACAO ADD COLUMN  grandeza int not null default 1;
ALTER TABLE ITEM_DOACAO ALTER COLUMN grandeza drop default;

CREATE TABLE CESTA_BASICA(
    cod_item_cesta serial primary key,
    cod_alimento int references alimento(cod_alimento),
    quantidade int not null
);

CREATE TABLE MEDICO(
    cod_medico serial primary key,
	nome varchar(50) not null,
    dt_nasc date not null,
    cpf varchar(14) unique not null,
    crm varchar(20) unique not null,
    telefone varchar(15) null
);

CREATE TABLE ESPECIALIDADE(
    cod_especialidade serial primary key,
    nome varchar(32) not null,
    descricao varchar(128) null
);

CREATE TABLE MEDICO_ESPECIALIDADE(
    cod_medico_especialidade serial primary key,
    cod_especialidade int references especialidade(cod_especialidade),
    cod_medico int references medico(cod_medico)
);

CREATE TABLE TIPO_EVENTO(
    cod_tipo_evento serial primary key,
    nome varchar(32) not null,
    descricao text not null
);

CREATE TABLE EVENTO(
    cod_evento serial primary key,
    cod_tipo_evento int references tipo_evento(cod_tipo_evento),
    arrecadacao float not null default 0,
    custo float not null default 0,
    nome varchar(32) not null,
	dt_inicio date not null default current_date,
	dt_fim date null
);

select quantidade from alimento;

SELECT (('{"arz": "1"}'::json)->>'arz')::int;
select * from doacao;
select * from item_doacao;
select buscar_cod_socio('780.252.620-57');
SELECT cadastrar('DOACAO', json '{"cpf_benfeitor": "677.359.478-28", "cesta_basica": 10}');
SELECT cadastrar('RECEBIMENTO', json '{"cpf_socio": "780.252.620-57", "cesta_basica": 5}');
select * from item_recebimento;
SELECT cadastrar('ALIMENTO', json '{"nome": "sardinha", "quantidade": 19, "unidade_de_medida": "g", "grandeza": 200}');
select * from ALIMENTO;
select receber_doacao('780.252.620-57', json '{"arroz": "5"}');
select * from alimento;
delete from alimento where cod_alimento=5;
SELECT cadastrar('CESTA_BASICA', json '{"item_cesta": "arroz", "quantidade": 0}');
SELECT buscar_cod_alimento('arroz');
select * from cesta_basica;

SELECT cadastrar('socio',
    '{"nome": "Joao", "cpf": "780.252.620-57", "dt_nasc": "1999-11-30", "cidade": "São Gonçalo", "estado": "Piauí"}'::json);
select * from socio;

SELECT FORMAT('%s.%s.%s-%s',
    substring('93084765049', 1, 3),
    substring('93084765049', 4, 3),
    substring('93084765049', 7, 3),
    substring('93084765049', 10, 2));

select buscar_cod_benfeitor('677.359.478-28');

SELECT cadastrar('benfeitor', json '{"nome": "Carolina Rebeca Brito", "cpf": "677.359.478-28", "dt_nasc": "10/06/1973", "telefone": "(86) 98628-0387"}');
SELECT realizar_doacao('677.359.478-28', json '{}');
select * from alimento;

select buscar_cod_benfeitor('677.359.478-28');


SELECT count(*) from json_object_keys(json '{}');





