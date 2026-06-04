-- limpar tabela de alertas que estão incorretos
DELETE FROM demo.nutricional_alerta;

CREATE TABLE demo.nutricional_aux_alerta(
    id SERIAL PRIMARY KEY,
    nratendimento BIGINT NOT NULL REFERENCES demo.pessoa(nratendimento),
    fkevolucao BIGINT NULL,
    fkpresmed BIGINT NULL,
    reconhecido BOOLEAN DEFAULT false
);

----------TRIGGER CRIA ALERTA EVOLUCAO----------
DROP FUNCTION IF EXISTS demo.cria_aux_alerta_evolucao();

CREATE OR REPLACE FUNCTION demo.cria_aux_alerta_evolucao()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN

    INSERT INTO demo.nutricional_aux_alerta (
        nratendimento,
        fkevolucao,
        reconhecido
    )
    VALUES (
        NEW.nratendimento,
        NEW.fkevolucao,
        false
    );

    RETURN NEW;

END;
$function$;

ALTER FUNCTION demo.cria_aux_alerta_evolucao() OWNER TO CURRENT_USER;

DROP TRIGGER IF EXISTS trg_cria_aux_alerta_evolucao
ON demo.evolucao;

CREATE TRIGGER trg_cria_aux_alerta_evolucao
AFTER INSERT
ON demo.evolucao
FOR EACH ROW
EXECUTE FUNCTION demo.cria_aux_alerta_evolucao();
-------------FIM DA TRIGGER-------------

----------TRIGGER CRIA ALERTA PRESMED----------
CREATE OR REPLACE FUNCTION demo.cria_aux_alerta_presmed()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    v_nratendimento BIGINT;
BEGIN

    IF lower(trim(NEW.origem)) IN ('dieta', 'dietas') THEN

        SELECT p.nratendimento
        INTO v_nratendimento
        FROM demo.prescricao p
        WHERE p.fkprescricao = NEW.fkprescricao;

        IF v_nratendimento IS NULL THEN
            RAISE EXCEPTION
                'Prescrição % não encontrada',
                NEW.fkprescricao;
        END IF;

    END IF;

    INSERT INTO demo.nutricional_aux_alerta (
        nratendimento,
        fkpresmed,
        reconhecido
    )
    VALUES (
        v_nratendimento,
        NEW.fkpresmed,
        false
    );

    RETURN NEW;
END;
$function$;

ALTER FUNCTION demo.cria_aux_alerta_presmed() OWNER TO CURRENT_USER;

DROP TRIGGER IF EXISTS trg_cria_aux_alerta_presmed
ON demo.presmed;

CREATE TRIGGER trg_cria_aux_alerta_presmed
AFTER INSERT
ON demo.presmed
FOR EACH ROW
EXECUTE FUNCTION demo.cria_aux_alerta_presmed();
-------------FIM DA TRIGGER-------------

-- remver NOT NULL da coluna reconhecido_por para iniciar alerta com
-- essa coluna nula (ficar assim até alguém reconhecer)
ALTER TABLE demo.nutricional_alerta
ALTER COLUMN reconhecido_por DROP NOT NULL;

ALTER TABLE demo.nutricional_alerta
DROP CONSTRAINT nutricional_alerta_severidade_check;

-- alterado constraint de check para severidade
ALTER TABLE demo.nutricional_alerta
ADD CONSTRAINT nutricional_alerta_severidade_check_updated
CHECK (severidade IN ('md', 'al', 'cr'));