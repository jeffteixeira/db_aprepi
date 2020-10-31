create or replace function validador_cpf(value_cpf varchar)
RETURNS varchar as
$$
    DECLARE
        number char;
        first_number char;
        equals_numbers boolean := true;
        sanitize_cpf varchar;
        t int := 9;
        d int := 0;
        c int := 0;

    BEGIN
        sanitize_cpf := REGEXP_REPLACE(value_cpf, '([^0-9])+', '', 'g');

        if LENGTH(sanitize_cpf) != 11 THEN
            raise exception 'CPF com numero de digitos diferente de 11: %', sanitize_cpf;
        END IF;

        first_number := SUBSTRING(sanitize_cpf, 1, 1);
        FOREACH number IN ARRAY regexp_split_to_array(sanitize_cpf, '') LOOP
            IF number != first_number THEN
                equals_numbers := false;
                EXIT;
            end if;
        end loop;

        IF equals_numbers THEN
            raise exception 'CPF com digitos iguais é invalido: %', sanitize_cpf;
        end if;

        LOOP
            exit when t = 11;
            -- reinicia c contador C e o D
            c := 0;
            d := 0;
            LOOP
                exit when c = t;
                d := d + SUBSTRING(sanitize_cpf, c+1, 1)::int * ((t + 1) - c);
                c := c + 1;
            end loop;

            d := ((10 * d) % 11) % 10;

            if (SUBSTRING(sanitize_cpf, c+1, 1)::int != d) THEN
                raise exception 'CPF invalido: %', sanitize_cpf;
            END IF;
            t := t + 1;
        end loop;

        return sanitize_cpf;
    END;
$$ language plpgsql;