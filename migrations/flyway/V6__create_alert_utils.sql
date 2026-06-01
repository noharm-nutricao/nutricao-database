CREATE TABLE demo.nutricional_aux_alerta(
    id SERIAL PRIMARY KEY,
    nratendimento BIGINT NOT NULL REFERENCES demo.pessoa(nratendimento),
    fkevolucao BIGINT NULL,
    fkpresmed BIGINT NULL,
    reconhecido BOOLEAN DEFAULT false
);

SELECT * FROM demo.nutricional_aux_alerta;
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

    SELECT p.nratendimento
      INTO v_nratendimento
      FROM demo.prescricao p
     WHERE p.fkprescricao = NEW.fkprescricao;

    IF v_nratendimento IS NULL THEN
        RAISE EXCEPTION
            'Prescrição % não encontrada para o medicamento %',
            NEW.fkprescricao,
            NEW.fkpresmed;
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


-- SELECTS QUE SERAO UTILIZADOS NO REPOSITORY
-- ISSO É APENAS PARA SALVAR PARA DEPOIS
SELECT naa.nratendimento,
       ev.anotacoes
  FROM demo.nutricional_aux_alerta naa
  JOIN demo.evolucao ev
    ON ev.fkevolucao = naa.fkevolucao
 WHERE naa.reconhecido = false
   AND naa.fkevolucao IS NOT NULL;

SELECT naa.nratendimento
  FROM demo.nutricional_aux_alerta naa
  JOIN demo.presmed ev
    ON ev.fkpresmed = naa.fkpresmed
 WHERE naa.reconhecido = false
   AND naa.fkpresmed IS NOT NULL;