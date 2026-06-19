-- Fix: cria_aux_alerta_presmed inseria com nratendimento=NULL para presmed
-- de origem != 'dieta/dietas', violando NOT NULL da nutricional_aux_alerta.
-- A guarda de early-return foi movida para antes do INSERT.

CREATE OR REPLACE FUNCTION demo.cria_aux_alerta_presmed()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    v_nratendimento BIGINT;
BEGIN
    IF lower(trim(NEW.origem)) NOT IN ('dieta', 'dietas') THEN
        RETURN NEW;
    END IF;

    SELECT p.nratendimento INTO v_nratendimento
      FROM demo.prescricao p
     WHERE p.fkprescricao = NEW.fkprescricao;

    IF v_nratendimento IS NULL THEN
        RAISE EXCEPTION 'Prescrição % não encontrada', NEW.fkprescricao;
    END IF;

    INSERT INTO demo.nutricional_aux_alerta (nratendimento, fkpresmed, reconhecido)
    VALUES (v_nratendimento, NEW.fkpresmed, false);

    RETURN NEW;
END;
$function$;

ALTER FUNCTION demo.cria_aux_alerta_presmed() OWNER TO CURRENT_USER;
