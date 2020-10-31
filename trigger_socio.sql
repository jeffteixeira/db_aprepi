create or replace function fc_trigger_socio()
RETURNS trigger as
$$
    BEGIN
        select validador_cpf(NEW.cpf) into NEW.cpf;
        raise notice 'new.cpf %', new.cpf;
        raise notice 'length(new.cpf) %', length(new.cpf);
        RETURN NEW;
    END;
$$ language plpgsql;

CREATE TRIGGER trigger_socio BEFORE INSERT or UPDATE on
socio for each row
execute procedure fc_trigger_socio();

select * from socio;
create or replace function informar_falecimento_socio(cpf varchar)
RETURNS table (n text) as
$$
    DECLARE
        id int;
    BEGIN
        id := buscar_cod_socio(cpf);
        UPDATE socio SET dt_falecimento = current_date WHERE cod_socio = id;
        RETURN QUERY SELECT 'Operação realizada com sucesso.';

        EXCEPTION
            WHEN others THEN
                RETURN QUERY SELECT unnest(ARRAY[CONCAT('Erro durante a execução -> ', SQLERRM)]);
    END;
$$ language plpgsql;

select informar_falecimento_socio('30544493001');