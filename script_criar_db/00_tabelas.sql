CREATE TABLE IF NOT EXISTS ALIMENTO (
    cod_alimento serial primary key,
    nome varchar(20) not null,
    descricao varchar(128) null,
    quantidade int not null,
    grandeza int not null,
    unidade_de_medida varchar(2) not null
);

CREATE TABLE IF NOT EXISTS CESTA_BASICA (
    cod_item_cesta serial primary key,
    cod_alimento int references alimento(cod_alimento),
    quantidade int not null
);

CREATE TABLE IF NOT EXISTS SOCIO (
    cod_socio serial primary key,
    nome varchar(50) not null,
    dt_nasc date not null,
    cpf varchar(14) unique not null,
    telefone varchar(15) null,
    dt_falecimento date null
);

CREATE TABLE IF NOT EXISTS BENFEITOR (
    cod_benfeitor serial primary key,
    nome varchar(50) not null,
    dt_nasc date not null,
    cpf varchar(14) unique not null,
    telefone varchar(15) null
);

CREATE TABLE IF NOT EXISTS DOACAO (
    cod_doacao serial primary key,
    cod_benfeitor int references benfeitor(cod_benfeitor),
    dt_doacao timestamp default current_timestamp
);

CREATE TABLE IF NOT EXISTS ITEM_DOACAO (
    cod_item_doacao serial primary key,
    cod_doacao int references doacao(cod_doacao),
    cod_alimento int references alimento(cod_alimento),
    quantidade int not null,
    grandeza int not null,
    unidade_de_medida varchar(2) not null
);

CREATE TABLE IF NOT EXISTS RECEBIMENTO (
    cod_recebimento serial primary key,
    cod_socio int references socio(cod_socio),
    dt_recebimento timestamp default current_timestamp
);

CREATE TABLE IF NOT EXISTS ITEM_RECEBIMENTO (
    cod_item_recebimento serial primary key,
    cod_alimento int references alimento(cod_alimento),
    cod_recebimento int references recebimento(cod_recebimento),
    quantidade int not null,
    grandeza int not null,
    unidade_de_medida varchar(2) not null
);

CREATE TABLE IF NOT EXISTS MEDICO (
    cod_medico serial primary key,
    nome varchar(50) not null,
    dt_nasc date not null,
    cpf varchar(14) unique not null,
    crm varchar(20) unique not null,
    telefone varchar(15) null
);

CREATE TABLE IF NOT EXISTS ESPECIALIDADE (
    cod_especialidade serial primary key,
    nome varchar(32) not null,
    descricao varchar(128) null
);

CREATE TABLE IF NOT EXISTS MEDICO_ESPECIALIDADE (
    cod_medico_especialidade serial primary key,
    cod_especialidade int references especialidade(cod_especialidade),
    cod_medico int references medico(cod_medico)
);

CREATE TABLE IF NOT EXISTS CONSULTA (
    cod_consulta serial primary key,
    cod_socio int references socio(cod_socio),
    cod_medico_especialidade int references medico_especialidade(cod_medico_especialidade),
    dt_consulta date not null,
    hora_consulta time not null
);

CREATE TABLE IF NOT EXISTS VOLUNTARIO (
    cod_voluntario serial primary key,
    nome varchar(50) not null,
    dt_nasc date not null,
    cpf varchar(14) unique not null,
    telefone varchar(15) null
);

CREATE TABLE IF NOT EXISTS FUNCAO (
    cod_funcao serial primary key,
    nome varchar(32) not null,
    descricao text not null
);

CREATE TABLE IF NOT EXISTS TIPO_EVENTO (
    cod_tipo_evento serial primary key,
    nome varchar(32) not null,
    descricao text not null
);

CREATE TABLE IF NOT EXISTS EVENTO (
    cod_evento serial primary key,
    cod_tipo_evento int references tipo_evento(cod_tipo_evento),
    arrecadacao float not null default 0,
    custo float not null default 0,
    nome varchar(32) not null,
    dt_inicio date not null default current_date,
    dt_fim date null
);

CREATE TABLE IF NOT EXISTS VOLUNTARIO_FUNCAO (
    cod_voluntario_funcao serial primary key,
    cod_voluntario int references voluntario(cod_voluntario),
    cod_evento int references evento(cod_evento),
    cod_funcao int references funcao(cod_funcao)
);

CREATE TABLE IF NOT EXISTS BENFEITOR_EVENTO (
    cod_benfeitor_evento serial primary key,
    cod_benfeitor int references benfeitor(cod_benfeitor),
    cod_evento int references evento(cod_evento),
    valor_doado float not null
);