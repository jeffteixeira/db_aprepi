create or replace function fc_trigger_benfeitor()
RETURNS trigger as
$$
    BEGIN
        select validador_cpf(NEW.cpf) into NEW.cpf;
        RETURN NEW;
    END;
$$ language plpgsql;

CREATE TRIGGER trigger_benfeitor BEFORE INSERT or UPDATE on
benfeitor for each row
execute procedure fc_trigger_benfeitor();