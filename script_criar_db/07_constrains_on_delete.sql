alter table cesta_basica
drop constraint cesta_basica_cod_alimento_fkey,
add constraint cesta_basica_cod_alimento_fkey
   foreign key (cod_alimento)
   references alimento(cod_alimento)
   on delete cascade;

alter table doacao
drop constraint doacao_cod_benfeitor_fkey,
add constraint doacao_cod_benfeitor_fkey
   foreign key (cod_benfeitor)
   references benfeitor(cod_benfeitor)
   on delete set null;

alter table item_doacao
drop constraint item_doacao_cod_doacao_fkey,
add constraint item_doacao_cod_doacao_fkey
   foreign key (cod_doacao)
   references doacao(cod_doacao)
   on delete cascade;

alter table item_doacao
drop constraint item_doacao_cod_alimento_fkey,
add constraint item_doacao_cod_alimento_fkey
   foreign key (cod_alimento)
   references alimento(cod_alimento)
   on delete cascade;

alter table recebimento
drop constraint recebimento_cod_socio_fkey,
add constraint recebimento_cod_socio_fkey
   foreign key (cod_socio)
   references socio(cod_socio)
   on delete set null;

alter table item_recebimento
drop constraint item_recebimento_cod_recebimento_fkey,
add constraint item_recebimento_cod_recebimento_fkey
   foreign key (cod_recebimento)
   references recebimento(cod_recebimento)
   on delete cascade;

alter table item_recebimento
drop constraint item_recebimento_cod_alimento_fkey,
add constraint item_recebimento_cod_alimento_fkey
   foreign key (cod_alimento)
   references alimento(cod_alimento)
   on delete cascade;

alter table medico_especialidade
drop constraint medico_especialidade_cod_especialidade_fkey,
add constraint medico_especialidade_cod_especialidade_fkey
   foreign key (cod_especialidade)
   references especialidade(cod_especialidade)
   on delete cascade;

alter table medico_especialidade
drop constraint medico_especialidade_cod_medico_fkey,
add constraint medico_especialidade_cod_medico_fkey
   foreign key (cod_medico)
   references medico(cod_medico)
   on delete cascade;

alter table consulta
drop constraint consulta_cod_medico_especialidade_fkey,
add constraint consulta_cod_medico_especialidade_fkey
   foreign key (cod_medico_especialidade)
   references medico_especialidade(cod_medico_especialidade)
   on delete cascade;

alter table consulta
drop constraint consulta_cod_socio_fkey,
add constraint consulta_cod_socio_fkey
   foreign key (cod_socio)
   references socio(cod_socio)
   on delete cascade;

alter table evento
drop constraint evento_cod_tipo_evento_fkey,
add constraint evento_cod_tipo_evento_fkey
   foreign key (cod_tipo_evento)
   references tipo_evento(cod_tipo_evento)
   on delete set null;

alter table voluntario_funcao
drop constraint voluntario_funcao_cod_evento_fkey,
add constraint voluntario_funcao_cod_evento_fkey
   foreign key (cod_evento)
   references evento(cod_evento)
   on delete cascade;

alter table voluntario_funcao
drop constraint voluntario_funcao_cod_funcao_fkey,
add constraint voluntario_funcao_cod_funcao_fkey
   foreign key (cod_funcao)
   references funcao(cod_funcao)
   on delete cascade;

alter table voluntario_funcao
drop constraint voluntario_funcao_cod_voluntario_fkey,
add constraint voluntario_funcao_cod_voluntario_fkey
   foreign key (cod_voluntario)
   references voluntario(cod_voluntario)
   on delete cascade;

alter table benfeitor_evento
drop constraint benfeitor_evento_cod_benfeitor_fkey,
add constraint benfeitor_evento_cod_benfeitor_fkey
   foreign key (cod_benfeitor)
   references benfeitor(cod_benfeitor)
   on delete set null;

alter table benfeitor_evento
drop constraint benfeitor_evento_cod_evento_fkey,
add constraint benfeitor_evento_cod_evento_fkey
   foreign key (cod_evento)
   references evento(cod_evento)
   on delete cascade;


-- select cadastrar('BENFEITOR', json '{
-- 	"nome": "Milena Fabiana Bruna Fernandes",
-- 	"cpf": "128.948.548-89",
-- 	"dt_nasc": "1963-12-09",
-- 	"telefone": "(21) 98605-2504"
-- }');
--
-- select cadastrar('TIPO_EVENTO', json '{
--   "nome": "show",
--   "descricao": "Um evento com fins de caridade"
-- }');
--
-- select cadastrar('EVENTO', json '{
--   "nome_evento": "Bazar APREPI 2020",
--   "nome_tipo_evento": "show"
-- }');
--
-- select * from evento;
--
-- select cadastrar('BENFEITOR_EVENTO', json '{
--   "nome_evento": "Bazar APREPI 2020",
--   "cpf_benfeitor": "128.948.548-89",
--   "valor_doacao": 1000}');
--
-- select relatorio_doacoes_feitas_eventos();
-- select relatorio_doacoes_feitas();
-- select * from benfeitor_evento;
--
-- select deletar('BENFEITOR', 'cpf', '128.948.548-89');
--
-- select pg_typeof((('{}'::json)->>'mikael')::float);
-- select coalesce((('{}'::json)->>'mikael')::float, 0);