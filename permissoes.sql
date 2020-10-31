-- https://dba.stackexchange.com/questions/140670/postgres-inherit-from-one-role-and-not-another
-- https://stackoverflow.com/questions/52709231/how-postgresql-give-permission-what-execute-a-function-in-schema-to-user
-- https://www.postgresqltutorial.com/postgresql-administration/postgresql-grant/
-- https://flaviocopes.com/postgres-user-permissions/#:~:text=Group%20roles,roles%20have%20the%20INHERIT%20attribute.

-- FUNCIONARIO
CREATE ROLE funcionario;

GRANT EXECUTE ON FUNCTION cadastrar(varchar, json) TO funcionario;
GRANT EXECUTE ON FUNCTION atualizar(nome_tabela varchar, chave varchar, valor varchar, campos json) TO funcionario;
ALTER FUNCTION cadastrar(nome_tabela varchar, campos json) SECURITY DEFINER SET search_path = public;
ALTER FUNCTION atualizar(nome_tabela varchar, chave varchar, valor varchar, campos json) SECURITY DEFINER SET search_path = public;

CREATE USER flavio PASSWORD 'postgres01';
GRANT funcionario TO flavio;

-- ADMINISTRADOR
CREATE ROLE administrador;

GRANT funcionario to administrador;
GRANT EXECUTE ON FUNCTION deletar(nome_tabela varchar, chave varchar, valor varchar) TO administrador;
ALTER FUNCTION deletar(nome_tabela varchar, chave varchar, valor varchar) SECURITY DEFINER SET search_path = public;

CREATE USER jose PASSWORD 'postgres01';
GRANT administrador TO jose;




